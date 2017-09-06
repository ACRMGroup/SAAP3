#!/acrm/usr/local/bin/perl -s
use config;

$::plugin = "Voids" if(!defined($::plugin));

my $dir = "$config::cacheDir/$::plugin";

my $done = 1;

while($done)
{
    print "Opening directory\n";
    if(opendir(DIR, $dir))
    {
        my $file;
        $done = 0;
        while(($file = readdir(DIR)) && ($done < 1000))
        {
            if($file =~ /^[a-zA-Z0-9\_]/)
            {
                my $fnm = "$dir/$file";
                $done++;
                printf "%4d $fnm\n", $done;
                unlink($fnm);
            }
        }
        close DIR;
    }
}
