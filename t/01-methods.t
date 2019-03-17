#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Perl::Metrics::Halstead';

throws_ok {
    Perl::Metrics::Halstead->new
} qr/Missing required arguments/, 'required file';

my $pmh = Perl::Metrics::Halstead->new( file => 'eg/tester.pl' );
isa_ok $pmh, 'Perl::Metrics::Halstead';

is $pmh->n_operators, 8, 'n_operators';
is $pmh->n_operands, 2, 'n_operands';
is $pmh->n_distinct_operators, 5, 'n_distinct_operators';
is $pmh->n_distinct_operands, 2, 'n_distinct_operands';
is $pmh->prog_vocab, 7, 'prog_vocab';
is $pmh->prog_length, 10, 'prog_length';
is sprintf('%.3f', $pmh->est_prog_length), '13.610', 'est_prog_length';
is sprintf('%.3f', $pmh->volume), 28.074, 'volume';
is sprintf('%.3f', $pmh->difficulty), '2.500', 'difficulty';
is sprintf('%.3f', $pmh->level), '0.400', 'level';
is sprintf('%.3f', $pmh->effort), 70.184, 'effort';
is sprintf('%.3f', $pmh->time_to_program), 3.899, 'time_to_program';
is sprintf('%.3f', $pmh->delivered_bugs), 0.006, 'delivered_bugs';

done_testing();
