use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

App::PPBuild - Perl Project Build System

=head1 DESCRIPTION

Replacement for make on large perl projects. Similar to rake in concept, but no
need to install and learn Ruby. The goal is to have a similar sytax to make
when defining tasks (or rules in make), while bringing in the power of being
able to write your rules in perl.

Some tasks are just simpler to write as shell commands. Doing this in PPBuild is
just as easy as in make. In fact, shell tasks are easier since there is no need
to put a tab before each command. As well all the commands in the rule run in
the same shell session.

=head1 SYNOPSIS

Makefile.ppb:

    use App::PPBuild; #This is required.

    describe "MyTask", "Completes the first task";
    task "MyTask", "Dependency task 1", "Dep task 2", ..., sub {
        ... Perl code to Complete the task ...
    };

    describe "MyTask2", "Completes MyTask2";
    task "MyTask2", qw/ MyTask /, <<EOT;
        echo "Task: MyTask2"
        ... Other shell commands ...
    EOT

    task "MyTask3", qw/ MyTask MyTask2 / , "Shell commands";

    describe "MyFile", "Creates file 'MyFile'";
    file "MyFile", qw/ MyTask /, "touch MyFile";

    describe "MyGroup", "Runs all the tasks";
    group "MyGroup", qw/ MyTask MyTask2 MyTask3 MyFile /;

To use it:
    $ ppbuild MyTask

    $ ppbuild MyGroup

    $ ppbuild --file Makefile.ppb --tasks
    Tasks:
     MyTask  - Completes the first task
     MyTask2 - Completes MyTask2
     ...

    $ ppbuild MyTask2 MyFile

    $ ppbuild ..tasks to run..

=head1 HOW IT WORKS

The ppbuild script uses a .ppb file to build a project. This is similar to make
and Makefiles. .ppb files are pure perl files. To define a task use the Task,
Group, or file functions. Give a task a desription using the describe function.

The first argument to any task creation function is the name of the task. The
last argument is usually the code to run. All arguments in the middle should be
names of tasks that need to run first. The code argument can be a string, or a
perl sub. If the code is a sub it will be run when the task is run. If the code
is a string it will be passed to the shell using system().

The ppbuild script automatically adds PPBuild to the library search path. If you
wish to write build system specific support files you can place them in a PPBuild
directory and not need to manually call perl -I PPBuild, or add use lib 'PPBuild'
yourself in your .ppb file. As well if you will be sharing the codebase with
others, and do not want to add PPBuild as a requirement you can copy PPBuild.pm into
the PPBuild directory in the project.

=head1 FUNCTIONS

=over 4

=cut

#}}}

package App::PPBuild;
use vars qw($VERSION);

$VERSION = '0.03';

use Exporter 'import';
our @EXPORT = qw/ task file group describe /;
our @EXPORT_OK = qw/ runtask tasklist /;

my %tasks;
my %descriptions;

=item describe()

Used to add or retrieve a task description.

    describe( 'MyTask', 'Description' );
    describe 'MyTask', "Description";
    my $description = describe( 'MyTask' );

Exported by default.

=cut

sub describe {
    my ( $name, $description ) = @_;
    $descriptions{ $name } = $description if $description;
    return $descriptions{ $name };
}

=item task()

Defines a task.

    task 'MyTask1', qw/ Dependancy /, "Shell Code";
    task 'MyTask2', sub { ..Perl Code... };
    task 'MyTask3', <<EOT;
    ...Lots of shell commands...
    EOT

Exported by default.

=cut

sub task {
    my $name = shift;
    return 0 unless $name;
    my $code = pop;
    my $depends = [ @_ ];

    _addtask(
        name => $name,
        code => $code,
        depends => $depends,
    );
}

=item file()

Specifies a file to be created. Will not run if file already exists. Syntax is
identical to task().

Exported by default.

=cut

sub file {
    my $name = shift;
    return 0 unless $name;
    my $code = pop;
    my $depends = [ @_ ];

    _addtask(
        name => $name,
        file => $name,
        code => $code,
        depends => $depends,
    );
}

=item group()

Group together several tasks as one new task. Tasks will run in specified
order. Syntax is identical to task() except it *DOES NOT* take code as the last
argument.

Exported by default.

=cut

sub group {
    my $name = shift;
    return 0 unless $name;
    my $depends = [ @_ ];

    _addtask(
        name => $name,
        depends => $depends,
    );
}

=item runtask()

Run the specified task.

First argument is the task to run.
If the Second argument is true the task will be forced to run even if it has
been run already.

Not exported by default.

=cut

sub runtask {
    my ( $name, $again ) = @_;

    die( "No such task: $name\n" ) unless $tasks{ $name };

    # Run the Tasks this one depends on:
    runtask( $_ ) for @{ $tasks{ $name }->{ depends }};

    my $file = $tasks{ $name }->{ file };

    # Unless we are told to run the task an additional time We want to return
    # true if the task has been run, or the file to be created is done.
    unless ( $again ) {
        return if $tasks{ $name }->{ ran };
        # This message should only be displayed if the rule was explicetly
        # stated in the command line, not if it is depended on by the called
        # Task. Thats why it is not stored anywhere.
        return "$file is up to date\n" if ( $file and -e $file );
    }

    # If the rule has no code assume it is a group, return true
    return unless my $code = $tasks{ $name }->{ code };

    my $exit;
    my $ref = ref $code;
    if ( $ref eq 'CODE' ) {
        $exit = $code->();
    }
    elsif ( $ref ) {
        die( "Unknown task code: '$ref' for task '$name'.\n" );
    }
    else { # Not a reference, shell 'script'
        exit($? >> 8) if system( $code );
    }

    croak( "File '$file' does not exist after file Task!\n" ) if ( $file and not -e $file );

    $tasks{ $name }->{ ran }++;

    return $exit;
}

=item tasklist()

Returns a list of task names. Return is an array, not an arrayref.

    my @tasks = tasklist();
    my ( $task1, $task2 ) = tasklist();

=cut

sub tasklist {
    return keys %tasks;
}

sub _addtask {
    my %params = @_;
    my $name = $params{ name };

    croak( "Task '$name' has already been defined!\n" ) if $tasks{ $name };

    $tasks{ $name } = { %params };
}

1;

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

