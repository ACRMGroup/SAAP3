#!/usr/bin/perl -s

use strict;
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/..");
use lib abs_path("$FindBin::Bin/");
use config;

my $verbose  = defined($::v)?"-v=$::v":"";
my $modlimit = defined($::modlimit)?"-modlimit=$::modlimit":"";
my $printall = defined($::printall)?"-printall":"";

my $filename = shift @ARGV;
my $ac     = '';
my $orig   = '';
my $resnum = '';
my $mutant = '';

if($filename =~ /(.*)_(...)_(\d+)_(...)\.json/)
{
    $ac     = $1;
    $orig   = $2;
    $resnum = $3;
    $mutant = $4;
}
elsif($filename =~ /(.*)_(.)_(\d+)_(.)\.json/)
{
    $ac     = $1;
    $orig   = $2;
    $resnum = $3;
    $mutant = $4;
}

$ac =~ s/^.*\///;           # Strip path

my $exec="$config::saapBinDir/saapPred $verbose $modlimit $printall -json=$filename $ac $orig $resnum $mutant";
my $result = `$exec`;
print $result;

