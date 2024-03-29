package PPI::Tinderbox::Task;

=pod

=head1 NAME

PPI::Tinderbox::Task - The main Task class for the PPI CPAN Tinderbox

=head1 DESCRIPTION

This task implements the main set of tests used by the PPI CPAN Tinderbox.

This implements a core set of tests that ensure that at the very least,
the Perl document can be loaded, tokenized, lexed without causing a
memory leak, and is round-trip-safe.

=head1 METHODS

=cut

use strict;
use UNIVERSAL 'isa';
use base 'PPI::Processor::KeyedTask::Ini';
use Time::HiRes    ();
use PPI::Tokenizer ();
use PPI::Lexer     ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.08';
}

# Unlike the general KeyedTask, this CAN autoconstruct
sub autoconstruct { 1 }





#####################################################################
# PPI::Processor::Task Methods

=pod

=head2 new

Unlike the general version, this KeyedTask sets itself up automatically,
and doesn't require any constructor arguments.

As such, the auto-constructor feature is enabled for this module.

Returns a new PPI::Processor::KeyedTask::Ini object, or C<undef> on error.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my %args  = @_;
	$class->SUPER::new(
		%args,
		tasks => {
			'01tokenizer'  => 'PPI::Tinderbox::Task->task_tokenizer',
			'02tokens'     => 'PPI::Tinderbox::Task->task_tokens',
			'03lexer_leak' => 'PPI::Tinderbox::Task->task_lexer_leak',
			'04document'   => 'PPI::Tinderbox::Task->task_document',
			'05unmatched'  => 'PPI::Tinderbox::Task->task_unmatched',
			},
		);
}

sub process_file {
	my ($self, $file, $path) = @_;

	# Anything bigger than 500k we skip, as PPI chokes
	my $size = (stat $file)[7];
	return undef unless defined $size;
	return '' if $size > 500000;

	# Get the start time
	my $start = [ Time::HiRes::gettimeofday() ];

	# Hand off to each of the tasks
	my %tasks   = $self->tasks or return undef;
	my %results = map { $_ => undef } keys %tasks;
	foreach my $task ( sort keys %tasks ) {
		local $_ = $file;
		$results{$task} = $tasks{$task}->( $file, $path );
		last unless defined $results{$task};
	}

	# Save the processing time
	$results{'00total_time'} = sprintf( '%.2d',
		Time::HiRes::tv_interval( $start ),
		);

	# Save the results
	$self->store_file( $path, \%results );	
}

# Can we load the Tokenizer for the file without error
sub task_tokenizer {
	my ($class, $file) = @_;

	# Create the one-shot Tokenizer
	my $Tokenizer = PPI::Tokenizer->load( $file ) or return undef;

	1;	
}

# Can we load file, and pull all the Token ok
sub task_tokens {
	my ($class, $file) = @_;

	# Create the one-shot Tokenizer
	my $Tokenizer = PPI::Tokenizer->load( $file ) or return undef;

	# Pull the tokens and handle errors
	my $Tokens;
	eval {
		$Tokens = $Tokenizer->all_tokens;
	};
	return undef unless $Tokens;

	# Return the number of Tokens found as the result
	scalar @$Tokens;
}

# Do we leak when attempting to create a Document
sub task_lexer_leak {
	my ($class, $file) = @_;

	# Get a count of the number of PARENT keys in the PPI
	# internal PARENT hash.
	my $start = scalar keys %PPI::_ELEMENT;

	# Parse the Document and DESTROY it if it is created
	my $Document = PPI::Document->load( $file ) or return undef;
	$Document->DESTROY;

	# How many refs did we leak?
	my $leak = scalar keys %PPI::_ELEMENT;
	$leak -= $start;

	$leak;
}

# Can the document be parsed into a Document
sub task_document {
	my ($class, $file) = @_;

	# Create the document
	my $Document = PPI::Document->load( $file ) or return undef;
	$Document->DESTROY;

	1;
}

# If we get a document, does it have any unmatched braces
sub task_unmatched {
	my ($class, $file) = @_;

	# Load the Document
	my $Document = PPI::Document->load( $file ) or return undef;
	
	# Can we find any unmatched brace statements
	### NOTE: Yes, we do want this to be zero, not ''
	my $rv = $Document->find_any( 'Statement::UnmatchedBrace' ) ? 1 : 0;
	$Document->DESTROY if $Document;
	$rv;
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PPI%3A%3ATinderbox>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy (Maintainer), L<http://ali.as/>, cpan@ali.as

Funding provided by The Perl Foundation

=head1 COPYRIGHT

Copyright (c) 2004 - 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
