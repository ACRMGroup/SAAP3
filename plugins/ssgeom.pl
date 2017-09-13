#!/usr/bin/perl -s

use strict;
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/");
use config;
use SAAP;

# Information string about this plugin
$::infoString = "Looking for disruption of disulphides";

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("SSGeom");

# See if the results are cached
my $json = SAAP::CheckCache("SSGeom", $pdbfile, $residue, $mutant);
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);

my $cacheFile = GetPDBListSSCacheFile($pdbfile);

if(IsSSCys($cacheFile, $residue))
{
    $result = "BAD";
}

$json = SAAP::MakeJson("SSGeom", ('BOOL'=>$result));
print "$json\n";
SAAP::WriteCache("SSGeom", $pdbfile, $residue, $mutant, $json);

sub GetPDBListSSCacheFile
{
    my ($pdbFile) = @_;
    my $cacheFile = $pdbFile;
    $cacheFile =~ s/\//\_/g;
    $cacheFile = "$config::pdbssCacheDir/$cacheFile";

    if(! -d $config::pdbssCacheDir)
    {
        system("mkdir $config::pdbssCacheDir");
        if(! -d $config::pdbssCacheDir)
        {
            my $message = "Unable to create cache dir ($config::pdbssCacheDir)";
            SAAP::PrintJsonError("SSGeom", $message);
            print STDERR "*** Error: $message\n";
            exit 1;
        }
    }
            
    if((! -f $cacheFile) || (-z $cacheFile))
    {
        my $exe = "$config::binDir/pdblistss $pdbfile $cacheFile";
        system("$exe");
        if((! -f $cacheFile) || (-z $cacheFile))
        {
            my $message = "Unable to create cache file ($cacheFile)";
            SAAP::PrintJsonError("SSGeom", $message);
            print STDERR "*** Error: $message\n";
            exit 1;
        }
    }

    return($cacheFile);
}


sub IsSSCys
{
    my($cacheFile, $residueIn) = @_;

    my $found  = 0;
    if(open(my $fp, '<', $cacheFile))
    {
        while(<$fp>)
        {
            chomp;
            s/^\s+//;
            my @fields = split;
            if(($fields[0] eq $residueIn) || ($fields[4] eq $residueIn))
            {
                $found = 1;
                last;
            }
        }
        close($fp);
    }
    else
    {
        SAAP::PrintJsonError("SSGeom", "Unable to read cached result file");
        exit 1;
    }

    return($found);
}



sub UsageDie
{
    print STDERR <<__EOF;

ssgeom.pl V1.0 (c) 2011, UCL, Dr. Andrew C.R. Martin
Usage: ssgeom.pl [chain]resnum[insert] newaa pdbfile
       (newaa maybe 3-letter or 1-letter code)

Does disulphide calculations for the SAAP server.
Checks if a native cysteine was involved in a disulphide

__EOF
   exit 0;
}
