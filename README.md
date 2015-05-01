# svngitify

Convert SVN distribution to git repository

# SYNOPSIS

    % svngitify [ -i | --interactive] [ [ -u | --user ] svnuser=gituser ] [ -v | --verbose ] url
    % svngitify --help
    % svngitify --version

url may be a traditional fully qualified URL, or a relative or absolute pathname.

# DESCRIPTION

There are lots of HOWTOs on the Interwebs on how to migrate from Subversion
to git.  I got tired of looking one of these up each time I needed to do it
and wrote this script to remember the incantations for me.  This is intended
for a simple one shot, no looking back to Subversion conversion.  If you want
to make changes with git and push them back to Subversion you should instead
of course use `git-svn`.

# OPTIONS

## --interactive | -i

If there are missing users not specified on the command line open the
user map in a text editor before continuing with the conversion.

## --user | -u

Specify a user mapping.  Can be used multiple times.  Example:

    % svngitify -u plicease='Graham Ollis <plicease@cpan.org>'

## --verbose | -v

Log to stdout, instead of a log file.

## --help | -h

Print help

## --version

Print the version

# SEE ALSO

- [cpangitify](https://metacpan.org/pod/cpangitify)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
