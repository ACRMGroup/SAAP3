#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    pipeline
#   File:       pipeline.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Runs the SAAP analysis pipeline
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
#   V1.0  04.11.11 Original   By: ACRM
#   V1.1  05.10.18 Updated for reorganization of code
#   V3.2  20.08.20 Added some command line error checking for use with
#                  -model and new -r parameter to allow the residue number
#                  in the UniProt file to be different from in the PDB
#                  file with -model
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
use PDB;

#*************************************************************************
my $programName = "SAAP";
my $uniprot = "";
my($residue, $mutant, $pdbfile, $pdbcode) = ParseCmdLine($programName, $::u, (defined($::c)?1:0));

if(defined($::model))
{
    UsageDie() if(!defined($::u) || !defined($::i));

    $::uniAC  = $::u;
    $::uniID  = $::i;
    $::uniRes = $residue;
    
    if(!defined($::r))
    {
        print STDERR <<__EOF;

Warning: assuming the residue number in the UniProt file is the same as the
         one provided for the PDB file.

__EOF
    }
    else
    {
        $::uniRes = $::r;
    }
}

if(opendir(PLUGINS, $config::pluginDir))
{
    my @plugins = sort grep !/~$/, grep !/^\./, readdir PLUGINS;
    closedir PLUGINS;

    # Print start of JSON
    PrintJsonHeader($programName, $residue, $mutant, $pdbfile, $pdbcode);

    if(SAAP::CheckRes($pdbfile, $residue))
    {
        my @results = ();

        foreach my $plugin (@plugins)
        {
            my $fullPlugin = "$config::pluginDir/$plugin";
            # If it's executable and not a directory
            if((-x $fullPlugin) && !(-d $fullPlugin)) 
            {
                if(defined($::v))
                {
                    if(defined($::info))
                    {
                        my $info = `$fullPlugin -info`;
                        chomp $info;
                        $info =~ s/^\s+//;
                        if(length($info))
                        {
                            print STDERR "$info...";
                        }
                        else
                        {
                            print STDERR "Running plugin: $plugin...";
                        }
                    }
                    else
                    {
                        print STDERR "Running plugin: $plugin...";
                    }
                    
                    if(defined($::model))
                    {
                        push @results, `$fullPlugin -v $::force -uniAC=$::uniAC -uniID=$::uniID -uniRes=$::uniRes $residue $mutant $pdbfile`;
                    }
                    else
                    {
                        push @results, `$fullPlugin -v $::force $residue $mutant $pdbfile`;
                    }
                }
                else
                {
                    if(defined($::model))
                    {
                        push @results, `$fullPlugin $::force -uniAC=$::uniAC -uniID=$::uniID -uniRes=$::uniRes $residue $mutant $pdbfile`;
                    }
                    else
                    {
                        push @results, `$fullPlugin $::force $residue $mutant $pdbfile`;
                    }
                }
                if(defined($::v))
                {
                    print STDERR "done\n";
                }
            }
        }
        
        PrintJsonStartResults();
        for(my $i=0; $i<int(@results); $i++)
        {
            my $result = $results[$i];
            chomp $result;
            my $pluginName = GetPluginName($result);
            print "         \"$pluginName\": $result";
            if($i<(int(@results)-1))
            {
                print ",\n";
            }
            else
            {
                print "\n";
            }
        }
        PrintJsonEndResults();
    }
    else
    {
        print "     \"ERROR\": \"PDB file ($pdbfile) does not contain residue ($residue)\"\n";
    }
    # End of JSON
    PrintJsonFooter($programName, $residue, $mutant, $pdbfile);

}
else
{
    print STDERR <<__EOF;

Can\'t read plugin directory: $config::pluginDir
You may need to modify the config file to point to the correct 
directory.

__EOF

}


##########################################################################
sub UsageDie
{
    print STDERR <<__EOF;

SAAP Pipeline V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin
Usage: 
       pipeline [chain]resnum[insert] newres pdbfile
   --or--
       pipeline -c [chain]resnum[insert] newres pdbcode
   --or--
       pipeline -u=uniprotAC resnum newres pdbfile
   --or--
       pipeline -u=uniprotAC -c resnum newres pdbcode
   --or--
       pipeline -model -u=uniprotAC -i=uniprotID [-r=uniprotResnum]
                [chain]resnum[insert] newres pdbfile

Options for all forms:
   -v     Run in verbose mode - reports which plugin is being run and
          causes plugins to run in verbose mode
   -info  With -v causes each plugin to report its info string rather
          that just naming the plugin
   -force Do not use cached values, but force recalculating
    
Runs the SAAP analysis pipeline.

If -model is used then both UniProt accession and UniProt IDs must be
supplied. If the residue number in the UniProt file differs from the
number in the PDB file, then the UniProt residue number must be given
with -r (as well as the PDB residue number supplied as an argument).
NOTE - cacheing is based on the PDB residue number, not the UniProt
residue number given with -r so you will have to use -force to
recalculate everything if you make a mistake with the residue numbers.    

If it is not a model, then if -u is used to specify a UniProt accession
(e.g. P69905), then resnum is a residue number within the UniProt entry.
Otherwise it is a residue ID within a PDB file. Note that if the number 
is given within the UniProt entry using -u, then only the first chain 
that matches this UniProt ID in the PDB file will be analyzed.

If -c is used then the PDB code must be given. Otherwise a full PDB
file specification must be given.

The replacement residue (newres) may be specified in upper, lower or
mixed case and using 1-letter or 3-letter code.

__EOF
   exit 0;
}


##########################################################################
sub ParseCmdLine
{
    my ($programName, $uniprot, $pdbcode) = @_;

    if(scalar(@ARGV) != 3)
    {
        &::UsageDie();
    }

    my $residue = shift(@ARGV);
    my $mutant  = shift(@ARGV);
    my $file    = shift(@ARGV);

    my $pdbfile = "";

    $::force = (defined($::force))?"-force":"";
    
    if(defined($::model))
    {
        $pdbfile = $file;
        $mutant = "\U$mutant";
        if(defined($SAAP::onethr{$mutant}))
        {
            $mutant = $SAAP::onethr{$mutant};
        }

        SAAP::Initialize();

        return($residue, $mutant, $pdbfile, 'NA');
    }
    else
    {
        if($pdbcode)
        {
            $file    = "\L$file";   # Lower case
            $pdbfile = $config::pdbPrep . $file . $config::pdbExt;
            $pdbcode = "$file";

            if(! -e $pdbfile)
            {
                $pdbfile = "/var/tmp/$file" . $config::pdbExt;
                if(! -e $pdbfile)
                {
                    print STDERR "Grabbing $pdbfile..." if(defined($::d));
                    PDB::GrabPDB($pdbcode, $pdbfile);
                    print STDERR "done\n" if(defined($::d));
                }
            }
        }
        else
        {
            $pdbfile = $file;
            if($file =~ /.*(\d...)\.[pe][dn][bt]/)
            {
                $pdbcode = $1;
                $pdbcode = "\L$pdbcode";
            }
        }

        if(! -e $pdbfile)
        {
            SAAP::PrintJsonError($programName, "PDB file ($pdbfile) does not exist");
            exit 1;
        }

        if($uniprot ne "")
        {
            # Look up the PDB code(s) for this PDB file.
            my @results = PDBSWS::ACQueryAll($uniprot, $residue);
            if($results[0] eq "ERROR")
            {
                SAAP::PrintJsonError($programName, "UniProt accession code ($uniprot) not known in PDBSWS");
                exit 1;
            }

            $residue = "";
            foreach my $result (@results)
            {
                if($$result{'PDB'} eq $pdbcode)
                {
                    $residue = $$result{'CHAIN'} . $$result{'RESID'};
                    last;
                }
            }
            if($residue eq "")
            {
                SAAP::PrintJsonError($programName, "PDB code ($pdbcode) is not found as a match UniProt accession ($uniprot) in PDBSWS");
                exit 1;
            }
        }

        $mutant = "\U$mutant";
        if(defined($SAAP::onethr{$mutant}))
        {
            $mutant = $SAAP::onethr{$mutant};
        }

        SAAP::Initialize();

        return($residue, $mutant, $pdbfile, $pdbcode);
    }
    
}

##########################################################################
sub GetExperimentalData
{
    my($pdbfile) = @_;

    my $getresol = "$config::binDir/getresol";
    my $result = `$getresol $pdbfile`;
    chomp $result;
    $result =~ s/\s//g;
    my($type, $resol, $rfactor) = split(/[\,\/]/, $result);
    return($type, $resol, $rfactor);
}

##########################################################################
sub PrintJsonHeader
{
    my($programName, $residue, $mutant, $pdbfile, $pdbcode) = @_;

    my($structureType, $resolution, $rfactor) = GetExperimentalData($pdbfile);

    print <<__EOF;
\{"$programName":
   \{ "file": "$pdbfile",
     "pdbcode": "$pdbcode",
     "residue": "$residue",
     "mutation": "$mutant",
     "structuretype": "$structureType",
     "resolution": "$resolution",
     "rfactor": "$rfactor",
__EOF
}

##########################################################################
sub PrintJsonFooter
{
    print <<__EOF;
   \}
\}
__EOF
}

##########################################################################
sub PrintJsonStartResults
{
    print <<__EOF;
     "results": \{
__EOF
}

##########################################################################
sub PrintJsonEndResults
{
    print <<__EOF;
      \}
__EOF
}

##########################################################################
sub GetPluginName
{
    my($result) = @_;

    # Remove characters: " { } \n
    $result =~ s/[\"\{\}\n]//g;
    # Remove anything after the first -
    $result =~ s/-.*//;
    $result =~ s/\s+//g;
    # Remainder is the plugin name
    return($result);
}
