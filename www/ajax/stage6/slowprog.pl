#!/acrm/usr/local/bin/perl
use conf;
my($processID, $uppdb, $ac, $native, $resnum, $mutant) = @ARGV;
$|=1;

$ENV{'PERL5LIB'} = "$ENV{'PERL5LIB'}:$conf::saapRoot:$conf::saapModules";
my $wkdir = "$conf::tmpdir/$processID";

if($uppdb eq "pdb")
{
    WriteMessage($wkdir, "Starting analysis...");
    system("cd $wkdir; $conf::saapPipeline -v -c $resnum $mutant $ac 2>$wkdir/log >$wkdir/results.json");
    WriteMessage($wkdir, "Building HTML...");
    system("cp $conf::gifDir/down.gif $wkdir");
    system("cp $conf::gifDir/up.gif $wkdir");
    system("cp $conf::gifDir/exclamation.gif $wkdir");
    system("cp $conf::gifDir/printpdf.cgi $wkdir");
    system('echo "Options ExecCGI" > $wkdir/.htaccess');
    system("cd $wkdir; $conf::saapJSON2HTML $wkdir/results.json >$wkdir/index.html");
    WriteMessage($wkdir, "done\n");
}
else
{
    if(open(FILE, ">$wkdir/mutant.lis"))
    {
        print FILE "$ac $native $resnum $mutant\n";
        close FILE;

        WriteMessage($wkdir, "Starting analysis...");
        system("cd $wkdir; $conf::saapMultiPipeline -v -f data mutant.lis >>$wkdir/log 2>&1");
        WriteMessage($wkdir, "Building HTML...");
        system("cd $wkdir; $conf::saapMultiJSON2HTML data >$wkdir/index.html");
        WriteMessage($wkdir, "done\n");
    }
    else
    {
        WriteMessage($wkdir, "Unable to create mutant list");
    }
}
WriteMessage($wkdir, "__EOF__");


sub WriteMessage
{
    my($wkdir, $msg) = @_;
    system("echo \"$msg\" >>$wkdir/log");
}
