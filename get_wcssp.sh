#!/bin/bash
#
# Author: David Byrne (dbyrne@noc.ac.uk)
# v1.0 (17/06/20)
#
# get_wcssp_multiple is for retrieving multiple netcdf files from the MOOSE WCSSP_India
# database on JASMIN. This script should be placed on JASMIN and run on a MASS Server.
# The script will get multiple files between two specified dates and either concatenate
# them into one (along the time dimension) or simple place them all in a specified
# directory. It takes advantage of the strict file naming rules.
#
# At it's most basic, the script can be run as:
#	get_wcssp_multiple.sh <start_date> <end_date> <output_directory> --concat false 
#	+optional_args
#
# This will get data for the default configuration/data type settings in the script. Dates
# should ideally be of form YYYYMMDD. The default scripts gets files between the specified 
# dates for ALL grids (T U V) and ALL variables. These can be changed using the optional 
# args:
#
#	--concat [default: true]
#		Whether or not to concatenate files along time dimension.
#	--cfg_name [default: rosie_u-bf945oeco8coare]
#		Name of the configuration for which to get data. Can be found no the WP1.2 wiki
#	--t_freq [default: '1h']
#		Output frequency of data -- either '1h' or '1d'
#	--run_id [default: 'ind']
#		Run identification. For WCSSP, can be kept as default.
#	--data_type [default: 'shelftmb']
#		Either 25hourm, mersea, shelftmb or hrsea (see wiki)
#	--U [default: All grids are selected, all data downloaded]
#		Tells the script to get U data. Must be followed by either 'all' or a string of
#		ncks type flags. E.G. "-v nav_lon,nav_lat,vozocrtx"
#	--V [default: All grids are selected, all data downloaded]
#		Tells the script to get V data. Must be followed by either 'all' or a string of
#		ncks type flags. E.G. "-v nav_lon,nav_lat,vomecrty"
#	--T [default: All grids are selected, all data downloaded]
#		Tells the script to get T data. Must be followed by either 'all' or a string of
#		ncks type flags. E.G. "-v nav_lon,nav_lat,sossheig"
#	--runstart [default: 20160109]
#		When the run was started.
#
# An example with optional flags:
#
#	get_wcssp_multiple.sh 20180101 20180105 ./jan18 --concat false --data_type mersea
#		--t_freq '1d' --U --T '-v nav_lon,nav_lat,votemper_top'
#
# This gets all files between 2018-01-01 and 2018-01-05 and puts them into the jan18 dir.
# It downloads just the U and T grid data. For the U grid, it gets everything. For the T
# grid it only get nav_lon, nav_lat and votemper_top.
#_______________________________________________________________________________________#

## INPUT ARGUMENTS -- DEFAULTS ##
# DEFAULT ARGUMENTS
export concat=true               
export cfg_name=rosie_u-bf945oeco8coare
export t_freq='1h'               
export run_id=ind                
export data_type='shelftmb'      
export runstart=20160109         

## PARSE INPUT ARGUMENTS, IF ANY
export POSITIONAL=()
export grid=()                  # Array of grids to read
export grid_opts=()             # Array of ncks commands
while [[ $# -gt 0 ]]            # Loop over input arguments
do
        export key="$1"
        case $key in            # $key is inputs arguments. Switch statement
                --concat)
                concat="$2"
                shift
                shift
                ;;
                --cfg_name)
                cfg_name="$2"
                shift
                shift
                ;;
                --t_freq)
                t_freq="$2"
                shift
                shift
                ;;
                --run_id)
                run_id="$2"
                shift
                shift
                ;;
                --data_type)
                data_type="$2"
                shift
                shift
                ;;
                --U)
                grid+=("U")
                grid_opts+=("$2")
                shift
                shift
                ;;
                --V)
                grid+=("V")
                grid_opts+=("$2")
                shift
                shift
                ;;
                --T)
                grid+=("T")
                grid_opts+=("$2")
                shift
                shift
                ;;
                --runstart)
                runstart="$2"
                shift
                shift
                ;;
                *)
                POSITIONAL+=("$1")
                shift
                ;;
        esac
done
# Restore positional arguments
set -- "${POSITIONAL[@]}"

# Default positional arguments
export date0=${1:-none}
export date1=${2:-none}
export out_dir=${3:-.}

# Default grid reading options
if [[ ${#grid[@]} = 0 ]]; then
        grid=(T U V)
        grid_opts=("all" "all" "all")
fi

# Output to terminal to show beginning of routine
echo " "
echo "Getting ${run_id}_${t_freq}_<DATES>_${runstart}_${data_type}_grid_<GRIDS>.nc files."
echo "Dates: $date0 -> $date1"
echo "Grids: ${grid[@]}"
echo "Output directory: ${out_dir}"
echo "_______________________________________________________________________"
echo " "

# GET DATA
#########################################################################################
#########################################################################################

# Set up some filenames and directories
export filter_stub="filter_opts"
export cat_stub="${out_dir}/${run_id}_${t_freq}_cat_${date0}_${date1}_${data_type}"
export fn_tmp="${cat_stub}.tmp.nc"
export dn_get=("moose:/devfc/${cfg_name}/field.nc.file/")

# Bashify date strings
d0=$(date -d "$date0" +%Y%m%d)
d1=$(date -d "$date1" +%Y%m%d)
d2=$(date -d "$date1 +1 day" +%Y%m%d)

# Loop over grids
grid_counter=0
for gg in "${grid[@]}"
do
        echo "Getting ${gg} Grid Data..."

        # Determine moo get or moo filter and create filter_opts files
        # In the case of moo filter, create and input string into filter query file $fn_filter_opts
        ncks_string="${grid_opts[grid_counter]}"
        if [[ "$ncks_string" = "all" ]]; then
                get_cmd="moo get -f "
        else
                fn_filter_opts="${filter_stub}.tmp.txt"
                echo $ncks_string
                (echo "$ncks_string" > $fn_filter_opts)
                get_cmd="moo filter -f $fn_filter_opts "
        fi

        # Define concatenation file (won't be used if !$concat)
        fn_cat="${cat_stub}_grid_${gg}.nc"

        # Loop over dates
        dateii=$d0
        while [ "$dateii" != "$d2" ]
        do
                # Define directory and filename of file to get from moose.
                fn_get="${run_id}_${t_freq}_${dateii}_${runstart}_${data_type}_grid_${gg}.nc"
                dn_fn_get="$dn_get$fn_get"
                echo "$dn_fn_get"

                # If concatenation, get file > tmp file and concatenate with $fn_cat using nco
                if $concat; then
                        if [[ "$dateii" = "$d0" ]]; then
                        $($get_cmd "$dn_fn_get" "$fn_cat" &> /dev/null)
                        else
                                $($get_cmd "$dn_fn_get" "$fn_tmp" &> /dev/null)
                                $(ncks -O --mk_rec_dmn time_counter $fn_cat $fn_cat)
                                $(ncrcat -O $fn_cat $fn_tmp $fn_cat)
                                rm "$fn_tmp"
                        fi
                # If not concatenation, simply get files
                else
                        $($get_cmd "$dn_fn_get" "$out_dir")
                fi

                # Update date variable for next iteration
                dateii=$(date -d "$dateii +1 day" +%Y%m%d)
        done
# Update grid counter
grid_counter=$grid_counter+1
done
