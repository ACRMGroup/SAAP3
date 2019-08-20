#!/acrm/usr/local/bin/perl
use strict;
use CGI;
use config;
$|=1;

my $pwd=`pwd`;
chomp $pwd;
$pwd =~ s/ /\\ /g;              # Escape any white space in the path

my $cgi = new CGI;

my $dir  = $cgi->param('dir');
my $json = $cgi->param('json');
my $jsonpath = "$dir/$json";

print $cgi->header();

#my $exec = "nohup $pwd/slowprog.pl $processID $uppdb $ac $native $resnum $mutant >$outDir/log2 2>&1 &";
#my $exec = "sleep 5";
#system($exec);

my $resFile = "$dir/predict.out";
my $exe = "(cd $config::predBin; $config::predBin/saapJSONPred.pl $jsonpath 2>&1 >$resFile)";
`$exe`;
my $result = `cat $resFile`;

print <<__EOF;

<hr />
<p style='background: yellow;'>predictSubmit results: $exe</p>
<pre style='background: yellow;'>$result</pre>
<hr />

__EOF
