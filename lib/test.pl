#!/acrm/usr/local/bin/perl

use strict;
use SPECSIM;

my $val;

$val = SPECSIM::GetSpecsim("","","MEAN","MEAN");
print "mean: $val\n";

$val = SPECSIM::GetSpecsim("","","MOUSE","HUMAN");
print "mouse/human: $val\n";

$val = SPECSIM::GetSpecsim("","","MOUSE","HUMAN");
print "mouse/human: $val\n";

