package config;

$homeDir           = "/home/bsm/martin";
$saapHome          = "$homeDir/SAAP/server";
$predHome          = "$homeDir/SAAP/pred";
$xmasDir           = "/acrm/data/xmas/pdb";
$swissprot         = "/acrm/data/swissprot/full/uniprot_sprot.dat";
$indexsprot        = "$homeDir/scripts/indexfasta/indexswissprot.pl";
$getsprot          = "$homeDir/scripts/indexfasta/getswissprot.pl";
$email             = "andrew\@andrew-martin.org"; # For EBI Webservices
$tmpDir            = "/tmp";
$webTmpDir         = "/acrm/www/html/tmp";
$RExe              = "/acrm/usr/local/bin/R";
$pdbPrep           = "/acrm/data/pdb/pdb";
$predictURL        = "/saap/dap/";
$pdbExt            = ".ent";
$cacheDir          = "/acrm/saapdb/pipelineCache";
$xmasbindir        = "/acrm/home/andrew/CONSULTANCY/inpharmatica/software/bin";
#$LocalSwissProt    = 1;         # Use local SwissProt rather than web services
$LocalSwissProt    = 0;         # Use web services for SwissProt lookups

##########################################################################
#             Shouldn't need to alter anything below here                #
##########################################################################
# Main binary and data directories
$binDir            = "$homeDir/bin";
$dataDir           = "$homeDir/data";
$checkHBondDir     = "$homeDir/cprogs/checkhbond";

# Dependent on $saapHome
$pluginDir           = "$saapHome/plugins";
$localBinDir         = "$saapHome/bin";
$saapMultiPipeline   = "$saapHome/multiUniprotPipeline.pl";
$saapUniprotPipeline = "$saapHome/uniprotPipeline.pl";
$saapMultiJSON2HTML  = "$saapHome/multiJson2html.pl";
$saapPipeline        = "$saapHome/pipeline.pl";
$saapJSON2HTML       = "$saapHome/json2html.pl";
$gifDir              = "$saapHome/webdata";
$predBin             = "$predHome/bin";
$ENV{'PBIN'}         = $predBin;
$EOF                 = "\n__EOF__\n";

# Dependent on $pluginDir
$pluginDataDir     = "$pluginDir/data";
$modulesDir        = "$pluginDir/modules";

# Dependent on $modulesDir
$RProg             = "$modulesDir/conservation_threshold.R";

# Dependent on $cacheDir
$xmasCacheDir      = "$cacheDir/xmas";
$avpCacheDir       = "$cacheDir/avp";
$consCacheDir      = "$cacheDir/cons";
$sprotCacheDir     = "$cacheDir/sprot";
$sprotIndex        = "$sprotCacheDir/sprot.idx";

# Dependent in $pluginDataDir
$specsimHashFile   = "$pluginDataDir/specsim.idx";
$specsimDumpFile   = "$pluginDataDir/specsim.dump";
$matrixFile        = "$pluginDataDir/pet91.mat";

# Dependent on $checkHBondDir
$checkHBondDataDir = "$checkHBondDir/data";
$checkHBondBinDir  = "$checkHBondDir/bin";

1;
