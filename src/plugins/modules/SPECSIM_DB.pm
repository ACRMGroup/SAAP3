package SPECSIM;
#*************************************************************************
#
#   Program:    
#   File:       
#   
#   Version:    V2.0
#   Date:       25.08.11
#   Function:   Scorecons-type calculation but with species similarity
#               corrections
#   
#   Copyright:  (c) Lisa McMillan & Dr. Andrew C. R. Martin, UCL, 2011
#   Author:     Lisa McMillan & Dr. Andrew C. R. Martin
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
#   V1.0  ??.??.?? Original  By: LEMM
#   V2.0  25.08.11 Modified to move the species similarity data into a
#         file rather than in a database to ease portability.
#         Also filenames all up the top and can be overridden on command
#         line
#         Still in need of a serious cleanup and commenting!
#
#*************************************************************************
use strict;
use config;
use DBI;
use SAAP;

#*************************************************************************
# Constants returned by GetSpecsim()
$::ERR_NODUMP       = (-1);
$::ERR_NOACCESSDUMP = (-2);
$::ERR_DBMOPEN      = (-3);
$::ERR_SPECIES      = (-4);

# Make GetSpecsim() run in verbose mode when creating the hash
# Set >1 to warn when species don't exist in the similarity matrix
$::VERBOSE = 1;

# Global variable for DBI connection to database
$::dbname="mcmillan";
$::dbhost="acrm8";
$::dbuser="apache";
$::specsimMean = 0.708276767778027;

#*************************************************************************
# ($status, @results) = RunSpecSim(\@sequences, \@sequenceIDs, $fullPrint);
sub RunSpecSim
{
    my ($pSequences, $pSequenceIDs, $fullPrint) = @_;

    my $seqLength = length($$pSequences[0]);

    # reading in the scoring matrix
    my %aa2pos = ( "A", 0,  "R", 1,  "N", 2,  "D", 3, 
                   "C", 4,  "Q", 5,  "E", 6,  "G", 7, 
                   "H", 8,  "I", 9,  "L", 10, "K", 11, 
                   "M", 12, "F", 13, "P", 14, "S", 15, 
                   "T", 16, "W", 17, "Y", 18, "V", 19, 
                   "B", 20, "Z", 21, "X", 22, "-", 23 );

    my %pos2aa = ();

    while ( my ( $key, $value ) = each %aa2pos )
    {
        $pos2aa{ $value } = $key;
    }

    my %mScores = ();
    my $aa_counter = 0;
    my $min = 10000;
    my $max = 0;

    if(!open( MAT, $config::matrixFile ))
    {
        return("Can't open matrix file: $config::matrixFile", undef);
    }

    while( <MAT> )
    {
        my $line = $_;
        $line =~ s/^\s+//g;
        $line =~ s/s+$//g;

        if ( substr( $line,0,1 ) ne "!" && $line =~ /\d/ )
        {
            my @scores = split( /\s+/, $line );
            
            for ( my $i=0; $i<@scores; $i++ )
            {
                $mScores{ $pos2aa{ $aa_counter } }{ $pos2aa{ $i } } = $scores[$i];
                $max = $scores[$i] if ( $scores[$i] > $max );
                $min = $scores[$i] if ( $scores[$i] < $min );
            }
            
            $aa_counter++;
        }
    }

    close( MAT );

    # normalising the matrix so that:
    #   the minimum value is 0
    #   the maximum value is 1

    my @aas = keys( %aa2pos );
    $max -= $min;

    for ( my $i=0; $i<@aas; $i++ )
    {
        for ( my $j=0; $j<@aas; $j++ )
        {
            my $tmp_val = $mScores{ $aas[$i] }{ $aas[$j] };
            $tmp_val -= $min;
            $tmp_val /= $max;
            $mScores{ $aas[$i] }{ $aas[$j] } = $tmp_val;
        }
    }    


    # calculating the score, weighted by sequences similarity
    $::avg_specsim = GetSpecsim($config::specsimDumpFile, $config::specsimHashFile, "MEAN", "MEAN");

    # Check for error
    if($::avg_specsim < 0)
    {
        if($::avg_specsim == $::ERR_NODUMP)
        {
            print STDERR "Specsim dump file doesn't exist: $config::specsimDumpFile\n";
        }
        elsif($::avg_specsim == $::ERR_NOACCESSDUMP)
        {
            print STDERR "Can't open Specsim dump file: $config::specsimDumpFile\n";
        }
        elsif($::avg_specsim == $::ERR_DBMOPEN)
        {
            print STDERR "Can't open Specsim DBM hash file: $config::specsimHashFile\n";
        }
        elsif($::avg_specsim == $::ERR_SPECIES)
        {
            print STDERR "Mean Specsim data not available. Maybe DBM hash file created on a different machine: $config::specsimHashFile\n";
        }
        exit 1;
    }


    my %seqsim;

    for ( my $i=0; $i<@$pSequences; $i++ )
    {
        for ( my $j=$i+1; $j<@$pSequences; $j++ )
        {
            my $seq1 = $$pSequences[$i];
            my $seq2 = $$pSequences[$j];
            my $numID = calcNumID( $seq1, $seq2 );
            my $percID = ( $numID/length( $seq1 ) )*100;
            $seqsim{ $i }{ $j } = 100-$percID;
        }
    }

    my %dScores;
    my %columnScores = ();
    my %substitute_warnings;

    my @results = ();

    for ( my $column=0; $column<$seqLength; $column++ )
    {                              
        my $col_score = 0;
        my $lambda = 0;
        
        my $col_string = "";
        
        for ( my $i=0; $i<@$pSequences; $i++ )
        {
            $col_string.=substr( $$pSequences[$i], $column, 1 );
        }
        
        for ( my $scount1=0; $scount1<@$pSequences; $scount1++ )
        {
            for ( my $scount2=$scount1+1; $scount2<@$pSequences; $scount2++ )
            {
                my $res1 = substr( $$pSequences[$scount1], $column, 1 );
                my $res2 = substr( $$pSequences[$scount2], $column, 1 );
                
                my ( $prot1, $spec1 ) = split( /\_/, $$pSequenceIDs[$scount1] );
                my ( $prot2, $spec2 ) = split( /\_/, $$pSequenceIDs[$scount2] );
                
                my $dScore;
                my $substitute;
                
                if ( $dScores{ $spec1 }{ $spec2 } )
                {
                    $dScore = $dScores{ $spec1 }{ $spec2 };
                }
                elsif ( $dScores{ $spec2 }{ $spec1 } )
                {
                    $dScore = $dScores{ $spec2 }{ $spec1 };
                }
                else
                {
                    ( $dScore, $substitute ) = &spec_sim( $spec1, $spec2 );
                    
                    if ( $substitute )
                    {
			$dScores{ $spec1 }{ $spec2 } = $seqsim{ $scount1 }{ $scount2 };
			$dScore = $dScores{ $spec1 }{ $spec2 };
                    }
                    else
                    {
			$dScores{ $spec1 }{ $spec2 } = 100-$dScore;
			$dScore = $dScores{ $spec1 }{ $spec2 };
                    }
                }
                
                if ( $substitute && ( not $substitute_warnings{ $substitute } ) )
                {
                    my ( $spec1, $spec2 ) = split ( /\t/, $substitute );
                    if($::VERBOSE > 1)
                    {
                        print STDERR "WARNING: no specsim score for [$spec1]x[$spec2], using seqsim ($dScores{$spec1}{$spec2})\n";
                    }
                    $substitute_warnings{ $substitute } = 1;
                }
                
                my $mScore = $mScores{ $res1 }{ $res2 };
                
                $lambda += $dScore;
                my $score = $dScore*$mScore;
                $col_score += $score;
            }
        }
        
        if ( $lambda == 0 )
        {
            $columnScores{ $column } = 1;
        }
        else
        {
            $columnScores{ $column } = $col_score/$lambda;
        }
        
        if($fullPrint)
        {
            push @results, sprintf("%4d %6.6f %s", $column+1, $columnScores{$column}, $col_string);
        }
        else
        {
            push @results, $columnScores{$column};
        }
    }
    return("OK", @results);
}

#-------------------------------------------------------------------------
sub spec_sim
{
    my ( $spec1, $spec2 ) = @_;

    my $specsim = GetSpecsim($config::specsimDumpFile, $config::specsimHashFile, $spec1, $spec2);

    if ( $specsim > 0 )
    {
	return ( $specsim*100, 0 );
    }
    else
    {
	return ( $::avg_specsim*100, "$spec1\t$spec2" );
    }
}

#-------------------------------------------------------------------------
# calculates the number of identical residues in two sequences
sub calcNumID
{
    my ( $seq1, $seq2 ) = @_;
    my $numID = 0;
    
    for ( my $i=0; $i<length( $seq1 ); $i++ )
    {
	my $residue1 = substr( $seq1, $i, 1 );
	my $residue2 = substr( $seq2, $i, 1 );
	$numID++ if ( $residue1 eq $residue2 );
    }

    return $numID;
}

#-------------------------------------------------------------------------
sub GenerateThreshold
{
    my($consFile, $name, $outFile) = @_;

    my $graphFile = $consFile;
    $graphFile =~ s/\.pire\.cons\.dat//;
    $graphFile .= ".pdf";

    my $thresholdFile = $graphFile;
    $thresholdFile =~ s/\.pdf//;
    $thresholdFile .= ".threshold";

    my $prestring = "pire.file <- '$consFile' ; protein.name <- '$name' ; graph.file <- '$graphFile' ; c1 <- $SAAP::impactC1 ; c2 <- $SAAP::impactC2 ; rounds <- 50 ;";
    #my $prestring = "pire.file <- '$consFile' ; protein.name <- '$name' ; graph.file <- '$graphFile' ; c1 <- $config::impactC1 ; c2 <- $config::impactC2 ; rounds <- 2 ;"; ## DEBUG!

    my $errFile = $outFile.".err";

    my $dostring = "( "."echo \"$prestring\" | cat - $config::RProg | $config::RExe --slave \\--vanilla > $thresholdFile ) >& $errFile ";
    # print "[$dostring]\n";
    my $do_optimisation = 1;
    my $optimisation_iteration = 0;
    my $threshold;

    system( "$dostring" );

    if(!( -e $thresholdFile ) || (-z $thresholdFile))
    {
        my $error = `cat $errFile`;
        $error =~ s/^\s+//;
        $error =~ s/\s+$//;
        if($error eq "")
        {
            $error = "Undefined error";
        }
	return(-1, $error);
    }

    my $threshold = (-1);
    if(open(my $FILE, $thresholdFile))
    {
        # Line following "mean"
        while(<$FILE>)
        {
            if(/^\s+mean/)
            {
                $threshold = <$FILE>;
                $threshold =~ s/\s//g;
            }
        }
        if($threshold == (-1))
        {
            # If we didn't find a line following mean look for
            # the last number after something in square brackets
            seek($FILE, 0, 0);
            while(<$FILE>)
            {
                if(/^\[.*\]\s+(.*)/)
                {
                    $threshold = $1;
                }
            }
        }
    }
    else
    {
        my $error = `cat $errFile`;
        $error =~ s/^\s+//;
        $error =~ s/\s+$//;
        if($error eq "")
        {
            $error = "Undefined error";
        }
	return(-1, $error);
    }

    unlink($thresholdFile);
    unlink($errFile);
    unlink($graphFile);

    $threshold = sprintf("%.2f", $threshold);

    return($threshold, undef);
}


#-------------------------------------------------------------------------
# Database version of GetSpecsim()
sub GetSpecsim
{
    my ($specsimDumpFile, $specsimHashFile, $species1, $species2) = @_;

    my %specsimValues;
    my $line;
    my $count = 0;
    my $total = 0;
    my $s1 = "";
    my $s2 = "";

    my $dbsource = "dbi:Pg:dbname=$::dbname;host=$::dbhost";

    if(($species1 eq "MEAN") && 
       ($species2 eq "MEAN"))
    {
        return($::specsimMean);
    }

    if(!defined($::dbh))
    {
        $::dbh = DBI->connect($dbsource, $::dbuser);
    }
    if(!$::dbh)
    {
        SAAP::PrintJsonError("Impact", "Could not connect to database: $DBI::errstr");
        exit 1;
    }

    
    if($species1 lt $species2)
    {
        $s1 = $species1;
        $s2 = $species2;
    }
    else
    {
        $s1 = $species2;
        $s2 = $species1;
    }

    my $sql = "SELECT avnw FROM specsim WHERE s1 = '$s1' AND s2 = '$s2'";
    my ($result) = $::dbh->selectrow_array($sql);

    return($result);
}



