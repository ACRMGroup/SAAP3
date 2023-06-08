#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    saap
#   File:       install.pl
#   
#   Version:    V1.0
#   Date:       06.09.17
#   Function:   Installation script for the SAAP program
#   
#   Copyright:  (c) Prof. Andrew C. R. Martin, UCL, 2017
#   Author:     Prof. Andrew C. R. Martin
#   Address:    Institute of Structural and Molecular Biology
#               Division of Biosciences
#               University College
#               Gower Street
#               London
#               WC1E 6BT
#   EMail:      andrew@bioinf.org.uk
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
#   ./install.pl
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   06.09.17  Original
#
#*************************************************************************
use strict;
if(! -e 'config.pm')
{
    print <<__EOF;

Installation aborting. You need to create a config.pm config file.

__EOF
    exit 1;
}

if((! -e "$ENV{'HOME'}/lib/libbiop.a") ||
   (! -d "$ENV{'HOME'}/include/bioplib"))
{
    print <<__EOF;

Installation aborting. Bioplib must be installed in ~/lib and ~/include

__EOF
    exit 1;
}


use Cwd qw(abs_path);

# Add the path of the executable to the library path
use FindBin;
use lib $FindBin::Bin;
use lib abs_path("$FindBin::Bin/lib");
use util;
use config;
use SPECSIM;

UsageDie() if(defined($::h));


# Do a specsim accecss in order to create/update the DBM hash file
print "*** Info: Updating SpecSim DBM file\n";
unlink($config::specsimHashFile);
SPECSIM::GetSpecsim($config::specsimDumpFile, $config::specsimHashFile, "MEAN", "MEAN");


#*************************************************************************
#> void UsageDie()
#  ---------------
#  Prints a usage message and exits
#
#  19.09.13  Original  By: ACRM
sub UsageDie
{
    print <<__EOF;

SAAP V1.0 install (c) 2017-2019, Prof. Andrew C.R. Martin, UCL

Usage: ./rebuildspecsim.pl [interface]

Rebuild the specsim hash

      !!!  YOU MUST EDIT config.pm BEFORE USING THIS SCRIPT  !!!

Run as 
   ./rebuildspecsim.pl

__EOF

   exit 0;
}


