package TLPCL;

# This is the command line parser used by delcache.pl and pipeline.pl

##########################################################################
sub ParseCmdLine
{
    my ($programName, $uniprot, $pdbcode) = @_;

    if(@ARGV != 3)
    {
        &::UsageDie();
    }

    my $residue = shift(@ARGV);
    my $mutant  = shift(@ARGV);
    my $file    = shift(@ARGV);

    my $pdbfile = "";

    if($pdbcode)
    {
        $file    = "\L$file";   # Lower case
        $pdbfile = $config::pdbPrep . $file . $config::pdbExt;
        $pdbcode = "$file";
    }
    else
    {
        $pdbfile = $file;
        if($file =~ /.*(\d...)\.[pe][dn][bt]/)
        {
            $pdbcode = $1;
            $pdbcode = "\L$pdbcode";
        }
    }

    if(! -e $pdbfile)
    {
        SAAP::PrintJsonError($programName, "PDB file ($pdbfile) does not exist");
        exit 1;
    }

    if($uniprot ne "")
    {
        # Look up the PDB code(s) for this PDB file.
        my @results = PDBSWS::ACQueryAll($uniprot, $residue);
        if($results[0] eq "ERROR")
        {
            SAAP::PrintJsonError($programName, "UniProt accession code ($uniprot) not known in PDBSWS");
            exit 1;
        }

        $residue = "";
        foreach my $result (@results)
        {
            if($$result{'PDB'} eq $pdbcode)
            {
                $residue = $$result{'CHAIN'} . $$result{'RESID'};
                last;
            }
        }
        if($residue eq "")
        {
            SAAP::PrintJsonError($programName, "PDB code ($pdbcode) is not found as a match UniProt accession ($uniprot) in PDBSWS");
            exit 1;
        }
    }

    $mutant = "\U$mutant";
    if(defined($SAAP::onethr{$mutant}))
    {
        $mutant = $SAAP::onethr{$mutant};
    }

    SAAP::Initialize();

    return($residue, $mutant, $pdbfile, $pdbcode);

}

1;
