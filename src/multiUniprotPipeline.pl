#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    multiUniprotPipeline
#   File:       multiUniprotPipeline.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Runs the SAAP analysis on a set of mutations (held in a 
#               file) writing the output to a directory
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
#   V1.0  11.11.11  Original   By: ACRM
#   V1.1  12.12.12  Added -r (restart) option
#   V1.2  05.10.18 Updated for reorganization of code
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
my $uniprotPipeline = $config::saapUniprotPipeline;

#*************************************************************************
if(defined($::h) || (int(@ARGV) < 1) || (int(@ARGV) > 2))
{
    UsageDie();
}

$::v       = defined($::v)?"-v":"";
$::restart = (defined($::r)||defined($::restart))?1:0;
$::info    = defined($::info)?"-info":"";
$::limit   = defined($::limit)?"-limit=$::limit":"";

my $outputDir = shift(@ARGV);

# Create an output directory for the JSON files
CreateDir($outputDir);

# Read the list of mutations
while(<>)
{
    chomp;
    my($ac, $native, $resnum, $mutant) = split;

    # TODO plan to keep comments on the same line and pass into the JSON
    s/\#.*//;                   # Remove comments
    s/^\s+//;                   # Remove leading spaces
    next if(!length($_));       # Skip blank lines (comment lines will now be blank)

    my $filename = "$outputDir/${ac}_${native}_${resnum}_${mutant}.json";

    if($::restart && (-f $filename))
    {
        if($::v ne "")
        {
            print STDERR "Skipping mutation: $ac $native $resnum -> $mutant (already done)\n";
        }
    }
    else
    {
        if($::v ne "")
        {
            print "\n\nAnalyzing mutation: $ac $native $resnum -> $mutant\n";
            print "-----------------------------------------\n\n";
        }

        my $exe = "$uniprotPipeline $::v $::info $::limit $ac $native $resnum $mutant > $filename";
        `$exe`;
    }
}


#*************************************************************************
# 12.12.12 Don't remove the directory if restarting
sub CreateDir
{
    my($outputDir) = @_;

    if($::restart)
    {
        if(!(-d $outputDir))
        {
            print STDERR "Can't restart as output directory ($outputDir) doesn't exist.\n";
            exit 1;
        }
    }
    else
    {
        if(-d $outputDir)
        {
            if(defined($::f))
            {
                `rm -rf $outputDir`;
                if( -d $outputDir)
                {
                    print STDERR "Removing output directory ($outputDir) failed. Do you have permissions to remove this directory?\n";
                    exit 1;
                }
            }
            else
            {
                print STDERR "Output directory ($outputDir) exists. Use -f to delete and overwrite.\n";
                exit 1;
            }
        }

        `mkdir $outputDir`;
        if(! -d $outputDir)
        {
            print STDERR "Failed to create output directory.\n";
            exit 0;
        }
    }

}


#*************************************************************************
sub UsageDie
{
    print <<__EOF;

multiUniprotPipeline V3.2 (c) UCL, Dr. Andrew C.R. Martin 2011-2020

Usage: multiUniprotPipeline [-v [-info]] [-r] [-f] [-limit=n] dirName mutantFile
       dirName    - Directory name for results files. Should not exist unless -f
                    specified in which case it will be deleted and re-created.
                    Use -f with care!!!
       mutantFile - File listing the mutations to analyze in the format:
                    UniProtAC Native ResNum Mutant
       -v         - Verbose
       -info      - Pipeline plugins report their info string
       -f         - Force writing a directory by removing and re-creating it
       -limit     - Limit the number of PDB files analyzed
       -r         - Restart from where we got to. Note that there may be a
                    damaged .json file at the end of a previous run, so may
                    be necessary to remove that first. (-restart is a synonym)

Reads a file listing a set of UniProtKB mutations and runs the pipeline on
each of them for all available structures.

__EOF
    exit 0;
}
