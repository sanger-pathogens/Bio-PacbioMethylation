#!/usr/bin/env perl
use strict;
use warnings;
use File::Compare;
use File::Slurp;
use Data::Dumper;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::PacbioMethylation::ArtemisPlots');
}

my $obj;
my $outprefix = 'test.ArtemisPlots.out';


# -------------- test initialization ---------------- #
ok($obj = Bio::PacbioMethylation::ArtemisPlots->new(
    infile  => 't/data/modifications.csv',
    outprefix => $outprefix,
), 'initialize Bio::Methylation::ArtemisPlots object');


# -------------- test _load_methylation_csv() ---------------- #
my %expected_methylation_data = (
    'Chromosome, foo, bar' => {
        1 => {0 => {ipdratio => 3.031, frac => 0}, 1 => {ipdratio => 4.198, frac => 0}},
        2 => {0 => {ipdratio => 2.272, frac => 0.42}, 1 => {ipdratio => 2.234, frac => 0.43}},
    },
    'Plasmid' => {
        42 => {0 => {ipdratio => 0.925, frac => 0.51}, 1 => {ipdratio => 0.926, frac => 0.12}},
    },
);
my $got_methylation_data = $obj->_load_methylation_csv();
is_deeply($got_methylation_data, \%expected_methylation_data, '_load_methylation_csv() with defaults');


# -------------- test _load_methylation_csv() different min_ipdratio ---------------- #
$obj->min_ipdratio(2.26);
%expected_methylation_data = (
    'Chromosome, foo, bar' => {
        1 => {0 => {ipdratio => 3.031, frac => 0}, 1 => {ipdratio => 4.198, frac => 0}},
        2 => {0 => {ipdratio => 2.272, frac => 0.42}, 1 => {ipdratio => 0, frac => 0.43}},
    },
    'Plasmid' => {
        42 => {0 => {ipdratio => 0, frac => 0.51}, 1 => {ipdratio => 0, frac => 0.12}},
    },
);
$got_methylation_data = $obj->_load_methylation_csv();
is_deeply($got_methylation_data, \%expected_methylation_data, '_load_methylation_csv() with min_ipdratio != 0');
$obj->min_ipdratio(0);


# -------------- test _write_plot_files() ---------------- #
my %data_to_write = (
    'Chromosome, foo, bar' => {
        1 => {0 => {ipdratio => 3.031, frac => 0}, 1 => {ipdratio => 4.198, frac => 0}},
        2 => {0 => {ipdratio => 2.272, frac => 0.42}, 1 => {ipdratio => 2.234, frac => 0.43}},
    },
    'Plasmid' => {
        42 => {0 => {ipdratio => 0.925, frac => 0.51}, 1 => {ipdratio => 0.926, frac => 0.12}},
    },
);
$obj->_write_plot_files(\%data_to_write);
ok(compare('t/data/ArtemisPlots.expected.frac.plot', "$outprefix.frac.plot") == 0, '_write_plot_files() frac.plot correct');
ok(compare('t/data/ArtemisPlots.expected.ipdratio.plot', "$outprefix.ipdratio.plot") == 0, '_write_plot_files() ipdratio.plot correct');
unlink "$outprefix.frac.plot" or die $!;
unlink "$outprefix.ipdratio.plot" or die $!;


# -------------------- test run() -------------------- #
for my $infile ('t/data/modifications.csv', 't/data/modifications.csv.gz') {
    $obj = Bio::PacbioMethylation::ArtemisPlots->new(
        infile  => $infile,
        outprefix => $outprefix,
    );

    $obj->run();
    ok(-e "$outprefix.frac.plot.gz.tbi", "run() with infile=$infile wrote frac plot tbi file");
    ok(-e "$outprefix.ipdratio.plot.gz.tbi", "run() with infile=$infile wrote ipdratio plot tbi file");

    my $expected_lines = read_file('t/data/ArtemisPlots.expected.frac.plot');
    open my $fh, "gunzip -c $outprefix.frac.plot.gz |" or die $!;
    my $got_lines = read_file($fh);
    is($got_lines, $expected_lines, "run() with infile=$infile frac.plot.gz correct");

    $expected_lines = read_file('t/data/ArtemisPlots.expected.ipdratio.plot');
    open $fh, "gunzip -c $outprefix.ipdratio.plot.gz |" or die $!;
    $got_lines = read_file($fh);
    is($got_lines, $expected_lines, "run() with infile=$infile ipdratio.plot.gz correct");

    unlink "$outprefix.frac.plot.gz" or die $!;
    unlink "$outprefix.frac.plot.gz.tbi" or die $!;
    unlink "$outprefix.ipdratio.plot.gz" or die $!;
    unlink "$outprefix.ipdratio.plot.gz.tbi" or die $!;
}

done_testing();

