#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    saapPred
#   File:       saapPred.pl
#   
#   Version:    V1.0
#   Date:       23.10.12
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
#   Run SAAP predection using the (Humvar) models
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   23.10.12  Original
#
#*************************************************************************
use configPred;
use strict;
use SAAP;

my($sprot,$pos,$nat,$mut) = ParseCmdLine();

#-- Check for -h - help request
UsageDie() if(defined($::h));

$::v         = defined($::v)?"-v":"";
$::info      = defined($::info)?"-info":"";
$::printpdb  = defined($::printpdb)?"-printpdb":"";
$::printall  = defined($::printall)?"-printall":"";

#-- Check for user-specified pdblimit, mlimit and prePred

#   pdblimit should be be an odd number 
if(!defined($::pdblimit))
{
    $::pdblimit = "3";
} 
else 
{
    if($::pdblimit % 2 == 0) 
    {
        $::pdblimit = $::pdblimit + 1;
    }
}                          

#  Should be be an odd number betwen 1-9
if(!defined($::mlimit)) 
{
    $::mlimit = "9";
} 
else 
{
    if($::mlimit % 2 == 0) 
    {
        $::mlimit = $::mlimit + 1;
    }
}

#  prePred should be either PD or SNP
if(!defined($::prePred)) 
{
    $::prePred = "PD";
}

my $jsonFile;
if(!defined($::json))
{
    $jsonFile = $configPred::pipelineJSON."/".$sprot."_".$nat."_".$pos."_".$mut.".json"; 
    $::json = "";
} 
else 
{
    $jsonFile = $::json;
}

my $csvFile    = $configPred::csvDir."/".$sprot."_".$nat."_".$pos."_".$mut.".csv";
my $arffFile   = $configPred::arffDir."/".$sprot."_".$nat."_".$pos."_".$mut.".arff";
my $idFile     = $configPred::arffDir."/".$sprot."_".$nat."_".$pos."_".$mut."_id";
my $predFile   = $configPred::predDir."/".$sprot."_".$nat."_".$pos."_".$mut.".txt";
my $piplineOut = $configPred::tmpDir."/".$sprot."_".$nat."_".$pos."_".$mut.".out";

print STDERR "\n" if(defined($::v));
#-------------------------------------------------------------------------#
#-- Run the pipline using the uniprotPipeline.pl and save the JSON file --#
#-------------------------------------------------------------------------#
if(!($::json))  
{
    print STDERR "     ... Run the pipline" if(defined($::v));
    my $shfile = create_sh_file();
    my$runPipline = "sh $shfile > $piplineOut";
    system( $runPipline );
    print STDERR "     ... Done\n" if(defined($::v));
}

#--------------------------------------#
#-- Parses JSON file to get csv file --#
#--------------------------------------#
print STDERR "     ... Run parsJson" if(defined($::v));
if(-e $jsonFile)
{
    my $runParseJSON = "$configPred::perl $configPred::parseJSON $jsonFile $::prePred > $csvFile";
    system( $runParseJSON );
}
print STDERR "        ... Done\n" if(defined($::v));

#--------------------------------------#
#-- Run csv2arff.pl to get arff file --#
#--------------------------------------#
print STDERR "     ... Run csv2arff" if(defined($::v));
if(`grep -Ev 'PDBSWS|acrm|ERROR|Error' $csvFile` )
{
    my $runcsv2arff = "$configPred::perl $configPred::csv2arff $configPred::options -norm=$configPred::normScale -class=$configPred::class -id=$configPred::id -idfile=$idFile -inputs=$configPred::features $configPred::output $csvFile > $arffFile "; 
    system( $runcsv2arff );
}    

else
{
    my $error = `cat $csvFile` ; 
    print STDERR "ERROR   $error\n"; 
}
print STDERR "        ... Done\n" if(defined($::v));

#-- save IDs in array num:uniprotac:res:nat:mut:pdbcode:chain:resnum:mutation:structuretype:resolution:rfactor
my $count=1;
my %id;

if(open(FILE, $idFile))
{
    while(<FILE>)
    {
        chomp;
        my @values    = split(',');
        my @ID        = split('\:', $values[0]);
        $id{num}[$count]         = $ID[0];  
        $id{uniprotac}[$count]   = $ID[1]; 
        $id{res}[$count]         = $ID[2];   
        $id{nat}[$count]         = $ID[3];       
        $id{mut}[$count]         = $ID[4];         
        $id{pdbcode}[$count]     = $ID[5];     
        $id{chain}[$count]       = $ID[6];    
        $id{resnum}[$count]      = $ID[7];   
        $id{mutation}[$count]    = $ID[8];   
        $id{structype}[$count]   = $ID[9];   
        $id{reseolution}[$count] = $ID[10]; 
        $id{rfactor}[$count]     = $ID[11];      
        $count++;
    }
    close FILE;
} 
else
{
    print STDERR "Can't open $idFile file with IDs fields\n";
    exit 1;
}


#------------------------#
#-- Run the predectour --#
#------------------------#
print STDERR "     ... Run the predectour" if(defined($::v));
my %predection = runPredectour($::mlimit);
print STDERR "  ... Done\n" if(defined($::v));
   

#-----------------------#
#--  Avraging result  --#
#-----------------------#
print STDERR "     ... Avraging          " if(defined($::v));
my ($avgPred,$avgConf,%predectionPdb) = averag(%predection) ;# avraging Models prormance for each PDB structer
print STDERR "  ... Done\n" if(defined($::v));

#-----------------------#
#--  Printing result  --#
#-----------------------#
print STDERR "     ... Printing results" if(defined($::v));
my $p;
if(($::printpdb)||($::printall))
{
    printf "uniprotac\tnat\tresnum\tmut\tpdbcode\tchain\tstructype\tresolution\trfactor\tpredection\tconfidant\n";
    
    for(my $i=1; $i<$::pdblimit+1; $i++)
    { 
        if($predectionPdb{pred}[$i] > 0.5) {$p = "PD";} else {$p = "SNP";};
        printf "%6s\t%1s\t%d\t%1s\t%s\t%s\t%s\t%s\t%s\t%s\t%.2f\n",$sprot, $nat, $pos, $mut,$id{pdbcode}[$i],$id{chain}[$i],$id{structype}[$i],$id{reseolution}[$i],$id{rfactor}[$i], $p, $predectionPdb{conf}[$i]; 
        
        if($::printall)
        {
            for(my $e=1; $e<$::mlimit+1; $e++) # or $count
            { 
                if($predection{'pred'.$i}[$e] == 1) {$p = "PD";} else {$p = "SNP";};
                print "          Model $e predect $p with a confidant of $predection{'conf'.$i}[$e]\n"; 
            }
        }
    }   
}
else
{
    printf "%6s\t%1s\t%d\t%1s\t%s\t%.2f\n",$sprot, $nat, $pos, $mut, $avg_pred, $avg_conf; 
}
print STDERR "    ... Done\n" if(defined($::v));
    
#-------------------------------------------------------------------------
sub averag
{
    my (%hash) = @_;
    my %h1; 
    my %h2;
    my $avgPredall = "";
    my $avgConfall = "";

    for(my $i=1; $i<$::pdblimit+1; $i++) 
    {    
        my $pred = ""; 
        my $conf = "";
        for(my $e=1; $e<$::mlimit+1; $e++) 
        { 
            $pred += $hash{'pred'.$i}[$e];
            $conf += $hash{'conf'.$i}[$e]; 
        }
        $pred = $pred/$::mlimit;
        $conf = $conf/$::mlimit;
        
        $h1{pred}[$i] = $pred;
        $h1{conf}[$i] = $conf;      
        
        $avgPredall += $pred;
        $avgConfall += $conf;        
    }  
    $avgPredall = $avgPredall/$::pdblimit;
    $avgConfall = $avgConfall/$::pdblimit;
    
    if($avgPredall > 0.5) 
    { 
        $avgPredall = "PD";
    } 
    elsif($avgPredall == 0.5) 
    {
        if($h1{conf}[1] > $h1{conf}[2]) 
        {
            $avgPredall = $h1{pred}[1];
        } 
        else 
        { 
            $avgPredall = $h1{pred}[2];
        } 
        
        if($avgPredall > 0.5) 
        {
            $avgPredall = "PD";
        }
        else
        {
            $avgPredall = "SNP";
        }
    }    
    else 
    {
        $avgPredall = "SNP";
    }
   
    return($avgPredall,$avgConfall,%h1);
}

#-------------------------------------------------------------------------
sub runPredectour
{
my ($n) = @_;
my %p;

 for (my $i=1; $i<$n+1; $i++)
 {     
     #$predFile =$predFile."_".$i;
     my $inst = 1;
     my $theModel = sprintf ( $configPred::model,$i) ;
     my $run_predectours = "$configPred::java $configPred::memory -cp $configPred::weka $configPred::classifiers -T $arffFile -l $theModel -p 0 > $predFile";
     system( $run_predectours ); 
     
     open(PR, $predFile); 
     while(my $line = <PR>) 
     { 
         # inst#     actual  predicted error prediction
         #     1       1:PD       1:PD       0.832
         if($line =~ m/\s+\d+\s+\d+:\w+\s+\d+:(\w+).*(\d+\.\d+)/)
         {
             #--- $p{"pred".$inst}[$i] --- predection result (PD or SNP)
             #    for line no.$inst using model no. $i 
             #--- Converte PD and SNP to 1 and 0 for avraging the results
             if ($1 eq "PD") {$p{"pred".$inst}[$i] = 1;} else {$p{"pred".$inst}[$i] = 0;} 
             
             #--- $pred{"conf".$inst}[$i] --- predection confidante result 
             #    (i.e 0.832) for line no.$inst using model no. $i
             $p{"conf".$inst}[$i] = $2 ;           
             $inst++;
         }
     }
     close FH;
 }
return (%p);
}

#-------------------------------------------------------------------------
sub ParseCmdLine
{
    if(@ARGV != 4)
    {
        &::UsageDie();
    }
    my $ac      = shift(@ARGV);
    my $native  = shift(@ARGV);
    my $resnum  = shift(@ARGV);
    my $mutant  = shift(@ARGV);

    $ac = "\U$ac";
    $native = "\U$native";
    $mutant = "\U$mutant";

    if(defined($SAAP::onethr{$native}))
    {
        $native = $SAAP::onethr{$native};
    }
    
    if(defined($SAAP::onethr{$mutant}))
    {
        $mutant = $SAAP::onethr{$mutant};
    }

    return($ac, $resnum, $native, $mutant);
}
#-------------------------------------------------------------------------
sub create_sh_file
{
    my $file = $configPred::tmpDir."/".$sprot."_".$nat."_".$pos."_".$mut.".sh";
   
    open ( FILE, ">$file" ) || die "Cannot write to file '$file'\n$!\n";
    print FILE "#!/bin/sh\n#\$ -S /bin/sh\n\n";
    #-- Define command line inputs
    print FILE  "cd ".$configPred::piplineDir." \n";
    print FILE  "source ./init.sh \n";
    print FILE  $configPred::perl." ".$configPred::pipeline_uniprot." -limit=".$::pdblimit." ".$sprot." ".$nat." ".$pos." ".$mut."  > ".$jsonFile." \n"; 
    #print FILE  $configPred::perl." ".$configPred::pipeline_uniprot." -v -limit=".$::pdblimit." ".$sprot." ".$nat." ".$pos." ".$mut."  > ".$jsonFile." \n";
    print FILE "echo COMPLETE\t".$file."\n";
    close ( FILE );
    return ( $file );
}
#-------------------------------------------------------------------------

sub UsageDie
{
    print <<__EOF;

saapPred V1.0 (c) 2012, UCL, Nouf S. Al Numair
Usage: 
        saapPred uniprotAC native resnum newres
        [-v [-info]] [-json=file] [-pdblimit=n]
        [-modllimit=n] > predection.txt

       
        -json=file If a json file is specified, then
                   saapPred will skip the pipeline analysis
                   and use givin json file.
        -pdblimit  Set the maximum number of PDB chains
                   to analyze
        -modlimit  Set the number of Models unsed in 
                   pathogencity redection.
        -printpdb  Print predection results from diffrent
                   PDB structures
        -printall  Print predection results from diffrent
                   moduels from each PDB structure
         -v        Verbose
  

Runs the SaapPred that sequentially run
- Analysis pipeline on each PDB chain that matches a specified
           uniprot accession.
- json2csv parses JSON file and convert it to CSV file contains
           a first record with column names and following records
           with pipline structural analysis data.
- csv2arff extracts the columns named in config file from CSV file
           and convert it to ARFF file.


The uniprotAC us a UniProt accession (e.g. P69905)

The native and mutant residues (native, newres) may be specified
in upper, lower or mixed case and using 1-letter or 3-letter code.

The resnum is the UniProt reside number.



__EOF

    exit 0;
}

