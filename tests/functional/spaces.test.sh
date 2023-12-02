#shellcheck shell=sh

%const LIBRARY_PATH: src/column_ansi.sh
Include "${LIBRARY_PATH}"

input_data () {
    printf "this  \twill  \t  be\taligned"
}

# @see https://github.com/LukeSavefrogs/column_ansi/issues/19
Describe "Mixed tabs and spaces:"
	Example "should work when words have mixed whitespace"
		Set 'errexit:on'

		Data input_data
		When call column_ansi -t -o "|"
		The status should be success
		The output should eq "this|will|be|aligned"
	End
End