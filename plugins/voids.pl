#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    SAAP
#   File:       voids.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Voids plugin for the SAAP server
#   
#   Copyright:  (c) UCL / Prof. Andrew C. R. Martin 2011-2020
#   Author:     Prof. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   EMail:      andrew@bioinf.org.uk
#   Web:        http://www.bioinf.org.uk/
#               
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
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  02.11.11 Original
#   V1.1  21.12.11 Fixed bug in caching of native voids. Now uses full
#                  filename path instead of trying to extract PDB code
#   V1.3  07.03.12 Number of voids now a variable and pads to this number
#                  if AVP returns fewer voids
#   V3.2  20.08.20 Added -force and fixed for blank chain label
#
#*************************************************************************
use strict;
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/");
use config;
use SAAP;

# Information string about this plugin
$::infoString = "Analyzing voids - this will take some time! (Ignore any sort/broken pipe errors!!!)";

# Programs we use
my $getchain = $config::binDir . "/pdbgetchain";
my $hstrip   = $config::binDir . "/pdbhstrip";
my $addhet   = $config::binDir . "/pdbaddhet";
my $avp      = $config::binDir . "/avp";
my $mutmodel = $config::binDir . "/mutmodel";

# Number of voids to look for and list
$::nvoids = 10;

# Temp files
my $tfile1  = "$config::tmpDir/voids_1_$$" . time . ".pdb";
my $tfile2  = "$config::tmpDir/voids_2_$$" . time . ".pdb";
my $tfile3  = "$config::tmpDir/voids_3_$$" . time . ".pdb";
my $avpout1 = "$config::tmpDir/voids_1_$$" . time . ".avp";
my $avpout2 = "$config::tmpDir/voids_2_$$" . time . ".avp";

# Parse command line and check for presence of PDB file
my($resid, $newaa, $pdbfile) = SAAP::ParseCmdLine("Voids");

# See if the results are cached
my $json = SAAP::CheckCache("Voids", $pdbfile, $resid, $newaa);
$json = "" if(defined($::force)); 

if($json ne "")
{
    print "$json\n";
    exit 0;
}

# Split the residue ID into its component parts
my($chain, $resnum, $insert) = SAAP::ParseResSpec($resid);

# Check the specified residue is in the resultant PDB file
# 02.11.11 Not really needed as the pipeline program now does it
if(!SAAP::CheckRes($pdbfile, $resid))
{
    ErrorDie("PDB file ($pdbfile) does not contain residue ($resid)");
}

# Get the chain of interest and strip hydrogens
if($chain eq '')
{
    `$getchain -n 1 $pdbfile | $hstrip > $tfile1`;
}
else
{
    `$getchain $chain $pdbfile | $hstrip > $tfile1`;
}

# Add back the het atoms
`$addhet $pdbfile $tfile1 $tfile2`;

# Check the specified residue is in the resultant PDB file
if(!SAAP::CheckRes($tfile2, $resid))
{
    ErrorDie("PDB file ($pdbfile) does not contain residue ($resid)");
}

# Run AVP
my($lvoid, $voids) = CheckNativeAVPCache($pdbfile, $chain);
if($lvoid < 0)
{
   `$avp -q -R -p 0.5 $tfile2 > $avpout1`;
    ($lvoid, $voids) = GetAVPData($avpout1);
   WriteNativeAVPCache($pdbfile, $chain, $lvoid, $voids);
}

# Do the AA replacement
`$config::binDir/mutmodel -m $resid $newaa -e 1 -s 5 $tfile2 $tfile3`;

# Run AVP
`$avp -q -R -p 0.5 $tfile3 > $avpout2`;
my($lvoid_mut, $voids_mut) = GetAVPData($avpout2);

# Check for a damaging void
my $badvoid = "OK";
if(($lvoid_mut >= 275) && ($lvoid < 275))
{
    $badvoid = "BAD";
}
    

# Print results
$json = SAAP::MakeJson("Voids", ('BOOL'=>$badvoid, 'NATIVE-LARGEST'=>$lvoid, 'NATIVE'=>$voids, 'MUTANT-LARGEST'=>$lvoid_mut, 'MUTANT'=>$voids_mut));
print "$json\n";
SAAP::WriteCache("Voids", $pdbfile, $resid, $newaa, $json);

# Cleanup temp files
unlink($tfile1);
unlink($tfile2);
unlink($tfile3);
unlink($avpout1);
unlink($avpout2);

exit 0;


#*************************************************************************
# 07.03.11 Modified to pad to $::nvoids voids if there are <$::nvoids in 
#          the AVP results
sub GetAVPData
{
    my($file) = @_;

    my $voidstring = `grep Void: $file | sort -r -n -k 6 | head -$::nvoids | awk '{print \$6}'`;
    $voidstring =~ s/\r//g;
    chomp $voidstring;
    my @voids = split(/\n/, $voidstring);
    my $nvoids = scalar(@voids);
    while($nvoids < $::nvoids)
    {
        push @voids, 0;
        $nvoids++
    }
    $voidstring = join('|', @voids);

    my $lvoid = `grep "Largest void volume" $file | awk '{print \$4}'`;
    chomp $lvoid;

    return($lvoid, $voidstring);
}


#*************************************************************************
sub ErrorDie
{
    my($msg) = @_;

    SAAP::PrintJsonError("Voids", $msg);
    exit 1;
}

#*************************************************************************
sub UsageDie
{
    print STDERR <<__EOF;

voids.pl V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin

Usage: voids.pl [-force] [chain]resnum[insert] newaa pdbfile
       -force   Force calculation even if results are cached
       (newaa maybe 3-letter or 1-letter code)

    
Does void calculations for the SAAP server.
       
__EOF
   exit 0;
}


#*************************************************************************
# my($lvoid, $voids) = CheckNativeAVPCache($pdbfile);
sub CheckNativeAVPCache
{
    my($pdbfile, $chain) = @_;
    my ($lvoid, $voids) = (-1, -1);

    $pdbfile =~ s/\//\_/g;

    my $file = "$config::avpCacheDir/${pdbfile}_${chain}.voids";
    if(-e $file)
    {
        if(open(CACHE, $file))
        {
            $lvoid = <CACHE>;
            chomp $lvoid;
            $voids = <CACHE>;
            chomp $voids;
            
            close CACHE;
        }
    }

    return($lvoid, $voids);
}

#*************************************************************************
sub WriteNativeAVPCache
{
    my($pdbfile, $chain, $lvoid, $voids) = @_;
    if(! -d $config::avpCacheDir)
    {
        `mkdir -p $config::avpCacheDir`;
        `chmod a+wxt $config::avpCacheDir`;
    }
    if(-d $config::avpCacheDir)
    {

        $pdbfile =~ s/\//\_/g;

        my $file = "$config::avpCacheDir/${pdbfile}_${chain}.voids";
        if(open(CACHE, ">$file"))
        {
            print CACHE "$lvoid\n";
            print CACHE "$voids\n";
            close CACHE;
        }
    }
}
