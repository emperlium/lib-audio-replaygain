package Nick::Audio::ReplayGain;

use strict;
use warnings;

use XSLoader;
use Carp;
use POSIX 'log10';

use base 'Exporter';

our( $VERSION, @EXPORT_OK );

BEGIN {
    $VERSION = '0.01';
    @EXPORT_OK = qw( safe_gain );
    XSLoader::load 'Nick::Audio::ReplayGain' => $VERSION;
}

=head1 NAME

Nick::Audio::ReplayGain - Wrapper for ReplayGainAnalysis.

=head1 SYNOPSIS

    use Nick::Audio::ReplayGain;
    use Nick::Audio::FLAC;

    my( $rg, $flac, $buffer, $sr, $ch );
    for ( <'flac_album/*.flac'> ) {
        print "$_\n";
        $flac = Nick::Audio::FLAC -> new( $_, 'buffer_out' => \$buffer );
        if ( $rg ) {
            $sr == $flac -> get_sample_rate()
                or $rg -> set_samplerate(
                    $sr = $flac -> get_sample_rate()
                );
            $ch == $flac -> get_channels()
                or $rg -> set_channels(
                    $ch = $flac -> get_channels()
                );
        } else {
            $sr = $flac -> get_sample_rate();
            $ch = $flac -> get_channels();
            $rg = Nick::Audio::ReplayGain -> new(
                'sample_rate'   => $sr,
                'channels'      => $ch,
                'buffer_in'     => \$buffer
            );
        }
        while (
            $flac -> read()
        ) {
            $rg -> process();
        }
        printf "  Gain dB: %.2f\n  Peak: %.2f\n", $rg -> get_track();
    }
    printf "Album\n  Gain dB: %.2f\n  Peak: %.2f\n", $rg -> get_album();

=head1 METHODS

=head2 new()

Instantiates a new Nick::Audio::ReplayGain object.

Arguments are interpreted as a hash.

There are two mandatory keys.

=over 2

=item sample_rate

Sample rate of PCM data.

=item channels

Number of audio channels.

=back

The following is optional.

=over 2

=item buffer_in

Scalar that'll be used to analyse PCM audio from.

=back

=head2 process()

Analyse the PCM audio currently in B<buffer_in>.

=head2 get_buffer_in_ref()

Returns the scalar currently being used to pull PCM audio from.

=head2 set_samplerate()

Change the current sample rate to the given value.

=head2 set_channels( channels )

Change the current audio channels to the given value.

=head2 get_track()

Get the suggested gain increase and peak value (0 to 1) for the current track.

Calling this method implies further processing is for the next track.

=head2 get_album()

Get the suggested gain increase and peak value (0 to 1) for the current album.

Calling this method implies further processing is for the next album.

=head2 safe_gain()

Exported function that checks whether a given suggested gain increase and peak value would raise the peak value above 1 (causing clipping).

If it would, the function returns a safe suggested gain increase, otherwise returns undef.

    use Nick::Audio::ReplayGain 'safe_gain';

    ...
    ( $gain, $peak ) = $rg -> get_track();

    print "Original gain: $gain dB\n";
    $gain = safe_gain( $gain, $peak )
        and print "Lowering to: $gain dB\n";

=cut

sub new {
    my( $class, %settings ) = @_;
    my @missing;
    @missing = grep(
        ! exists $settings{$_}, qw( sample_rate channels )
    ) and croak(
        'Missing parameters: ' . join ', ', @missing
    );
    exists( $settings{'buffer_in'} )
        or $settings{'buffer_in'} = do{ my $x = '' };
    return Nick::Audio::ReplayGain -> new_xs(
        @settings{ qw( sample_rate channels buffer_in ) }
    );
}

sub safe_gain {
    my( $gain, $peak ) = @_;
    return(
        $gain > 0 && $peak > 0 && ( 10 ** ( $gain / 20 ) ) * $peak > 1
        ? int( 20000 * log10( 1 / $peak ) ) / 1000
        : undef
    );
}

1;
