# lib-audio-replaygain

Wrapper for ReplayGainAnalysis (written by David Robinson, Glen Sawyer and Frank Klemm).

As the original included code (gain_analysis.*), this module is released under GPL 2.1 (included).

## Dependencies

None.

## Note

Currently limited to 16 bit audio.

## Installation

    perl Makefile.PL
    make test
    sudo make install

## Example

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

## METHODS

### new()

Instantiates a new Nick::Audio::ReplayGain object.

Arguments are interpreted as a hash.

There are two mandatory keys.

- sample\_rate

    Sample rate of PCM data.

- channels

    Number of audio channels.

The following is optional.

- buffer\_in

    Scalar that'll be used to analyse PCM audio from.

### process()

Analyse the PCM audio currently in **buffer\_in**.

### get\_buffer\_in\_ref()

Returns the scalar currently being used to pull PCM audio from.

### set\_samplerate()

Change the current sample rate to the given value.

### set\_channels( channels )

Change the current audio channels to the given value.

### get\_track()

Get the suggested gain increase and peak value (0 to 1) for the current track.

Calling this method implies further processing is for the next track.

### get\_album()

Get the suggested gain increase and peak value (0 to 1) for the current album.

Calling this method implies further processing is for the next album.

### safe\_gain()

Exported function that checks whether a given suggested gain increase and peak value would raise the peak value above 1 (causing clipping).

If it would, the function returns a safe suggested gain increase, otherwise returns undef.

    use Nick::Audio::ReplayGain 'safe_gain';

    ...
    ( $gain, $peak ) = $rg -> get_track();

    print "Original gain: $gain dB\n";
    $gain = safe_gain( $gain, $peak )
        and print "Lowering to: $gain dB\n";
