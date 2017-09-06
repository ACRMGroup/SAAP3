#!/acrm/usr/local/bin/perl -s

use config;
use strict;
use SAAP;

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("Proline");

# See if the results are cached
my $json = SAAP::CheckCache("Proline", $pdbfile, $residue, $mutant);
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);
my $chainfile = SAAP::GetChain($pdbfile, $chain);
my $native = SAAP::GetNative($pdbfile, $residue);
my($phi, $psi) = SAAP::GetTorsion($chainfile, $resnum, $insert);

# If it's a change from Proline to something else...
if(($native ne "PRO") && ($mutant eq "PRO"))
{
    if($phi eq "NULL")
    {
        SAAP::PrintJsonError("Proline", "Residue not found");
        exit 1;
    }
    elsif(($phi == 9999.0) || ($psi == 9999.0))
    {
        SAAP::PrintJsonError("Proline", "Terminal residue - analysis not performed");
        exit 0;
    }

    my $bad = CheckProlinePhiPsi($phi, $psi);
    if($bad)
    {
        $result = "BAD";
    }
}

$json = SAAP::MakeJson("Proline", ('BOOL'=>$result, 'PHI'=>$phi, 'PSI'=>$psi));
print "$json\n";
SAAP::WriteCache("Proline", $pdbfile, $residue, $mutant, $json);

# Checks whether the phi/psi angles are within the allowed regions for 
# proline residues:
# (-70 <= phi <= -50) && (-70   <= psi <= -50)
# (-70 <= phi <= -50) && (110   <= psi <= 130)
# If OK, returns 0, else returns 1
sub CheckProlinePhiPsi
{
    my($phi,$psi) = @_;

    if (($phi >= -70) && ($phi <= -50))
    {
        if (($psi >= -70) && ($psi <= -50))
        {
            return (0);
        }
        if (($psi >= 110) && ($psi <= 130))
        {
            return (0);
        }
    }
    return (1);
}

