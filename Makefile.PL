use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Nick::Audio::ReplayGain',
    VERSION_FROM        => 'lib/Nick/Audio/ReplayGain.pm',
    AUTHOR              => 'Nick Peskett',
    MYEXTLIB            => 'libreplaygain/gain_analysis.o',
    clean               => {
        'FILES' => 'libreplaygain/gain_analysis.o libreplaygain/libreplaygain.so'
    },
    TEST_REQUIRES       => {
        'Test::More' => 0
    }
);

sub MY::postamble {
    return <<'MAKE_FRAG';
$(MYEXTLIB): libreplaygain/Makefile
	cd libreplaygain && $(MAKE)
MAKE_FRAG
}
