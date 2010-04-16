package IrcTranslator::Handler::Stream::Channel;

use Moose;
use URI::Escape;
use LWP::Simple ();
use JSON;
use AnyEvent;
use AnyEvent::IRC;
use AnyEvent::IRC::Connection;
use AnyEvent::IRC::Client;
use Tatsumaki::MessageQueue;
use Tatsumaki::Error;
use Data::Dumper;

extends 'Tatsumaki::Handler';
__PACKAGE__->asynchronous(1);


my %streams;

sub create_stream {
    my $self = shift;
    my ( $server, $channel ) = @_;

    my $mq = Tatsumaki::MessageQueue->instance( $server.$channel );
    unless ($streams{$server}{$channel}) {
	my $con = AnyEvent::IRC::Client->new;
	$con->reg_cb(
	    registered => sub {
		my $self = shift;
		$con->enable_ping(60);
		$con->send_srv("JOIN", '#'.$channel);
	    },
	    irc_privmsg => sub {
		my ( $self, $msg ) = @_;

		# comment data

		my $prefix = $msg->{prefix};
		$prefix =~ m/^(.*?)\!/;
		my $name = $1;
		my $comment = $msg->{params}->[-1];


		# translate

		my $trans_url = 'http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=' . uri_escape($comment).'&langpair=en%7Cja';
		my $json = LWP::Simple::get($trans_url);
		my $result = from_json($json);

		my $comment_jp = $result->{responseData}->{translatedText};


		my @word_list;
		for my $word (split(/\s+/,$comment)) {
		    if ($word =~ /^[a-zA-Z]+$/) {
			push @word_list, qq(<a href="http://smart.fm/jisho/$word" target="_blank">$word</a>);
		    } else {
			push @word_list, $word;
		    }
		}
		my $comment_with_link = join(' ',@word_list);


		$mq->publish( { type => 'privmsg', name => $name, comment => $comment_with_link, comment_jp => $comment_jp } );
	    },
	    );

	$con->connect( $server, 6667, { nick => 'irc_translator', user => 'irc_translator', real => 'the bot' } );

	$streams{$server}{$channel} = $con;
    }
}

		

sub get {
    my $self = shift;
    my ( $server, $channel ) = @_;

    my $session = $self->request->param('session')
	or Tatsumaki::Error::HTTP->throw(500, "'session' needed");

    $streams{$server}{$channel} or $self->create_stream( $server, $channel );
    my $mq = Tatsumaki::MessageQueue->instance( $server.$channel );
    $mq->poll_once( $session, sub {
	my @events_published = @_;
	$self->write( \@events_published );
	$self->finish;
		    });
}


no Moose;

1;
