package SDLx::App::GifMaker;
use strict;
use warnings;

# ABSTRACT: Create animated GIFs using SDL

use Carp;
use Imager;
use Scalar::Util qw(refaddr);
use File::Temp qw( tempfile tempdir );
use File::Spec;

use SDL::Video;
use SDLx::App;

use parent qw(SDLx::App);

my $FILE_FORMAT = 'SDLx-App-GifMaker-%09d.bmp',

    my %_output_file;
my %_images;
my %_image_count;
my %_delay;
my %_tempdir;

sub new {
    my ( $class, %options ) = @_;

    my $self = $class->SUPER::new(%options);

    my $delay = int( $self->min_t * 100 );
    if ( $delay != $self->min_t * 100 ) {
        carp "Rounding delay\n";
        carp "Use a multiple of 0.01 for min_t to prevent this warning\n";
    }

    my $id = refaddr $self;
    $_output_file{$id} = $options{output_file};
    $_images{$id}      = [];
    $_image_count{$id} = 0;
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

    my $id = refaddr $self;

    my $filename = File::Spec->catfile( $_tempdir{$id},
        sprintf( $FILE_FORMAT, $_image_count{$id} ) );

    $_image_count{$id}++;

    SDL::Video::save_BMP( $self, $filename );

    push @{ $_images{$id} }, $filename;
}

sub _write_gif {
    my $self = shift;

    my $id = refaddr $self;

    my $count = scalar @{ $_images{$id} };
    print "Image count $count\n";

    if ( system(qw( which ffmpeg )) == 0 ) {

        my $delay = $_delay{$id};
        my $fps   = 100 / $delay;

        print "Using FPS: $fps\n";

        my $command
            = qq(ffmpeg -y -i $_tempdir{$id}/$FILE_FORMAT -loop_output 0 -pix_fmt rgb24 $_output_file{$id});

#= qq(ffmpeg -y -r $fps -i $_tempdir{$id}/$FILE_FORMAT -loop_output 0 -pix_fmt rgb24 $_output_file{$id});
#= qq(ffmpeg -y -i $_tempdir{$id}/$FILE_FORMAT -r $fps -loop_output 0 -pix_fmt rgb24 $_output_file{$id});

        print $command, "\n";

        qx($command)
            or croak $!;

    }
    else {
        $|++;

        my @images;
        for ( @{ $_images{$id} } ) {
            print '.';
            push @images, Imager->new( file => $_ );
        }
        print "\n";

        print "Writing file: ", $_output_file{$id}, "\n";

        my $delay = $_delay{$id};
        print "Using delay: ${delay}/100s\n";

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
}

1;
