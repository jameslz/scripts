#!/usr/bin/perl -w

use strict;
use warnings;

die "Usage:perl $0  <fasta> <repeatmask> <type:hard|soft>" if(@ARGV != 3);

my ( $fasta,  $repeatmask, $type) = @ARGV;

my %mask_h = ();

load_repeatmask();
repeatmask();

exit;

sub load_repeatmask{

    open( DATA,  $repeatmask ) || die "$!";
    while (<DATA>) {
        next if( $. <= 3);
        my @its = split /\s+/, $_;
        push @{$mask_h{ $its[5] }}, qq{$its[6]\t$its[7]};
    }
    close DATA;

}


sub repeatmask{
    
    open( DATA,         $fasta ) || die "$!";
    local $/ = "\n>";

    while (<DATA>) {
            
            $_ =~ s/^>//;
            chomp;

            my ($head_line, $sequence)  =  split /\n/, $_, 2;
            my ($identifier)  =  $head_line =~ /^(\S+)/;

            print qq{>$_\n} if(! exists $mask_h{$identifier});
            $sequence =~s/\s+//g;
            next if(! exists $mask_h{$identifier});

            print qq{>$head_line\n}, seq_mask($identifier, $sequence), "\n";
            

    }
    local $/="\n";
    close DATA;
}


sub seq_mask{

    my ( $identifier, $seq ) = @_;
    
    my  @base = split //, $seq;

    foreach my $x ( @{$mask_h{$identifier}} ) {
        my @its = split /\t/, $x;
        foreach my $y ( $its[0] .. $its[1] ) {
            $base[ $y-1 ] = ($type eq 'soft') ? lc($base[ $y -1 ]) : 'N';
        }
    }
    
    return seq_width_format( join('', @base) );

}

sub seq_width_format{

    my $val = shift;
    $val =~s/(.{80})/$1\n/g;
    $val =~s/\s+$//;
    return $val;

}