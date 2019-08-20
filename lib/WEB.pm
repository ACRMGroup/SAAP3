package WEB;
#*************************************************************************
#
#   Program:    
#   File:       WEB.pm
#   
#   Version:    V1.0
#   Date:       12.01.07
#   Function:   Routines to support web page access from Perl
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2007
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
#   according and used freely providing this header is retained
#
#*************************************************************************
#
#   Description:
#   ============
#   Simplify accessing web pages from Perl using LWP
#
#*************************************************************************
#
#   Usage:
#   ======
#   Normal page requests or CGI requests using GET
#   my $proxy   = ""; # Replace with proxy address if needed
#   my $url     = "http://mysite.com/path/to/page";
#   my $ua      = WEB::CreateUserAgent($proxy);
#   my $req     = WEB::CreateGetRequest($url);
#   my $content = WEB::GetContent($ua, $req);
#
#   CGI requests using POST
#   my $proxy   = ""; # Replace with proxy address if needed
#   my $url     = "http://mysite.com/path/to/script";
#   my $params  = "key=value&key=value";
#   my $ua      = WEB::CreateUserAgent($proxy);
#   my $req     = WEB::CreatePostRequest($url, $params);
#   my $content = WEB::GetContent($ua, $req);
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   12.01.07  Original   By: ACRM
#
#*************************************************************************
use strict;
use LWP;

########################################################################
#>sub GetContent($ua, $req)
# -------------------------
# Input:   $ua       User agent
#          $req      The packaged GET or POST request
# Returns: string    Result text
#
# Gets the content from a web page
# See Usage info above
#
# 12.01.07  Original   By: ACRM
sub GetContent
{
    my($ua, $req) = @_;
    my($res);

    $res = $ua->request($req);
    if($res->is_success)
    {
        return($res->content);
    }
    return(undef);
}

########################################################################
#>sub CreateGetRequest($url)
# --------------------------
# Input:   string $url The URL to access
# Returns:             The packaged GET request
#
# Creates an HTTP GET request
# See Usage info above
#
# 12.01.07  Original   By: ACRM
sub CreateGetRequest
{
    my($url) = @_;
    my($req);
    $req = HTTP::Request->new('GET',$url);
    return($req);
}

########################################################################
#>sub CreatePostRequest($url, $params)
# ------------------------------------
# Input:   string $url     The URL to access
#          string $params  Parameters in GET style 
#                          (key=value&key=value...)
# Returns:                 The packaged POST request
#
# Creates an HTTP POST request
# See Usage info above
#
# 12.01.07  Original   By: ACRM
sub CreatePostRequest
{
    my($url, $params) = @_;
    my($req);
    $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/x-www-form-urlencoded');
    $req->content($params);

    return($req);
}

########################################################################
#>sub CreateUserAgent($proxy)
# ---------------------------
# Input:   string $proxy Address of a proxy server or a blank string
# Returns:               The user agent
#
# Creates a user agent
# See Usage info above
#
# 12.01.07  Original   By: ACRM
sub CreateUserAgent
{                               
    my($webproxy) = @_;

    my($ua);
    $ua = LWP::UserAgent->new(timeout => 300);
    if(length($webproxy))
    {
        $ua->proxy(['http', 'ftp'] => $webproxy);
    }
    return($ua);
}

1;
