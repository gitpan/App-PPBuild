package App::PPBuild;
use strict;
use warnings;

###########################################################
# Package stuff and magic
###########################################################
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

    # Create some session variables. These follow a make like order for where they get their values.
    # If the given ID has already been initialized it will get the value it already has
    # If the environment variable is set the value will be that.
    # If there is no environment variable then it will try to pull it from the
    # loaded session (see sessions)
    # If there is no environment variable or session value it will use the
    # default/fallback listed in this call
    # undef is the final fallback.
    session_variables(
        IDENT => my $variable = 'default/fallback value'

        # Will be the $HOME environment variable, or the session HOME variable, or '/home/bob'.
        HOME  => my $home = '/home/bob',
        CC    => our $CC  = '/usr/bin/gcc',

        A     => my $a, #No default
    );

    # This will make it so any variables tied to the 'A' session variable will
    # have 'blah' as their value.
    $a = 'blah';

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

    # Include this line if you want to be able to call your PPBFile directly
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

You can also call it directly if you call do_tasks() at the end of your PPBFile:

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

=head1 OBJECT ORIENTED

PPBuild is object oriented under the hood. Unless otherwise stated, all
subroutines are both methods on App::PPBuild objects, and exported as
functions. When used in function form they act upon a global default
App::PPBuild object.

=cut

#}}}

use vars qw($VERSION);
$VERSION = '0.18';

use Exporter qw/import/;
our @EXPORT = qw/ task file group svars session_variables load_session write_session variable_list do_tasks /;
our @EXPORT_OK = qw/ describe runtask runtask_again tasklist add_task task_accessor parse_params /;

#{{{ Magic

#{{{ POD

=head1 MAGIC

A lot of packages out there do not document their magic. I will outline it up
front in hopes that being aware of it will help you avoid any nasty gotchas they
may bring. I have not found or heard of any related to these pieces of magic,
but you might have.

=over 4

=item BEGIN modifies $INC

App::PPBuild may be loaded directly, or it may be loaded indirectly by
inc::App::PPBuild. When the latter is used it loads inc/App/PPBuild.pm, which
means the other modules being loaded will try to load App::PPBuild again. This
is because %INC keeps record of every module that was loaded, and which file it
was found in.

To solve this problem App::PPBuild will add itself to %INC under the correct
relative path name:

    BEGIN {
        $INC{ 'App/PPBuild.pm' } ||= __FILE__;
    }

=item App::PPBuild overrides inc::App::PPBuild's import() function.

When you use inc::App::PPBuild instead of App::PPBuild you do not get all the
exported functions. To solve this App::PPBuild will override
inc::App::PPBuild's import function to be an alias to App::PPBuilds. This
override takes effect immedietly since all 'use' directives are treated the
same as a BEGIN block, and inc::App::PPBuild uses App::PPBuild.

=item use lib qw/ PPBuild inc /;

Since inc may have bundled copies of required modules it is added to the
library path. As well PPBuild is added to the path to make it easy for users to
seperate functionality into included modules that are kept seperate from the
bundled ones.

=back

=cut

#}}}

BEGIN {
    $INC{ 'App/PPBuild.pm' } ||= __FILE__;
}

# This courtesy of ewilhelm.
sub inc::App::PPBuild::import {
    shift;
    unshift( @_, __PACKAGE__ );
    goto &App::PPBuild::import;
}

use lib qw/ PPBuild inc /;

#}}}

use App::PPBuild::Task;
use App::PPBuild::Task::File;
use App::PPBuild::CUI;
use App::PPBuild::Session;
use App::PPBuild::Session::Variable;
use Filter::Simple;
use Carp;
use Storable;

###########################################################
# Package variables
###########################################################
#{{{ PACKAGE VARIABLES

=head1 PACKAGE VARIABLES

These are the package variables for App::PPBuild. You should not directly
access these. Look for an accessor instead. Documented for completeness.

=over 4

=item $App::PPBuild::GLOBAL

The global App::PPBuild object that is used by default when using exported
functions instead of method form.

=cut

our $GLOBAL;
#}}}

###########################################################
# Methods / Exported functions
###########################################################
#{{{ POD

=back

=head1 METHODS / EXPORTED FUNCTIONS

The following methods are also exported as functions by default (see not on object orientation above.)

=over 4

=cut

#}}}

#{{{ task()

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
#}}}
#{{{ file()

=item file()

Specifies a file to be created. Will not run if file already exists. Syntax is
identical to task().

=cut

sub file {
    my $self = get_self( \@_ );
    my $params = parse_params( @_ );
    $self->addtask( App::PPBuild::Task::File->new( %$params ));
}
#}}}
#{{{ group()

=item group()

Group together several tasks as one new task. Tasks will run in specified
order. Syntax is identical to task() except it *DOES NOT* take code as the last
argument.

=cut

sub group {
    my $self = get_self( \@_ );
    $self->task( @_, undef ); #undef as last argument, aka undef as code.
}
#}}}
#{{{ do_tasks()

=item do_tasks()

Call this at the end of your PPBFile if you want to be able to run the PPBFile
directly. Will parse the parameters and run the specified tasks.

=cut

sub do_tasks {
    my $self = get_self( \@_ );

    # Only do this once.
    return if $self->{ do_tasks };
    $self->{ do_tasks } = 1;

    my $cui = App::PPBuild::CUI->new( $self );
    $cui->file( 'PPBFile' );
    $cui->run;
}
#}}}

###########################################################
# Methods / Importable Functions
###########################################################
#{{{ POD

=back

=head1 METHODS / IMPORTABLE FUNCTIONS

The following methods can be imported as functions (see not on object orientation above.)

    use App::PPBuild qw/ describe runtask runtask_again

=over 4

=cut

#}}}

#{{{ describe()

=item describe()

Used to retrieve a task description.

    my $description = describe( 'MyTask' );

=cut

sub describe {
    my $self = get_self( \@_ );
    my ( $name ) = @_;
    return $self->task_accessor( $name )->description;
}
#}}}
#{{{ runtask()

=item runtask()

Run the specified task.

First argument is the task to run, all additional arguments will be passed to
the code if it is a perl sub.

=cut

sub runtask {
    my $self = get_self( \@_ );
    my ( $name, @params ) = @_;
    return $self->_runtask(
        name => $name,
        task_params => \@params,
        again => 0,
    );
}
#}}}
#{{{ runtask_again()

=item runtask_again()

Run a task even if it has already been run. First argument is task, additonal
arguments are passed to the code if it is a perl sub.

=cut

sub runtask_again {
    my $self = get_self( \@_ );
    my ( $name, @params ) = @_;
    return $self->_runtask(
        name => $name,
        task_params => \@params,
        again => 1,
    );
}
#}}}
#{{{ tasklist()

=item tasklist()

Returns a list of task names. Return is an array, not an arrayref.

    my @tasks = tasklist();
    my ( $task1, $task2 ) = tasklist();

=cut

sub tasklist {
    my $self = get_self( \@_ );
    return keys %{ $self->{ tasks }};
}
#}}}
#{{{ addtask()

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
    $task->_set_ran( $self->_session->ran( $name ) || 0 );
    return $self->task_accessor( $name, $task );
}
#}}}
#{{{ task_accessor()

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
#}}}
#{{{ parse_params()

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
        croak( "Task name not provided in hash!\n" ) unless $name->{ name } and not ref $name->{ name };
        warn( "Warning: Ignoring parameters after hash in task defenition '" . $name->{ name } . "'\n" ) if @$params;
        return {
            deps => [],
            flags => {},
            description => "No Description",
            %$name
        };
    }

    croak( "Name must be a string!\n" ) if ref $name;

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
#}}}

###########################################################
# Session related variable methods / functions
###########################################################
#{{{ POD

=back

=head1 SESSION VARIABLE METHODS/FUNCTIONS

This set of subroutines deals specifically with non-temporary variables. These
are variables which can be stored in a session for use next time ppbuild is
run. They also have make-like behavior, the value will be pulled from the
following sources in this order:

=head3 CURRENT

If the variable has been modified during run-time.

=head3 ENV

Pulled from the environment variables.

=head3 SESSION

Pulled from the loaded session

=head3 DEFAULT

A default you specify when initializing the session variable.

=head2 METHODS/FUNCTIONS

All of these are exported by default.

=over 4

=cut

#}}}

#{{{ session_variables()

=item session_variables()

Used to initialize and access session variables.

Usage:

    my $a;
    our $b;
    session_variables(
        'IDENT' => my $var = 'default',
        'A' => $a = 'default_a',
        'B' => $b = 'default_b',
    );

This will declare the variables $a, $b, and $var. It will tie each scalar to
the current session variable with the given IDENT. The value of the scalar will
then be set to the environment variable IDENT, the value brought in for IDENT
from the loaded session, or to the 'default' specified.

If you change the value of the scalar it will be reflected in the session, and
in any other scalar tied to that IDENT *regardless of scope*. When the session
is saved the current value of IDENT will be stored.

You can tie as many scalars as you want to each IDENT. However you should only
specify a default value once per IDENT and call to session_variables. As well
you should not use the same scalar more than once per call to
session_variables. Both these conditions are checked for and will generate
warnings.

Additional Example:

    session_variables(
        # Will be the previously initialised value, or $ENV{ HOME } or the
        # session's HOME, or '/home/bob' if nothing else is found.
        'HOME' => my $home = '/home/bob',

        # Get the system CC compiler, or the default listed
        'CC'   => my $cc = '/usr/sbin/gcc',

        # Tie a second scalar to the same value - not useful except when
        # session_variables is called in different scopes.
        'HOME' => my $home_clone,

        # This will generate a warning since a second default is being provided
        # for the same IDENT.
        'HOME' => my $home_bad = 'new_default',

        # This will generate a warning since the same scalar is being tied again.
        'ANYTHING' => $home_bad,

        # This will generate both warnings.
        'HOME' => $home_bad = 'another_default',
    );

=cut

sub session_variables {
    my $self = get_self( \@_ );
    my %set;
    while ( @_ ) {
        my ( $ident, $default ) = @_[0,1];

        warn( "Warning: you listed a variable more than once in a single call to session_variables(). Hint: ident was '$ident'" ) if $set{ \$_[1] };
        tie( $_[1], 'App::PPBuild::Session::Variable', $self->_session, $ident );
        $set{ \$_[1] } = 1;

        if ( defined $default ) {
            warn( "Warning: '$ident' session variable default set multiple times in one call to session_variables()." ) if $set{ $ident };
            $set{ $ident } = 1;
        }

        $self->_session->init_variable( $ident, $default );

        splice(@_, 0, 2);
    }
}
#}}}
#{{{ svars()
=item svars()

Alias for session_variables(), syntax and purpose are identical.

=cut

sub svars {
    goto &session_variables;
}
#}}}
#{{{ load_session()

=item load_session

Load a session. first argument should be either a file name (YAML file) or a
hashref. Additonal arguments should be parameters.

    load_session( 'session.yaml', override => 1, clear => 1 );

If override is true then the variables from the session will become current.
This will override the typical order that puts environment variables first. Any
value specified for variables in the session will become the value. Previously
initialized session variables that are not overriden by the session will remain
unchanged.

If clear is true then the current values for all session variables will be
cleared. No value will remain initialized. Next time the variable is accessed
it will be reinitialized, first pulling from ENV, then the session. This
clearing takes place before the override if that is also specified.

Example data structure:

    {
        variables => {
            HOME => '/home/bob',
            CC => '/bin/gcc',
        },
        ran => {
            Task_A => 5,
            Task_B => 2,
            ...
        }
    }

=cut

sub load_session {
    my $self = get_self( \@_ );
    my ( $data ) = @_;
    $self->_session->load( @_ );
}
#}}}
#{{{ write_session()

=item write_session()

Save the current session. Sessions are stored as YAML files. Only argument is a
filename. If no argument is specified then the filename the session was loaded
from will be used. If the session was not loaded from a file and no file is
specified a warning will be generated and write_session will return false.

=cut

sub write_session {
    my $self = get_self( \@_ );
    return $self->_session->save( @_ );
}
#}}}
#{{{ variable_list()

=item variable_list()

returns a list of session variables that have been initialized.

=cut

sub variable_list {
    my $self = get_self( \@_ );
    return $self->_session->variable_list;
}
#}}}

###########################################################
# Methods
###########################################################
#{{{ POD

=back

=head1 METHODS

The following methods are to be used when using App::PPBuild in an object
oriented way. They are not exported, and you probably will never need them
unless you are writing an extension.

=over 4

=cut

#}}}

#{{{ get_self()

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
    return ( ref $params->[0] eq __PACKAGE__ ) ? shift( @$params ) : global();
}
#}}}
#{{{ global()

=item global()

returns the default/global App::PPBuild object.

=cut

sub global {
    $GLOBAL = App::PPBuild->new() unless $GLOBAL;
    return $GLOBAL;
}
#}}}
#{{{ new()

=item new()

Create a new App::PPBbuild object.

None of the arguments are required.

usage:

    App::PPBuild->new(
        tasks => { TaskName => App::PPBuild::Task->new() },
        session => HASH OR FILENAME,
    );

=cut

sub new {
    my $class = shift;
    $class = ref $class || $class;
    my %proto = @_;
    my $session = delete $proto{ session };
    my $self = bless {
        tasks => {},
        %proto,
    }, $class;
    $self->load_session( $session ) if $session;
    return $self;
}
#}}}

###########################################################
# Private Methods
###########################################################
#{{{ POD

=back

=head1 PRIVATE METHODS

These Methods are private. You should never need these. They are documented for
completeness.

=over 4

=cut

#}}}

#{{{ _session()

=item _session()

Retrieve the current session object. Creates a new one if there is not one
already. No parameters.

=cut

sub _session {
    my $self = get_self( \@_ );
    $self->{ _session } ||= App::PPBuild::Session->new($self, {});
    return $self->{ _session };
}
#}}}
#{{{ __tasks()

=item __tasks()

Retrieve the internal tasks hash. Don't play with this. Used in the session
object only since it needs to modify this to set the ran counts.

=cut

sub __tasks {
    my $self = shift;
    return $self->{ tasks };
}
#}}}
#{{{ _runtask()

=item _runtask()

This is used by runtask and runtask_again. They are the friendly interfaces to
this.

Parameters:

    $self->_runtask(
        name => 'TASK_NAME=PARAM,PARAM2',
        task_params => \@params,
        again => BOOLEAN,
    );

=cut

sub _runtask {
    my $self = get_self( \@_ );
    my %params = @_;
    my ( $name, $arg ) = split( /=/, $params{ name }, 2 );
    my @params = @{ $params{ task_params }};
    if ( $arg ) {
        push @params => eval "( $arg );";
        die( "Could not process arguments: ( $arg );\n$@\n" ) if $@;
    }

    croak( "No task named '$name'.\n" )
        unless my $task = $self->task_accessor( $name );

    # Run the Tasks this one depends on:
    runtask( $_ ) for @{ $task->deplist };

    return $params{ again } ? $task->run_again( @params )
                            : $task->run( @params );
}
#}}}

1;

#{{{ End Pod

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

#}}}
