#!/acrm/usr/local/bin/perl -s

use config;
use strict;
use SAAP;

# Information string about this plugin
$::infoString = "Checking whether this was a mutation from a cis-proline";

my $result = "OK";
my($residue, $mutant, $pdbfile) = SAAP::ParseCmdLine("CisPro");

# See if the results are cached
my $json = SAAP::CheckCache("CisPro", $pdbfile, $residue, $mutant);
if($json ne "")
{
    print "$json\n";
    exit 0;
}

my($chain, $resnum, $insert) = SAAP::ParseResSpec($residue);
my $chainfile = SAAP::GetChain($pdbfile, $chain);
my $native = SAAP::GetNative($pdbfile, $residue);
my($phi,$psi,$omega) = SAAP::GetTorsion($chainfile, $resnum, $insert);

# If it's a change from CisPro to something else...
if(($native eq "PRO") && ($mutant ne "PRO"))
{
    if($phi eq "NULL")
    {
        SAAP::PrintJsonError("CisPro", "Residue not found");
        exit 1;
    }

    my $bad = IsCis($omega);
    if($bad)
    {
        $result = "BAD";
    }
}

unlink($chainfile);

$json = SAAP::MakeJson("CisPro", ('BOOL'=>$result, 'OMEGA'=>$omega, 'NATIVE'=>$native));
print "$json\n";
SAAP::WriteCache("CisPro", $pdbfile, $residue, $mutant, $json);

# Checks whether the omega angle is cis
sub IsCis
{
    my($omega) = @_;

    if (($omega >= -20) && ($omega <= 20))
    {
        return(1);
    }
    return (0);
}

