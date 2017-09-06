#!/acrm/usr/local/bin/perl -s

use config;
use strict;
use SAAP;

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("Glycine");

# See if the results are cached
my $json = SAAP::CheckCache("Glycine", $pdbfile, $residue, $mutant);
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);
my $chainfile = SAAP::GetChain($pdbfile, $chain);
my $native = SAAP::GetNative($pdbfile, $residue);
my($phi, $psi) = SAAP::GetTorsion($chainfile, $resnum, $insert);



# If it's a change from Glycine to something else...
if(($native eq "GLY") && ($mutant ne "GLY"))
{
    if($phi eq "NULL")
    {
        SAAP::PrintJsonError("Glycine", "Residue not found");
        exit 1;
    }
    elsif(($phi == 9999.0) || ($psi == 9999.0))
    {
        SAAP::PrintJsonError("Glycine", "Terminal residue - analysis not performed");
        exit 0;
    }

    my $bad = CheckNormalPhiPsi($phi, $psi);
    if($bad)
    {
        $result = "BAD";
    }
}

$json = SAAP::MakeJson("Glycine", ('BOOL'=>$result, 'PHI'=>$phi, 'PSI'=>$psi, 'NATIVE'=>$native));
print "$json\n";
SAAP::WriteCache("Glycine", $pdbfile, $residue, $mutant, $json);


# Checks whether the phi/psi angles are within the allowed regions for 
# non-glycine residues:
# (-180 <= phi <= -30) && (60   <= psi <= 180)
# (-115 <= phi <= -15) && (-90  <= psi <= 60)
# (-180 <= phi <= -45) && (-180 <= psi <= -120)
# (30   <= phi <= 90)  && (-20  <= psi <= 105)
# If OK, returns 0, else returns 1
sub CheckNormalPhiPsi
{
    my($phi,$psi) = @_;

    if (($phi >= -180) && ($phi <= -30))
    {
        if (($psi >= 60) && ($psi <= 180))
        {
            return (0);
        }
    }
    if (($phi >= -115) && ($phi  <= -15))
    {
        if (($psi >= -90) && ($psi <= 60))
        {
            return (0);
        }
    }
    if (($phi >= -180) && ($phi <= -45))
    {
        if (($psi >= -180) && ($psi <= -120))
        {
            return (0);
        }
    }
    if (($phi >= 30) && ($phi <= 90))
    {
        if (($psi >= -20) && ($psi <=105))
        {
            return (0);
        }
    }
    return (1);
}

