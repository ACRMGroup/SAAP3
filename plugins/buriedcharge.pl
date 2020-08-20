#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    SAAP
#   File:       voids.pl
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
#   V1.0  02.11.11 Original
#   V1.1  22.05.12 Changed to use molecule accessibility as a charge at an
#                  interface will be dealt with elsewhere
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
$::infoString = "Analyzing disruption of buried charges";


my $relaccess    = (-1);
my $relaccessMol = (-1);

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("BuriedCharge");

# See if the results are cached
my $json = SAAP::CheckCache("BuriedCharge", $pdbfile, $residue, $mutant);
$json = "" if(defined($::force)); 
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
    my $message = $SAAP::ErrorMessage;
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

buriedcharge.pl V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin

Usage: buriedcharge.pl [-force] [chain]resnum[insert] newaa pdbfile
       -force   Force calculation even if results are cached
       (newaa maybe 3-letter or 1-letter code)

Does buried charge calculations for the SAAP server.
Note that the accessibility is returned as -1 if this is not
a change in charge
       
__EOF
   exit 0;
}
