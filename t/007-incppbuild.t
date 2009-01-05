#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
    warn "inc/App/PPBuild.pm already present, test results may be inaccurate!\n" if ( -f './inc/PPBuild.pm' );
    warn "inc/App/PPBuild dir already present, test results may be inaccurate!\n" if ( -d './inc/PPBuild' );
    warn "inc/Getopt dir already present, test results may be inaccurate!\n" if ( -d './inc/Getopt' );
}

use vars qw/ $one $tmp $CLASS /;
$CLASS = 'inc::App::PPBuild';
use_ok( $CLASS );
use inc::App::PPBuild;

for my $module ( grep { m/^App\/PPBuild/ } keys %INC ) {
    ok( -e "./inc/$module", "$module was copied" );
}
ok( -e "./inc/Getopt/Long.pm", "Getopt was copied" );

ok( defined \&App::PPBuild::task, "exported functions were imported." );
ok( defined \&inc::App::PPBuild::task, "exported functions were referenced by inc::App::PPBuild." );
is( \&App::PPBuild::task, \&inc::App::PPBuild::task, "Functions are the same" );

#Cleanup
END {
    for ( qw{ App/PPBuild App/PPBuild.pm Getopt } ) {
        if ( system( "rm -r './inc/$_'" )) {
            warn "rm command failed, inc/$_ was not removed!\n";
        }
    }
}
