#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    SAAP
#   File:       hbonds.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   HBonds plugin for the SAAP server
#   
#   Copyright:  (c) UCL / Prof. Andrew C. R. Martin 2011-2020
#   Author:     Prof. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   EMail:      andrew@bioinf.org.uk
#   Web:        http://www.bioinf.org.uk/
#               
#               
#*************************************************************************
#
#   This program is not in the public domain, but it may be copied
#   according to the conditions laid out in the accompanying file
#   COPYING.DOC
#
#   The code may be modified as required, but any modifications must be
#   documented so that the person responsible can be identified. If 
#   someone else breaks this code, I don't want to be blamed for code 
#   that does not work! 
#
#   The code may not be sold commercially or included as part of a 
#   commercial product except as described in the file COPYING.DOC.
#
#*************************************************************************
#
#   Description:
#   ============
#
#*************************************************************************
#
#   Usage:
#   ======
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  2011     Original
#   V3.2  20.08.20 Added -force
#
#*************************************************************************

use strict;
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/");
use config;
use SAAP;

# Information string about this plugin
$::infoString = "Analyzing disturbed hydrogen-bonds";

#*************************************************************************
$::hstrip = "$config::binDir/pdbhstrip";

#*************************************************************************
my $result = "OK";
my $energy = "NULL";
my $zval = "NULL";
my $ok;

my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("HBonds");

# See if the results are cached
my $json = SAAP::CheckCache("HBonds", $pdbfile, $residue, $mutant);
$json = "" if(defined($::force)); 
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);

my $HBFile = SAAP::CacheHBondData($pdbfile);

my ($partnerRes, $partnerAtom, $atom) = HBondPartner($HBFile, $residue);
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
# my ($partnerRes, $partnerAtom, $atom) = HBondPartner($HBFile, $residue);
sub HBondPartner
{
    my($HBFile, $residueIn) = @_;

    if(open(my $fp, '<', $HBFile))
    {
        my $inPPHBonds = 0;
        while(<$fp>)
        {
            chomp;
            s/\#.*//;           # Remove comments
            s/^\s+//;           # Remove leading spaces
            if(length)
            {
                if(/TYPE:\s+pphbonds/)
                {
                    $inPPHBonds = 1;
                }
                elsif(/TYPE:\s/)
                {
                    $inPPHBonds = 0;
                }
                elsif($inPPHBonds)
                {
                    my(@fields) = split;
                    my $dResid = $fields[3];
                    my $dAtnam = $fields[4];
                    my $aResid = $fields[6];
                    my $aAtnam = $fields[7];

                    if($dResid eq $residueIn)
                    {
                        if(($dAtnam ne "N") && ($dAtnam ne "O"))
                        {
                            close($fp);
                            return($aResid, $aAtnam, $dAtnam);
                        }
                    }
                    if($aResid eq $residueIn)
                    {
                        if(($aAtnam ne "N") && ($aAtnam ne "O"))
                        {
                            close($fp);
                            return($dResid, $dAtnam, $aAtnam);
                        }
                    }
                }
            }
        }
        close($fp);
    }
    else
    {
        SAAP::PrintJsonError("HBonds", "Unable to read HBond cache file ($HBFile)");
        exit 1;
    }

    return("NULL", "NULL", "NULL");
}


#*************************************************************************
sub UsageDie
{
    print STDERR <<__EOF;

hbonds.pl V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin

Usage: hbonds.pl [-force] [chain]resnum[insert] newaa pdbfile
       -force   Force calculation even if results are cached
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

# HERE
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
    if($hbtype eq "N")
    {
        $chb = $SAAP::checkhbondN;
        $chbdata1 = $SAAP::chbdata1N;
        $chbdata2 = $SAAP::chbdata2N;
        $emean  = $SAAP::emeanN;
        $esigma = $SAAP::esigmaN;
    }
    elsif($hbtype eq "O")
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


