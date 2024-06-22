#! /usr/bin/bash
readonly local SERVER="YOUR_FTP_SERVER_NAME"
readonly local USER_NAME="FTP_USER_NAME"
readonly local PASSWORD="FTP_USER_PASSWORD"

echo
echo "==sync start=="

declare -a directories=()
declare -a files=()

function read_directories {
	echo "$FUNCNAME"
	while read -r directory
	do
		directories+=($directory)
	done < sync_directories
}

function get_file_list() {
	echo "$FUNCNAME"
	while ((${#directories[@]} != 0)); do
		echo "================while start=============="
		local current_directory=${directories[0]}
		directories=("${directories[@]:1}")

		# Add current_directory files.
		cd $current_directory
		if [ $? -ne 0 ]; then
			echo "===========Fail to move to current_directory: $current_directory======="
			continue
		fi

		readarray -d '' file_names < <(find . -maxdepth 1 -type f -print0)
		for file_name in "${file_names[@]}"; do
			# echo "file_name: ${file_name%./}"
			files+=("${current_directory}/${file_name#./}")
		done

		# Add next searching directory
		echo "pwd: $(pwd)"
		local next_directories=($(ls -d */))
		if [ $? -eq 0 ]; then
			for next_directory in ${next_directories[@]}; do
				echo "next_directory: $next_directory"
				echo "current_directory: ${current_directory}"
				directories+=("${current_directory}/${next_directory%/}")
			done
		fi

		echo "directories: ${directories[@]}"
		echo "directories sizse: ${#directories[@]}"
		echo "================while ENd=============="
	done
}

function copy_files_to_downloads() {
	for f in "${files[@]}"; do
		destination_directory="/home/john/Downloads/copy${f%/*}"
		echo "destination_directory: $destination_directory"
		# get the name of file.
		mkdir -p "$destination_directory"
		cp "$f" "$destination_directory" 
	done
}

function backup_file_by_ftp() {	
	echo "function start: $FUNCNAME"
	
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
get_file_list
backup_file_by_ftp
