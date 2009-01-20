package App::PPBuild::CUI;
use strict;
use warnings;

#{{{ POD

=pod

=head1 NAME

App::PPBuild::CUI - Command line user interface for App::PPBuild

=head1 DESCRIPTION

Used by the ppbuild script, and PPBFiles when run directly. Processes arguments
and runs the specified tasks.

=head1 SYNOPSIS

Used internally, you probably do not want to use this yourself.

=head1 METHODS

Many of these rely on data obtained from Getopt::Long to run.

=over 4

=cut

#}}}

# If there is a ppbuild dir present then add it to @INC so the PPBuild file can
# access its support files.

use lib q/ PPBuild inc /;
use Getopt::Long;
use Carp;

our %GETOPT;
our $one;

GetOptions(
    "file:s"    => \$GETOPT{ file },
    "session:s" => \$GETOPT{ load_session },
    "quiet"     => \$GETOPT{ quiet },
    "again"     => \$GETOPT{ again },
    "tasks"     => \$GETOPT{ task_list },
    "help"      => sub { print help(); exit(0) },
);

=item help()

Prints the command line help to STDOUT.

=cut

sub help {
    return <<EOT;
Usage: $0 [OPTIONS] Task1, Task2, ...

Options:
    --tasks   | -t  Show a list of tasks
    --help    | -h  Show this message
    --file    | -f  Specify the PPBuild file to use (Defaults to PPBFile)
    --session | -s  Specify a session file to track which tasks have been run
                    across multiple ppbuild executions.
    --quiet   | -q  Quiet, as in do not print messages each task returns.
                    Messages generated while tasks run will still be displayed.
    --again   | -a  Force the tasks to run again.

$0 is used to build a perl project.

EOT
}

=item new()

Create a new App::PPBuild object.

The only argument is the App::PPBuild object to use, if none is specified it
will use the global.

=cut

sub new {
    return $one if $one;
    my $class = shift;
    $class = ref $class || $class;
    my ( $ppb ) = @_;
    croak( 'you must provide a ppbuild object.' ) unless $ppb;
    $one = bless { %GETOPT, ppb => $ppb }, $class;
    return $one;
}

=item ppb()

Set/Retrieve the App::PPBuild object used by the CUI.

=cut

sub ppb {
    my $self = shift;
    $self->{ ppb } = shift if @_;
    return $self->{ ppb };
}

=item again()

Set/Retrieve the global 'again' flag. (ppbuild --again)

=cut

sub again {
    my $self = shift;
    $self->{ again } = shift if @_;
    return $self->{ again };
}

=item quiet()

Set/Retrieve the 'quiet' flag. (ppbuild --quiet)

=cut

sub quiet {
    my $self = shift;
    $self->{ quiet } = shift if @_;
    return $self->{ quiet };
}

=item run()

Run the tasks specified in the command line arguments. Arguments will be
shifted off, NOT preserved, This is by design.

=cut

sub run {
    my $self = shift;
    my ( $file ) = shift;
    $self->file( $file );
    $self->load_session;
    my $tasklist = $self->task_list;
    print $tasklist if $tasklist;

    return unless ( @ARGV );

    my @return;
    while ( my $task = shift( @ARGV )){
        my $out = $self->ppb->runtask( $task, $self->again );
        print "$out\n" if $out and $out !~ m/^\d+$/ and not $self->quiet; #Do not print the default return of 1
        push @return => $out;
    }
    print "\n" unless $self->quiet;

    $self->write_session;
    return @return
}

=item file()

Set and or load the PPBFile being used.

Warning, PPBFiles only work on the global App::PPBuild object, if the CUI was
created with a different App::PPBuild object this will generate a warning.

=cut

sub file {
    my $self = shift;
    $self->{ file } ||= shift if @_;
    return unless $self->{ file };
    warn "WARNING: Loading PPBFile while using non-global APP::PPBuild object! "
        . "This is probably not what you want. "
        . "Tasks in the PPBFile will go to the global PPBuild object, not the active one.\n"
        if $self->ppb ne App::PPBuild::global();
    require $self->{ file };
    return $self->{ file };
}

=item load_session()

Load the specified session file.

=cut

sub load_session {
    my $self = shift;
    return unless my $file = $self->{ load_session };
    return unless -e $file;
    $self->ppb->load_session( $file );
    return $self->{ load_session };
}

=item write_session()

Write the session to the specified file.

=cut

sub write_session {
    my $self = shift;
    return unless my $file = $self->{ load_session };
    $self->ppb->write_session( $file );
    return $self->{ load_session };
}

=item task_list()

Print the list of available tasks.

=cut

sub task_list {
    my $self = shift;
    return unless $self->{ task_list };
    my $out = "Available Tasks:\n";
    my $length = 0;
    for my $task ( $self->ppb->tasklist ) {
        my $this = length( $task );
        $length = $this if $this > $length;
    }
    for my $task ( sort( $self->ppb->tasklist )) {
        $out .= sprintf( " %-${length}s - \%s\n", $task, $self->ppb->describe( $task ) || "" );
    }
    return $out . "\n";
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

