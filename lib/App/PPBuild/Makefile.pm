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
session is cleared each time you call make.

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

See Module::Install::PPBuild if you want to use PPBuild and Module::Install in
conjunction. Module::Install::PPBuild uses this module to do most of the work.
The benefit of using Module::Install::PPBuild over this module is the helpful
rules such as manifest and dist that it creates for you. As well it will let
you use the install and test rules from Module::Install, along with extra rules
you define in PPBuild. If needed you can override Module::Install's default
rules.

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
use lib "PPBuild";

our $ppbfile;

use App::PPBuild;

=item ppbfile()

Loads the specified PPBFile. Takes only 1 argument, the PPBFile filename.

=cut

sub ppbfile {
    $ppbfile = shift || "PPBFile";
    require $ppbfile;
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
    print $makefile all( %params );
    close( $makefile );
}

=back

=head1 PRIVATE FUNCTIONS

=over 4

=item all()

Returns a string containing all the makefile rules for the PPBuild tasks.

=cut

sub all {
    my %params = @_;
    my $prefix = $params{ prefix } || "";
    my $out = header( $prefix ) . helpers( $prefix );
    $out .= rule( $_, $prefix ) for App::PPBuild::tasklist();
    return $out;
}

=item header()

Returns a string for the default rule.

=cut

sub header {
    my ( $prefix ) = @_;
    return <<EOT;

${prefix}default: tasks

EOT
}

=item helpers()

Returns the rules for printing a task list, and clear_session.

=cut

sub helpers {
    my ( $prefix ) = @_;
    return <<EOT;

${prefix}tasks:
\t\@perl ./$ppbfile --tasks

${prefix}clear_session:
\t\@rm -f .session

EOT
}

=item rule()

Takes a task name and a prefix.

Returns a makefile rule defenition (string) for the PPBuild task.

=cut

sub rule {
    my ( $name, $prefix ) = @_;
    return <<EOT;
${prefix}${name}: ${prefix}clear_session
\t\@perl ./$ppbfile --session .session $name

EOT
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

