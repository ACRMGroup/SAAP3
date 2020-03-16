package FOSTA;
#*************************************************************************
#
#   Program:    
#   File:       
#   
#   Version:    
#   Date:       
#   Function:   
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
#   Web services-based routines to access FOSTA and UniProt FASTA files
#
#*************************************************************************
#
#   Usage:
#   ======
#   ($sequences, $nseq) = GetFOSTASequences($swissprotID);
#      Extracts a set of sequences in FASTA format for FEPs for the
#      given SwissProt ID
#   @ids = GetFOSTA($swissprotID);
#      Extracts a set of SwissProt IDs for the FEPs of a given 
#      SwissProt ID - web services access to FOSTA
#   $sequence = GetFASTA($swissprotID);
#      Extracts the sequence for a given SwissProt ID - web services
#      access to Uniprot
#
#*************************************************************************
#
#   Revision History:
#   =================
#
#*************************************************************************
use strict;
use WEB;
use UNIPROT;

#-------------------------------------------------------------------------
my $fostaURL = "http://www.bioinf.org.uk/servers/fosta/cgi/fosta_XML.cgi?id=";
my $uniprotURL = "http://www.uniprot.org/uniprot/%s.fasta";

#-------------------------------------------------------------------------
# Error codes
my $ERROR_NOROOTID  = -1;
my $ERROR_NOFEPS    = -2;
my $ERROR_NOCONNECT = -3;
my $SUCCESS         = 0;
#-------------------------------------------------------------------------
sub GetFOSTASequences
{
    my ($id) = @_;

    # Get the list of FEPs from FOSTA
    my ($error, @feps) = GetFOSTA($id);

    if($error == $ERROR_NOROOTID)
    {
        return("ID $id was not a member of a FOSTA family", $error);
    }
    elsif($error == $ERROR_NOFEPS)
    {
        return("No FEPs found for ID $id", $error);
    }
    elsif($error == $ERROR_NOCONNECT)
    {
        return("Connection to FOSTA Failed",$error);
    }

    # Extract each of the sequences in FASTA format and assemble
    my $allFasta = "";
    my $nseq = 0;
    foreach my $fep (@feps)
    {
        my $fasta = UNIPROT::GetFASTA($fep);
        $allFasta .= $fasta;
        $nseq++;
    }

    return($allFasta, $nseq);
}

#-------------------------------------------------------------------------
# Returns (error, @feps)
# error = ERROR_NOROOTID  - No root ID extracted
#         ERROR_NOFEPS    - No FEPs data extracted
#         ERROR_NOCONNECT - REST connection failed
#         SUCCESS         - Success
sub GetFOSTA
{
    my ($id) = @_;

    my @fepList = ();

    # Grab the XML data from the FOSTA web service
    my $url = $fostaURL . $id;
    my $ua = WEB::CreateUserAgent("");
    my $req = WEB::CreateGetRequest($url);
    my $content = WEB::GetContent($ua, $req);
    if($content eq "")
    {
        return(-3,@fepList);
    }

    # Extract the root ID
    $content =~ /\<root\s+(.*?)\>/;              # <root ***** >
    my $rootAttributes = $1;
    $rootAttributes =~ /id\s*=\s*[\'\"](.*?)[\'\"]/; # id="*****"
    my $rootID = $1;
    if($rootID eq "")
    {
        return(-1,@fepList);
    }

    # Add the root ID to our FEP list
    push @fepList, $rootID;

    # Extract the content of the FEPs tag
    $content =~ s/\n//g;
    $content =~ /\<feps.*?\>(.*?)\<\/feps\>/;    # <feps> ***** </feps>
    my $fepsXML = $1;
    if($fepsXML eq "")
    {
        return(-2,@fepList);
    }

    # Replace the returns and then split into an array of <fep> entries
    $fepsXML =~ s/\<\/fep\>/\<\/fep\>\n/g;
    my @fepsEntries = split(/\n/, $fepsXML);

    # Run through the array extracting the attribues and the identifier of
    # each FEP
    foreach my $fepEntry (@fepsEntries)
    {
        # <fep *****>*****</fep>
        if($fepEntry =~ /\<fep\s+(.*?)\>(.*)\<\/fep\>/)
        {
            my $fepAttributes = $1;
            my $fepID = $2;

            # If it's not flagged as unreliable or as a fragment then 
            # add it to our list of FEPs
            if((GetAttribute($fepAttributes, "unreliable") eq "f") &&
               (GetAttribute($fepAttributes, "fragment") eq "f"))
            {
                # Add this FEP to our list
                push @fepList, $fepID;
            }
        }
    }

    # Return the list of FEPs
    return(0,@fepList);
}


#-------------------------------------------------------------------------
sub GetAttribute
{
    my($attributes, $keyAttribute) = @_;

    $attributes =~ /$keyAttribute\s*=\s*["'](.*?)["']/;
    return($1);
}


1;
