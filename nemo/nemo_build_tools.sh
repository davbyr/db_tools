#!/bin/bash
# General utility functions used for building NEMO and XIOS
#
# To use a function in the terminal or inside another script, call the script followed
# by the desired function. e.g.
#
#		./nemo_build_tools fancy_print arg1 arg2
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

# This thing allows for the above functions to be called externally
"$@"