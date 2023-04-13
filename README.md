[![License](https://img.shields.io/github/license/LukeSavefrogs/column_ansi)](./LICENSE)
[![GitHub contributors (via allcontributors.org)](https://img.shields.io/github/all-contributors/LukeSavefrogs/column_ansi)](#contributors)
[![GitHub last commit](https://img.shields.io/github/last-commit/LukeSavefrogs/column_ansi)](https://github.com/LukeSavefrogs/column_ansi/commits/main)
[![GitHub issues](https://img.shields.io/github/issues/LukeSavefrogs/column_ansi)](https://github.com/LukeSavefrogs/column_ansi/issues?q=is%3Aopen+is%3Aissue)

[![CI](https://github.com/LukeSavefrogs/column_ansi/actions/workflows/test.yml/badge.svg)](https://github.com/LukeSavefrogs/column_ansi/actions/workflows/test.yml)

# ANSI-compatible `column`: `column_ansi`
`Perl` version of `column` with support for ANSI color codes

## Syntax
```shell
column_ansi [-s SEPARATOR] [-o SEPARATOR] [-R COLUMNS] [-H COLUMNS] [-C COLUMNS]
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

-H COLUMNS, --table-hide COLUMNS
        Don't print specified columns. The special placeholder '-' maybe be used to hide all unnamed columns (see --table-columns).
        IMPORTANT: The striked part of the description is still not implemented.

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
- Support for **hidden columns**
- Support for **quoted fields** and **escaped quotes** thanks to the `Text::ParseWords` module!


## TODO
- Improve [`CONTRIBUTING.md` file](CONTRIBUTING.md)
- Parse CLI parameters directly from the Perl file (_maybe the [`Getopts:Long`](https://metacpan.org/pod/Getopt::Long) package?_)
- Write **better tests** (maybe use a [testing framework](https://github.com/dodie/testing-in-bash)?) - _Work in progress..._
- Add option to **keep or skip empty lines** (right now it keeps them, which is different from the default behaviour of `column`);
- Add option to **remove colors** and control characters from the **output**;
- Make the choice of **right/center alignment _explicit_** (so that one cannot pass the same column index to both options)
- Update documentation with the description of the various **Environment Variables** used by the Perl script
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
![Help page](https://user-images.githubusercontent.com/33452387/162549413-8ebbf962-c3a5-48ff-8573-2488c94e6e52.png)

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

### Run tests
To run tests ensure to have [`shellspec` installed](./CONTRIBUTING.md#installing-shellspec), then launch the following command:
```shell
shellspec --format d
```

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

## tecolicom - `App-ansicolumn`
ANSI terminal sequence aware column command written in Perl (_not tested_).

#### Pro
- Has both `fill by rows` and `fill by columns` options from the original `column` command;
- Good documentation
- Lots of additional options

#### Cons
_Not enough data_

### Links
- [Author](https://github.com/kaz-utashiro)
- [Project](https://github.com/tecolicom/App-ansicolumn)

## Contributors
<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center"><a href="https://www.linkedin.com/in/lucasalvarani/"><img src="https://avatars.githubusercontent.com/u/33452387?v=4?s=100" width="100px;" alt="Luca Salvarani"/><br /><sub><b>Luca Salvarani</b></sub></a><br /><a href="https://github.com/LukeSavefrogs/column_ansi/commits?author=LukeSavefrogs" title="Code">💻</a> <a href="https://github.com/LukeSavefrogs/column_ansi/commits?author=LukeSavefrogs" title="Documentation">📖</a> <a href="#maintenance-LukeSavefrogs" title="Maintenance">🚧</a> <a href="#question-LukeSavefrogs" title="Answering Questions">💬</a> <a href="https://github.com/LukeSavefrogs/column_ansi/pulls?q=is%3Apr+reviewed-by%3ALukeSavefrogs" title="Reviewed Pull Requests">👀</a> <a href="https://github.com/LukeSavefrogs/column_ansi/commits?author=LukeSavefrogs" title="Tests">⚠️</a></td>
      <td align="center"><a href="https://github.com/bartasha"><img src="https://avatars.githubusercontent.com/u/44841974?v=4?s=100" width="100px;" alt="bartasha"/><br /><sub><b>bartasha</b></sub></a><br /><a href="https://github.com/LukeSavefrogs/column_ansi/commits?author=bartasha" title="Code">💻</a> <a href="https://github.com/LukeSavefrogs/column_ansi/issues?q=author%3Abartasha" title="Bug reports">🐛</a> <a href="https://github.com/LukeSavefrogs/column_ansi/commits?author=bartasha" title="Tests">⚠️</a></td>
      <td align="center"><a href="https://github.com/LukasWillin"><img src="https://avatars.githubusercontent.com/u/14276298?v=4?s=100" width="100px;" alt="Lukas Willin"/><br /><sub><b>Lukas Willin</b></sub></a><br /><a href="https://github.com/LukeSavefrogs/column_ansi/issues?q=author%3ALukasWillin" title="Bug reports">🐛</a> <a href="https://github.com/LukeSavefrogs/column_ansi/commits?author=LukasWillin" title="Code">💻</a> <a href="https://github.com/LukeSavefrogs/column_ansi/commits?author=LukasWillin" title="Tests">⚠️</a></td>
    </tr>
  </tbody>
  <tfoot>
    <tr>
      <td align="center" size="13px" colspan="7">
        <img src="https://raw.githubusercontent.com/all-contributors/all-contributors-cli/1b8533af435da9854653492b1327a23a4dbd0a10/assets/logo-small.svg">
          <a href="https://all-contributors.js.org/docs/en/bot/usage">Add your contributions</a>
        </img>
      </td>
    </tr>
  </tfoot>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
