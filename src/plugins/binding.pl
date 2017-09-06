#!/acrm/usr/local/bin/perl -s

use strict;
use config;
use XMAS;
use SAAP;

# Information string about this plugin
$::infoString = "Analyzing specific binding interactions";

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("Binding");

# See if the results are cached
my $json = SAAP::CheckCache("Binding", $pdbfile, $residue, $mutant);
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);

my $xmasFile = SAAP::GetXmasFile($pdbfile);

if(IsBindingResidue($xmasFile, "plhbonds", $residue, 0) ||
   IsBindingResidue($xmasFile, "pseudohbonds", $residue, 0) ||
   IsBindingResidue($xmasFile, "nonbonds", $residue, 0) ||
   IsBindingResidue($xmasFile, "pphbonds", $residue, 1))
{
    $result = "BAD";
}


$json = SAAP::MakeJson("Binding", ('BOOL'=>$result));
print "$json\n";
SAAP::WriteCache("Binding", $pdbfile, $residue, $mutant, $json);




sub IsBindingResidue
{
    my($xmasFile, $dataType, $residueIn, $crossChain) = @_;

    # Grab the data
    my ($pResults, $pFields, $status) = XMAS::GetXMASData($xmasFile, $dataType);

    # Error in getting XMAS data
    if($status)
    {
        # Status 1 is a missing file so this is a real error
        if($status == 1)
        {
            my $message;
            $message = $XMAS::ErrorMessage[$status];
            SAAP::PrintJsonError("Binding", $message);
            exit 1;
        }
        # Other status values represent missing data which is OK in this case, but means
        # we haven't found the current residue listed
        return(0);
    }

    # Set field names
    # - for hbonds (pphbonds, plhbonds, pseudohbonds)
    my $field1 = "dchain";
    my $field2 = "dresnum";
    my $field3 = "achain";
    my $field4 = "aresnum";
    # - for nonbonds
    if($dataType eq "nonbonds")
    {
        my $field1 = "chain1";
        my $field2 = "resnum1";
        my $field3 = "chain2";
        my $field4 = "resnum2";
    }

    # Find which fields contain the chain and residue numbers
    my $dChainField  = XMAS::FindField($field1, $pFields);
    my $dResnumField = XMAS::FindField($field2, $pFields);
    my $aChainField  = XMAS::FindField($field3, $pFields);
    my $aResnumField = XMAS::FindField($field4, $pFields);

    # Extract what we need
    foreach my $record (@$pResults)
    {
        my $dChain     = XMAS::GetField($record, $dChainField);
        my $dResnum    = XMAS::GetField($record, $dResnumField);
        my $dResidue = $dChain . $dResnum;

        my $aChain     = XMAS::GetField($record, $aChainField);
        my $aResnum    = XMAS::GetField($record, $aResnumField);
        my $aResidue = $aChain . $aResnum;

        # If we are OK with same chain bonds, or we aren't (i.e. crossChain is set)
        # and the chains are different...
        if((!$crossChain) || ($aChain ne $dChain))
        {
            $dResidue =~ s/\s+//g;
            $aResidue =~ s/\s+//g;
            if(($dResidue eq $residueIn) || ($aResidue eq $residueIn))
            {
                return(1);
            }
        }
    }
    return(0);
}



sub UsageDie
{
    print STDERR <<__EOF;

binding.pl V1.0 (c) 2011, UCL, Dr. Andrew C.R. Martin
Usage: binding.pl [chain]resnum[insert] newaa pdbfile
       (newaa maybe 3-letter or 1-letter code)

Does binding calculations for the SAAP server.
Identifies residues making hbonds, pseudohbonds or nonbond contacts to a ligand
or hbonds to another protein chain

__EOF
   exit 0;
}
