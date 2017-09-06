#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    saap
#   File:       install.pl
#   
#   Version:    V1.0
#   Date:       06.09.17
#   Function:   Installation script for the abYmod program
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2017
#   Author:     Dr. Andrew C. R. Martin
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
use Cwd qw(abs_path);

# Add the path of the executable to the library path
use FindBin;
use lib $FindBin::Bin;
use lib abs_path("$FindBin::Bin/src/lib");
use config;
use util;

UsageDie() if(defined($::h));

# Check that the destination is correct
if(!DestinationOK("SAAP", $config::saapHome))
{
    print <<__EOF;

Installation aborting. Modify config.pm if you wish to install elsewhere.

__EOF
    exit 1;
}

# Create the installation directories and build the C programs
util::RunCommand("mkdir -p $config::bindir");
BuildPackages();

InstallPrograms($config::bindir);



#*************************************************************************
sub InstallPrograms
{
    my($binDir) = @_;
    util::RunCommand("cp -Rp src/* $binDir");
    util::RunCommand("cp -Rp config.pm $binDir");
}

#*************************************************************************
#> BOOL DestinationOK($progName, $destination)
#  -------------------------------------------
# Checks with the user if the installation destination is OK.
#
# 28.09.15 Original   By: ACRM
#
sub DestinationOK
{
    my($progName, $destination) = @_;
    $|=1;
    print "$pfogName will be installed in $destination\n";
    print "Do you wish to proceed? (Y/N) [Y] ";
    my $response = <>;
    chomp $response;
    $response = "\U$response";
    return(0) if(substr($response,0,1) eq "N");

    # Test we can write to the directory
    # Try to create it if is doesn't exist
    if(! -d $destination)
    {
        system("mkdir -p $destination 2>/dev/null");
    }
    # Fail if it doesn't exist
    if(! -d $destination)
    {
        print STDERR "\n   *** Error: Cannot create installation directory ***\n";
        return(0);
    }
    # Fail if we can't write to it
    my $tFile = "$destination/testWrite.$$";
    system("touch $tFile 2>/dev/null");
    if(! -e $tFile)
    {
        print STDERR "\n   *** Error: Cannot write to installation directory ***\n";
        return(0);
    }
    unlink $tFile;

    return(1);
}


#*************************************************************************
#> void BuildPackages()
#  --------------------
#  Build all C program packages
#
#  06.09.17  Original  By: ACRM
### NEED TO ADD:
# getresol
# addhetv2
# avp
sub BuildPackages
{
    my $dir = util::GetDir($config::chodat);
    util::BuildPackage("./packages/mutmodel_V1.22.tgz",   # Package file
                       "src",                             # Subdir containing src
                       \["mutmodel","clashcalc"],         # Generated executable
                       $config::bindir,                   # Destination binary directory
                       "data",                            # Data directory
                       $config::mmDataDir);               # Destination data directory
    
    util::BuildPackage("./packages/pdbhstrip_V1.4.tgz",   # Package file
                       "",                                # Subdir containing src
                       \["pdbhstrip"],                    # Generated executable
                       $config::bindir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory

    util::BuildPackage("./packages/pdbgetchain_V2.1.tgz", # Package file
                       "",                                # Subdir containing src
                       \["pdbgetchain"],                  # Generated executable
                       $config::bindir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory

}


#*************************************************************************
#> void UsageDie()
#  ---------------
#  Prints a usage message and exits
#
#  19.09.13  Original  By: ACRM
sub UsageDie
{
    print <<__EOF;

SAAP V1.0 install (c) 2017, Dr. Andrew C.R. Martin, UCL

Usage: ./install.pl [interface]

install is the SAAP installer.

      !!!  YOU MUST EDIT config.pm BEFORE USING THIS SCRIPT  !!!

__EOF

   exit 0;
}


