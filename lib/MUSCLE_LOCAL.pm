package MUSCLE;
#*************************************************************************
#
#   Program:    
#   File:       
#   
#   Version:    V1.1
#   Date:       26.02.14
#   Function:   Access the EBI MUSCLE Web service
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2011-2014
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
#   Set of routines for using the EBI MUSCLE REST web service. Based on
#   the example script supplied by the EBI
#
#*************************************************************************
#
#   Usage:
#   ======
#
#   use MUSCLE;
#   ($error, $result) = RunMuscle($sequences, $email);
#
#   $sequences is the set of sequences in FASTA format
#   $email is your email address
#
#   On Error:   $error is 1 and $result contains a message
#   On Success: $error is 0 and $result contains FASTA alignment
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  31.08.11  Original   By: ACRM
#   V1.1  26.02.14  Modified to force the input format to FASTA since
#                   EBI changed the default to clustal...
#
#*************************************************************************
# Enable Perl warnings
use strict;
use warnings;

# Load libraries
use config;

#-------------------------------------------------------------------------
# RunMuscle()
#
# Submit a MUSCLE job to the service.
#
#  ($error, $result) = RunMuscle($seq, $email);
# The sequences must be in FASTA format
#
# $email is ignored and kept just for compatibility with the web services
# version
#
# 04.10.18 Original   By: ACRM
sub RunMuscle
{
    my($sequences, $email) = @_;
    my $error  = 0;
    my $result = '';
    my $muscle = "$config::binDir/muscle";
    my $tfile  = "/var/tmp/muscle_$$" . time() . ".faa";
    if(! -x $muscle)
    {
        $error = 1;
        $result = "Muscle executable not available ($muscle)";
    }
    else
    {
        if(open(my $fp, '>', $tfile))
        {
            print $fp $sequences;
            close $fp;
            $result = `$muscle -quiet -in $tfile`;
            unlink $tfile;
        }
        else
        {
            $error = 1;
            $result = "Unable to write temporary .faa file";
        }
    }

    return($error, $result);
}

1;
