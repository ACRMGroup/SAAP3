#!/usr/bin/perl -s
use configPred;
use strict;
use SAAP;


my $predFile = "gtg";
my %pred;
 for (my $i=0; $i<$::n; $i++)
 {
     $predFile =$predFile."_".$i;
     my $inst = 0;
     my $theModel = sprintf ( $configPred::model,$i+1) ;
     my $pred = "$configPred::java $configPred::memory -cp $configPred::weka $configPred::classifiers -T $::arffFile -l $theModel -p 0 &> $predFile";
     system( $pred ); 
     
     open(PR, $predFile); 
     while(my $line = <PR>) 
     { 
         if($line =~ m/\s+\d+\s+\d+:\w+\s+\d+:(\w+).*(\d+\.\d+)/) 
         {
             if ($1 eq "PD") {$pred{"pred".$inst}[$i] = 1;} else {$pred{"pred".$inst}[$i] = 0;} 
             $pred{"conf".$inst}[$i] = $2 ;
             $inst++;
         }
     }
     close FH;
 }


print "$pred{pred2}[0]  $pred{conf2}[0]\n";
print "$pred{pred2}[1]  $pred{conf2}[1]\n";
print "$pred{pred2}[2]  $pred{conf2}[2]\n";
print "$pred{pred2}[3]  $pred{conf2}[3]\n";
