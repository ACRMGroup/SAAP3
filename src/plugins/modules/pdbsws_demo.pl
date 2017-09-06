#!/acrm/usr/local/bin/perl

use strict;
use PDBSWS;

my $resnum1 = 40;
my $resnum2 = 45;
my $sprotid = "LYSC_CHICK";


my($pdb1, $pdbresnum1) = GetPDBData($resnum1, $sprotid);
my($pdb2, $pdbresnum2) = GetPDBData($resnum2, $sprotid);

#print "$pdb1 $pdbresnum1 $pdbresnum2\n";

my $pdbfile = "/acrm/data/pdb/pdb" . $pdb1 . ".ent";
my $result = `pdbdist $pdbresnum1 $pdbresnum2 $pdbfile`;
print ">>$pdbfile $pdbresnum1 $pdbresnum2\n";
print $result;

sub GetPDBData
{
    my ($resnum, $sprotid) = @_;

    my %result = PDBSWS::IDQuery($sprotid, $resnum);

#foreach my $key (keys(%result))
#{
#    print "$key $result{$key}\n";
#}

    my $pdbcode   = $result{'PDB'};
    my $pdbresnum = $result{'CHAIN'} . $result{"RESID"};

    return($pdbcode, $pdbresnum);
}


# my @fields = split;
# $sprotid = shift @fields;
# shift @fields;
# 
# $nfields = int(@fields);
# for($i=0; $i<$nfields; $i++)
# {
#     for($j=$i+1; $j<$nfields; $j++)
#     {
#     }
# }

    
