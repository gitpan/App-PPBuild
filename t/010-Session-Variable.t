#!/usr/sbin/perl
use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use_ok( 'App::PPBuild::Session::Variable' );
use App::PPBuild;

use vars qw/ $tmp /;
use Data::Dumper;

my $session = App::PPBuild::global->_session;

my $a;
ok( tie( $a, 'App::PPBuild::Session::Variable', $session, 'a' ));
is( $a, undef, 'no value for $a' );
ok( $a = 'test' , 'set $a');
is( $a, 'test', '$a value set.' );
$a = undef;
is( $a, undef, '$a value cleared.' );

