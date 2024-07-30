#! /bin/bash

# logging setting
LOGFILE="log.log"
if [ ! -f ./log.log ]; then
	touch log.log
fi

exec 3>&1 1>"$LOGFILE" 2>&1
trap "echo 'ERROR: An error occurred during execution, check log $LOGFILE for details.' >&3" ERR
trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG

declare -a backup_directories=()
declare -a files=()

# Set script location
SCRIPT_FILE_LOCATION=$(realpath "$0")
SCRIPT_DIRECTORY=$(dirname "$SCRIPT_FILE_LOCATION")

function read_backup_directories {
	while read -r directory
	do
		backup_directories+=($directory)
	done < "$SCRIPT_DIRECTORY/SYNC_DIRECTORIES"
}

function get_file_list() {
	while ((${#backup_directories[@]} != 0)); do
		local current_directory=${backup_directories[0]}
		backup_directories=(${backup_directories[@]:1})
		# echo "current_directory: ${current_directory}"

		# Add current_directory files.
		cd $current_directory
		if [ $? -ne 0 ]; then
			echo "fail to move to $current_directory folder."
			continue
		fi

		readarray -d '' current_files < <(find . -type f -print0) 

		for ((i = 0; i < ${#current_files[@]}; i++)); do
			files+=("${current_directory}${current_files[i]#.}")
		done
	done
}

function copy_files_to_downloads() {
	for f in "${files[@]}"; do
		destination_directory="/home/john/Downloads/copy${f%/*}"
		# get the name of file.
		mkdir -p "$destination_directory"
		cp "$f" "$destination_directory" 
	done
}

function backup_file_by_ftp() {
	local SERVER
	local USER_NAME
	local PASSWORD

	# directory where saves the file
	local FTP_DIRECTORY

	while IFS="=" read -r key value; do
		echo "key: $key"
		case "$key" in
			"SERVER") SERVER="$value" ;;
			"USER_NAME") USER_NAME="$value" ;;
			"PASSWORD") PASSWORD="$value" ;;
			"FTP_DIRECTORY") FTP_DIRECTORY="$value"
		esac
	done < "$SCRIPT_DIRECTORY/FTP_SETTING"
	echo "SERVER: $SERVER USER_NAME: $USER_NAME\n PASSWORD: $PASSWORD"

	if [ -z $SERVER ]; then
		echo "Cann't find SERVER value in FTP_SETTING"
		return -1
	elif [ -z $USER_NAME ]; then
		echo "Cann't find USER_NAME value in FTP_SETTING"
		return -1
	elif [ -z $PASSWORD ]; then
		echo "Cann't find PASSWORD value in FTP_SETTING"
		return -1
	elif [ -z $FTP_DIRECTORY ]; then
		echo "Cann't find FTP_DIRECTORY value in FTP_SETTING"
		return -1
	fi
	
	ftp -inv "$SERVER" <<EOF
		user $USER_NAME $PASSWORD
		binary
		pwd

		$(for directory_name in ${!directory_map[@]}; do
				echo "cd /$FTP_DIRECTORY"

				IFS="/"
				read -ra array <<< "$directory_name"

				for ((i=0; i<${#array[@]}; i++)); do
					echo "mkdir ${array[i]}"
					echo "cd ${array[i]}"
				done
		done

		for (( i=0; i<${#files[@]}; i++ )); do
			echo "cd /$FTP_DIRECTORY"                           
      backup_directory=${pure_directory_name_of_files[i]}
			IFS="/"                                             
		                                                      	
		  echo "cd /$FTP_DIRECTORY$backup_directory"          	
		  echo "pwd"                                          	
      echo "lcd $backup_directory"
		                                                      	
		  f=${files[i]}
			f=${f##*/}
			f=\"$f\"
		  echo "put $f"
    done
		)
	bye
EOF
}

function substract_directory_from_files() {
	local -n file_directories=$1

	for f in "${files[@]}"; do
		file_directories+=("${f%/*}")
	done
}

function substract_file_name_from_files() {
	local -n file_names=$1

	for f in "${files[@]}"; do
		file_names+=("${f##*/}")
	done
}

read_backup_directories
get_file_list

declare -a pure_file_names=()
substract_file_name_from_files pure_file_names

declare -a pure_directory_name_of_files=()
substract_directory_from_files pure_directory_name_of_files

declare -A directory_map=()
for d in ${pure_directory_name_of_files[@]}; do
	directory_map["$d"]=true
done

#for ((i = 0; i < ${#pure_file_names[@]}; i++)); do
#	echo "pure_file_name: ${pure_file_names[i]}"
#	echo "pure_directory_nmae: ${pure_directory_name_of_files[i]}"
#done

backup_file_by_ftp
