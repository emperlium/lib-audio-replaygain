#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "libreplaygain/gain_analysis.h"

#define BUFFER_SAMPLES 32768
#define PCM_MAX_VALUE 32768.0

struct nickaudioreplaygain {
    SV *scalar_in;
    bool is_mono;
    int16_t track_max;
    int16_t album_max;
    long max_bytes;
    Float_t *buffer_left;
    Float_t *buffer_right;
};

typedef struct nickaudioreplaygain NICKAUDIOREPLAYGAIN;

MODULE = Nick::Audio::ReplayGain  PACKAGE = Nick::Audio::ReplayGain

static NICKAUDIOREPLAYGAIN *
NICKAUDIOREPLAYGAIN::new_xs( sample_rate, channels, scalar_in )
        long sample_rate;
        U8 channels;
        SV *scalar_in;
    CODE:
        if (
            InitGainAnalysis( sample_rate ) != INIT_GAIN_ANALYSIS_OK
        ) {
            croak( "Unable to initialise gain analysis" );
        }
        if ( channels < 1 || channels > 2 ) {
            croak( "Invalid number of channels: %d", channels );
        }
        Newxz( RETVAL, 1, NICKAUDIOREPLAYGAIN );
        RETVAL -> is_mono = channels == 1;
        RETVAL -> max_bytes = BUFFER_SAMPLES * 2 * channels;
        RETVAL -> track_max = 0;
        RETVAL -> album_max = 0;
        RETVAL -> scalar_in = SvREFCNT_inc(
            SvROK( scalar_in ) ? SvRV( scalar_in ) : scalar_in
        );
        Newx( RETVAL -> buffer_left, BUFFER_SAMPLES, Float_t );
        Newx( RETVAL -> buffer_right, BUFFER_SAMPLES, Float_t );
    OUTPUT:
        RETVAL

void
NICKAUDIOREPLAYGAIN::DESTROY()
    CODE:
        SvREFCNT_dec( THIS -> scalar_in );
        Safefree( THIS -> buffer_left );
        Safefree( THIS -> buffer_right );
        Safefree( THIS );

SV *
NICKAUDIOREPLAYGAIN::get_buffer_in_ref()
    CODE:
        RETVAL = newRV_inc( THIS -> scalar_in );
    OUTPUT:
        RETVAL

void
NICKAUDIOREPLAYGAIN::set_samplerate( sample_rate )
        long sample_rate;
    CODE:
        if (
            ResetSampleFrequency( sample_rate ) != INIT_GAIN_ANALYSIS_OK
        ) {
            croak( "Unable to initialise sample rate" );
        }

void
NICKAUDIOREPLAYGAIN::set_channels( channels )
        U8 channels;
    CODE:
        if ( channels < 1 || channels > 2 ) {
            croak( "Invalid number of channels: %d", channels );
        }
        THIS -> is_mono = channels == 1;

int
NICKAUDIOREPLAYGAIN::process()
    INIT:
        STRLEN len_in;
        unsigned char *pcm = SvPV( THIS -> scalar_in, len_in );
        int16_t samp;
        int16_t max = 0;
        Float_t *buffer_left = THIS -> buffer_left;
        Float_t *buffer_right = THIS -> buffer_right;
        int samples = 0;
        int i;
    CODE:
        if (
            ! SvOK( THIS -> scalar_in )
        ) {
            XSRETURN_UNDEF;
        }
        if ( len_in > THIS -> max_bytes ) {
            croak(
                "Too much data (%d) for maximum buffer size (%d)",
                len_in, THIS -> max_bytes
            );
        }
        if ( THIS -> is_mono ) {
            for ( i = 0; i < len_in; i += 2 ) {
                samp = pcm[i] + ( ( int16_t )pcm[ i + 1 ] << 8 );
                buffer_left[samples] = (Float_t)samp;
                samples++;
                if ( samp < 0 ) {
                    samp *= -1;
                }
                if ( samp > max ) {
                    max = samp;
                }
            }
            if (
                AnalyzeSamples(
                    buffer_left, 0, samples, 1
                ) != GAIN_ANALYSIS_OK
            ) {
                croak( "Unable to analyze samples" );
            }
        } else {
            for ( i = 0; i < len_in; i += 2 ) {
                samp = pcm[i] + ( ( int16_t )pcm[ i + 1 ] << 8 );
                if ( ( i / 2 ) % 2 ) {
                    buffer_left[samples] = (Float_t)samp;
                    samples++;
                } else {
                    buffer_right[samples] = (Float_t)samp;
                }
                if ( samp < 0 ) {
                    samp *= -1;
                }
                if ( samp > max ) {
                    max = samp;
                }
            }
            if (
                AnalyzeSamples(
                    buffer_left, buffer_right, samples, 2
                ) != GAIN_ANALYSIS_OK
            ) {
                croak( "Unable to analyze samples" );
            }
        }
        if ( max > THIS -> track_max ) {
            THIS -> track_max = max;
            if ( max > THIS -> album_max ) {
                THIS -> album_max = max;
            }
        }
        RETVAL = 1;
    OUTPUT:
        RETVAL

void
NICKAUDIOREPLAYGAIN::get_track()
    PPCODE:
        XPUSHs( sv_2mortal(
            newSVnv( GetTitleGain() )
        ) );
        XPUSHs( sv_2mortal(
            newSVnv( THIS -> track_max / PCM_MAX_VALUE )
        ) );
        THIS -> track_max = 0;

void
NICKAUDIOREPLAYGAIN::get_album()
    PPCODE:
        XPUSHs( sv_2mortal(
            newSVnv( GetAlbumGain() )
        ) );
        XPUSHs( sv_2mortal(
            newSVnv( THIS -> album_max / PCM_MAX_VALUE )
        ) );
        THIS -> album_max = 0;
