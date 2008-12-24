#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

use_ok( 'App::PPBuild::Makefile' );
use App::PPBuild::Makefile;

use vars qw/ $tmp %TASKS /;

ppbfile 't/res/PPBFile';
write_makefile file => 't/res/MakefileA';
is( readfile( 't/res/MakefileA' ), readfile('t/res/Makefile.wantA' ), "No Prefix");

write_makefile file => 't/res/MakefileB', prefix => 'ppb_';
is( readfile( 't/res/MakefileB' ), readfile('t/res/Makefile.wantB' ), "Prefix");

ok( unlink( 't/res/MakefileA' ), "Cleanup" );
ok( unlink( 't/res/MakefileB' ), "Cleanup" );

sub readfile {
    my $file = shift;
    my $out;
    open( my $FILE, '<', $file );# || die( "Cannot open file: $!" );
    $out .= $_ while <$FILE>;
    close( $file );
    return $out;
}
