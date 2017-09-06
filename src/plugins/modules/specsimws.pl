#!/acrm/usr/local/bin/perl
use strict;
use CGI;

# TODO: These need to move into config!
# Constants returned by GetSpecsim()
$::ERR_NODUMP       = (-1);
$::ERR_NOACCESSDUMP = (-2);
$::ERR_DBMOPEN      = (-3);
$::ERR_SPECIES      = (-4);
$::ERR_NOSPECSIM    = (-5);
# Configuration directories
my $homeDir           = "/home/bsm/martin";
my $saapHome          = "$homeDir/SAAP/server";
my $pluginDir         = "$saapHome/plugins";
my $pluginDataDir     = "$pluginDir/data";
$::specsimHashFile   = "$pluginDataDir/specsim.idx";
$::specsimDumpFile   = "$pluginDataDir/specsim.dump";
# END-TODO


# Make GetSpecsim() run in verbose mode when creating the hash
# Set >1 to warn when species don't exist in the similarity matrix
$::VERBOSE = 1;

my $cgi = new CGI;

my $species1 = $cgi->param('species1');
my $species2 = $cgi->param('species2');

my %specsimValues;
my $line;
my $count = 0;
my $total = 0;

if((! -e $::specsimDumpFile) && (! -e $::specsimHashFile))
{
    printHTML($::ERR_NODUMP);
}

# If DBM hash doesn't exist or is older than the dump file then create the
# dump file
if((! -e $::specsimHashFile ) ||                          # Hash doesn't exist
       (( -M $::specsimHashFile ) > ( -M $::specsimDumpFile ))) # Hash older than dump file
{
    open(FILE,$::specsimDumpFile) || printHTML($::ERR_NOACCESSDUMP);
    unlink $::specsimHashFile;
    dbmopen %specsimValues, $::specsimHashFile, 0666 || printHTML($::ERR_DBMOPEN);

    # Grab and ignore the first 2 lines
    $line = <FILE>;
    $line = <FILE>;

    while($line = <FILE>)
    {
        chomp $line;
        # Break out on the number of rows line
        last if($line =~ /\(\d+\s+rows\)/);
            
        # Extract the fields
        my @fields = split(/\s+\|\s+/, $line);
        my $s1 = $fields[1];
        my $s2 = $fields[2];
        my $avnw = $fields[4];
        $s1   =~ s/\s//g;
        $s2   =~ s/\s//g;
        $avnw =~ s/\s//g;
        
        # Create a key and store avnw in the hash indexed by the species names
        my $key = "${s1}_${s2}";
        $specsimValues{$key} = $avnw;

        # To calculate the mean
        $total += $avnw;
        $count++;

        if($::VERBOSE)
        {
            if(!($count%1000))
            {
                print STDERR "$count";
            }
            elsif(!($count%250))
            {
                print STDERR ".";
            }
        }
    }
    close(FILE);
    
    if($::VERBOSE)
    {
        print STDERR " - done\n";
    }

    # Now create the special "mean" key
    $specsimValues{"MEAN_MEAN"} = $total / $count;

    # Close the connection to the DBM file
    dbmclose %specsimValues;

    # Touch the file in case the DBM routines just create .pag and .dir versions
    `touch $::specsimHashFile`;
}

# Dump file is up to date so open it
dbmopen %specsimValues, $::specsimHashFile, 0666 || printHTML($::ERR_DBMOPEN);
        
# Build the key for the species we want and extract value
my $key = "${species1}_${species2}";
my $retval = $::ERR_SPECIES;
if(defined($specsimValues{$key}))
{
    $retval = $specsimValues{$key};
}
else                        # Try the species the other way round if needed
{
    my $key = "${species2}_${species1}";
    if(defined($specsimValues{$key}))
    {
        $retval = $specsimValues{$key};
    }
}

# Return the value if found - otherwise it will be the error code
printHTML($retval);


sub printHTML
{
    my($val) = @_;
    print $cgi->header();
    print "$val\n";
    exit 0;
}


