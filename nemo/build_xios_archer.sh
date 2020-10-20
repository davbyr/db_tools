#!/bin/bash
# Downloads and compiles XIOS
export XIOS_DIR=$1
export ARCH_DIR=$2
	
# Determine if desired output dir exists. If not, create it.
if [! -d "$XIOS_DIR" ]; then
	mkdir "$XIOS_DIR"
fi
	
fancy_print "Downloading and compiling XIOS in $XIOS_DIR"

cd $XIOS_DIR # Previous DIR = $PWD
	
# Checkout XIOS version
fancy_print " Checkout out XIOS repository"
svn co http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/branchs/xios-2.5@1627 xios
	
# Get arch files and move them across to the fresh checkout
cd xios
cp $ARCH_DIR/* ./arch
	
# Compile XIOS
fancy_print " Compiling XIOS"
./make_xios --full --prod --arch archer --netcdf_lib netcdf4_par --job 4
