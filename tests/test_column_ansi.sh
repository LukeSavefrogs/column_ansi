#!/bin/env bash

# For the tests to work we need the function `column_ansi` available from the downloaded script.
# Sourcing won't execute the function 
source "../column_ansi.sh" || exit 1;

# @description:    Bash version of column (similar to the one from util-linux) which works with color codes
# @author:         NORMAN GEIST
# @source:         https://stackoverflow.com/a/38762316/8965861
function column2 () (
	#!/bin/bash
	which sed >> /dev/null || exit 1

	version=1.0b
	editor="Norman Geist"
	last="04 Jul 2016"

	# NOTE: Brilliant pipeable tool to format input text into a table by 
	# NOTE: an configurable seperation string, similar to column
	# NOTE: from util-linux, but we are smart enough to ignore 
	# NOTE: ANSI escape codes in our column width computation
	# NOTE: means we handle colors properly ;-)

	# BUG : none

	addspace=1
	seperator=$(echo -e " ")
	columnW=()
	columnT=()

	while getopts "s:hp:v" opt; do
	case $opt in
	s ) seperator=$OPTARG;;
	p ) addspace=$OPTARG;;
	v ) echo "Version $version last edited by $editor ($last)"; exit 0;;
	h ) echo "column2 [-s seperator] [-p padding] [-v]"; exit 0;;
	* ) echo "Unknow comandline switch \"$opt\""; exit 1
	esac
	done
	shift $(($OPTIND-1))

	if [ ${#seperator} -lt 1 ]; then
	echo "Error) Please enter valid seperation string!"
	exit 1
	fi

	if [ ${#addspace} -lt 1 ]; then
	echo "Error) Please enter number of addional padding spaces!"
	exit 1
	fi

	#args: string
	function trimANSI()
	{
	TRIM=$1
	TRIM=$(sed 's/\x1b\[[0-9;]*m//g' <<< $TRIM); #trim color codes
	TRIM=$(sed 's/\x1b(B//g'         <<< $TRIM); #trim sgr0 directive
	echo $TRIM
	}

	#args: len
	function pad()
	{
	for ((i=0; i<$1; i++))
	do 
	echo -n " "
	done
	}

	#read and measure cols
	while read ROW
	do
	while IFS=$seperator read -ra COLS; do
	ITEMC=0
	for ITEM in "${COLS[@]}"; do
	SITEM=$(trimANSI "$ITEM"); #quotes matter O_o
	[ ${#columnW[$ITEMC]} -gt 0 ] || columnW[$ITEMC]=0
	[ ${columnW[$ITEMC]} -lt ${#SITEM} ] && columnW[$ITEMC]=${#SITEM}
	((ITEMC++))
	done
	columnT[${#columnT[@]}]="$ROW"
	done <<< "$ROW"
	done

	#print formatted output
	for ROW in "${columnT[@]}"
	do
	while IFS=$seperator read -ra COLS; do
	ITEMC=0
	for ITEM in "${COLS[@]}"; do
	WIDTH=$(( ${columnW[$ITEMC]} + $addspace ))
	SITEM=$(trimANSI "$ITEM"); #quotes matter O_o
	PAD=$(($WIDTH-${#SITEM}))

	if [ $ITEMC -ne 0 ]; then
		pad $PAD
	fi

	echo -n "$ITEM"

	if [ $ITEMC -eq 0 ]; then
		pad $PAD
	fi

	((ITEMC++))
	done
	done <<< "$ROW"
	echo ""
	done
)

_trim_all_ANSI () {
	perl -e '
		use strict;
		use warnings;

		sub trim_ansi {
			my $__temp_string = $_[0];
			
			# Remove all Control Characters (color codes, carriage returns, bells and other characters)
			$__temp_string =~ s/ \e[ #%()*+\-.\/]. |
				\r | # Remove extra carriage returns also
				(?:\e\[|\x9b) [ -?]* [@-~] | # CSI ... Cmd
				(?:\e\]|\x9d) .*? (?:\e\\|[\a\x9c]) | # OSC ... (ST|BEL)
				(?:\e[P^_]|[\x90\x9e\x9f]) .*? (?:\e\\|\x9c) | # (DCS|PM|APC) ... ST
				\e.|[\x80-\x9f] //xg;
			1 while $__temp_string =~ s/[^\b][\b]//g;  # remove all non-backspace followed by backspace
			
			return $__temp_string
		}

		while (<STDIN>) {
			print (trim_ansi($_));
		}
	'
}

if [[ $# -eq 0 ]]; then
	SEPARATOR=":"
	string=$(
		printf "First column${SEPARATOR}Second${SEPARATOR}3rd column${SEPARATOR}\033[0;31mErrors\033[0m${SEPARATOR}Notes\n"; 
		printf "Test value${SEPARATOR}\033[1;35mColored output\033[0m${SEPARATOR}ABC${SEPARATOR}YES${SEPARATOR}Very long text\n";
	);
	sanitized_string="$(echo "${string}" | _trim_all_ANSI)"

 	string2="
Current Date Time    :  \t
ABC Reset            :  -- : \t
ABC Reboot           :  --  \t
Program Restart      :  -- : \t
\f_
\t
Last    System Reboot: -- : \t\n
Hostname             : dev-c1234some01 \tDevicename :
ABC Master Server    :  \tOut-Nummer :
Out Sync Protokoll   :  \tOS System  :
SSH Authentication   :  \tTimeserver :
IP-Address           :   \tGateway    :
Subnetmask           :  \tDNS        :
\t
Out-Server           :  \tMain  check:
System               :  \tABC Name   :
UEFI System Check    :         \tBootorder  :
System Up Time       :  \tRotation   :
";
	
	printf "\033[1mCOLUMN (Original):\033[0m\n";
	time echo "${string}" | column -t -s "${SEPARATOR}";
	printf "\n\n";


	printf "\033[1mCOLUMN (Original - Without ANSI):\033[0m\n";
	time echo "${sanitized_string}" | column -t -s "${SEPARATOR}";
	printf "\n\n";


	printf "\033[1mCOLUMN (Custom - @NORMAN GEIST):\033[0m\n";
	time echo "${string}" | column2 -s "${SEPARATOR}";
	printf "\n\n";


	printf "\033[1mCOLUMN (Custom - mine):\033[0m\n";
	time echo "${string}" | column_ansi -s "${SEPARATOR}";
	printf "\n\n";


	printf "\033[1mCOLUMN (Custom - mine): Empty Data without Ansi Codes\033[0m\n"
	time echo -e -n "${string2}" | column_ansi -t -s $'\t'
	printf "\n\n";
else
	# If script is NOT being sourced, then start the column_ansi function
	# Source: https://stackoverflow.com/a/28776166/8965861
	if ! (return 0 2>/dev/null); then
		column_ansi "$@";
	fi
fi
