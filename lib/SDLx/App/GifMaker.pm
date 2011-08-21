package SDLx::App::GifMaker;
use strict;
use warnings;

# ABSTRACT: Create animated GIFs using SDL

use Carp qw(confess);
use Imager;
use Scalar::Util qw(refaddr);
use File::Temp qw( tempfile tempdir );

use SDL::Video;
use SDLx::App;

use parent qw(SDLx::App);

my %_output_file;
my %_images;
my %_delay;
my %_tempdir;

sub new {
    my ( $class, %options ) = @_;

    my $self = $class->SUPER::new(%options);

    my $delay = int $self->dt * 100;
    if ( $delay != $self->dt * 100 ) {
        warn "Rounding delay\n";
        warn "Use a multiple of 0.01 for dt to prevent this warning\n";
    }

    my $id = refaddr $self;
    $_output_file{$id} = $options{output_file};
    $_images{$id}      = [];
    $_delay{$id}       = $delay;
    $_tempdir{$id}     = tempdir( CLEANUP => 1 );

    return bless $self, $class;
}

sub DESTROY {
    my $self = shift;

    my $id = refaddr $self;
    delete $_output_file{$id};
    delete $_images{$id};
    delete $_delay{$id};
    delete $_tempdir{$id};
}

sub stop {
    my $self = shift;

    $self->SUPER::stop(@_);

    $self->_write_gif();
}

sub _show {
    my $self = shift;

    $self->SUPER::_show(@_);

    my ( undef, $filename ) = tempfile(
        'SDLx-App-GifMaker-XXXXXX',
        SUFFIX => '.bmp',
        DIR    => $_tempdir{ refaddr $self},
        OPEN   => 0,
    );

    SDL::Video::save_BMP( $self, $filename );

    push @{ $_images{ refaddr $self} }, $filename;
}

sub _write_gif {
    my $self = shift;

    my $id = refaddr $self;

    my $delay = $_delay{$id};
    print "Delay ${delay}/100s\n";

    my $count = scalar @{ $_images{$id} };
    print "Image count $count\n";

    $|++;

    my @images;
    for ( @{ $_images{$id} } ) {
        print '.';
        push @images, Imager->new( file => $_ );
    }
    print "\n";

    print "Writing file: ", $_output_file{$id}, "\n";

    Imager->write_multi(
        {   file        => $_output_file{$id},
            gif_delay   => int $_delay{$id},
            gif_loop    => 0,
            type        => 'gif',
            make_colors => 'mediancut',
        },
        @images
    ) or print "Cannot write: ", Imager->errstr;
}

1;
