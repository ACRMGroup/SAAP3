#!/usr/bin/perl
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

# Programs we use
my $getchain = $config::binDir . "/getchain";
my $hstrip   = $config::binDir . "/hstrip";
my $addhet   = $config::binDir . "/addhetv2";
my $avp      = $config::binDir . "/avp";
my $mutmodel = $config::binDir . "/mutmodel";

# Temp files
my $tfile1  = "$config::tmpDir/voids_1_$$.pdb";
my $tfile2  = "$config::tmpDir/voids_2_$$.pdb";
my $tfile3  = "$config::tmpDir/voids_3_$$.pdb";
my $avpout1 = "$config::tmpDir/voids_1_$$.avp";
my $avpout2 = "$config::tmpDir/voids_2_$$.avp";

# Parse command line and check for presence of PDB file
my($resid, $newaa, $pdbfile) = config::ParseCmdLine("Voids");

# See if the results are cached
my $json = config::CheckCache("Voids", $pdbfile, $resid, $newaa);
if($json ne "")
{
    print "$json\n";
    exit 0;
}

# Split the residue ID into its component parts
my($chain, $resnum, $insert) = config::ParseResSpec($resid);

# Check the specified residue is in the resultant PDB file
if(!config::CheckRes($pdbfile, $resid))
{
    ErrorDie("PDB file ($pdbfile) does not contain residue ($resid)");
}

# Get the chain of interest and strip hydrogens 
`$getchain $chain $pdbfile | $hstrip > $tfile1`;

# Add back the het atoms
`$addhet $pdbfile $tfile1 $tfile2`;

# Check the specified residue is in the resultant PDB file
if(!config::CheckRes($tfile2, $resid))
{
    ErrorDie("PDB file ($pdbfile) does not contain residue ($resid)");
}

# Run AVP
`$avp -q -R -p 0.5 $tfile2 > $avpout1`;
my($lvoid, $voids) = GetAVPData($avpout1);

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
$json = config::MakeJson("Voids", ('BOOL'=>$badvoid, 'NATIVE-LARGEST'=>$lvoid, 'NATIVE'=>$voids, 'MUTANT-LARGEST'=>$lvoid_mut, 'MUTANT'=>$voids_mut));
print "$json\n";
config::WriteCache("Voids", $pdbfile, $resid, $newaa, $json);

# Cleanup temp files
unlink($tfile1);
unlink($tfile2);
unlink($tfile3);
unlink($avpout1);
unlink($avpout2);

exit 0;


#*************************************************************************
sub GetAVPData
{
    my($file) = @_;

    my $voids = `grep Void: $file | sort -r -n -k 6 | head -10 | awk '{print \$6}'`;
    $voids =~ s/\r//g;
    chomp $voids;
    $voids =~ s/\n/\|/g;

    my $lvoid = `grep "Largest void volume" $file | awk '{print \$4}'`;
    chomp $lvoid;

    return($lvoid, $voids);
}


#*************************************************************************
sub ErrorDie
{
    my($msg) = @_;

    config::PrintJsonError("Voids", $msg);
    exit 1;
}

#*************************************************************************
sub UsageDie
{
    print STDERR <<__EOF;

voids.pl V1.0 (c) 2011, UCL, Dr. Andrew C.R. Martin
Usage: voids.pl [chain]resnum[insert] newaa pdbfile
       (newaa maybe 3-letter or 1-letter code)

Does void calculations for the SAAP server.
       
__EOF
   exit 0;
}

