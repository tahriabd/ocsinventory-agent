package Ocsinventory::Agent::Backend::OS::Generic::Packaging::Deb;

use strict;
use warnings;

sub check { can_run("dpkg") }

sub run {
  my $params = shift;
  my $common = $params->{common};
  
# use dpkg-query --show --showformat='${Package}|||${Version}\n'
  foreach(`dpkg-query --show --showformat='\${Package}---\${Version}---\${Installed-Size}---\${Description}\n'`) {
     if (/^(\S+)---(\S+)---(\S+)---(.*)/) {     	     	
       $common->addSoftware ({
         'NAME'          => $1,
         'VERSION'       => $2,
         'FILESIZE'      => $3,
         'COMMENTS'      => $4,
         'FROM'          => 'deb'
       });
    }
  }
}

1;
