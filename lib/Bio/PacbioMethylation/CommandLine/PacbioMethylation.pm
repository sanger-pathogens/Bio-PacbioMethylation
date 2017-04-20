package Bio::PacbioMethylation::CommandLine::PacbioMethylation;

# ABSTRACT: Runs the RS_Modification_and_Motif_Analysis pipeline and tidies output files

# PODNAME: pacbio_methylation

=head1 synopsis

Runs the RS_Modification_and_Motif_Analysis pipeline and tidies output files

=cut

use strict;
use warnings;
use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::PacbioMethylation::RSModificationRunner;

has 'args'            => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'bax_h5_files'    => ( is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] } );
has 'reference_fasta' => ( is => 'rw', isa => 'Str' );
has 'outdir'          => ( is => 'rw', isa => 'Str');
has 'threads'         => ( is => 'rw', isa => 'Int', default => 1);
has 'noclean'         => ( is => 'rw', isa => 'Bool', default => 0 );
has 'min_ipdratio'    => ( is => 'rw', isa => 'Num', default => 0);


sub BUILD {
    my $self = shift;
    my (
        $help,
        $outdir,
        $threads,
        $noclean,
        $min_ipdratio,
    );

    my $options_ok = GetOptionsFromArray(
        $self->args,
        'h|help' => \$help,
        't|threads=i' => \$threads,
        'n|noclean' => \$noclean,
        'm|min_ipdratio=f' => \$min_ipdratio,
    );

    if (!($options_ok) or !(scalar(@{$self->args}) >=3) or $help){
        $self->usage_text;
    }

    $self->outdir($self->args->[0]);
    $self->reference_fasta($self->args->[1]);

    for my $i (2 .. scalar(@{$self->args}) - 1){
        push(@{$self->bax_h5_files}, $self->args->[$i]);
    }
}


sub run {
    my $self = shift;
    my $obj = Bio::PacbioMethylation::RSModificationRunner->new(
        bax_h5_files => $self->bax_h5_files,
        reference_fasta => $self->reference_fasta,
        outdir => $self->outdir,
        threads => $self->threads,
        clean => !($self->noclean),
        min_ipdratio => $self->min_ipdratio,
    );
    $obj->run();
}


sub usage_text {
    my $self = shift;

    print $self->script_name . " [options] <output dir> <reference.fasta> <*.bax.h5>

Runs the Pacio Methylation pipeline, makes Artemis plot files, and
cleans up unneeded files.

Options:

-h,help
    Show this help and exit

-m,-min_ipdratio
    Cutoff for the ipdratio when making Artemis plot file.
    Any value less than -min_ipdratio will be set to zero [" . $self->min_ipdratio . "]

-n,-noclean
    Do not delete intermediate files

-t,-threads INT
    Number of threads [" . $self->threads . "]
";

    exit(1);
}




__PACKAGE__->meta->make_immutable;
no Moose;
1;
