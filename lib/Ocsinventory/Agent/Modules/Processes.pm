###############################################################################
## PVS Pro
## Abdou TAHRI
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Ocsinventory::Agent::Modules::Processes;
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
	my $name="processes";   #Set the name of your module here

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

sub processes_start_handler { 	#Use this hook to test prerequisites needed by module and disble it if needed
	my $self = shift;
	my $logger = $self->{logger};

	#$logger->debug("Yeah you are in processes_start_handler :)");
	my $prerequisites = 0;
	
	if( can_run("pip") ) {
		$prerequisites = 1;
	}
	
	if ( $prerequisites == 0 ) { 
		$self->{disabled} = 1; #Use this to disable the module
		$logger->debug("processes_start_handler: pip not found... module disable");
	}
}


sub processes_prolog_writer {	#Use this hook to add information the prolog XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in processes_prolog_writer :)");

}


sub processes_prolog_reader {	#Use this hook to read the answer from OCS server
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in processes_prolog_reader :)");

}


sub processes_inventory_handler {		#Use this hook to add or modify entries in the inventory XML
	my $self = shift;
	my $logger = $self->{logger};

	$logger->debug("Yeah you are in processes_inventory_handler :)");
	
	run($self);

}

######### Hook methods ############

sub run {

    my $self = shift;
    my $logger = $self->{logger};

    my $common = $self->{context}->{common};
	
    $logger->debug("Yeah you are in Processes_inventory_handler:)");
	delete $common->{xmltags}->{PROCESSES};
    # test if ps command is available :)
    sub check {can_run("ps")}

    my $line;
    my $begin;
    my %month = (
        'Jan' => '01',
        'Feb' => '02',
        'Mar' => '03',
        'Apr' => '04',
        'May' => '05',
        'Jun' => '06',
        'Jul' => '07',
        'Aug' => '08',
        'Sep' => '09',
        'Oct' => '10',
        'Nov' => '11',
        'Dec' => '12',
    );
	
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $the_year=$year+1900;

    my $os;
    chomp($os=`uname -s`);

    if ($os eq "SunOS") {
           open(PS, "ps -A -o user,pid,pcpu,pmem,vsz,rss,tty,s,stime,time,comm|");
    } else {
           open(PS, "ps ax -o user,pid,%cpu,%mem,vsz,tty,stat,lstart=,command|");
    }

    while ($line = <PS>) {
        next if ($. ==1 or $line =~ /user,pid/);
        if ($line =~
            /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)$/){
            my $user = $1;
            my $pid= $2;
            my $cpu= $3;
            my $mem= $4;
            my $vsz= $5;
            my $tty= $6;
            $begin=$12."-".$month{$9}."-".sprintf("%02d",$10)." ".$11;
            my $cmd= $13;
            push @{$common->{xmltags}->{PROCESSES}},
            {
                    USER            => $user,
                    PID             => $pid,
                    CPUUSAGE        => $cpu,
                    MEM             => $mem,
                    VIRTUALMEMORY   => $vsz,
                    TTY             => $tty,
                    STARTED         => $begin,
                    CMD             => $cmd
            };
        }
    }
    close(PS);
}

1;
