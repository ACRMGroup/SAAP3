#!/acrm/usr/local/bin/perl -s

use config;
use strict;
use SAAP;

# Information string about this plugin
$::infoString = "Checking if this is a mutation to proline";

#NSN:19.10.11

my $glyInfile  = "$SAAP::glyTorsionDensityMap";
my $proInfile  = "$SAAP::proTorsionDensityMap";
my $elseInfile = "$SAAP::elseTorsionDensityMap";

my $glyThreshold  = "$SAAP::glyThreshold";
my $proThreshold  = "$SAAP::proThreshold";
my $elseThreshold = "$SAAP::elseThreshold";

my $natEnergy; my $mutEnergy; my $badNat; my $badMut; my $natThreshold;

my $natResult = "OK";
my $mutResult = "OK";
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
    if(($phi eq "NULL") || ($psi eq "NULL"))
    {
        SAAP::PrintJsonError("Proline", "Residue not found");
        exit 1;
    }
    elsif(($phi == 9999.0) || ($psi == 9999.0))
    {
        SAAP::PrintJsonError("Proline", "Terminal residue - analysis not performed as Phi/Psi angles could not be calculated");
        exit 0;
    }

    ($badNat, $badMut, $natEnergy, $mutEnergy, $natThreshold) = 
        CheckGlyPhiPsi($phi, $psi, $native, $glyInfile, $proInfile, $elseInfile);
    if ($badNat) 
    {
        $natResult = "BAD"; 
    }
    if (($badMut) && !($badNat))
    {
        $mutResult = "BAD"; 
    }
}

unlink($chainfile);

$json = SAAP::MakeJson("Proline", ('BOOL'=>$mutResult, 'NATIVE-BOOL'=>$natResult, 'PHI'=>$phi, 'PSI'=>$psi, 'NATIVE'=>$native, 'MUTANT'=>$mutant,'MUTANT-ENERGY'=>$mutEnergy,'NATIVE-ENERGY'=>$natEnergy, 'NATIVE-THRESHOLD'=>$natThreshold, 'MUTANT-THRESHOLD'=>$proThreshold ));
print "$json\n";
SAAP::WriteCache("Proline", $pdbfile, $residue, $mutant, $json);

#---------------------------------------------
sub CheckGlyPhiPsi
{
    my($phi,$psi, $native, $glyInfile, $proInfile, $elseInfile) = @_;
    
    my @GlyMatrix  = ReadTorsionDensityMap($glyInfile);
    my @ProMatrix  = ReadTorsionDensityMap($proInfile);
    my @ElseMatrix = ReadTorsionDensityMap($elseInfile);
    
    $phi = RoundandLimit($phi, 180);
    $psi = RoundandLimit($psi, 180);
    
    my $glyEnergy = $GlyMatrix[($phi+180)][($psi+180)];
    my $proEnergy = $ProMatrix[($phi+180)][($psi+180)];
    my $elseEnergy = $ElseMatrix[($phi+180)][($psi+180)];
    
    # The following loop will check and return 4 results
    # (Is Nat in allowed region?, Is Mut in allowed region?, return the 
    #  NatEnergy, return the MutEnergy)
    
    # Checking if the native in the allowed region
    if ($proEnergy < $proThreshold)   
    {
        $badMut = 0;
    }   
    else # Native Gly not in the allowed region
    { 
        $badMut = 1;
    }    
    
    # If the mutant PRO check if it's in the allowed region 
    if ($native eq "GLY") 
    { 
        $natEnergy = $glyEnergy; 
        $natThreshold =$glyThreshold;
        
        if ($glyEnergy < $glyThreshold)
        {
            $badNat = 0;           
        }
        else
        {
            $badNat = 1; 
        }
    }
    else  # The mutant is not PRO, check if it's in the general allowed region 
    {
        $natEnergy = $elseEnergy; 
        $natThreshold =$elseThreshold;
        
        if ($elseEnergy <  $elseThreshold) 
        {
            $badNat = 0;          
        }    
        else 
        {
            $badNat = 1; 
        }
    }    
    return ($badNat, $badMut, $natEnergy, $proEnergy, $natThreshold);   
}
    
#---------------------------------------------
sub ReadTorsionDensityMap
{
    my ($infile) = @_;
    
    my @array;       
    open (IN, "$infile") || die "Can't read $infile";
   
    <IN>; # skipping the first line (header)
    for (my $j = 0; <IN>; $j++) 
    {
        chomp;
        $array[$j] = [ split /,/ ];
        shift @{$array[$j]};   # Remove the line label
    }
    return @array;
    close IN;
}
#---------------------------------------------
sub RoundandLimit
{
    my ($val, $limit) = @_;
    
    $val -= 0.5;
    $val = int($val);
    if($val > $limit)
    {
        $val = $limit;
    }
    return($val);
}
#---------------------------------------------
