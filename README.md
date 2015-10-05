# NAME

App::OATH -  Simple OATH authenticator

# BADGES

[![Code on GitHub](https://img.shields.io/badge/github-repo-blue.svg)](https://github.com/marcbradshaw/app-oath) [![Build Status](https://travis-ci.org/marcbradshaw/app-oath.svg?branch=master)](https://travis-ci.org/marcbradshaw/app-oath) [![Coverage Status](https://coveralls.io/repos/marcbradshaw/app-oath/badge.svg)](https://coveralls.io/r/marcbradshaw/app-oath) [![Open Issues](https://img.shields.io/github/issues/marcbradshaw/app-oath.svg)](https://github.com/marcbradshaw/app-oath/issues) [![Dist on CPAN](https://img.shields.io/cpan/v/App-OATH.svg)](https://metacpan.org/release/App-OATH) [![CPANTS](https://img.shields.io/badge/cpants-kwalitee-blue.svg)](http://cpants.cpanauthors.org/dist/App-OATH) [![CPAN Testers](https://img.shields.io/badge/CPAN-Testers-blue.svg)](http://www.cpantesters.org/distro/A/App-OATH.html)

# DESCRIPTION

Simple command line OATH authenticator written in Perl.

# SYNOPSIS

Implements the Open Authentication (OATH) time-based one time password (TOTP)
two factor authentication standard as a simple command line programme.

Allows storage of multiple tokens, which are kept encrypted on disk.

Google Authenticator is a popular example of this standard, and this project
can be used with the same tokens.

# USAGE

usage: oath --add string --file filename --help --init --list --newpass --search string 

options:

\--add string

    add a new password to the database, the format can be one of the following

        text: identifier:secret
        url:  otpauth://totp/alice@google.com?secret=JBSWY3DPEHPK3PXP

\--file filename

    filename for database, default ~/.oath.json

\--help

    show this help

\--init

    initialise the database, file must not exist

\--list

    list keys in database

\--newpass

    resave database with a new password

\--search string

    search database for keys matching string

# SECURITY

Tokens are encrypted on disk, the identifiers are not encrypted and can be read in plaintext
from the file.

This is intended to secure against casual reading of the file, but as always, if you have specific security requirements
you should do your own research with regard to relevant attack vectors and use an appropriate solution.

# AUTHORS

Marc Bradshaw <marc@marcbradshaw.net>

# COPYRIGHT

Copyright 2015

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

