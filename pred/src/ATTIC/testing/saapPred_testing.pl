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
#   Run SAAP prediction using the (Humvar) models
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   23.10.12  Original
#
#*************************************************************************
use config;
use configPred;
use strict;
use SAAP;

$|=1;

my($sprot,$pos,$nat,$mut) = ParseCmdLine();
my $programName = "saapPred";

#-- Check for -h - help request
UsageDie() if(defined($::h));

$::printpdb  = defined($::printpdb)?1:0;
$::printall  = defined($::printall)?1:0;
$::printjson = defined($::printjson)?1:0;

#-- Check for pdblimit (should be be an odd number) 
if(!defined($::pdblimit))
{
    $::pdblimit = $configPred::pdblimit;
} 
else 
{
    if($::pdblimit % 2 == 0) 
    {
        $::pdblimit = $::pdblimit + 1;
    }
}                          

#-- Check for mlimit (should be be an odd number between 1-9)
if(!defined($::mlimit)) 
{
    $::mlimit = $configPred::mlimit;
} 
else 
{
    if($::mlimit % 2 == 0) 
    {
        $::mlimit = $::mlimit + 1;
    }
}

#-- Check for prePred (should be either PD or SNP)
if(!defined($::prePred)) 
{
    $::prePred = "PD";
}

#-- Define files (all the files can be re-directed to /tmp by changing the
#   directories in configPred file 
my $jsonFile;
if(!defined($::json))
{
    $jsonFile = $configPred::pipelineJSON.$sprot."_".$nat."_".$pos."_".$mut.".json"; 
    $::json = "";
} 
else 
{
    $jsonFile = $::json;
}

my $csvFile    = $configPred::csvDir.$sprot."_".$nat."_".$pos."_".$mut.".csv";
my $arffFile   = $configPred::arffDir.$sprot."_".$nat."_".$pos."_".$mut.".arff";
my $idFile     = $configPred::arffDir.$sprot."_".$nat."_".$pos."_".$mut."_id";
my $predFile   = $configPred::predDir.$sprot."_".$nat."_".$pos."_".$mut.".txt";
my $jsonOut    = $configPred::jsonOut.$sprot."_".$nat."_".$pos."_".$mut."_pred.json";

#--------------------------------------------------------------------------#
#-- Run the pipeline using the uniprotPipeline.pl and save the JSON file --#
#--------------------------------------------------------------------------#
if(!($::json))  
{
    print STDERR "     ... Run the pipeline" if($::v);
    my $runPipeline = `$configPred::perl $config::saapUniprotPipeline -limit=$::pdblimit $sprot $nat $pos $mut > $jsonFile`;
    print STDERR "          ... Done\n" if($::v);
}

#-------------------------------------------------------------------------#
#----------------- Parses JSON file to get csv file ----------------------#
#-------------------------------------------------------------------------#
print STDERR "     ... Run parsJson" if($::v);
if(-e $jsonFile)
{
    my $runParseJSON = `$configPred::perl $configPred::parseJSON $jsonFile $::prePred > $csvFile`;
}
print STDERR "             ... Done\n" if($::v);

#-------------------------------------------------------------------------#
#----------------- Run csv2arff.pl to get arff file ----------------------#
#-------------------------------------------------------------------------#
print STDERR "     ... Run csv2arff" if($::v);
if(`grep -Ev 'PDBSWS|acrm|ERROR|Error' $csvFile` )  ## Check this! ACRM
{
    my $runcsv2arff = `$configPred::perl $configPred::csv2arff $configPred::options -norm=$configPred::normScale -class=$configPred::class -id=$configPred::id -idfile=$idFile -inputs=$configPred::features $configPred::output $csvFile > $arffFile `; 
}    
else
{
    my $error = `cat $csvFile` ; 
    print STDERR "ERROR   $error\n"; 
}
print STDERR "             ... Done\n" if($::v);

#-- save Ids in a hash for printing propounds 
my %id = saveIDS($idFile);

#-------------------------------------------------------------------------#
#------------------------ Run the predictor ------------------------------#
#-------------------------------------------------------------------------#
print STDERR "     ... Run the predictor" if($::v);
my (%allPrediction) = runPredictor($::mlimit);
print STDERR "        ... Done\n" if($::v);

#-------------------------------------------------------------------------#
#------------------------  Averaging result  -----------------------------#
#-------------------------------------------------------------------------#
print STDERR "     ... Averaging          " if($::v);
my ($avgPred,$avgConf,%pdbPrediction) = average(%allPrediction);
print STDERR "       ... Done\n" if($::v); 

#-------------------------------------------------------------------------#
#------------------------  Printing result  ------------------------------#
#-------------------------------------------------------------------------#
print STDERR "     ... Printing results" if($::v);
printPred();
print STDERR "         ... Done\n" if($::v);

if($::printjson)  
{
    print STDERR "     ... Printing results in JSON" if($::v);
    PrintJson($programName, $sprot,$pos,$nat,$mut,$jsonOut);
    print STDERR " ... Done\n" if($::v);
}
exit;

#-------------------------------------------------------------------------
#-- save Ids from $idFile generated by csv2arff.pl in a hash for printing 
sub saveIDS
{
    my ($file) = @_;
    my $count=1;
    my %id;

    if(open(FILE, $file))
    {
        while(<FILE>)
        {
            chomp;
            my @values    = split(',');
            #-- The Id will be always the 1st value in @values, yet not all
            #   the Ids from other files will have the same format of: 
            #-- (num:uniprotac:res:nat:mut:pdbcode:chain:resnum:mutation
            #   :structuretype:resolution:rfactor)
            #-- change in this subroutine in case you have different 
            #   Id combination or more than one Id
            my @ID        = split('\:', $values[0]);
            $id{num}[$count]         = $ID[0];  
            $id{uniprotac}[$count]   = $ID[1]; 
            $id{res}[$count]         = $ID[2];   
            $id{nat}[$count]         = $ID[3];       
            $id{mut}[$count]         = $ID[4];         
            $id{pdbcode}[$count]     = $ID[5];     
            $id{chain}[$count]       = $ID[6];
            $id{chainresnum}[$count] = $ID[6].$ID[7];
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
    return(%id);
}
#-------------------------------------------------------------------------
sub runPredectour
{
    my ($numberOfModels) = @_;
    my %prediction;
	
    for(my $i=1; $i<$numberOfModels+1; $i++)
    {     
        my $theModel = sprintf ( $configPred::model,$i) ;
        my $runPredectours = "$configPred::java $configPred::memory -cp $configPred::weka $configPred::classifiers -T $arffFile -l $theModel -p 0 > $predFile.$i";
        system( $runPredectours ); 
        
        my $instance= 1;
        if(open(PR, "$predFile.$i"))
        { 
            while(my $line = <PR>) 
            { 
                # inst#     actual  predicted error prediction
                #     1       1:PD       1:PD       0.832
                if($line =~ m/\s+\d+\s+\d+:\w+\s+\d+:(\w+).*(\d+\.\d+)/)
                {
                    #--- prediction result (PD or SNP) will be saved as 
                    #    $p{"pred".$i}[$instance] for line no.$instance
                    #    using model no. $i , each line ($instance) 
                    #    represent a different combination of PDB/Chain
                    #    we are testing with
                    $prediction{'pred'.$instance}[$i] = $1;
                    
                    #--- prediction confidante result (i.e 0.832) will be 
                    #    saved as $pred{"conf".$i}[$instance] for line 
                    #    no.$instance using model no. $i
                    $prediction{'conf'.$instance}[$i] = $2 ;   		
                    $instance++;
                }
            }
            close PR;
        }
        else
        {    
            print STDERR "Error: Unable to open file: $predFile.$i ";
            exit 1;
        }
    }
	return(%prediction);
}
#-------------------------------------------------------------------------
# averaging Models performance for each PDB structure
sub averag
{
    my (%hash) = @_;
    my %avgPDB; 
    my $allPred    = "";  my $allConf    = 0;
    my $avgAllPred = "";  my $avgAllConf = 0;

    for(my $i=1; $i<$::pdblimit+1; $i++) 
    {    
        my $pdbPred = ""; 
        my $pdbConf = 0;
        
        for(my $e=1; $e<$::mlimit+1; $e++) 
        { 
            if ($hash{'pred'.$i}[$e] eq "PD")
            {
                $pdbConf += $hash{'conf'.$i}[$e]; 
            }
            else
            {
                $pdbConf += (1 - $hash{'conf'.$i}[$e]); 
            }
        }
        #-- $avgPdbPred and $avgPdbConf are the average of different Models
        #   results for $i PDB entry
        my $avgPdbConf = $pdbConf/$::mlimit;     
        my $avgPdbPred;  
        if($avgPdbConf < 0.5) 
        { 
            $avgPdbPred = "SNP";
            $avgPdbConf = 1-$avgPdbConf;
        }   
        else 
        {
            $avgPdbPred = "PD";
        }
        
        #-- %avgPDB is a hash to save $pdbPred and $pdbConf for each $i
        $avgPdbConf = sprintf "%.2f", $avgPdbConf;
        $avgPDB{pred}[$i] = $avgPdbPred;
        $avgPDB{conf}[$i] = $avgPdbConf;    
        
        $allConf += $avgPdbConf;  
    }  
    #-- $avgAllPred is the average of all PDB averages
    my $avgAllConf = $allConf/$::pdblimit;
    
    if($avgAllConf < 0.5) 
    { 
        $avgAllPred = "SNP";
        $avgAllConf = 1-$avgAllConf;
    }   
    else 
    {
        $avgAllPred = "PD";
    } 
    return($avgAllPred,$avgAllConf,%avgPDB);
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

    $ac     = "\U$ac";
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
sub printPred
{
    my $empty= "";
    
    if($::printpdb || $::printall)
    {
        printf "Header:  Uniprotac, Nat, Resnum, Mut, PDBcode, Chain, Structype, Resolution, Rfactor, Predection, Confidant\n";
        
        for(my $i=1; $i<$::pdblimit+1; $i++)
        {   
            #-- To print all the result including each PDB/Chain combination
            #    and the different Models prediction
            if($::printall)
            {
                #-- Printing different Models prediction of $i PDB/Chain
                for(my $e=1; $e<$::mlimit+1; $e++) # or $count
                { 
                    printf "Model%s:  %9s, %3s, %6d, %3s, %7s, %5s, %9s, %10s, %7s, %10s, %.3f\n",$e, $sprot, $nat, $pos, $mut,$id{pdbcode}[$i],$id{chain}[$i],$id{structype}[$i],$id{reseolution}[$i],$id{rfactor}[$i], $allPrediction{'pred'.$i}[$e], $allPrediction{'conf'.$i}[$e];  
                }
            }        
            printf "Avrg%s:   %9s, %3s, %6d, %3s, %7s, %5s, %9s, %10s, %7s, %10s, %.2f\n",$i, $sprot, $nat, $pos, $mut,$id{pdbcode}[$i],$id{chain}[$i],$id{structype}[$i],$id{reseolution}[$i],$id{rfactor}[$i],$pdbPredection{pred}[$i],$pdbPredection{conf}[$i]; 
        }  
     
        #-- Print the average for all prediction result 
        printf "AvrgALL: %9s, %3s, %6d, %3s, %7s, %5s, %9s, %10s, %7s, %10s, %.2f\n",$sprot,$nat,$pos,$mut,$empty,$empty,$empty,$empty,$empty,$avgPred,$avgConf; 
    }
    else
    {
        #-- The default setting for printing
        print  "Header:  Uniprotac, Nat, Resnum, Mut, Predection, Confidant\n";
        printf "AvrgALL: %9s, %3s, %6d, %3s, %10s, %.2f\n",$sprot,$nat,$pos,$mut,$avgPred,$avgConf; 
    }     
}
#-------------------------------------------------------------------------
sub PrintJson
{
    my ($programName, $ac, $resnum, $native, $mutant, $outFile) = @_;
    my @results;
    if(open(JSON, ">$outFile"))
    {        
        print JSON <<__EOF;
\{"$programName":\{ 
      "uniprotac": "$sprot",
      "resnum": $pos,
      "native": "$nat",
      "mutant": "$mut",
      "pdbs"  : \[
__EOF


for(my $i=1; $i<$::pdblimit+1; $i++) 
  {    
    #-- To turn PDB codes into a filename...
    my $pdbfile = $configPred::pdbprep.$id{pdbcode}[$i].$configPred::pdbext;

    print JSON <<__EOF;
                 \{"$programName":\{
                       "file": "$pdbfile",
                       "pdbcode": "$id{pdbcode}[$i]",
                       "residue": "$id{chainresnum}[$i]",
                       "mutation": "$id{mutation}[$i]",
                       "structuretype": "$id{structype}[$i]",
                       "resolution": "$id{reseolution}[$i]",
                       "rfactor": "$id{rfactor}[$i]",
                       "results": \[
__EOF
        
       #-- Printing different Models prediction of $i PDB/Chain
      for(my $e=1; $e<$::mlimit+1; $e++)
      {
          print JSON "                                   {\"Prediction\": \"$allPrediction{'pred'.$i}[$e]\", \"Confidence\": \"$allPrediction{'conf'.$i}[$e]\"";
          endJsonArray($e,$::mlimit);
          
      }
    
    print JSON  "                       \"Avgerge\": {\"Prediction\": \"$pdbPredection{pred}[$i]\", \"Confidence\": \"$pdbPredection{conf}[$i]\"\}\n"; 
    print JSON  "                        }\n"; 
    print JSON  "                 ";
    endJsonArray($i,$::pdblimit);
  }  
    

        print JSON  "      \"Final\": {\"Prediction\": \"$avgPred\", \"Confidence\": \"$avgConf\"}\n";
        print JSON  "   }\n";
        print JSON  "}\n";


    }
    
    else
    {
    print STDERR "Error: Unable to open file: '$outFile";
    exit 1;
    }
}
#-------------------------------------------------------------------------
sub endJsonArray
{
    my ($num,$limit) = @_;
    

    if($num<($limit))
    {
        print JSON "},\n";
    }
    else
    {
        print JSON "}],\n";
    }
}
#-------------------------------------------------------------------------  
sub UsageDie
{
    print <<__EOF;

saapPred V1.0 (c) 2012, UCL, Nouf S. Al Numair
Usage: 
        saapPred uniprotAC native resnum newres
        [-v [-info]] [-json=file] [-printall or -printpdb] 
        [-pdblimit=n] [-modllimit=n] > prediction.txt

       
        -json=file If a json file is specified, then
                   saapPred will skip the pipeline analysis
                   and use givin json file.
        -pdblimit  Set the maximum number of PDB chains
                   to analyze
        -modlimit  Set the number of Models unsed in 
                   pathogencity redection.
        -printpdb  Print prediction results from diffrent
                   PDB/Chain structures
        -printall  Print prediction results from diffrent
                   moduels from each PDB/Chain structure
        -prinjson  Print prediction results in a JSON format.
         -v        Verbose
  

Runs the SaapPred that sequentially run
- Analysis pipeline on diffrent number of PDB/Chain (-pdblimit)
           that matches a specified uniprot accession.
- json2csv parses JSON file and convert it to CSV file contains
           a first record with column names and following records
           with pipeline structural analysis data.
- csv2arff extracts the columns named in config file from CSV file
           and convert it to ARFF file.
- Run diffrent numbers of predectour models (-modlimit) then  


The uniprotAC us a UniProt accession (e.g. P69905)

The native and mutant residues (native, newres) may be specified
in upper, lower or mixed case and using 1-letter or 3-letter code.

The resnum is the UniProt reside number.

__EOF

    exit 0;
}
