package Ocsinventory::Agent::Backend::OS::Generic::Packaging::Gentoo;

use strict;
use warnings;

sub check {can_run("equery")}

sub run {
  my $params = shift;
  my $common = $params->{common};

# TODO: This had been rewrite from the Linux agent _WITHOUT_ being checked!
  foreach (`equery list -i`){
    if (/^([a-z]\w+-\w+\/\.*)-([0-9]+.*)/) {
      $common->addSoftware({
	  'NAME'          => $1,
	  'VERSION'       => $2,
	  });
    }
  }
}

1;
