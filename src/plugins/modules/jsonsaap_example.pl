#!/acrm/usr/local/bin/perl 

use JSONSAAP;
use strict;


my $content = "";
while(<>)
{
    $content .= $_;
}

my $json = JSONSAAP::Decode($content);

my ($type, $error) = JSONSAAP::Check($json);
if($error ne "")
{
    print "$error\n";
    exit 1;
}

if($type eq "SAAPS")
{
    my($ac, $resnum, $native, $mutant) = JSONSAAP::IdentifyUniprotSaap($json);
    print "Accession: $ac\n";
    print "Mutation: $native$resnum$mutant\n";
}

my @jsonData = JSONSAAP::GetSaapArray($json);

foreach my $jsonDatum (@jsonData)
{
    my($file, $pdbcode, $chain, $resnum, $mutation) = JSONSAAP::IdentifyPDBSaap($jsonDatum);
    print "\n\n\nPDBFILE: $file\n";
    print "PDBCODE: $pdbcode\n";
    print "CHAIN: $chain\n";
    print "RESNUM: $resnum\n";
    print "MUTATION: $mutation\n";

    my($type, $res, $rfac) = JSONSAAP::GetPDBExperiment($jsonDatum);
    print "EXPERIMENTTYPE: $type\n";
    print "RESOLUTION: $res\n";
    print "RFACTOR: $rfac\n\n";

    my @analyses = JSONSAAP::ListAnalyses($jsonDatum);
    foreach my $analysis (@analyses)
    {
        my $pResults = JSONSAAP::GetAnalysis($jsonDatum, $analysis);

        print "\n\nAnalysis: $analysis\n";
        foreach my $key (keys %$pResults)
        {
            if(($analysis eq "Voids") &&
               ($key eq "Voids-MUTANT") || ($key eq "Voids-NATIVE"))
            {
                print "   $key : ";
                my $pVoidsArray = $$pResults{$key};
                foreach my $void (@$pVoidsArray)
                {
                    print "$void ";
                }
                print "\n";
            }
            else
            {
                print "   $key : $$pResults{$key}\n";
            }
        }
    }
}
