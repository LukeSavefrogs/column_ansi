#!/bin/env bash
# **********************************************************************************
#                                                                                                                                                                    *
# Description:
#   Bash wrapper around `column_ansi.pl`, which provides the following features:
#   - better CLI help output (colors + formatting)
#   - support for CLI parameters (`--help`)
#                                                                                                                                                                    *
# **********************************************************************************


# @description: Perl version of column2 which works with color codes and is way faster than the bash version
# @author:      Luca Salvarani
# @source:      https://stackoverflow.com/a/38762316/8965861
# @git:         https://github.com/LukeSavefrogs/column_ansi
column_ansi ()
{
	(
		local __name="${FUNCNAME[0]}";
		local __version="1.4.0";

		# shellcheck disable=SC2155,SC2164
		local __script_path="";
		
		if [[ -n "${COLUMN_ANSI_PLSCRIPT_PATH:-}" ]]; then
			__script_path="${COLUMN_ANSI_PLSCRIPT_PATH}/";
		fi

		__main () {
			local _input_separator=" ";
			local _output_separator="  ";
			local _align_right="  ";
			local _align_center="  ";
			local _hidden_columns="0";

			# From this excellent StackOverflow answer: https://stackoverflow.com/a/14203146/8965861
			OPTIND=1;
			POSITIONAL=();
			while [[ $# -gt 0 ]]; do
				case $1 in
					-s | --separator)
						_input_separator="$2";
						shift 2 || return 1;
					;;
					-o | --output-separator)
						_output_separator="$2";
						shift 2 || return 1;
					;;
					-R | --table-right)
						_align_right="$2";
						shift 2 || return 1;
					;;
					-C | --table-center)
						_align_center="$2";
						shift 2 || return 1;
					;;
					-H | --table-hide)
						_hidden_columns="$2";
						shift 2 || return 1;
					;;
					-t | --table)     # Does nothing - Only for compatibility reasons
						shift;
					;;
					-\? | -h |--help)
						__usage
						return 0;
					;;
					*)
						POSITIONAL+=("$1");
						shift || return 1;
					;;
				esac;
			done;
			[[ ${#POSITIONAL[@]} -gt 0 ]] && set -- "${POSITIONAL[@]}";

			export PCOLUMN_INPUT_SEPARATOR="${_input_separator}";
			export PCOLUMN_OUTPUT_SEPARATOR="${_output_separator}";
			export PCOLUMN_ALIGN_RIGHT="${_align_right}";
			export PCOLUMN_ALIGN_CENTER="${_align_center}";
			export PCOLUMN_HIDDEN_COLUMNS="${_hidden_columns}";

			# Call the actual Perl program
			perl "${__script_path}column_ansi.pl" || return 1;


			unset PCOLUMN_INPUT_SEPARATOR;
			unset PCOLUMN_OUTPUT_SEPARATOR;
			unset PCOLUMN_ALIGN_RIGHT;
			unset PCOLUMN_ALIGN_CENTER;
			unset PCOLUMN_HIDDEN_COLUMNS;
		}

		# shellckeck disable=SC2059
		__usage () {
			local -r __indent_1=$'\t';
			local -r __indent_2=$'\t\t';
			local -r __indent_3=$'\t\t\t';
			
			local -r __bold="\033[1m";
			local -r __underlined="\033[4m";
			local -r __striked="\033[9m";
			local -r __yellow="\033[0;33m";
			local -r __red="\033[0;31m";
			local -r __green="\033[0;32m";
			local -r __reset="\033[0m";
			
			printf "${__bold}NAME${__reset}:\n";
			printf "${__indent_1}${__bold}%s${__reset} - Columnate lists (Perl version w/support for color codes)\n" "${__name}";
			printf "\n";
			
			printf "${__bold}USAGE${__reset}:\n"
			printf "${__indent_1}${__yellow}%s${__reset} [-s ${__underlined}SEPARATOR${__reset}] [-o ${__underlined}SEPARATOR${__reset}] [-R ${__underlined}COLUMNS${__reset}] [-H ${__underlined}COLUMNS${__reset}] [-C ${__underlined}COLUMNS${__reset}]\n" "${__name}";
			printf "${__indent_1}${__yellow}%s${__reset} --help\n" "${__name}";
			printf "\n";
			
			printf "${__bold}OPTIONS${__reset}:\n";
			printf "${__indent_1}${__red}-t${__reset}, ${__red}--table${__reset}\n";
			printf "${__indent_2}Does nothing, was left for compatibility reasons. [DEFAULT]\n";
			printf "\n";
			printf "${__indent_1}${__red}-s${__reset} ${__underlined}SEPARATOR${__reset}, ${__red}--separator${__reset} ${__underlined}SEPARATOR${__reset}\n";
			printf "${__indent_2}Specify the possible input item delimiters (default is whitespace).\n";
			printf "\n";
			printf "${__indent_1}${__red}-o${__reset} ${__underlined}SEPARATOR${__reset}, ${__red}--output-separator${__reset} ${__underlined}SEPARATOR${__reset}\n";
			printf "${__indent_2}Specify the columns delimiter for table output (default is two spaces).\n";
			printf "\n";
			printf "${__indent_1}${__red}-R${__reset} ${__underlined}COLUMNS${__reset}, ${__red}--table-right${__reset} ${__underlined}COLUMNS${__reset}\n";
			printf "${__indent_2}Right align text in the specified columns (comma-separated).\n";
			printf "\n";
			printf "${__indent_1}${__red}-H${__reset} ${__underlined}COLUMNS${__reset}, ${__red}--table-hide${__reset} ${__underlined}COLUMNS${__reset}\n";
			printf "${__indent_2}Don't print specified columns. ${__striked}The special placeholder '-' maybe be used to hide all unnamed columns (see --table-columns).${__reset}\n";
			printf "${__indent_2}${__bold}IMPORTANT${__reset}: The striked part of the description is still not implemented.\n";
			printf "\n";
			printf "${__indent_1}${__red}-C${__reset} ${__underlined}COLUMNS${__reset}, ${__red}--table-center${__reset} ${__underlined}COLUMNS${__reset}\n";
			printf "${__indent_2}Center align text in the specified columns (comma-separated).\n";
			printf "${__indent_2}${__bold}IMPORTANT${__reset}: This option is not present in the original column command.\n";
			printf "\n";
			printf "${__indent_1}${__red}-h${__reset}, ${__red}--help${__reset}\n";
			printf "${__indent_2}Display help text and exit.\n";
			printf "\n";
			
			printf "${__bold}BUGS${__reset}:\n"
			printf "${__indent_1}Luca Salvarani - lucasalvarani99@gmail.com\n"
			printf "\n"
			
			printf "${__bold}VERSION${__reset}:\n"
			printf "${__indent_1}%s\n" "${__version}"
			printf "\n"
		}

		__main "$@";
	)
}

# Check if the file is being sourced (source: https://stackoverflow.com/a/28776166/8965861)
if ! (return 0 2>/dev/null); then
	# If EXECUTED (no source):
	#    - Set the `COLUMN_ANSI_PLSCRIPT_PATH` env variable to the path of the executed script.
	#    - Execute the function.

	# shellcheck disable=SC2155,SC2164
	if [[ -z "${COLUMN_ANSI_PLSCRIPT_PATH:-}" ]]; then
		COLUMN_ANSI_PLSCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P )";
	fi

	# Make sure to export the `COLUMN_ANSI_PLSCRIPT_PATH` env variable even if it was not set already
	export COLUMN_ANSI_PLSCRIPT_PATH="${COLUMN_ANSI_PLSCRIPT_PATH:-}";

	column_ansi "$@";
else
	# If SOURCE'D:
	#    - Set the `COLUMN_ANSI_PLSCRIPT_PATH` environment variable to the path of the sourced file.

	# shellcheck disable=SC2155,SC2164
	if [[ -z "${COLUMN_ANSI_PLSCRIPT_PATH:-}" ]]; then
		COLUMN_ANSI_PLSCRIPT_PATH="$( cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1; pwd -P )";
	fi
	
	# Make sure to export the `COLUMN_ANSI_PLSCRIPT_PATH` env variable even if it was not set already
	export COLUMN_ANSI_PLSCRIPT_PATH="${COLUMN_ANSI_PLSCRIPT_PATH:-}";
fi
