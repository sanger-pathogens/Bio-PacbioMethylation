package Bio::PacbioMethylation::RSModificationRunner;

# ABSTRACT: Runs the RS_Modification_and_Motif_Analysis pipeline and tidies output files

=head1 SYNOPSIS

$runner = RSModificationRunner(
    bax_h5_files => ('file1.bax.h5', 'file2.bax.h5'),
    reference_fasta => 'reference.fasta',
    outdir => 'output_directory',
    threads => 8,
);
$runner->run();

=cut

use strict;
use warnings;

use Moose;
use Data::Dumper;
use File::Spec;
use File::Basename;
use File::Path 'rmtree';
use Bio::PacbioMethylation::ArtemisPlots;

has 'bax_h5_files'    => ( is => 'rw', isa => 'ArrayRef[Str]', required => 1 );
has 'reference_fasta' => ( is => 'rw', isa => 'Str', required => 1 );
has 'outdir'          => ( is => 'rw', isa => 'Str', required => 1 );
has 'threads'         => ( is => 'rw', isa => 'Int', required => 1, default => 1);
has 'clean'           => ( is => 'ro', isa => 'Bool', required => 0, default => 1);
has 'min_ipdratio'    => ( is => 'rw', isa => 'Num', required => 1, default => 0);


sub _check_input_files_and_make_abs_paths {
    my $self = shift;
    -e $self->reference_fasta or die "Reference FASTA file " . $self->reference_fasta . " not found. Cannot continue";
    $self->reference_fasta(File::Spec->rel2abs($self->reference_fasta));

    for my $i (0..(scalar(@{$self->bax_h5_files})-1)) {
        -e $self->bax_h5_files->[$i] or die "Input h5 file " . $self->bax_h5_files->[$i] . " not found. Cannot continue";
        $self->bax_h5_files->[$i] = File::Spec->rel2abs($self->bax_h5_files->[$i])
    }

    -e $self->outdir and die "Ouptut directory " . $self->outdir . " must not already exist. Cannot continue";
}


sub _run_pacbio_smrtanalysis {
    my $self = shift;
    my $cmd = join(' ', (
        'pacbio_smrtanalysis',
        '--no_bsub',
        '--threads', $self->threads,
        '--reference', $self->reference_fasta,
        'RS_Modification_and_Motif_Analysis',
        $self->outdir
    ));
    $cmd .= ' ' . join(' ', @{$self->bax_h5_files});

    if (system($cmd)) {
        die "Error running pacbio_smrtanalysis script: $cmd";
    }
}


sub _make_plots {
    my $self = shift;
    my $artplot = Bio::PacbioMethylation::ArtemisPlots->new(
        infile  => File::Spec->catfile($self->outdir, 'All_output', 'data', 'modifications.csv.gz'),
        outprefix => File::Spec->catfile($self->outdir, 'modifications'),
        min_ipdratio => $self->min_ipdratio,
    );
    $artplot->run();
}


sub _cleanup {
    my $self = shift;
    my $all_output_dir = File::Spec->catfile($self->outdir, 'All_output');

    my @files_to_keep = (
        File::Spec->catfile($all_output_dir, 'data', 'base_mod_contig_ids.txt'),
        File::Spec->catfile($all_output_dir, 'data', 'contig_ids.txt'),
        File::Spec->catfile($all_output_dir, 'data', 'modifications.csv.gz'),
        File::Spec->catfile($all_output_dir, 'data', 'modifications.gff.gz'),
        File::Spec->catfile($all_output_dir, 'data', 'motifs.gff.gz'),
        File::Spec->catfile($all_output_dir, 'data', 'motif_summary.csv'),
        File::Spec->catfile($all_output_dir, 'data', 'temp_kinetics.h5'),

    );

    for my $abs_filename (@files_to_keep) {
        my $filename = fileparse($abs_filename);
        rename($abs_filename, File::Spec->catfile($self->outdir, $filename)) or die $!;
    }

    rmtree($all_output_dir) or die $!;
}


sub run {
    my $self = shift;
    $self->_check_input_files_and_make_abs_paths();
    $self->_run_pacbio_smrtanalysis();
    $self->_make_plots();
    $self->_cleanup() if $self->clean;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

