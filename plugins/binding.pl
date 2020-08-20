#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    SAAP
#   File:       binding.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Voids plugin for the SAAP server
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

# Note that this no longer uses XMAS files, but fakes the XMAS data
# format instead, so the XMAS package is still used.
use XMAS;

# Information string about this plugin
$::infoString = "Analyzing specific binding interactions";

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("Binding");

# See if the results are cached
my $json = SAAP::CheckCache("Binding", $pdbfile, $residue, $mutant);
$json = "" if(defined($::force)); 
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);

# my $xmasFile = SAAP::GetXmasFile($pdbfile);

if(IsBindingResidue($pdbfile, "plhbonds", $residue, 0) ||
   IsBindingResidue($pdbfile, "pseudohbonds", $residue, 0) ||
   IsBindingResidue($pdbfile, "nonbonds", $residue, 0) ||
   IsBindingResidue($pdbfile, "pphbonds", $residue, 1))
{
    $result = "BAD";
}

$json = SAAP::MakeJson("Binding", ('BOOL'=>$result));
print "$json\n";
SAAP::WriteCache("Binding", $pdbfile, $residue, $mutant, $json);



sub IsBindingResidue
{
    my($pdbFile, $dataType, $residueIn, $crossChain) = @_;

    my $hbondFile = SAAP::CacheHBondData($pdbFile);
    if($hbondFile eq "")
    {
        ErrorDie("Can't build hbond file for $pdbFile");
    }

    my ($pResults, $pFields) = GetHBondData($hbondFile, $dataType);

    # Set field names
    # - for hbonds (pphbonds, plhbonds, pseudohbonds)
    my $field1 = "dresid";
    my $field2 = "aresid";
    # - for nonbonds
    if($dataType eq "nonbonds")
    {
        $field1 = "resid1";
        $field2 = "resid2";
    }

    # Find which fields contain the chain and residue numbers
    my $dResidField = XMAS::FindField($field1, $pFields);
    my $aResidField = XMAS::FindField($field2, $pFields);

    # Extract what we need
    foreach my $record (@$pResults)
    {
        my $dResid     = XMAS::GetField($record, $dResidField);
        my $aResid     = XMAS::GetField($record, $aResidField);

        # If we are OK with same chain bonds, or we aren't (i.e. crossChain is set)
        # and the chains are different...
        my($aChain, $null1, $null2) = SAAP::ParseResSpec($aResid);
        my($dChain, $null1, $null2) = SAAP::ParseResSpec($dResid);

        if((!$crossChain) || ($aChain ne $dChain))
        {
            if(($dResid eq $residueIn) || ($aResid eq $residueIn))
            {
                return(1);
            }
        }
    }
    return(0);
}

sub GetHBondData
{
    my($hbondFile, $dataType) = @_;
    my $inData = 0;
    my @fields = ();
    my @data   = ();

    if(($dataType eq "plhbonds") ||
       ($dataType eq "llhbonds"))
    {
        push @fields, "datom";
        push @fields, "aatom";
        push @fields, "dresnam";
        push @fields, "dresid";
        push @fields, "datnam";
        push @fields, "aresnam";
        push @fields, "aresid";
        push @fields, "aatnam";
        push @fields, "relaxed";
    }
    elsif(($dataType eq "pseudohbonds") ||
          ($dataType eq "pphbonds"))
    {
        push @fields, "datom";
        push @fields, "aatom";
        push @fields, "dresnam";
        push @fields, "dresid";
        push @fields, "datnam";
        push @fields, "aresnam";
        push @fields, "aresid";
        push @fields, "aatnam";
    }
    elsif($dataType eq "nonbonds")
    {
        push @fields, "atomnum1";
        push @fields, "atomnum2";
        push @fields, "resnam1";
        push @fields, "resid1";
        push @fields, "atnam1";
        push @fields, "resnam2";
        push @fields, "resid2";
        push @fields, "atnam2";
    }

    if(open(my $HBfp, '<', $hbondFile))
    {
        while(<$HBfp>)
        {
            chomp;
            s/\#.*//;               # Remove comments
            s/^\s+//;               # Remove leading spaces
            if(length)
            {
                if(/^TYPE: $dataType/)
                {
                    $inData = 1;
                }
                elsif(/^TYPE:/)
                {
                    $inData = 0;
                }
                elsif($inData)
                {
                    push @data, $_;
                }
            }     
        }
        close($HBfp);
    }
    else
    {
        ErrorDie("Cannot read cached HBond datafile ($hbondFile)");
    }

    return(\@data, \@fields);
}


sub UsageDie
{
    print STDERR <<__EOF;

binding.pl V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin

Usage: binding.pl [-force] [chain]resnum[insert] newaa pdbfile
       -force   Force calculation even if results are cached
       (newaa maybe 3-letter or 1-letter code)

Does binding calculations for the SAAP server.
Identifies residues making hbonds, pseudohbonds or nonbond contacts to a ligand
or hbonds to another protein chain

V1.1 no longer uses XMAS files

__EOF
   exit 0;
}

sub ErrorDie
{
    my($msg) = @_;

    SAAP::PrintJsonError("Binding", $msg);
    exit 1;
}

