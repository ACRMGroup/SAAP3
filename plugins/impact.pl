#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    SAAP
#   File:       impact.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   IMPact plugin for the SAAP server
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
#   Run with -vv flag for verbose information on progress
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0 2011       Original
#   V1.1 26.02.14   Added -force and -nocache
#   V1.2 15.10.14   Fixed bug in checking for error return from PDBSWS
#   V1.3 22.10.14   Added -uniID
#   V3.2 20.08.20   Added -uniRes
#
#*************************************************************************
use strict;
use FindBin;
use Cwd qw(abs_path);
use lib abs_path("$FindBin::Bin/../lib");
use lib abs_path("$FindBin::Bin/");
use config;
use FOSTA;
use MUSCLE;
use SPECSIM;
use SAAP;
use PDBSWS;
$| = 1;

# Information string about this plugin
$::infoString = "Analyzing conservation at this position in the sequence";

# Temp files
my $consFile = "$config::tmpDir/IMPACT.$$" . time . ".cons";
my $outFile  = "$config::tmpDir/IMPACT.$$" . time . ".out";


#*************************************************************************
# Parse command line and check for presence of PDB file
my($resid, $newaa, $pdbfile) = SAAP::ParseCmdLine("Impact");


# See if the results are cached
my $json = SAAP::CheckCache("Impact", $pdbfile, $resid, $newaa);
$json = "" if(defined($::force)); 

if($json ne "")
{
    print "$json\n";
    exit 0;
}

# Get the ID and SwissProt residue number for the residue of interest
my $pdbcode;
unless(defined($::uniID))
{
    $pdbcode = ExtractPDBCode($pdbfile);
}
my ($chain, $resnum, $insert) = SAAP::ParseResSpec($resid);
my $pdbres = $resnum . $insert;

my $startTime;
if(defined($::vv)) {$startTime = time; print STDERR "Finding ID from PDBSWS..."}

my $id;
my $sprotRes;
if(defined($::uniID))
{
    $id = $::uniID;
    $sprotRes = (defined($::uniRes))?$::uniRes:$resnum;
}
else
{
    my %pdbsws = PDBSWS::PDBQuery($pdbcode, $chain, $pdbres);
    if(!defined($pdbsws{'ID'}))
    {
        if(defined($pdbsws{'ERROR'}))
        {
            ErrorDie($pdbsws{'ERROR'});
        }
        else
        {
            ErrorDie("No PDBSWS mapping for $pdbcode\n");
        }
    }
    $id = $pdbsws{'ID'};
    $sprotRes = $pdbsws{'UPCOUNT'};
}

if(defined($::vv)) {printf STDERR "done ($id, %d secs)\n", time-$startTime}

my ($threshold, $nseq, @mappedConsScores) = CheckConsCache($id);
if(defined($::force))
{
    $threshold = -1;
    $nseq = 0;
    @mappedConsScores = ();
}

if($threshold < 0)              # not in the cache
{
    # Extract sequences for FEPs using FOSTA and UniProt web services
    # ---------------------------------------------------------------
    if(defined($::vv)) {$startTime = time; print STDERR "Getting FOSTA sequences..."}
    my $sequences;
    ($sequences, $nseq) = FOSTA::GetFOSTASequences($id);
    if($nseq <= 0)
    {
        # FOSTA failed - we'll wait and try once more
        sleep 10;
        ($sequences, $nseq) = FOSTA::GetFOSTASequences($id);
        if($nseq <= 0)
        {
            ErrorDie("FOSTA failed - $sequences");
        }
    }
    if(!($sequences =~ /$id/))
    {
        ErrorDie("FOSTA failed - The search sequence $id not found in the results");
    }
    if(defined($::vv)) {printf STDERR "done ($nseq sequences, %d secs)\n", time-$startTime}

    if($nseq < 2)
    {
        ErrorDie("FOSTA failed - no functionally equivalent proteins found");
    }

    # Run MUSCLE web service writing the results to a PIR format file
    # ---------------------------------------------------------------
    if(defined($::vv)) {$startTime = time; print STDERR "Running MUSCLE..."}
    my ($error, $alignment) = MUSCLE::RunMuscle($sequences, $config::email);
    if($error)
    {
        # MUSCLE failed - we'll wait and try once more
        sleep 10;
        ($error, $alignment) = MUSCLE::RunMuscle($sequences, $config::email);
        if($error)
        {
            ErrorDie($alignment);
        }
    }
    if(defined($::vv)) {printf STDERR "done (%d secs)\n", time-$startTime}

    # Extract the sequence of interest from the alignment
    my $alignedSequence = GetFASTASequence($alignment, $id);
    if($alignedSequence eq "")
    {
        ErrorDie("MUSCLE failed - Sequence $id not found in alignment");
    }

    # Run SpecSim version of Scorecons
    # --------------------------------
    if(defined($::vv)) {$startTime = time; print STDERR "Running SpecSim..."}
    my($error, $pSequences, $pSequenceIDs) = BuildSequenceArrays($alignment);
    if($error)
    {
        ErrorDie($pSequences);
    }
    my($status, @consScores) = SPECSIM::RunSpecSim($pSequences, $pSequenceIDs, 0);
    if($status ne "OK")
    {
        ErrorDie($status);
    }
    if(defined($::vv)) {printf STDERR "done (%d secs)\n", time-$startTime}

    # Map SpecSim conservation scores to our sequence
    # -----------------------------------------------
    if(defined($::vv)) {$startTime = time; print STDERR "Mapping and storing scores..."}
    @mappedConsScores = MapConsScores($alignedSequence, @consScores);

    
    # Write SpecSim data to a file
    if(open(my $CONS, ">$consFile"))
    {
        foreach my $consScore (@consScores)
        {
            print $CONS "$consScore\n";
        }
        close $CONS;
    }
    else
    {
        ErrorDie("Can't write $consFile");
    }
    if(defined($::vv)) {printf STDERR "done (%d secs)\n", time-$startTime}

    # Generate the threshold
    # ----------------------
    if(defined($::vv)) {$startTime = time; print STDERR "Running Threshold..."}
    my $error;
    ($threshold, $error) = SPECSIM::GenerateThreshold($consFile, $id, $outFile);
    unlink($consFile);              # Cleanup - remove the specsim data
    if($threshold < 0)
    {
        ErrorDie($error);
    }
    if(defined($::vv)) {printf STDERR "done (%d secs)\n", time-$startTime}

    # Cache the results for this SwissProt ID
    if(!defined($::nocache))
    {
        StoreConsCache($id, $threshold, $nseq, @mappedConsScores);
    }
}

# See if we are a conserved residue
my $conserved = "OK";
if($mappedConsScores[$sprotRes] >= $threshold)
{
    $conserved = "BAD";
}

# Print the results
$json = SAAP::MakeJson("Impact", ('BOOL'=>$conserved, 
                                    'CONSSCORE'=>$mappedConsScores[$sprotRes], 
                                    'THRESHOLD'=>$threshold,
                                    'NSEQ'=>$nseq));
print "$json\n";
if(!defined($::nocache))
{
    SAAP::WriteCache("Impact", $pdbfile, $resid, $newaa, $json);
}



#*************************************************************************
sub BuildSequenceArrays
{
    my($allSeqs) = @_;

    my @sequenceIDs = ();
    my @sequences = ();

    my @records = split(/\n/, $allSeqs);

    my $sequence = "";

    foreach my $record (@records)
    {
        if($record =~ /^\>/)
        {
            my @fields = split(/\|/, $record);
            my $idPart = $fields[2];
            @fields = split(/\s+/, $idPart);
            my $id = $fields[0];
            if(!($id =~ /.+_.+/))
            {
                return("1", "Valid ID not found in FASTA file. Format from UniProt may have changed", undef);
            }
            push @sequenceIDs, $fields[0];

            if($sequence ne "")
            {
                $sequence =~ s/\s//g;
                push @sequences, $sequence;
                $sequence = "";
            }
        }
        else
        {
            $sequence .= $record;
        }
    }

    if($sequence ne "")
    {
        $sequence =~ s/\s//g;
        push @sequences, $sequence;
    }

    return(0, \@sequences, \@sequenceIDs);
}



#*************************************************************************
sub GetFASTASequence
{
    my($alignment, $id) = @_;

    my $thisID = "";
    my $inRecord = 0;
    my $theSequence = "";

    my @records = split(/\n/, $alignment);
    foreach my $record (@records)
    {
        if($record =~ /^\>/)
        {
            $inRecord = 0;

            # First one matches cases where ID is followed by a | or space
            # Second one matches cases where ID is at end of line
            if(($record =~ /[\>\s\|]([A-Z0-9]{1,5}_[A-Z0-9]{1,5})[\s\|]/)||
               ($record =~ /[\>\s\|]([A-Z0-9]{1,5}_[A-Z0-9]{1,5})$/))
            {
                $thisID = $1;
                if($thisID eq $id)
                {
                    $inRecord = 1;
                }
            }
        }
        if($inRecord)
        {
            $theSequence .= $record . "\n";
        }
    }
    return($theSequence);
}


#*************************************************************************
sub MapConsScores
{
    my($alignedSequence, @consScores) = @_;

    my @mappedConsScores = ();
    # Remove the header from the aligned sequence
    $alignedSequence =~ s/.*?\n//;
    # Remove all return characters, so it's just the aligned sequence
    $alignedSequence =~ s/\n//g;
    # Now run through the sequence pushing the consScore onto the mappedConsScore
    # array if it's an actual residue not a '-'
    my $i = 0;
    my @alignedResidues = split(//,$alignedSequence);
    foreach my $alignedResidue (@alignedResidues)
    {
        if($alignedResidue ne "-")
        {
            push @mappedConsScores, $consScores[$i];
        }
        $i++;
    }
    return(@mappedConsScores);
}

#*************************************************************************
sub ExtractPDBCode
{
    my ($pdbfile) = @_;

    $pdbfile =~ s/.*\///;       # Remove the path
    $pdbfile =~ s/\..*$//;      # Remove the extension
    $pdbfile =~ /(\d\w{3})/;    # Match the PDB code
    return($1);
}


#*************************************************************************
sub StoreConsCache
{
    my($id, $threshold, $nseq, @mappedConsScores) = @_;

    # Create the cache directory if needed
    if(! -e $config::consCacheDir)
    {
        `mkdir $config::consCacheDir`;
        if(! -e $config::consCacheDir)
        {
            ErrorDie("Cannot create cache directory: $config::consCacheDir");
        }
        `chmod a+wxt $config::consCacheDir`;
    }
    my $fnm = "$config::consCacheDir/$id";
    if(open(my $CACHE, ">$fnm"))
    {
        print $CACHE "$threshold\n";
        print $CACHE "$nseq\n";
        foreach my $value (@mappedConsScores)
        {
            print $CACHE "$value\n";
        }
        close $CACHE;
    }
    else
    {
        ErrorDie("Cannot write cache file: $fnm");
    }
}

#*************************************************************************
sub CheckConsCache
{
    my($id) = @_;
    my $fnm = "$config::consCacheDir/$id";
    my $threshold = (-1);
    my $nseq      = 0;
    my @mappedConsScores = ();

    if(-e $fnm)
    {
        if(open(my $CACHE, $fnm))
        {
            $threshold = <$CACHE>;
            chomp $threshold;
            $nseq = <$CACHE>;
            chomp $nseq;
            while(<$CACHE>)
            {
                chomp;
                push @mappedConsScores, $_;
            }
            close $CACHE;
        }
    }
    return($threshold, $nseq, @mappedConsScores);
}


#*************************************************************************
sub ErrorDie
{
    my($msg) = @_;

    SAAP::PrintJsonError("Impact", $msg);
    exit 1;
}

#*************************************************************************
sub UsageDie
{
    print STDERR <<__EOF;

impact.pl V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin
Usage: impact.pl [-v] [-nocache] [-force] [-uniID=xxx] [-uniRes=xxx]
                 [chain]resnum[insert] newaa pdbfile

       (newaa maybe 3-letter or 1-letter code)

       -v       Verbose - prints progress
       -vv      More verbose
       -force   Force calculation even if results are cached
       -nocache Do not cache results
       -uniID   Specify UniProt ID rather than using PDBSWS
       -uniRes  Specify UniProt residue number rather than assume it
                is the same as the PDB residue number
    
Does ImPACT conservation calculations for the SAAP server.
       
__EOF
   exit 0;
}
