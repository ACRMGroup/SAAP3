#!/acrm/usr/local/bin/perl -s
# 22.05.12 Changed to use molecule accessibility as a charge at an
# interface will be dealt with elsewhere

use strict;
use config;
use XMAS;
use SAAP;

# Information string about this plugin
$::infoString = "Analyzing disruption of buried charges";


my $relaccess    = (-1);
my $relaccessMol = (-1);

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("BuriedCharge");

# See if the results are cached
my $json = SAAP::CheckCache("BuriedCharge", $pdbfile, $residue, $mutant);
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);
my $native = SAAP::GetNative($pdbfile, $residue);

my $status;
($relaccess, $relaccessMol, $status) = SAAP::GetRelativeAccess($pdbfile, $residue);
if($status != 0)
{
    if($status < 0)
    {
        SAAP::PrintJsonError("BuriedCharge", "Accessibility of residue ($residue) not found");
        exit 1;
    }
    my $message = $XMAS::ErrorMessage[$status];
    SAAP::PrintJsonError("BuriedCharge", $message);
    exit 1;
}

# Changed from relaccess to relaccessMol ACRM 22.05.12
if($relaccessMol < $SAAP::buried)
{
    # If there has been a charge change
    if(($SAAP::charge{$native} - $SAAP::charge{$mutant}) != 0)
    {
        $result = "BAD";
    }
}

# Changed from relaccess to relaccessMol ACRM 22.05.12
$json = SAAP::MakeJson("BuriedCharge", ('BOOL'=>$result, 'RELACCESS'=>$relaccessMol, 'NATIVE-CHARGE'=>$SAAP::charge{$native}, 'MUTANT-CHARGE'=>$SAAP::charge{$mutant}));
print "$json\n";
SAAP::WriteCache("BuriedCharge", $pdbfile, $residue, $mutant, $json);



sub UsageDie
{
    print STDERR <<__EOF;

buriedcharge.pl V1.0 (c) 2011, UCL, Dr. Andrew C.R. Martin
Usage: buriedcharge.pl [chain]resnum[insert] newaa pdbfile
       (newaa maybe 3-letter or 1-letter code)

Does buried charge calculations for the SAAP server.
Note that the accessibility is returned as -1 if this is not
a change in charge
       
__EOF
   exit 0;
}
