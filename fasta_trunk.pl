#!/usr/bin/perl -w

use strict;
use warnings;

die "Usage: perl $0 <fasta> <trunk_values> <export>" unless (@ARGV == 3);

my ($fasta, $trunk_values, $export) = @ARGV;

fasta_trunk($fasta, $trunk_values, $export);

exit;

sub fasta_trunk {

	my ($fasta, $trunk_values, $export) = @_; 

	my $capacity = get_capacity($fasta, $trunk_values);
	my $prefix   = 'blast_';
	my ( $i, $j ) = ( 1, 1 );

	system("mkdir -p  $export");

	open( DATA, $fasta) || die "$!";
	local $/ = "\n>";

	open( EXPORT, ">$export/$prefix$j.fa" ) || die "$!";
	while (<DATA>) {
		chomp;
		$_ =~ s/^>//;
		
		if ( ( $i / $capacity ) > $j ) {
			close EXPORT;
			$j++;
			open( EXPORT, ">$export/$prefix$j.fa" ) || die "$!";
		}
		print EXPORT ">$_\n";
		$i++;
	}
	local $/ = "\n";
	close EXPORT;
	close DATA;
}

sub get_capacity{

	my ($fasta, $trunk_values) = @_; 

	my $number_info   = `grep ">" $fasta | wc `;
	   $number_info   =~ s/^\s+//;

	my ($gene_number) = $number_info =~ /^(\d+)/;
	my  $capacity     = int( $gene_number / $trunk_values ) + 1;

	return $capacity;

}
