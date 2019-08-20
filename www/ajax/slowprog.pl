#!/usr/bin/perl
use FindBin;
use lib $FindBin::Bin;
use config;
my($processID, $uppdb, $ac, $native, $resnum, $mutant) = @ARGV;
$|=1;

$ENV{'PERL5LIB'} = "$ENV{'PERL5LIB'}:$config::saapHome:$config::modulesDir";

my $wkdir = "$config::webTmpDir/$processID";

if($uppdb eq "pdb")
{
    WriteMessage($wkdir, "Starting analysis...");
    my $exe = "cd $wkdir; $config::saapPipeline -v -info -c $resnum $mutant $ac 2>$wkdir/log >$wkdir/results.json";
    WriteMessage($wkdir, $exe);
    system($exe);

    WriteMessage($wkdir, "Building HTML...");
    system("cp $config::gifDir/down.gif $wkdir");
    system("cp $config::gifDir/up.gif $wkdir");
    system("cp $config::gifDir/exclamation.gif $wkdir");
    system("cp $config::gifDir/printpdf.cgi $wkdir");
    system('echo "Options ExecCGI" > $wkdir/.htaccess');
    my $dataDir=`pwd` . "/data";
    system("cd $wkdir; $config::saapJSON2HTML -wkdir=$wkdir -data=$dataDir $wkdir/results.json >$wkdir/index.html");
    WriteMessage($wkdir, "done\n");
}
else
{
    if(open(FILE, ">$wkdir/mutant.lis"))
    {
        print FILE "$ac $native $resnum $mutant\n";
        close FILE;

        WriteMessage($wkdir, "Starting analysis...");
        my $exe = "cd $wkdir; $config::saapMultiPipeline -v -info -f data mutant.lis >>$wkdir/log 2>&1";
        WriteMessage($wkdir, $exe);
        system($exe);
        
        $exe = "cd $wkdir; $config::saapMultiPipeline -v -info -f data mutant.lis >>$wkdir/log 2>&1";
        WriteMessage($wkdir, $exe);
        system($exe);

        WriteMessage($wkdir, "Building HTML...");
        system("cd $wkdir; $config::saapMultiJSON2HTML -wkdir=$wkdir data >$wkdir/index.html");
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
