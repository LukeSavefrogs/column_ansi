#shellcheck shell=sh

# Must NOT quote the `$1` variable to allow variable expansion
#   and pass the correct parameters to the script.
#
# shellcheck disable=SC2086,SC2288

%const LIBRARY_PATH: src/column_ansi.sh
Include "${LIBRARY_PATH}"


# Custom matcher used to find a string inside of a text containing ANSI escape codes.
match_plain_text() {
	# Source: https://unix.stackexchange.com/a/18979/348102
	sanitized_text="$(echo "${match_plain_text:?}" | perl -e '
		while (<>) {
			s/ \e[ #%()*+\-.\/]. |
				\r | # Remove extra carriage returns also
				(?:\e\[|\x9b) [ -?]* [@-~] | # CSI ... Cmd
				(?:\e\]|\x9d) .*? (?:\e\\|[\a\x9c]) | # OSC ... (ST|BEL)
				(?:\e[P^_]|[\x90\x9e\x9f]) .*? (?:\e\\|\x9c) | # (DCS|PM|APC) ... ST
				\e.|[\x80-\x9f] //xg;
				1 while s/[^\b][\b]//g;  # remove all non-backspace followed by backspace
			print;
		}
	')"

	echo "${sanitized_text}" | grep "$1" >/dev/null 2>&1
}

# Custom matcher used to find a string inside of a text containing ANSI escape codes.
match_rich_text() {
	if [ -z "${1}" ]; then
		printf "ERROR: You cannot pass an empty string!\n" >&2;
		return 1;
	fi

	# shellcheck disable=SC2059
	rich_search_term="$(printf "$1")"
	match="$(echo "${match_rich_text:-}" | perl -ne "print if /\Q${rich_search_term}/")"

	[ -n "${match}" ]
}


Context "Parameter testing:"
	Describe "should have help option..."
		Parameters
			"Short" "-h"
			"Long" "--help"
		End

		Example "$1 ($2)"
			Set 'errexit:on'


			When call "${LIBRARY_PATH}" $2
			The status should be success
			
			# Here i use a custom matcher function because the text has ANSI colors by default,
			# and this makes impossible to the `eq` matcher to find text.
			The output should satisfy match_plain_text "OPTIONS:"

			bold='\033[1m'
			reset='\033[0m'
			The output should satisfy match_rich_text "${bold}USAGE${reset}:"

		End
	End

	Describe "should SUCCEED when passed the right arguments:"
		long_input_text="$(
			%text
			#|First SecondVeryVeryVeryVeryLongText Third
			#|First SecondShortText Third
		)"

		# Save the expected output for every alignment parameter
		expected_output_param_t="$(
			%text
			#|First  SecondVeryVeryVeryVeryLongText  Third
			#|First  SecondShortText                 Third
		)"
		expected_output_param_R="$(
			%text
			#|First  SecondVeryVeryVeryVeryLongText  Third
			#|First                 SecondShortText  Third
		)"
		expected_output_param_C="$(
			%text
			#|First  SecondVeryVeryVeryVeryLongText  Third
			#|First         SecondShortText          Third
		)"

		Parameters
			# Alignment check
			# By default the text gets aligned at the LEFT of the column
			"-t"       "${long_input_text}"    "${expected_output_param_t}"
			"-R 1,2"   "${long_input_text}"    "${expected_output_param_R}"
			"-C 2"     "${long_input_text}"    "${expected_output_param_C}"
		
			"-s ' '"   "1 2 3"    "1  2  3"
			"-o '|'"   "1 2 3"    "1|2|3"
			"-H 2,3"   "1 2 3 4"  "1  4"
			"-h"
		End

		Example "$1"
			Set 'errexit:on'

			Data "$2"
			When call eval timeout 3 "${LIBRARY_PATH}" $1
			The status should be success
			if [ -n "$3" ]; then
				The output should eq "$3"
			else
				The output should be defined
			fi
		End
	End

	Describe "should FAIL if no parameters are passed:"
		Parameters:block
			"-s"
			"-o"
			"-R"
			"-H"
			"-C"
		End

		Example "$1"
			Set 'errexit:on'

			Data "1 2 3"
			When call eval timeout 3 "${LIBRARY_PATH}" $1
			The status should be failure
			
			# Must not receive timeout
			The status should not eq 124
			The output should be defined
		End
	End

	Describe "should FAIL if wrong parameters are passed:"
		Parameters:block
			"-R 'test'"
			"-H ','"
			"-C '.'"
		End

		Example "$1"
			Set 'errexit:on'

			Data "1 2 3"
			When call eval timeout 3 "${LIBRARY_PATH}" $1
			The status should be failure
			
			# Must not receive timeout
			The status should not eq 124
			The error should include "undefined column name"
			The output should be defined
		End
	End
End