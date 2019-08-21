#!/acrm/usr/local/bin/perl
use strict;
use CGI;
use config;
$|=1;

my $cgi = new CGI;
my $processID = $cgi->param('processid');
my $logfile = "$config::tmpdir/$processID/log";
my $prevContent;

if(! -e $logfile)
{
    $prevContent = "ERROR: Process $processID doesn't exist\nEND\n";
}
else
{
    $prevContent = `cat $logfile`;
    my $changed = 0;

    while(1)
    {
        my $content = `cat $logfile`;
        
        # Exit if we have the word 'END' in the content
        if($content =~ /END/)
        {
            $prevContent = $content;
            last;
        }

        # If the content has changed, sit in a loop waiting until it is stable
        while($content ne $prevContent)
        {
            $changed = 1;
            $prevContent = $content;
            sleep 1;
            $content = `cat $logfile`;
        }

        last if($changed);
        sleep 5;
    }
}

print $cgi->header();
print $prevContent;

