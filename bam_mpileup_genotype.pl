#!/usr/bin/perl -w

use strict;
use warnings;

die "Usage:perl $0  <fasta>  <bam>  <mini_support>" if(@ARGV != 3);

my ($fasta, $bam, $mini_support) = @ARGV;


my @base = ();

load_fasta();
mpileup_parser();

sub mpileup_parser{
    
    open( DATA,       qq{samtools mpileup $bam |}) || die "$!";

    while (<DATA>) {
        
        my @its = split /\t/, $_;
        my $pat = uc($its[4]);
        
        my %val   = ();
        my @count = ();
        my $ref   = $base[$its[1] - 1];

        foreach my $x (split //, $pat) {
            $val{$x}++;
        }

        my $flag         = 0;

        foreach my $x (qw/A T C G/) {
            
            my $v = (exists $val{$x}) ? $val{$x} : 0;
            push @count, qq{$x=$v};
            
           if( ($x ne $ref) and ($v >= $mini_support) ){
               $flag = 1;
            }

        }

        if( $flag == 1 ){
           printf qq{%s\t.\tMutation\t%d\t%d\t.\t+\t.\tID=%d; Ref=$ref; %s\n} , ($its[0], $its[1], $its[1], $its[1],  join('; ', @count)); 
        }    

    }
}

sub load_fasta{

    open( DATA,         $fasta ) || die "$!";
    local $/ = "\n>";

    while (<DATA>) {
            $_ =~ s/^>//;
            $_ =~ s/\s+$//msg;
            chomp;
            my ($head_line, $sequence)  =  split /\n/, $_, 2;
            $sequence =~s/\s+//g;
            @base     = split //, $sequence;
    }
    local $/="\n";
    close DATA;

}