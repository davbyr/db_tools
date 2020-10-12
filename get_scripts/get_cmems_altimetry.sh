#!/bin/bash
#
# Author: David Byrne (dbyrne@noc.ac.uk)
# v1.0 (12/10/20)
#
# This is a shell script for getting altimetry data from the CMEMS database between
# two specified dates. The script will download data from all available altimeters
# between these dates.
#
# All variables will be downloaded.
#
# ARGUMENTS:
#		get_cmems_altimetry.sh <USERNAME> <PASSWORD> <start_date> <end_date> <out_dir>
#							   <user_pid>
#
# 		> Dates should be supplied as strings in the format 'YYYY-MM-DD hh:mm:ss'
#		> USERNAME and PASSWORD relate to CMEMS login information
#		> Output will be put into the directory out_dir. If it doesn't exist it will be
#				created.
#		> user_pid (optional) is a string if you want to download data from only a single 
#				altimeter. For example, Jason-3 is 'j3'. Check CMEMS for all possible 
#				altimeters or take a look inside the pid_array variable of this script.
#
# EXAMPLE USEAGE:
#		get_cmems_altimetry.sh 'user_eg' 'password123' '2018-03-28 23:24:54' 
#							   '2018-03-30 23:24:54' ./cmems_data_dir 'j3'
#
# Some additional notes on getting data from CMEMS:
# 	> service-id relates to the
#		The suffix -DGF is Direct Get File. Alternatively, this might be -TSD (subsetter).
#		I'm not sure is -TSD works for this altimetry data.
# 	> product-id relates to the
# 	> motu-server is either my.cmems-du.eu or nrt.cmems-du.eu. my = multi year.
#
# It is possible that the service-id in this script may expire. Just change this variable
# if needed. Additionally, this can be changed to other altimetry product service-ids.
#
# *NOTE1: This script will create and remove a temporary file called tmp_cmemsDBxyz.zip 
#_______________________________________________________________________________________#

export USERNAME="$1"
PASSWORD="$2"
date_min="$3"
date_max="$4"
out_dir="$5"

# Server to use
export motu_server='http://my.cmems-du.eu/motu-web/Motu'
# Service ID for the data -> This is GLOBAL
export service_id='SEALEVEL_GLO_PHY_L3_REP_OBSERVATIONS_008_062-DGF'
export tmp_file='tmp_cmemsDBxyz.zip'

# Altimeters to loop through and get data from
if [[ -n "$6" ]]; then
	export pid_array=("$6")
else
	export pid_array=('alg' 'al' 'c2' 'e1g' 'e1' 'e2' 'enn' 'en' 'g2' 'h2g' 'h2' 'j1g' 'j1n'
				  		'j1' 'j2g' 'j2n' 'j2' 'j3' 's3a' 's3b' 'tpn' 'tp')
fi

# Check if input directory exists
if [ ! -d $out_dir ]; then 
	echo 'Creating output directory'
	mkdir $out_dir
fi

echo ' ' # Whitespace

cd $out_dir

# Loop over CMEMS altimetry dataset. If command fails, no problems, bash will continue.
for pid in "${pid_array[@]}"
do
	product_id='dataset-duacs-rep-global-'$pid'-phy-l3'
    echo '|>>>>>> Downloading from: '$product_id
	python -m motuclient --motu $motu_server --service-id $service_id \
	--product-id $product_id \
	--date-min $date_min --date-max $date_max \
	--out-dir '.' --out-name $tmp_file --user $USERNAME --pwd $PASSWORD >/dev/null
	unzip "$tmp_file" >/dev/null 2>/dev/null
	rm "$tmp_file" >/dev/null 2>/dev/null
done
