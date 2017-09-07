package UNIPROT;
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
#   $sequence = GetFASTAWeb($swissprotID);
#      Extracts the sequence for a given SwissProt ID - web services
#      access to Uniprot
#
#   CONFIG:
#   =======
#   Requires a config.pm module which specifies...
#     $LocalSwissProt - 1: use local files, 2: use web
#   If using local files, the following must be specified
#     $swissprot      - SwissProt file if using local files
#     $sprotCacheDir  - Directory for SwissProt index
#     $sprotIndex     - Index file (full path)
#     $getsprot       - getsprot indexing program
#     $indexsprot     - SwissProt indexing program
#
#*************************************************************************
#
#   Revision History:
#   =================
#
#*************************************************************************
use strict;
use config;
use WEB;

#-------------------------------------------------------------------------
my $uniprotURLfastaAC = "http://www.uniprot.org/uniprot/%s.fasta";
my $uniprotURLsprotAC = "http://www.uniprot.org/uniprot/%s.txt";
my $uniprotURLfastaID = "http://www.uniprot.org/uniprot/?query=%s&column=id&format=fasta";
my $uniprotURLsprotID = "http://www.uniprot.org/uniprot/?query=%s&column=id&format=txt";

#-------------------------------------------------------------------------
sub GetFASTA
{
    my ($id) = @_;
    if($config::LocalSwissProt)
    {
        # Index SwissProt if necessary
        IndexSwissProt($config::swissprot, $config::sprotCacheDir, $config::sprotIndex);
        return(GetFASTALocal($id));
    }
    return(GetFASTAWeb($id));
}

#-------------------------------------------------------------------------
sub GetFASTALocal
{
    my ($id) = @_;

    my $result = `$config::getsprot -f $config::swissprot $config::sprotIndex $id`;
    $result =~ s/[ \t]//g;
    return($result);
}

#-------------------------------------------------------------------------
sub GetFASTAWeb
{
    my ($id) = @_;
    my $url;

    # Grab the FASTA sequence from the UniProt web service
    if($id =~ /\_/)
    {
        $url = sprintf($uniprotURLfastaID, $id);
    }
    else
    {
        $url = sprintf($uniprotURLfastaAC, $id);
    }
    my $ua = WEB::CreateUserAgent("");
    my $req = WEB::CreateGetRequest($url);
    my $content = WEB::GetContent($ua, $req);

    return($content);
}


# Indexes SwissProt if the index doesn't exist, or SwissProt has been updated
# TODO: Move this into config and also call it from the FOSTA code
sub IndexSwissProt
{
    my($sprot, $sprotCache, $sprotIndex) = @_;

    if(! -d $sprotCache)
    {
        `mkdir $sprotCache`;
        `chmod a+wxt $sprotCache`;
    }

    if((! -e $sprotIndex) ||                    # Index doesn't exist
       (( -M $sprotIndex) > ( -M $sprot)))      # Index older than SwissProt
    {
        print STDERR "Building SwissProt index...";
        unlink($sprotIndex)       if (-e $sprotIndex );
        unlink("$sprotIndex.dir") if (-e "$sprotIndex.dir" );
        unlink("$sprotIndex.pag") if (-e "$sprotIndex.pag" );
        `$config::indexsprot -q $sprot $sprotIndex`;
        `touch $sprotIndex`;    # In case DBM only makes .dir and .pag files
        print STDERR "done\n";
    }
}

# Use indexing program to extract the data from SwissProt
sub GetSwissProt
{
    my($ac) = @_;

    if($config::LocalSwissProt)
    {
        # Index SwissProt if necessary
        IndexSwissProt($config::swissprot, $config::sprotCacheDir, $config::sprotIndex);
        
        return(GetSwissProtLocal($ac));
    }

    return(GetSwissProtWeb($ac));
}

# Use indexing program to extract the data from SwissProt
sub GetSwissProtLocal
{
    my($ac) = @_;
    my $data = `$config::getsprot $config::swissprot $config::sprotIndex $ac`;

    return($data);
}

sub GetSwissProtWeb
{
    my($id) = @_;
    my $url;

    # Grab the SwissProt entry from the UniProt web service
    if($id =~ /\_/)
    {
        $url = sprintf($uniprotURLsprotID, $id);
    }
    else
    {
        $url = sprintf($uniprotURLsprotAC, $id);
    }
    my $ua = WEB::CreateUserAgent("");
    my $req = WEB::CreateGetRequest($url);
    my $content = WEB::GetContent($ua, $req);

    return($content);
}

1;
