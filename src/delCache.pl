#!/usr/bin/perl -s

# TODO - implement the code for deleting from a given uniprot code

#*************************************************************************
#
#   Program:    delCache
#   File:       delCache.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Remove cached entries for a specified mutation
#   
#   Copyright:  (c) UCL / Prof. Andrew C. R. Martin 2014-2020
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
#   V1.0  11.03.14 Original   By: ACRM
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
use TLPCL;
use PDBSWS;

#*************************************************************************
my $programName = "delcache";
my $uniprot = "";

if(defined($::uniprot))
{

}
else
{
    my($residue, $mutant, $pdbfile, $pdbcode) = TLPCL::ParseCmdLine($programName, $::u, (defined($::c)?1:0));
    delcachepdb($residue, $mutant, $pdbfile, $pdbcode, (defined($::all)?1:0));
}

##########################################################################
sub delcachepdb
{
    my($resid, $newres, $pdbfile, $pdbcode, $delAll) = @_;

    my $cacheFile = "${pdbfile}_${resid}_${newres}";
    $cacheFile =~ s/\//_/g;
    $pdbfile =~ s/\//_/g;

    if(opendir(my $cacheDirFP, $config::cacheDir))
    {
        my @programs = sort grep !/~$/, grep !/^\./, readdir $cacheDirFP;
        closedir $cacheDirFP;

        foreach my $program (@programs)
        {
            my $fullProgram = "$config::cacheDir/$program";
            if(-d $fullProgram)
            {
                if($delAll)
                {
                    print STDERR "This will be slow!\nReading directory $fullProgram...";
                    if(opendir(my $progCacheDirFP, $fullProgram))
                    {
                        my @files = grep !/^\./, readdir $progCacheDirFP;
                        print STDERR "done";
                        for my $file (@files)
                        {
                            if($file =~ /^$pdbfile/)
                            {
                                my $fullFile = "$fullProgram/$file";
                                if(defined($::v))
                                {
                                    print STDERR "Deleting $fullFile\n";
                                }
                            }
                        }
                    }
                    else
                    {
                        print STDERR "Can't read program cache directory: $fullProgram\n";
                    }
                }
                else
                {
                    my $fullCacheFile = "$config::cacheDir/${program}/$cacheFile";

                    if(defined($::v))
                    {
                        print STDERR "Deleting $fullCacheFile\n";
                    }
                }
            }
        }
    }
    else
    {
        print STDERR <<__EOF;
        
Can\'t read cache directory: $config::cacheDir
You may need to modify the config file to point to the correct 
directory.

__EOF
    }
}

##########################################################################
sub UsageDie
{
    print STDERR <<__EOF;

*****************************************************************************
*** INCOMPLETE! NEEDS CODE TO DELETE FROM A GIVEN UNIPROT CODE TO BE DONE ***
*****************************************************************************

SAAP Pipeline (c) 2014-2020, UCL, Prof. Andrew C.R. Martin
Usage: 
   Remove cached items for a given PDB file
       delcache [chain]resnum[insert] newres pdbfile
   --or--
       delcache -c [chain]resnum[insert] newres pdbcode
   --or--
       delcache -u=uniprotAC resnum newres pdbfile
   --or--
       delcache -u=uniprotAC -c resnum newres pdbcode

   Remove cached items for a given UniProt code


Function:
   This program deletes entries from the SAAPdap cache

Options:
   -v    Run in verbose mode
   -all  Remove all items for a specified PDB file or UniProt
         code. This is used with the options above do the 
         specified residues are ignored.

If -u is used to specify a UniProt accession (e.g. P69905), then
resnum is a residue number within the UniProt entry. Otherwise it is a
residue ID within a PDB file. Note that if the number is given within
the UniProt entry using -u, then only the first chain that matches
this UniProt ID in the PDB file will be analyzed.

If -c is used then the PDB code must be given. Otherwise a full PDB
file specification must be given.

The replacement residue (newres) may be specified in upper, lower or
mixed case and using 1-letter or 3-letter code.

__EOF
   exit 0;
}

