# ANSI-compatible `column`: `column_ansi`
`Perl` version of `column` with support for ANSI color codes

## Syntax
```shell
column_ansi [-s SEPARATOR] [-o SEPARATOR] [-R COLUMNS] [-C COLUMNS]
column_ansi --help
```

## Options
```
-t, --table
        Does nothing, was left for compatibility reasons. [DEFAULT]

-s SEPARATOR, --separator SEPARATOR
        Specify the possible input item delimiters (default is whitespace).

-r SEPARATOR, --output-separator SEPARATOR
        Specify the columns delimiter for table output (default is two spaces).

-R COLUMNS, --table-right COLUMNS
        Right align text in the specified columns (comma-separated).

-C COLUMNS, --table-center COLUMNS
        Center align text in the specified columns (comma-separated). 
        This option is not present in the original column command.

-h, --help
        Display help text and exit.
```

## Features
- Support for **ANSI color** codes and characters (output is aligned)
- Same **syntax** and parameters as `column` (see `column_ansi --help` for more info)
- **Right, Left and even Center alignment** for every column (1-based)!

## TODO
- Add option to keep or skip empty lines (right now it keeps them, which is different from the default behaviour of `column`);
- Add option to remove colors and control characters from the output;
- Make the choice of right/center alignment _explicit_ (so one cannot pass the same column index to both options)
- _Feel free to suggest anything in the [Issue](https://github.com/LukeSavefrogs/column_ansi/issues) section..._ 😃

## Description
I needed to format a very long awk-generated colored output (more than 300 lines) into a nice table.
I first thought of using `column`, but as i discovered it didn't take into consideration ANSI characters, since the output would come out not aligned.

After searching a bit on Google i found [this interesting answer](https://stackoverflow.com/a/38762316/8965861) on SO which dynamically calculated the width of every single column in the output after removing the ANSI characters and THEN it built the table.

It was all good, but it was taking way too long to load... In the attached tests `test_column_ansi.sh` you will find that even for 2 lines `column2` (the one i found on SO) takes up to 2-3 seconds (which is a lot in comparison to the 0.0xx seconds of the original `column`)!

After trying out this version in my production script the time used to display data **dropped from 30s to <1s**!!


## Considerations
### Why not use `bash`?
Because each call to `bash`'s `read` is [very slow](https://unix.stackexchange.com/a/169765/348102).

## Screenshots
#### Comparison with `column` command
![Comparison with column](https://user-images.githubusercontent.com/33452387/147605328-e786c713-afdb-4913-ab77-652098935b45.png)

#### Help page
![Help page](https://user-images.githubusercontent.com/33452387/147606019-40c42e9e-ed65-4b7c-93a5-bd92a293afee.png)

## Tests
In the following screenshot you can see (and try it yourself, by executing the attached `test_column_ansi.sh` script) 4 tests with the corresponding timings:
1. Original `column` command - WITH colors
    The output is completely **out of alignment** because of the colors.

2. Original `column` command - WITHOUT colors
    After removing the colors the output is shown **as expected**.

3. Custom `column2` command - By [@NORMAN GEIST](https://stackoverflow.com/users/5871407/norman-geist)
    Output is shown **as expected** but is **very slow** compared to `column`.

4. Custom `column_ansi` command - By me
    Output is shown **as expected** and the **time** needed to render is way **similar** to the original `column` one.

![Example output](https://user-images.githubusercontent.com/33452387/147603917-5cfaafe1-7d21-4436-a2f7-b7d91ef58e7c.png)

# Other projects
## NORMAN GEIST - `ccolumn`
Very spartan project written entirely in **Bash** which works but it is very slow... It is the project that led me to the `Perl` solution.

#### Pro
- Works without a bug (tested)

#### Cons
- Very slow since it uses Bash `read` command in a loop (see [this answer](https://stackoverflow.com/a/13764233/8965861) for more info)

### Links
- [Author](https://stackoverflow.com/users/5871407/norman-geist)
- [Project](https://stackoverflow.com/a/38762316/8965861)


## SandersJ16 - `ccolumn`
Very good project written entirely in **Bash** which has some similarities with the original `column` command, yet handles colors.

#### Pro
- Has both `fill by rows` and `fill by columns` options from the original `column` command;
- Allows to choose whether or not to print colors
- Has an option to print empty lines too

#### Cons
- Very slow since it uses Bash `read` command in a loop (see [this answer](https://stackoverflow.com/a/13764233/8965861) for more info)
- Possibly slower than `column2` (not tested)

### Links
- [Author](https://github.com/SandersJ16)
- [Project](https://github.com/SandersJ16/Bash-Better-Column-Command)
