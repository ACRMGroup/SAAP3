# Use the REST interface to PDBSWS to obtain the SwissProt code and residue number
# TODO Change to use the version in PDBSWS.pm
sub PDBtoSProt
{
    my ($pdbfile, $chain, $resid) = @_;
    my $ac = "Error: Undefined";
    my $upResnum = 0;

    $pdbfile =~ /^.*(....)\..*/;
    my $pdbcode = $1;
    # http://www.bioinf.org.uk/cgi-bin/pdbsws/query.pl?plain=1&qtype=pdb&id=$pdbcode&chain=$chain&res=$resid
    my $url = sprintf "%s?plain=1&qtype=pdb&id=%s&chain=%s&res=%s", $config::pdbswsURL, $pdbcode, $chain, $resid;
    my $ua = WEB::CreateUserAgent("");
    my $req = WEB::CreateGetRequest($url);
    my $content = WEB::GetContent($ua, $req);
    if($content eq "")
    {
        return("Error: No data returned from PDBSWS", 0);
    }

    my @records = split(/\n/, $content);
    foreach my $record (@records)
    {
        my @fields = split(/\s+/, $record, 2);
        if($fields[0] =~ /^AC:/)
        {
            #UniProt accession
            $ac = $fields[1];
        }
        elsif($fields[0] =~ /^UPCOUNT:/)
        {
            #Residue number in the UniProt sequence
            $upResnum = $fields[1];
        }
        elsif($fields[0] =~ /^ERROR:/)
        {
            #Error message (if any - database connectivity)
            return($fields[1], 0);
        }
    }
    return($ac, $upResnum);
}

