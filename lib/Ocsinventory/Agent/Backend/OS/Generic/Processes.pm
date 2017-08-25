package Ocsinventory::Agent::Backend::OS::Generic::Processes;
use strict;

sub check {can_run("ps")}

sub run {
    my $params = shift;
    my $common = $params->{common};

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
    	   open(PS, "ps aux|");
    }

    while ($line = <PS>) {
        next if ($. ==1);
        if ($line =~
            /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*?)\s*$/){
            my $user = $1;
            my $pid= $2;
            my $cpu= $3;
            my $mem= $4;
            my $vsz= $5;
            my $tty= $7;
            my $started= $9;
            my $time= $10;
            my $cmd= $11;

            if ($started =~ /^(\w{3})/)  {
                my $d=substr($started, 3);
                my $m=substr($started, 0,3);
                $begin=$the_year."-".$month{$m}."-".$d." ".$time; 
            }  else {
                $begin=$the_year."-".$mon."-".$mday." ".$started;
            }

            $common->addProcess({
                    'USER' => $user,
                    'PID' => $pid,
                    'CPUUSAGE' => $cpu,
                    'MEM' => $mem,
                    'VIRTUALMEMORY' => $vsz,
                    'TTY' => $tty,
                    'STARTED' => $begin,
                    'CMD' => $cmd
                });
        }
    }
    close(PS); 
}

1;
