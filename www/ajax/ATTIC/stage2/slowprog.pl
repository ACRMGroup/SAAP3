#!/acrm/usr/local/bin/perl

my($processID, $sprotID, $native, $resnum, $mutant) = @ARGV;
$|=1;

sleep 10;
print "SPROT $sprotID\n";

sleep 10;
print "NATIVE $native\n";
sleep 10;
print "RESNUM $resnum\n";
sleep 10;
print "MUTANT $mutant\n";
sleep 10;
print "END\n";
__EOF


