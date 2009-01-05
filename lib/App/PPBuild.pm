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

It is now possible to use PPBuild and Module::Install together. See the Pod for
Module::Install::PPBuild.

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

    #!/usr/bin/perl       #Only needed if you want to run the PPBFile directly, but always a good idea.

    use inc::App::PPBuild #If you DO want to include a copy of App::PPBuild with your distribution.
    # *** OR ***
    use App::PPBuild;     #If you DO NOT want to include a copy of App::PPBuild with your distribution.

    # Define the task 'MyTask'
    task "MyTask", [ "Dependancy task 1", "Dep task 2", ... ], "Task named MyTask, run perl code.", sub {
        ... Perl code to Complete the task ...
    };

    # Task name and code are the only required arguments.
    task "MyTask2", <<SHELL;
        echo "Task: MyTask2"
        ... Other shell commands ...
    SHELL

    task "MyTask3", [qw/ MyTask MyTask2 /], "MyTask3 runs shell commands", "Shell commands";

    # Description, Flags, and Dependancies can be specified in any order so
    # long as they are between the task name and code.
    file "MyFile", "MyFile creates an empty file called MyFile", { FlagA => 1 }, [qw/ MyTask /], "touch MyFile";

    group "MyGroup", [qw/ MyTask MyTask2 MyTask3 MyFile /], "Group of tasks";

    # You can also define a task in a named parameter style using a hash:
    task {
        name => 'A Task',
        code => sub { ... }, # Or "shell code"
        deps => [ 'MyTask', 'MyTask2' ],
        flags => { FlagA => 1, FlagB => 'Blah' },
        description => 'This is a task.',
    };

    # If you want to be able to run your PPBFile directly, instead of relying on
    # the ppbuild command, call do_tasks() just before the end.
    do_tasks();

    1; #You must end your file with a true value.

To use it:

    $ ppbuild MyTask

    $ ppbuild MyGroup

    $ ppbuild --file PPBFile --tasks
    Tasks:
     MyTask  - Task named MyTask, run perl code.
     MyFile  - MyFile creates an empty file called MyFile
     ...

    $ ppbuild MyTask2 MyFile

    $ ppbuild ..tasks to run..

If you call do_tasks() at the end of the PPBFile you can call it directly:

    $ ./PPBFile --tasks
    $ ./PPBFile MyTask MyTask2


=head1 HOW IT WORKS

The ppbuild script uses a PPBFile file to build a project. This is similar to make
and Makefiles. PPBFiles are pure perl files. To define a task use the task,
group, or file functions.

The first argument to any task creation function is the name of the task. The
last argument is usually the code to run. The code argument can be a string, or
a perl sub. If the code is a sub it will be run when the task is run. If the
code is a string it will be passed to the shell using system().

The arguments between the name and code can come in any order. Hashref
arguments are treated as flag lists. Arrayref arguments are treated as lists of
dependancies. The first string parameter is treated as the task description.
With exception of string arguments, all arguments between name and code of the
same type will be combined and flattened.

The ppbuild script automatically adds ./PPBuild/ to the library search path. If
you wish to write build system specific support files you can place them in a
PPBuild directory and not need to manually call perl -I PPBuild, or add use lib
'PPBuild' yourself in your PPBFile. As well if you will be sharing the codebase
with others, and do not want to add PPBuild as a requirement you can copy
PPBuild.pm into the PPBuild directory in the project.

=head1 METHODS / EXPORTED FUNCTIONS

PPBuild is object oriented under the hood. The following are both methods on
App::PPBuild objects, and exported as functions. When used in function form
they act upon a global default App::PPBuild object.

=over 4

=cut

#}}}

package App::PPBuild;

BEGIN {
    $INC{ 'App/PPBuild.pm' } = $INC{ 'inc/App/PPBuild.pm' } if $INC{ 'inc/App/PPBuild.pm' } and not $INC{ 'App/PPBuild.pm' };
    *inc::App::PPBuild:: = *App::PPBuild::;
}

use vars qw($VERSION);
$VERSION = '0.13';

use Exporter 'import';
our @EXPORT = qw/ task file group do_tasks /;
our @EXPORT_OK = qw/ runtask tasklist session write_session load_session add_task parse_params describe /;

use lib qw/ PPBuild inc /;
use App::PPBuild::Task;
use App::PPBuild::Task::File;
use App::PPBuild::CUI;
use Carp;

my $GLOBAL;

=item task()

Defines a task.

    task 'TaskName', [ qw/ Dependancy1 ... /], { FlagA => 'blah', ... }, "Task Description", CODE;
    task 'MyTask1', [qw/ Dependancy /], "Shell Code";
    task 'MyTask2', sub { ..Perl Code... };
    task 'MyTask3', <<SHELL;
    ...Lots of shell commands...
    SHELL

The first parameter is always the task name, the last parameter is always the
code. Any arrayref passed in will be used as a list of dependancies, any
hashref passed in will be considered a set of flags. The first string passed in
will be used as the task description. If multiple arrayrefs for hashrefs are
passed in they will be combined and flattened. If multiple strings are
speciofied between the code and the task name they will be ignored and a
warning will be generated.

You can also use a hash to define a task in a named parameter style.

    task {
        name => 'NAME', #string
        code => CODE,   #String or coderef
        deps => DEPS,   #arrayref
        flags => FLAGS, #hashref
        description => DESCRIPTION, #string
    };

=cut

sub task {
    my $self = get_self( \@_ );
    my $params = parse_params( @_ );
    $self->addtask( App::PPBuild::Task->new( %$params ));
}

=item file()

Specifies a file to be created. Will not run if file already exists. Syntax is
identical to task().

=cut

sub file {
    my $self = get_self( \@_ );
    my $params = parse_params( @_ );
    $self->addtask( App::PPBuild::Task::File->new( %$params ));
}

=item group()

Group together several tasks as one new task. Tasks will run in specified
order. Syntax is identical to task() except it *DOES NOT* take code as the last
argument.

=cut

sub group {
    my $self = get_self( \@_ );
    $self->task( @_, undef ); #undef as last argument, aka undef as code.
}

=item do_tasks()

Call this at the end of your PPBFile if you want to be able to run the PPBFile
directly. Will parse the parameters and run the specified tasks.

=cut

sub do_tasks {
    my $self = get_self( \@_ );
    App::PPBuild::CUI->new( $self )->run;
}

=back

=head1 METHODS / IMPORTABLE FUNCTIONS

PPBuild is object oriented under the hood. The following are both methods on
App::PPBuild objects, and importable as functions. When used in function form
they act upon a global default App::PPBuild object.

=over 4

=item describe()

Used to retrieve a task description.

    my $description = describe( 'MyTask' );

=cut

sub describe {
    my $self = get_self( \@_ );
    my ( $name ) = @_;
    return $self->task_accessor( $name )->description;
}

=item runtask()

Run the specified task.

First argument is the task to run.
If the Second argument is true the task will be forced to run even if it has
been run already.

=cut

sub runtask {
    my $self = get_self( \@_ );
    my ( $name, $again ) = @_;

    croak( "No task named '$name'.\n" ) unless $self->task_accessor( $name );

    # Run the Tasks this one depends on:
    runtask( $_ ) for @{ $self->task_accessor( $name )->deplist };

    return $self->task_accessor( $name )->run( $again );
}

=item tasklist()

Returns a list of task names. Return is an array, not an arrayref.

    my @tasks = tasklist();
    my ( $task1, $task2 ) = tasklist();

=cut

sub tasklist {
    my $self = get_self( \@_ );
    return keys %{ $self->{ tasks }};
}

=item addtask()

Add a task to the list of available tasks.

    $self->addtask( $task_ref, $task_name );
    $self->addtask( PPBuild::Task->new( name => 't', ... ), 't' );

=cut

sub addtask {
    my $self = get_self( \@_ );
    my $task = shift;
    my $name = $task->name;
    croak( "Task '$name' has already been defined!\n" ) if $self->task_accessor( $name );
    $task->_set_ran( $self->session->{ $name } || 0 );
    return $self->task_accessor( $name, $task );
}

=item task_accessor()

Retrieve or set a specific task.

    my $task = task_accessor( 'MyTask' );
    task_accessor( 'MyTask', App::PPBuild::Task->new() );

=cut

sub task_accessor {
    my $self = get_self( \@_ );
    my $name = shift;
    return unless $name;
    $self->{ tasks }->{ $name } = shift if @_;
    return $self->{ tasks }->{ $name };
}

#{{{ Session code
# Originally I went with YAML for sessions. However since deciding to make
# PPBuild self-bundling, I want to minimize the non-core dependancies. As such
# I have written a simple dumper for sessions. If sessions become more
# complicated than 'name => ran', then I will probably switch back to yaml.

=item session()

Specify a session file to use. Sessions store how many times each task has been
run. Use a session if you are scripting the use of ppbuild and want to ensure
task run counts are preserved between executions of ppbuild.

    session '.session';

You can also pass a session hashref:

    session {
        TaskA => 5,
        TaskB => 22,
        TaskC => 18,
    };

=cut

sub session {
    my $self = get_self( \@_ );

    if ( @_ ) {
        my $arg = shift;
        if ( ref $arg and ref $arg eq 'HASH' ) {
            $self->{ session } = $arg;
        }
        else {
            $self->{ session } = load_session( $arg );
        }

        for my $task ( values %{ $self->{ tasks }} ) {
            $task->_set_ran( $self->{ session }->{ $task->name } || 0 );
        }
    }
    return $self->{ session };
}

=item write_session()

Write the current run counts to a session file.

    write_session '.session';

=cut

sub write_session {
    my $self = get_self( \@_ );
    my $sessionfile = shift;
    open( my $FILE, '>', $sessionfile ) || die( "Unable to open session file: $sessionfile. $!\n" );
    print $FILE "{\n";
    print $FILE "    " . $_->name . " => " . ( $_->ran || '0' ) . ",\n" for ( values %{ $self->{ tasks }} );
    print $FILE "};";
    close( $FILE );
}

=item load_session()

Reads a session file and returns a hashref. This will not actually set the
session, to do that use session();

    load_session '.session';

=cut

sub load_session {
    my $self = get_self( \@_ );
    my $sessionfile = shift;
    return {} unless $sessionfile;

    my $content;
    open( my $FILE, '<', $sessionfile ) || die( "Unable to open session file: $sessionfile. $!\n" );
    {
        $/ = undef;
        $content = <$FILE>;
    }
    close( $FILE );

    unless ( $content ) {
        warn( "Session file is empty!" );
        return {};
    }

    my $session = eval $content;
    warn( "Unable to process session: $@\n" ) if $@;
    return ( ref $session eq 'HASH' ) ? $session : {};
}

#}}}

=item parse_params()

Parses the standard task defenition parameters.

Returns:

    return {
        name => NAME,
        code => CODE,
        deps => DEPENDENCIES,
        flags => FLAG LIST,
        description => DESCRIPTION,
    };

If the first argument is a hash, the hash will be returned, no other parameters
will be parsed. Otherwise the first param will be the task name, the last will
be the code, the arrayrefs will be treated as dep lists, hashrefs as flag sets,
the first string as the description.

=cut

sub parse_params {
    my $params = [ @_ ];

    my $name = shift( @$params );
    return unless $name;

    # If the first param is a hash then the task is defiend with named parameters.
    if ( ref $name eq 'HASH' ) {
        croak( "Task name not provided in hash!\n" ) unless $name->{ name };
        warn( "Warning: Ignoring parameters after hash in task defenition '" . $name->{ name } . "'\n" ) if @$params;
        return {
            deps => [],
            flags => {},
            description => "No Description",
            %$name
        };
    }

    my $code = pop( @$params );
    my $deps = [];
    my $flags = {};
    my $description = "";

    for my $item ( @$params ) {
        if ( ref $item eq 'ARRAY' ) {
            push @$deps => @$item;
        }
        elsif ( ref $item eq 'HASH' ) {
            $flags = { %$flags, %$item };
        }
        elsif ( ref $item ) {
            croak( "Not sure what to do with: " . ref $item . " in task declaration: $name\n" );
        }
        else {
            warn( "Extra string in paremeters list: '$item' task description already set to: '$description'\n" ) if $description;
            $description = $item unless $description;
        }
    }

    return {
        name => $name,
        code => $code,
        deps => $deps,
        flags => $flags,
        description => $description || "No Description",
    };
}

=back

=head1 METHODS

The following methods are to be used when using App::PPBuild in an object
oriented way.

=over 4

=item get_self()

Used to retrieve self. Use instead of shift in methods that can also be
exported/imported as functions. If the function was called as a method it will
act the same as $self = shift(@_). If the function is used as an imported function
it will return the global object without modifying @_.

It takes a reference to the @_ array.

usage:

    sub MyMethod {
        my $self = get_self( \@_ );
        ...
    }

=cut

sub get_self {
    my ( $params ) = @_;
    return ( ref $params->[0] eq 'App::PPBuild' ) ? shift( @$params ) : global();
}

=item global()

returns the default/global App::PPBuild object.

=cut

sub global {
    $GLOBAL = App::PPBuild->new() unless $GLOBAL;
    return $GLOBAL;
}

=item new()

Create a new App::PPBbuild object.

No arguments are required.

usage:

    App::PPBuild->new(
        tasks => { TaskName => App::PPBuild::Task->new() },
        session => { TaskName => 0 },
    );

=cut

sub new {
    my $class = shift;
    $class = ref $class || $class;
    my %proto = @_;
    return bless {
        tasks => {},
        session => {},
        %proto,
    }, $class;
}

1;

__END__

=back

=head1 FLAGS

Flags are used to specify special behavior. They can be specified using hashrefs in the task declaration.

    task 'MyTask4', [ 'DepA', 'DebB' ], { 'FlagA' => 1, 'FlagB' => 'blah' }, CODE;

The following flags are available for use:

=over 4

=item always

the always flag is used to specify that the task should always run when called.
This means every time it is listed as a dependancy, and every time it is listed
at the command prompt. It will run each time regardless of how many times it
has already run. True or False.

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
task types, then add them to the list using $self->addtask().

=item Use the new module in your PPBuild file.

After 'use App::PPBuild;' in the PPBuild file add 'use App::PPBuild::YourExt;'
to bring in your own exported functions.

=back

=head1 SEE ALSO

=over 4

=item inc::App::PPBuild

Use this if you want to bundle PPBuild with your code.

=item App::PPBuild::CUI

Command line user interface module for PPBuild.

=item App::PPBuild::Task

The base Task object. All tasks should inherit from this one.

=item App::PPBuild::Task::File

The File task object. Tasks that create a file use this object.

=item App::PPBuild::Makefile

Used in a Makefile.PL to generate a Makefile with rules for each PPBuild task.
This does not do any kind of conversion, the makefile simply deligates to
PPBuild.

=item Module::Install::PPBuild

A PPBuild extension for Module::Install. With this PPBuild and Module::Install
can be used together.

=back

=head1 AUTHOR

Chad Granum E<lt>exodist7@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2009 Chad Granum

licensed under the GPL version 3.
You should have received a copy of the GNU General Public License
along with this.  If not, see <http://www.gnu.org/licenses/>.

=cut

