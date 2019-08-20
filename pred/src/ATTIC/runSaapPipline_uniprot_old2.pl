#!/usr/bin/perl -s
#*************************************************************************
use configPred;
use strict;
my $res;

print "$configPred::perl\n";
submit_jobs($::sprot,$::nat,$::pos,$::mut,$::PDBlimit); 

#we can add specific PDB structure later
#submit_jobs($::sprot,$::nat,$::pos,$::mut,$::PDBlimit,$::PDBcode);
sleep( 2 );
clearup();
#do { $res=clearup($::sprot,$::nat,$::pos,$::mut) } while (!$res);
exit;

#-------------------------------------------------------------------------
sub submit_jobs
{
    ($::sprot,$::nat,$::pos,$::mut,$::PDBlimit) = @_;
    #my $outfile = $config::pipelineJSON."/".$::sprot."_".$::nat."_".$::pos."_".$::mut.".json";
    my $shfile = &create_sh_file($::sprot,$::nat,$::pos,$::mut,$::PDBlimit);
    my $job = `qsub -cwd -o $config::gridOutDir -e $config::gridOutDir $shfile`;
    $job =~ s/\s+$//;
    print "$job\n";
    print STDERR "    submitted $job\n";
}

#-------------------------------------------------------------------------
sub create_sh_file
{
    ($::sprot,$::nat,$::pos,$::mut,$::PDBlimit) = @_;
    my $outfile = $config::pipelineJSON."/".$::sprot."_".$::nat."_".$::pos."_".$::mut.".json";
    my $fname = $config::gridOutDir."id_".$::sprot."_".$::nat."_".$::pos."_".$::mut.".sh";
    
    open ( FILE, ">$fname" ) || die "Cannot write to file '$fname'\n$!\n";
    print FILE "#!/bin/sh\n#\$ -S /bin/sh\n\n";
    #-- Define command line inputs
    print FILE  "cd ".$config::piplineDir." \n";
    print FILE  "source ./init.sh \n";
    print FILE  $config::perl." ".$config::pipeline_uniprot." -v -limit=".$::PDBlimit." ".$::sprot." ".$::nat." ".$::pos." ".$::mut."  > ".$outfile." \n";
    print FILE "echo COMPLETE\t".$fname." in \$HOSTNAME\n";
    close ( FILE );
    return ( $fname );
}
#-------------------------------------------------------------------------
sub clearup
{
   
    opendir( DIR, $config::gridOutDir ) || die "Cannot read directory $config::gridOutDir!\n";
    my @ofiles = grep {/c*.sh.o\d+$/} readdir( DIR );
    
    foreach my $ofile ( @ofiles )
    {
        if ( `grep COMPLETE $config::gridOutDir$ofile` )         
        {
            print "ok\n";
            my $grep =`grep COMPLETE $config::gridOutDir$ofile`;        # 'COMPLETE '$file'
            chomp $grep;
            my @array = split(/\./, $ofile);
            my $file = $array[0];
            my $jobnum = substr($array[2], 1, 7);
            my $efile= $file.".sh.e".$jobnum;
            
            if (-s $efile)
            {
                if ( `grep directory $config::gridOutDir$efile` )
                {
                    my $copystring = "mv $file* $config::errorDir/noPDBfile;";
                    system( $copystring );
                }
                elsif ( `grep mutmodel $efile` )
                {
                    my $copystring = "mv $file* $config::errorDir/mutmodel;";
                    system( $copystring );
                }
                elsif (`grep atom $efile`)
                {
                    my $copystring = "mv $file* $config::errorDir/opiningPDBfile;";
                    system( $copystring );
                }
                elsif ( `grep ERROR $efile` )
                {
                    my $copystring = "mv $file* $config::errorDir/generalError;";
                    system( $copystring );
                }
            }
            print STDERR "     ---- Cleaning grid standard output and error $jobnum files ----\n";
            my $delstring = "rm -f $config::gridOutDir$file*$jobnum;";
            system( $delstring );
        } 
    }
}
#-------------------------------------------------------------------------  


