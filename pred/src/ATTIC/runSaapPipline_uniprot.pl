#!/usr/bin/perl -s
#*************************************************************************
use configPred;
use strict;

#my $shfile = &create_sh_file($::sprot,$::nat,$::pos,$::mut,$::PDBlimit);
#my $job = `sh $shfile`;
#$job =~ s/\s+$//;
#print "$job\n";
#print STDERR "    submitted $shfile\n";
#print STDERR "    submitted $job\n";

#exit;
#-------------------------------------------------------------------------
#sub create_sh_file
#{
  #  ($::sprot,$::nat,$::pos,$::mut,$::PDBlimit) = @_;
  #  my $outfile = $configPred::pipelineJSON."/".$::sprot."_".$::nat."_".$::pos."_".$::mut.".json";
    my $shfile = $configPred::tmpDir."/id_".$::sprot."_".$::nat."_".$::pos."_".$::mut.".sh";
    
    open ( FILE, ">$shfile" ) || die "Cannot write to file '$shfile'\n$!\n";
    print FILE "#!/bin/sh\n#\$ -S /bin/sh\n\n";
    #-- Define command line inputs
    print FILE  "cd ".$configPred::piplineDir." \n";
    print FILE  "source ./init.sh \n";
    print FILE  $configPred::perl." ".$configPred::pipeline_uniprot." -v -limit=".$::PDBlimit." ".$::sprot." ".$::nat." ".$::pos." ".$::mut."  > ."$::jsonFile." \n";
    print FILE "echo COMPLETE\t".$shfile." in \n";
    close ( FILE );
my $job = `sh $shfile`;
print "$job\n";
   # return ( $fname );
#}
#-------------------------------------------------------------------------
