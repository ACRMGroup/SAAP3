#!/usr/bin/perl
# Very simple templating code - replaces $[xxx] with $ENV{xxx}

use strict;

while(<>)
{
    while(/\$\[(.*?)\]/)
    {
        my $key = $1;
        if(!defined($ENV{$key}))
        {
            die "Environment variable not defined: $key\n";
        }
        s/\$\[(.*?)\]/$ENV{$key}/;
    }
    print;
}
