#shellcheck shell=sh

Include "src/column_ansi.sh"

Describe "The library..."
	It "should export 'column_ansi' function"
		The function "column_ansi" should be defined
	End
	
	It "should provide the Perl file"
		The path "src/column_ansi.pl" should be exist
		The path "src/column_ansi.pl" should be file
	End
End