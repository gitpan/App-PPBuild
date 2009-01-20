package App::PPBuild::Session::Variable;
use strict;
use warnings;

use Tie::Scalar;

our @ISA = qw(Tie::Scalar);

sub TIESCALAR {
    my ( $class, $session, $ident ) = @_;
    $class = ref $class || $class;
    return bless { session => $session, ident => $ident }, $class;
}

sub FETCH {
    my $self = shift;
    return $self->session->current_variable( $self->ident );
}

sub STORE {
    my $self = shift;
    $self->session->current_variable( $self->ident, @_ );
}

sub ident {
    my $self = shift;
    return $self->{ ident };
}

sub session {
    my $self = shift;
    return $self->{ session };
}

1;
