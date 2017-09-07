#!/usr/bin/perl -s

use strict;
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use config;
use XMAS;
use SAAP;

# Information string about this plugin
$::infoString = "Analyzing disturbed hydrogen-bonds";

#*************************************************************************
$::hstrip = "$config::binDir/hstrip";

#*************************************************************************
my $result = "OK";
my $energy = "NULL";
my $zval = "NULL";
my $ok;

my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("HBonds");

# See if the results are cached
my $json = SAAP::CheckCache("HBonds", $pdbfile, $residue, $mutant);
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);

my $xmasFile = SAAP::GetXmasFile($pdbfile);

my ($partnerRes, $partnerAtom, $atom) = HBondPartner($xmasFile, $residue);
if($partnerRes ne "NULL")
{
    ($ok, $energy, $zval) = CheckHBond($pdbfile, $residue, $mutant, $partnerRes, $partnerAtom);
    if(!$ok)
    {
        $result = "BAD";
    }
}


$json = SAAP::MakeJson("HBonds", ('BOOL'=>$result, 
                                    'PARTNER-RES'=>$partnerRes, 
                                    'PARTNER-ATOM'=>$partnerAtom, 
                                    'ATOM'=>$atom, 
                                    'ENERGY'=>$energy, 
                                    'ZVAL'=>$zval));
print "$json\n";
SAAP::WriteCache("HBonds", $pdbfile, $residue, $mutant, $json);


#*************************************************************************
sub HBondPartner
{
    my($xmasFile, $residueIn) = @_;

    # Grab the data
    my ($pResults, $pFields, $status) = XMAS::GetXMASData($xmasFile, "pphbonds");

    # Error in getting XMAS data
    if($status)
    {
        my $message;
        $message = $XMAS::ErrorMessage[$status];
        SAAP::PrintJsonError("HBonds", $message);
        exit 1;
    }

    # Set field names
    # - for hbonds (pphbonds, plhbonds, pseudohbonds)
    my $field1 = "dchain";
    my $field2 = "dresnum";
    my $field3 = "achain";
    my $field4 = "aresnum";
    my $field5 = "datnam";
    my $field6 = "aatnam";

    # Find which fields contain the chain and residue numbers
    my $dChainField  = XMAS::FindField($field1, $pFields);
    my $dResnumField = XMAS::FindField($field2, $pFields);
    my $aChainField  = XMAS::FindField($field3, $pFields);
    my $aResnumField = XMAS::FindField($field4, $pFields);
    my $dAtnamField  = XMAS::FindField($field5, $pFields);
    my $aAtnamField  = XMAS::FindField($field6, $pFields);

    # Extract what we need
    foreach my $record (@$pResults)
    {
        my $dChain     = XMAS::GetField($record, $dChainField);
        my $dResnum    = XMAS::GetField($record, $dResnumField);
        my $dResidue   = $dChain . $dResnum;
        my $dAtnam     = XMAS::GetField($record, $dAtnamField);

        my $aChain     = XMAS::GetField($record, $aChainField);
        my $aResnum    = XMAS::GetField($record, $aResnumField);
        my $aResidue   = $aChain . $aResnum;
        my $aAtnam     = XMAS::GetField($record, $aAtnamField);

        $dResidue =~ s/\s+//g;
        $aResidue =~ s/\s+//g;
        if($dResidue eq $residueIn)
        {
            if(($dAtnam ne " N  ") && ($dAtnam ne " O  "))
            {
                return($aResidue, $aAtnam, $dAtnam);
            }
        }
        if($aResidue eq $residueIn)
        {
            if(($aAtnam ne " N  ") && ($aAtnam ne " O  "))
            {
                return($dResidue, $dAtnam, $aAtnam);
            }
        }
    }
    return("NULL", "NULL", "NULL");
}


#*************************************************************************
sub UsageDie
{
    print STDERR <<__EOF;

hbonds.pl V1.0 (c) 2011, UCL, Dr. Andrew C.R. Martin
Usage: hbonds.pl [chain]resnum[insert] newaa pdbfile
       (newaa maybe 3-letter or 1-letter code)

Does HBond calculations for the SAAP server.
Identifies residues making protein-protein hbonds and sees if they can 
be conserved using checkhbond

Typical range of pseudo-energies is 5-20; low values are good.

__EOF
   exit 0;
}


#*************************************************************************
sub CheckHBond
{
    my($pdbfile, $residue, $mutant, $partnerRes, $partnerAtom) = @_;
    my $cutoff = 0.25;

    my $tfile = "$config::tmpDir/HB_$$" . time . ".pdb";
    `$::hstrip $pdbfile $tfile`;

    my($checkhbond, $chbdata1, $chbdata2, $emean, $esigma) = SetType($partnerAtom);
    my $results = `$checkhbond -m $chbdata1 $chbdata2 -c $cutoff $tfile $partnerRes $residue $mutant 2>&1`;
    
    my($ok, $energy, $zval) = ParseResults($results, $emean, $esigma);

    unlink($tfile);

    return($ok, $energy, $zval);
}

#*************************************************************************
sub ParseResults
{
    my($results, $emean, $esigma) = @_;
    my($ok, $energy, $zval);

    $ok = 0;
    my @results = split(/\n/, $results);
    $energy = "NULL";
    $zval   = "NULL";

    foreach my $result (@results)
    {
        if($result =~ /Pseudoenergy/)
        {
            my @fields = split(/\s+/, $result);
            $energy = $fields[6];
            $zval = sprintf("%.3f",($fields[6] - $emean) / $esigma);
            $ok = 1;
        }
    }

    return($ok, $energy, $zval);
}

#*************************************************************************
sub SetType
{
    my($hbtype) = @_;
    my($chb, $chbdata1, $chbdata2, $emean, $esigma);
    if($hbtype eq " N  ")
    {
        $chb = $SAAP::checkhbondN;
        $chbdata1 = $SAAP::chbdata1N;
        $chbdata2 = $SAAP::chbdata2N;
        $emean  = $SAAP::emeanN;
        $esigma = $SAAP::esigmaN;
    }
    elsif($hbtype eq " O  ")
    {
        $chb = $SAAP::checkhbondO;
        $chbdata1 = $SAAP::chbdata1O;
        $chbdata2 = $SAAP::chbdata2O;
        $emean  = $SAAP::emeanO;
        $esigma = $SAAP::esigmaO;
    }
    else
    {
        $chb = $SAAP::checkhbondSS;
        $chbdata1 = $SAAP::chbdata1SS;
        $chbdata2 = $SAAP::chbdata2SS;
        $emean  = $SAAP::emeanSS;
        $esigma = $SAAP::esigmaSS;
    }
    return($chb, $chbdata1, $chbdata2, $emean, $esigma);
}

