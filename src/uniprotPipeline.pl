#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    uniprot_pipeline
#   File:       uniprot_pipeline.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Runs the SAAP analysis pipeline for a UniProt code
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
#               andrew.martin@ucl.ac.uk
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
#   V1.0  11.11.11 Original   By: ACRM
#   V1.1  05.10.18 Updated for reorganization of code
#   V3.2  20.08.20 Bumped for second official release
#
#*************************************************************************
use strict;
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/..");
use lib abs_path("$FindBin::Bin/");
use config;
use SAAP;
use PDBSWS;

#*************************************************************************
my $programName = "SAAPS";
my $uniprot = "";
my($ac, $resnum, $native, $mutant) = ParseCmdLine($programName);

my $pipeline = $config::saapPipeline;

$::v    = defined($::v)?"-v":"";
$::info = defined($::info)?"-info":"";

# Print start of JSON
PrintJsonHeader($programName, $ac, $resnum, $native, $mutant);

# Obtain a list of PDB codes that map to this UniProt AC
my @pdbresidues = GetPDBResidues($ac, $resnum);

my $count = 0;
foreach my $pdbres (@pdbresidues)
{
    if($count)
    {
        print ",\n";
    }
    my($pdb, $resid) = split(/:/,$pdbres);
    my $exe = "$pipeline $::v $::info -c $resid $mutant $pdb";
    if($::v ne "")
    {
        print STDERR "\nRunning pipeline command:\n";
        my $progname = $exe;
        $progname =~ s/.*\///;
        print STDERR "   $progname\n";
    }
    my $json = `$exe`;
    print $json;
    $count++;
    if(defined($::limit) && ($count >= $::limit))
    {
        last;
    }
}

# End of JSON
PrintJsonFooter();

##########################################################################
sub UsageDie
{
    print STDERR <<__EOF;

SAAP UniProt Pipeline V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin

Usage: 
uniprotPipeline [-v [-info]] [-limit=n] uniprotAC native resnum newres
                 -v     Verbose
                 -info  Used with -v to get pipeline plugins 
                        to report their info strings
                 -limit Set the maximum number of PDB chains
                        to analyze

Runs the SAAP analysis pipeline on each PDB chain that matches a
specified uniprot accession.

uniprotAC us a UniProt accession (e.g. P69905)

The native and mutant residues (native, newres) may be specified in 
upper, lower or mixed case and using 1-letter or 3-letter code.

__EOF
   exit 0;
}


##########################################################################
sub ParseCmdLine
{
    my ($programName) = @_;

    if(@ARGV != 4)
    {
        &::UsageDie();
    }

    my $ac      = shift(@ARGV);
    my $native  = shift(@ARGV);
    my $resnum  = shift(@ARGV);
    my $mutant  = shift(@ARGV);

    $ac = "\U$ac";

    $native = "\U$native";
    if(defined($SAAP::onethr{$native}))
    {
        $native = $SAAP::onethr{$native};
    }

    $mutant = "\U$mutant";
    if(defined($SAAP::onethr{$mutant}))
    {
        $mutant = $SAAP::onethr{$mutant};
    }

    SAAP::Initialize();

    return($ac, $resnum, $native, $mutant);

}

##########################################################################
sub GetPDBResidues
{
    my ($uniprot, $resnum) = @_;
    my @data = ();

    # Look up the PDB code(s) for this PDB file.
    my @results = PDBSWS::ACQueryAll($uniprot, $resnum);
    if($results[0] eq "ERROR")
    {
        print "{\"SAAP-ERROR\": \"$results[1]\"}\n";
    }
    else
    {
        foreach my $result (@results)
        {
            if($$result{'CHAIN'} =~ /[0-9]/)
            {
                # Numeric chain label so separate chain label from residue with a "."
                push @data, "$$result{'PDB'}:$$result{'CHAIN'}.$$result{'RESID'}";
            }
            else
            {
                # Normal alphabetical chain label
                push @data, "$$result{'PDB'}:$$result{'CHAIN'}$$result{'RESID'}";
            }
        }
    }

    return(@data);
}

##########################################################################
sub PrintJsonHeader
{
    my($programName, $ac, $resnum, $native, $mutant) = @_;

    print <<__EOF;
\{"$programName":
   \{ "uniprotac": "$ac",
     "resnum": $resnum,
     "native": "$native",
     "mutant": "$mutant",
     "pdbs"  : \[
__EOF
}

##########################################################################
sub PrintJsonFooter
{
    print <<__EOF;
      \]
   \}
\}
__EOF
}

