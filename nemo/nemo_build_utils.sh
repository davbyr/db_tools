#!/bin/bash
# Functions for downloading, building and compiling NEMO
#
# To use a function in the terminal or inside another script, call the script followed
# by the desired function. e.g.
#
#		./nemo_build_tools build_xios_archer arg1 arg2
#
# See individual functions for more info on arguments.

function load_modules_archer() {
	# Loads modules for compiling NEMO and XIOS on ARCHER
	module swap PrgEnv-cray PrgEnv-intel
	module load cray-hdf5-parallel
	module load cray-netcdf-hdf5parallel
}

function fancy_print(){
	# More noticeable printing to stdout
	echo "  | >>>>>>>>>>>> $1"
}

function check_path_is_absolute(){
	export path_to_check=$1
	if [ ${path_to_check:0:1} != "/" ]; then
		fancy_print 'Exiting...'
		fancy_print 'Ensure all paths are absolute not relative.'
		fancy_print "$path_to_check is not."
		fancy_print "Try using \$PWD/$path_to_check."
		exit 1
	fi
}

function build_xios_archer() {
	# Downloads and compiles XIOS
	export out_dir=$1
	export repo_dir=$2
	export arch_name=$3

	check_path_is_absolute $out_dir
	check_path_is_absolute $repo_dir
	
	# Determine if desired output dir exists. If not, create it.
	if [ ! -d "$out_dir" ]; then
		mkdir "$out_dir"
	fi
	
	load_modules_archer

	fancy_print "Downloading and compiling XIOS in $xios_dir"

	# Checkout XIOS version
	fancy_print " Checkout XIOS repository"
	svn co http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/branchs/xios-2.5@1627 $out_dir
	
	# Get arch files and move them across to the fresh checkout
	export arch_files="arch-${arch_name}.*"
	cp $repo_dir/arch/xios/$arch_files $out_dir/arch
	cd $out_dir
	
	# Compile XIOS
	fancy_print " Compiling XIOS"
	./make_xios --full --prod --arch $arch_name --netcdf_lib netcdf4_par --job 4
}

function build_nemo_v4_archer() {
	# Downloads and compiles NEMO4
	export out_dir=$1
	export repo_dir=$2
	export arch_name=$3
	export cfg_name=$4
	export xios_dir=$5 

	check_path_is_absolute "$out_dir"
	check_path_is_absolute "$repo_dir"
	check_path_is_absolute "$xios_dir"

	export work_cfgs="OCE TOP"
        export version="4.0.2"

        export arch_file="arch-${arch_name}.fcm"
        export arch_dir=$out_dir/arch
        export cfg_dir=$out_dir/cfgs/$cfg_name
	
	# Load modules
	load_modules_archer
	
	# Download NEMO source code
        #export svn_url="http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r${version}"
	#svn co $svn_url $out_dir
	fancy_print 'Checking out NEMO code..'
        svn co http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r$version --depth empty $out_dir
	svn co http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r$version/src --depth infinity $out_dir/src
	svn co http://forge.ipsl.jussieu.fr/nemo/svn/utils/build/mk $out_dir/mk
	svn co http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r$version/cfgs/SHARED $out_dir/cfgs/SHARED
	svn export http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r4.0.2/cfgs/ref_cfgs.txt $out_dir/cfgs/ref_cfgs.txt
	svn co http://forge.ipsl.jussieu.fr/nemo/svn/vendors/FCM $out_dir/ext/FCM
	svn co http://forge.ipsl.jussieu.fr/nemo/svn/vendors/IOIPSL $out_dir/ext/IOIPSL
	svn export http://forge.ipsl.jussieu.fr/nemo/svn/utils/build/makenemo $out_dir/makenemo	

	# Make directories (or try to)
	fancy_print 'Making some necessary directories..'
	if [ ! -d "$cfg_dir" ]; then
                mkdir "$cfg_dir"
        fi
	if [ ! -d "$arch_dir" ]; then
                mkdir "$arch_dir"
        fi
	if [ ! -d "$cfg_dir/MY_SRC" ]; then
                mkdir "$cfg_dir/MY_SRC"
        fi

	# Move arch files to where they need to be	
	fancy_print 'Copying files from repository to config'
	cp $repo_dir/arch/nemo/$arch_file $out_dir/arch 
	cp $repo_dir/"cpp_${cfg_name}.fcm" $cfg_dir
	
	# Create work_cfgs file
	echo "$cfg_name $work_cfgs" > $out_dir/cfgs/work_cfgs.txt

	# Set XIOS directory in arch file
	export xios_line="%XIOS_HOME           ${xios_dir}"
	sed -i "s|^%XIOS_HOME.*|${xios_line}|" $arch_dir/$arch_file
	
	# Move MY_SRC files
	cp $repo_dir/MY_SRC/* $cfg_dir/MY_SRC

	# Compile NEMO
	cd $out_dir
        fancy_print "Compiling NEMO $cfg_name Config"
	fancy_print "./makenemo -m $arch_name -r $cfg_name -j 10"
        ./makenemo -m $arch_name -r $cfg_name -j 10
}


# This thing allows for the above functions to be called externally
"$@"
