#!/bin/bash 

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )";
CONFIG_LOCATION="$DIR/config.txt";
TEMPLATE_LOCATION="$DIR/bin/template";

scheduler_enable="true";
scheduler_backupTime="23:59:59";
export_location="./tmp";
export_retainFiles="5";
export_compress="true";
main_dumperTool="mydumper";
mysqldump_options="";
mydumper_options="";


# https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
trim_result=""
trim() {
	trim_result=""

    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    trim_result="$var"
}


# check required program
checkMydumper() {
	if [ -z "$(command -v mydumper)" ]; then
		printf "Command mydumper is not found, you can read the installation instructions at https://mydumper.github.io/mydumper/docs/html/installing.html\n";
		exit 0;
	fi
}

checkMysqldump() {
	if [ -z "$(command -v mysqldump)" ]; then
		printf "Command mysqldump is not found, you can install it first\n";
		exit 0;
	fi
}

# parse config file
parseConfigFile(){
	if [ ! -f "$CONFIG_LOCATION" ]; then
		cp "$TEMPLATE_LOCATION/config.txt" "$CONFIG_LOCATION";
		printf "Please edit $CONFIG_LOCATION first!\n";
		printf "For more information, you can check https://github.com/mydumper/mydumper\n";
		exit 0;
	fi

	local fileContents="$(cat "$CONFIG_LOCATION")";
	local schedulerConfig="$( echo "$fileContents" | awk '/\[scheduler\]/{f=1} /^$/{f=0;print} f' )";
	trim "$( echo "$schedulerConfig" | grep 'enable' | cut -f2- -d'=' )";
	scheduler_enable="$trim_result";
	trim "$( echo "$schedulerConfig" | grep 'backupTime' | cut -f2- -d'=' )";
	scheduler_backupTime="$trim_result";

	local exportConfig="$( echo "$fileContents" | awk '/\[export\]/{f=1} /^$/{f=0;print} f' )";
	trim "$( echo "$exportConfig" | grep 'location' | cut -f2- -d'=' )";
	export_location="$trim_result";
	trim "$( echo "$exportConfig" | grep 'retainFiles' | cut -f2- -d'=' )";
	export_retainFiles="$trim_result";
	trim "$( echo "$exportConfig" | grep 'compress' | cut -f2- -d'=' )";
	export_compress="$trim_result";

	local mainConfig="$( echo "$fileContents" | awk '/\[main\]/{f=1} /^$/{f=0;print} f' )";
	trim "$( echo "$mainConfig" | grep 'dumperTool' | cut -f2- -d'=' )";
	main_dumperTool="$trim_result";

	local mydumperConfig="$( echo "$fileContents" | awk '/\[mydumper\]/{f=1} /^$/{f=0;print} f' )";
	trim "$( echo "$mydumperConfig" | grep 'options' | cut -f2- -d'=' )";
	mydumper_options="$trim_result";

	local mysqldumpConfig="$( echo "$fileContents" | awk '/\[mysqldump\]/{f=1} /^$/{f=0;print} f' )";
	trim "$( echo "$mysqldumpConfig" | grep 'options' | cut -f2- -d'=' )";
	mysqldump_options="$trim_result";
}

filterDumpDirectory(){
	local fileNames=($DIR/$export_location/*)
	local countFile=${#fileNames[@]}

	for ((i=countFile - 1,j=0;i>=0;i--,j++)); do
   		if [[ $j -ge $export_retainFiles ]]
   		then
        	rm -r "${fileNames[$i]}"
   		fi
	done
}

backup(){

	mkdir -p "$DIR/$export_location"

	local filename="export-$(date "+%Y%m%d_%H%M%S")"

	if [ "$main_dumperTool" == "mydumper" ]; then

		checkMydumper

		if [ "$export_compress" == "true" ]; then
			mydumper --defaults-file "$CONFIG_LOCATION" -o "$DIR/$export_location/$filename" -c $mydumper_options
		else
			mydumper --defaults-file "$CONFIG_LOCATION" -o "$DIR/$export_location/$filename" $mydumper_options
		fi
	fi

	if [ "$main_dumperTool" == "mysqldump" ]; then
		checkMysqldump

		if [ "$export_compress" == "true" ]; then
			mysqldump $mysqldump_options | xz -c > "$DIR/$export_location/$filename.sql.xz"
		else
			mysqldump $mysqldump_options > "$DIR/$export_location/$filename.sql"
		fi
	fi

	filterDumpDirectory

	echo "BACKUP AT $(date "+%Y-%m-%d %H:%M:%S")"
}

loop(){

	if [ "$scheduler_enable" != "true" ]; then
		exit 0
	fi

	while true
	do
		currentTime="$(date "+%T")"

		IFS=',' read -ra backupTimes <<< "$scheduler_backupTime"
		for backupTime in "${backupTimes[@]}"; do

			if [ "$currentTime" == "$backupTime" ]; then
				backup
			fi
		done

		sleep 1
	done
}


# ================== MAIN ======================
parseConfigFile
backup
loop
