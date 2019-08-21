#!/acrm/usr/local/bin/perl
use strict;
use CGI;
use config;
$|=1;

my $pwd=`pwd`;
chomp $pwd;
$pwd =~ s/ /\\ /g;              # Escape any white space in the path

my $cgi = new CGI;

my $sprotID = $cgi->param('sprotid');
my $native = $cgi->param('native');
my $resnum = $cgi->param('resnum');
my $mutant = $cgi->param('mutant');

my $processID = "$$" . time();
my $outDir = "$config::tmpdir/$processID";
`mkdir $outDir`;
`touch $outDir/index.html`;

print $cgi->header();
print $processID;

my $exec = "nohup $pwd/slowprog.pl $processID $sprotID $native $resnum $mutant >$outDir/log 2>&1 &";
system($exec);

