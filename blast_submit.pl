#!/usr/bin/perl  -w

use strict;
use warnings;

die "Usage: perl $0 <blast_type> <task> <database>  <sequence>  <evalue> <outfmt> <max_target_seqs> <project>" unless (@ARGV == 8);

my ($blast_type, $task, $database, $sequence, $evalue, $outfmt, $maxhit, $project) = @ARGV;

my $split   = qq{$project/split};
my $run     = qq{$project/run};
my @batch_t = ();

submit();
exit;


sub submit{

    fs();
    fasta_trunk();
    blast_run();
    merge_submit();
    merge();
    clean();

}

sub fs{

    `mkdir -p  $split $run`;

}

sub fasta_trunk{

    my  $trunk_it       = qq{fasta_trunk.pl $sequence  24  $split\n};
    system $trunk_it;

}


sub blast_run{

    my $itms = `ls  $split/*`;
    foreach my $batch ( split /\n/, $itms ) {
        
        my ($prefix)      = $batch =~ /^(\S+)\./;
        my  $batch_val    = batch_val($batch);
        push @batch_t, $batch_val;
        
        open(EXPORT, ">$run/$batch_val.sh");

        my $blast_run_cmd = qq{$blast_type  
                                   -task            $task
                                   -query           $batch
                                   -db              $database
                                   -out             $prefix.res
                                   -evalue          $evalue
                                   -outfmt          $outfmt
                                   -max_target_seqs $maxhit
                                   -num_threads     1\n};
            $blast_run_cmd    =~ s/\s+/ /msg;
        print  EXPORT qq($blast_run_cmd\n);
        close EXPORT;
    }

}

sub batch_val{
    my $val = shift;
    my @its = split /\//, $val;
    my ($batch_val) = $its[-1] =~/^(.+?)\./;
    return $batch_val;
}

sub merge_submit {   
   
   my $sample_bins       = 1;
   my ($batch, $cnt)     = (1,  0);

   foreach my $it ( @batch_t ) {
       $cnt++;
       if($cnt > $sample_bins ){
          $batch++;
          $cnt  = 1;
       }
       system qq{cat $run/$it.sh >> $run/$batch\_run.sh};
   }
   
   foreach my $b (1 .. $batch ) {

      my $stats     = qq{touch $run/$b\_run.sh.finish\n};
      open( FH, qq{>>$run/$b\_run.sh} ) || die "$!";
      print FH  $stats;
      close  FH;
      system qq{nohup bash  $run/$b\_run.sh >$run/$b\_batch.log &};
   
   } 

   while(1){
      my %batch = ();
      my $cnt   = 0;
      foreach my $b (1 .. $batch) {
          next if(exists $batch{$b});
          next if(! -e  qq{$run/$b\_run.sh.finish});
          $cnt++;
          $batch{$b} = 1;
      }
      last if($cnt == $batch);
   }

   print qq{Finished!\n};

}


sub merge{

    my $res  = ($outfmt eq '5') ? 'xml' : 'tsv';
    my $cat  = qq{cat  $split/*.res  >$project/blast.$res\n};
    print  $cat; system $cat;

}

sub clean{

    my $rm = qq{rm -rf $split\n};
    print  $rm; system $rm;

}