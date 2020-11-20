#!/bin/bash
#
# Script for downloading and compiling/installing xios
# 

#********* ARGUMENTS *********

# out_dir   | Where to checkout XIOS code. If it doesn't exist it will be created.
# url       | Base URL to use for downloading XIOS. 
#           |    e.g. 'http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/branchs/xios-2.5@1627'
# arch_dir  | Directory from where to copy arch files for compilation
# arch_name | Name of arch files (i.e. the bit between arch- and .fcm etc).

# Required
out_dir='./xios'  
url='http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/branchs/xios-2.5@1627'
arch_dir='./arch'
arch_name='archer'



#********* SCRIPT *********
	
# Determine if desired output dir exists. If not, create it.
if [ ! -d "$out_dir" ]; then
	mkdir "$out_dir"
fi
	
# Load modules for ARCHER
echo '>>> Loading modules'
module swap PrgEnv-cray PrgEnv-intel
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel

# Checkout XIOS using svn
'>>> Downloading XIOS source code'
svn co $url $out_dir
	
# Get arch files and move them across to the fresh checkout
arch_files="arch-${arch_name}.*"
echo '>>> Copying arch files: $arch_files'
cp $arch_dir/$arch_files $out_dir/arch
cd $out_dir
	
# Compile XIOS
echo '>>> ./make_xios --full --prod --arch $arch_name --netcdf_lib netcdf4_par --job 4'
./make_xios --full --prod --arch $arch_name --netcdf_lib netcdf4_par --job 4