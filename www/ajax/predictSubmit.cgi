#!/usr/bin/perl
use FindBin;
use lib $FindBin::Bin;
use strict;
use CGI;
use config;

my $slowProgram = "predictSlowprog.pl";

$|=1;

my $pwd=`pwd`;
chomp $pwd;
$pwd =~ s/ /\\ /g;              # Escape any white space in the path

my $cgi = new CGI;

my $dir  = $cgi->param('dir');
my $json = $cgi->param('json');
my $jsonpath = "$dir/$json";

my $processID = "$$" . time();
my $outDir = "$config::webTmpDir/$processID";

print $cgi->header();

`mkdir -p $outDir`;
if(WriteIndexFile($outDir, $processID))
{
    print $processID;

    # *** NOW RUN THE SLOW PROGRAM 
    my $exec = "nohup $pwd/$slowProgram $processID $dir $jsonpath >$outDir/log2 2>&1 &";
#    my $exec = "nohup ssh acrm3 \"$pwd/$slowProgram $processID $dir $jsonpath &>$outDir/log2\" &";
    print STDERR "*** $exec ***\n";
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
        # *** REPLACE THE HTML AS YOU SEE FIT - THIS PAGE WILL BE REPLACED ***
        print FILE <<__EOF;
<html>
<head>
<title>SAAPdap</title>
</head>
<body>
<h1>SAAPdap analysis</h1>
<p>You should not normally be seeing this page...</p>

<p>If you have been directed to this page from the SAAPdap server,
something has gone wrong! Please examine the <a href='./log'>log</a>
file and correct any errors. Failing that, check the <a
href='./log2'>log2</a> file and report details including the process
ID: $processID</p>

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
