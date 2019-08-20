#!/usr/bin/perl
#*************************************************************************
#
#   Program:    printpdf
#   File:       printpdf.cgi
#   
#   Version:    V1.0
#   Date:       21.06.12
#   Function:   Print a PDF of the current web page
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2012
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Structural & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   EMail:      andrew@bioinf.org.uk
#               andrew.martin@ucl.ac.uk
#   Web:        http://www.bioinf.org.uk/
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
#   Returns the current web page as a PDF file using wkhtmltopdf to do
#   the conversion.
#
#   You simply provide a link to this script on the web page.
#
#   The code makes use of the CGI referer information to obtain the URL
#   of the page from which this script was called.
#
#   If called with ?expand=1 parameter, then any "style='display: none'"
#   items are replaced with "style='display: inline'" to expand any
#   hidden text.
#
#*************************************************************************
#
#   Usage:
#   ======
#
#   You simply provide a link to this script on the web page.
#      <a href='printpdf.cgi'>[Print PDF]</a>
#   --or--
#      <a href='printpdf.cgi?expand=1'>[Print Expanded PDF]</a>
#
#*************************************************************************
#
#   Revision History:
#   =================
#
#*************************************************************************
use CGI;
use strict;
#*************************************************************************
# CONFIGURE THIS to point to your HTML to PDF converter - with any options
# needed 
my $html2pdf = "wkhtmltopdf -q -s A4";

#*************************************************************************
my $cgi = new CGI;
my $url = $cgi->referer();
my $expand = $cgi->param('expand');
my $tstem = "/tmp/$$".time;

if($url ne "")
{
    my $pdffile = "$tstem.pdf";
    my $hfile1 = "$tstem.1.html";
    my $hfile2 = "$tstem.2.html";
    
    if($expand)
    {
        `wget -O $hfile1 $url`; 
        Expand($hfile1, $hfile2, $url);
        `$html2pdf $hfile2 $pdffile`;
    }
    else
    {
        `$html2pdf $url $pdffile`;
    }
    print $cgi->header(-type=>"application/pdf");
    my $pdf = `cat $pdffile`;
    unlink $pdffile;
    unlink $hfile1;
    unlink $hfile2;

    print $pdf;
}
else
{
    print $cgi->header();
    print <<__EOF;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" 
   "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<link rel='stylesheet' href='/bo.css' />
<title>www.bioinf.org.uk : Dr. Andrew C.R. Martin's Group at UCL</title>
<meta http-equiv="pragma" content="no-cache" />
<meta http-equiv="expires" content="0" />
<meta http-equiv="Cache-control" content="no-cache" />
</head>
<body>
<p>
</p>
</body>
<div id='header'>
<p>www.bioinf.org.uk : Dr. Andrew C.R. Martin's Group</p>
</div> <!-- header -->
<div id='separator'>
<form method='get' action='http://www.google.com/search' >
<p>
<input type='hidden' name='as_sitesearch' value='bioinf.org.uk' />
<input type='text' name='as_q' size='20' value='Search site' onclick="document.forms[0].as_q.value=''" />
</p>
</form>
</div> <!-- separator -->


<div id='mainpage' style='margin: 10pt;'>
<h1>Error</h1>
<p>PDF printing is not supported on this browser.</p>
</div>

</body>
</html>

__EOF
}

#*************************************************************************
sub Expand
{
    my($hfile1, $hfile2, $url) = @_;

    # Work out base URL - remove anything after final / which matches *.*
    $url =~ s/\/\w+\.\w+$/\//;

    if(open(FILE1, $hfile1))
    {
        if(open(FILE2, ">$hfile2"))
        {
            while(<FILE1>)
            {
                s/display:\s*none/display:inline/g;
                if(/src\s*=\s*[\'\"](.*?)[\'\"]/)
                {
                    my $link = $1;
                    if(!($link=~/^http/))
                    {
                        s/src\s*=\s*[\'\"].*?[\'\"]/src=\'$url$link\'/;
                    }
                }
                print FILE2;
            }
            close FILE2;
        }
        close FILE1;
    }
}

