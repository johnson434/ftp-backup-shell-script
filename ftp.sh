#! /bin/bash

# logging setting
LOGFILE="log.log"
if [ ! -f ./log.log ]; then
	touch log.log
fi

exec 3>&1 1>"$LOGFILE" 2>&1
trap "echo 'ERROR: An error occurred during execution, check log $LOGFILE for details.' >&3" ERR
trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG

declare -a directories=()
declare -a files=()

function read_directories {
	while read -r directory
	do
		directories+=($directory)
	done < SYNC_DIRECTORIES
}

function get_file_list() {
	while ((${#directories[@]} != 0)); do
		local current_directory=${directories[0]}
		directories=("${directories[@]:1}")

		# Add current_directory files.
		cd $current_directory
		if [ $? -ne 0 ]; then
			echo "fail to move to $current_directory folder."
			continue
		fi

		readarray -d '' file_names < <(find . -maxdepth 1 -type f -print0)
		for file_name in "${file_names[@]}"; do
			files+=("${current_directory}/${file_name#./}")
		done

		# Add next searching directory
		local dir=$(ls -d */)
		local next_directories=("${dir%/*}")

		if [ $? -eq 0 ]; then
			for next_directory in ${next_directories[@]}; do
				directories+=("${current_directory}/${next_directory%/}")
			done
		fi
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
	readonly local SERVER
	readonly local USER_NAME
	readonly local PASSWORD

	while IFS="=" read -r key value; do
		case "$key" in
			"SERVER") SERVER="$value" ;;
			"USER_NAME") USER_NAME="$value" ;;
			"PASSWORD") PASSWORD="$value" ;;
		esac
	done < FTP_SETTING

	if [ $? -ne 0 ]; then
		return -1
	fi

	pwd
	ls -al
	echo $(pwd)

	echo "SERVER: $SERVER USER_NAME: $USERN_NAME\n PASSWORD: $PASSWORD"
	
	ftp -inv $SERVER <<EOF
		user $USER_NAME $PASSWORD
		binary

		!(for f in "${files[@]}"; do cd /HDD1; ls -al; done)
#
#	for f in "${files[@]}"; do		
#		cd /HDD1
#		ls -al
#
#		file_full_name="$f"
#		file_directory="${file_full_name}${f%/*}"
#		lcd $file_directory
#		lpwd
#
#		file_name="${file_full_name##*/}"
#
#		IFS='/' read -ra DEST <<< "$file_directory"
#		for folder_name in "${DEST[@]}"; do
#			mkdir $folder_name
#			cd $folder_name
#			pwd
#		done
#
#		put $file_name
#	done
#
bye
EOF

}

read_directories
echo "read_directories_result: ${directories[@]}"

get_file_list
echo "get_file_list_result : ${files[@]}"

backup_file_by_ftp
