#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    saapPred
#   File:       saapPred.pl
#   
#   Version:    V1.3
#   Date:       06.10.15
#   Function:   
#   
#   Copyright:  (c) Nouf S. Al Numair, UCL, 2012-2015
#   Author:     Nouf S. Al Numair and Andrew C.R. Martin
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
#   V1.1   16.04.13  Added 
#                    $config::tmpRootDir 
#                      - specifies base tmp dir rather than /tmp
#                    $config::remote
#                      - specifies remote machine on which to run Weka
#                    Corrected some spelling errors in output
#                    By: ACRM
#   V1.2   28.03.14  The summary prediction was wrong as average() was
#                    not correctly handling confidence for SNP vs PD.
#                    This meant all predictions were PD.
#   V1.3   06.10.15  Now takes -log parameter
#
#*************************************************************************

use strict;
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/..");
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/");
use config;
use SAAP;

$|=1;                           # Turn on flushing

my($sprot,$pos,$nat,$mut) = ParseCmdLine();
my $programName = "saapPred";

#-- Check for -h - help request
UsageDie() if(defined($::h));

$::printpdb  = defined($::printpdb)?1:0;
$::printall  = defined($::printall)?1:0;
$::printjson = defined($::printjson)?1:0;
$::log       = defined($::log)?$::log:'';

#-- Check for pdblimit (should be be an odd number) 
if(!defined($::pdblimit))
{
    $::pdblimit = $config::pdblimit;
} 
else 
{
    if($::pdblimit % 2 == 0) 
    {
        $::pdblimit = $::pdblimit + 1;
    }
}                          

#-- Check for modlimit (should be be an odd number between 1-9)
if(!defined($::modlimit)) 
{
    $::modlimit = $config::modlimit;
} 
else 
{
    if($::modlimit && ($::modlimit % 2 == 0))
    {
        $::modlimit = $::modlimit + 1;
    }
}
if(($::modlimit > 9) || ($::modlimit == 0))
{
    $::modlimit = 9;
}

#-- Check for prePred (should be either PD or SNP)
if(!defined($::prePred)) 
{
    $::prePred = "PD";
}

#-- Make a unique temporary directory under /tmp/ 
# 06.12.13 Added 'time' to directory name   By: ACRM 
my $tmpDir = "$config::tmpDir" . "/saapPred$$" . time . "/";
`mkdir $tmpDir`;

#-- Define files 
my $jsonFile;
if(!defined($::json))
{
    $jsonFile = $tmpDir.$sprot."_".$nat."_".$pos."_".$mut.".json"; 
    $::json = "";
} 
else 
{
    $jsonFile = $::json;
}

my $csvFile  = $tmpDir.$sprot."_".$nat."_".$pos."_".$mut.".csv";
my $arffFile = $tmpDir.$sprot."_".$nat."_".$pos."_".$mut.".arff";
my $idFile   = $tmpDir.$sprot."_".$nat."_".$pos."_".$mut."_id";
my $predFile = $tmpDir.$sprot."_".$nat."_".$pos."_".$mut.".txt";
my $jsonOut  = $tmpDir.$sprot."_".$nat."_".$pos."_".$mut."_pred.json";

#--------------------------------------------------------------------------#
#-- Run the pipeline using uniprotPipeline and save the JSON file        --#
#--------------------------------------------------------------------------#
if(!($::json))  
{
    Log("Running SAAP Pipeline ... ");
    my $exec1 = "$config::saapUniprotPipeline -limit=$::pdblimit $sprot $nat $pos $mut > $jsonFile";
    `$exec1`; 
    Log("Done\n");
}

#-------------------------------------------------------------------------#
#----------------- Parses JSON file to get csv file ----------------------#
#-------------------------------------------------------------------------#
Log("Converting JSON to CSV ... ");
if(-e $jsonFile)
{
    my $exec2  = "$config::parseJSON $jsonFile $::prePred > $csvFile";
    `$exec2`;
}
else # 06.12.13 Added this if JSON file not found By: ACRM
{
    Log("Error (saapPred): Specified JSON file ($jsonFile) does not exist\n", 1);
    `\\rm -rf $tmpDir`;
    exit 1;
}
Log("Done\n");

#-------------------------------------------------------------------------#
#----------------- Run csv2arff.pl to get arff file ----------------------#
#-------------------------------------------------------------------------#
Log("Converting CSV to ARFF ... ");
if(`grep -Ev 'PDBSWS|acrm|ERROR|Error' $csvFile` )  ## Check this! ACRM
{
    my $exec3 = "$config::csv2arff $config::csv2arffOptions -norm=$config::normScale -class=$config::class -id=$config::id -idfile=$idFile -inputs=$config::features $config::output $csvFile > $arffFile "; 
    `$exec3`;
}    
else
{
    my $error = `cat $csvFile` ; 
    Log("$error\n", 1);      # 06.12.13 CSV file now contains 'ERROR: ' By: ACRM
    `\\rm -rf $tmpDir`;
    exit 1;                  # 06.12.13 Now exits on error in CSV file  By: ACRM
}
Log("Done\n");

#-- save Ids in a hash for printing propounds 
my %id = saveIDS($idFile);

#-------------------------------------------------------------------------#
#------------------------ Run the predictor ------------------------------#
#-------------------------------------------------------------------------#
Log("Running the predictor\n");
my (%allPrediction) = runPredictor($::modlimit);

#-------------------------------------------------------------------------#
#------------------------  Averaging result  -----------------------------#
#-------------------------------------------------------------------------#
Log("Averaging results ... ");
my ($avgPred,$avgConf,%pdbPrediction) = average(%allPrediction);
Log(" Done\n");

#-------------------------------------------------------------------------#
#------------------------  Printing result  ------------------------------#
#-------------------------------------------------------------------------#
Log("Printing results ... \n");
printPred();

if($::printjson)  
{
    Log("Printing results in JSON ... ");
    PrintJson($programName, $sprot,$pos,$nat,$mut,$jsonOut);
    Log(" Done\n");
}

#-- Deleting /tmp files
`rm -rf $tmpDir`;
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
        Log("Can't open $idFile file with IDs fields\n", 1);
        exit 1;
    }
    return(%id);
}
#-------------------------------------------------------------------------
sub runPredictor
{
    my ($numberOfModels) = @_;
    my %prediction;
	
    for(my $i=1; $i<$numberOfModels+1; $i++)
    {   
        Log("Running Model $i of $numberOfModels ... ");

        my $theModel = sprintf ( $config::model,$i) ;
        my $runPredictors = "";

        if($config::remote eq "")
        {
            $runPredictors = `$config::java $config::memory -cp $config::weka $config::classifiers -T $arffFile -l $theModel -p 0 > $predFile.$i`;
        }
        else
        {
            $runPredictors = `ssh $config::remote "$config::java $config::memory -cp $config::weka $config::classifiers -T $arffFile -l $theModel -p 0 > $predFile.$i"`;
        }
       
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
            Log("Error: Unable to open file: $predFile.$i ", 1);
            exit 1;
        }
        Log("Done\n");
    }
	return(%prediction);
}
#-------------------------------------------------------------------------
# averaging Models performance for each PDB structure
# 28.03.14 Fixed the averaging. Before it was using 1-score for SNPs
#          which meant that lots of medium confidence scores added
#          up to > 0.5. i.e. they effectively become less confident as
#          we get more of them. Now we add the PD and SNP predictions 
#          separately and subtract the SNP predictios from the PD
#          predictions. This means SNP ones become more negative and
#          PD becomes more positive with a threshold of zero for
#          the SNP/PD boundary.  By: ACRM
# 05.10.15 Added check on number of structures to avoid /0 error
sub average
{
    my (%hash) = @_;
    my %avgPDB; 
    my $allPred    = "";  my $allConf    = 0;
    my $avgAllPred = "";  my $avgAllConf = 0;
    my $strucCount = 0;


    for(my $i=1; $i<$::pdblimit+1; $i++) 
    {    
        # Check this structure number exists. If it does, increment the
        # number of structures - if not then exit the loop through
        # structures
        if(defined($hash{'pred'.$i}))
        {
            $strucCount++;
        }
        else
        {
            last;
        }


        my $pdbPred = ""; 
        my $pdbConf = 0;
        my $PDConf  = 0;
        my $SNPConf = 0;
        my $nSNP    = 0;
        my $nPD     = 0;
        
        # Loop through the models adding up the confidence for
        # SNP and PD predictions
        for(my $e=1; $e<$::modlimit+1; $e++) 
        { 
            # Exit the loop if we have run out of models
            last if(!defined($hash{'pred'.$i}[$e]));

            if ($hash{'pred'.$i}[$e] eq "PD")
            {
                $PDConf += $hash{'conf'.$i}[$e]; 
                $nPD++;
            }
            else
            {
                $SNPConf += $hash{'conf'.$i}[$e]; 
                $nSNP++;
            }
        }

        # Find the average SNP and PD predictions
        $PDConf  /= (($nPD > 0)?$nPD:1);
        $SNPConf /= (($nSNP > 0)?$nSNP:1);

        #-- $avgPdbPred and $avgPdbConf are the average of different Models
        #   results for $i PDB entry
        my $avgPdbConf = $PDConf - $SNPConf;
        $allConf += $avgPdbConf;  

        my $avgPdbPred;  
        if($avgPdbConf < 0) 
        { 
            $avgPdbPred = "SNP";
            $avgPdbConf = 0-$avgPdbConf;
        }   
        else 
        {
            $avgPdbPred = "PD";
        }
        
        #-- %avgPDB is a hash to save $pdbPred and $pdbConf for each $i
        $avgPdbConf = sprintf "%.2f", $avgPdbConf;
        $avgPDB{pred}[$i] = $avgPdbPred;
        $avgPDB{conf}[$i] = $avgPdbConf;    
     
    }  

    my $avgAllConf = 0;
    if($strucCount)             # 05.10.15 Added By: ACRM
    {
        #-- $avgAllPred is the average of all PDB averages
        $avgAllConf = $allConf/$strucCount;
    
        if($avgAllConf < 0) 
        { 
            $avgAllPred = "SNP";
            $avgAllConf = 0-$avgAllConf;
        }   
        else 
        {
            $avgAllPred = "PD";
        } 
    }
    else
    {
        $avgAllPred = "ERROR";
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
        LogPrint("Header:  UniProtAC, Nat, Resnum, Mut, PDBcode, Chain, Structype, Resolution, Rfactor, Prediction, Confidence\n");
        
        for(my $i=1; $i<$::pdblimit+1; $i++)
        {   
            #-- To print all the result including each PDB/Chain combination
            #    and the different Models prediction
            if($::printall)
            {
                #-- Printing different Models prediction of $i PDB/Chain
                for(my $e=1; $e<$::modlimit+1; $e++) # or $count
                { 
                    LogPrint("Model%s:  %9s, %3s, %6d, %3s, %7s, %5s, %9s, %10s, %7s, %10s, %.3f\n",$e, $sprot, $nat, $pos, $mut,$id{pdbcode}[$i],$id{chain}[$i],$id{structype}[$i],$id{reseolution}[$i],$id{rfactor}[$i], $allPrediction{'pred'.$i}[$e], $allPrediction{'conf'.$i}[$e]);  
                }
            }        
            LogPrint("Avrg%s:   %9s, %3s, %6d, %3s, %7s, %5s, %9s, %10s, %7s, %10s, %.2f\n",$i, $sprot, $nat, $pos, $mut,$id{pdbcode}[$i],$id{chain}[$i],$id{structype}[$i],$id{reseolution}[$i],$id{rfactor}[$i],$pdbPrediction{pred}[$i],$pdbPrediction{conf}[$i]); 
        }  
     
        #-- Print the average for all prediction results
        LogPrint("AvrgALL: %9s, %3s, %6d, %3s, %7s  %5s  %9s  %10s  %7s  %10s, %.2f\n",$sprot,$nat,$pos,$mut,$empty,$empty,$empty,$empty,$empty,$avgPred,$avgConf); 
    }
    else
    {
        #-- The default setting for printing
        LogPrint("Header:  UniProtAC, Nat, Resnum, Mut, Prediction, Confidence\n");
        LogPrint("AvrgALL: %9s, %3s, %6d, %3s, %10s, %.2f\n",$sprot,$nat,$pos,$mut,$avgPred,$avgConf); 
    }     

    LogPrint("\n****************************************************\n");
    LogPrint("*                                                  *\n");
    LogPrint("*  FINAL PREDICTION: %-10s CONFIDENCE: %5.2f  *\n", $avgPred, $avgConf);
    LogPrint("*                                                  *\n");
    LogPrint("*  PD = Pathogenic; SNP = Neutral                  *\n");
    LogPrint("*                                                  *\n");
    LogPrint("****************************************************\n");
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
            my $pdbfile = $config::pdbPrep.$id{pdbcode}[$i].$config::pdbExt;

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
            for(my $e=1; $e<$::modlimit+1; $e++)
            {
                print JSON "                                   {\"Prediction\": \"$allPrediction{'pred'.$i}[$e]\", \"Confidence\": \"$allPrediction{'conf'.$i}[$e]\"";
                endJsonArray($e,$::modlimit);
            }
    
            print JSON  "                       \"Average\": {\"Prediction\": \"$pdbPrediction{pred}[$i]\", \"Confidence\": \"$pdbPrediction{conf}[$i]\"\}\n"; 
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
        Log("Error: Unable to open file: '$outFile", 1);
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
sub Log
{
    my($text, $force) = @_;
    if(($::log ne '') && open(my $logfh, '>>', $::log))
    {
        print $logfh $text;
        close $logfh;
    }
    print STDERR $text if($::v || $force);
}

#-------------------------------------------------------------------------  
sub LogPrint
{
    my(@params) = @_;
    if(($::log ne '') && open(my $logfh, '>>', $::log))
    {
        printf $logfh @params;
        close $logfh;
    }
    printf @params;
}

#-------------------------------------------------------------------------  
sub UsageDie
{
    print <<__EOF;

saapPred V1.3 (c) 2012-15, UCL, Nouf S. Al Numair, Dr. Andrew C.R. Martin
Usage: 
        saapPred uniprotAC native resnum newres
        [-v [-info]] [-log=logfile] [-json=file] [-printall | -printpdb] 
        [-pdblimit=n] [-modlimit=n] [-printjson] > prediction.txt
       
        -json=file  If a json file is specified, then
                    saapPred will skip the pipeline analysis
                    and use given JSON file.
        -pdblimit   Set the maximum number of PDB chains
                    to analyze
        -modlimit   Set the number of Models used in 
                    pathogencity prediction.
        -printpdb   Print prediction results from different
                    PDB/Chain structures
        -printall   Print prediction results from different
                    models from each PDB/Chain structure
        -printjson  Print prediction results in JSON format.
        -v          Verbose
        -log        Save all progress/error messages to the specified file
  

Runs SAAPpred that sequentially runs
- The analysis pipeline on different numbers of PDB/Chain (-pdblimit)
           that match a specified uniprot accession.
- json2csv parses JSON file and converts it to a CSV file containing
           a first record with column names and following records
           with pipeline structural analysis data.
- csv2arff extracts the columns named in the config file from the 
           CSV file and converts them to an ARFF file.
- Runs different numbers of predictor models (-modlimit) using 
           Weka
- Averages the results to give a final prediction

The uniprotAC is a UniProt accession (e.g. P69905)

The native and mutant residues (native, newres) may be specified
in upper, lower or mixed case and using 1-letter or 3-letter code.

The resnum is the UniProt reside number.

__EOF

    exit 0;
}
