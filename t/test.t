#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

use_ok( 'App::PPBuild' );
use App::PPBuild qw/ describe task file group runtask tasklist /;

use vars qw/ $tmp /;

is( describe( "A", "Description A" ), "Description A", "Check setting a description function style" );
is( describe( "A" ), "Description A", "Verify value of description" );
describe "B", "Description B";
is( describe( "B" ), "Description B", "Description was set using make-like syntax" );

ok( task( 'taskA', "echo 'taskA'" ), "Create taskA" );
dies_ok { task( 'taskA', "echo 'taskA'" ) } "Cannot create taskA twice.";

$tmp = "";
task 'SetTmp', sub { $tmp = 'SetTmp' };
is( runtask( 'SetTmp' ), 'SetTmp', "SetTmp ran" );
is( $tmp, 'SetTmp', "task set the tmp variable." );
is_deeply( [ tasklist() ], [ sort 'taskA', 'SetTmp' ], "Both tasks are in list." );

file 'fileA', 'echo "Not making fileA"';
dies_ok { runtask( 'fileA' ) } "Dies when file is not created in file task";

die( "Try deleting the file: 'fileB'" ) unless
    ok( not (-e 'fileB'), "fileB does not already exist." );
$tmp = file 'fileB', 'touch fileB';
ok( runtask( 'fileB' ) || 1, "fileB task does not die" );
ok( -e 'fileB', "fileB was created" );
ok( $tmp->{ ran }, "fileB has run." );
$tmp->{ ran } = undef;
is( runtask( 'fileB' ) , "fileB is up to date\n", "fileB already created" );
unlink( 'fileB' );

ok( $tmp = group( 'Mygroup', 'a', 'b' ), "group works" );
is_deeply(
    $tmp,
    {
        depends => [ qw/ a b /],
        name => 'Mygroup'
    },
    "Mygroup is right."
);

$tmp = task 'Hi', sub { return 'Hi' };
is( runtask( 'Hi' ), 'Hi', "task runs the first time." );
is( runtask( 'Hi' ), undef, "task does not run the second time." );
is( runtask( 'Hi', 1 ), 'Hi', "task forced to run again" );

dies_ok { runtask( 'Faketask' ) } "Cannot run non-existant task";

task 'BadCode', [ 'a', 'b' ];
dies_ok { runtask( 'BadCode' ) } "Cannot run an array as code.";

