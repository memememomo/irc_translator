package IrcTranslator;

use Tatsumaki::Application;
use Tatsumaki::Handler;

sub h($) {
    my $class = shift;
    eval "require $class" or die $@;
    $class;
}


sub webapp {
    my $class = shift;

    my $word = '[\w\.\-]+';
    my $app = Tatsumaki::Application->new([
	"/($word)/($word)/poll" => h 'IrcTranslator::Handler::Stream::Channel',
	"/($word)/($word)" => h 'IrcTranslator::Handler::Html',
					  ]);
    $app->template_path( "root/template" );
    $app->static_path( "root/static" );

    $app->psgi_app;
}

1;
