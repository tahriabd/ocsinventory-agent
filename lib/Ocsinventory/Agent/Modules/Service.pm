###############################################################################
## PVS pro 
## Abdou TAHRI
## 
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Ocsinventory::Agent::Modules::Service;
use strict;
use warnings;


my $initdir = '/etc/init.d';
#my $inetddir = '/etc/inetd.d';
#my $xinetddir = '/etc/xinetd.d';

my %to_d = (
  '0' => 'rc0.d', '1' => 'rc1.d', '2' => 'rc2.d', '3' => 'rc3.d',
  '4' => 'rc4.d', '5' => 'rc5.d', 'S' => 'rcS.d', 'B' => 'boot.d'
);


my %skips_rc = map {$_ => 1} qw {rc rx skeleton powerfail boot halt reboot single boot.local halt.local};


my %links = ();
my %known_all = ();


sub can_run {
  my $binary = shift;
  my $calling_namespace = caller(0);
  chomp(my $binpath=`which $binary 2>/dev/null`);
  return unless -x $binpath;
  1;
}

sub new {
	my $name="service";   #Set the name of your module here

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

sub service_start_handler { 	#Use this hook to test prerequisites needed by module and disble it if needed
	my $self = shift;
	my $logger = $self->{logger};

	#$logger->debug("Yeah you are in patch_start_handler :)");
	my $prerequisites = 0;
	
	if( can_run("chkconfig") ) {
		$prerequisites = 1;
	}
	
	if ( $prerequisites == 0 ) { 
		#$self->{disabled} = 1; #Use this to disable the module
		$logger->debug("service_start_handler: chkconfig command not found...");
	}
}


sub service_prolog_writer {	#Use this hook to add information the prolog XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in service_prolog_writer :)");

}


sub service_prolog_reader {	#Use this hook to read the answer from OCS server
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in service_prolog_reader :)");

}


sub service_inventory_handler {		#Use this hook to add or modify entries in the inventory XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in service_inventory_handler :)");
	
	run($self);

}

sub service_end_handler {		#Use this hook to add treatments before the end of agent launch
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in patch_end_handler :)");

}

sub run {
	my $self = shift;
	my $common = $self->{context}->{common};
	my $logger = $self->{logger};

	findknown();
	initlinks_rc();
	
	my $s;
	
	for $s (%known_all) {
		next unless defined $known_all{$s};
		my $l;
		my $status = "Stopped";
		my $startmode = "Manual";
        my $description = $known_all{$s}->{description};
        my $provider = $known_all{$s}->{provider};
        my $pathname = $known_all{$s}->{pathname};
		for $l (0, 1, 2, 3, 4, 5, 6, 'B', 'S') {
			if ($links{$l}->{$s}) {
				$startmode = "Auto";
				$status =  "Running";
				last;
			}
		}
		if (length($s) > 0) {
			&addService($common->{xmltags}, {
				'SVCNAME' => $s,
				'SVCDN' => $provider,
				'SVCSTATE'=> $status,
				'SVCDESC' => $description,
				'SVCSTARTMODE' =>$startmode,
				'SVCPATH' => $pathname,
				'SVCSTARTNAME' => 'root',
				'SVCEXITCODE' => 0,
				'SVCSPECEXITCODE' => 0
			});
		}
	}
}

sub addService {
	my ($xmltags,$args) = @_;
	my $name = $args->{SVCNAME};
	my $dn = $args->{SVCDN};
	my $state = $args->{SVCSTATE};
	my $desc = $args->{SVCDESC};
	my $startmode = $args->{SVCSTARTMODE};
	my $startname = $args->{SVCSTARTNAME};
	my $path = $args->{SVCPATH};
	my $exitcode = $args->{SVCEXITCODE};
	my $specexitcode = $args->{SVCSPECEXITCODE};
	
	push @{$xmltags->{SERVICES}},
	{
		SVCNAME => [$name],
		SVCDN => [$dn],
		SVCSTATE => [$state],
		SVCDESC => [$desc],
		SVCSTARTMODE => [$startmode],
		SVCSTARTNAME => [$startname],
		SVCPATH => [$path],
		SVCEXITCODE => [$exitcode],
		SVCSPECEXITCODE => [$specexitcode]	
	};
}


sub  trim { 
	my $s = shift; 
	$s =~ s/^\s+|\s+$//g; 
	return $s 
}

sub ls {
  my $dir = shift;

  local *D;
  return () unless opendir(D, $dir);
  my @ret = grep {$_ ne '.' && $_ ne '..'} readdir(D);
  closedir D;
  return @ret;
}

sub initlinks_rc {
  my $l;
  for $l (keys %to_d) {
    my @links = grep {s/^S\d\d//} ls("$initdir/../$to_d{$l}");
    $links{$l} = { map {$_ => 1} @links };
  }
}

sub findknown {
  for (ls($initdir)) {
    next unless -f "$initdir/$_";
    next if /^README/ || /^core/;
    next if /~$/ || /^[\d\$\.#_\-\\\*]/ || /\.(rpm|ba|old|new|save|swp|core)/;
	getInfos("$_");
  }
}

sub getInfos {
	my $file = shift;
	my $filepath = "$initdir/$file";
	return unless -f $filepath;
	open my $fh, '<:encoding(UTF-8)', $filepath or die;
	$known_all{$file}->{description} = "";
	$known_all{$file}->{provider} = "";
	$known_all{$file}->{pathname} = $filepath;
	while (my $line = <$fh>) {
		chomp($line);
		if ($line =~ s/^# Provides: //) {
			$known_all{$file}->{provider} = trim($line);		
		}
		if ($line =~ s/^# Short-Description: //) {
			$known_all{$file}->{description}= $line;
			last;
        	}
    	}
	close $fh;
}

1;
