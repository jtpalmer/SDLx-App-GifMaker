use strict;
use warnings;
use SDLx::App;
use SDLx::App::GifMaker;

my $app = SDLx::App::GifMaker->new(
    output_file => '/tmp/test.gif',
    width       => 640,
    height      => 480,
    eoq         => 1,
);

$app->add_show_handler(
    sub {
        $app->draw_line(
            [ 0,            0 ],
            [ rand $app->w, rand $app->h ],
            [ rand 255, rand 255, rand 255 ]
        );
        $app->update;
    }
);

$app->run;
