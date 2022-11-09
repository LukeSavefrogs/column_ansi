#shellcheck shell=sh

%const LIBRARY_PATH: src/column_ansi.sh
Include "${LIBRARY_PATH}"

Describe "Basic test:"
	Example "should work out of the box when no arguments are passed"
		Set 'errexit:on'

		Data "1 2 3"
		When call column_ansi
		The status should be success
		The output should eq "1  2  3"
	End
End