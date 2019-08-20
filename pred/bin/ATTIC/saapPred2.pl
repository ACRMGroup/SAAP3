#!/usr/bin/perl -sd
#*************************************************************************
#
#   Program:    saapPred
#   File:       saapPred.pl
#   
#   Version:    V1.0
#   Date:       29.10.12
#   Function:   
#   
#   Copyright:  (c) Nouf S. Al Numair, UCL, 2012
#   Author:     Nouf S. Al Numair
#   EMail:      
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
#   Run SAAPdb predection using the Humvar models
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   29.10.12  Original
#
#*************************************************************************
use config;
use strict;
use SAAP;


my($sprot, $pos, $nat, $mut) = ParseCmdLine();

#-- Check for -h - help request
UsageDie() if(defined($::h));

$::v    = defined($::v)?"-v":"";
$::info = defined($::info)?"-info":"";

#-- Check for user-specified PDBlimit and prePred
$::PDBlimit = "3" if(!defined($::PDBlimit));
$::prePred  = "PD" if(!defined($::prePred)); #PD or SNP

my $jsonFile = $config::pipelineJSON."/".$sprot."_".$nat."_".$pos."_".$mut.".json";
my $csvFile  = $config::csvDir."/".$sprot."_".$nat."_".$pos."_".$mut.".csv";
my $arffFile = $config::arffDir."/".$sprot."_".$nat."_".$pos."_".$mut.".arff";
my $idFile   = $config::arffDir."/".$sprot."_".$nat."_".$pos."_".$mut."_id";
my $predFile = $config::predDir."/".$sprot."_".$nat."_".$pos."_".$mut.".txt";

#-- Run the pipline using the uniprotPipeline.pl and save the JSON file 
print "     ... Run the pipline\n";
my $run_pipline = "$config::perl $config::runSaapPipline -PDBlimit=$::PDBlimit -sprot=$sprot -nat=$nat -pos=$pos -mut=$mut" ;
system( $run_pipline );

#-- Pars JSON file to get csv file
print "     ... Run parsJson\n";
if (-e $jsonFile)
{
my $run_parseJSON;
$run_parseJSON = "$config::perl $config::parseJSON $jsonFile $::prePred > $csvFile";
system( $run_parseJSON );
}

#-- Run csv2arff.pl to get arff file
print "     ... csv2arff\n";
if ( `grep -Ev 'PDBSWS|acrm|ERROR|Error' $csvFile` )
{
     my $run_csv2arff = "$config::perl $config::csv2arff -ni -no -norm=$config::normScale -class=PD,SNP -id=num:uniprotac:res:nat:mut:pdbcode:chain:resnum:mutation:structuretype:resolution:rfactor -idfile=$idFile -inputs=$config::features dataset $csvFile > $arffFile ";
    system( $run_csv2arff );
}    

else
{
    my $error = `cat $csvFile` ;
    print "ERROR   $error\n"; 
}

#-- save IDs in array num:uniprotac:res:nat:mut:pdbcode:chain:resnum:mutation:structuretype:resolution:rfactor
my $count=0;
my %id;my @ID;
if(open(FILE, $idFile))
{
    while(<FILE>)
    {
        chomp;
        my @values    = split(',');
        @ID        = split('\:', $values[0]);
        $id{$ID[0]}[$count]  = $ID[0];  # $num
        $id{$ID[1]}[$count]  = $ID[1];  # $uniprotac 
        $id{$ID[2]}[$count]  = $ID[2];  # $res       
        $id{$ID[3]}[$count]  = $ID[3];  # $nat       
        $id{$ID[4]}[$count]  = $ID[4];  # $mut       
        $id{$ID[5]}[$count]  = $ID[5];  # $pdbcode   
        $id{$ID[6]}[$count]  = $ID[6];  # $chain     
        $id{$ID[7]}[$count]  = $ID[7];  # $resnum    
        $id{$ID[8]}[$count]  = $ID[8];  # $mutation  
        $id{$ID[9]}[$count]  = $ID[9];  # $structype 
        $id{$ID[10]}[$count] = $ID[10]; # $resolution
        $id{$ID[11]}[$count] = $ID[11]; # $rfactor    
  
       print "$id{$ID[0]}[$count]\n"; print "$id{$ID[6]}[$count]\n";
        $count++;
    }
    close FILE;
} 
else
{
    print STDERR "Can't open $idFile file with IDs fields\n";
    exit 1;
}


#-- Run the predectour
my $pred = "nohup nice -5 $config::java -Xmx6g -cp $config::weka weka.classifiers.trees.RandomForest -T $arffFile -l $config::model_1 -p 0 &> $predFile";
system( $pred );


#  Print result

my @modl1 = `grep 1: $predFile`;
my $n =int(@modl1);

for(my $i=0; $i<$n; $i++) # or $count
{ 
print "chain     : $id{$ID[0]}[$i] $id{$ID[6]}[$i]\n";
    if(!defined($::v))
    {
        print "$sprot $nat $pos $mut Model predection $modl1[$i] \n"; 
    }
    else
    {
        print "$sprot $nat $pos $mut 
                    num       : $id{$ID[0]}[$i]  
                    uniprotac : $id{$ID[1]}[$i]
                    res       : $id{$ID[2]}[$i]
                    nat       : $id{$ID[3]}[$i]
                    mut       : $id{$ID[4]}[$i]
                    pdbcode   : $id{$ID[5]}[$i]
                    chain     : $id{$ID[6]}[$i]
                    resnum    : $id{$ID[7]}[$i]
                    mutation  : $id{$ID[8]}[$i]
                    structype : $id{$ID[9]}[$i]
                    resolution: $id{$ID[10]}[$i]
                    rfactor   : $id{$ID[11]}[$i]\n
                    predection $modl1[$i] \n"; 
        }
}

#-- Run the predectour

#*************************************************************************
sub runPredectour
{
#hard code
#my $Mod2_pred
#print "$PiplineResulte.Mod1.txt\n" ; 
}

#*************************************************************************
sub ParseCmdLine
{
    #print "@ARGV\n";
    #if(@ARGV != 4)
    #{
    #    &::UsageDie();
    #}

    my $ac      = shift(@ARGV);
    my $native  = shift(@ARGV);
    my $resnum  = shift(@ARGV);
    my $mutant  = shift(@ARGV);

    $ac = "\U$ac";

    $native = "\U$native";
    if(defined($SAAP::onethr{$native}))
    {
        $native = $SAAP::onethr{$native};
    }

    $mutant = "\U$mutant";
    if(defined($SAAP::onethr{$mutant}))
    {
        $mutant = $SAAP::onethr{$mutant};
    }

    #SAAP::Initialize();

    return($ac, $resnum, $native, $mutant);

}
#*************************************************************************
sub UsageDie
{
    print <<__EOF;

saapPred V1.0 (c) 2012, UCL, Nouf S. Al Numair
Usage: 
        saapPred uniprotAC native resnum mutant
        [-v [-info]] [-limit=n] [-prePred=PD or SNP] > predection.txt

         -prePred
        -limit   Set the maximum number of PDB chains
                 to analyze
        -v       Verbose
        -info    Used with -v to get pipeline plugins 
                 to report their info strings
             

Runs the SAAP analysis pipeline on each PDB chain that matches a
specified uniprot accession.

uniprotAC us a UniProt accession (e.g. P69905)

The native and mutant residues (native, newres) may be specified in 
upper, lower or mixed case and using 1-letter or 3-letter code.


__EOF

    exit 0;
}
#*************************************************************************

#Usage: 
#        saapPred -uniprot=uniprotAC -nat=native -pos=resnum -mut=mutres
#        [-v [-info]] [-limit=n] [-prePred=PD or SNP] > predection.txt
#        -uniprot UniprotAC
#        -nat     Native amino acid 
#        -pos     Reside number
#        -mut     Mutated amino acid 
#        -limit   Set the maximum number of PDB chains
#                 to analyze
#        -v       Verbose
#        -info    Used with -v to get pipeline plugins 
#                 to report their info strings
             

