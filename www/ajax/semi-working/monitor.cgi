#!/acrm/usr/local/bin/perl
use strict;
use CGI;
use config;
$|=1;

my $cgi = new CGI;
my $processID = $cgi->param('processid');
my $logfile = "$config::webTmpDir/$processID/log";
my $prevContent;

if(! -e $logfile)
{
    sleep 5;                        # Give NFS time to realize directory is there
}

if(! -e $logfile)
{
    $prevContent = "ERROR: Process $processID doesn't exist\n__EOF__\n";
}
else
{
    $prevContent = `cat $logfile`;
    my $changed = 0;

    while(1)
    {
        my $content = `cat $logfile`;
        
        # Exit if we have the end-of-file marker at the end of the content
        if($content =~ /\n__EOF__\n$/)
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

