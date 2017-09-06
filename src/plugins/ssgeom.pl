#!/acrm/usr/local/bin/perl -s

use strict;
use config;
use XMAS;
use SAAP;

# Information string about this plugin
$::infoString = "Looking for disruption of disulphides";

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("SSGeom");

# See if the results are cached
my $json = SAAP::CheckCache("SSGeom", $pdbfile, $residue, $mutant);
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);

my $xmasFile = SAAP::GetXmasFile($pdbfile);

if(IsSSCys($xmasFile, $residue))
{
    $result = "BAD";
}

$json = SAAP::MakeJson("SSGeom", ('BOOL'=>$result));
print "$json\n";
SAAP::WriteCache("SSGeom", $pdbfile, $residue, $mutant, $json);




sub IsSSCys
{
    my($xmasFile, $residueIn) = @_;

    # Grab the data
    my ($pResults, $pFields, $status) = XMAS::GetXMASData($xmasFile, "ssbond");

    # Error in getting XMAS data
    if($status)
    {
        # Status 1 is a missing file so this is a real error
        if($status == 1)
        {
            my $message;
            $message = $XMAS::ErrorMessage[$status];
            SAAP::PrintJsonError("SSGeom", $message);
            exit 1;
        }
        # Other status values represent missing data which is OK in this case, but means
        # we haven't found the current residue listed
        return(0);
    }

    # Find which fields contain the chain and residue numbers
    my $chain1Field  = XMAS::FindField("chain1", $pFields);
    my $resnum1Field = XMAS::FindField("resnum1", $pFields);
    my $chain2Field  = XMAS::FindField("chain2", $pFields);
    my $resnum2Field = XMAS::FindField("resnum2", $pFields);

    # Extract what we need
    foreach my $record (@$pResults)
    {
        my $chain1     = XMAS::GetField($record, $chain1Field);
        my $resnum1    = XMAS::GetField($record, $resnum1Field);
        my $residue1 = $chain1 . $resnum1;

        my $chain2     = XMAS::GetField($record, $chain2Field);
        my $resnum2    = XMAS::GetField($record, $resnum2Field);
        my $residue2 = $chain2 . $resnum2;

        # If we are OK with same chain bonds, or we aren't (i.e. crossChain is set)
        # and the chains are different...
        $residue1 =~ s/\s+//g;
        $residue2 =~ s/\s+//g;
        if(($residue1 eq $residueIn) || ($residue2 eq $residueIn))
        {
            return(1);
        }
    }
    return(0);
}



sub UsageDie
{
    print STDERR <<__EOF;

ssgeom.pl V1.0 (c) 2011, UCL, Dr. Andrew C.R. Martin
Usage: ssgeom.pl [chain]resnum[insert] newaa pdbfile
       (newaa maybe 3-letter or 1-letter code)

Does disulphide calculations for the SAAP server.
Checks if a native cysteine was involved in a disulphide

__EOF
   exit 0;
}
