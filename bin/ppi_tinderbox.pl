#!/usr/bin/perl

# First implementation of the CPAN Tinderbox

use PPI::Processor;
use CPAN::Processor;

# Create the PPI::Processor object
my $Processor = PPI::Processor->new(
	source => './tinderbox',
	);
$Processor->add_task( 
