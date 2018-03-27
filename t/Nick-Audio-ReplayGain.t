use strict;
use warnings;

use Test::More tests => 5;

use_ok( 'Nick::Audio::ReplayGain' );

my $buffer;
my $replaygain = Nick::Audio::ReplayGain -> new(
    'sample_rate'   => 22050,
    'channels'      => 2,
    'buffer_in'     => \$buffer
);

ok( defined( $replaygain ), 'new()' );

my $songs = 5;
my $block_size = 8192;
my $step = 8192;

my $volume = 32767;
my( @got, $block, $i );
for ( my $song = 1; $song <= $songs; $song++ ) {
    $buffer = pack( 's2', -$volume, $volume ) x $block_size;
    $replaygain -> process() or die;
    push @got => sprintf '%.3f|%.3f', $replaygain -> get_track();
    $volume -= $step;
}

is(
    join( ' ', @got ),
    '2.870|1.000 5.360|0.750 8.890|0.500 14.910|0.250 64.820|0.000',
    'get_track()'
);

is(
    sprintf( '%.3f|%.3f', $replaygain -> get_album() ),
    '5.360|1.000',
    'get_album()'
);

is(
    Nick::Audio::ReplayGain::safe_gain( 3.22, 0.70501709 ),
    3.036,
    'safe_gain()'
);
