[![macOS status](../../workflows/macos/badge.svg)](../../actions?query=workflow%3Amacos)[![ubuntu status](../../workflows/ubuntu/badge.svg)](../../actions?query=workflow%3Aubuntu)[![MS Windows status](../../workflows/windows/badge.svg)](../../actions?query=workflow%3Awindows)[![AppVeyor status](https://ci.appveyor.com/api/projects/status/m7fjcqjmoue0wssu?svg=true)](https://ci.appveyor.com/project/briandfoy/perl6-prettydump) [![artistic2](https://img.shields.io/badge/license-Artistic%202.0-blue.svg?style=flat)](https://opensource.org/licenses/Artistic-2.0)

# The Raku PrettyDump module

When you want to look at your Raku data structure, you probably want
something nicer than `.perl` or `.gist`.

I wrote about this in [Pretty Printing Perl 6](https://www.perl.com/article/pretty-printing-perl-6/).

## Installation

Install it with [zef](https://github.com/ugexe/zef), which comes with
the latest [Rakudo Star](http://rakudo.org/how-to-get-rakudo/):

	zef install PrettyDump

You can also checkout the [latest sources](https://github.com/briandfoy/perl6-PrettyDump) then install from that directory:

	zef install .

## Contributing

Fork the [perl6-PrettyDump](https://github.com/briandfoy/perl6-PrettyDump), edit, commit, and send a pull request!

If it's something non-trivial, you might consider [opening an issue](https://github.com/briandfoy/perl6-PrettyDump/issues) first.

# Author

brian d foy, based off a the [perl-pp](https://github.com/drforr/perl6-pp) module from
[Jeffrey Goff](https://github.com/drforr/).

# License

Artistic License 2.0
