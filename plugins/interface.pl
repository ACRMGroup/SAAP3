#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    SAAP
#   File:       interface.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Interface plugin for the SAAP server
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
$::infoString = "Checking if this disturbs a known interface";

my $relaccess    = (-1);
my $relaccessMol = (-1);

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("Interface");

# See if the results are cached
my $json = SAAP::CheckCache("Interface", $pdbfile, $residue, $mutant);
$json = "" if(defined($::force)); 

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

interface.pl V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin
Usage: interface.pl [-force] [chain]resnum[insert] newaa pdbfile
       -force   Force calculation even if results are cached
       (newaa maybe 3-letter or 1-letter code)

Does interface calculations for the SAAP server.
Identifies residues where relative access changes by >10% on binding
       
__EOF
   exit 0;
}
