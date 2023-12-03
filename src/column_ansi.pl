#!/bin/env perl
use strict;
use warnings;

# Set minimum Perl version to v5.6.0 (https://github.com/LukeSavefrogs/column_ansi/issues/2#issuecomment-1324001702)
use 5.006;

# By making use of the module "Text::ParseWords" we can abstract all the complexity of handling all the edge cases of CSV data, like quoted fields, escaped quotes, etc.
# Source: https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch01s16.html
use Text::ParseWords;

# Source: https://unix.stackexchange.com/a/18979/348102
sub trim_ansi {
	my $__temp_string = $_[0];
	if(!defined $__temp_string) { return ""; }
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
my $HIDDEN_COLUMNS = $ENV{"PCOLUMN_HIDDEN_COLUMNS"};
my $IGNORE_LINE_PREFIX = $ENV{"PCOLUMN_IGNORE_LINE_PREFIX"};
my $LENGTH_IGNORE_LINE_PREFIX = length($IGNORE_LINE_PREFIX);
my $IS_IGNORE_LINE_PREFIX_SET = 0;
if ($LENGTH_IGNORE_LINE_PREFIX ne 0){
	$IS_IGNORE_LINE_PREFIX_SET = 1;
}

# Default values for INPUT_SEPARATOR and OUTPUT_SEPARATOR
if ($INPUT_SEPARATOR eq ""){
	$INPUT_SEPARATOR = qr/[\s\t]+/;
}
if ($OUTPUT_SEPARATOR eq ""){
	$OUTPUT_SEPARATOR = "  "
}

# ALIGN_RIGHT must be a single number or a comma-separated list of numbers
# Then split ALIGN_RIGHT into an array and then convert it to an hash that will be used to check
#   if the column needs to be aligned to the right
$ALIGN_RIGHT =~ s/^\s+|\s+$//g; # Remove extra spaces
if ($ALIGN_RIGHT ne "" && not $ALIGN_RIGHT =~ /^[0-9]+(,[0-9]+)*$/) {
	print STDERR "error: undefined column name '$ALIGN_RIGHT'\n";
	exit 1;
}
my %ALIGN_RIGHT_HASH = map {$_ - 1 => 1} split(/,/, $ALIGN_RIGHT); # Create a hash with (index-1) as key and 1 as value (just a truthy value) (https://it.perlmaven.com/transforming-a-perl-array-using-map)


# ALIGN_CENTER must be a single number or a comma-separated list of numbers
# Then split ALIGN_CENTER into an array and then convert it to an hash that will be used to check
#   if the column needs to be aligned to the center
$ALIGN_CENTER =~ s/^\s+|\s+$//g; # Remove extra spaces
if ($ALIGN_CENTER ne "" && not $ALIGN_CENTER =~ /^[0-9]+(,[0-9]+)*$/) {
	print STDERR "error: undefined column name '$ALIGN_CENTER'\n";
	exit 1;
}
my %ALIGN_CENTER_HASH = map {$_ - 1 => 1} split(/,/, $ALIGN_CENTER); # Create a hash with (index-1) as key and 1 as value (just a truthy value)


# HIDDEN_COLUMNS must be a single number or a comma-separated list of numbers
# Then split HIDDEN_COLUMNS into an array and then convert it to an hash that will be used to check
#   if the column needs to be hidden
$HIDDEN_COLUMNS =~ s/^\s+|\s+$//g; # Remove extra spaces
if ($HIDDEN_COLUMNS ne "" && not $HIDDEN_COLUMNS =~ /^[0-9]+(,[0-9]+)*$/) {
	print STDERR "error: undefined column name '$HIDDEN_COLUMNS'\n";
	exit 1;
}
my %HIDDEN_COLUMNS_HASH = map {$_ - 1 => 1} split(/,/, $HIDDEN_COLUMNS); # Create a hash with (index-1) as key and 1 as value (just a truthy value)

# Save the STDIN into an Array, so that we can loop over it multiple times
my @stdin = <STDIN>;
my $column_widths = [];

# First loop: get the width of each column and save it in an array
foreach my $line_ref (@stdin) {
	my $line = $line_ref;
	$line =~ s/\r?\n?$//;
	# Ignore line if prefixed with argument from `-i`
	if ($IS_IGNORE_LINE_PREFIX_SET && (rindex $line, $IGNORE_LINE_PREFIX, 0) eq 0) {
		next;
	}
	$line =~ s/(\\+)/$1$1/g;		# escape backslashes
	$line =~ s/"/\\"/g;				# escape double quotes
	$line =~ s/'/\\'/g;		        # escape single quotes
	my @columns = quotewords($INPUT_SEPARATOR, 1, $line); # split(/\Q$INPUT_SEPARATOR/, $line);
	my $column_index = 0;

	foreach my $column (@columns) {
		next if !defined $column;
		$column =~ s/\\'/'/g;	        # unescape single quotes
		$column =~ s/\\"/"/g;			# unescape double quotes
		$column =~ s/(\\+)\1/$1/g;		# unescape backslashes
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
foreach my $line_ref (@stdin) {
	my $line = $line_ref;
	$line =~ s/\r?\n?$//;
	# Print as is if prefixed with argument from `-i` but ommit the prefix
	if ($IS_IGNORE_LINE_PREFIX_SET && (rindex $line, $IGNORE_LINE_PREFIX, 0) eq 0) {
		print(substr $line, $LENGTH_IGNORE_LINE_PREFIX);
		print("\n");
		next;
	}
	$line =~ s/(\\+)/$1$1/g;		# escape backslashes
	$line =~ s/"/\\"/g;				# escape double quotes
	$line =~ s/'/\\'/g;		        # escape single quotes
	my @columns = quotewords($INPUT_SEPARATOR, 1, $line); # split (/\Q$INPUT_SEPARATOR/, $line);
	my $column_index = -1;

	foreach my $column (@columns) {
		next if !defined $column;
		$column =~ s/\\'/'/g;	        # unescape single quotes
		$column =~ s/\\"/"/g;			# unescape double quotes
		$column =~ s/(\\+)\1/$1/g;		# unescape backslashes
		$column_index++;

		# 2022/04/09 - Hide the column if it is in HIDDEN_COLUMNS
		if (exists $HIDDEN_COLUMNS_HASH{$column_index}) {
			next;
		}

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
	}
	print("\n");
}