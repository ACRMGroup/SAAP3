#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    SAAP
#   File:       sprotft.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   SwissProt features plugin for the SAAP server
#   
#   Copyright:  (c) Prof. Andrew C. R. Martin, UCL, 2011-2020
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
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0 2011       Original
#   V1.3 22.10.14   Added -uniAC
#   V3.2 20.08.20   Added -uniRes
#
#*************************************************************************

use strict;
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/");
use config;
use WEB;
use PDBSWS;
use UNIPROT;
use SAAP;

# Information string about this plugin
$::infoString = "Looking to see if this is annotated as a feature in SwissProt";

my %spfeatures = ('NULL'     => 0,
                  'ACT_SITE' => (2**0),
                  'BINDING'  => (2**1),
                  'CA_BIND'  => (2**2),
                  'DNA_BIND' => (2**3),
                  'NP_BIND'  => (2**4),
                  'METAL'    => (2**5),
                  'MOD_RES'  => (2**6),
                  'CARBOHYD' => (2**7),
                  'MOTIF'    => (2**8),
                  'LIPID'    => (2**9),
                  'DISULFID' => (2**10),
                  'CROSSLNK' => (2**11));

my $result = "OK";
my $featureText = "";

my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("SProtFT");

# See if the results are cached
my $json = SAAP::CheckCache("SProtFT", $pdbfile, $residue, $mutant);
$json = "" if(defined($::force)); 

if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);

# Obtain the accession code for this PDB file
my $resid = "$resnum$insert";
$resid =~ s/\s//g;

my $ac;
my $sprotnum;
if(defined($::uniAC))
{
    $ac = $::uniAC;
    $sprotnum = (defined($::uniRes))?$::uniRes:$resnum;
}
else
{
    $pdbfile =~ /^.*(....)\..*/;
    my $pdbcode = $1;

    my %pdbsws = PDBSWS::PDBQuery($pdbcode, $chain, $resid);
    if(defined($pdbsws{'ERROR'}))
    {
        SAAP::PrintJsonError("SProtFT", $pdbsws{'ERROR'});
        exit 1;
    }

    $ac = $pdbsws{'AC'};
    $sprotnum = $pdbsws{'UPCOUNT'};
}

# Extract the required entry from SwissProt
my $data = UNIPROT::GetSwissProt($ac);
if($data eq "")
{
    SAAP::PrintJsonError("SProtFT", "Accession $ac not found in SwissProt");
    exit 1;
}

# Process the features
my $ft = ProcessFeatures($sprotnum, $data, %spfeatures);
if($ft != 0)
{
    $result = "BAD";

    my $intFt = bin2dec($ft);
    foreach my $feature (keys %spfeatures)
    {
        if(($intFt & $spfeatures{$feature}))
        {
            if($featureText ne "")
            {
                $featureText .= ":";
            }
            $featureText .= $feature;
        }
    }
}

$json = SAAP::MakeJson("SProtFT", ('BOOL'=>$result, 'FEATURES'=>$ft, 'NAMES'=>$featureText));
print "$json\n";
SAAP::WriteCache("SProtFT", $pdbfile, $residue, $mutant, $json);


sub bin2dec 
{
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}


# Extract relevant SwissProt features and see if our residue is
# annotated by any of the features. Or the binary feature strings
# together to get a complete annotation
sub ProcessFeatures
{
    my($sprotnum, $data, %spfeatures) = @_;
    my @records = split(/\n/, $data);
    my $result = 0;

    foreach my $record (@records)
    {
        if($record =~ /^FT /)
        {
            # my $feature = substr($line, 5, 8);
            # my $from = substr($line, 14, 6);
            # my $to = substr($line, 21, 6);
            # my $info = substr($line, 34);
            # $from =~ s/\s//g;
            # $to =~ s/\s//g;
                    
            my @fields = split(/\s+/, $record);
            if(defined($spfeatures{$fields[1]}))
            {
                # For these it is 2 individual residues that are specified
                if(($fields[1] eq "DISULFID") ||
                   ($fields[1] eq "CROSSLNK"))
                {
                    if(($sprotnum == $fields[2]) ||
                       ($sprotnum == $fields[3]))
                    {
                        $result |= $spfeatures{$fields[1]};
                    }
                }
                else  # It's a range of residues for anything else
                {
                    if(($sprotnum >= $fields[2]) &&
                       ($sprotnum <= $fields[3]))
                    {
                        $result |= $spfeatures{$fields[1]};
                    }
                }
            }
        }
    }

    # Create a format string to print the binary result with the right number
    # of leading zeros
    my $format = sprintf "%%0%db", int(keys %spfeatures);
    $result = sprintf $format,$result;

    return($result);
}


sub UsageDie
{
    print STDERR <<__EOF;

sprotft.pl V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin

Usage: sprotft.pl [-force] [-uniAC=xxx] [-uniRes=xxx] 
                  [chain]resnum[insert] newaa pdbfile

       (newaa maybe 3-letter or 1-letter code)

       -force   Force calculation even if results are cached
       -uniAC   Specify UniProt AC rather than using PDBSWS
       -uniRes  Specify UniProt residue number rather than assume it
                is the same as the PDB residue number

Examines SwissProt feature (FT) records. First looks up the residue of
interest in PDBSWS then extracts the SwissProt entry and checks
whether the residue is annotated as described below. The annotation
information is returned in SProtFT-FEATURES as a binary string:

   ACT_SITE  000000000001
   BINDING   000000000010
   CA_BIND   000000000100
   DNA_BIND  000000001000
   NP_BIND   000000010000
   METAL     000000100000
   MOD_RES   000001000000
   CARBOHYD  000010000000
   MOTIF     000100000000
   LIPID     001000000000
   DISULFID  010000000000
   CROSSLNK  100000000000

If a residue is annotated by more than one feature, then the binary
strings will be ORd together.

Also returns SProtFT-NAMES which is a colon-separated list of the
feature names.

__EOF
   exit 0;
}
