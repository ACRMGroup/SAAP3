#!/usr/bin/perl
use FindBin;
use lib $FindBin::Bin;

use config;
my($processID, $id, $native, $resnum, $mutant) = @ARGV;
$|=1;

# $ENV{'PERL5LIB'} = "$ENV{'PERL5LIB'}:$config::saapHome:$config::modulesDir";

my $wkdir = "$config::webTmpDir/$processID";

WriteMessage($wkdir, "Starting analysis...");
sleep(120);
WriteMessage($wkdir, "Building HTML...");
sleep(120);
WriteMessage($wkdir, "Doing something else...");
sleep(120);
WriteMessage($wkdir, "done\n");
sleep(120);
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
