package configPred;
 
#-- set direcories
$pipelineJSON     = "/acrm/saapdb/saapPred/json/"  ;
$jsonOut          = "/acrm/saapdb/saapPred/jsonOut/"  ;
#$gridOutDir       = "/acrm/saapdb/saapPred/gridOutFiles/"  ;
$errorDir         = "/acrm/saapdb/saapPred/error/"  ;
$csvDir           = "/acrm/saapdb/saapPred/csv/"  ;
$arffDir          = "/acrm/saapdb/saapPred/arff/"  ;
$predDir          = "/acrm/saapdb/saapPred/prediction/"  ;
# above difrecories could be redirected to /tmp
$tmpDir           = "/tmp";


#-- Programs
$perl             = "/acrm/usr/local/bin/perl"  ;
$java             = "/acrm/usr64/local/apps/java/jre1.6.0_21/bin/java"  ;
$weka             = "/home/bsm/anya/tools/weka-3-6-2/weka.jar"  ;

#-- To turn PDB codes into a filename...
$pdbprep          = "/acrm/data/pdb/pdb";
$pdbext           = ".ent";

#------------------#
#-- saapPipeline --#
#------------------#
$pdblimit = "3";

#-----------------#
#-- JSON to CSV --#
#-----------------#
$parseJSON        = "/acrm/saapdb/saapPred/bin/json2csv_uniprot_allPDB.pl";

#-----------------#
#-- CSV to ARFF --#
#-----------------#
$csv2arff         = "/home/bsm/martin/bin/csv2arff";
$features         = "Binding,SProtFT2,SProtFT4,SProtFT5,SProtFT6,SProtFT7,SProtFT8,SProtFT9,SProtFT10,SProtFT11,SProtFT12,Interface,Relaccess,Impact,HBonds,SPhobic,CPhim,BCharge,SSGeom,Voids,MLargest1,MLargest2,MLargest3,MLargest4,MLargest5,MLargest6,MLargest7,MLargest8,MLargest9,MLargest10,NLargest1,NLargest2,NLargest3,NLargest4,NLargest5,NLargest6,MLargest7,MLargest8,NLargest9,NLargest10,Clash,Glycine,Proline,CisPro";
$class            = "PD,SNP";
$output           = "dataset"; # name of field to be used as output
$id               = "num:uniprotac:res:nat:mut:pdbcode:chain:resnum:mutation:structuretype:resolution:rfactor";
$normScale        = "/acrm/saapdb/saapPred/models/HumVar_norm_scale_bestPDB"  ;
$options          = "-ni -no";


#------------------------#
#-- Run the predectour --#
#------------------------#

$mlimit = "3";
$modelsDir        = "/acrm/saapdb/saapPred/models/"  ;

#-- Java
$memory           = "-Xmx6g"  ;

#--weka
$classifiers      = "weka.classifiers.trees.RandomForest";
$model            = "/acrm/saapdb/comTools/result/saap/model/humVarSNPandPD_bestPDB_NoErrorsNoMissing_%d_4.model";

##########################################################################
1;
