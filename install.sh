#!/bin/bash
#############################################################################
## install variables
#############################################################################
package_name="debify-scripts"
package_script="debify_scripts.sh"
dir_install="/usr/local"

# set directory depending on whether installing from command line or .deb
package_dir=""
current_dir=$(basename $(dirname $(realpath $0)))
if [ "$current_dir" == "$package_name" ]; then
  package_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
  package_dir="/tmp/$package_name"
fi


#############################################################################
## install
#############################################################################
# verify installation run as root
if [ "$(whoami)" != "root" ]; then
  echo "You must run `basename $0` as root"
  exit
fi

# copy script to home directory
mkdir --parents "$dir_install/scripts"
cp "$package_dir/$package_script" "$dir_install/scripts"
chmod 0755 "$dir_install/scripts/$package_script"
sudo ln --symbolic "$dir_install/scripts/$package_script" "/usr/bin/$package_name"
