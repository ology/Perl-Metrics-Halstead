package Perl::Metrics::Halstead;

# ABSTRACT: Compute Halstead complexity metrics

our $VERSION = '0.0100';

use Moo;
use strictures 2;
use namespace::clean;

use PPI::Document;
use PPI::Dumper;

=head1 SYNOPSIS

  use Perl::Metrics::Halstead;

  my $pmh = Perl::Metrics::Halstead->new(file => '/some/perl/code.pl');

  printf "Total operators = %d, Total operands = %d\n", $pmh->n_operators, $pmh->n_operands;
  printf "Distinct operators = %d, Distinct operands = %d\n", $pmh->n_distinct_operators, $pmh->n_distinct_operands;
  printf "Program vocabulary = %d, Program length = %d\n", $pmh->prog_vocab, $pmh->prog_length;
  printf "Estimated program length = %.3f\n", $pmh->est_prog_length;
  printf "Program volume = %.3f\n", $pmh->volume;
  printf "Program difficulty = %.3f\n", $pmh->difficulty;
  printf "Program level = %.3f\n", $pmh->level;
  printf "Program effort = %.3f\n", $pmh->effort;
  printf "Time to program = %.3f\n", $pmh->time_to_program;
  printf "Delivered bugs = %.3f\n", $pmh->delivered_bugs;

=head1 DESCRIPTION

C<Perl::Metrics::Halstead> computes Halstead complexity metrics.

=head1 ATTRIBUTES

=head2 file

  $file = $pmh->file;

The file to analyze.  This is a required attribute.

=cut

has file => (
    is       => 'ro',
    required => 1,
);

=head2 n_operators

  $n_operators = $pmh->n_operators;

The total number of operators.  This is a computed attribute.

=cut

has n_operators => (
    is       => 'ro',
    init_arg => undef,
);

=head2 n_operands

  $n_operands = $pmh->n_operands;

The total number of operators.  This is a computed attribute.

=cut

has n_operands => (
    is       => 'ro',
    init_arg => undef,
);

=head2 n_distinct_operators

  $n_distinct_operators = $pmh->n_distinct_operators;

The number of distinct operators.  This is a computed attribute.

=cut

has n_distinct_operators => (
    is       => 'ro',
    init_arg => undef,
);

=head2 n_distinct_operands

  $n_distinct_operands = $pmh->n_distinct_operands;

The number of distinct operators.  This is a computed attribute.

=cut

has n_distinct_operands => (
    is       => 'ro',
    init_arg => undef,
);

=head2 prog_vocab

  $prog_vocab = $pmh->prog_vocab;

The program vocabulary.  This is a computed attribute.

=cut

has prog_vocab => (
    is       => 'ro',
    init_arg => undef,
);

=head2 prog_length

  $prog_length = $pmh->prog_length;

The program length.  This is a computed attribute.

=cut

has prog_length => (
    is       => 'ro',
    init_arg => undef,
);

=head2 est_prog_length

  $est_prog_length = $pmh->est_prog_length;

The estimated program length.  This is a computed attribute.

=cut

has est_prog_length => (
    is       => 'ro',
    init_arg => undef,
);

=head2 volume

  $volume = $pmh->volume;

The program volume.  This is a computed attribute.

=cut

has volume => (
    is       => 'ro',
    init_arg => undef,
);

=head2 difficulty

  $difficulty = $pmh->difficulty;

The program difficulty.  This is a computed attribute.

=cut

has difficulty => (
    is       => 'ro',
    init_arg => undef,
);

=head2 level

  $level = $pmh->level;

The program level.  This is a computed attribute.

=cut

has level => (
    is       => 'ro',
    init_arg => undef,
);

=head2 effort

  $effort = $pmh->effort;

The program effort.  This is a computed attribute.

=cut

has effort => (
    is       => 'ro',
    init_arg => undef,
);

=head2 time_to_program

  $time_to_program = $pmh->time_to_program;

The time to program.  This is a computed attribute.

=cut

has time_to_program => (
    is       => 'ro',
    init_arg => undef,
);

=head2 delivered_bugs

  $delivered_bugs = $pmh->delivered_bugs;

Delivered bugs.  This is a computed attribute.

=cut

has delivered_bugs => (
    is       => 'ro',
    init_arg => undef,
);

=head1 METHODS

=head2 new()

  $pmh = Perl::Metrics::Halstead->new(file => $file);

Create a new C<Perl::Metrics::Halstead> object given the B<file> argument.

=head2 BUILD()

Process the given B<file> into the computed metrics.

=cut

sub BUILD {
    my ( $self, $args ) = @_;

    my $doc = PPI::Document->new( $self->file );

    my $dump = PPI::Dumper->new( $doc, whitespace => 0 );

    my %halstead;

    for my $item ( $dump->list ) {
        $item =~ s/^\s*//;
        $item =~ s/\s*$//;
        my @item = split /\s+/, $item, 2;
        next unless defined $item[1];
        push @{ $halstead{ $item[0] } }, $item[1];
    }

    $self->{n_operators} = 0;
    $self->{n_operands}  = 0;

    for my $key ( keys %halstead ) {
        if ( _is_operator($key) ) {
            $self->{n_operators} += @{ $halstead{$key} };
        }
        else {
            $self->{n_operands} += @{ $halstead{$key} };
        }
    }

    my %distinct;

    for my $key ( keys %halstead ) {
        for my $item ( @{ $halstead{$key} } ) {
            if ( _is_operator($key) ) {
                $distinct{operands}->{$item} = undef;
            }
            else {
                $distinct{operators}->{$item} = undef;
            }
        }
    }

    $self->{n_distinct_operators} = keys %{ $distinct{operators} };
    $self->{n_distinct_operands}  = keys %{ $distinct{operands} };

    $self->{prog_vocab} = $self->{n_distinct_operators} + $self->{n_distinct_operands};

    $self->{prog_length} = $self->{n_operators} + $self->{n_operands};

    $self->{est_prog_length} = $self->{n_distinct_operators} * _log2($self->{n_distinct_operators})
        + $self->{n_distinct_operands} * _log2($self->{n_distinct_operands});

    $self->{volume} = $self->{prog_length} * _log2($self->{prog_vocab});

    $self->{difficulty} = ($self->{n_distinct_operators} / 2)
        * ($self->{n_operands} / $self->{n_distinct_operands});

    $self->{level} = 1 / $self->{difficulty};

    $self->{effort} = $self->{difficulty} * $self->{volume};

    $self->{time_to_program} = $self->{effort} / 18; # seconds

    $self->{delivered_bugs} = ($self->{effort} ** (2/3)) / 3000;
}

sub _is_operator {
    my $key = shift;
    return $key eq 'PPI::Token::Comment'
        || $key eq 'PPI::Token::Number'
        || $key eq 'PPI::Token::Symbol'
        || $key =~ /Quote/;
}

sub _log2 {
    my $n = shift;
    return log($n) / log(2);
}

1;
__END__

=head1 SEE ALSO

L<Moo>

L<PPI::Document>

L<PPI::Dumper>

L<https://en.wikipedia.org/wiki/Halstead_complexity_measures>

L<https://www.verifysoft.com/en_halstead_metrics.html>

=cut
