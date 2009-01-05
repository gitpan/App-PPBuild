#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 52;
use Test::Exception;

use_ok( 'App::PPBuild' );
use App::PPBuild qw/ describe task file group runtask tasklist parse_params /;

use vars qw/ $tmp /;

ok( task( 'taskA', "echo 'taskA'" ), "Create taskA" );
dies_ok { task( 'taskA', "echo 'taskA'" ) } "Cannot create taskA twice.";

$tmp = "";
task 'SetTmp', sub { $tmp = 'SetTmp' };
is( runtask( 'SetTmp' ), 'SetTmp', "SetTmp ran" );
is( $tmp, 'SetTmp', "task set the tmp variable." );
is_deeply( [ tasklist() ], [ sort 'taskA', 'SetTmp' ], "Both tasks are in list." );

file 'fileA', 'echo "Not making fileA"';
dies_ok { runtask( 'fileA' ) } "Dies when file is not created in file task";

warn( "Try deleting the file: 'fileB'" ) unless
    ok( not (-e 'fileB'), "fileB does not already exist." );
$tmp = file 'fileB', 'touch fileB';
ok( runtask( 'fileB' ) || 1, "fileB task does not die" );
ok( -e 'fileB', "fileB was created" );
ok( $tmp->ran, "fileB has run." );
$tmp->{ ran } = undef;
is( runtask( 'fileB' ) , "Task fileB Has already been run.", "fileB already created" );
unlink( 'fileB' );

ok( $tmp = group( 'Mygroup', ['a', 'b'] ), "group works" );
is_deeply(
    $tmp,
    {
        deps => [ qw/ a b /],
        name => 'Mygroup',
        flags => {},
        code => undef,
        ran => 0,
        description => "No Description",
    },
    "Mygroup is right."
);

$tmp = task 'Hi', sub { return 'Hi' };
is( runtask( 'Hi' ), 'Hi', "task runs the first time." );
is( runtask( 'Hi' ), 'Task Hi Has already been run.', "task does not run the second time." );
is( runtask( 'Hi', 1 ), 'Hi', "task forced to run again" );

dies_ok { runtask( 'Faketask' ) } "Cannot run non-existant task";

task 'BadCode', [ 'a', 'b' ];
dies_ok { runtask( 'BadCode' ) } "Cannot run an array as code.";

$tmp = "";
my $foo = "";

lives_ok { task 'SetFoo', { again => 1 }, sub { $foo = "Foo" }; };
lives_ok { task 'SetTmp2', { again => 1 }, [ 'SetFoo' ], sub { $tmp = "Tmp" }; };

lives_ok { is(runtask('SetFoo'), 'Foo'); };
is($foo, 'Foo');

$foo = "";
lives_ok { is(runtask('SetTmp2'), 'Tmp') };
is($tmp, 'Tmp');
is($foo, 'Foo');

$foo = "";
$tmp = "";

lives_ok { task 'SetFoo2', sub { $foo = "Foo" }; };
lives_ok { task 'SetTmp3', { again => 1 }, [ 'SetFoo2'], sub { $tmp = "Tmp" }; };

lives_ok { is(runtask('SetTmp3'), 'Tmp') };
is($tmp, 'Tmp');
is($foo, 'Foo');

$foo = "";
$tmp = "";

lives_ok { is(runtask('SetTmp3'), 'Tmp') };

is($tmp, 'Tmp');
ok(!$foo);

$tmp = task 'NewFlagsA', ['DepA'], { 'SomeFlag' => 1, 'Another flag' => 1 }, [ 'DepB' ], { YANF => 1 }, ['DepC'], "shell code";
ok(( grep { $_ eq 'SomeFlag' } @{ $tmp->flaglist }), "Found the flag" );
ok(( grep { $_ eq 'Another flag' } @{ $tmp->flaglist }), "Found the flag" );
ok(( grep { $_ eq 'YANF' } @{ $tmp->flaglist }), "Found the flag" );
ok(( grep { $_ eq 'DepA' } @{ $tmp->deplist }), "Found the dep" );
ok(( grep { $_ eq 'DepB' } @{ $tmp->deplist }), "Found the dep" );
ok(( grep { $_ eq 'DepC' } @{ $tmp->deplist }), "Found the dep" );

$tmp = task {
    name => 'ByHash',
    code => 'shell code',
    deps => [ 'Deps' ],
    flags => { 'Flags' => 1 },
    description => "Blah",
};

is( $tmp->name, 'ByHash', 'Got name' );
is( $tmp->code, "shell code", "Got code" );
is_deeply( $tmp->deplist, [ 'Deps' ], "Got deps" );
is_deeply( $tmp->flaglist, [ 'Flags' ], "Got flags" );
is( $tmp->description, "Blah", "Got description" );

dies_ok { parse_params({}) } "Dies w/o a name";
is_deeply(
    parse_params({ name => 'bob' }),
    {
        name => 'bob',
        deps => [],
        flags => {},
        description => 'No Description',
    },
    "Only name is required"
);

is_deeply(
    parse_params( 'bob', ['depA'], { flagA => 1, flagB => 1 }, ['depB'], { flagC => 1 }, ['depC'], { flagD => 1 }, "code" ),
    {
        name => 'bob',
        deps => [ qw/ depA depB depC /],
        flags => {
            flagA => 1,
            flagB => 1,
            flagC => 1,
            flagD => 1,
        },
        code => 'code',
        description => 'No Description',
    },
    "Parsing complicated defenition"
);
