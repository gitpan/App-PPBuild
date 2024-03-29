use strict;
use warnings;

package App::PPBuild::Task;

#{{{ POD

=pod

=head1 NAME

App::PPBuild::Task - A basic task for PPBuilder, also the base class for new task types.

=head1 DESCRIPTION

All tasks for PPBuilder should be based on, or compatible with this class.

You will probably never need to create an object of this class yourself.
Generally you should use the task(), file(), or group() functions from
PPBuilder.pm. You would only need to create new instances of this object
yourself if you are creating an extenstion to PPBuilder.

=head1 SYNOPSIS

    App::PPBuild::Task->new(
        name => $name,
        code => $code,
        deps => [ qw/ ...deps... / ],
        flags => { %flags },
    );

=head1 METHODS

=over 4

=cut

#}}}

=item new()

Create a new instance of a Task object.

Named parameters:

    name   - Name of the task.
    code   - coderef or string of shell commands.
    deps   - Tasks this task depends on.
    flags  - list of flags.
    description - Task description.

=cut

sub new {
    my $class = shift;
    $class = ref $class || $class;
    my %params = @_;

    my $self = bless {
        name => $params{ name },
        code => $params{ code } || undef,
        deps => $params{ deps } || [],
        flags => $params{ flags } || {},
        description => $params{ description } || "No Description",
        %{ hook_proto( %params ) },
    }, $class;

    return $self;
}

=item run()

Run the task. If the task has been run it will not run again unless the 'again'
flag is set. Will determine code type, run it, and then check to be sure the
code ran succesfully.

If the code is a perl sub then any parameters passed to run() will be passed
into the task code.

=cut

sub run {
    my $self = shift;
    return "Task " . $self->name . " Has already been run." if $self->ran and not $self->flag( 'again' );
    return $self->_run( @_ );
}

=item run_again()

Run the task even if it has already been run. Usage is identical to run().

=cut

sub run_again {
    my $self = shift;
    return $self->_run( @_ );
}

sub _run {
    my $self = shift;

    $self->{ ran }++;

    return 1 unless my $code = $self->code;

    my $exit;
    my $ref = ref $code;
    if ( $ref eq 'CODE' ) {
        $exit = $code->( @_ );
    }
    elsif ( $ref ) {
        $exit = hook_run( $code, @_ );
    }
    else { # Not a reference, shell 'script'
        exit($? >> 8) if system( $code );
    }

    $self->hook_completed( \$exit );
    return $exit;
}

=item deplist

Returns a list of tasks depended on by this task.

=cut

sub deplist {
    my $self = shift;
    return $self->{ deps };
}

=item ran()

Returns the number of times this task has been run.

=cut

sub ran {
    my $self = shift;
    return $self->{ ran };
}

sub _set_ran {
    my $self = shift;
    $self->{ ran } = shift if @_;
    return $self->{ ran };
}

=item flag()

Returns the value of the specified flag.

=cut

sub flag {
    my $self = shift;
    my ( $flag ) = @_;
    return $self->{ flags }->{ $flag };
}

=item flaglist()

Returns the list of flags.

=cut

sub flaglist {
    my $self = shift;
    return [ keys %{ $self->{ flags }} ];
}

=item code

Returns the code if present, will be a coderef, string.

=cut

sub code {
    my $self = shift;
    return $self->{ code };
}

=item name

Returns the name of the task.

=cut

sub name {
    my $self = shift;
    return $self->{ name };
}

sub description {
    my $self = shift;
    return $self->{ description };
}

=back
=head1 HOOK METHODS AND FUNCTIONS

Hook methods are available for use in subclasses.

=over 4

=item hook_completed()

hook_completed is run at the end of the run() method. It is a method. The only
parameter is a reference to the $exit string that run() will return. You can
check or modify this as necessary.

The point of this hook is to verify that everything the task was supposed to do
has been done. An example would be the File task, which uses this hook to
verify a file with the name of the task has been created.

=cut

sub hook_completed { }

=item hook_proto()

hook_proto is used to add your own parameter parsing to new(). It is *not* a
method. The parameters are everything passed to new() except the class. The
hook should return a hash of properties to give the new instance of the object.

=cut

sub hook_proto { {} }

=item hook_run()

hook_run is used to run code of types other than coderef or string. It is a
method. The 'code' from the task is the first parameter. Parameters from
command line come next. Returns a string.

=cut

sub hook_run { croak( "Cannot run code of type: " . ref( shift ) . "\n" ) }

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

