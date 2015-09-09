# NAME

App::OATH -  Simple OATH authenticator

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

Tokens are encrypted on disk using Rijndael, the identifiers are not encrypted and can be read in plaintext
from the file.

This is intended to secure against casual reading of the file, but as always, if you have specific security requirements
you should do your own research with regard to relevant attack vectors and use an appropriate solution.

# METHODS

You most likely won't ever want to call these directly, you should use the included command line programme instead.

- _new()_

    Instantiate a new object

- _usage()_

    Display usage and exit

- _set\_search()_

    Set the search parameter

- _get\_search()_

    Get the search parameter

- _init()_

    Initialise a new file

- _add\_entry()_

    Add an entry to the file

- _list\_keys()_

    Display a list of keys in the current file

- _get\_counter()_

    Get the current time based counter

- _display\_codes()_

    Display a list of codes

- _google\_auth()_

    Perform the authentication calculations

- _set\_filename()_

    Set the filename

- _get\_filename()_

    Get the filename

- _load\_data()_

    Load in data from file

- _save\_data()_

    Save data to file

- _get\_crypt\_object()_

    Get the crypt object

- _encrypt\_data()_

    Encrypt the data

- _decrypt\_data()_

    Decrypt the data

- _get\_plaintext()_

    Get the plaintext version of the data

- _get\_encrypted()_

    Get the encrypted version of the data

- _set\_newpass()_

    Signal that we would like to set a new password

- _drop\_password()_

    Drop the password

- _get\_password()_

    Get the current password (from user or cache)

#CODE CLIMATE

[Code on GitHub](https://github.com/marcbradshaw/app-oath)

[![Build Status](https://travis-ci.org/marcbradshaw/app-oath.svg?branch=master)](https://travis-ci.org/marcbradshaw/app-oath)

[![Coverage Status](https://coveralls.io/repos/marcbradshaw/app-oath/badge.svg)](https://coveralls.io/r/marcbradshaw/app-oath)

# DEPENDENCIES

    Convert::Base32
    Crypt::Rijndael
    Digest::HMAC_SHA1
    Digest::MD5
    JSON
    POSIX
    String::Random
    Term::ReadKey

# AUTHORS

Marc Bradshaw <marc@marcbradshaw.net>

# COPYRIGHT

Copyright 2015

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
