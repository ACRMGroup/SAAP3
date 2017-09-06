#!/acrm/usr/local/bin/perl -s
#*************************************************************************
#
#   Program:    
#   File:       
#   
#   Version:    
#   Date:       
#   Function:   
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2011
#   Author:     Dr. Andrew C. R. Martin
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
#
#*************************************************************************
use strict;
use config;
use SAAP;

# Information string about this plugin
$::infoString = "Checking whether the new sidechain clashes with its surroundings";

# Programs we use
my $getchain = $config::binDir . "/getchain";
my $hstrip   = $config::binDir . "/hstrip";
my $addhet   = $config::binDir . "/addhetv2";
my $mutmodel = $config::binDir . "/mutmodel";

# Cutoffs
$::energyThreshold = 34.33;     # 99% of sidechains have energy less than this

# Temp files
my $tfile1  = "$config::tmpDir/clashes_1_$$" . time . ".pdb";
my $tfile2  = "$config::tmpDir/clashes_2_$$" . time . ".pdb";
my $tfile3  = "$config::tmpDir/clashes_3_$$" . time . ".pdb";

# Variables
my $clash;

# Parse command line and check for presence of PDB file
my($resid, $newaa, $pdbfile) = SAAP::ParseCmdLine("Clash");

# See if the results are cached
my $json = SAAP::CheckCache("Clash", $pdbfile, $resid, $newaa);
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
`$getchain $chain $pdbfile | $hstrip > $tfile1`;

# Add back the het atoms
`$addhet $pdbfile $tfile1 $tfile2`;

# Check the specified residue is in the resultant PDB file
if(!SAAP::CheckRes($tfile2, $resid))
{
    ErrorDie("PDB file ($pdbfile) does not contain residue ($resid)");
}

# Do the AA replacement
my $result = `$config::binDir/mutmodel -m $resid $newaa -v -e 4 -s 30 -t 5 $tfile2 $tfile3`;

my $energy = ParseMutModel($result);

if($energy > $::energyThreshold)
{
    $clash = "BAD";
}
else
{
    $clash = "OK";
}

# Print results
$json = SAAP::MakeJson("Clash", ('BOOL'=>$clash, 'ENERGY'=>$energy));
print "$json\n";
SAAP::WriteCache("Clash", $pdbfile, $resid, $newaa, $json);

# Cleanup temp files
unlink($tfile1);
unlink($tfile2);
unlink($tfile3);

exit 0;


#*************************************************************************
sub ParseMutModel
{
    my($result) = @_;
    my(@fields) = split(/\s+/,$result);
    return($fields[1]);
}

#*************************************************************************
sub ErrorDie
{
    my($msg) = @_;

    SAAP::PrintJsonError("Clash", $msg);
    exit 1;
}

#*************************************************************************
sub UsageDie
{
    print STDERR <<__EOF;

clashes.pl V1.0 (c) 2011, UCL, Dr. Andrew C.R. Martin
Usage: clashes.pl [chain]resnum[insert] newaa pdbfile
       (newaa maybe 3-letter or 1-letter code)

Does clash calculations for the SAAP server.
       
__EOF
   exit 0;
}

