#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use vars qw/ $one $tmp $CLASS /;
$CLASS = 'App::PPBuild::Task::File';
use_ok( $CLASS );
use App::PPBuild::Task::File;

$one = $CLASS->new(
    name => 'TaskA',
    deps => [ 'a', 'b' ],
    code => sub { 1 },
);

isa_ok( $one, $CLASS, "Created instance of Task." );
warn "delete the TaskA file" if -e 'TaskA';
dies_ok { $one->hook_completed } "File does nto exist, hook_completed dies.";
ok(( not $one->ran), "Has not been run" );

open( $tmp, '>', 'TaskA' ) || die( "$!" );
print $tmp '.';
close( $tmp );

lives_ok { $one->hook_completed } "hook_completed does not die when file exists.";
is( $one->ran, 1, "File exists, has been run." );
unlink( 'TaskA' );
