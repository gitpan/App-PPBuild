#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 62;
use Test::Exception;
use Test::Warn;

use_ok( 'App::PPBuild' );
use App::PPBuild qw/ describe task file group runtask tasklist parse_params runtask_again /;

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
is( runtask_again( 'Hi' ), 'Hi', "task forced to run again" );

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

$ENV{ 'B' } = 'b';

load_session( { variables => { C => 'c' } } );
svars(
    A => my $a = 'a',
    B => my $b = 'not right',
    C => my $c,
    A => my $a2,
);
is( $a, 'a', 'Got from default' );
is( $b, 'b', 'Got from ENV' );
is( $c, 'c', 'Got from session' );
is( $a2, 'a', 'Got from default' );

$a = 'bob';
is( $a, 'bob', '$a set' );
is( $a2, 'bob', '$a2 was effected' );

$a2 = 'ted';
is( $a, 'ted', '$a was effected' );
is( $a2, 'ted', '$a2 was set' );

    my $x;
    warning_is {
        svars(
            'X' => $x,
            'Y' => $x,
        );
    }
    "Warning: you listed a variable more than once in a single call to session_variables(). Hint: ident was 'Y'",
    "Using a single variable twice gives a warning.";

    warning_is {
        svars(
            'X' => my $y = 'y',
            'X' => my $z = 'z',
        );
    }
    "Warning: 'X' session variable default set multiple times in one call to session_variables().",
    "Assigning more than one default value in a single call warns.";





