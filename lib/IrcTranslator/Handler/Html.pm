package IrcTranslator::Handler::Html;
use Moose;

extends 'Tatsumaki::Handler';

sub get {
    my $self = shift;
    my ( $server, $channel ) = @_;
    $self->render( 'index.html' );
}

no Moose;

1;
