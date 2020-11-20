#!/bin/bash
#
# Bash script compiling a new configuration of NEMO.
# Variables defined at the top of the script may be changed.

#********* ARGUMENTS *********
# Comment out optional arguments if not required.
# out_dir | 
# url     | 
#         |  

# Required
nemo_dir=''
xios_dir=''
work_cfgs='OCE' 
jobs=10

# Optional
cpp_file=''
arch_file=''
my_src=''



#********* SCRIPT *********

# Define the path to the configuration directory
cfg_dir=$nemo_dir/cfgs/$cfg_name

# Load modules
module swap PrgEnv-cray PrgEnv-intel
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel
	
# Make some directories if they don't already exist.
if [ ! -d "$cfg_dir" ]; then
    mkdir "$cfg_dir"
fi
if [ ! -d "$nemo_dir/arch" ]; then
    mkdir "$nemo_dir/arch"
fi
if [ ! -d "$cfg_dir/MY_SRC" ]; then
    mkdir "$cfg_dir/MY_SRC"
fi
	
# Create work_cfgs file -> describes which components of NEMO to use.
echo "$cfg_name $work_cfgs" > $nemo_dir/cfgs/work_cfgs.txt

# Copy across cpp file.
if [ "$cpp_file" ]; then
	cp $cpp_file $cfg_dir
fi

# Set XIOS directory in arch file
if [ "$arch_file" ]; then
	cp $arch_file $nemo_dir/arch 
	export replace_line="%XIOS_HOME           ${xios_dir}"
	sed -i "s|^%XIOS_HOME.*|${replace_line}|" "$nemo_dir/arch/arch-${arch_name}.fcm"
fi
	
# Move MY_SRC files if provided to function
if [ "$my_src" ]; then
	cp $my_src/* $cfg_dir/MY_SRC
fi

# Compile NEMO
cd $nemo_dir
echo "Compiling NEMO $cfg_name Config"
echo "./makenemo -m $arch_name -r $cfg_name -j $jobs"
./makenemo -m $arch_name -r $cfg_name -j 10