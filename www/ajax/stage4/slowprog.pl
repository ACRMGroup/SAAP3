#!/acrm/usr/local/bin/perl
use config;
my($processID, $sprotID, $native, $resnum, $mutant) = @ARGV;
$|=1;

$ENV{'PERL5LIB'} = "$ENV{'PERL5LIB'}:$config::saapRoot:$config::saapModules";
my $wkdir = "$config::tmpdir/$processID";

if(open(FILE, ">$wkdir/mutant.lis"))
{
    print FILE "$sprotID $native $resnum $mutant\n";
    close FILE;

    WriteMessage($wkdir, "Starting analysis...");
    system("cd $wkdir; $config::saapPipeline -v -f data mutant.lis >>$wkdir/log 2>&1");
    WriteMessage($wkdir, "Building HTML...");
    system("cd $wkdir; $config::saapJSON2HTML data >$wkdir/index.html");
    WriteMessage($wkdir, "__EOF__");
}
else
{
    WriteMessage($wkdir, "Unable to create mutant list");
    WriteMessage($wkdir, "__EOF__");
}


sub WriteMessage
{
    my($wkdir, $msg) = @_;
    system("echo \"$msg\" >>$wkdir/log");
}
