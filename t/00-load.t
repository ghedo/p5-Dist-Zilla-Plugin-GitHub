#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Dist::Zilla::Plugin::GitHub::Create' ) || print "Bail out!
";
    use_ok( 'Dist::Zilla::Plugin::GitHub::Update' ) || print "Bail out!
";

}

diag( "Testing Dist::Zilla::Plugin::GitHub::Create $Dist::Zilla::Plugin::GitHub::Create::VERSION, Perl $], $^X" );
diag( "Testing Dist::Zilla::Plugin::GitHub::Update $Dist::Zilla::Plugin::GitHub::Update::VERSION, Perl $], $^X" );
