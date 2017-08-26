###############################################################################
## PVS pro
## Abdou TAHRI
##
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Ocsinventory::Agent::Modules::YumUpgrade;
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

	if( can_run("yum") ) {
		$prerequisites = 1;
	}

	if ( $prerequisites == 0 ) {
		$self->{disabled} = 1; #Use this to disable the module
		$logger->debug("patch_start_handler: yum not found... module disable");
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
	my $logger = $self->{logger};

	my ($pkg,$ver,$repo);

	open YUM,"yum -q check-update 2>/dev/null| xargs -n3 |" or return 0;

    	while (<YUM>) {
		next unless /^\S+/;
		#return 0 if /(Could not open lock file)|(Could not get lock)/;
		($pkg,$ver,$repo) = /(\S+)\s+(\S+)\s+(\S+)/;
		if (defined($pkg)) {
			&addPatch($common->{xmltags},{
				'NAME'  	=> $pkg,
		                'VERSION'       => '',
				'NEWVERSION'    => $ver,
				'SOURCE'        => 0
			});
		}
	}
	close YUM;

}

sub addPatch {
	my ($xmltags,$args) = @_;
	my $name = $args->{NAME};
	my $oldversion = $args->{VERSION};
	my $newversion = $args->{NEWVERSION};
	my $source = $args->{SOURCE};
	my $self = shift;
    	foreach my $node ( @{$xmltags->{SOFTWARES}} ) {
		if ( $name eq $node->{NAME}[0]) {
			$oldversion = $node->{VERSION}[0];
			push @{$xmltags->{PATCH}}, {
                		NAME => [$name],
                		VERSION => [$oldversion],
                		NEWVERSION => [$newversion],
                		SOURCE => [$source]
            		};
            	last;
        	}
    	}
}


sub patch_end_handler {		#Use this hook to add treatments before the end of agent launch
	my $self = shift;
	my $logger = $self->{logger};
	$logger->debug("Yeah you are in patch_end_handler :)");
}

1;
