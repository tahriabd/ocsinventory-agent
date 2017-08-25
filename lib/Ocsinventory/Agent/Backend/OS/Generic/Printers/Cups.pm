package Ocsinventory::Agent::Backend::OS::Generic::Printers::Cups;
use strict;

sub check {
    # If we are on a MAC, Mac::SysProfile will do the job
    return if -r '/usr/sbin/system_profiler';
    return unless can_load("Net::CUPS");
    return 1;
}

sub run {
    my $params = shift;
    my $common = $params->{common};

    my $cups = Net::CUPS->new();
    my $printer = $cups->getDestination();

    return unless $printer;

    # Just grab the default printer, is I use getDestinations, CUPS
    # returns all the printer of the local subnet (is it can)
    # TODO There is room for improvement here
    $common->addPrinter({
            NAME    => $printer->getName(),
            DESCRIPTION => $printer->getDescription(),
#                DRIVER =>  How to get the PPD?!!
        });

}
1;
