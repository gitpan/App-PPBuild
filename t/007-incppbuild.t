#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;

BEGIN {
    warn "inc/App/PPBuild.pm already present, test results may be inaccurate!\n" if ( -f './inc/PPBuild.pm' );
    warn "inc/App/PPBuild dir already present, test results may be inaccurate!\n" if ( -d './inc/PPBuild' );
    warn "inc/Getopt dir already present, test results may be inaccurate!\n" if ( -d './inc/Getopt' );
}

use vars qw/ $one $tmp $CLASS /;
use inc::App::PPBuild;

for my $module ( grep { m/^App\/PPBuild/ } keys %INC ) {
    ok( -e "./inc/$module", "$module was copied" );
}
ok( -e "./inc/Getopt/Long.pm", "Getopt was copied" );

ok( defined \&App::PPBuild::task, "exported functions were imported." );
ok( defined \&task, "exported functions were imported." );
ok( defined \&group, "exported functions were imported." );

ok( task( 'blah', undef ), "can run task()" );

#Cleanup
END {
    for ( qw{ App/PPBuild App/PPBuild.pm Getopt YAML } ) {
        if ( system( "rm -r './inc/$_'" )) {
            warn "rm command failed, inc/$_ was not removed!\n";
        }
    }
}
