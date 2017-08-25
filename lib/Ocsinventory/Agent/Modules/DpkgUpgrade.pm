###############################################################################
## PVS pro 
## Abdou TAHRI
## 
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Ocsinventory::Agent::Modules::DpkgUpgrade;
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
	my $name="patch";   #Set the name of your module here

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

sub patch_start_handler { 	#Use this hook to test prerequisites needed by module and disble it if needed
	my $self = shift;
	my $logger = $self->{logger};

	#$logger->debug("Yeah you are in patch_start_handler :)");
	my $prerequisites = 0;
	
	if( can_run("apt-get") ) {
		$prerequisites = 1;
	}
	
	if ( $prerequisites == 0 ) { 
		$self->{disabled} = 1; #Use this to disable the module
		$logger->debug("patch_start_handler: dpkg-query not found... module disable");
	}
}


sub patch_prolog_writer {	#Use this hook to add information the prolog XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in patch_prolog_writer :)");

}


sub patch_prolog_reader {	#Use this hook to read the answer from OCS server
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in patch_prolog_reader :)");

}


sub patch_inventory_handler {		#Use this hook to add or modify entries in the inventory XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in patch_inventory_handler :)");
	
	run($self);

}

sub run {
	my $self = shift;
	my $common = $self->{context}->{common};

	my ($pkg,$oldver,$ver,$tmp,$release,$source);

	open APT,"apt-get -s dist-upgrade 2>&1|" or return 0;
	my (%security,%other);
	while (<APT>) {
		return 0 if /(Could not open lock file)|(Could not get lock)/;
		next unless /^Inst/;
		#Inst update-notifier [0.119ubuntu8.6] (0.119ubuntu8.7 Ubuntu:12.04/precise-updates [amd64]) []
		($pkg,$tmp,$oldver,$ver,$release) = /Inst (.*?)( \[(.*?)\])? \((.*?) (.*?)\)/;
		next unless defined $release;
		$source = 0; 
		$source = 1 if $release =~ /security/i;
		&addPatch($common->{xmltags},{
				'NAME'          => $pkg,
				'VERSION'       => $oldver,
				'NEWVERSION'    => $ver,
				'SOURCE'        => $source
		});
	}
	close APT;

}

sub addPatch {
	my ($xmltags,$args) = @_;
	my $name = $args->{NAME};
	my $oldversion = $args->{VERSION};
	my $newversion = $args->{NEWVERSION};
	my $source = $args->{SOURCE};

	push @{$xmltags->{PATCH}},
	{
		NAME => [$name],
		VERSION => [$oldversion],
		NEWVERSION => [$newversion],
		SOURCE => [$source]
	};
}

sub patch_end_handler {		#Use this hook to add treatments before the end of agent launch
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in patch_end_handler :)");

}

1;
