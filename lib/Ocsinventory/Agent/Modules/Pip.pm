###############################################################################
## PVS pro 
## Abdou TAHRI
## 
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Ocsinventory::Agent::Modules::Pip;
use strict;
use warnings;
use POSIX qw(strftime);

sub can_run {
    my $binary = shift;
    my $calling_namespace = caller(0);
    chomp(my $binpath=`which $binary 2>/dev/null`);
    return unless -x $binpath;
    1;
}

sub new {
	my $name="pip";   #Set the name of your module here

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

sub pip_start_handler { 	#Use this hook to test prerequisites needed by module and disble it if needed
	my $self = shift;
	my $logger = $self->{logger};

	#$logger->debug("Yeah you are in pip_start_handler :)");
	my $prerequisites = 0;
	
	if( can_run("pip") ) {
		$prerequisites = 1;
	}
	
	if ( $prerequisites == 0 ) { 
		$self->{disabled} = 1; #Use this to disable the module
		$logger->debug("pip_start_handler: pip not found... module disable");
	}
}


sub pip_prolog_writer {	#Use this hook to add information the prolog XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in pip_prolog_writer :)");

}


sub pip_prolog_reader {	#Use this hook to read the answer from OCS server
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in pip_prolog_reader :)");

}


sub pip_inventory_handler {		#Use this hook to add or modify entries in the inventory XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in pip_inventory_handler :)");
	
	run($self);

}


sub run {

	my $self = shift;
	my $common = $self->{context}->{common};
	my $pipversion;
	chomp($pipversion = `pip -V`);
	#$pippath =~ s/pip\s(\S+)\sfrom\s(.*)(\s\(.*\)?)//g;
	open PIP,"pip list 2>&1|" or return 0;
	my ($module,$version);
	while (<PIP>) {	
		return 0 if /(Could not open lock file)|(Could not get lock)/;
		next unless /^(\S+)\s\((\S+)\)/;
		($module,$version) = /(\S+)\s\((\S+)\)/;
		next unless defined $module;
		&addSoftware($common->{xmltags},{
			'NAME'          => $module,
			'VERSION'       => $version,
			'PACKNAME'      => undef,
			'FILESIZE'      => 0,
			'COMMENTS'      => undef,
			'INSTALLDATE'   => undef,
			'FROM'          => 'pip'
		});		
	}
	close PIP;
}

sub addSoftware {
	my ($xmltags,$args) = @_;
	my $ocsname = $args->{NAME};
	my $ocsversion = $args->{VERSION};
	my $ocspackname = $args->{PACKNAME};
	my $ocsfilesize = $args->{FILESIZE};
	my $ocscomments = $args->{COMMENTS};
	my $ocsinstalldate = $args->{INSTALLDATE};
	my $ocsfrom = $args->{FROM};

	push @{$xmltags->{SOFTWARES}},
	{
		NAME        => [$ocsname],
		VERSION     => [$ocsversion],
		PACKNAME    => [$ocspackname],
		FILESIZE    => [$ocsfilesize],
		COMMENTS    => [$ocscomments],
		INSTALLDATE => [$ocsinstalldate],
		FROM        => [$ocsfrom]
	};
}

sub pip_end_handler {		#Use this hook to add treatments before the end of agent launch
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in pip_end_handler :)");

}

1;
