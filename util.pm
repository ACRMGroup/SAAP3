package util;
#*************************************************************************
#
#   Program:    abYmod
#   File:       util.pm
#   
#   Version:    V1.14
#   Date:       13.09.16
#   Function:   General perl utilities
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2013-2016
#   Author:     Dr. Andrew C. R. Martin
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
#   V1.0   19.09.13  Original
#   V1.1   10.01.14  Skipped
#   V1.2   13.02.14  Skipped
#   V1.3   13.02.14  Skipped
#   V1.4   24.04.14  Skipped
#   V1.5   15.07.14  Fully commented
#   V1.6   17.07.14  Scoring against specified mismatched residues in CDRs 
#   V1.7   17.07.14  Ranks the CDR templates based on similarity score
#   V1.8   21.07.14  Added support for using MODELLER
#   V1.9   22.07.14  MODELLER used for all mismatched loop lengths
#                    instead of just CDR-H3. 
#   V1.10  15.09.15  Skipped
#   V1.11  28.09.15  Added $useSystem parameter to RunCommand()
#   V1.12  01.10.15  Moved BuildPackage() in here
#   V1.13  02.11.15  Skipped
#   V1.14  13.09.16  Added check that executables are actually installed.
#                    Added utilities to check for library and include
#                    files
#
#*************************************************************************
use config;
use strict;

#*************************************************************************
# my ($filename, $stem) = util::BuildFileName($inFile, $dir, $ext)
# ----------------------------------------------------------------
# Input:   text  $inFile    Input filename (maybe with a path)
#          text  $dir       Required path
#          text  $ext       Required extension
# Returns  text  $filename  New filename
#          text  $stem      The filestem
#
# Builds a filename by discarding the path and extension from an input 
# filename and adding new path and extension
#
# For some odd reason /\..*?$/ doesn't properly do a non-greedy match -
# it matches from the first '.' instead of the last '.'. Consequently 
# the code to remove te extension has to do a greedy match on the first
# part of the string and substitute that for the whole thing
#
#  19.09.13  Original  By: ACRM
sub BuildFileName
{
    my($inFile, $dir, $ext) = @_;

    my $stem = $inFile;
    $stem =~ s/(.*)\..*?$/$1/;           # Remove extension
    $stem =~ s/.*\///;                   # Remove path

    chop $dir if($dir =~ /\/$/);         # Remove / from end of path
    $ext = ".$ext" if(!($ext =~ /^\./)); # Prepend . to extension if needed

    my $outFile = "$dir/$stem$ext";      # Construct filename

    return($outFile, $stem);
}


#*************************************************************************
#> $tmpDir = CreateTempDir($pName)
#  -------------------------------
#  Input:   string   $pName    Directory base name
#  Return:  string             Full created directory name
#
#  Create a temporary directory. The time is appended to the filestem
#  and this is placed in the directory named in $config::tmp
#
#  19.09.13  Original  By: ACRM
sub CreateTempDir
{
    my ($pName) = @_;
    my $tmpDir = $config::tmp . "/${pName}_$$" . "_" . time;
    $tmpDir =~ s/\/\//\//g; # Replace // with /
    `mkdir -p $tmpDir`;
    if(! -d $tmpDir)
    {
        return(undef);
    }
    return($tmpDir);
}

#*************************************************************************
# @files = GetFileList($dir, $type, $prepend)
# -------------------------------------------
# Input:   string   $dir      A directory path
#          string   $type     A file extension (or blank)
#          BOOL     $prepend  Prepend the directory path onto the filenames
# Returns: string[]           List of filenames
#
# This function gets a list of filenames from a directory which have the
# specified extension - strictly this is just text that the filename must
# contain - if it really must be an extension then it needs to end with a $
# (end of string marker).
# By default, the filenames are returned without the path information.
# If $prepend is set, then the path is prepended onto each filename
#
#  19.09.13  Original  By: ACRM
sub GetFileList
{
    my($dir, $type, $prepend) = @_;
    my @files = ();

    chop $dir if($dir =~ /\/$/);

    if(opendir(my $dh, $dir))
    {
        @files = grep(!/^\./, readdir($dh));
        if($type ne "")
        {
            @files = grep(/$type/, @files);
        }
        closedir($dh);
    }
    if($prepend)
    {
        foreach my $file (@files)
        {
            $file = "$dir/$file";
        }
    }
    return(sort(@files));
}

#*************************************************************************
#> BOOL FileNewer($testFile, $refFile)
#  -----------------------------------
#  Input:   string   $testFile   File of which to check date
#           string   $refFile    Reference file against which we compare
#  Returns: BOOL                 True if either file does not exist or
#                                if $testFile is newer than $refFile
#
#  Tests whether $testFile is newer than $refFile
#
#  19.09.13  Original  By: ACRM
sub FileNewer
{
    my($testFile, $refFile) = @_;

    return(1) if((! -e $testFile) || (! -e $refFile));

    my @stats;
    @stats = stat($testFile);
    my $testDate = $stats[9];
    @stats = stat($refFile);
    my $refDate = $stats[9];

    return((($testDate > $refDate)?1:0));
}


#*************************************************************************
#> void CheckAndDie($path, $isDir, $text)
#  --------------------------------------
#  Input:   string   $path   Path to a directory or file
#           BOOL     $isDir  $path is a directory
#           string   $text   Text message
#
#  Tests whether $path is a directory or file (depending on $isDir) and
#  if it isn't what it is supposed to be, prints a message including $text
#  and dies
#
#  19.09.13  Original  By: ACRM
sub CheckAndDie
{
    my($path, $isDir, $text) = @_;
    my $ok = 1;
    if($isDir)
    {
        $ok = 0 if(! -d $path);
    }
    else
    {
        $ok = 0 if(! -f $path);
    }

    if(!$ok)
    {
        Die("\nabYmod configuration/installation error: $text doesn't exist:\n   $path\n\n");
    }
}

#*************************************************************************
#> void Die($text)
#  ---------------
#  Input:   string   $text    Message to print
#
#  Prints a message and exits
#
#  19.09.13  Original  By: ACRM
sub Die
{
    my($text) = @_;
    print STDERR $text;
    exit 1;
}

#*************************************************************************
#> %hash = BuildTwoColumnHash(@array)
#  ----------------------------------
#  Input:   string[]   @array    An array of strings of the form 'X Y'
#  Returns: hash                 A hash where X is the key and Y the value
#
#  Builds a hash from an array containing strings with two columns. 
#  NOTE! - If items in the first column (X) are repeated, then the last occurrence
#          will be used as the stored value
#        - If the string contains more than two columns, then only the second
#          column will be stored (i.e. 'X Y Z' will use X as a key for Y and Z
#          will be discarded.
#
#
#  19.09.13  Original  By: ACRM
sub BuildTwoColumnHash
{
    my @records = @_;
    my %resultHash = ();
    foreach my $line (@records)
    {
        chomp $line;
        my @fields = split(/\s+/, $line);
        $resultHash{$fields[0]} = $fields[1];
    }
    return(%resultHash);
}

#*************************************************************************
#> ($chain, $resnum, $insert) = ParseResID($resid)
#  -----------------------------------------------
#  Input:   string   $resid    Residue identifier (e.g. L27A)
#  Returns: string   $chain    The chain label (or undef)
#           int      $resnum   The residue number (or undef)
#           string   $insert   The insert code (or undef)
#
#  Parse a residue identifier to extract the chain, residue number and
#  insert code
#
#  19.09.13  Original  By: ACRM
sub ParseResID
{
    my ($resid) = @_;

    if(!($resid =~ /([a-zA-Z]?)(\d+)([a-zA-Z]?)/))
    {
        return(undef, undef, undef);
    }
    return($1, $2, $3);
}

#*************************************************************************
#> BOOL resLE($res1, $res2)
#  ------------------------
#  Input:   string   $res1    First residue ID
#           string   $res2    Second residue ID
#  Return:  BOOL              Is $res1 <= $res2
#
#  Tests whether a residue ID is <= another residue ID
#
#  19.09.13  Original  By: ACRM
sub resLE
{
    my($res1, $res2) = @_;

    my @resA = ParseResID($res1);
    my @resB = ParseResID($res2);

    if($resA[0] eq $resB[0])         # Chain matches
    {
        if($resA[1] < $resB[1])      # ResNum1 less than ResNum2
        {
            return(1);
        }
        elsif($resA[1] == $resB[1])  # ResNum1 == ResNum2
        {
            if($resA[2] le $resB[2]) # Insert1 <= Insert2
            {
                return(1);
            }
        }
    }

    return(0);
}

#*************************************************************************
#> BOOL resGE($res1, $res2)
#  ------------------------
#  Input:   string   $res1    First residue ID
#           string   $res2    Second residue ID
#  Return:  BOOL              Is $res1 >= $res2
#
#  Tests whether a residue ID is >= another residue ID
#
#  19.09.13  Original  By: ACRM
sub resGE
{
    my($res1, $res2) = @_;

    my @resA = ParseResID($res1);
    my @resB = ParseResID($res2);

    if($resA[0] eq $resB[0])
    {
        if($resA[1] > $resB[1])
        {
            return(1);
        }
        elsif($resA[1] == $resB[1])
        {
            if($resA[2] ge $resB[2])
            {
                return(1);
            }
        }
    }

    return(0);
}


#*************************************************************************
#> $paddedId = PadResID($id)
#---------------------------
#  Input:   string    $id        Residue identifier (e.g. "L24A")
#  Returns: string    $paddedId  Padded residue ID (e.g.  "L  24A")
#
#  Pads a residue ID with spaces to a common format for sorting etc
#  The padded format is the same as the layout in PDB files
#
#  19.09.13  Original  By: ACRM
sub PadResID
{
    my ($id) = @_;

    my @parts = ParseResID($id);
    $id = sprintf("%1s%4d%1s", $parts[0], $parts[1], $parts[2]);
    return($id);
}


#*************************************************************************
#> BOOL inlist($item, @list)
#  -------------------------
#  Input:   string   $item    An item for which to search
#           string[] @list    An array
#  Return:  BOOL              Was $item in the array?
#
#  Tests whether an item appears in the array
#
#  19.09.13  Original  By: ACRM
sub inlist
{
    my($item, @list) = @_;
    foreach my $listItem (@list)
    {
        if($item eq $listItem)
        {
            return(1);
        }
    }
    return(0);
}

#*************************************************************************
# @textArray = ReadFileAsArray($inFile)
# -------------------------------------
# Input:   text   $inFile    A file name to be read
# Returns: text[]            An array of lines from the file
#
#  19.09.13  Original  By: ACRM
sub ReadFileAsArray
{
    my($inFile) = @_;
    my @contents = ();

    if(open(my $fp, $inFile))
    {
        while(<$fp>)
        {
            chomp;
            s/\r//;
            push @contents, $_;
        }
        close $fp;
    }
    return(@contents);
}


#*************************************************************************
#> void RunCommand($exe, $useSystem)
#  ---------------------------------
#  Input:   string  $exe    An excutable string
#
#  Runs a command
#  19.09.13  Original  By: ACRM
#  28.09.15  Now returns the output
#  30.09.15  Added $useSystem parameter (optional)
sub RunCommand
{
    my ($exe, $useSystem) = @_;
    my $result = '';

    print STDERR "$exe\n";
    if(defined($useSystem) && $useSystem)
    {
        system("$exe");
    }
    else
    {
        $result = `$exe`;
    }
    return($result);
}

#*************************************************************************
#> $dir = GetDir($file)
#  --------------------
#  Input:   string   $file    Full path to a file
#  Return:  string            The directory (path) element of the filename
#
#  19.09.13  Original  By: ACRM
sub GetDir
{
    my ($file) = @_;
    $file =~ /(.*\/)/;  
    my $dir = $1;
    return($dir);
}

#*************************************************************************
#> @canFiles = RemoveExcludedFiles(\@canFiles, \@exclList)
#  -------------------------------------------------------
# Input:   Ref-to-text[]  $aInFiles   Reference to array of filenames
#          Ref-to-text[]  @aExclList  Reference to array of files to exclude
# Returns: text[]                     Array of filenames
#
# This routine takes a reference to an array of filenames and builds
# a new array containing only those files that don't start with a
# string specified in the @aExclList. The path is stripped off the filenames
# before the comparison.
#
#  10.01.14   Original   By: ACRM
sub RemoveExcludedFiles
{
    my ($aInFiles, $aExclList) = @_;

    # If exclusion list is empty just return the full array
    if(!(@$aExclList))
    {
        return(@$aInFiles);
    }

    # Otherwise build a list of output files to keep
    my @outFiles = ();

    foreach my $file (@$aInFiles)
    {
        my $flagged = 0;
        my $basename = $file;
        $basename =~ s/^.*\///; # Strip the path
        foreach my $excl (@$aExclList)
        {
            if ($basename =~ /^$excl/)
            {
                $flagged = 1;
                last;
            }
        }
        if(!$flagged)
        {
            push @outFiles, $file;
        }
    }

    return(@outFiles);
}

#*************************************************************************
#> @result = sortArrayByArray($aTarget, $aKey)
#  -------------------------------------------
#  Input:   \data[]  $aTarget  Reference to array to be sorted
#           \data[]  $aKey     Reference to array on which to sort
#  Returns: data[]   @result   Sorted version of $aTarget
#
#  Sorts the $aTarget array based on the values in the $aKey array
#
#  17.07.14 Original   By: ACRM
sub sortArrayByArray
{
    my ($aTarget, $aKey) = @_;
    my @idx = sort {$$aKey[$a] <=> $$aKey[$b]} 0 .. $#$aKey;
    my @target = @$aTarget[@idx];
    return(@target);
}

#*************************************************************************
#> %mdm = ReadMDM($file)
#  ---------------------
#  Input:   string     $file    MDM file
#  Return:  hash{}{}   %mdm     Hash containing MDM scores indexed by
#                               1-letter codes
#
#  Reads a mutation similarity matrix from a file. (e.g. BLOSUM or
#  Dayhoff matrix). Returns a hash indexed by the two amino acids
#
#  17.07.14  Original   By: ACRM
sub ReadMDM
{
    my($file) = @_;

    my %mdm = ();

    if(open(my $fp, $file))
    {
        my @columns = ();
        my $firstRow = 1;
        while(<$fp>)
        {
            chomp;
            s/\#.*//;           # Remove comments
            s/^\s+//;           # Remove leading whitespace
            s/\s+$//;           # Remove trailing whitespace
            if(length)          # If there is something left
            {
                if($firstRow)
                {
                    @columns = split;
                    $firstRow = 0;
                }
                else
                {
                    my @data = split;
                    my $rowRes = shift @data;
                    foreach my $colRes (@columns)
                    {
                        $mdm{$rowRes}{$colRes} = shift @data;
                    }
                }
            }
        }
        close $fp;
    }
    else
    {
        return(undef);
    }

    return(%mdm);
}


#*************************************************************************
#> $one = throne($three)
#  ---------------------
#  Input:   string  $three   3- or 1-letter code for an amino acid
#  Return:  string           1-letter code for an amino acid
#
#  17.07.14 Original   By: ACRM
sub throne
{
    my($inAA) = @_;
    my $outAA = "X";

    $inAA = "\U$inAA";

    if(length($inAA) == 1)
    {
        $outAA = $inAA;
    }
    elsif(defined($util::throneData{$inAA}))
    {
        $outAA = $util::throneData{$inAA};
    }

    return($outAA);
}

#*************************************************************************
# 3- to 1-letter conversion
%util::throneData = 
    ('ALA' => 'A',
     'CYS' => 'C',
     'ASP' => 'D',
     'GLU' => 'E',
     'PHE' => 'F',
     'GLY' => 'G',
     'HIS' => 'H',
     'ILE' => 'I',
     'LYS' => 'K',
     'LEU' => 'L',
     'MET' => 'M',
     'ASN' => 'N',
     'PRO' => 'P',
     'GLN' => 'Q',
     'ARG' => 'R',
     'SER' => 'S',
     'THR' => 'T',
     'VAL' => 'V',
     'TRP' => 'W',
     'TYR' => 'Y');


#*************************************************************************
#> ThroneSeqFileContents($aSeqFileContents)
#  ----------------------------------------
#  I/O:   \string[]  $aSeqFileContents   Sequence file contents
#
#  Runs through the sequence file and converts all amino acid names to
#  1-letter code
#
#  17.07.14  Original   By: ACRM
sub ThroneSeqFileContents
{
    my ($aSeqFileContents) = @_;

    for(my $count=0; $count<scalar(@$aSeqFileContents); $count++)
    {
        my $line = $$aSeqFileContents[$count];
        my @fields = split(/\s+/, $line);
        $fields[1] = util::throne($fields[1]);
        $$aSeqFileContents[$count] = "$fields[0] $fields[1]";
    }
}

#*************************************************************************
#> void ThroneSequenceHash($hSeqHash)
#  ----------------------------------
#  I/O:   \hash  $hSeqHash    Reference to hash containing sequence data
#
#  Takes a reference to a sequence hash and changes all the residues to
#  use 1-letter code rather than 3-letter code. Mixed case and 1-letter
#  code in the input is all handled
#
#
#  19.09.13  Original  By: ACRM
#  17.07.14  Changed to use new util::throne() function
sub ThroneSequenceHash
{
    my ($hSeqHash) = @_;

    foreach my $key (keys %$hSeqHash)
    {
        $$hSeqHash{$key} = util::throne($$hSeqHash{$key});
    }
}

#*************************************************************************
#> void DEBUG($string)
#  -------------------
#  Input:   string   $string   A text string
#
#  Prints the string if $::debug is defined
#
#  17.07.14  Original   By: ACRM
sub DEBUG
{
    my($string) = @_;

    if(defined($::debug))
    {
        print STDERR "DEBUG: $string\n";
    }
}

#*************************************************************************
#> %sequence = GetSequenceHash($file, $isId, $chain)
#  -------------------------------------------------
#  Input:   string  $file     Filename or PDB ID
#           BOOL    $isId     $file is a PDB ID not a filename
#           string  $chain    Chain label (or null string)
#  Return:  hash              1-letter code sequence keyed by residue ID
#
#  Reads a sequence file. If $isId is set then $file is a PDB ID and
#  we work out the sequence filename. Results are returned as a hash
#  which is keyed by the residue ID. If $chain is set, then only the
#  specified chain is returned.
#  3-letter code is converted to 1-letter code
#
#  18.07.14 Original  By: ACRM
sub GetSequenceHash
{
    my($file, $isId, $chain) = @_;

    my %sequence = ();
    my $seqFilename = $file;

    if($isId)
    {
        my $stem;
        ($seqFilename, $stem) = util::BuildFileName($file, 
                                                    $config::abseqlib,
                                                    $config::seqExt);
    }
    my @seqArray = util::ReadFileAsArray($seqFilename);
    if($chain ne '')
    {
        @seqArray = grep(/^$chain/, @seqArray);
    }
    my %sequence = util::BuildTwoColumnHash(@seqArray);
    util::ThroneSequenceHash(\%sequence);

    return(%sequence);
}

#*************************************************************************
#> void FindUniqueLabels($hUniqueLabels, $hSeqHash)
#  ------------------------------------------------
#  I/O:     \hash   $hUniqueLabels   Reference to hash in which we store
#                                    unique residue labels (padded)
#  Input:   \hash   $hSeqHash        Reference to sequence hash
#
#  Adds to a hash of unique residue labels. The labels are padded with
#  whitespace before being added
#
#  19.07.14  Original   By: ACRM
sub FindUniqueLabels
{
    my($hUniqueLabels, $hSeqHash) = @_;
    foreach my $label (keys %$hSeqHash)
    {
        $$hUniqueLabels{util::PadResID($label)} = 1;
    }
}



#*************************************************************************
#> %sequence = GetPDBSequenceHash($file, $chain)
#  ----------------------------------------------------
#  Input:   string  $file     Filename or PDB ID
#           string  $chain    Chain label (or null string)
#  Return:  hash              1-letter code sequence keyed by residue ID
#
#  Reads the sequence from a PDB file. If $isId is set then $file is a 
#  PDB ID and
#  we work out the sequence filename. Results are returned as a hash
#  which is keyed by the residue ID. If $chain is set, then only the
#  specified chain is returned.
#  3-letter code is converted to 1-letter code
#
#  21.07.14 Original  By: ACRM
sub GetPDBSequenceHash
{
    my($file, $chains) = @_;

    my %sequence = ();
    my $seqFilename = $file;

    if(open(my $fp, $file))
    {
        while(my $line = <$fp>)
        {
            my $atom = substr($line, 12, 4);
            if($atom eq ' CA ')
            {
                my $thisChain = substr($line, 21, 1);
                my $resnum    = substr($line, 22, 4);
                my $insert    = substr($line, 26, 1);
                $thisChain  =~ s/\s//g;
                $resnum     =~ s/\s//g;
                $insert     =~ s/\s//g;
                if(($chains eq '') || (index($chains, $thisChain) >= 0))
                {
                    my $id = $thisChain . $resnum . $insert;
                    my $resnam = substr($line, 17, 3);
                    $sequence{$id} = util::throne($resnam);
                }
            }
        }
        close $fp;
    }
    return(%sequence);
}

#*************************************************************************
#> ($sequence, %lookup, $loopupNoInserts) = 
#         GenerateSequence($hUniqueLabels, $chain, $hSeqHash)
#  ----------------------------------------------------------
#  Input:   \hash  $hUniqueLabels   Reference to hash of unique labels
#                                   (whitespace padded)
#           string $chain           Chain of interest
#           \hash  $hSeqHash        Sequence hash - keyed by label
#                                   (unpadded)
#  Return:  string $sequence        Extracted sequence
#           hash   %lookup          Key: residue label, value: sequential
#                                   position in sequence
#           hash   %lookupNoInserts Key: residue label, value: sequential
#                                   position in sequence
#
#  19.07.14 Original   By: ACRM
sub GenerateSequence
{
    my($hUniqueLabels, $chain, $hSeqHash) = @_;

    my $sequence        = "";
    my %lookup          = ();
    my %lookupNoInserts = ();
    my $count           = 0;
    my $countNoInserts  = 0;

    foreach my $label (sort keys %$hUniqueLabels)
    {
        if(substr($label,0,1) eq $chain)
        {
            $count++;
            $label =~ s/\s//g;
            if(defined($$hSeqHash{$label}))
            {
                $countNoInserts++;
                $sequence .= $$hSeqHash{$label};
                $lookup{$label}          = $count;
                $lookupNoInserts{$label} = $countNoInserts;
            }
            else
            {
                $sequence .= '-';
                $lookup{$label} = (-1);
                $lookupNoInserts{$label} = (-1);
            }
        }
    }

    return($sequence, \%lookup, \%lookupNoInserts);
}

#*************************************************************************
#>void PrettyPrint($fp, $sequence, $width, $append)
# -------------------------------------------------
# Input:   FILE   $fp         Reference to file handle
#          string $sequence   Sequence to be printed
#          int    $width      Width to print
#          string $append     String to be appended to the sequence
#
# Prints a string breaking it up into $width chunks. The $append string
# is appended to the main string before this is done.
#
# 21.07.14 Original   By: ACRM
sub PrettyPrint
{
    my($fp, $sequence, $width, $append) = @_;
    $sequence .= $append;

    while($sequence ne '')
    {
        print $fp substr($sequence, 0, $width) . "\n";
        $sequence = substr($sequence, $width);
    }
}


#*************************************************************************
#> void BuildPackage($package, $subdir, $aExe, $binDir, $dataDir, 
#                    $dataDest, $postBuild)
#  -------------------------------------------------------------------------
#  Input:   string  $package    The gzipped tar file of the package
#           string  $subdir     Subdirectory of the unpacked package
#                               containing source code
#           string  $aAxe       Reference to array of exectuables generated
#           string  $binDir     Destination binary directory
#           string  $dataDir    Data directory in unpacked package
#           string  $dataDest   Destination data directory
#
#  Builds and installs a C package
#
#  19.09.13  Original  By: ACRM
#  25.09.15  Now takes a reference to an array of executables
#  01.10.15  Makes the destination directories if they don't exist
#  02.10.15  Moved into util.pm
#  13.09.16  Added checks that install of executable files has 
#            actually worked
#  24.03.17  Added $postBuild
sub BuildPackage
{
    my ($package, $subdir, $aExe, $binDir, $dataDir, $dataDest, $postBuild) = @_;

    # See if we need to do this - i.e. we don't have the files
    # already
    my $needsToRun = 0;
    foreach my $exe (@$$aExe)
    {
        if(! -x "$binDir/$exe")
        {
            $needsToRun = 1;
            last;
        }
    }
    if(($dataDir ne '') && ( ! -d $dataDest))
    {
        $needsToRun = 1;
    }

    if($needsToRun)
    {
        util::RunCommand("tar -zxvf $package");
        my $packageDir = $package;
        $packageDir =~ s/.*\///;
        $packageDir =~ s/\.tgz//;
        util::RunCommand("cd $packageDir/$subdir; make");
        foreach my $exe (@$$aExe)
        {
            util::RunCommand("mkdir -p $binDir") if(! -d $binDir);
            util::RunCommand("cp $packageDir/$subdir/$exe $binDir");

            if(! -e "$binDir/$exe")
            {
                Die("\nabYmod installation error: $binDir/$exe not created.\n       Compilation in $packageDir probably failed\n\n");
            }
        }
        if($dataDir ne "")
        {
            util::RunCommand("mkdir -p $dataDest") if(! -d $dataDest);
            util::RunCommand("cp -R $packageDir/$dataDir/* $dataDest");
        }
        if($postBuild ne "")
        {
            util::RunCommand($postBuild);
        }
        `rm -rf $packageDir`;
    }
    else
    {
        print STDERR "*** Info: Skipped installation of $package - already installed\n";
    }
}


#*************************************************************************
#> BOOL CheckLibrary(@libs)
#  ------------------------
#  Input:    @libs   Array of library names to search for
#  Returns:  BOOL    Found?
#
#  Checks the library paths to see if a specified library exists
#
#  13.09.16 Original   By: ACRM
sub CheckLibrary
{
    my(@files) = @_;

    my @dirs = qw(/usr/lib /usr/lib64 /usr/local/lib /usr/local/lib64);

    return(CheckFilesExistInDirs(\@files, \@dirs));
}


#*************************************************************************
#> BOOL CheckInclude(@incs)
#  ------------------------
#  Input:    @libs   Array of include file names to search for
#  Returns:  BOOL    Found?
#
#  Checks the system include paths to see if a specified library exists
#
#  13.09.16 Original   By: ACRM
sub CheckInclude
{
    my(@files) = @_;

    my @dirs = qw(/usr/include /usr/local/include);

    return(CheckFilesExistInDirs(\@files, \@dirs));
}


#*************************************************************************
# BOOL CheckFilesExistInDirs(\@FilesToCheck, \@DirsToSearch)
# ----------------------------------------------------------
# Input:    \@FilesToCheck  Ref to list of files we are looking for
#           \@DirsToSearch  Ref to list of directories to search
#
# Checks if the specified files exist in any of the specified directories.
# These are searched recursively.
#
#  13.09.16 Original   By: ACRM
sub CheckFilesExistInDirs
{
    my($aFiles, $aDirs) = @_;

    foreach my $inFile (@$aFiles)
    {
        my $found = 0;

        foreach my $location (@$aDirs)
        {
            if(!$found)
            {
                my @fileList = GetRecursiveFileList($location);

                foreach my $file (@fileList)
                {
                    
                    if($file =~ /$inFile$/)
                    {
                        $found = 1;
                        last;
                    }
                }
            }
        }

        if(!$found)
        {
            return(0);
        }
    }

    return(1);

}


#*************************************************************************
#> @files = GetRecursiveFileList($location)
#  ----------------------------------------
#  Input:    $location   Top level directory
#  Returns:              List of full file paths in that directory
#
#  Builds a list of all files below a given direcotory - uses 'ls -R' to
#  obtain a recursive list
#
#  13.09.16 Original   By: ACRM
sub GetRecursiveFileList
{
    my($location) = @_;
    my $stem = '';
    my @files = ();
    my $dirTree = `\\ls -R $location 2>/dev/null`;
    my @records = split(/\n/, $dirTree);
    foreach my $record (@records)
    {
        $record =~ s/\s+$//;    # Remove trailing whitespace
        if(length($record))
        {
            if($record =~ /(.*)\:/)
            {
                $stem = $1 . '/';
            }
            else
            {
                push @files, "$stem$record";
            }
        }
    }

    return(@files);
}

1;


