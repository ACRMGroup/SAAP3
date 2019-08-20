#!/usr/bin/perl
use strict;
use CGI;
use FindBin;
use lib $FindBin::Bin;
use config;
$|=1;

my $pwd=`pwd`;
chomp $pwd;
$pwd =~ s/ /\\ /g;              # Escape any white space in the path

my $cgi = new CGI;

my $uppdb  = $cgi->param('uppdb');
my $ac     = $cgi->param('ac');
my $native = $cgi->param('native');
my $resnum = $cgi->param('resnum');
my $mutant = $cgi->param('mutant');

my $processID = "$$" . time();
my $outDir = "$config::webTmpDir/$processID";

print $cgi->header();

`mkdir $outDir`;
if(WriteIndexFile($outDir, $processID))
{
    print $processID;

    my $exec = "nohup $pwd/slowprog.pl $processID $uppdb $ac $native $resnum $mutant >$outDir/log2 2>&1 &";
    system($exec);
}
else
{
    print "<p>Submission failed. Unable to create working directory.</p>\n";
}

############################################################################
sub WriteIndexFile
{
    my($outDir, $processID) = @_;
    if(open(FILE, ">$outDir/index.html"))
    {
        print FILE <<__EOF;
<html>
<head>
<title>SAAPdap</title>
</head>
<body>
<h1>SAAPdap analysis</h1>
<p>You should not normally be seeing this page...</p>

<p>If you have been directed to this page from the SAAPdap server,
something has gone wrong! Please examine the <a href='./log'>log file</a> 
and correct any errors. Failing that, please report details including 
the process ID: $processID</p>

<p>If you have decided not to wait for the online server to complete,
but recorded this URL for later viewing, then keep refreshing this page
until you obtain results. You can check progress in the 
<a href='./log'>log file</a>. If you have not obtained results after
an hour then something has probably gone wrong. If you cannot correct
your submission based on information in the log file, please report
details including the process ID: $processID</p>

</body>
</html>
__EOF
        close FILE;
    }
    else
    {
        return(0);
    }
    return(1);
}
