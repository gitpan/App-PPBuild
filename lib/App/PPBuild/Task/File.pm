use strict;
use warnings;

package App::PPBuild::Task::File;

#{{{ POD

=pod

=head1 NAME

App::PPBuild::Task::File - A task for PPBuilder.

=head1 DESCRIPTION

Used for tasks that create a file.

=head1 SYNOPSIS

    App::PPBuild::Task::File->new(
        name => $name,
        code => $code,
        deps => [ qw/ ...deps... / ],
        flags => { %flags },
    );

=head1 METHODS

=over 4

=cut

#}}}

use base 'App::PPBuild::Task';
use Carp;

=item hook_completed()

Use hook_completed to verify a file with the name of the task exists.

=cut

sub hook_completed {
    my $self = shift;
    my ( $exitref ) = shift;

    unless ( -e $self->name ) {
        croak( "File '" . $self->name . "' Does not exist after task has run.\n" );
    }
}

=item ran()

Override ran() to return true (1) if a file with the name of th task exisits.

=cut

sub ran {
    my $self = shift;
    return 1 if ( -e $self->name );
    return $self->SUPER::ran( @_ );
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

