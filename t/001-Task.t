#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

use vars qw/ $one $tmp $CLASS /;
$CLASS = 'App::PPBuild::Task';
use_ok( $CLASS );
use App::PPBuild::Task;

$one = $CLASS->new(
    name => 'TaskA',
    deps => [ 'a', 'b' ],
    code => sub { 1 },
);

isa_ok( $one, $CLASS, "Created instance of Task." );

is( $one->run, 1, "Task runs, code is run." );
is( $one->ran, 1, "Task has been run once" );
is( $one->run, "Task TaskA Has already been run.", "Task has been run" );
is( $one->run_again( 1 ), 1, "Task runs again, code is run again." );
is( $one->ran, 2, "Task has been run twice" );
is( $one->run, "Task TaskA Has already been run.", "Task has been run" );
$one->{ flags } = { again => 1 };
is( $one->run, 1, "Task runs again with flag, code is run again." );
is( $one->ran, 3, "Task has been run three times" );

is_deeply( $one->deplist, [ 'a', 'b' ], "Dep list is accurate");

is( $one->flag( 'again' ), 1, "Again flag is set" );
is_deeply( $one->flaglist, [ 'again' ], "again is in flag list" );

is( ref $one->code, 'CODE', "Code is a coderef" );
is( $one->name, 'TaskA', "Name is set" );

dies_ok { $one->hook_run( [] ) } "hook_run dies in Task";

ok( defined( $one->_set_ran( 0 )), "_set_ran works" );
is( $one->ran, 0, "ran has been set to 0." );
ok( $one->_set_ran( 6 ), "_set_ran" );
is( $one->ran, 6, "ran has been set to 6." );

is( $one->description, "No Description", "Default description is 'No Description'" );

$one = $CLASS->new(
    name => 'TaskA',
    deps => [ 'a', 'b' ],
    code => sub { 1 },
    description => 'Blah',
);

is( $one->description, "Blah", "Can provide a description." );
