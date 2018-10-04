#!/usr/bin/perl
use lib qw(..);
use strict;

use MUSCLE;

my $sequences = `cat test_muscle.faa`;

my ($error, $result) = MUSCLE::RunMuscle($sequences, 'andrew@bioinf.org.uk');
#my ($error, $result) = LocalRunMuscle($sequences, 'andrew@bioinf.org.uk');

if($error)
{
    print "Error: $result\n";
}
else
{
    print $result;
}


