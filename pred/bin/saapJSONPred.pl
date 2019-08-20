#!/acrm/usr/local/bin/perl -s

use strict;

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

my $exec="\$PBIN/saapPred.pl $verbose $modlimit $printall -json=$filename $ac $orig $resnum $mutant";
my $result = `$exec`;
print $result;

