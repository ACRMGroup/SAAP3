#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    json2html
#   File:       json2html.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Converts a SAAP pipeline JSON file to HTML for display
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
#   If new analyses are added, then appropriate parsers should be provided
#   in JSONHTML.pm (this code provides a default parser)
#   Takes optional parameter [-nopredict] - if present the 
#   'Predict Pathogenicity' button is NOT printed
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  12.12.11 Original
#   V1.1  20.06.12 Added Javascript for getElementsByClassName()
#   V1.2  05.10.15 Added support for running prediction
#   V1.3  05.10.18 Updated for reorganization of code
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
use JSONHTML;
use JSONSAAP;

#*************************************************************************
$::webfilesDir = "$config::saapHome/webdata";

#*************************************************************************
# Grab the file
my $content = "";
while(<>)
{
    $content .= $_;
}

WriteHTMLHeader();

my $jsonText = JSONSAAP::Decode($content);

my ($type,$error) = JSONSAAP::Check($jsonText);
my $uniprotAC = "";
my $uniprotRes = "";
my $uniprotNative = "";
my $uniprotMutant = "";

if($error ne "")
{
    ($uniprotAC, $uniprotRes, $uniprotNative, $uniprotMutant) = JSONSAAP::IdentifyUniprotSaap($jsonText);
    PrintHTMLIdentity("UniProt", $uniprotAC, $uniprotRes, $uniprotNative, $uniprotMutant);

#    print "<div class='mutation'><table><tr><td>Error</td></tr></table></div>\n";
    print "<h2>Error</h2>\n";
    print "<p>No crystal structures could be analyzed:</p>\n";
    $error =~ s/\|/<br \/>/g;
    print "<p>$error</p>\n";
}
else
{
    # This is a JSON file containing an analysis of a UniProt accession
    # mapping to one or more PDB files
    if($type eq "SAAPS")
    {
        ($uniprotAC, $uniprotRes, $uniprotNative, $uniprotMutant) = JSONSAAP::IdentifyUniprotSaap($jsonText);
        PrintHTMLIdentity("UniProt", $uniprotAC, $uniprotRes, $uniprotNative, $uniprotMutant);
    }
    elsif($type eq "SAAP")
    {
        my($pdbfile, $pdbcode, $chain, $resnum, $pdbMutant) = JSONSAAP::IdentifyPDBSaap($jsonText);
        PrintHTMLIdentity("PDB", "$pdbfile ($pdbcode)", "$chain$resnum", "", $pdbMutant);
    }

    # Extract the list of analyses (one for each PDB chain)
    my @jsonSaaps = JSONSAAP::GetSaapArray($jsonText);

    # Get list of analyses performed on the first of these
    my (@analyses) = JSONSAAP::ListAnalyses($jsonSaaps[0]);

    # Print summary table
    PrintSummary(\@jsonSaaps, \@analyses);
    
    # Print the button for running a prediction
    PrintPredictButton() if(!defined($::nopredict));

    # Start of the structural analysis
    PrintStructuralAnalysisHeader();

    foreach my $jsonSaap (@jsonSaaps)
    {
        my $error = "";
        my $junk  = "";

        if($type eq "SAAPS")
        {
            # There are (potentially) multiple PDB files, so the Check() routine called above
            # will only have exited if *all* failed. In that case we need to check each one
            # for an individual structure failing
            ($junk, $error) = JSONSAAP::Check($jsonSaap);
        }

        # This looks after printing an error message if needed otherwise printing
        # analysis results
        PrintStructuralAnalysis($jsonSaap, $error, @analyses);
    }

}

print <<__EOF;
<p>
<a href='./printpdf.cgi'>[Download Summary PDF]</a>
<a href='./printpdf.cgi?expand=1'>[Download Expanded PDF]</a>
</p>
__EOF

WriteHTMLFooter();


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
      arrow.className = 'fliparrow fas fa-angle-down';
   }
   else 
   { 
      text.style.display = 'inline'; 
      arrow.className = 'fliparrow fas fa-angle-up';
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
      arrows[tag].className = 'fliparrow fas fa-angle-up';
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
      arrows[tag].className = 'fliparrow fas fa-angle-down';
   }
}

function fixIE()
{
//    document.getElementsByClassName("submit").disabled = false;

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

<!-- Ajax for Predict button -->
<script type='text/javascript' src='$config::predictURL/predictAjax.js'></script>

<link rel='stylesheet' href='$config::saapURL/css/font-awesome/css/fontawesome.min.css' />
<link rel='stylesheet' href='$config::saapURL/css/font-awesome/css/solid.min.css' />

<style type='text/css'>
<!--
p, td, th, li {  font-family: Helvetica,Arial; }

h1 
{  text-align: center;
   font: 24pt Helvetica,Arial
}

h2 { font: 18pt Helvetica,Arial;      }
h3 { font: bold 14pt Helvetica,Arial; }
h4 { font: 12pt Helvetica,Arial;      }
a  { outline: none;                   }

a span, a:active, a:visited, a:hover 
{  border: none; 
   color: #000000;
   text-decoration: none;
}

.mutation 
{  background: #666666;
   margin: 0em 0em 1em 0em;
   padding: 2pt;
}

.mutation td 
{  color: #FFFFFF;
   font: 12pt Helvetica, Arial;
}

.summary .ok      {background: #cccccc;}
.summary .bad     {background: #FF0000;}
.summary .unknown {background: #AAAAAA;}

.summary table    
{  border-collapse: collapse;
   border: solid 1pt #000000;
   text-align: center;
}

.summary td, .summary th 
{  border: solid 1pt #000000;
   padding: 2pt;
   font: 10pt Helvetica,Arial;
}

.summary th { font: 12pt Helvetica,Arial; }

.summary th a:link, .summary th a:visited, .summary th a:hover, .summary th a:active  
{  font: 12pt Helvetica,Arial;
   color: #000000;
   text-decoration: none;
}

.mutantsummary .ok      {background: #00FF00;}
.mutantsummary .bad     {background: #FF0000;}
.mutantsummary .unknown {background: #AAAAAA;}

.mutantsummary table    
{  border-collapse: collapse;
   border: solid 1pt #000000;
   text-align: left;
}

.mutantsummary td, .mutantsummary th 
{  border: solid 1pt #000000;
   padding: 2pt;
   font: 12pt Helvetica,Arial;
}

.mutantsummary th a:link, .mutantsummary th a:visited, .mutantsummary th a:hover, .mutantsummary th a:active  
{  font: 12pt Helvetica,Arial;
   color: #000000;
   text-decoration: none;
}

.footnote 
{  font: italic 8pt Helvetica,Arial;
}

.button 
{  font: bold 12pt Helvetica,Arial;
   background: #7A96BE;
   margin: 4pt 0pt;
   padding: 1pt 4pt 4pt 4pt;
   border: outset 2pt #000000;
}

.button a:link, .button a:visited, .button a:hover, .button a:active  
{  font: bold 12pt Helvetica,Arial;
   color: #000000;
   text-decoration: none;
}

.analysis 
{  border: 1pt solid #000000;
   margin: 1em 0 0 0;
   padding: 0 0 0 0;
   background: #CCCCCC;
}

.analysis h3 
{  margin: 0 0 0 0;
   padding: 2pt;
   background: #666666;
   color: #FFFFFF;
}

.analysis h4 
{  margin: 0 0 0 0;
   padding: 0 2pt 2pt 2pt;
   background: #aaaaaa;
   color: #000000;
   border: solid 1pt #777777;
}

.analysis .left  { width: 49%; }
.analysis .right { width: 49%; }

.analysis .bad 
{  margin: 0;
   padding: 2pt;
   background: #eeeeee;
   border: solid 3px #ff0000;
}

.analysis .ok  
{  margin: 0;
   padding: 2pt;
   background: #eeeeee;
   border: solid 3px #eeeeee;
}

.analysis .unknown  
{  margin: 0;
   padding: 2pt;
   background: #AAAAAA;
   border-bottom: solid 1pt #7A96BE;
   border-left: solid 1pt #7A96BE;
   border-right: solid 1pt #7A96BE;
}

.analysis p 
{  margin: 0;
   padding: 0;
}

.analysis table { width: 100%; }
.analysis td    {vertical-align: top; }

.resultsFrame
{  background: #FFFFFF;
   border: solid 1px #666666;
   padding: 1em;
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
sub PrintHTMLIdentity
{
    my($type, $ac, $resnum, $native, $mutation) = @_;

    print <<__EOF;

<!-- INFO ON THE MUTATION -->
<div class='mutation'>
<table>
<tr><td>$type Entry:</td><td>$ac</td></tr>
<tr><td>Mutation:</td><td>$native $resnum-&gt;$mutation</td></tr>
</table>
</div>
<!-- END OF INFO ON THE MUTATION -->

__EOF

}


#*************************************************************************
sub PrintSummary
{
    my ($pJsonSaaps, $pAnalyses) = @_;

    print <<__EOF;
<!-- BEGIN SUMMARY -->
<h2>Summary</h2>

<div class='summary'>
<table>
    <tr>
        <th>PDB</th>
        <th>chain</th>
__EOF

   foreach my $analysis (@$pAnalyses)
   {
       my $analysisName = "\L$analysis";
       print <<__EOF;
        <th><a href="javascript:void(0);" 
        onmouseover="return overlib('$JSONHTML::explain{$analysisName}');" 
        onmouseout="return nd();">$analysis</a>
        </th>
__EOF
   }

    print <<__EOF;
    </tr>
__EOF

    # Go through each of the structures analyzed
    foreach my $jsonSaap (@$pJsonSaaps)
    {
        my($pdbfile, $pdbcode, $chain, $resnum, $mutant) = JSONSAAP::IdentifyPDBSaap($jsonSaap);
        my $id = "\#P$pdbcode$chain";
        my ($experiment, $resol, $rfactor) = JSONSAAP::GetPDBExperiment($jsonSaap);
        my $warning = "";
        if(($resol > 2.5) || ($resol == 0.0))
        {
            $warning = " <a href=\"javascript:void(0);\" 
        onmouseover=\"return overlib('The structure has poor resolution. Detailed structural analyses should be interpreted with caution.');\" 
        onmouseout=\"return nd();\"><span style='color: orange;' class='fas fa-exclamation-triangle'></span></a>";
        }
        print <<__EOF;
        <tr><td align='left'><a href='$id'>$pdbcode</a> $warning</td>
            <td>$chain</td>
__EOF
        foreach my $analysis (@$pAnalyses)
        {
            my $boolKey = "$analysis-BOOL";
            my $resultHash = JSONSAAP::GetAnalysis($jsonSaap, $analysis);
            my $ok = $$resultHash{$boolKey};
            if($ok eq "OK")
            {
                print "<td class='ok'>&nbsp;</td>\n";
            }
            elsif($ok eq "BAD")
            {
                print "<td class='bad'>X</td>\n";
            }
            else
            {
                print "<td class='unknown'>?</td>\n";
            }

        }
        print "        </tr>\n";
    }
   
    print <<__EOF;
</table>
<p class='footnote'>Hover over the column titles for an explanation.</p>
</div>

<!-- END SUMMARY -->
__EOF

}

#*************************************************************************
sub PrintStructuralAnalysisHeader
{
    print <<__EOF;
<!-- BEGIN STRUCTURAL ANALYSIS HEADER -->
<h2>Structural analysis</h2>

<div style='text-align: center;'>
<button onclick='expand_all();'>Expand all</button>
&nbsp;&nbsp; 
<button onclick='collapse_all();'>Collapse all</button>
</div>

<!-- END STRUCTURAL ANALYSIS HEADER -->

__EOF
}

#*************************************************************************
sub PrintStructuralAnalysis
{
    my($jsonSaap, $error, @analyses) = @_;

    my ($pdbfile, $pdbcode, $chain, $residue, $mutation) = JSONSAAP::IdentifyPDBSaap($jsonSaap);
    my ($experiment, $resol, $rfactor) = JSONSAAP::GetPDBExperiment($jsonSaap);
    my $experimental = "Structure type: $experiment \| Resolution: $resol";
    if($experiment eq "crystal")
    {
        $experimental .= " \| R-factor: $rfactor";
    }
    if(($resol > 2.5) || ($resol == 0.0))
    {
        $experimental .= " <a href=\"javascript:void(0);\" 
        onmouseover=\"return overlib('The structure has poor resolution. Detailed structural analyses should be interpreted with caution.');\" 
        onmouseout=\"return nd();\"><span style='color: orange;' class='fas fa-exclamation-triangle'></span></a>";
    }

    my $id = "P$pdbcode$chain";

    print <<__EOF;
<!-- BEGIN A STRUCTURAL ANALYSIS -->
<div class='analysis'>
<h3 id='$id'>$pdbcode Residue $chain$residue \| $experimental</h3>
__EOF

    if($error ne "")
    {
        print "<p>Error: $error</p>\n";
    }
    else
    {
        print <<__EOF;
<table>
<colgroup>
<col class='left' />
<col class='right' />
</colgroup>
__EOF

        my $count = 0;
        foreach my $analysis (@analyses)
        {
            if($count%2 == 0)
            {
                print "<tr>\n";
            }
            my $aid = "P$pdbcode$chain$analysis";
            print <<__EOF;
    <td>
        <h4>$analysis
        <a href="javascript:toggle_text_arrow('$aid','${aid}Arrow')">
        <span class='fliparrow fas fa-angle-down ' id='${aid}Arrow' ></span>
        </a> 
        </h4>
__EOF
            my($ok, $para1, $para2) = GetData($jsonSaap, $analysis);

            print <<__EOF;
        <div class='$ok'>
        <p>$para1</p>
        <p id='$aid' class='collapsable' style='display: none'>
           $para2
        </p>
        </div>
    </td>
__EOF

            $count++;
            if($count%2 == 0)
            {
                print "</tr>\n";
            }
        }

        if($count%2 != 0)
        {
            print "</tr>\n";
        }

        print "</table>\n";
    }

    print <<__EOF;
</div> <!-- analysis -->
<!-- END A STRUCTURAL ANALYSIS -->
<!-- ********************************************************************* -->
__EOF

}


#*************************************************************************
sub GetData
{
    my($jsonSaap, $analysis) = @_;

    my $resultHash = JSONSAAP::GetAnalysis($jsonSaap, $analysis);
    my $error = $$resultHash{"$analysis-ERROR"};
    if($error ne "")
    {
        return("unknown", "An analysis error occurred", $error);
    }

    my $ok    = $$resultHash{"$analysis-BOOL"};
    $ok = "\L$ok";
    if($ok eq "")
    {
        $ok = "unknown";
    }

    # A horrible bit of Perl to call the relevant parser for each analysis
    # A better way to do this is iven the name of the package a function 
    # lives in and the function name itself, we can retrieve the code reference 
    # for that function using $package->can($function), without having to turn 
    # strict refs off. Hence we can build a lookup table of code references
    # and use them explicitly
    # sub route {
    #    print "hello, world!";
    #}
    #
    #my %h;
    #$h{a} = \&route;
    #
    #$h{a}->();
    my $parser = "JSONHTML::Parse$analysis";
    my($para1, $para2);
    if(defined &$parser)
    {
        ($para1, $para2) = &$parser(%$resultHash);
    }
    else
    {
        ($para1, $para2) = ParseDefault(%$resultHash);
    }
    
    return($ok, $para1, $para2);
}


#*************************************************************************
# Default JSON result parser - used if a specific parser isn't available
# for an analysis
sub ParseDefault
{
    my(%results) = @_;
    my @keyNames = keys(%results);
    my $progname = @keyNames[0];
    $progname =~ s/-.*//;       # Remove the -xxxxx part

    my $para1 = "No problems identified";
    if($results{$progname . "-BOOL"} eq "BAD")
    {
        $para1 = "$progname identified a potential disrupting effect";
    }

    my $para2 = "";
    foreach my $key (@keyNames)
    {
        my $analysis = $key;
        $analysis =~ s/${progname}-//;
        
        if($analysis ne "BOOL")
        {
            if($para2 ne "")
            {
                $para2 .= "<br />";
            }
            $para2 .= "$analysis : $results{$key}";
        }
    }
    return($para1, $para2);
}


sub PrintPredictButton
{
    if(defined($::name))
    {
        my $jsonFile = $::name;
        $jsonFile    =~ s/(.*\/)//;
        my $dir      = "$config::webTmpDir/" . $1;
        my $urlPath  = $config::predictURL;

        print <<__EOF;
<!--    <p style='background: yellow;'>WKDIR: $::wkdir NAME: $::name JSON: $jsonFile DIR: $dir URLPATH: $urlPath</p>  -->
__EOF

        $dir = $::wkdir if(defined($::wkdir));

        print <<__EOF;
        <p><button type='button' id='submit' onclick='SubmitPredict(\"$dir\", \"$jsonFile\", \"$urlPath\");'>Predict Pathogenicity</button> [EXPERIMENTAL]</p>
            <div class='resultsFrame'>
            <div id='throbber' style='display: none;'><p><img src='$config::predictURL/throbber.gif' alt='WAIT'/>Please wait (this will take up to 5 minutes!)...</p></div>
            <div id='results'></div>
            </div>
__EOF
    }
}
