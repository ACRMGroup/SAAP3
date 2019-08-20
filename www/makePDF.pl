#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    makePDF
#   File:       makePDF.pl
#   
#   Version:    V1.0
#   Date:       20.06.12
#   Function:   Build PDF files for HTML in a specified directory
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2012
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
#
#*************************************************************************
#
#   Revision History:
#   =================
#
#*************************************************************************
use config;
use lib $config::modulesDir;
use strict;

#*************************************************************************
$::html2pdf   = "$config::saapHome/wkhtml/wkhtmltopdf-amd64 -s A4 -q";

#*************************************************************************
if(int(@ARGV) != 1)
{
    UsageDie();
}

# Grab the directory name containing the files
my $dir = shift(@ARGV);
my $dataDir = "$dir/data";

# Read the directory
my @files = ReadDirectory($dataDir);

Convert($dir, "index.html", 0);

foreach my $file (@files)
{
    Convert($dataDir, $file, 1);
}

#*************************************************************************
sub Convert
{
    my($dir, $file, $expand) = @_;
    my $pdfFile = $file;
    $pdfFile =~ s/\.html$/\.pdf/;
    my $exe = "cd $dir; $::html2pdf $file $pdfFile";
    print "$exe\n";
    system($exe);
}

#*************************************************************************
sub ReadDirectory
{
    my($dir) = @_;
    if(!opendir(DIR, $dir))
    {
        print STDERR "Can't open directory $dir";
        exit 1;
    }
    my @files = grep /\.html$/, grep !/^\./, readdir(DIR);
    closedir DIR;
    return(@files);
}


#*************************************************************************
sub UsageDie
{
    print <<__EOF;

makePDF V1.0

Usage: makePDF rootHTMLDir

Takes the name of a directory containing an index.html file and a data
sub-directoy containing multiple .html files. Converts each into a PDF
file.

__EOF

    exit 0;
}

