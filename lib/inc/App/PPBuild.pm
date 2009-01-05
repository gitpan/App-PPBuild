use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

inc::App::PPBuild - Copies App::PPBuild to inc/ then loads App::PPBuild.

=head1 DESCRIPTION

Use this instead of App::PPBuild if you want PPBuild to bundle itself into your
project/module. It is similar to Module::Install, it copies itself and all
App::PPBuild::* modules that are loaded into the ./inc/ directory.

=head1 SYNOPSIS

PPBFile:

    use inc::App::PPBuild;

    ... Define tasks ...

    # call do_tasks() st the end of your PPBFile so that you can call the
    # PPBFile directly. inc::App::PPBuild does not make the ppbuild script
    # available.
    do_tasks();

    1;

=head1 FUNCTIONS

These are subject to change and are not made available through exporter.

=over 4

=cut

#}}}

use App::PPBuild qw//;
use App::PPBuild::Makefile;
use File::Copy;

include( $_ ) for grep { /^App\/PPBuild/ } keys %INC;
include( 'Getopt/Long.pm' );

=item include()

Copy the specified module to the inc/ directory. Module should be in
'relative/path/to/module.pm' format.

=cut

sub include {
    my ( $module ) = @_;
    my $destination = "./inc/$module";
    mkpath( $destination );
    copy( $INC{ $module }, $destination );
    die ( "Cannot copy module '$module': $!\n" ) unless -e $destination;
    print "Included module: $module\n";
}

=item mkpath()

Essentially a recursive mkdir(). Also strips the module off the end of the
path. mkpath('path/to/module.pm') will create the 'path/to' directory tree.

=cut

sub mkpath {
    my ( $path ) = shift;
    $path =~ s,[^/]+$,,;
    $path =~ s,^[\./]+,,;
    _mkrdir( ".", split( /\/+/, $path ));
}

=item _mkrdir()

Recursive function to create each directory in a chain of directories.

To make dir: path/to:

    _mkdir( '.', 'path', 'to' );

=cut

sub _mkrdir {
    my $previous = shift;
    my $next = shift;
    return 1 unless $next;
    my $make = "$previous/$next";
    mkdir( $make );
    return _mkrdir( $make, @_ );
}

1;

__END__

=back

=head1 AUTHOR

Chad Granum E<lt>exodist7@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2009 Chad Granum

licensed under the GPL version 3.
You should have received a copy of the GNU General Public License
along with this.  If not, see <http://www.gnu.org/licenses/>.

=cut

