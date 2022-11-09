#shellcheck shell=sh

%const LIBRARY_PATH: src/column_ansi.sh

Describe "Code quality tests:"
	Include "${LIBRARY_PATH}"
	It "should not reference unset variables"
		# Same as `set -e` and `set -u`
		# https://github.com/shellspec/shellspec#set---set-shell-options
		Set 'errexit:on' 'nounset:on'

		Data "1 2 3"
		When call column_ansi
		The status should be success
		The stderr should not include "unbound variable"
		The output should be defined
	End

	Describe "should explicitly unset all Environment Variables:"
		Parameters:dynamic
			# shellcheck disable=SC2013
			for variable_name in $(grep -E "^\s*export +[-A-Za-z_0-9]+" "${LIBRARY_PATH}" | cut -d= -f1 | sed 's/^\s*export //'); do
				if [ "${variable_name}" != "COLUMN_ANSI_PLSCRIPT_PATH" ]; then
					%data "${variable_name}"
				fi
			done
		End
		
		It "should unset '$1'"
			find_unset_command () {
				grep -E "^\s*unset +$1" "${LIBRARY_PATH}"
			}
			When call find_unset_command "$1"
			The output should be present
		End
	End

End