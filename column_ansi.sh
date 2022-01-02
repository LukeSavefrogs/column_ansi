#!/bin/env bash

# @description:    Perl version of column2 which works with color codes and is way faster than the bash version
# @author:         Luca Salvarani
# @source:         https://stackoverflow.com/a/38762316/8965861
column_ansi () {
	(
		local __name="${FUNCNAME[0]}";
		local __version="1.2.0";

		__main () {
			local _input_separator=" ";
			local _output_separator="  ";
			local _align_right="  ";
			local _align_center="  ";

			# From this excellent StackOverflow answer: https://stackoverflow.com/a/14203146/8965861
			OPTIND=1;
			POSITIONAL=();
			while [[ $# -gt 0 ]]; do
				case $1 in
					-s | --separator)
						_input_separator="$2";
						shift 2;
					;;
					-o | --output-separator)
						_output_separator="$2";
						shift 2;
					;;
					-R | --table-right)
						_align_right="$2";
						shift 2;
					;;
					-C | --table-center)
						_align_center="$2";
						shift 2;
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
						shift;
					;;
				esac;
			done;
			[[ ${#POSITIONAL[@]} -gt 0 ]] && set -- "${POSITIONAL[@]}";

			export PCOLUMN_INPUT_SEPARATOR="${_input_separator}";
			export PCOLUMN_OUTPUT_SEPARATOR="${_output_separator}";
			export PCOLUMN_ALIGN_RIGHT="${_align_right}";
			export PCOLUMN_ALIGN_CENTER="${_align_center}";

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

				# Environment variables used by the program
				my $INPUT_SEPARATOR = $ENV{"PCOLUMN_INPUT_SEPARATOR"};
				my $OUTPUT_SEPARATOR = $ENV{"PCOLUMN_OUTPUT_SEPARATOR"};
				my $ALIGN_RIGHT = $ENV{"PCOLUMN_ALIGN_RIGHT"};
				my $ALIGN_CENTER = $ENV{"PCOLUMN_ALIGN_CENTER"};

				# Default values for INPUT_SEPARATOR and OUTPUT_SEPARATOR
				if ($INPUT_SEPARATOR eq ""){
					$INPUT_SEPARATOR = " "
				}
				if ($OUTPUT_SEPARATOR eq ""){
					$OUTPUT_SEPARATOR = "  "
				}

				# ALIGN_RIGHT must be a single number or a comma-separated list of numbers
				# Then split ALIGN_RIGHT into an array and then convert it to an hash that will be used to check
				#   if the column needs to be aligned to the right
				$ALIGN_RIGHT =~ s/^\s+|\s+$//g;
				if ($ALIGN_RIGHT ne "" && not $ALIGN_RIGHT =~ /^[0-9]+(,[0-9]+)*$/) {
					print STDERR "error: undefined column name '\''$ALIGN_RIGHT'\''\n";
					exit 1;
				}
				my %ALIGN_RIGHT_HASH = map {$_ - 1 => 1} split(/,/, $ALIGN_RIGHT);
				
				
				# ALIGN_CENTER must be a single number or a comma-separated list of numbers
				# Then split ALIGN_CENTER into an array and then convert it to an hash that will be used to check
				#   if the column needs to be aligned to the right
				$ALIGN_CENTER =~ s/^\s+|\s+$//g;
				if ($ALIGN_CENTER ne "" && not $ALIGN_CENTER =~ /^[0-9]+(,[0-9]+)*$/) {
					print STDERR "error: undefined column name '\''$ALIGN_CENTER'\''\n";
					exit 1;
				}
				my %ALIGN_CENTER_HASH = map {$_ - 1 => 1} split(/,/, $ALIGN_CENTER);

				# Save the STDIN into an Array, so that we can loop over it multiple times
				my @stdin = <STDIN>;
				my $column_widths = [];

				# First loop: get the width of each column and save it in an array
				foreach my $line (@stdin) {
					$line =~ s/\r?\n?$//;
					my @columns = split(/\Q$INPUT_SEPARATOR/, $line);
					my $column_index = 0;

					foreach my $column (@columns) {
						$column = trim_ansi($column);

						if (!defined $column_widths->[$column_index]) {
							$column_widths->[$column_index] = 0;
						}

						if ($column_widths->[$column_index] < length($column)) {
							$column_widths->[$column_index] = length($column);
						}
						$column_index++;
					}
				}

				# Second loop: print the columns
				foreach my $line (@stdin) {
					$line =~ s/\r?\n?$//;
					my @columns = split (/\Q$INPUT_SEPARATOR/, $line);
					my $column_index = 0;

					foreach my $column (@columns) {
						my $__current_column_length = length(trim_ansi($column));
						my $__current_column_padding = $column_widths->[$column_index] - $__current_column_length;
						
						if (exists $ALIGN_RIGHT_HASH{$column_index}) {
							print(" " x $__current_column_padding);
							print($column);
						} elsif (exists $ALIGN_CENTER_HASH{$column_index}) {
							my $__left_padding = int($__current_column_padding / 2);
							my $__right_padding = $__current_column_padding - $__left_padding;
							print(" " x $__left_padding);
							print($column);
							print(" " x $__right_padding);
						} else {
							print($column);
							print(" " x $__current_column_padding);
						}
						
						if ($column_index != $#columns) {
							print($OUTPUT_SEPARATOR);
						}
						$column_index++;
					}
					print("\n");
				}
			' || return 1;


			unset PCOLUMN_INPUT_SEPARATOR;
			unset PCOLUMN_OUTPUT_SEPARATOR;
			unset PCOLUMN_ALIGN_RIGHT;
			unset PCOLUMN_ALIGN_CENTER;
		}

		# shellckeck disable=SC2059
		__usage () {
			local -r __indent_1=$'\t';
			local -r __indent_2=$'\t\t';
			local -r __indent_3=$'\t\t\t';
			
			local -r __bold="\033[1m";
			local -r __underlined="\033[4m";
			local -r __yellow="\033[0;33m";
			local -r __red="\033[0;31m";
			local -r __green="\033[0;32m";
			local -r __reset="\033[0m";
			
			printf "${__bold}NAME${__reset}:\n";
			printf "${__indent_1}${__bold}%s${__reset} - Columnate lists (Perl version w/support for color codes)\n" "${__name}";
			printf "\n";
			
			printf "${__bold}USAGE${__reset}:\n"
			printf "${__indent_1}${__yellow}%s${__reset} [-s ${__underlined}SEPARATOR${__reset}] [-o ${__underlined}SEPARATOR${__reset}] [-R ${__underlined}COLUMNS${__reset}] [-C ${__underlined}COLUMNS${__reset}]\n" "${__name}";
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
			printf "${__indent_1}${__red}-C${__reset} ${__underlined}COLUMNS${__reset}, ${__red}--table-center${__reset} ${__underlined}COLUMNS${__reset}\n";
			printf "${__indent_2}Center align text in the specified columns (comma-separated).\n";
			printf "${__indent_2}This option is not present in the original column command.\n";
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

# If script is NOT being sourced, then start the column_ansi function
# Source: https://stackoverflow.com/a/28776166/8965861
if ! (return 0 2>/dev/null); then
	column_ansi "$@";
fi
