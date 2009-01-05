#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

use_ok( 'App::PPBuild' );
use App::PPBuild qw/ describe task file group runtask tasklist session write_session load_session /;

use vars qw/ $tmp /;

#Make sure each task starts w/ 0 runs
my $tasks = {};
is(( $tasks->{ $_ } = task( "Task$_", sub { $_ }))->ran, 0, "Task$_ has been run 0 times" ) for ( 0 .. 4 );

#Make sure task runs increment.
runtask( 'Task1' );
is( $tasks->{ 1 }->ran(), 1, "Task1 ran once" );
runtask( 'Task1', 1 );
is( $tasks->{ 1 }->ran(), 2, "Task2 ran twice" );

#Load session and make sure test counts have been set.
session 't/res/session';
is( $tasks->{ $_ }->ran(), $_, "Task$_ has been run $_ times" ) for ( 0 .. 4 );

#Make sure new tasks get the correct count for the session
$tasks->{ 5 } = task 'Task5', sub { 5 };
is( $tasks->{ 5 }->ran(), 5, "Task5 has been run 5 times" );

write_session( 't/res/test-session' );
ok( -e 't/res/test-session', "test-session exists" );

my $old = load_session( 't/res/session' );
my $new = load_session( 't/res/test-session' );
is_deeply( $new, $old, "Newly created session has same data as old." );
ok( unlink( 't/res/test-session' ), "cleanup" );
