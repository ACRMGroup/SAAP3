#!/acrm/usr/local/bin/perl
use strict;
use CGI;
$|=1;

my $pwd=`pwd`;
chomp $pwd;

my $cgi = new CGI;

my $sprotID = $cgi->param('sprotid');
my $native = $cgi->param('native');
my $resnum = $cgi->param('resnum');
my $mutant = $cgi->param('mutant');

my $processID = "$$" . time();
`mkdir /tmp/$processID`;


print $cgi->header();
print $processID;

my $exec = "nohup $pwd/slowprog.pl $processID $sprotID $native $resnum $mutant >/tmp/$processID/log 2>&1 &";
system($exec);

