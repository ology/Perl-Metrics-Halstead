#!/usr/bin/env perl
# PODNAME: halstead.pl
use strict;
use warnings;

use Perl::Metrics::Halstead;
use Getopt::Long;
use Pod::Usage;

my $metric = 'effort';
my $report = 0;
my $prec   = 2;
my $help   = 0;
my $man    = 0;

GetOptions(
    'metric|m=s'    => \$metric,
    'report|r'      => \$report,
    'precision|p=i' => \$prec,
    'help|?'        => \$help,
    'man'           => \$man,
) or pod2usage(2);

pod2usage(1) if $help || !@ARGV;
pod2usage( -exitval => 0, -verbose => 2 ) if $man;

die "Invalid Halstead metric: $metric\n"
    unless Perl::Metrics::Halstead->can($metric);

my @packages = @ARGV;

my @scores;

my $width = length scalar @packages;

my $i = 0;

# Compute Halstead for each given file.
for my $file (@packages) {
    unless ( -e $file ) {
        warn "File $file does not exist.\n";
        next;
    }

    if ( $report ) {
        $i++;
        print "\t$i. Processing $file:\n";
    }

    my $m;
    eval {
        $m = Perl::Metrics::Halstead->new( file => $file )
    };
    if ( $@ ) {
        warn "$@\n";
        next;
    }

    if ( $report ) {
        $m->report($prec);
    }
    else {
        push @scores, [ $file, $m->$metric ] if $metric && $m;
    }
}

if ( @scores ) {
    # Output the sorted file list.
    my $n = 0;
    for my $i ( sort { $a->[1] <=> $b->[1] } @scores ){
        printf "%*d. %.4f %s\n", $width, ++$n, $i->[1], $i->[0];
    }
}

__END__

=head1 SYNOPSIS

  halstead [--options] /some/perl/file.pl [/some/perl/Module.pm ...]

=head1 DESCRIPTION

Analyze the Halstead complexity of Perl code.

=head1 OPTIONS

=head2 metric

  --metric effort

The Halstead sorted metric.  If not specified on the command line, a metric of
C<effort> is used.

Possible metrics:

  effort
  difficulty
  volume
  level
  lang_level
  intel_content
  time_to_program
  delivered_bugs

=head2 report

  --report

Output a Halstead report for each given file instead of a single C<--metric>.

=head2 precision

  --prec 4

Specify the decimal precision to use for report numbers.

=head1 SEE ALSO

L<Getopt::Long>

L<Pod::Usage>

=cut
