package SAAP;
use config;
##########################################################################
# Percentage threshold for a buried residue and a surface residue
$buried  = 10.0;
$surface = 20.0;
##########################################################################
# Parameters for variations of checkhbond
$checkhbondSS = "$config::binDir/checkhbond";
$chbdata1SS   = "$config::dataDir/hbmatricesS35.dat";
$chbdata2SS   = ""; # This should be empty

$checkhbondO  = "$config::binDir/checkhbond_Oacceptor";
$chbdata1O    = "$config::dataDir/hbmatricesS35_SCMC.dat";
$chbdata2O    = "-n $config::dataDir/hbmatricesS35_O.dat";

$checkhbondN  = "$config::binDir/checkhbond_Ndonor";
$chbdata1N    = "$config::dataDir/hbmatricesS35_SCMC.dat";
$chbdata2N    = "-n $config::dataDir/hbmatricesS35_N.dat";

$emeanSS      = 10.44;        # CATH v2.6.0 06.02.06
$esigmaSS     = 2.04;

$emeanN       = 6.98;         # CATH v2.6.0 06.02.06
$esigmaN      = 1.21;

$emeanO       = 13.68;        # CATH v2.6.0 06.02.06
$esigmaO      = 3.33;


##########################################################################
# Used for Error messages
$ErrorMessage = "";

##########################################################################
# Used by IMPACT
$pdbswsURL       = "http://www.bioinf.org.uk/pdbsws/query.pl";
$impactC1        = 0.8;
$impactC2        = 2.0;

##########################################################################
# Glycine & Proline Analysis
$glyTorsionDensityMap  = "$config::pluginDataDir/heatMap_pc25res1.8R0.3_Gly_sm6_energyMatrix.txt";
$proTorsionDensityMap  = "$config::pluginDataDir/heatMap_pc25res1.8R0.3_Pro_sm6_energyMatrix.txt";
$elseTorsionDensityMap = "$config::pluginDataDir/heatMap_pc25res1.8R0.3_Else_sm6_energyMatrix.txt";
$glyThreshold  = 0.35;   
$proThreshold  = 0.53;   
$elseThreshold = 1.5;     


##########################################################################
my %onethr = 
(
    'A' => 'ALA',
    'C' => 'CYS',
    'D' => 'ASP',
    'E' => 'GLU',
    'F' => 'PHE',
    'G' => 'GLY',
    'H' => 'HIS',
    'I' => 'ILE',
    'K' => 'LYS',
    'L' => 'LEU',
    'M' => 'MET',
    'N' => 'ASN',
    'P' => 'PRO',
    'Q' => 'GLN',
    'R' => 'ARG',
    'S' => 'SER',
    'T' => 'THR',
    'V' => 'VAL',
    'W' => 'TRP',
    'Y' => 'TYR'
);

##########################################################################
# Consensus values: Eisenberg, et al 'Faraday Symp.Chem.Soc'17(1982)109
%hydrophobicity = 
(
 'ILE' =>   0.730,
 'PHE' =>   0.610,
 'VAL' =>   0.540,
 'LEU' =>   0.530,
 'TRP' =>   0.370,
 'MET' =>   0.260,
 'ALA' =>   0.250,
 'GLY' =>   0.160,
 'CYS' =>   0.040,
 'TYR' =>   0.020,
 'PRO' =>  -0.070,
 'THR' =>  -0.180,
 'SER' =>  -0.260,
 'HIS' =>  -0.400,
 'GLU' =>  -0.620,
 'ASN' =>  -0.640,
 'GLN' =>  -0.690,
 'ASP' =>  -0.720,
 'LYS' =>  -1.100,
 'ARG' =>  -1.800
);

##########################################################################
%charge = 
(
 'ILE' =>   0,
 'PHE' =>   0,
 'VAL' =>   0,
 'LEU' =>   0,
 'TRP' =>   0,
 'MET' =>   0,
 'ALA' =>   0,
 'GLY' =>   0,
 'CYS' =>   0,
 'TYR' =>   0,
 'PRO' =>   0,
 'THR' =>   0,
 'SER' =>   0,
 'HIS' =>   1,
 'GLU' =>  -1,
 'ASN' =>   0,
 'GLN' =>   0,
 'ASP' =>  -1,
 'LYS' =>   1,
 'ARG' =>   1
);

#*************************************************************************
sub Initialize
{
    $ENV{'PERL5LIB'} .= ":$config::saapHome:$config::libDir";
    $ENV{'DATADIR'} = $config::dataDir;
    if(! -d $config::cacheDir)
    {
        `mkdir $config::cacheDir`;
        `chmod a+wxt $config::cacheDir`;
    }
}

#*************************************************************************
sub ParseCmdLine
{
    my ($program) = @_;

    # 11.07.12 Print an information message if called with -info
    # and $::infoString is defined.
    if(defined($::info))
    {
        if(defined($::infoString))
        {
            print "$::infoString\n";
        }
        exit 0;
    }

    if(@ARGV != 3)
    {
        &::UsageDie();
    }

    my $residue = shift(@ARGV);
    my $mutant  = shift(@ARGV);
    my $pdbfile = shift(@ARGV);

    $mutant = "\U$mutant";
    if(defined($onethr{$mutant}))
    {
        $mutant = $onethr{$mutant};
    }

    if(! -e $pdbfile)
    {
        PrintJsonError($program, "PDB file ($pdbfile) does not exist");
        exit 1;
    }

    Initialize();

    return($residue, $mutant, $pdbfile);
}

#*************************************************************************
# Identifies the native amino acid at a specified position
sub GetNative
{
    my($pdbfile, $residue) = @_;
    my $resnam = `$config::binDir/getresidue $residue $pdbfile`;
    chomp $resnam;
    $resnam =~ s/\s//g;
    return($resnam);
}

#*************************************************************************
sub GetChain
{
    my($pdbfile, $chain) = @_;
    my $chainfile = "$config::tmpDir/$chain.pdb.$$";
    if($chain eq "")
    {
        `cp $pdbfile $chainfile`;
    }
    else
    {
        `$config::binDir/pdbgetchain $chain $pdbfile $chainfile`;
    }
    return($chainfile);
}

#*************************************************************************
# 05.12.11 Modified to deal with numeric chain names
sub ParseResSpec
{
    my($resspec) = @_;
    if($resspec =~ /\./)
    {
        $resspec =~ /([0-9]+)\.(\d+)([A-Za-z]*)/;
        return($1,$2,$3);
    }

    $resspec =~ /([A-Za-z]*)(\d+)([A-Za-z]*)/;
    return($1,$2,$3);
}

#*************************************************************************
sub PrintJsonError
{
    my($program, $message) = @_;

    print "{\"$program-ERROR\": \"$message\"}\n";
}

#*************************************************************************
# 04.11.11  Modified to put the JSON keyword in "" and to take lists
#           separated with | and turn into an array
sub MakeJson
{
    my($program, %hash) = @_;
    my $first = 1;
    my $json;

    $json = "{";
    foreach $key (keys %hash)
    {
        if($first)
        {
            $first = 0;
        }
        else
        {
            $json .= ", ";
        }
        my $value = $hash{$key};
        # Escape any double inverted commas
        $value =~ s/\"/\\\"/g;
        # If the value contains vertical bars then it's an array
        # Replace the vertical bars and wrap in []
        if($value =~ /\|/)
        {
            $value =~ s/\|/,/g;
            $value = "[$value]";
        }
        else # a scalar value
        {
            $value = "\"$value\"";
        }
        $json .= "\"$program-$key\": $value";
    }
    $json .= "}";
    return($json);
}

#*************************************************************************
sub CheckRes
{
    my($file, $resid) = @_;
    my $result = `$config::binDir/pdbcheckforres $resid $file`;
    if($result =~ /Y/i)
    {
        return(1);
    }
    return(0);
}

#*************************************************************************
sub CheckCache
{
    my($program, $pdbfile, $resid, $newres) = @_;
    my $cacheFile = "${pdbfile}_${resid}_${newres}";
    $cacheFile =~ s/\//_/g;
    $cacheFile = "$config::cacheDir/${program}/$cacheFile";

    if(-e $cacheFile)
    {
        my $cache = `cat $cacheFile`;
        return($cache);
    }
    return("");
}

#*************************************************************************
sub WriteCache
{
    my($program, $pdbfile, $resid, $newres, $results) = @_;
    if(! -d "$config::cacheDir/$program")
    {
        `mkdir -p $config::cacheDir/$program`;
        `chmod a+wxt $config::cacheDir/$program`;
    }
    if(-d "$config::cacheDir/$program")
    {
        my $cacheFile = "${pdbfile}_${resid}_${newres}";
        $cacheFile =~ s/\//_/g;
        $cacheFile = "$config::cacheDir/$program/$cacheFile";

        if(open(CACHE, ">$cacheFile"))
        {
            print CACHE $results;
            close CACHE;
        }
    }
}

#*************************************************************************
sub GetRelativeAccess
{
    my($pdbFile, $residueIn) = @_;

    my($chainIn, $resnumIn, $insertIn) = ParseResSpec($residueIn);

    my $resFile = $pdbFile;
    $resFile =~ s/\//\_/g;
    my $solvFile = "$config::solvCacheDir/$resFile";
    my $solvFileChain = "$config::solvCacheDir/$resFile" . "_$chainIn";

    if(! -d $config::solvCacheDir)
    {
        `mkdir -p $config::solvCacheDir`;
        if(! -d $config::solvCacheDir)
        {
            $ErrorMessage = "Cannot create solvent accessibility cache directory ($config::solvCacheDir)";
            print STDERR "***Error: $ErrorMessage\n";
            return(0,0,-1);
        }
    }

    # Build cached files if they don't exist
    if(! -e $solvFile)
    {
        my $exe = "$config::binDir/pdbsolv -f $config::dataDir/radii.dat -r $solvFile -n $pdbFile";
        system($exe);
        if(! -e $solvFile)
        {
            $ErrorMessage = "Cannot create solvent accessibility cache file ($solvFile)";
            print STDERR "***Error: $ErrorMessage\n";
            return(0,0,-1);
        }
    }

    if(! -e $solvFileChain)
    {
        my $exe;
        if($chainIn eq '')
        {
            $exe = "$config::binDir/pdbgetchain -n 1 $pdbFile | $config::binDir/pdbsolv -f $config::dataDir/radii.dat -r $solvFileChain -n";
        }
        else
        {
            $exe = "$config::binDir/pdbgetchain $chainIn $pdbFile | $config::binDir/pdbsolv -f $config::dataDir/radii.dat -r $solvFileChain -n";
        }
        system($exe);
        if(! -e $solvFileChain)
        {
            $ErrorMessage = "Cannot create chain solvent accessibility cache file ($solvFileChain)";
            print STDERR "***Error: $ErrorMessage\n";
            return(0,0,-1);
        }
    }

    my $relaccessOut    = 0;
    my $status          = -1;
    if(open(my $fp, '<', $solvFile))
    {
        while(<$fp>)
        {
            chomp;
            if(/^RESACC\s+([a-zA-Z0-9]+)\s+(\d+)([a-zA-z]?)\s+([A-Z]+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/)
            {
                my $chain       = $1;
                my $resnum      = $2;
                my $insert      = $3;
                my $resnam      = $4;
                my $access      = $5;
                my $relaccess   = $6;
                my $scaccess    = $7;
                my $screlaccess = $8;

                if(($chain eq $chainIn) && ($resnum eq $resnumIn) && ($insert eq $insertIn))
                {
                    $relaccessOut = $relaccess;
                    $status       = 0;
                    last;
                }
            }
            elsif(/^RESACC\s+(\d+)([a-zA-z]?)\s+([A-Z]+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/)
            {
                my $resnum      = $1;
                my $insert      = $2;
                my $resnam      = $3;
                my $access      = $4;
                my $relaccess   = $5;
                my $scaccess    = $6;
                my $screlaccess = $7;

                if(($chainIn eq '') && ($resnum eq $resnumIn) && ($insert eq $insertIn))
                {
                    $relaccessOut = $relaccess;
                    $status       = 0;
                    last;
                }
            }
        }
        close $fp;
    }

    my $relaccessMolOut = 0;
    if($status == 0)
    {
        $status             = -1;
        if(open(my $fp, '<', $solvFileChain))
        {
            while(<$fp>)
            {
                chomp;
                if(/^RESACC\s+([a-zA-Z0-9]+)\s+(\d+)([a-zA-z]?)\s+([A-Z]+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/)
                {
                    my $chain       = $1;
                    my $resnum      = $2;
                    my $insert      = $3;
                    my $resnam      = $4;
                    my $access      = $5;
                    my $relaccess   = $6;
                    my $scaccess    = $7;
                    my $screlaccess = $8;

                    if(($chain eq $chainIn) && ($resnum eq $resnumIn) && ($insert eq $insertIn))
                    {
                        $relaccessMolOut = $relaccess;
                        $status          = 0;
                        last;
                    }
                }
                elsif(/^RESACC\s+(\d+)([a-zA-z]?)\s+([A-Z]+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/)
                {
                    my $resnum      = $1;
                    my $insert      = $2;
                    my $resnam      = $3;
                    my $access      = $4;
                    my $relaccess   = $5;
                    my $scaccess    = $6;
                    my $screlaccess = $7;

                    if(($chainIn eq '') && ($resnum eq $resnumIn) && ($insert eq $insertIn))
                    {
                        $relaccessMolOut = $relaccess;
                        $status          = 0;
                        last;
                    }
                }
            }
            close $fp;
        }
    }

    return($relaccessOut, $relaccessMolOut, $status);
}


#*************************************************************************
sub GetTorsion
{
    my ($pdbfile, $resnum, $insert) = @_;
    my $resid = $resnum . $insert;
    my $omega = 9999.0;

    my $torsionResults = `$config::binDir/pdbtorsions -o $pdbfile`;
    my @records = split(/\n/, $torsionResults);
    foreach my $record (@records)
    {
        $record =~ s/^\s+//;
        my @fields = split(/\s+/, $record);
        if($fields[0] eq $resid)
        {
            return($fields[2], $fields[3], $omega);
        }
        $omega = $fields[4];
    }
    return("NULL","NULL","NULL");
}

sub CacheHBondData
{
    my($pdbFile) = @_;
    my $cacheFile = $pdbFile;
    $cacheFile =~ s/\//_/g;
    my $hbondFile = "$config::hbCacheDir/$cacheFile";

    if(! -e $hbondFile)
    {
        `mkdir -p $config::hbCacheDir` if(! -d $config::hbCacheDir);
        system("$config::binDir/pdbhbond -p $config::dataDir/Explicit.pgp $pdbFile $hbondFile");
        if((! -e $hbondFile) || ( -z $hbondFile))
        {
            return("");
        }
    }

    return($hbondFile);
}

1;
