#!/acrm/usr/local/bin/perl -s

use config;
use strict;
use SAAP;

# Information string about this plugin
$::infoString = "Checking for mutation from glycine";

#NSN:19.10.11

my $glyInfile  = "$SAAP::glyTorsionDensityMap";
my $proInfile  = "$SAAP::proTorsionDensityMap";
my $elseInfile = "$SAAP::elseTorsionDensityMap";

my $glyThreshold  = "$SAAP::glyThreshold";
my $proThreshold  = "$SAAP::proThreshold";
my $elseThreshold = "$SAAP::elseThreshold";

my $natEnergy; my $mutEnergy; my $badNat; my $badMut; my $mutThreshold;

my $natResult = "OK";
my $mutResult = "OK";
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
    if(($phi eq "NULL") || ($psi eq "NULL"))
    {
        SAAP::PrintJsonError("Glycine", "Residue not found");
        exit 1;
    }
    elsif(($phi == 9999.0) || ($psi == 9999.0))
    {
        SAAP::PrintJsonError("Glycine", "Terminal residue - analysis not performed as Phi/Psi angles could not be calculated");
        exit 0;
    }
    
    ($badNat, $badMut, $natEnergy, $mutEnergy, $mutThreshold) = 
        CheckGlyPhiPsi($phi, $psi, $mutant, $glyInfile, $proInfile, $elseInfile);  
    
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

$json = SAAP::MakeJson("Glycine", ('BOOL'=>$mutResult, 'NATIVE-BOOL'=>$natResult, 'PHI'=>$phi, 'PSI'=>$psi, 'NATIVE'=>$native, 'MUTANT'=>$mutant,'MUTANT-ENERGY'=>$mutEnergy,'NATIVE-ENERGY'=>$natEnergy, 'NATIVE-THRESHOLD'=>$glyThreshold, 'MUTANT-THRESHOLD'=>$mutThreshold ));
print "$json\n";
SAAP::WriteCache("Glycine", $pdbfile, $residue, $mutant, $json);


#---------------------------------------------
sub CheckGlyPhiPsi
{
    my($phi,$psi, $mutant, $glyInfile, $proInfile, $elseInfile) = @_;
    
    my @GlyMatrix  = ReadTorsionDensityMap($glyInfile);
    my @ProMatrix  = ReadTorsionDensityMap($proInfile);
    my @ElseMatrix = ReadTorsionDensityMap($elseInfile);
    
    $phi = RoundandLimit($phi, 180);
    $psi = RoundandLimit($psi, 180);
    
    my $glyEnergy = $GlyMatrix[($phi+180)][($psi+180)];
    my $proEnergy = $ProMatrix[($phi+180)][($psi+180)];
    my $elseEnergy = $ElseMatrix[($phi+180)][($psi+180)];
    
    # The following loop will check and return 4 results
    # (Is Nat in allowed region?, Is Mut in allowed region?, return the NatEnergy, return the MutEnergy)
    
    # Checking if the native Gly in the allowed region
    if ($glyEnergy < $glyThreshold)   
    {
        $badNat = 0;
    }   
    else # Native Gly not in the allowed region
    { 
        $badNat = 1;
    }
    
    
    # If the mutant PRO check if it's in the allowed region 
    if ($mutant eq "PRO") 
    { 
        $mutEnergy = $proEnergy; 
        $mutThreshold =$proThreshold;
        
        if ($proEnergy < $proThreshold)
        {
            $badMut = 0;           
        }
        else
        {
            $badMut = 1; 
        }
    }
    else  # The mutant is not PRO, check if it's in the general allowed region 
    {

        $mutEnergy = $elseEnergy; 
        $mutThreshold =$elseThreshold;
        
        if ($elseEnergy <  $elseThreshold) 
        {
            $badMut = 0;          
        }    
        else 
        {
            $badMut = 1; 
        }
    }    
    return ($badNat, $badMut, $glyEnergy, $mutEnergy, $mutThreshold);   
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
