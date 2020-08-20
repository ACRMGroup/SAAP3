#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    multiJson2html
#   File:       multiJson2html.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Convert a set of JSON files to HTML creating an index.html
#               file at the same time to provide links to all the data
#   
#   Copyright:  (c) Prof. Andrew C. R. Martin, UCL, 2011-2020
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
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  12.12.11 Original   By: ACRM
#   V1.1  05.10.15 Added -name and -wkdir parameters to json2html.pl call
#   V1.2  05.10.18 Updated for reorganization of code
#   V3.2  20.08.20 Bumped for second official release
#
#*************************************************************************
use strict;
no strict 'refs';
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/..");
use lib abs_path("$FindBin::Bin/");
use config;
use JSONSAAP;
use JSONHTML;
use HSL;

#*************************************************************************
$::json2html   = "$config::saapBinDir/json2html";
$::webfilesDir = "$config::gifDir";

#*************************************************************************
if(int(@ARGV) != 1)
{
    UsageDie();
}

# Nopredict parameter
$::nopredict = defined($::nopredict)?"-nopredict":"";

# Grab the directory name containing the files
my $dir = shift(@ARGV);

# Read the directory
my @files = ReadDirectory($dir);

# Find a list of uniprot ACs used in these files
my @acs = FindACs(@files);

# Start the HTML and provide a header
WriteHTMLHeader();

# Print a title for each UniProt entry analyzed
foreach my $ac (@acs)
{
    print <<__EOF;
<div class='mutation'>
<table>
<tr><td>UniProt Entry:</td><td>$ac</td></tr>
</table>
</div>
__EOF

    # Now obtain a sorted list of residues/mutations analyzed for this
    # Uniprot entry
    my @acFiles = GetACFiles($ac, @files);

    # Start a table in the HTML
    print "<div class='mutantsummary'>\n";
    print "<table>\n";
    print "<tr><th>Mutant</th><th>Structures</th><th>Effects</th><th>JSON</th></tr>\n";

    # Run through the files
    foreach my $file (@acFiles)
    {
        # Generate the HTML for this JSON file
        my $jsonFileName = "$dir/$file";
        my $htmlFileName = $jsonFileName;
        $htmlFileName =~ s/\.json/\.html/;
        if(defined($::v))
        {
            print STDERR "Processing $jsonFileName\n";
        }
        my $wkdir=defined($::wkdir)?"-wkdir=$::wkdir/data":"";
        `$::json2html $wkdir $::nopredict -name=$jsonFileName $jsonFileName > $htmlFileName`;

        # Get the mutation name from the file name
        my(undef, $native, $resnum, $mutant) = split(/[\_\.]/, $file);

        # Start the table row
        print "<tr>\n";
        # Create a link to the HTML in our web page table
        print "    <td><a href='$htmlFileName'>$native $resnum -&gt; $mutant</a></td>\n";
        # Summarize JSON data
        SummarizeJsonData($jsonFileName);
        # Create a link to the JSON in our web page table
        print "    <td>[<a href='$jsonFileName'>JSON</a>]</td>";
        # End the table row
        print "\n</tr>\n";
    }
    print "</table>\n";

    print "<p class='footnote'>Hover over the 'Effects' names for an explanation. Numbers in parentheses are the number of structures in which the effect is observed. The colour (green..red) indicates the fraction of structures having the highest count of observed effects. </p>\n";

    print "</div> <!-- mutantsummary -->\n";
}

print "<p><a href='$dir/printpdf.cgi'>[Download PDF]</a></p>\n";

WriteHTMLFooter();

# Copy in the images
`cp $::webfilesDir/*.gif $dir`;
# ACRM+++ 20.06.12
# Copy in the PDF printing script
`cp $::webfilesDir/printpdf.cgi $dir`;
# and allow it to execute as a CGI script
`echo "Options ExecCGI" >$dir/.htaccess`;
# ACRM-END

#*************************************************************************
# Obtains only those files that relate to mutations in the specified AC
# Sort by residue number and mutation
sub GetACFiles
{
    my($ac, @files) = @_;
    my @acFiles = ();

    foreach my $file (@files)
    {
        if($file =~ /^$ac/)
        {
            push @acFiles, $file;
        }
    }

    my @sortedAcFiles = sort {&sortFunction($a, $b)} @acFiles;
    # TODO - sort the list

    return(@sortedAcFiles);
}

#*************************************************************************
sub sortFunction
{
    my ($a, $b) = @_;

    my @fieldsA = split(/[\_\.]/, $a);
    my @fieldsB = split(/[\_\.]/, $b);

    if($fieldsA[2] < $fieldsB[2])
    {
        return(-1);
    }
    elsif($fieldsA[2] > $fieldsB[2])
    {
        return(1);
    }
    else
    {
        if($fieldsA[1] lt $fieldsB[1])
        {
            return(-1);
        }
        elsif($fieldsA[1] gt $fieldsB[1])
        {
            return(1);
        }
    }
    return(0);
}

#*************************************************************************
sub FindACs
{
    my(@files) = @_;

    my %acs = ();
    foreach my $file (@files)
    {
        my ($ac) = split(/\_/,$file);
        $acs{$ac} = 1;
    }
    return(keys %acs);
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
    my @files = grep /\.json$/, grep !/^\./, readdir(DIR);
    closedir DIR;
    return(@files);
}


#*************************************************************************
sub UsageDie
{
    print <<__EOF;

multiJson2html V1.1 (c) 2011-2020 UCL / Prof. Andrew C.R. Martin

Usage: mutiJson2html [-nopredict] [-v] [-wkdir=dir] jsonDir > index.html
       -nopredict - Do not create a 'Predict Pathogenicity' button

Takes the name of a directory containing a set of SAAP pipeline JSON files.
Converts them all to HTML and creates an HTML index file summarizing all the
mutations in the directory.

__EOF

    exit 0;
}

#*************************************************************************
sub WriteHTMLHeader
{
    print <<__EOF
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" 
   "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">

<head>
<title>SAAP analysis</title>

<script type='text/javascript' src='$config::saapURL/js/getElementsByClassName.js'>
<!-- http://robertnyman.com -->
</script>
<script type="text/javascript" src="$config::saapURL/js/overlib/overlib.js">
<!-- overLIB (c) Erik Bosrup -->
</script>

<script type='text/javascript'>
<!--
function toggle_text(obj) 
{
   var text = document.getElementById(obj);
   if ( text.style.display == 'inline' ) { text.style.display = 'none'; }
   else { text.style.display = 'inline'; }
}
function toggle_text_arrow(obj1, obj2) 
{
   var text = document.getElementById(obj1);
   var arrow = document.getElementById(obj2);
   if (( text.style.display == 'inline' ) || ( text.style.display == 'block' ))
   { 
      text.style.display = 'none'; 
      arrow.src = 'down.gif';
   }
   else 
   { 
      text.style.display = 'inline'; 
      arrow.src = 'up.gif';
   }
}
function expand_all()
{
   var tags = document.getElementsByClassName('collapsable');
   for(var tag=0; tag<tags.length; tag++)
   {
      tags[tag].style.display = 'block';
   }

   var arrows = document.getElementsByClassName('fliparrow');
   for(var tag=0; tag<arrows.length; tag++)
   {
      arrows[tag].src = 'up.gif';
   }
}
function collapse_all()
{
   var tags = document.getElementsByClassName('collapsable');
   for(var tag=0; tag<tags.length; tag++)
   {
      tags[tag].style.display = 'none';
   }

   var arrows = document.getElementsByClassName('fliparrow');
   for(var tag=0; tag<arrows.length; tag++)
   {
      arrows[tag].src = 'down.gif';
   }
}
function fixIE()
{
   if (document.getElementsByClassName == undefined) 
   {
      document.getElementsByClassName = function(className)
      {
         var hasClassName = new RegExp("(?:^|\\s)" + className + "(?:$|\\s)");
         var allElements = document.getElementsByTagName("*");
         var results = [];

         var element;
         for (var i = 0; (element = allElements[i]) != null; i++) 
         {
            var elementClass = element.className;
            if (elementClass && elementClass.indexOf(className) != -1 && 
                hasClassName.test(elementClass))
            {
               results.push(element);
            }
         }

         return results;
      }
   }
}

-->
</script>

<style type='text/css'>
<!--
p, td, th, li 
{
   font-family: Helvetica,Arial;
}
h1 
{
   text-align: center;
   font: 24pt Helvetica,Arial
}
h2 
{
   font: 18pt Helvetica,Arial
}
h3 
{
   font: bold 14pt Helvetica,Arial
}
h4 
{
   font: 12pt Helvetica,Arial
}
a img, a:active, a:visited, a:hover 
{
   border: none; vertical-align: top
}
a 
{ 
   outline: none; 
}

.mutation 
{
   background: #666666;
   margin: 0em 0em 1em 0em;
   padding: 2pt;
}
.mutation td 
{
  color: #FFFFFF;
  font: 12pt Helvetica, Arial;
}

.summary .ok   {background: #00FF00;}
.summary .bad  {background: #FF0000;}
.summary .unknown  {background: #AAAAAA;}
.summary table {border-collapse: collapse;
                border: solid 1pt #000000;
                text-align: center;
}
.summary td, .summary th 
{
   border: solid 1pt #000000;
   padding: 2pt;
   font: 10pt Helvetica,Arial;
}
.summary th 
{
   font: 12pt Helvetica,Arial;
}
.summary th a:link, .summary th a:visited, .summary th a:hover, .summary th a:active  
{
   font: 12pt Helvetica,Arial;
   color: #000000;
   text-decoration: none;
}


.mutantsummary
{
  padding: 0pt 0pt 20pt 0pt;
}

.mutantsummary .ok   {background: #00FF00;}
.mutantsummary .bad  {background: #FF0000;}
.mutantsummary .unknown  {background: #AAAAAA;}
.mutantsummary table {border-collapse: collapse;
                border: solid 1pt #000000;
                text-align: left;
}
.mutantsummary td, .mutantsummary th 
{
   border: solid 1pt #000000;
   padding: 2pt;
   font: 12pt Helvetica,Arial;
}
.mutantsummary th a:link, .mutantsummary th a:visited, .mutantsummary th a:hover, .mutantsummary th a:active  
{
   font: 12pt Helvetica,Arial;
   color: #000000;
   text-decoration: none;
}




.footnote 
{ 
   font: italic 8pt Helvetica,Arial;
}

.button 
{
   font: bold 12pt Helvetica,Arial;
   background: #7A96BE;
   margin: 4pt 0pt;
   padding: 1pt 4pt 4pt 4pt;
   border: outset 2pt #000000;
}
.button a:link, .button a:visited, .button a:hover, .button a:active  
{
   font: bold 12pt Helvetica,Arial;
   color: #000000;
   text-decoration: none;
}

.analysis 
{
   border: 1pt solid #000000;
   margin: 1em 0 0 0;
   padding: 0 0 0 0;
   background: #CCCCCC;
}

.analysis h3 {margin: 0 0 0 0;
              padding: 2pt;
              background: #666666;
              color: #FFFFFF;
}
.analysis h4 {margin: 0 0 0 0;
              padding: 0 2pt 2pt 2pt;
              background: #7A96BE;
              color: #FFFFFF;
              border-top: solid 1pt #7A96BE;
              border-left: solid 1pt #7A96BE;
              border-right: solid 1pt #7A96BE;
}
.analysis .left { width: 49%;
}
.analysis .right { width: 49%;
}
.analysis .bad {margin: 0;
                padding: 2pt;
                background: #FF7777;
                border-bottom: solid 1pt #7A96BE;
                border-left: solid 1pt #7A96BE;
                border-right: solid 1pt #7A96BE;
}
.analysis .ok  {margin: 0;
                padding: 2pt;
                background: #AAFFAA;
                border-bottom: solid 1pt #7A96BE;
                border-left: solid 1pt #7A96BE;
                border-right: solid 1pt #7A96BE;
}
.analysis .unknown  {margin: 0;
                padding: 2pt;
                background: #AAAAAA;
                border-bottom: solid 1pt #7A96BE;
                border-left: solid 1pt #7A96BE;
                border-right: solid 1pt #7A96BE;
}
.analysis p {margin: 0;
             padding: 0;
}
.analysis table {width: 100%;
}
.analysis td {vertical-align: top;
}

-->
</style>
</head>
<body>
<!-- <body onload='fixIE();'> -->
<div id="overDiv" style="position:absolute; visibility:hidden; z-index:1000;"></div>

<h1>SAAP Analysis</h1>

<!-- END OF COMMON HEADER -->

__EOF
}

#*************************************************************************
sub WriteHTMLFooter
{
    print <<__EOF

<!-- COMMON FOOTER -->

</body>
</html>

__EOF
}

#*************************************************************************
sub SummarizeJsonData
{
    my($file) = @_;

    # Read the file
    my $content = "";
    if(open(FILE,$file))
    {
        while(<FILE>)
        {
            $content .= $_;
        }
        close(FILE);
    }
    else
    {
        print "    <td>&nbsp;</td>\n";
        print "    <th class='unknown'>JSON file not found: $file</th>\n";
        return;
    }

    # Parse and check for errors
    my $jsonText = JSONSAAP::Decode($content);
    my ($type, $error) = JSONSAAP::Check($jsonText);
    if($error ne "")
    {
        print "    <td>&nbsp;</td>\n";
        print "    <th class='unknown'>$error</th>\n";
        return;
    }

    # 
    # Extract the list of analyses (one for each PDB chain)
    my @jsonSaaps = JSONSAAP::GetSaapArray($jsonText);

    # Get list of analyses performed on the first of these
    my (@analyses) = JSONSAAP::ListAnalyses($jsonSaaps[0]);

    my $summary = "";
    my %badAnalyses = ();

    # Go through each of the structures analyzed - record the 
    # name of each 'bad' analysis in a unique list
    my $nPDB = 0;
    foreach my $jsonSaap (@jsonSaaps)
    {
        $nPDB++;
        foreach my $analysis (@analyses)
        {
            my $resultHash = JSONSAAP::GetAnalysis($jsonSaap, $analysis);

            my $boolKey = "$analysis-BOOL";
            my $ok = $$resultHash{$boolKey};
            
            # Count number of structures for a given analysis where the
            # analysis was flagged as bad
            if($ok eq "BAD")
            {
                if(defined($badAnalyses{$analysis}))
                {
                    $badAnalyses{$analysis}++;
                }
                else
                {
                    $badAnalyses{$analysis} = 1;
                }
            }
        }
    }

    # Copy the list of unique bad analyses to the summary string
    my $maxBad = 0;             # Max fraction of structures having
                                # a particular 'bad' analysis
    foreach my $analysis (sort keys %badAnalyses)
    {
        my $analysisName = "\L$analysis";
        my $count = $badAnalyses{$analysis};
        if($nPDB)
        {
            if(($count/$nPDB) > $maxBad)
            {
                $maxBad = $count/$nPDB;
            }
        }

        if($summary ne "")
        {
            $summary .= " | ";
        }

        $summary .= "<a style=\"text-decoration: none\" href=\"javascript:void(0);\" \
onmouseover=\"return overlib('$JSONHTML::explain{$analysisName}');\" \
onmouseout=\"return nd();\">$analysis ($count)</a> ";
    }

    # Print number of structures
    print "    <td>$nPDB</td>\n";

    # Print summary
    if($summary eq "")
    {
        my $colour = HSL::hexWarningColour(0);
        print "    <td>";
        print "<span style='background: $colour;'>&nbsp;&nbsp;&nbsp;&nbsp;</span> ";
        print "No structural effects identified";
        print "</td>\n";
    }
    else
    {
        my $colour = HSL::hexWarningColour($maxBad);
        print "    <td>";
        print "<span style='background: $colour;'>&nbsp;&nbsp;&nbsp;&nbsp;</span> ";
        print $summary;
        print "</td>\n";
    }
}
