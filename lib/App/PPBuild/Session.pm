package App::PPBuild::Session;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

App::PPBuild::Session - Session object used by App::PPBuild to record run
counts and variables.

=head1 DESCRIPTION

App::PPBuild is capable of using sessions. This object takes care of loading
and saving run counts for tasks, and tracking variables that need to be
preserved.

=head1 METHODS

=over 4

=cut

#}}}

use YAML::Syck;
use Carp;

=item new()

Create a new App::PPBuild object. Takes 2 arguments, a PPBuild object, and
either a session hash, or a session yaml file.

    App::PPBuild->new( $ppbuild, { ran => {...}, variables => {...} };
    App::PPBuild->new( $ppbuild, 'session.yaml' };

=cut

sub new {
    my $class = shift;
    my ( $ppbuild, $data ) = @_;
    $class = ref $class || $class;
    my $self = bless( { }, $class );
    $self->ppbuild( $ppbuild ) || die( "Could not get PPBuild object, did you pass one to the constructor?" );;
    $self->load( $data ) || die( "Could not retrieve session data!" );
    return $self;
}

=item file()

Set or retrieve the session file name. Does not effect the session variables or
run counts.

=cut

sub file {
    my $self = shift;
    $self->{ file } = shift if @_;
    return $self->{ file };
}

=item loaded()

Accessor for the loaded hash which contains the values the session variables
had in the session file.

=cut

sub loaded {
    my $self = shift;
    $self->{ loaded } = shift if @_;
    $self->{ loaded } ||= {};
    return $self->{ loaded };
}

=item current()

Accessor for the current session variables hash.

=cut

sub current {
    my $self = shift;
    $self->{ current } = shift if @_;
    $self->{ current } ||= {};
    return $self->{ current };
}

sub variable_list {
    my $self = shift;
    return [ keys %{ $self->current }];
}

=item current_variable()

Get the current value of a session variable. If the value has not been
initialized it will be.

=cut

sub current_variable {
    my $self = shift;
    my $ident = shift;
    return unless $ident;
    $self->init_variable( $ident ) unless $self->initialized( $ident );
    $self->current->{ $ident } = shift if @_;
    return $self->current->{ $ident };
}

=item loaded_variable()

Get the value of a variable as it was stored in the session.

=cut

sub loaded_variable {
    my $self = shift;
    my $ident = shift;
    return unless $ident;
    return $self->loaded->{ $ident };
}

=item initialized()

Check if a variable has been initialized. Also used to mark a variable as
initialized.

Check:

    $self->initialized( 'var' );

Set:

    $self->initialized( 'var', 1 );

Unset:

    $self->initialized( 'var', undef );

=cut

sub initialized {
    my $self = shift;
    my $ident = shift;
    $self->{ initialized } ||= {};
    $self->{ initialized }->{ $ident } = shift if @_;
    return $self->{ initialized }->{ $ident };
}

=item init_variable()

Used to initialize a variable, takes a variable name, and a default value if no
other is found. Default is optional. Value is first obtained from the
environment, if that si not set then from the session, if that is not set then
from the default passed in.

=cut

sub init_variable {
    my $self = shift;
    my ( $ident, $default ) = @_;

    # Return if the variable has already been initialized
    return $self->current_variable( $ident ) if $self->initialized( $ident );
    $self->initialized( $ident, 1 );

    # Try to find a value
    if ( my $value = $ENV{ $ident } || $self->loaded_variable( $ident ) || $default ) {
        $self->current_variable( $ident, $value );
    }
    return $self->current_variable( $ident );
}

=item set_ran()

Set the run counts for the tasks in the associated PPBuild object.

    $self->ran(
        TASK_NAME  => 5,
        TASK_NAME2 => 2,
    );

=cut

sub set_ran {
    my $self = shift;
    my ( $set ) = @_;
    my $ppbuild = $self->ppbuild;
    my $out = {};

    $self->{ ran } = $set;

    for my $task ( values %{ $ppbuild->__tasks }) {
        $task->_set_ran( $set->{ $task->name } || 0 ) if $set;
        $out->{ $task->name } = $task->ran;
    }
    return $out;
}

=item ran()

Find the run count for a specific task. First argument is task name.

=cut

sub ran {
    my $self = shift;
    my ( $task ) = @_;
    return $self->{ ran }->{ $task };
}

=item ppbuild()

Get/Set the associated PPBuild object.

=cut

sub ppbuild {
    my $self = shift;
    $self->{ ppbuild } = shift if @_;
    return $self->{ ppbuild };
}

=item load()

Load a session yaml file or hash.

=cut

sub load {
    my $self = shift;
    my ( $data, %params ) = @_;
    $data = {} unless $data;

    if ( ref $data eq 'HASH' ) {
        $self->file( undef );
    }
    else {
        croak( "load takes a hashref or filename.\n" ) if (ref $data) or not -e $data;
        $data = LoadFile( $data ) || die( "Could not load YAML file: $data\n$!\n" );
        $self->file( $data );
    }

    $self->loaded( $data->{ variables }) if $data->{ variables };

    if( $params{ clear }) {
        $self->current( { } );
        delete $self->{ initialized };
    }

    if ( $params{ override }) {
        my $new_current =  { %{ $self->current }, %{ $data->{ variables }}};
        $self->current( $new_current );
        $self->initialized( $_, 1 ) for keys %$new_current;
    }

    $self->set_ran( $data->{ ran }) unless $params{ no_ran };
}

=item save()

Save the session, takes a filename. If no name is provided the loaded one will
be used.

=cut

sub save {
    my $self = shift;
    my ( $file ) = @_;
    $file ||= $self->file;
    unless ( $file ) {
        warn( "Session was not loaded from a file, and no file was specified!" );
        return 0;
    }
    my $data = {
        ran => $self->set_ran,
        variables => { %{ $self->loaded }, %{ $self->current }},
    };
    unless( DumpFile( $file, $data )) {
        warn( "Could not write YAML file: $data\n$!\n" );
        return 0;
    }
    return 1;
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

