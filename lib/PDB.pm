package PDB;

use LWP::UserAgent;
use strict;

$PDB::URLtemplate  = "ftp://ftp.ebi.ac.uk/pub/databases/pdb/data/structures/all/pdb/pdb%s.ent.gz";
$PDB::gunzip       = "gunzip";

sub GrabPDB
{
    my($pdbcode, $file) = @_;

    # Create the URL and output filename
    my $url = CreateURL($pdbcode);

    # Grab the file
    my ($ok, $data) = GetFile($url);
    if(!$ok)
    {
        print STDERR "$data\n";
        print STDERR "URL: $url\n";
        exit 1;
    }

    $data = Uncompress($data);

    if(!WriteData($data, $file))
    {
        print STDERR "Can't write file: $file\n";
        exit 1;
    }
}


#*************************************************************************
# Writes the data to the specified file. If the filename is '-' or 
# 'stdout', then it writes to standard output
#
# 28.02.13 Original   By: ACRM
sub WriteData
{
    my($data, $file) = @_;

    if(($file eq "-") || ($file eq "stdout"))
    {
        print $data;
    }
    else
    {
        if(open(FILE, ">$file"))
        {
            print FILE $data;
            close FILE;
        }
        else
        {
            return 0;
        }
    }
    return(1);
}

#*************************************************************************
# Creates a URL from the PDB code and the global URL template
#
# 28.02.13 Original   By: ACRM
# 25.06.15 Added pdbml flag
# 28.04.16 Added mmcif flag
sub CreateURL
{
    my($pdb) = @_;

    $pdb = "\L$pdb" if($PDB::LowerCase);
    my $url = sprintf($PDB::URLtemplate, $pdb);

    return($url);
}

#*************************************************************************
# Uncompresses a compressed datafile using the command specified in the
# global $PDB::gunzip variable. Input is the compressed data and output is the
# uncompressed data. This version makes use of a temporary file since
# pipes seem unreliable with larger files.
#
# 01.07.13 Original   By: ACRM
sub Uncompress
{
    my($inData) = @_;
    my $outData = "";
    my $tfile  = "/tmp/grabpdb_$$" . time;
    my $tfileZ = $tfile . ".gz";

    if(open(my $fh, ">$tfileZ"))
    {
        print $fh $inData;
        close $fh;
        `cd /tmp; $PDB::gunzip $tfileZ`;
        if(open(my $fh, "$tfile"))
        {
            my @fileContent = <$fh>;
            $outData = join('', @fileContent);
        }
        else
        {
            print STDERR "Can't open temporary file for reading ($tfile). Data not uncompressed\n";
            $outData = $inData
        }
    }
    else
    {
        print STDERR "Can't open temporary file for writing ($tfileZ). Data not uncompressed\n";
        $outData = $inData
    }

    unlink $tfileZ;
    unlink $tfile;

    return($outData);
}


#*************************************************************************
# Grabs a file using the LWP package
# Returns two values: success (TRUE/FALSE) and the data (content if all 
# was OK, otherwise the error message)
#
# 28.02.13 Original   By: ACRM
sub GetFile
{
    my ($url) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent("grabpdb/0.1 ");
    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);
    # Check the outcome of the response
    if ($res->is_success) 
    {
        return(1, $res->content);
    }

    return(0, $res->status_line);
}


1;
