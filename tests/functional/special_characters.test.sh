#shellcheck shell=sh

Include "src/column_ansi.sh"

Describe "Special characters and edge cases:"
	# Checks if backslashes are not stripped from the output
	# @see https://github.com/LukeSavefrogs/column_ansi/issues/6
	It 'should handle backslashes'
		# This will feed the STDIN of the called function
		# Line MUST start with "#|"
		Data
			#|Backslash: \
		End

		When call column_ansi -o " | " -s '@'
		The output should eq "Backslash: \\"
	End

	# Checks if quotes are not stripped from the output
	# @see https://github.com/LukeSavefrogs/column_ansi/issues/6
	It 'should handle quotes (single/double)'
		Data
			#|Single quote: '
			#|Double quote: "
		End

		When call column_ansi -o " | " -s '@'
		The first line of output should eq "Single quote: '"
		The second line of output should eq 'Double quote: "'
	End

	It 'should handle empty fields'
		TAB="$(printf '\t')"
		Data:expand
			#|First field@@Third field@    @${TAB}
		End

		When call column_ansi -o "|" -s '@'
		The output should eq "First field||Third field|    |${TAB}"
	End
End