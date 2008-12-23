use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

App::PPBuild - Perl Project Build System, The low-learnign curve simple build system.

=head1 DESCRIPTION

Replacement for make on large perl projects. Similar to rake in concept, but no
need to install and learn Ruby. The goal is to have a similar sytax to make
when defining tasks (or rules in make), while bringing in the power of being
able to write your rules in perl.

Some tasks are just simpler to write as shell commands. Doing this in PPBuild is
just as easy as in make. In fact, shell tasks are easier since there is no need
to put a tab before each command. As well all the commands in the rule run in
the same shell session.

One of the primary goals is to have a small learning curve. You should not have
to weed through miles of documentation searching for the small subset of
features you need. At the same time PPBuild is meant to be easily expandable,
so if you need a lot of extra functionality it is there.

=head1 SYNOPSIS

PPBFile:

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

    $ ppbuild --file PPBFile --tasks
    Tasks:
     MyTask  - Completes the first task
     MyTask2 - Completes MyTask2
     ...

    $ ppbuild MyTask2 MyFile

    $ ppbuild ..tasks to run..

=head1 HOW IT WORKS

The ppbuild script uses a PPBFile file to build a project. This is similar to make
and Makefiles. PPBFiles are pure perl files. To define a task use the Task,
Group, or file functions. Give a task a desription using the describe function.

The first argument to any task creation function is the name of the task. The
last argument is usually the code to run. All arguments in the middle should be
names of tasks that need to run first. The code argument can be a string, or a
perl sub. If the code is a sub it will be run when the task is run. If the code
is a string it will be passed to the shell using system().

The ppbuild script automatically adds PPBuild to the library search path. If you
wish to write build system specific support files you can place them in a PPBuild
directory and not need to manually call perl -I PPBuild, or add use lib 'PPBuild'
yourself in your PPBFile. As well if you will be sharing the codebase with
others, and do not want to add PPBuild as a requirement you can copy PPBuild.pm into
the PPBuild directory in the project.

=head1 FUNCTIONS

=over 4

=cut

#}}}

package App::PPBuild;
use vars qw($VERSION);
$VERSION = '0.05';

use Exporter 'import';
our @EXPORT = qw/ task file group describe /;
our @EXPORT_OK = qw/ runtask tasklist /;

use App::PPBuild::Task;
use App::PPBuild::Task::File;
use Carp;

my %TASKS;
my %DESCRIPTIONS;

=item describe()

Used to add or retrieve a task description.

    describe( 'MyTask', 'Description' );
    describe 'MyTask', "Description";
    my $description = describe( 'MyTask' );

Exported by default.

=cut

sub describe {
    my ( $name, $description ) = @_;
    $DESCRIPTIONS{ $name } = $description if $description;
    return $DESCRIPTIONS{ $name };
}

=item task()

Defines a task.

    task 'MyTask1', qw/ Dependancy /, "Shell Code";
    task 'MyTask2', sub { ..Perl Code... };
    task 'MyTask3', <<EOT;
    ...Lots of shell commands...
    EOT
    # Specify the :again: flag to force the task to run every time it is
    # specified instead fo only once. Same as using runtask( 'task', 1 );
    task 'MyTask4', ':again:', qw/ ..Deps.. /, CODE;

Exported by default.

=cut

sub task {
    my $name = shift;
    return 0 unless $name;
    my $code = pop;

    my ($depends, $flags) = _parse_flags(@_);

    addtask( App::PPBuild::Task->new(
        name => $name,
        code => $code,
        deps => $depends,
        flags => $flags,
    ));
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

    my ($depends, $flags) = _parse_flags(@_);

    addtask( App::PPBuild::Task::File->new(
        name => $name,
        code => $code,
        deps => $depends,
        flags => $flags,
    ));
}

=item group()

Group together several tasks as one new task. Tasks will run in specified
order. Syntax is identical to task() except it *DOES NOT* take code as the last
argument.

Exported by default.

=cut

sub group {
    task @_, undef; #undef as last argument, aka undef as code.
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

    croak( "No task named '$name'.\n" ) unless $TASKS{ $name };

    # Run the Tasks this one depends on:
    runtask( $_ ) for @{ $TASKS{ $name }->deplist };

    return $TASKS{ $name }->run( $again );
}

=item tasklist()

Returns a list of task names. Return is an array, not an arrayref.

    my @tasks = tasklist();
    my ( $task1, $task2 ) = tasklist();

=cut

sub tasklist {
    return keys %TASKS;
}

sub _parse_flags {
    my $depends = [ ];
    my $flags = { };

    foreach my $dep (@_) {
        if ( $dep =~ /^:([^:]+):$/ ) {
            $flags->{ $1 } = 1;
        } else {
            push @$depends, $dep;
        }
    }

    return ($depends, $flags);
}

sub addtask {
    my $task = shift;
    my $name = $task->name;
    croak( "Task '$name' has already been defined!\n" ) if $TASKS{ $name };
    $TASKS{ $name } = $task;
}

1;

__END__

=back

=head1 EXTENSIONS

One of the goals of PPBuild is to be very simple with a small learning curve.
Thus additional functionality should be done as extensions. We do not want to
clutter PPBuild with a lot of extra functionality to get in the way.

Creating an extension for PPBuild is easy:
 * Create any new Task types you want as modules that use App::PPBuild::Task as a base.
   - See the POD for App::PPBuild for a list of available hooks and methods.
 * Create a module that uses App::PPBuild, and exports new functions similar to task() and file().
   - The exported functions should build instances of your custom task types,
   then add them to the list using addtask().

=head1 AUTHOR

Chad Granum E<lt>exodist7@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2008 Chad Granum

licensed under the GPL version 3.
You should have received a copy of the GNU General Public License
along with this.  If not, see <http://www.gnu.org/licenses/>.

=cut

