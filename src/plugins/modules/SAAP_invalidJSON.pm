package SAAP;
use config;
##########################################################################
# Percentage threshold for a buried residue
$buried = 10.0;
##########################################################################
# Parameters for variations of checkhbond
$checkhbondSS = "$config::checkHBondBinDir/checkhbond";
$chbdata1SS   = "$config::checkHBondDataDir/hbmatricesS35.dat";
$chbdata2SS   = "";

$checkhbondO  = "$config::checkHBondBinDir/checkhbond_Oacceptor";
$chbdata1O    = "$config::checkHBondDataDir/hbmatricesS35_SCMC.dat";
$chbdata2O    = "-n $config::checkHBondDataDir/hbmatricesS35_O.dat";

$checkhbondN  = "$config::checkHBondBinDir/checkhbond_Ndonor";
$chbdata1N    = "$config::checkHBondDataDir/hbmatricesS35_SCMC.dat";
$chbdata2N    = "-n $config::checkHBondDataDir/hbmatricesS35_N.dat";

$emeanSS      = 10.44;        # CATH v2.6.0 06.02.06
$esigmaSS     = 2.04;

$emeanN       = 6.98;         # CATH v2.6.0 06.02.06
$esigmaN      = 1.21;

$emeanO       = 13.68;        # CATH v2.6.0 06.02.06
$esigmaO      = 3.33;


##########################################################################
# Used by IMPACT
$pdbswsURL       = "http://www.bioinf.org.uk/cgi-bin/pdbsws/query.pl";
$impactC1        = 0.8;
$impactC2        = 2.0;


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
# 
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

##########################################################################
sub Initialize
{
    $ENV{'PERL5LIB'} .= ":$config::saapHome:$config::pluginDir/modules";
    $ENV{'DATADIR'} = $config::dataDir;
    if(! -d $config::cacheDir)
    {
        `mkdir $config::cacheDir`;
    }
    if(! -d $config::xmasCacheDir)
    {
        `mkdir $config::xmasCacheDir`;
    }
}

##########################################################################
sub ParseCmdLine
{
    my ($program) = @_;

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

# Identifies the native amino acid at a specified position
sub GetNative
{
    my($pdbfile, $residue) = @_;
    my $resnam = `$config::localBinDir/getresidue $residue $pdbfile`;
    chomp $resnam;
    $resnam =~ s/\s//g;
    return($resnam);
}

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
        `$config::binDir/getchain $chain $pdbfile $chainfile`;
    }
    return($chainfile);
}

sub ParseResSpec
{
    my($resspec) = @_;
    $resspec =~ /([A-Za-z]*)(\d+)([A-Za-z]*)/;
    return($1,$2,$3);
}

sub PrintJsonError
{
    my($program, $message) = @_;

    print "{$program-ERROR: \"$message\"}\n";
}

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
        $value =~ s/\"/\\\"/g;
        $json .= "$program-$key: \"$value\"";
    }
    $json .= "}";
    return($json);
}

#*************************************************************************
sub CheckRes
{
    my($file, $resid) = @_;
    my $result = `$config::binDir/checkforres -l $resid $file`;
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
sub GetXmasFile
{
    my($pdbfile) = @_;
    my $xmasFile;

    # Work out the XMAS filename, creating the file if needed
    $pdbfile =~ /(.*\/)?(.*)\..*/;
    my $filestem = $2;
    if(-e "$config::xmasDir/$filestem.xmas")
    {
        $xmasFile = "$config::xmasDir/$filestem.xmas";
    }
    else
    {
        $xmasFile = "$config::xmasCacheDir/$filestem.xmas";
        if(! -e $xmasFile)
        {
            CreateXmasFile($pdbfile, $xmasFile);
        }
    }
    return($xmasFile);
}


#*************************************************************************
sub GetRelativeAccess
{
    my($pdbfile, $residueIn) = @_;
    my $xmasFile;

    $xmasFile = SAAP::GetXmasFile($pdbfile);

    # Grab the data
    my ($pResults, $pFields, $status) = XMAS::GetXMASData($xmasFile, "atoms");
    if($status)
    {
        return(0,0,$status);
    }

    # Find which field contains the relative accessibility
    my $relaccessField    = XMAS::FindField("residue.relaccess", $pFields);
    my $relaccessMolField = XMAS::FindField("residue.relaccess_mol", $pFields);
    my $chainField        = XMAS::FindField("chain.chain", $pFields);
    my $resnumField       = XMAS::FindField("residue.resnum", $pFields);
    # Extract what we need
    foreach my $record (@$pResults)
    {
        my $relaccess    = XMAS::GetField($record, $relaccessField);
        my $relaccessMol = XMAS::GetField($record, $relaccessMolField);
        my $chain        = XMAS::GetField($record, $chainField);
        my $resnum       = XMAS::GetField($record, $resnumField);

        my $residue = $chain . $resnum;
        $residue =~ s/\s+//g;
        if($residue eq $residueIn)
        {
            return($relaccess, $relaccessMol, 0);
        }
    }
    
    return(0,0,-1);
}


#*************************************************************************
sub GetTorsion
{
    my ($pdbfile, $resnum, $insert) = @_;
    my $resid = $resnum . $insert;
    my $omega = 9999.0;

    my $torsionResults = `$config::binDir/torsions $pdbfile`;
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


#*************************************************************************
sub CreateXmasFile
{
    my($pdbfile, $xmasFile) = @_;

    print "DUMMY ROUTINE - NEEDS WRITING!\n";
}

1;
