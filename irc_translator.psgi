use strict;
use FindBin qw($Bin);
use lib $Bin . '/lib';
use IrcTranslator;

if ($0 eq __FILE__) {
    require Plack::Runner;
    my $app = Plack::Runner->new;
    $app->parse_options(@ARGV);
    return $app->run(IrcTranslator->webapp);
}

IrcTranslator->webapp;
