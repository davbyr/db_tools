#!/bin/bash
#
# Bash script for using svn to checkout NEMO code on ARCHER.
# Variables defined at the top of the script may be changed.

#********* ARGUMENTS *********

# out_dir | Where to checkout NEMO code. If it doesn't exist it will be created.
# url     | Base URL to use for downloading NEMO. 
#         |    e.g. 'http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r4.0.1'

out_dir='./'  
url='http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r4.0.1'




#********* SCRIPT *********

module load svn

# Download NEMO source code
svn co '$url'