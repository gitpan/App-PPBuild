#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 25;
use Test::Exception;

use vars qw/ $one $tmp $CLASS /;
$CLASS = 'App::PPBuild::CUI';
use_ok( $CLASS );
use App::PPBuild::CUI;
use App::PPBuild;

dies_ok { $one = $CLASS->new() } "Need to provide a ppbuild object.";
$one = $CLASS->new( App::PPBuild::global());
isa_ok( $one, $CLASS, "Created object is a $CLASS" );
ok( $one->help, "Help" );

$App::PPBuild::CUI::one = undef;
is( $CLASS->new( 'a' )->ppb, 'a', "Setting ppb at creations works" );
is( $CLASS->new( 'a' )->ppb( 'b' ), 'b', "Setting ppb works" );

is( $one->ppb( 'b' ), 'b', "Setting ppb works" );
is( $one->ppb, 'b', "Setting ppb works" );
$one->ppb( App::PPBuild::global() );

is( $one->again, undef, "no again by default" );
is( $one->again( 1 ), 1, "set again." );
is( $one->again, 1, "set again." );
is( $one->again( undef ), undef, "set again to undef." );

is( $one->quiet, undef, "no quiet by default" );
is( $one->quiet( 1 ), 1, "set quiet." );
is( $one->quiet, 1, "set quiet." );
is( $one->quiet( undef ), undef, "set quiet to undef." );

is( $one->run, undef, "Nothing to run." );
is( $one->file, undef, "No file." );
is( $one->load_session, undef, "No session." );
is( $one->write_session, undef, "No session." );

task 'MyTask', 'My Task', sub { return "My Task Ran"};

is( $one->run, undef, "No arguments for running" );
$one->{ task_list } = 1; #Fake --tasks to ARGV;
is(
    $one->task_list,
    <<EOT,
Available Tasks:
 MyTask - My Task

EOT
    "Task list is correct"
);
$one->{ task_list } = 0; #be kind rewind

is( $one->quiet( 1 ), 1, "set quiet." );
push @ARGV => 'MyTask';
is_deeply( [ $one->run ], [ "My Task Ran" ], "Ran the task" );
is_deeply( \@ARGV, [], "ARGV is now empty." );

