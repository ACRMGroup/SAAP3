#!/usr/bin/perl -s

use strict;
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/");
use config;
use SAAP;

# Information string about this plugin
$::infoString = "Checking if this disturbs a known interface";

my $relaccess    = (-1);
my $relaccessMol = (-1);

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("Interface");

# See if the results are cached
my $json = SAAP::CheckCache("Interface", $pdbfile, $residue, $mutant);
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);

my $status;
($relaccess, $relaccessMol, $status) = SAAP::GetRelativeAccess($pdbfile, $residue);
if($status != 0)
{
    if($status < 0)
    {
        SAAP::PrintJsonError("Interface", "Residue not found");
        exit 1;
    }
    my $message = $SAAP::ErrorMessage;
    SAAP::PrintJsonError("Interface", $message);
    exit 1;
}

if(($relaccessMol - $relaccess) > 10)
{
    $result = "BAD";
}

$json = SAAP::MakeJson("Interface", ('BOOL'=>$result, 'RELACCESS'=>$relaccess, 'RELACCESS-MOL'=>$relaccessMol));
print "$json\n";
SAAP::WriteCache("Interface", $pdbfile, $residue, $mutant, $json);



sub UsageDie
{
    print STDERR <<__EOF;

interface.pl V1.1 (c) 2011-2017, UCL, Dr. Andrew C.R. Martin
Usage: interface.pl [chain]resnum[insert] newaa pdbfile
       (newaa maybe 3-letter or 1-letter code)

Does interface calculations for the SAAP server.
Identifies residues where relative access changes by >10% on binding
       
__EOF
   exit 0;
}
