###############################################################################
## PVS pro 
## Abdou TAHRI
## 
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Ocsinventory::Agent::Modules::LSB;
use strict;
use warnings;

sub can_run {
  my $binary = shift;
  my $calling_namespace = caller(0);
  chomp(my $binpath=`which $binary 2>/dev/null`);
  return unless -x $binpath;
  1;
}

sub new {
	my $name="lsb";   #Set the name of your module here

	my (undef,$context) = @_;
	my $self = {};

	#Create a special logger for the module
	$self->{logger} = new Ocsinventory::Logger ({
		config => $context->{config}
	});

	$self->{logger}->{header}="[$name]";

	$self->{context}=$context;

	$self->{structure}= {
		name => $name,
		start_handler => $name."_start_handler",    #or undef if don't use this hook 
		prolog_writer => undef,    #or undef if don't use this hook  
		prolog_reader => undef,    #or undef if don't use this hook  
		inventory_handler => $name."_inventory_handler",    #or undef if don't use this hook 
		end_handler => undef   #or undef if don't use this hook 
	};

	bless $self;
}



######### Hook methods ############

sub lsb_start_handler { 	#Use this hook to test prerequisites needed by module and disble it if needed
	my $self = shift;
	my $logger = $self->{logger};

	#$logger->debug("Yeah you are in lsb_start_handler :)");
	my $prerequisites = 0;
	
	if( can_run("lsb_release") ) {
		$prerequisites = 1;
	}
	
	if ( $prerequisites == 0 ) { 
		$self->{disabled} = 1; #Use this to disable the module
		$logger->debug("lsb_start_handler: dpkg-query not found... module disable");
	}
}


sub lsb_prolog_writer {	#Use this hook to add information the prolog XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in lsb_prolog_writer :)");

}


sub lsb_prolog_reader {	#Use this hook to read the answer from OCS server
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in lsb_prolog_reader :)");

}


sub lsb_inventory_handler {		#Use this hook to add or modify entries in the inventory XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in lsb_inventory_handler :)");
	
	run($self);

}


sub run {

	my $self = shift;
	my $common = $self->{context}->{common};
	my $logger = $self->{logger};

	my $release = undef;
	my $codename = undef;
	
	foreach (`lsb_release -cd`) {
	  $release = $1 if /Description:\s+(.*)/;
	  $codename = "($1)" if /Codename:\s+(.+)/;
	}
	if ($release !~ /$codename/) {
	 $release = $release ." ". $codename;
	}
	
	my $OSComment;
	chomp($OSComment =`uname -v`);
	
	&setHardware($common->{xmltags},{
	  OSNAME => $release,
	  OSCOMMENTS => "$OSComment"
	});

}

sub setHardware {
  my ($xmltags, $args) = @_;

  foreach my $key (qw/USERID OSVERSION PROCESSORN OSCOMMENTS CHECKSUM
    PROCESSORT NAME PROCESSORS SWAP ETIME TYPE OSNAME IPADDR WORKGROUP
    DESCRIPTION MEMORY UUID DNS LASTLOGGEDUSER
    DATELASTLOGGEDUSER DEFAULTGATEWAY VMSYSTEM/) {

    if (exists $args->{$key}) {
      $xmltags->{'HARDWARE'}{$key}[0] = $args->{$key};
    }
  }
}

sub lsb_end_handler {		#Use this hook to add treatments before the end of agent launch
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in lsb_end_handler :)");

}

1;
