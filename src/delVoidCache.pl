#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    delVoidCache
#   File:       delVoidCache.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Delete the void cache
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
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/..");
use lib abs_path("$FindBin::Bin/");
use config;

$::plugin = "Voids" if(!defined($::plugin));

my $dir = "$config::cacheDir/$::plugin";

my $done = 1;

while($done)
{
    print "Opening directory\n";
    if(opendir(DIR, $dir))
    {
        my $file;
        $done = 0;
        while(($file = readdir(DIR)) && ($done < 1000))
        {
            if($file =~ /^[a-zA-Z0-9\_]/)
            {
                my $fnm = "$dir/$file";
                $done++;
                printf "%4d $fnm\n", $done;
                unlink($fnm);
            }
        }
        close DIR;
    }
}
