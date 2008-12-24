use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

App::PPBuild - Perl Project Build System, The low-learning curve simple build system.

=head1 DESCRIPTION

Replacement for make on large perl projects. Similar to rake in concept, but no
need to install and learn Ruby. The goal is to have a similar syntax to make
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

=head1 WHAT PPBUILD IS NOT

PPBuild is not intended to replace Module::Install or similar utilities.
Module::Install is superb, if you have a module, or simple application that
needs to be installed you should use it. PPBuild is intended to be used on
projects where the makefiles Module::Install generates are not sufficient for
your needs, and making an extension to Module::Install is not an option.

The ultimate flaw in using a makefile on a large perl project is 'make' itself.
Make was designed with C projects in mind. Trying to manage a reasonably
compicated perl project build system with makefiles is a difficult task.
Module::Install is great for managing the makefile work for you on most modules
and apps, however if you need to do something complicated you run into the
'make' problem again when you extend Module::Install to write a more
complicated Makefile.

=head1 WHAT PPBUILD IS

The best way to explain what PPBuild is for is an example project.

You have a project based on someone else's program. This program takes modules
as extensions, as such you are writing several such modules. All your extension
modules are under active development, as such installing them each time you
change them is not an options. You are keeping track of each module, as well as
vendor modules and the vendor branch of the base program in seperate locations
under one root directory.

You need to create migrations to bring people from old versions to new ones.
You may have many versions of a database that might need to be loaded, dropped
or backed up at various times.

And finally, you need to create an intelligent system to deploy this massive
mess. You may be deploying new installs on virgin systems. You might be
upgrading an existing deployment.

Obviously Module::Install should be used on each module you are using. As well
the base program probably has its own deployment system you can work with.
However you need to tie it all together, and put support in place to allow
development and testing of all the components mentioned.

At this point you have a few options:

=over 4

=item Makefiles

You can write a series of Makefiles, which is how many of these projects start.
Once a perl project of this nature gets to a given size though you begin to
need a PHD in make.

=item External Utilities

You can use a non-perl tool such as rake. Rake is nice, but it requires
learning ruby. As well you need to have ruby installed on any system you want
to use the project on. Requiring ruby for a perl project is silly.

=item Module::Install::YourExtension

You can extend Module::Install, but the name says it all, it is intended for
modules. As well the ultimate output is a Makefile, so even though you are not
directly writing a Makefile you still need to worry about make and all it's
baggage.

=item Roll Your Own

You can roll your own from scratch. Sometimes a good option, but what if you
have several projects of this nature, wouldn't something reusable be nice?

=item PPBuild

You can use PPBuild. Use PPBuild instead of a Makefile, the syntax is similar,
but you can write your rules, or tasks as PPBuild calls them, in pure perl, or
as shell commands. It is a lot like rake in that it replaces make, but you do
not need to deal with ruby. It is reusable. It is designed for perl projects.

=back

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
Group, or file functions. Give a task a description using the describe function.

The first argument to any task creation function is the name of the task. The
last argument is usually the code to run. All arguments in the middle should be
names of tasks that need to run first or flags denoted by ':flag:'. The code
argument can be a string, or a perl sub. If the code is a sub it will be run
when the task is run. If the code is a string it will be passed to the shell
using system().

The ppbuild script automatically adds PPBuild to the library search path. If
you wish to write build system specific support files you can place them in a
PPBuild directory and not need to manually call perl -I PPBuild, or add use lib
'PPBuild' yourself in your PPBFile. As well if you will be sharing the codebase
with others, and do not want to add PPBuild as a requirement you can copy
PPBuild.pm into the PPBuild directory in the project.

=head1 FUNCTIONS

=over 4

=cut

#}}}

package App::PPBuild;
use vars qw($VERSION);
$VERSION = '0.08';

use Exporter 'import';
our @EXPORT = qw/ task file group describe /;
our @EXPORT_OK = qw/ runtask tasklist session write_session /;

use App::PPBuild::Task;
use App::PPBuild::Task::File;
use Carp;
use YAML::Syck qw//;

my %TASKS;
my %DESCRIPTIONS;
my $SESSION = {};

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

=item addtask()

Add a task to the list of available tasks.

    addtask( $task_ref, $task_name );
    addtask( PPBuild::Task->new( name => 't', ... ), 't' );

=cut

sub addtask {
    my $task = shift;
    my $name = $task->name;
    croak( "Task '$name' has already been defined!\n" ) if $TASKS{ $name };
    $task->_set_ran( $SESSION->{ $name } || 0 );
    $TASKS{ $name } = $task;
}

=item session()

Specify a session file to use. Sessions store how many times each task has been
run. Use a session if you are scripting the use of ppbuild and want to ensure
task run counts are preserved between executions of ppbuild.

    session '.session';
    session( 'session.yaml' );

=cut

sub session {
    my $sessionfile = shift;
    $SESSION = YAML::Syck::LoadFile( $sessionfile ) || die( "Cannot open session file: $!\n" );

    for my $task ( values %TASKS ) {
        $task->_set_ran( $SESSION->{ $task->name } || 0 );
    }
}

=item write_session()

Write the current run counts to a session file.

    write_session '.session';
    write_session( 'session.yaml' );

=cut

sub write_session {
    my $sessionfile = shift;
    my $out = {};
    for my $task ( values %TASKS ) {
        $out->{ $task->name } = $task->ran;
    }
    YAML::Syck::DumpFile( $sessionfile, $out );
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

1;

__END__

=back

=head1 EXTENSIONS

One of the goals of PPBuild is to be very simple with a small learning curve.
Thus additional functionality should be done as extensions. We do not want to
clutter PPBuild with a lot of extra functionality to get in the way.

Creating an extension for PPBuild is easy:

=over 4

=item Create new Task objects

Create any new Task types you want as modules that use App::PPBuild::Task as a
base. See the POD for App::PPBuild for a list of available hooks and methods.

=item Create a module exporting task creation functions

Create a module that uses App::PPBuild, and exports new functions similar to
task() and file(). The exported functions should build instances of your custom
task types, then add them to the list using addtask().

=item Use the new module in your PPBuild file.

After 'use App::PPBuild;' in the PPBuild file add 'use App::PPBuild::YourExt;'
to bring in your own exported functions.

=back

=head1 AUTHOR

Chad Granum E<lt>exodist7@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2008 Chad Granum

licensed under the GPL version 3.
You should have received a copy of the GNU General Public License
along with this.  If not, see <http://www.gnu.org/licenses/>.

=cut

