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

function download_and_compile_xios() {
	while :; do
		case $1 in
			-o|--out_dir)
				out_dir=$2
				shift
				;;
			-a|--arch_dir)
				arch_dir=$2
				shift
				;;
			-b|--arch_name)
				arch_name=$2
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

	check_path_is_absolute $out_dir
	check_path_is_absolute $arch_dir
	
	# Determine if desired output dir exists. If not, create it.
	if [ ! -d "$out_dir" ]; then
		mkdir "$out_dir"
	fi
	
	load_modules_archer

	fancy_print "Downloading and compiling XIOS in $out_dir"

	# Checkout XIOS version
	fancy_print " Checkout XIOS repository"
	# Fixed version for now:
	svn co http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/branchs/xios-2.5@1627 $out_dir
	
	# Get arch files and move them across to the fresh checkout
	arch_files="arch-${arch_name}.*"
	cp $arch_dir/$arch_files $out_dir/arch
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

function compile_nemo_config(){

	while :; do
		case $1 in
			-h|--help|-\?)
				echo ' Compiles a NEMO configuration on ARCHER, new or existing. '
				echo ' '
				echo ' Flags:  -n, --nemo_dir   Full path to NEMO directory. '
				echo '         -x, --xios_dir   Full path to XIOS directory. '
				echo '         -c, --cfg_name   Name of the configuration to compile. '
				echo '         -b, --arch_name  Architecture name (arch-<arch_name>.fcm).'
				echo '         -a, --arch_file  [Optional] Full path to architecture file. '
				echo '         -m, --my_src     [Optional] Full path to MY_SRC directory to use. ' 
				echo '         -p, --cpp_file   [Optional] Full path to NEMO cpp flags file to use. '
				echo ' '
				echo ' If optional files are not provided, they will be assumed already present in '
				echo ' the NEMO directory. If specified paths do not exist, they will be created.'
				exit
				;;
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
	
	# Create work_cfgs file
	echo "$cfg_name $work_cfgs" > $nemo_dir/cfgs/work_cfgs.txt

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
    fancy_print "Compiling NEMO $cfg_name Config"
	fancy_print "./makenemo -m $arch_name -r $cfg_name -j 10"
    ./makenemo -m $arch_name -r $cfg_name -j 10
}

function build_config_from_repo() {
		while :; do
		case $1 in
			-h|--help)
				echo ' Downloads XIOS, NEMO and compiles using files from Github repo. '
				echo ' If code has already been downloaded for either XIOS or NEMO, use '
				echo ' --no_xios or --no_nemo flags to skip the download steps '
				echo ' '
				echo ' Flags:  -n, --nemo_dir   Full path to NEMO directory. '
				echo '         -x, --xios_dir   Full path to XIOS directory. '
				echo '         -x, --repo_dir   Full path to repository directory. '
				echo '         -c, --cfg_name   Name of the configuration to compile. '
				echo '         -b, --arch_name  Architecture name arch-<arch_name>.fcm.'
				echo '		   -v, --version    NEMO version to download. '
				echo '             --no_xios    Skip download and install of XIOS. '
				echo '			   --no_nemo	Skip download of NEMO but will still compile. '
				echo ' '
				echo ' Currently, arch_name is assumed to be the same for NEMO and XIOS. '
				echo ' Version only specifies the NEMO version to download. '
				exit
				;;
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
			--no_xios)
				no_xios=true
				shift
				;;
			--no_nemo)
				no_nemo=true
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
	
	if [ ! $no_xios ]; then
		download_and_compile_xios -o $xios_dir -a $repo_dir/arch/xios -b $arch_name
	fi
	
	if [ ! $no_nemo ]; then
		checkout_nemo $nemo_dir $version
	fi
	
	compile_new_config -n $nemo_dir -x $xios_dir -c co9-amm15 -a $arch_file -b $arch_name \
					   -m $my_src -p $cpp_file
}


# This thing allows for the above functions to be called externally
"$@"
