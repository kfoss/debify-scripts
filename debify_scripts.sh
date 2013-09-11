#!/bin/bash
#############################################################################
## default values
#############################################################################
package_author_name=`whoami`
package_author_email=`hostname`
package_architecture=`dpkg --print-architecture`
package_version=1.0

#############################################################################
## helper functions
#############################################################################
# check if system installed given package
# format: is_installed PACKAGE
function is_installed(){
  local __package="$1"
  for __package; do
      dpkg -s "$__package" >/dev/null 2>&1 && {
          return 0
      } || {
          return
      }
  done
}


# set a variable with a given value
# format: variable_set VARIABLE VALUE
function variable_set(){
  local __var=$1
  local __val=$2
  eval $__var="'$__val'"
  echo "set ${__var}=${__val}"
}


# get or set a given variable with a given input and default fallback
# format: variable_get_or_set VARIABLE DEFAULT [INPUT]
function variable_get_or_set(){
  local __var=$1
  local __default=$2
  local __input=$3

  if [ "$__input" != "" ]; then
    variable_set $__var "$__input"
  else
    variable_set $__var "$__default"
  fi
}


# find_max_version
# format find_max_version VARIABLE DIRECTORY [NUMBER]
function find_max_version(){
  local __var=$1
  local __dir=$2
  local __num=$3

  # set iteration number if not given
  if [ "$__num" == "" ];then __num=1; fi

  # return directory
  if [ ! -e "$__dir-$__num.deb" ]; then
    variable_set $__var $__num
  else
    find_max_version $__var $__dir $[__num+1]
  fi
}


# notify the user
function notify_user(){
  local __msg=$1

  if is_installed zenity; then
    zenity --info --text "$__msg" &
  else
    echo "$__msg"
  fi
}

# ask the user a question
function ask_user(){
  local __msg=$1
    if [ $install_messages_command_line_only == false ] && is_installed zenity; then
    zenity --question --text "$__msg"
  else
    # read in variable with default value
    echo -e "$__msg [Yn]"
    read __confirm
    [ -z "$__confirm" ] && __confirm="Y"

    if [ "$__confirm" == "Y" ]; then
      return 0
    elif [ "$__confirm" == "n" ]; then
      return 1
    else
      ask_user $__msg
    fi
  fi
}

# notify and wait for user confirmation before continuing
function notify_and_wait(){
  local __msg=$1
  notify_user "$__msg"

  ask_user "Ready to continue?"
  if [ "0" -ne "$?" ]; then
    notify_and_wait $__msg
  fi
}

# notify and wait for user confirmation before continuing
function ask_to_proceed(){
  local __msg=$1
  ask_user $__msg

  if [ "0" -eq "$?" ]; then
    return 0
  else
    return
  fi
}

# notify and continue without waiting for user confirmation
function notify_without_waiting(){
  local __msg=$1
  notify_user "$__msg"
}
#############################################################################
## run
#############################################################################
# get user input
msg_usage="Usage: $0 [-v version] [-d description] [-n author_name] [-e author_email] repo/file"
while getopts :n:e:v:d:h option
do
  case "${option}"
  in
    n) package_author_name=${OPTARG};;
    e) package_author_email=${OPTARG};;
    v) package_version=${OPTARG};;
    d) package_description=${OPTARG};;
    h) notify_without_waiting "${msg_usage}";exit;;
  esac
done
shift $(($OPTIND - 1))


# configure input/ouput dirs
input_file=$1
if [ -z "$input_file" ]; then
  notify_without_waiting $msg_usage
  exit
fi
input_dir=$(dirname $(realpath $input_file))
input_repo=$(basename $input_dir)
dir_output="$input_dir/deb"
variable_get_or_set package_description "${input_repo}_${package_version}" "$package_description"


# create output dir
mkdir --parents $dir_output


# calculate the new iteration
find_max_version package_iteration "$dir_output/${input_repo}_${package_version}"


# create a directory shell for the new iteration
dir_output_iteration="$dir_output/${input_repo}_${package_version}-${package_iteration}"
mkdir --parents "$dir_output_iteration/DEBIAN"
mkdir --parents "$dir_output_iteration/tmp"


# setup script/directory to install in /tmp (use rsync to exclude deb directory)
rsync --archive --exclude='deb' --exclude='.git' $input_dir "$dir_output_iteration/tmp"


# create control configuration file
sh -c "echo '\
Package: $input_repo
Version: ${package_version}-${package_iteration}
Section: base
Priority: optional
Architecture: $package_architecture
Depends: realpath
Maintainer: $package_author_name <$package_author_email>
Description: $package_description'\
> $dir_output_iteration/DEBIAN/control"


# setup script to run after dpkg using /tmp as its root directory
sh -c "echo '\
#!/bin/bash
# check if system installed given package
# format: is_installed PACKAGE
function is_installed(){
  local __package=\"\$1\"
  for __package; do
      dpkg -s \"\$__package\" >/dev/null 2>&1 && {
          return 0
      } || {
          return
      }
  done
}

# notify the user
function notify_user(){
  local __msg=\$1

  if is_installed zenity; then
    nohup zenity --info --text \"\$__msg\" >/dev/null 2>&1 &
  else
    echo -e \"\$__msg\"
  fi
}

chmod a+x \"/tmp/$input_repo/$input_file\"
__msg_user=\"\\\n\\\n-----------------------------------------------------------------\\\n\"
__msg_user=\"\${__msg_user}Queued package '\''$input_repo'\'' for installation:\\\n\"
__msg_user=\"\${__msg_user}     - It is now \`date\`\\\n\"
__msg_prog=\$(echo \"nohup bash -c /tmp/$input_repo/$input_file 1> /tmp/$input_repo/install.log 2>&1\" | at now + 1 min  2>&1 | tail -n 1)
__msg_user=\"\${__msg_user}     - Queued \${__msg_prog}\\\n\"
__msg_user=\"\${__msg_user}     - Installation log set to /tmp/$input_repo/install.log\\\n\"
__msg_user=\"\${__msg_user}-----------------------------------------------------------------\"
notify_user \"\$__msg_user\"'\
> $dir_output_iteration/DEBIAN/postinst"
chmod 0755 "$dir_output_iteration/DEBIAN/postinst"
sed --in-place "s/DIR_SCRIPT_ROOT\=.*$/DIR_SCRIPT_ROOT=\"\/tmp\/$input_repo\"/g" "$dir_output_iteration/DEBIAN/postinst"


# build the package and copy it to the current version for direct-link download
dpkg-deb --build "$dir_output/${input_repo}_${package_version}-${package_iteration}"
chmod a+x "$dir_output/${input_repo}_${package_version}-${package_iteration}.deb"
cp "$dir_output/${input_repo}_${package_version}-${package_iteration}.deb" "$dir_output/${input_repo}_current.deb"


# cleanup and alert complete
rm --recursive "$dir_output/${input_repo}_${package_version}-${package_iteration}"
notify_without_waiting "Package $input_repo (${input_repo}_${package_version}-${package_iteration}) Built"
