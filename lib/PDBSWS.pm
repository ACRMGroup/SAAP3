package PDBSWS;
#*************************************************************************
#
#   Program:    
#   File:       PDBSWS.pm
#   
#   Version:    V1.0
#   Date:       01.12.11
#   Function:   Access PDBSWS from Perl
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2011
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
#   and used freely providing this header is retained
#
#*************************************************************************
#
#   Description:
#   ============
#   Web services-based routines to access PDBSWS
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
#   V1.0   01.12.11  Original   By: ACRM
#
#*************************************************************************
use strict;
use WEB;

#-------------------------------------------------------------------------
my $pdbswsURL = "http://www.bioinf.org.uk/servers/pdbsws/query.cgi?plain=1&qtype=";
#&qtype=ttt&id=iii&chain=ccc&res=rrr

#-------------------------------------------------------------------------
#>sub PDBQuery($id, $chain, $res)
# -------------------------------
# Input:   string  $id     PDB identifier
#          string  $chain  PDB chain label (may be blank)
#          string  $res    Residue number (may contain an insert code)
#                          May be a blank string
# Returns: hash            Hash of results
#
# Query PDBSWS by PDB identifier.
#
# The results have keys and content as described at 
# http://www.bioinf.org.uk/pdbsws/cgi.html
# On error, a key 'ERROR' is set describing the error
#
# This returns the longest entry or, if tied, the alphabetically earlier
# PDB code/chain
#
# 01.12.11 Original   By: ACRM                        
sub PDBQuery
{
    my ($id, $chain, $res) = @_;

    # Grab the FASTA sequence from the UniProt web service
    my $url = $pdbswsURL . "pdb&id=$id";
    if($chain ne "")
    {
        $url .= "&chain=$chain";
    }
    if($res ne "")
    {
        $res =~ s/^[A-Za-z]+//;  # Remove starting letters
        $url .= "&res=$res";
    }
    my $ua = WEB::CreateUserAgent("");
    my $req = WEB::CreateGetRequest($url);
    my $content = WEB::GetContent($ua, $req);

    if($content eq "")
    {
        my %results;
        $results{'ERROR'} = "PDB code ($id) not found in PDBSWS (PDB-to-UniProt mapping)";
        return %results;
    }

    # Create a hash containing the results
    my %results = BuildHash($content);

    return(%results);
}


#-------------------------------------------------------------------------
#>sub IDQuery($id, $res)
# ----------------------
# Input:   string  $id     UniProt identifier (XXXX_XXXX)
#          string  $res    Residue number - May be a blank string
# Returns: hash            Hash of results
#
# Query PDBSWS by UniProt identifier.
#
# The results have keys and content as described at 
# http://www.bioinf.org.uk/pdbsws/cgi.html
# On error, a key 'ERROR' is set describing the error
#
# This returns the longest entry or, if tied, the alphabetically earlier
# PDB code/chain
#
# 01.12.11 Original   By: ACRM                        
sub IDQuery
{
    my ($id, $res) = @_;

    # Grab the FASTA sequence from the UniProt web service
    my $url = $pdbswsURL . "id&id=$id";
    if($res ne "")
    {
        $res =~ s/[A-Za-z]//g;  # Remove any letters
        $url .= "&res=$res";
    }
    my $ua = WEB::CreateUserAgent("");
    my $req = WEB::CreateGetRequest($url);
    my $content = WEB::GetContent($ua, $req);

    if($content eq "")
    {
        my %results = ();
        $results{'ERROR'} = "UniProt ID ($id) not found in PDBSWS so cannot map to structure";
        return %results;
    }

    # Create a hash containing the results
    my %results = BuildHash($content);

    return(%results);
}

#-------------------------------------------------------------------------
#>sub ACQuery($id, $res)
# ----------------------
# Input:   string  $id     UniProt accession (e.g. P12345)
#          string  $res    Residue number - May be a blank string
# Returns: hash            Hash of results
#
# Query PDBSWS by UniProt accession.
#
# The results have keys and content as described at 
# http://www.bioinf.org.uk/pdbsws/cgi.html
# On error, a key 'ERROR' is set describing the error
#
# This returns the longest entry or, if tied, the alphabetically earlier
# PDB code/chain
#
# 01.12.11 Original   By: ACRM                        
sub ACQuery
{
    my ($id, $res) = @_;

    # Grab the FASTA sequence from the UniProt web service
    my $url = $pdbswsURL . "ac&id=$id";
    if($res ne "")
    {
        $res =~ s/[A-Za-z]//g;  # Remove any letters
        $url .= "&res=$res";
    }
    my $ua = WEB::CreateUserAgent("");
    my $req = WEB::CreateGetRequest($url);
    my $content = WEB::GetContent($ua, $req);

    if($content eq "")
    {
        my %results = ();
        $results{'ERROR'} = "UniProt AC ($id) not found in PDBSWS so cannot map to structure";
        return %results;
    }

    # Create a hash containing the results
    my %results = BuildHash($content);

    return(%results);
}

#-------------------------------------------------------------------------
#>sub ACQueryAll($id, $res)
# -------------------------
# Input:   string  $id     UniProt identifier (XXXX_XXXX)
#          string  $res    Residue number - May be a blank string
# Returns: array-of-hashes Array of hashes of results
#
# Query by UniProt AC, but return all results
#
# The results are an array of hashes which have keys and content 
# as described at  
# http://www.bioinf.org.uk/pdbsws/cgi.html
# On error, a key 'ERROR' is set describing the error
#
# 01.12.11 Original   By: ACRM                        
sub ACQueryAll
{
    my ($id, $res) = @_;

    # Grab the FASTA sequence from the UniProt web service
    my $url = $pdbswsURL . "ac&id=$id";
    if($res ne "")
    {
        $res =~ s/[A-Za-z]//g;  # Remove any letters
        $url .= "&res=$res";
    }
    my $ua = WEB::CreateUserAgent("");
    my $req = WEB::CreateGetRequest($url);
    my $content = WEB::GetContent($ua, $req);

    if($content eq "")
    {
        my %results = ();
        $results{'ERROR'} = "";
        if($res ne "")
        {
            $results{'ERROR'} = "Residue $res from ";
        }
        $results{'ERROR'} .= "SwissProt AC ($id) did not map to any PDB files in PDBSWS so structure is unknown";
        return %results;
    }

    # Create a hash containing the results
    my @results = BuildArrayHash($content);

    return(@results);
}

#-------------------------------------------------------------------------
#>sub BuildArrayHash($content)
# ----------------------------
# Input:   string  $content  key:value pairs (separated by \n)
# Returns: hash              Hash of key:value pairs
#
# This constructs an array of hashes containing the full result set
# of results that have been returned by the web service. 
#
# Not intended to be called by the end user
#
# 01.12.11 Original   By: ACRM                        
sub BuildArrayHash
{
    my($content) = @_;
    my @results = ();
    my $entryCount = 0;

    my @records = split(/\n/, $content);
    foreach my $record (@records)
    {
        my @fields = split(/:\s+/, $record);
        if($fields[0] eq "//")
        {
            $entryCount++;
        }
        else
        {
            $results[$entryCount]{$fields[0]} = $fields[1];
        }
    }

    return(@results);
}

#-------------------------------------------------------------------------
#>sub BuildArrayHash($content)
# ----------------------------
# Input:   string  $content  key:value pairs (separated by \n)
# Returns: hash              Hash of key:value pairs
#
# This constructs a hash containing the 'best' result that has been 
# returned by the web service. It selects the longest entry or, if tied, 
# the alphabetically earlier PDB code/chain. 
#
# Not intended to be called by the end user
#
# 01.12.11 Original   By: ACRM                        
sub BuildHash
{
    my($content) = @_;

    my @allResults = BuildArrayHash($content);
    my $entryCount = int(@allResults);

    # Run through looking for the longest one
    my $bestLength = 0;
    my $bestEntry  = 0;
    for(my $i=0; $i<$entryCount; $i++)
    {
        # If the match is longer then use this instead
        my $len = $allResults[$i]{'STOP'} - $allResults[$i]{'START'};
        if($len > $bestLength)
        {
            $bestLength = $len;
            $bestEntry  = $i;
        }
        elsif($len == $bestLength)
        {
            # If the match is the same length, then use it if the PDB code
            # is alphabetically earlier, or if the PDB code is the same
            # but the chain name is earlier
            if($allResults[$i]{'PDB'} lt $allResults[$bestEntry]{'PDB'})
            {
                $bestEntry = $i;
            }
            elsif($allResults[$i]{'PDB'} eq $allResults[$bestEntry]{'PDB'})
            {
                if($allResults[$i]{'CHAIN'} lt $allResults[$bestEntry]{'CHAIN'})
                {
                    $bestEntry = $i;
                }
            }
        }
    }

    # Now take another pass through and see if the best chain was a non-zero length
    # match, but there were any with length 0 as these are most likely full chains
    if($bestLength > 0)         # Current match is non-zero length
    {
        for(my $i=0; $i<$entryCount; $i++)
        {
            # If this one has length zero
            my $len = $allResults[$i]{'STOP'} - $allResults[$i]{'START'};
            if($len == 0)
            {
                # We haven't already replaced with length zero so do so and set
                # $bestLength to zero to indicate that we've done the replacement
                if($bestLength > 0)
                {
                    $bestEntry  = $i;
                    $bestLength = 0;
                }
                else
                {
                    # We've replaced already so replace on alphabetically earlier
                    # or if the PDB code is the same but the chain name is earlier
                    if($allResults[$i]{'PDB'} lt $allResults[$bestEntry]{'PDB'})
                    {
                        $bestEntry = $i;
                    }
                    elsif($allResults[$i]{'PDB'} eq $allResults[$bestEntry]{'PDB'})
                    {
                        if($allResults[$i]{'CHAIN'} lt $allResults[$bestEntry]{'CHAIN'})
                        {
                            $bestEntry = $i;
                        }
                    }
                }
            }
        }
    }

    return(%{$allResults[$bestEntry]});
}

1;
