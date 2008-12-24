package App::PPBuild::Makefile;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

App::PPBuild::Makefile - Generate a Makefile that calls PPBuild rules in a
session.

=head1 DESCRIPTION

Used within a Makefile.PL to add or append PPBuild rules to a Makefile. The
rules will have the same name as the PPBuild tasks, with an optional prefix.
Each rule will simply call ppbuild and the specified task. Each call to ppbuild
will specify .session as the session file, thus if you call make TaskA TaskA,
TaskA will run only once. Each rule calls a clear_session rule, this way the
session si cleared each time you call make.

The idea behind this is that most people are familar with make. You want your
user to be able to download your project and use make as expected. As well many
automated tools rely on make.

CPAN's testing tools know how to run a Makefile.PL. This module is designed to
be used in a Makefile.PL. If you want to put your project on CPAN and have the
automated tools work you should use this module. If you have a 'test' ppbuild
task, then the Makefile will have a 'test' rule that calls ppbuild test. This
way CPAN's automated testing system can find it.

=over 4

=item NOTE

This is still not a replacement for Module::Install. Module::Install does a LOT
more than simply allow CPAN to test your work. As well Module::Install is able
to install your module and do much more. This is simply here to help you when
you have to use ppbuild, but need make to work.

=back

=head1 SYNOPSIS

example/Makefile.PL:
    use App::PPBuild::Makefile;

    # Load the PPBFile
    ppbfile 'PPBFile';

    # Write a makefile that passes all rules to ppbuild.
    # makefile will use a session to preserve rule has already been run behavior.
    write_makefile;

=head1 EXPORTED FUNCTIONS

=over 4

=cut

#}}}

use Exporter 'import';
our @EXPORT = qw/ ppbfile write_makefile /;

# If there is a ppbuild dir present then add it to @INC so the PPBuild file can
# access its support files.
use lib "App::PPBuild";

use App::PPBuild qw/ runtask tasklist describe session write_session /;

=item ppbfile()

Loads the specified PPBFile. Takes only 1 argument, the PPBFile filename.

=cut

sub ppbfile {
    my $file = shift || "PPBFile";
    require $file;
}

=item write_makefile()

Writes out a Makefile that calls ppbuild tasks.

Parameters: (All parameters are optional)
    write_makefile(
        file => 'Makefile',
        op   => '>', # Use >> to append the rules to the end of the makefile
                     # instead of overwriting the makefile.
        prefix => 'ppb_', # The prefix to attach to the rule names. Default is
                          # none.
    );

=cut

sub write_makefile {
    my %params = @_;
    my $file = $params{ file } || "Makefile";
    my $op = $params{ op } || ">";
    my $prefix = $params{ prefix } || "";

    open( my $makefile, $op, $file ) || die( "Cannot open $file for writing: $!\n" );
    print $makefile header( $prefix );
    print $makefile rule( $_, $prefix ) for tasklist();
    close( $makefile );
}

sub header {
    my ( $prefix ) = @_;
    return <<EOT;
${prefix}default: tasks

${prefix}tasks:
\t\@ppbuild --tasks

${prefix}clear_session:
\t\@rm -f .session

EOT
}

sub rule {
    my ( $name, $prefix ) = @_;
    return <<EOT;
${prefix}${name}: ${prefix}clear_session
\t\@ppbuild --session .session $name

EOT
}

__END__

=back

=head1 AUTHOR

Chad Granum E<lt>exodist7@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2008 Chad Granum

licensed under the GPL version 3.
You should have received a copy of the GNU General Public License
along with this.  If not, see <http://www.gnu.org/licenses/>.

=cut

