#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;

my $CLASS = 'App::PPBuild::Session';
use_ok( $CLASS );
use App::PPBuild::Session;
use App::PPBuild;

use vars qw/ $one $tmp /;

$one = $CLASS->new(
    App::PPBuild::global(),
    {
        variables => { a => 'A', b => 'B' },
        ran => { a => 1, b => 2 },
    }
);
isa_ok( $one, $CLASS, "Session is a $CLASS" );

dies_ok { $CLASS->new() } "new dies w/o params";

lives_ok { $CLASS->new( App::PPBuild::global() )} "Lives w/ only the ppbuild object";

$one->file( undef );
is( $one->file, undef, "Cleared file" );
$one->file( 'fake' );
is( $one->file, 'fake', "file set" );
$one->file( undef );

$one->loaded( undef );
is_deeply( $one->loaded, {}, "Cleared loaded" );
$one->loaded( 'fake' );
is( $one->loaded, 'fake', "loaded set" );
$one->loaded( undef );

$one->current( undef );
is_deeply( $one->current, {}, "Cleared current" );
$one->current( 'fake' );
is( $one->current, 'fake', "current set" );
$one->current( undef );

is( $one->initialized( 'a' ), undef, 'a is not initialized' );
is( $one->current_variable( 'a' ), undef, 'a is not set' );
is( $one->initialized( 'a' ), 1, 'a is initialized' );
$one->current_variable( 'a', 'a' );
is( $one->current_variable( 'a' ), 'a', 'a is set' );

is( $one->initialized( 'b' ), undef, 'b is not initialized' );
is( $one->initialized( 'b', 1 ), 1, 'b is initialized' );
is( $one->initialized( 'b' ), 1, 'b is initialized' );
is( $one->initialized( 'b', undef ), undef, 'b is cleared' );
is( $one->initialized( 'b' ), undef, 'b is not initialized' );

is( $one->loaded_variable( 'a' ), undef, "no 'a' in loaded data" );
$one->load( { variables => { a => 'a' }} );
is( $one->loaded_variable( 'a' ), 'a', "'a' is 'a' in loaded data" );

