#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    SAAP
#   File:       ssgeom.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Disulphide geometry plugin for the SAAP server
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
$::infoString = "Looking for disruption of disulphides";

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("SSGeom");

# See if the results are cached
my $json = SAAP::CheckCache("SSGeom", $pdbfile, $residue, $mutant);
$json = "" if(defined($::force)); 

if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);

my $cacheFile = GetPDBListSSCacheFile($pdbfile);

if(IsSSCys($cacheFile, $residue))
{
    $result = "BAD";
}

$json = SAAP::MakeJson("SSGeom", ('BOOL'=>$result));
print "$json\n";
SAAP::WriteCache("SSGeom", $pdbfile, $residue, $mutant, $json);

sub GetPDBListSSCacheFile
{
    my ($pdbFile) = @_;
    my $cacheFile = $pdbFile;
    $cacheFile =~ s/\//\_/g;
    $cacheFile = "$config::pdbssCacheDir/$cacheFile";

    if(! -d $config::pdbssCacheDir)
    {
        system("mkdir $config::pdbssCacheDir");
        if(! -d $config::pdbssCacheDir)
        {
            my $message = "Unable to create cache dir ($config::pdbssCacheDir)";
            SAAP::PrintJsonError("SSGeom", $message);
            print STDERR "*** Error: $message\n";
            exit 1;
        }
    }
            
    if(! -f $cacheFile) # || (-z $cacheFile))
    {
        my $exe = "$config::binDir/pdblistss $pdbfile $cacheFile";
        system("$exe");
        if(! -f $cacheFile) # || (-z $cacheFile))
        {
            my $message = "Unable to create cache file ($cacheFile)";
            SAAP::PrintJsonError("SSGeom", $message);
            print STDERR "*** Error: $message\n";
            exit 1;
        }
    }

    return($cacheFile);
}


sub IsSSCys
{
    my($cacheFile, $residueIn) = @_;

    my $found  = 0;
    if(open(my $fp, '<', $cacheFile))
    {
        while(<$fp>)
        {
            chomp;
            s/^\s+//;
            my @fields = split;
            if(($fields[0] eq $residueIn) || ($fields[4] eq $residueIn))
            {
                $found = 1;
                last;
            }
        }
        close($fp);
    }
    else
    {
        SAAP::PrintJsonError("SSGeom", "Unable to read cached result file");
        exit 1;
    }

    return($found);
}



sub UsageDie
{
    print STDERR <<__EOF;

ssgeom.pl V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin

Usage: ssgeom.pl [chain]resnum[insert] newaa pdbfile
       -force   Force calculation even if results are cached
       (newaa maybe 3-letter or 1-letter code)

Does disulphide calculations for the SAAP server.
Checks if a native cysteine was involved in a disulphide

__EOF
   exit 0;
}
