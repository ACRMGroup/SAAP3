#!/usr/bin/perl -s

use configPred;
use strict;
use SAAP;

my($sprot, $pos, $nat, $mut) = ParseCmdLine();

#-- Check for -h - help request
UsageDie() if(defined($::h));

$::v     = defined($::v)?"-v":"";
$::info  = defined($::info)?"-info":"";
$::printpdb  = defined($::printpdb)?"-printpdb":"";
$::printall  = defined($::printall)?"-printall":"";
#$::avg  = defined($::avg)?"-avg":"";

#-- Check for user-specified PDBlimit and prePred
if(!defined($::PDBlimit)) {$::PDBlimit = "3";} else {if ($::PDBlimit % 2 == 0) {$::PDBlimit = $::PDBlimit + 1;}}    # Should be be an odd number                          
if(!defined($::Mlimit))   {$::Mlimit   = "5";} else {if ($::Mlimit   % 2 == 0) {$::Mlimit   = $::Mlimit   + 1;}}    # Should be be an odd number betwen 1-9
if(!defined($::prePred))  {$::prePred = "PD";} #PD or SNP

my $jsonFile;
if(!defined($::json)) {$jsonFile = $configPred::pipelineJSON."/".$sprot."_".$nat."_".$pos."_".$mut.".json"; $::json="";} else {$jsonFile = $::jason};
my $csvFile    = $configPred::csvDir."/".$sprot."_".$nat."_".$pos."_".$mut.".csv";
my $arffFile   = $configPred::arffDir."/".$sprot."_".$nat."_".$pos."_".$mut.".arff";
my $idFile     = $configPred::arffDir."/".$sprot."_".$nat."_".$pos."_".$mut."_id";
my $predFile   = $configPred::predDir."/".$sprot."_".$nat."_".$pos."_".$mut.".txt";
my $piplineOut = $configPred::tmpDir."/".$sprot."_".$nat."_".$pos."_".$mut.".out";



#-- save IDs in array num:uniprotac:res:nat:mut:pdbcode:chain:resnum:mutation:structuretype:resolution:rfactor
my $count=1;
my %id;
my @ID;

if(open(FILE, $idFile))
{
    while(<FILE>)
    {
        chomp;
        my @values    = split(',');
        @ID        = split('\:', $values[0]);
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
print STDERR "     ... Run the predectour";
my %predection = runPredectour($::Mlimit);
print STDERR "  ... Done\n";
   

#-----------------------#
#--  Avraging result  --#
#-----------------------#
print STDERR "     ... Avraging          ";
my ($avg_pred,$avg_conf,%predection_pdb) = averag(%predection) ;# avraging Models prormance for each PDB structer
#my %predection_one = averag(%predection_PDB) # avraging Models prormance for each PDB structer
print STDERR "  ... Done\n";

#-----------------------#
#--  Printing result  --#
#-----------------------#
print STDERR "     ... Printing results\n";
my $p;

if (($::printpdb)||($::printall))
{
    if(!($::v))
    {
        printf "%6s %1s %d %1s:\n",$sprot, $nat, $pos, $mut;    
        for(my $i=1; $i<$::PDBlimit+1; $i++)
        { 
            if ($predection_pdb{pred}[$i] > 0.5) {$p = "PD";} else {$p = "SNP";};
            printf "SAAPpred %s %s %.2f\n",$id{pdbcode}[$i], $p, $predection_pdb{conf}[$i]; 
            
            if ($::printall)
            {
                for(my $e=1; $e<$::Mlimit+1; $e++) # or $count
                { 
                    if ($predection{'pred'.$i}[$e] == 1) {$p = "PD";} else {$p = "SNP";};
                    print "Model $e predection $p with a confidant of $predection{'conf'.$i}[$e]\n"; 
                }
            }
        }   
    }
    else  
    {
        printf "%6s %1s %d %1s:\n",$sprot, $nat, $pos, $mut;    
        for(my $i=1; $i<$::PDBlimit+1; $i++)
        { 
            print"\n
            pdbcode   : $id{pdbcode}[$i]
            chain     : $id{chain}[$i]
            structype : $id{structype}[$i]
            resolution: $id{reseolution}[$i]
            rfactor   : $id{rfactor}[$i]\n";
            
            if ($predection_pdb{'pred'}[$i] > 0.5) {$p = "PD";} else {$p = "SNP";}
            printf "SAAPpred %s %.2f\n", $p, $predection_pdb{'conf'}[$i]; 
            print "------------------------------------------------------------------------------\n";
            
            if ($::printall)
            {
                for(my $e=1; $e<$::Mlimit+1; $e++) # or $count
                { 
                    if ($predection{'pred'.$i}[$e] == 1) {$p = "PD";} else {$p = "SNP";};
                    print "Model $e predection $p  with a confidant of  $predection{'conf'.$i}[$e]\n"; 
                }
            }
        }   
    }
}
else
{
    printf "%6s %1s %d %1s: %s %.2f\n",$sprot, $nat, $pos, $mut, $avg_pred, $avg_conf; 
}


print STDERR "    ... Done\n";
    
#-------------------------------------------------------------------------
sub averag
{
    my (%hash) = @_;
  #  my $inst = 1;  
    my %h1; my %h2;
    my  $avg_predall = "" ;my  $avg_confall = "";
    for(my $i=1; $i<$::PDBlimit+1; $i++) # or $count
    { 
        
        my $pred = ""; my $conf = "";
        for(my $e=1; $e<$::Mlimit+1; $e++) # or $count
        { 
            $pred += $hash{'pred'.$i}[$e];
            $conf += $hash{'conf'.$i}[$e]; 
        }
        $pred = $pred/$::Mlimit;
        $conf = $conf/$::Mlimit;

        $h1{pred}[$i] = $pred;
        $h1{conf}[$i] = $conf;      
        
        $avg_predall += $pred;
        $avg_confall += $conf;
        
    }  
    $avg_predall = $avg_predall/$::PDBlimit;
    $avg_confall = $avg_confall/$::PDBlimit;


    if ( $avg_predall > 0.5) { $avg_predall = "PD";} 
    elsif($avg_predall == 0.5) 
    {
        if  ($h1{conf}[1] > $h1{conf}[2]) {$avg_predall = $h1{pred}[1];} else { $avg_predall = $h1{pred}[2];} 
        if ( $avg_predall > 0.5) { $avg_predall = "PD";} else {$avg_predall = "SNP"; }
    }
    else 
    {
        $avg_predall = "SNP";
    }
    
    return ($avg_predall,$avg_confall,%h1);
}

#-------------------------------------------------------------------------
sub runPredectour
{
my ($n) = @_;
my %p;

  
     
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
 
return (%p);
}

#-------------------------------------------------------------------------
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
#-------------------------------------------------------------------------
sub create_sh_file
{
    my $file = $configPred::tmpDir."/".$sprot."_".$nat."_".$pos."_".$mut.".sh";
   
    open ( FILE, ">$file" ) || die "Cannot write to file '$file'\n$!\n";
    print FILE "#!/bin/sh\n#\$ -S /bin/sh\n\n";
    #-- Define command line inputs
    print FILE  "cd ".$configPred::piplineDir." \n";
    print FILE  "source ./init.sh \n";
    print FILE  $configPred::perl." ".$configPred::pipeline_uniprot." -limit=".$::PDBlimit." ".$sprot." ".$nat." ".$pos." ".$mut."  > ".$jsonFile." \n"; 
    #print FILE  $configPred::perl." ".$configPred::pipeline_uniprot." -v -limit=".$::PDBlimit." ".$sprot." ".$nat." ".$pos." ".$mut."  > ".$jsonFile." \n";
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
