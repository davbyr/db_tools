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

function build_xios() {
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

function checkout_nemo(){

	while :; do
		case $1 in
			-o|--out_dir)
				out_dir=$2
				shift
				;;
			-v|--version)
				version=$2
				shift
				;;
			--)
				shift
				break
				;;
			*)
				break
		esac
		shift
	done

	# Download NEMO source code
	fancy_print 'Checking out NEMO code..'
    svn co http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r$version --depth empty $out_dir
	svn co http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r$version/src --depth infinity $out_dir/src
	svn co http://forge.ipsl.jussieu.fr/nemo/svn/utils/build/mk $out_dir/mk
	svn co http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r$version/cfgs/SHARED $out_dir/cfgs/SHARED
	svn export http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r4.0.2/cfgs/ref_cfgs.txt $out_dir/cfgs/ref_cfgs.txt
	svn co http://forge.ipsl.jussieu.fr/nemo/svn/vendors/FCM $out_dir/ext/FCM
	svn co http://forge.ipsl.jussieu.fr/nemo/svn/vendors/IOIPSL $out_dir/ext/IOIPSL
	svn export http://forge.ipsl.jussieu.fr/nemo/svn/utils/build/makenemo $out_dir/makenemo	
}

function compile_new_config(){

	while :; do
		case $1 in
			-n|--nemo_dir)
				nemo_dir=$2
				shift
				;;
			-x|--xios_dir)
				xios_dir=$2
				shift
				;;
			-c|--cfg_name)
				cfg_name=$2
				shift
				;;
			-a|--arch_file)
				arch_file=$2
				shift
				;;
			-b|--arch_name)
				arch_name=$2
				shift
				;;
			-m|--my_src)
				my_src=$2
				shift
				;;
			-p|--cpp_file)
				cpp_file=$2
				shift
				;;
	                --)
                                shift
                                break
                                ;;
                        *)
                                break
		esac
		shift
	done
	
	export work_cfgs="OCE TOP"
    export cfg_dir=$nemo_dir/cfgs/$cfg_name

	# Load modules
	load_modules_archer
	
	fancy_print 'Making some necessary directories..'
	if [ ! -d "$cfg_dir" ]; then
                mkdir "$cfg_dir"
        fi
	if [ ! -d "$nemo_dir/arch" ]; then
                mkdir "$nemo_dir/arch"
        fi
	if [ ! -d "$cfg_dir/MY_SRC" ]; then
                mkdir "$cfg_dir/MY_SRC"
        fi
        
    fancy_print 'Copying files to config'
	cp $arch_file $nemo_dir/arch 
	cp $cpp_file $cfg_dir
	
	# Create work_cfgs file
	echo "$cfg_name $work_cfgs" > $nemo_dir/cfgs/work_cfgs.txt

	# Set XIOS directory in arch file
	export replace_line="%XIOS_HOME           ${xios_dir}"
	sed -i "s|^%XIOS_HOME.*|${replace_line}|" "$nemo_dir/arch/arch-${arch_name}.fcm"
	
	# Move MY_SRC files
	cp $my_src/* $cfg_dir/MY_SRC

	# Compile NEMO
	cd $nemo_dir
    fancy_print "Compiling NEMO $cfg_name Config"
	fancy_print "./makenemo -m $arch_name -r $cfg_name -j 10"
    ./makenemo -m $arch_name -r $cfg_name -j 10
}

function build_config_from_repo() {
		while :; do
		case $1 in
			-n|--nemo_dir)
				nemo_dir=$2
				shift
				;;
			-r|--repo_dir)
				repo_dir=$2
				shift
				;;
			-x|--xios_dir)
				xios_dir=$2
				shift
				;;
			-c|--cfg_name)
				cfg_name=$2
				shift
				;;
			-b|--arch_name)
				arch_name=$2
				shift
				;;
			-v|--version)
				version=$2
				shift
				;;
	                --)
                                shift
                                break
                                ;;
                        *)
                                break
		esac
		shift
	done
	
	$arch_file="$repo_dir/arch/arch-${arch_name}.fcm"
	$my_src="$repo_dir/MY_SRC"
	$cpp_file="$repo_dir/cpp_${cfg_name}.fcm"
	
	checkout_nemo $nemo_dir $version
	
	compile_new_config -n $nemo_dir -x $xios_dir -c co9-amm15 -a $arch_file -b $arch_name \
					   -m $my_src -p $cpp_file
}


# This thing allows for the above functions to be called externally
"$@"
