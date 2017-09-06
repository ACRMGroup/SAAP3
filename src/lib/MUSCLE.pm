package MUSCLE;
#*************************************************************************
#
#   Program:    
#   File:       
#   
#   Version:    V1.1
#   Date:       26.02.14
#   Function:   Access the EBI MUSCLE Web service
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2011-2014
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
#   Set of routines for using the EBI MUSCLE REST web service. Based on
#   the example script supplied by the EBI
#
#*************************************************************************
#
#   Usage:
#   ======
#
#   use MUSCLE;
#   ($error, $result) = RunMuscle($sequences, $email);
#
#   $sequences is the set of sequences in FASTA format
#   $email is your email address
#
#   On Error:   $error is 1 and $result contains a message
#   On Success: $error is 0 and $result contains FASTA alignment
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  31.08.11  Original   By: ACRM
#   V1.1  26.02.14  Modified to force the input format to FASTA since
#                   EBI changed the default to clustal...
#
#*************************************************************************
# Enable Perl warnings
use strict;
use warnings;

# Load libraries
use LWP;
use XML::Simple;

#-------------------------------------------------------------------------
# Base URL for service
$::baseUrl = 'http://www.ebi.ac.uk/Tools/services/rest/muscle';
# Set interval for checking status
$::checkInterval = 3;

#-------------------------------------------------------------------------
# RunMuscle()
#
# Submit a MUSCLE job to the service.
#
#  ($error, $result) = RunMuscle($seq, $email);
# The sequences must be in FASTA format
sub RunMuscle
{
    my($sequences, $email) = @_;
    
    # Submit the job
    my ($jobid, $error) = RESTRun($email, $sequences, "fasta");
    if(!$jobid)
    {
        return(1, $error);
    }

    sleep 1;
    my ($ok,$result) = GetResults($jobid);
    if(!$ok)
    {
        return(1, $result);
    }
    return(0, $result);
}

#-------------------------------------------------------------------------
# Perform a REST request.
# my ($ok, $response_str) = RESTRequest($url);
sub RESTRequest 
{
    my ($requestUrl) = @_;

    # Create a user agent
    my $ua = LWP::UserAgent->new();
    '$Revision: 1902 $' =~ m/(\d+)/;
    $ua->env_proxy;

    # Perform the request
    my $response = $ua->get($requestUrl);

    # Check for HTTP error codes
    if ( $response->is_error ) 
    {
        $response->content() =~ m/<h1>([^<]+)<\/h1>/;
        return(0, "HTTP status: $response->code ($response->message: $1)");
    }

    # Return the response data
    return (1, $response->content());
}


#-------------------------------------------------------------------------
# RESTRun()
#
# Submit a job.
#
#  my ($job_id, $message) = RESTRun($email, $sequences, $format );
#  $format = fasta / clw (default) / clwstrict / html / msf / phyi / phys 
#            See: http://www.ebi.ac.uk/Tools/services/rest/muscle/parameterdetails/format/

sub RESTRun 
{
    my ($email, $sequences, $format) = @_;
    
    # User agent to perform http requests
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;

    # Set parameters
    my %params;
    $params{'email'}    = $email;
    $params{'sequence'} = $sequences;
    $params{'format'}   = $format;

    # Submit the job as a POST
    my $url = $::baseUrl . '/run';
    my $response = $ua->post( $url, \%params );

    # Check for HTTP error codes
    if ( $response->is_error ) 
    {
        $response->content() =~ m/<h1>([^<]+)<\/h1>/;
        return(0, "HTTP status: $response->code ($response->message: $1)");
    }

    # The job id is returned
    my $job_id = $response->content();
    return ($job_id, "");
}

#-------------------------------------------------------------------------
# RESTGetStatus()
#
# Check the status of a job.
#
#  my $status = RESTGetStatus($job_id);
sub RESTGetStatus 
{
    my ($job_id) = @_;
    my $status_str;
    my $ok;
    my $url        = $::baseUrl . '/status/' . $job_id;
    ($ok, $status_str) = RESTRequest($url);
    if(!$ok || ($status_str eq ""))
    {
        $status_str = 'UNKNOWN';
    }

    return $status_str;
}

#-------------------------------------------------------------------------
# RESTGetResultTypes()
#
# Get list of result types for finished job.
#
#  my (@result_types) = RESTGetResultTypes($job_id);
sub RESTGetResultTypes 
{
    my ($job_id) = @_;
    my (@resultTypes);
    my $url                             = $::baseUrl . '/resulttypes/' . $job_id;
    my ($ok, $result_type_list_xml_str) = RESTRequest($url);
    if(!$ok)
    {
        return(undef);
    }
    my $result_type_list_xml            = XMLin($result_type_list_xml_str);
    (@resultTypes) = @{ $result_type_list_xml->{'type'} };
    return (@resultTypes);
}

#-------------------------------------------------------------------------
# RESTGetResult()
#
# Get result data of a specified type for a finished job.
#
#  my $result = RESTGetResult($job_id, $result_type);
sub RESTGetResult 
{
    my ($job_id, $type) = @_;
    my $url    = $::baseUrl . '/result/' . $job_id . '/' . $type;
    my ($ok,$result) = RESTRequest($url);
    return ($ok,$result);
}

#-------------------------------------------------------------------------
# PollClient()
#
# Client-side job polling.
#
#  PollClient($job_id);
sub PollClient 
{
    my ($jobid) = @_;
    my $status = 'PENDING';

    # Check status and wait if not finished.
    # Terminate if three attempts get "ERROR".
    my $errorCount = 0;
    while ($status eq 'RUNNING' ||
           $status eq 'PENDING' ||
           (($status eq 'ERROR') && ($errorCount < 2)))
    {
        $status = RESTGetStatus($jobid);
        if ($status eq 'ERROR') 
        {
            $errorCount++;
        }
        elsif ($errorCount > 0) 
        {
            $errorCount--;
        }
        if ($status eq 'RUNNING' ||
            $status eq 'PENDING' ||
            $status eq 'ERROR' )
        {
            
            # Wait before polling again.
            sleep $::checkInterval;
        }
    }
    return $status;
}

#-------------------------------------------------------------------------
# GetResults()
#
# Get the results for a job identifier.
#
#  GetResults($job_id);
sub GetResults 
{
    my ($jobid) = @_;

    # Check status, and wait if not finished
    PollClient($jobid);

    # Get list of data types
    my (@resultTypes) = RESTGetResultTypes($jobid);

    # Get the data for the fasta alignment format
    foreach my $resultType (@resultTypes) 
    {
        if($resultType->{'identifier'} eq "aln-fasta")
        {
            my ($ok,$result) = RESTGetResult($jobid, $resultType->{'identifier'});
            return($ok,$result);
        }
    }
    return(0, "MUSCLE failed - No FASTA alignment generated");
}


1;
