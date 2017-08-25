###############################################################################
## PVS pro 
## Abdou TAHRI
## 
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Ocsinventory::Agent::Modules::Reboot;
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
	my $name="reboot";   #Set the name of your module here

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
		start_handler => undef,    #or undef if don't use this hook 
		prolog_writer => undef,    #or undef if don't use this hook  
		prolog_reader => undef,    #or undef if don't use this hook  
		inventory_handler => $name."_inventory_handler",    #or undef if don't use this hook 
		end_handler => undef   #or undef if don't use this hook 
	};

	bless $self;
}

######### Hook methods ############
sub reboot_start_handler { 	#Use this hook to test prerequisites needed by module and disble it if needed
	my $self = shift;
	my $logger = $self->{logger};
	$logger->debug("Yeah you are in reboot_start_handler");
}

sub reboot_prolog_writer {	#Use this hook to add information the prolog XML
	my $self = shift;
	my $logger = $self->{logger};
	$logger->debug("Yeah you are in reboot_prolog_writer :)");
}

sub reboot_prolog_reader {	#Use this hook to read the answer from OCS server
	my $self = shift;
	my $logger = $self->{logger};
	$logger->debug("Yeah you are in reboot_prolog_reader :)");
}

sub reboot_inventory_handler {		#Use this hook to add or modify entries in the inventory XML
	my $self = shift;
	my $logger = $self->{logger};
	$logger->debug("Yeah you are in reboot_inventory_handler :)");
	run($self);

}

sub run {
	my $self = shift;
	my $common = $self->{context}->{common};
	my $logger = $self->{logger};

	my $activekernel;
	chomp($activekernel =`uname -r`);
	return if ($activekernel eq "");

	my $newkernel;
	chomp($newkernel = `ls -t /boot/vmlinuz-* 2>/dev/null|head -1`);
	return if($newkernel eq "");
	$newkernel =~ s/\/boot\/vmlinuz-//g;

	my $reboot = 0;
	if ($newkernel ne $activekernel) {
		$reboot = 1;
		$activekernel = $newkernel;
	}
	&addReboot($common->{xmltags}, {	
		'REQUIRED' => $reboot,
		'VERSION' => $activekernel
	});
}


sub addReboot {
	my ($xmltags,$args) = @_;
	my $ocsreboot = $args->{REQUIRED};
	my $ocsversion = $args->{VERSION};

	push @{$xmltags->{REBOOT}},
	{
		REQUIRED => [$ocsreboot],
		OSVERSION => [$ocsversion]
	};
}


sub reboot_end_handler {		#Use this hook to add treatments before the end of agent launch
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in reboot_end_handler :)");

}

1;
