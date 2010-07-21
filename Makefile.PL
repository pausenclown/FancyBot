use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FancyBot',
    AUTHOR              => q{Tailgunner <tailgunner@somewhere.com>},
    VERSION_FROM        => 'lib/FancyBot.pm',
    ABSTRACT_FROM       => 'lib/FancyBot.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
	EXE_FILES           => [ 'bin/fancybot' ],
    PREREQ_PM => {
        'Test::More'      => 0,
		'Moose'           => 0,  
		'Config::Simple'  => 0,
		'Win32'           => 0,
		'Win32::Process'  => 0,
		'Win32::GuiTest'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FancyBot-*' },
);

