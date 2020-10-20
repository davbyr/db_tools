#!/bin/bash
# Functions for downloading, building and compiling NEMO
#
# To use a function in the terminal or inside another script, call the script followed
# by the desired function. e.g.
#
#		./nemo_build_tools build_xios_archer arg1 arg2
#
# See individual functions for more info on arguments.

load_modules_archer() {
	# Loads modules for compiling NEMO and XIOS on ARCHER
	module swap PrgEnv-cray PrgEnv-intel
	module load cray-hdf5-parallel
	module load cray-netcdf-hdf5parallel
}

fancy_print(){
	# More noticeable printing to stdout
	echo "  ***"
	echo "  | >>>>>>>>>>>> $1"
	echo "  ***"
}

build_xios_archer() {
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
	cp $ARCH_DIR/* ./nemo/arch
	cd xios
	
	# Compile XIOS
	fancy_print " Compiling XIOS"
	./make_xios --full --prod --arch archer --netcdf_lib netcdf4_par --job 4
}

build_nemo_archer() {

}

recompile_nemo_archer(){

}

# This thing allows for the above functions to be called externally
"$@"