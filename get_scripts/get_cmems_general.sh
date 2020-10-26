#!/bin/bash
#
# General script for downloading CMEMS data, with advice given on arguments (see below).
#
# Most arguments are changed in the script below. USERNAME and PASSWORD are passed as
# command line arguments to prevent sensitive information being made public.
#
# This script will create a temporary file by the name of $tmp_file. This will be
# removed at the end of the script.
#
# Author: David Byrne (dbyrne@noc.ac.uk)
# v1.0 (26/10/20)
#_______________________________________________________________________________________#

export USERNAME="$1"
PASSWORD="$2"

# Arguments to change.
# 1. Dates should be given in the form 'YYYY-MM-DD hh:mm:ss'
# 2. Service-id must have the correct suffix: either -DGF or -TSD
#			These stand for Direct Get File and Subsetter respectively.
#			The rest of the string is the main outer name of the data to get.
# 3. If out_dir doesn't exist, it will be created
# 4. Motu-server can be either options below (one is commented). 'my' stands for 
#			'multi-year' and 'nrt' for 'Near Real Time'
# 5. Product-id is the secondary subname of the data to get. This is the name from the list
#			given after selecting which dataset to download. For example, different
#			satellite options for altimetry.
date_min=
date_max=
out_dir='.'
service_id='SEALEVEL_GLO_PHY_L3_REP_OBSERVATIONS_008_062-DGF'
motu_server='http://my.cmems-du.eu/motu-web/Motu'
product_id='dataset-duacs-rep-global-'$pid'-phy-l3'


tmp_file='tmp_cmemsDBxyz.zip'


# Check if input directory exists
if [ ! -d $out_dir ]; then 
	echo 'Creating output directory'
	mkdir $out_dir
fi

echo ' ' # Whitespace

cd $out_dir

echo '|>>>>>> Downloading from: '$product_id
python -m motuclient --motu $motu_server --service-id $service_id \
	--product-id $product_id \
	--date-min $date_min --date-max $date_max \
	--out-dir '.' --out-name $tmp_file --user $USERNAME --pwd $PASSWORD >/dev/null
unzip "$tmp_file" >/dev/null 2>/dev/null
rm "$tmp_file" >/dev/null 2>/dev/null

