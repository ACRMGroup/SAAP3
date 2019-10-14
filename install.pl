#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    saap
#   File:       install.pl
#   
#   Version:    V1.0
#   Date:       06.09.17
#   Function:   Installation script for the SAAP program
#   
#   Copyright:  (c) Prof. Andrew C. R. Martin, UCL, 2017
#   Author:     Prof. Andrew C. R. Martin
#   Address:    Institute of Structural and Molecular Biology
#               Division of Biosciences
#               University College
#               Gower Street
#               London
#               WC1E 6BT
#   EMail:      andrew@bioinf.org.uk
#               
#*************************************************************************
#
#   This program is not in the public domain, but it may be copied
#   according to the conditions laid out in the accompanying file
#   COPYING.DOC
#
#   The code may be modified as required, but any modifications must be
#   documented so that the person responsible can be identified. If 
#   someone else breaks this code, I don't want to be blamed for code 
#   that does not work! 
#
#   The code may not be sold commercially or included as part of a 
#   commercial product except as described in the file COPYING.DOC.
#
#*************************************************************************
#
#   Description:
#   ============
#
#*************************************************************************
#
#   Usage:
#   ======
#   ./install.pl
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   06.09.17  Original
#
#*************************************************************************
use strict;
if(! -e 'config.pm')
{
    print <<__EOF;

Installation aborting. You need to create a config.pm config file.

__EOF
    exit 1;
}

use Cwd qw(abs_path);

# Add the path of the executable to the library path
use FindBin;
use lib $FindBin::Bin;
use lib abs_path("$FindBin::Bin/lib");
use util;
use config;
use SPECSIM;

UsageDie() if(defined($::h));

if($ARGV[0] eq "interface") # install the web interface
{
    shift(@ARGV);
    InstallInterface();
}
elsif($ARGV[0] eq "pred") # only install the prediction code
{
    shift(@ARGV);
    InstallPredCode();
}
else
{
    InstallDAPCode();
    InstallPredCode();
}

sub InstallInterface
{
    # Check that the destination is correct
    if(!DestinationOK("SAAP", $config::saapWeb))
    {
        print <<__EOF;
        
Installation aborting. Modify config.pm if you wish to install elsewhere.

__EOF
        exit 1;
    }

    # Fix the web temp URL so it starts and ends with a single /
    $config::webTmpURL = '/' . $config::webTmpURL . '/';  # Add slashes to start and end
    $config::webTmpURL =~ s/\/\//\//g;                    # Replace double slash with single
    
    CopyDir("www", "$config::saapHome/www");
    
    BuildHTML();
    
    my $webDir  = "$config::saapWeb";
    MakeDir($config::webTmpDir);
    util::RunCommand("sudo chmod a+w $config::webTmpDir");
    util::RunCommand("sudo chmod +t  $config::webTmpDir");
    CopyFile("www/webdata/getElementsByClassName.js", "$webDir/js");
    CopyFile("www/packages/overlib.js", "$webDir/js/overlib");
    CopyDir("www/packages/fontawesome", "$webDir/css/font-awesome");
    CopyDir("www/ajax", $webDir);
    CopyDir("www/webdata", "$webDir/webdata");
    util::RunCommand("rm -f $webDir/config.pm");
    CopyFile("config.pm", $webDir);

    MakeDir($config::cacheDir);
    print "*** Ignore Error Messages! ***\n";
    util::RunCommand("sudo chmod a+w $config::cacheDir");
    util::RunCommand("sudo chmod a+w $config::cacheDir/*");
    util::RunCommand("sudo chmod +t  $config::cacheDir/*");
}

sub BuildHTML
{
    if(! -f "$config::webRoot/bo.css")
    {
        CopyFile("www/includes/bo.css", $config::webRoot);
    }

    $ENV{'WWW'}    = $config::webIncludes;
    $ENV{'SERVER'} = $config::webServer;
    $ENV{'TMPURL'} = $config::webTmpURL;
    `(cd www/ajax; make)`
}

sub InstallDAPCode
{
    # Check that the destination is correct
    if(!DestinationOK("SAAP", $config::saapHome))
    {
        print <<__EOF;
        
Installation aborting. Modify config.pm if you wish to install elsewhere.

__EOF
        exit 1;
    }

    if(!CheckPreInstall())
    {
        print <<__EOF;

Installation aborting. You must run the preinstall.sh script first.
    
__EOF
        exit 1;
    }

    # Create the installation directories and build the C programs
    MakeDir($config::binDir);
    MakeDir($config::dataDir);
    BuildPackages();

    MakeDir($config::saapBinDir);
    InstallDAPPrograms($config::saapHome, $config::saapBinDir);
    InstallData($config::dataDir);

    MakeDir($config::cacheDir);
    util::RunCommand("sudo chmod a+w $config::cacheDir");
    util::RunCommand("sudo chmod a+w $config::cacheDir/*");
    util::RunCommand("sudo chmod +t  $config::cacheDir/*");

    # Do a specsim accecss in order to create/update the DBM hash file
    print "*** Info: Updating SpecSim DBM file if needed\n";
    SPECSIM::GetSpecsim($config::specsimDumpFile, $config::specsimHashFile, "MEAN", "MEAN");

}

sub InstallPredCode
{
    MakeDir($config::dataDir);  # Should be there already!

    # Unpack the Random Forest models if they aren't there
    if(! -d "$config::dataDir/models" )
    {
        print "*** Info: Unpacking RF Models\n";
        util::RunCommand("(here=`pwd`; cd $config::dataDir; tar jxvf \$here/pred/models.tjz)");
    }
    else
    {
        print "*** Info: Skipped installation of RF Models - already installed\n";
    }

    MakeDir($config::saapBinDir);
    InstallPredPrograms($config::saapPredHome, $config::saapBinDir);
}

sub Uncompress
{
    my ($exe, $inFile, $outFile, $packageName) = @_;

    my $dataFileName = $outFile;
    $dataFileName =~ s/.*\///;

    if((! -f $outFile) || (-z $outFile))
    {
        print "*** Info: Unpacking $dataFileName ... ";
        my $ret = system("bzcat $inFile >$outFile");
        if($?)
        {
            print "\n*** ERROR: Data installation failed\n";
            if ($? == -1) 
            {
                print "***        Failed to execute: $!\n";
            }
            elsif ($? & 127) 
            {
                printf "***       Child died with signal %d, %s coredump\n",
                   ($? & 127),  ($? & 128) ? 'with' : 'without';
            }
            elsif(($? >> 8) == 127)
            {
                print "***        You need to install the $exe program:\n";
                print "***        yum install $packageName\n" if ($packageName ne '');
            }
            else 
            {
                printf "child exited with value %d\n", $? >> 8;
            }
            print "\n";
        }
        else
        {
            print "done ***\n";
        }
    }
    else
    {
        print "*** Info: Skipped installation of $dataFileName data - already installed\n";
    }

}
#*************************************************************************
sub InstallData
{
    my($dataDir) = @_;

    Uncompress("bzcat", "data/specsim.dump.bz2", "$dataDir/specsim.dump", "bzip");
    CopyFile("data/pet91.mat", $dataDir);
}

#*************************************************************************
sub InstallDAPPrograms
{
    my($saapHome, $binDir) = @_;
    CopyDir("./src", "$saapHome/src");
    CopyDir("./lib", "$saapHome/lib");
    CopyDir("./plugins", "$saapHome/plugins");
    CopyFile("config.pm", $saapHome);
    LinkFiles("$saapHome/src", $binDir);
}

#*************************************************************************
sub InstallPredPrograms
{
    my($saapPredHome, $binDir) = @_;

    CopyDir("./pred/src", "$saapPredHome/src");
    LinkFiles("$saapPredHome/src", $binDir);
    unlink("$binDir/$config::wekaZip");

    if(! -d "$saapPredHome/src/weka-$config::wekaVersion")
    {
        CopyFile("./pred/packages/$config::wekaZip", "$saapPredHome/src");
        util::RunCommand("(cd $saapPredHome/src; unzip $config::wekaZip)");
        unlink("$saapPredHome/src/$config::wekaZip");
    }
    else
    {
        print "*** Info: Skipped unpacking Weka - already done\n";
    }
}

#*************************************************************************
sub LinkFiles
{
    my($inDir, $outDir) = @_;

    my @files = split("\n", `ls $inDir`);

    foreach my $file (@files)
    {
        my $fullFile = "$inDir/$file";

        if( -f $fullFile )
        {
            if( $fullFile =~ /\.pl$/ )
            {
                my $newFile = $file;
                $newFile =~ s/\..*?$//;
                `(cd $outDir; ln -sf $fullFile ./$newFile)`;
            }
            else
            {
                `(cd $outDir; ln -sf $fullFile .)`;
            }
        }
    }
}

sub CopyFile
{
    my($in, $out) = @_;
    MakeDir($out) if(! -d $out);
    my $inFull = abs_path($in);
    my $fileName = $inFull;
    $fileName =~ s/.*\///;
    my $outFull = abs_path($out);
    $outFull .= "/$fileName";

    if($inFull eq $outFull)
    {
        print STDERR "*** Info: Destination and source files are the same so not copying\n";
    }
    elsif(-f $outFull)
    {
        print STDERR "*** Info: Destination file already exists so not copying\n";
    }
    else
    {
        util::RunCommand("cp $in $out");
    }
}


sub MakeDir
{
    my($destination) = @_;

    # Test we can write to the directory
    # Try to create it if is doesn't exist
    if(! -d $destination)
    {
        system("mkdir -p $destination 2>/dev/null");
    }
    # Fail if it doesn't exist
    if(! -d $destination)
    {
        print STDERR "\n*** Error: Cannot create directory $destination\n";
        exit 1;
    }
    # Fail if we can't write to it
    my $tFile = "$destination/testWrite.$$";
    system("touch $tFile 2>/dev/null");
    if(! -e $tFile)
    {
        print STDERR "\n*** Error: Cannot write to directory $destination\n";
        exit 1;
    }
    unlink $tFile;
}

sub CopyDir
{
    my($in, $out) = @_;
    MakeDir($out);
    $in = abs_path($in);
    $out = abs_path($out);

    if($in ne $out)
    {
        util::RunCommand("cp -Rp $in/* $out");
    }
    else
    {
        print STDERR "*** Info: Destination and source dirctories are the same so not copying\n";
    }
}

#*************************************************************************
#> BOOL DestinationOK($progName, $destination)
#  -------------------------------------------
# Checks with the user if the installation destination is OK.
#
# 28.09.15 Original   By: ACRM
#
sub DestinationOK
{
    my($progName, $destination) = @_;
    $|=1;
    print "$progName will be installed in $destination\n";
    print "Do you wish to proceed? (Y/N) [Y] ";
    my $response = <>;
    chomp $response;
    $response = "\U$response";
    return(0) if(substr($response,0,1) eq "N");

    MakeDir($destination);

    return(1);
}


#*************************************************************************
#> void BuildPackages()
#  --------------------
#  Build all C program packages
#
#  06.09.17  Original  By: ACRM
#  04.10.18  Added muscle
#  03.06.19  Moved to getresol V0.2
sub BuildPackages
{
    util::BuildPackage("./packages/mutmodel_V1.22.tgz",   # Package file
                       "src",                             # Subdir containing src
                       \["mutmodel","clashcalc"],         # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "data",                            # Data directory
                       $config::dataDir);                 # Destination data directory
    
    util::BuildPackage("./packages/pdbhstrip_V1.4.tgz",   # Package file
                       "",                                # Subdir containing src
                       \["pdbhstrip"],                    # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory

    util::BuildPackage("./packages/pdbgetchain_V2.1.tgz", # Package file
                       "",                                # Subdir containing src
                       \["pdbgetchain"],                  # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory

    util::BuildPackage("./packages/getresol_V0.2.tgz",    # Package file
                       "",                                # Subdir containing src
                       \["getresol"],                     # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory

    util::BuildPackage("./packages/pdbaddhet_V2.4.tgz",   # Package file
                       "",                                # Subdir containing src
                       \["pdbaddhet"],                    # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory

    util::BuildPackage("./packages/avp_V1.4.tgz",         # Package file
                       "src",                             # Subdir containing src
                       \["avp"],                          # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory

    util::BuildPackage("./packages/getresidue_V1.0.tgz",  # Package file
                       "",                                # Subdir containing src
                       \["getresidue"],                   # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory

    util::BuildPackage("./packages/pdbtorsions_V2.1.tgz", # Package file
                       "",                                # Subdir containing src
                       \["pdbtorsions"],                  # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory

    util::BuildPackage("./packages/pdbcheckforres_V1.5.tgz", # Package file
                       "",                                # Subdir containing src
                       \["pdbcheckforres"],               # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory

    util::BuildPackage("./packages/pdbhbond_V2.1.tgz",    # Package file
                       "",                                # Subdir containing src
                       \["pdbhbond"],                     # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "data",                            # Data directory
                       $config::dataDir);                 # Destination data directory

    util::BuildPackage("./packages/pdbsolv_V1.5.tgz",     # Package file
                       "",                                # Subdir containing src
                       \["pdbsolv"],                      # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "data",                            # Data directory
                       $config::dataDir);                 # Destination data directory

    util::BuildPackage("./packages/checkhbond_V2.1.tgz",  # Package file
                       "src",                             # Subdir containing src
                       \["checkhbond",
                         "checkhbond_Ndonor",
                         "checkhbond_Oacceptor"],         # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "data",                            # Data directory
                       $config::dataDir);                 # Destination data directory

    util::BuildPackage("./packages/pdblistss_V1.0.tgz",   # Package file
                       "",                                # Subdir containing src
                       \["pdblistss"],                    # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory

    util::BuildPackage("./packages/muscle_V3.8.1551.tgz", # Package file
                       "",                                # Subdir containing src
                       \["muscle"],                       # Generated executable
                       $config::binDir,                   # Destination binary directory
                       "",                                # Data directory
                       "");                               # Destination data directory
}





#*********************************************************************
sub CheckPreInstall
{
    # Check glibc-static
    if(!( -f '/usr/lib64/libm.a' ) && !( -f '/usr/lib/libm.a'))
    {
        print STDERR "***Error: glibc-static not installed\n";
        return(0);
    }
    # Check R
    if(!( -f '/usr/bin/R'))
    {
        print STDERR "***Error: R not installed\n";
        return(0);
    }
    # Check Java
    if(!( -f '/usr/bin/java'))
    {
        print STDERR "***Error: Java not installed\n";
        return(0);
    }
    # Check Unzip
    if(!( -f '/usr/bin/unzip'))
    {
        print STDERR "***Error: Unzip not installed\n";
        return(0);
    }
#    # Check wkhtmltopdf
#    if(!( -f '/usr/bin/wkhtmltopdf'))
#    {
#        print STDERR "***Error: wkhtmltopdf not installed\n";
#        return(0);
#    }
    # Check perl-LWP-Protocol-https
    my $https = `find /usr/lib/   -name SSLeay.so -print`;
    $https   .= `find /usr/lib64/ -name SSLeay.so -print`;
    $https =~ s/\s//g;
    if(!length($https))
    {
        print STDERR "***Error: perl LWP not installed\n";
        return(0);
    }

    # Check perl-JSON
    $https  = `find /usr/share/perl5 -name JSON.pm -print`;
    $https .= `find /usr/lib64/      -name JSON    -print`;
    $https  =~ s/\s//g;
    if(!length($https))
    {
        print STDERR "***Error: perl JSON not installed\n";
        return(0);
    }

    return(1);
}


#*************************************************************************
#> void UsageDie()
#  ---------------
#  Prints a usage message and exits
#
#  19.09.13  Original  By: ACRM
sub UsageDie
{
    print <<__EOF;

SAAP V1.0 install (c) 2017-2019, Prof. Andrew C.R. Martin, UCL

Usage: ./install.pl [interface]

install is the SAAP installer.

      !!!  YOU MUST EDIT config.pm BEFORE USING THIS SCRIPT  !!!

Run as 
   ./install.pl
first to compiled and install the code. Then run
   ./install.pl interface
to install the web interface

__EOF

   exit 0;
}


