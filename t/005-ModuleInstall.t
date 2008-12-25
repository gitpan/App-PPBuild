#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use_ok( 'Module::Install::PPBuild' );
use Module::Install::PPBuild;

use vars qw/ $tmp %TASKS /;

is( $Module::Install::PPBuild::PREFIX, 'ppbuild_', "PPBuild Prefix." );
is( ppb_prefix, 'ppbuild_', "prefix by function" );
is( ppb_prefix( 'ppb_' ), 'ppb_', "set prefix" );
is( ppb_prefix, 'ppb_', "prefix set" );

ppbfile undef, 't/res/PPBFile', 'TaskA' => 'install';

is(
    MY::install(),
    "install: ppb_TaskA\n",
    "MY::install defined"
);

is(
    MY::postamble(),
    "
ppb_tasks:
\t\@ppbuild --tasks

ppb_clear_session:
\t\@rm -f .session

ppb_TaskA: ppb_clear_session
\t\@ppbuild --session .session TaskA

ppb_TaskB: ppb_clear_session
\t\@ppbuild --session .session TaskB

",
    "task rules are defined"
);
