#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    SAAP
#   File:       cispro.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   cispro plugin for the SAAP server
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
$::infoString = "Checking whether this was a mutation from a cis-proline";

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("CisPro");

# See if the results are cached
my $json = SAAP::CheckCache("CisPro", $pdbfile, $residue, $mutant);
$json = "" if(defined($::force)); 
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);
my $chainfile = SAAP::GetChain($pdbfile, $chain);
my $native = SAAP::GetNative($pdbfile, $residue);
my($phi,$psi,$omega) = SAAP::GetTorsion($chainfile, $resnum, $insert);

# If it's a change from CisPro to something else...
if(($native eq "PRO") && ($mutant ne "PRO"))
{
    if($phi eq "NULL")
    {
        SAAP::PrintJsonError("CisPro", "Residue not found");
        exit 1;
    }

    my $bad = IsCis($omega);
    if($bad)
    {
        $result = "BAD";
    }
}

unlink($chainfile);

$json = SAAP::MakeJson("CisPro", ('BOOL'=>$result, 'OMEGA'=>$omega, 'NATIVE'=>$native));
print "$json\n";
SAAP::WriteCache("CisPro", $pdbfile, $residue, $mutant, $json);

# Checks whether the omega angle is cis
sub IsCis
{
    my($omega) = @_;

    if (($omega >= -20) && ($omega <= 20))
    {
        return(1);
    }
    return (0);
}

#*************************************************************************
sub UsageDie
{
    print STDERR <<__EOF;

cispro.pl V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin

Usage: cispro.pl [-force] [chain]resnum[insert] newaa pdbfile
       -force   Force calculation even if results are cached
       (newaa maybe 3-letter or 1-letter code)

Does cis-Proline calculations for the SAAP server.
       
__EOF
   exit 0;
}

