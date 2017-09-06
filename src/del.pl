#!/usr/bin/perl -s
use FindBin;
use lib $FindBin::Bin;

use strict;
use config;

if(scalar(@ARGV) != 4)
{
   print <<__EOF;

Usage: del.pl plugin pdbcode resid newres

__EOF
    exit 0;
}

my $plugin = shift(@ARGV);
my $pdbcode = shift(@ARGV);
my $resid = shift(@ARGV);
my $newres= shift(@ARGV);

my $pdbfile = $config::pdbPrep . $pdbcode . $config::pdbExt;
$pdbfile =~ s/\//_/g;

my $dir = "$config::cacheDir/$plugin";
my $file = "${dir}/${pdbfile}_${resid}_$newres";
if(! -e $file)
{
    print "$file does not exist\n";
}
else
{
    print "Deleting $file\n";
    system("\\rm -f $file");
}

