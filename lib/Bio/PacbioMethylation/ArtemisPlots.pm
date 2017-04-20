package Bio::PacbioMethylation::ArtemisPlots;

# ABSTRACT: Convert methylation CSV file to Artemis plot files

=head1 SYNOPSIS

$plot = ArtemisPlots(
    infile => 'modifications.csv', # can be gzipped
    outprefix => 'out',
);
$plot->run();

=cut

use strict;
use warnings;

use Moose;
use Data::Dumper;

has 'infile'     =>   ( is => 'rw', isa => 'Str', required => 1 );
has 'outprefix'  =>   ( is => 'rw', isa => 'Str', required => 1 );
has 'min_ipdratio' => ( is => 'rw', isa => 'Num', required => 1, default => 0);
has 'frac_plot_file'     => ( is => 'ro', isa => 'Str', builder => '_build_frac_plot_file', lazy => 1);
has 'ipdratio_plot_file' => ( is => 'ro', isa => 'Str', builder => '_build_ipdratio_plot_file', lazy => 1);


sub _build_frac_plot_file {
    my $self = shift;
    return $self->outprefix . '.frac.plot';
}


sub _build_ipdratio_plot_file {
    my $self = shift;
    return $self->outprefix . '.ipdratio.plot';
}


sub _load_methylation_csv {
    my $self = shift;
    my $fh;
    if ($self->infile =~ /\.gz$/) {
        open $fh, 'gunzip -c ' . $self->infile . '|' or die "Error opening file $self->infile $!";
    }
    else {
        open $fh, $self->infile or die "Error opening file $self->infile $!";
    }

    my %columns;
    my %data;

    while (my $line = <$fh>) {
        # split before chomp because the final field is often empty and
        # we don't want to lose it
        my @fields = split(',', $line);
        chomp @fields;

        if (0 == keys %columns) {
            for my $i (0..$#fields) {
                $columns{$fields[$i]} = $i;
            }
        }
        else {
            # the sequence name column might be in quotes, and also
            # contain one or more comma(s)
            if (@fields > keys %columns) {
                my $extra_cols = @fields - (keys %columns);
                @fields = (join(',', @fields[0..$extra_cols]), @fields[$extra_cols + 1 .. $#fields]);
            }

            $fields[0] = substr($fields[0], 1, -1) if ($fields[0] =~/^".*"$/);
            (@fields == keys %columns) or die "unexpected number of columns $!";
            my $ipdratio = $fields[$columns{'ipdRatio'}] < $self->min_ipdratio ? 0 : $fields[$columns{'ipdRatio'}];
            my $frac = $fields[$columns{'frac'}] eq '' ? 0 : $fields[$columns{'frac'}];

            # tpl = coordinate in the contig
            $data{$fields[$columns{refName}]}{$fields[$columns{tpl}]}{$fields[$columns{strand}]}{ipdratio} = $ipdratio;
            $data{$fields[$columns{refName}]}{$fields[$columns{tpl}]}{$fields[$columns{strand}]}{frac} = $frac;
        }
    }

    close $fh or die $!;
    return \%data;
}


sub _write_plot_files {
    my $self = shift;
    my $data = shift;

    open (my $ipdratio_fh, '>', $self->ipdratio_plot_file) or die "Error opening ipdratio file $!";
    open (my $frac_fh, '>', $self->frac_plot_file) or die "Error opening frac file $!";

    for my $seq_name (sort keys %{$data}) {
        for my $coord (sort {$a <=> $b} keys %{$data->{$seq_name}}) {
            my $ipd0 = defined $data->{$seq_name}{$coord}{0}{ipdratio} ? $data->{$seq_name}{$coord}{0}{ipdratio} : 0;
            my $ipd1 = defined $data->{$seq_name}{$coord}{1}{ipdratio} ? $data->{$seq_name}{$coord}{1}{ipdratio} : 0;
            my $frac0 = defined $data->{$seq_name}{$coord}{0}{frac} ? $data->{$seq_name}{$coord}{0}{frac} : 0;
            my $frac1 = defined $data->{$seq_name}{$coord}{1}{frac} ? $data->{$seq_name}{$coord}{1}{frac} : 0;
            print $ipdratio_fh "$seq_name\t$coord\t$ipd0\t$ipd1\n";
            print $frac_fh "$seq_name\t$coord\t$frac0\t$frac1\n";
        }
    }

    close $ipdratio_fh or die $!;
    close $frac_fh or die $!;
}


sub run {
    my $self = shift;
    my $data = $self->_load_methylation_csv();
    $self->_write_plot_files($data);

    for my $file ($self->ipdratio_plot_file, $self->frac_plot_file) {
        my $cmd = "bgzip -f $file";
        system($cmd) and die "Error running $cmd";
        $cmd = "tabix -f -b 2 -e 2 $file.gz";
        system($cmd) and die "Error running $cmd";
    }
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

