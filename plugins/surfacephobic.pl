#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    
#   File:       surfacephobic.pl
#   
#   Version:    V1.0
#   Date:       16.12.11
#   Function:   Surface Phobic plugin for the SAAP server
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2011
#   Author:     Dr. Andrew C. R. Martin
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
#   V1.0  16.12.11 Original
#
#*************************************************************************
use strict;
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/");
use config;
use XMAS;
use SAAP;

# Information string about this plugin
$::infoString = "Looking for hydrophobics introduced on the surface";

my $relaccess    = (-1);
my $relaccessMol = (-1);

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("SurfacePhobic");

# See if the results are cached
my $json = SAAP::CheckCache("SurfacePhobic", $pdbfile, $residue, $mutant);
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
        SAAP::PrintJsonError("SurfacePhobic", "Residue not found");
        exit 1;
    }
    my $message = $XMAS::ErrorMessage[$status];
    SAAP::PrintJsonError("SurfacePhobic", $message);
    exit 1;
}

if($relaccessMol >= $SAAP::surface)
{
    # If it's a change from hydrophilic to hydrophobic...
    if(($SAAP::hydrophobicity{$native} < 0.0) && 
       ($SAAP::hydrophobicity{$mutant} > 0.3))
    {
        $result = "BAD";
    }
}

$json = SAAP::MakeJson("SurfacePhobic", ('BOOL'=>$result, 'RELACCESS'=>$relaccessMol, 'NATIVE-HPHOB'=>$SAAP::hydrophobicity{$native}, 'MUTANT-HPHOB'=>$SAAP::hydrophobicity{$mutant}));
print "$json\n";
SAAP::WriteCache("SurfacePhobic", $pdbfile, $residue, $mutant, $json);



sub UsageDie
{
    print STDERR <<__EOF;

surfacephobic.pl V1.0 (c) 2011, UCL, Dr. Andrew C.R. Martin
Usage: surfacephobic.pl [chain]resnum[insert] newaa pdbfile
       (newaa maybe 3-letter or 1-letter code)

Does surface hydrophobic calculations for the SAAP server.

__EOF
   exit 0;
}
