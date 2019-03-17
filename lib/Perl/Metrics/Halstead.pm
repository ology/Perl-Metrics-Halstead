package Perl::Metrics::Halstead;

# ABSTRACT: Compute Halstead complexity metrics

our $VERSION = '0.0204';

use Moo;
use strictures 2;
use namespace::clean;

use PPI::Document;
use PPI::Dumper;

=head1 SYNOPSIS

  use Perl::Metrics::Halstead;

  my $pmh = Perl::Metrics::Halstead->new(file => '/some/perl/code.pl');

  $pmh->dump;

=head1 DESCRIPTION

C<Perl::Metrics::Halstead> computes Halstead complexity metrics.

Please see the explanatory links in the L</"SEE ALSO"> section for descriptions
of what these attributes mean and how they are computed.

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

=head2 n_operands

  $n_operands = $pmh->n_operands;

The total number of operators.  This is a computed attribute.

=head2 n_distinct_operators

  $n_distinct_operators = $pmh->n_distinct_operators;

The number of distinct operators.  This is a computed attribute.

=head2 n_distinct_operands

  $n_distinct_operands = $pmh->n_distinct_operands;

The number of distinct operators.  This is a computed attribute.

=cut

has [qw(
    n_operators
    n_operands
    n_distinct_operators
    n_distinct_operands
)] => (
    is       => 'ro',
    init_arg => undef,
);

=head2 prog_vocab

  $prog_vocab = $pmh->prog_vocab;

The program vocabulary.  This is a computed attribute.

=head2 prog_length

  $prog_length = $pmh->prog_length;

The program length.  This is a computed attribute.

=head2 est_prog_length

  $est_prog_length = $pmh->est_prog_length;

The estimated program length.  This is a computed attribute.

=head2 volume

  $volume = $pmh->volume;

The program volume.  This is a computed attribute.

=head2 difficulty

  $difficulty = $pmh->difficulty;

The program difficulty.  This is a computed attribute.

=head2 level

  $level = $pmh->level;

The program level.  This is a computed attribute.

=head2 effort

  $effort = $pmh->effort;

The program effort.  This is a computed attribute.

=head2 time_to_program

  $time_to_program = $pmh->time_to_program;

The time to program.  This is a computed attribute.

=head2 delivered_bugs

  $delivered_bugs = $pmh->delivered_bugs;

Delivered bugs.  This is a computed attribute.

=cut

has [qw(
    prog_vocab
    prog_length
    est_prog_length
    volume
    difficulty
    level
    effort
    time_to_program
    delivered_bugs
)] => (
    is       => 'lazy',
    init_arg => undef,
    builder  => 1,
);

sub _build_prog_vocab {
    my ($self) = @_;
    return $self->n_distinct_operators + $self->n_distinct_operands;
}

sub _build_prog_length {
    my ($self) = @_;
    return $self->n_operators + $self->n_operands;
}

sub _build_est_prog_length {
    my ($self) = @_;
    return $self->n_distinct_operators * _log2($self->n_distinct_operators)
        + $self->n_distinct_operands * _log2($self->n_distinct_operands);
}

sub _build_volume {
    my ($self) = @_;
    return $self->prog_length * _log2($self->prog_vocab);
}

sub _build_difficulty {
    my ($self) = @_;
    return ($self->n_distinct_operators / 2)
        * ($self->n_operands / $self->n_distinct_operands);
}

sub _build_level {
    my ($self) = @_;
    return 1 / $self->difficulty;
}

sub _build_effort {
    my ($self) = @_;
    return $self->difficulty * $self->volume;
}

sub _build_time_to_program {
    my ($self) = @_;
    return $self->effort / 18; # seconds
}

sub _build_delivered_bugs {
    my ($self) = @_;
    return ($self->effort ** (2/3)) / 3000;
}

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
        if ( _is_operand($key) ) {
            $self->{n_operands} += @{ $halstead{$key} };
        }
        else {
            $self->{n_operators} += @{ $halstead{$key} };
        }
    }

    my %distinct;

    for my $key ( keys %halstead ) {
        for my $item ( @{ $halstead{$key} } ) {
            if ( _is_operand($key) ) {
                $distinct{operands}->{$item} = undef;
            }
            else {
                $distinct{operators}->{$item} = undef;
            }
        }
    }

    $self->{n_distinct_operators} = keys %{ $distinct{operators} };
    $self->{n_distinct_operands}  = keys %{ $distinct{operands} };
}

=head2 dump()

  $pmh->dump();

Print the computed metrics to C<STDOUT>.

=cut

sub dump {
    my ($self) = @_;
    printf "Total operators = %d, Total operands = %d\n", $self->n_operators, $self->n_operands;
    printf "Distinct operators = %d, Distinct operands = %d\n", $self->n_distinct_operators, $self->n_distinct_operands;
    printf "Program vocabulary = %d, Program length = %d\n", $self->prog_vocab, $self->prog_length;
    printf "Estimated program length = %.3f\n", $self->est_prog_length;
    printf "Program volume = %.3f\n", $self->volume;
    printf "Program difficulty = %.3f\n", $self->difficulty;
    printf "Program level = %.3f\n", $self->level;
    printf "Program effort = %.3f\n", $self->effort;
    printf "Time to program = %.3f\n", $self->time_to_program;
    printf "Delivered bugs = %.3f\n", $self->delivered_bugs;
}

sub _is_operand {
    my $key = shift;
    return $key eq 'PPI::Token::Comment'
        || $key eq 'PPI::Token::Number'
        || $key eq 'PPI::Token::Symbol'
        || $key eq 'PPI::Token::Pod'
        || $key eq 'PPI::Token::HereDoc'
        || $key =~ /Quote/;
}

sub _log2 {
    my $n = shift;
    return log($n) / log(2);
}

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> file in this distribution.

L<Moo>

L<PPI::Document>

L<PPI::Dumper>

L<https://en.wikipedia.org/wiki/Halstead_complexity_measures>

L<https://www.verifysoft.com/en_halstead_metrics.html>

=cut
