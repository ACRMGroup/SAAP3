package JSONSAAP;

use JSON;
sub Decode
{
    my ($content) = @_;

    my $json = new JSON;
    my $jsonText = $json->relaxed->decode($content);
    return($jsonText);
}

sub Check
{
    my($jsonText) = @_;
    my $type = "";

    if(defined($$jsonText{'SAAP'}))
    {
        # It's a single PDB analysis
        $type = "SAAP";
        
        my $SAAPHash = $$jsonText{'SAAP'};
        if(!defined $$SAAPHash{'residue'})
        {
            return("SAAP","Residue is not defined");
        }
        if(!defined $$SAAPHash{'mutation'})
        {
            return("SAAP","Mutation is not defined");
        }
        if(!defined $$SAAPHash{'file'})
        {
            return("SAAP","PDB File is not defined");
        }
        if(defined $$SAAPHash{'ERROR'})
        {
            return("SAAP",$$SAAPHash{'ERROR'});
        }
    }
    elsif(defined($$jsonText{'SAAP-ERROR'}))
    {
        return("SAAP", $$jsonText{'SAAP-ERROR'});
    }
    elsif(defined($$jsonText{'SAAPS'}))
    {
        # It's a multi analysis
        $type = "SAAPS";

        my $SAAPSHash = $$jsonText{'SAAPS'};
        if(!defined($$SAAPSHash{'uniprotac'}))
        {
            return("SAAPS","Uniprot accession is not defined");
        }
        if(!defined($$SAAPSHash{'resnum'}))
        {
            return("SAAPS","Uniprot residue number is not defined");
        }
        if(!defined($$SAAPSHash{'native'}))
        {
            return("SAAPS","Native residue is not defined");
        }
        if(!defined($$SAAPSHash{'mutant'}))
        {
            return("SAAPS","Mutant residue is not defined");
        }

        # Now we have the array of structural analyses for each PDB file
        # Recursively call this routine on each of these
        my $SAAPArray = $$SAAPSHash{'pdbs'};
        my $nAnalyses = 0;
        my $nErrors   = 0;
        my $errorMessages = "";
        foreach my $saap (@$SAAPArray)
        {
            $nAnalyses++;
            my ($junk,$return) = Check($saap);
            if($return ne "")
            {
                $nErrors++;
                if($errorMessages eq "")
                {
                    $errorMessages = $return;
                }
                else
                {
                    $errorMessages .= " | $return";
                }
            }
        }

        # If everything failed then return an error status
        if($nErrors == $nAnalyses)
        {
            return("SAAPS",$errorMessages);
        }
    }

    return($type,"");
}

sub GetSaapArray
{
    my($jsonText) = @_;

    if(defined($$jsonText{'SAAP'}))
    {
        my @results;
        push @results, $jsonText;
        return(@results);
    }
    elsif(defined($$jsonText{'SAAPS'}))
    {
        my $SAAPSHash = $$jsonText{'SAAPS'};
        my $SAAPArray = $$SAAPSHash{'pdbs'};
        return(@$SAAPArray);
    }

    return();
}

sub IdentifyPDBSaap
{
    my($jsonText) = @_;
    my $SAAPHash = $$jsonText{'SAAP'};
    my @results = ();

    my $resid = $$SAAPHash{'residue'};
    $resid =~ /([a-zA-Z]*)(.*)/;
    my $chain = $1;
    my $resnum = $2;

    push @results, $$SAAPHash{'file'};
    push @results, $$SAAPHash{'pdbcode'};
    push @results, $chain;
    push @results, $resnum;
    push @results, $$SAAPHash{'mutation'};

    return(@results);
}

sub GetPDBExperiment
{
    my($jsonText) = @_;
    my $SAAPHash = $$jsonText{'SAAP'};
    my @results = ();

    push @results, $$SAAPHash{'structuretype'};
    push @results, $$SAAPHash{'resolution'};
    push @results, $$SAAPHash{'rfactor'};

    return(@results);
}

sub IdentifyUniprotSaap
{
    my($jsonText) = @_;
    my $SAAPHash = $$jsonText{'SAAPS'};
    my @results = ();

    push @results, $$SAAPHash{'uniprotac'};
    push @results, $$SAAPHash{'resnum'};
    push @results, $$SAAPHash{'native'};
    push @results, $$SAAPHash{'mutant'};

    return(@results);
}

sub ListAnalyses
{
    my($jsonText) = @_;
    my $SAAPHash = $$jsonText{'SAAP'};
    my $resultsHash = $$SAAPHash{'results'};

    return(keys %$resultsHash);
}

sub GetAnalysis
{
    my($jsonText, $analysis) = @_;
    my $SAAPHash = $$jsonText{'SAAP'};
    my $resultsHash = $$SAAPHash{'results'};
    return($$resultsHash{$analysis});
}

1;
