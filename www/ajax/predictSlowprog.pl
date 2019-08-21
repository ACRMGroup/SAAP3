#!/usr/bin/perl
use FindBin;
use lib $FindBin::Bin;

use config;
my($processID, $dir, $jsonpath) = @ARGV;
$|=1;

# $ENV{'PERL5LIB'} = "$ENV{'PERL5LIB'}:$config::saapHome:$config::modulesDir";

my $wkdir = "$config::webTmpDir/$processID";

WriteMessage($wkdir, "Starting analysis...");
my($ac, $orig, $resnum, $mutant) = ParseJsonFilename($jsonpath);
WriteMessage($wkdir, "Parameters are AC: $ac, ORIG: $orig, RESNUM: $resnum, MUTANT: $mutant");

my $logfile = "$wkdir/log";

my $exe = "(cd $config::predBin; $config::predBin/saapPred -printall -v=3 -log=$logfile -json=$jsonpath $ac $orig $resnum $mutant 2>&1 >$wkdir/log2)";
`$exe`;

WriteNewIndexFile($wkdir);
# Indicate that the program has finished
WriteMessage($wkdir, $config::EOF);

sub WriteNewIndexFile
{
    my($wkdir) = @_;

    if(open(INDEX, '>', "$wkdir/index.html"))
    {
        print INDEX <<__EOF;

<html>
<head><title>New index file</title></head>
<body>
<h1>Results</h1>
<p>These are the results from the slow-running program</p>
</body>
</html>

__EOF
        close(INDEX);
    }
    else
    {
        WriteMessage($wkdir, "Error! Unable to update index file");
    }

}

sub WriteMessage
{
    my($wkdir, $msg) = @_;
    system("echo \"$msg\" >>$wkdir/log");
}

sub ParseJsonFilename
{
    my($filename) = @_; 
    my($ac, $orig, $resnum, $mutant);

    if($filename =~ /(.*)_(...)_(\d+)_(...)\.json/) # Three-letter code
    {
        $ac     = $1;
        $orig   = $2;
        $resnum = $3;
        $mutant = $4;
    }
    elsif($filename =~ /(.*)_(.)_(\d+)_(.)\.json/) # One-letter code
    {
        $ac     = $1;
        $orig   = $2;
        $resnum = $3;
        $mutant = $4;
    }
    else
    {
        $ac = $orig = $resnum = $mutant = '';
    }
    $ac =~ s/^.*\///;           # Strip path

    return($ac, $orig, $resnum, $mutant);
}

