###############################################################################
## PVS pro 
## Abdou TAHRI
## 
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Ocsinventory::Agent::Modules::Dpkg;
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
	my $name="dpkg";   #Set the name of your module here

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

sub dpkg_start_handler { 	#Use this hook to test prerequisites needed by module and disble it if needed
	my $self = shift;
	my $logger = $self->{logger};

	#$logger->debug("Yeah you are in dpkg_start_handler :)");
	my $prerequisites = 0;
	
	if( can_run("dpkg-query") ) {
		$prerequisites = 1;
	}
	
	if ( $prerequisites == 0 ) { 
		$self->{disabled} = 1; #Use this to disable the module
		$logger->debug("dpkg_start_handler: dpkg-query not found... module disable");
	}
}


sub dpkg_prolog_writer {	#Use this hook to add information the prolog XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in dpkg_prolog_writer :)");

}


sub dpkg_prolog_reader {	#Use this hook to read the answer from OCS server
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in dpkg_prolog_reader :)");

}


sub dpkg_inventory_handler {		#Use this hook to add or modify entries in the inventory XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in dpkg_inventory_handler :)");
	
	run($self);

}


sub run {

	my $self = shift;
	my $common = $self->{context}->{common};

	my @arr = @{$common->{xmltags}->{SOFTWARES}};
	my @indexes = grep { $arr[$_]->{FROM}[0] eq "deb" } (keys @arr);
	my $item;
	foreach $item (@indexes) {
		delete $common->{xmltags}->{SOFTWARES}[$item];
	}
	
	@{$common->{xmltags}->{SOFTWARES}} = grep defined, @{$common->{xmltags}->{SOFTWARES}};
	
	opendir(D, "/var/lib/dpkg/info");
	my @files = readdir(D);
	closedir(D);
	foreach(`dpkg-query -W -f='\${Package}---\${Version}---\${Source}---\${Status}---\${Installed-Size}---\${Description}\n'`) {
		if(/^(\S+)---(\S+)---(.*)---(.*)---(\S+)---(.*)/) {
			my $install = $4;
			my $pkg=$1;
			my $version=$2;
			my $source=($3 eq "") ? $1 : $3;
			my $size=$5;
			my $desc=$6;
			my $installdate;	
			my @filename = grep { $_ =~ /^\Q$pkg\E(:\w+)?.list$/ }  @files;
			if (@filename) {
				my $filename = "/var/lib/dpkg/info/@filename";
				my $mtime = (stat($filename))[9];
				$installdate = strftime( "%Y-%m-%d %H:%M:%S", localtime( $mtime ) );
			}
			if( $install =~ m/^install /i ) {
				$source =~ s/ (\S+)//g;
				&addSoftware ($common->{xmltags},{
					'NAME'          => $pkg,
					'VERSION'       => $version,
					'PACKNAME'      => $source,
					'FILESIZE'      => $size,
					'COMMENTS'      => $desc,
					'INSTALLDATE'   => $installdate,
					'FROM'          => 'deb'
				});
			}
		}
	}
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
		NAME => [$ocsname],
		VERSION => [$ocsversion],
		PACKNAME => [$ocspackname],
		FILESIZE => [$ocsfilesize],
		COMMENTS => [$ocscomments],
		INSTALLDATE => [$ocsinstalldate],
		FROM => [$ocsfrom]
	};
}

sub dpkg_end_handler {		#Use this hook to add treatments before the end of agent launch
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in dpkg_end_handler :)");

}

1;
