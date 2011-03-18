#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Dist::Zilla::Plugin::GitHub::Create' ) || print "Bail out!
";
    use_ok( 'Dist::Zilla::Plugin::GitHub::Meta' ) || print "Bail out!
";
    use_ok( 'Dist::Zilla::Plugin::GitHub::Update' ) || print "Bail out!
";
    use_ok( 'Dist::Zilla::PluginBundle::GitHub' ) || print "Bail out!
";

}

diag( "Testing Dist::Zilla::Plugin::GitHub::Create $Dist::Zilla::Plugin::GitHub::Create::VERSION, Perl $], $^X" );
diag( "Testing Dist::Zilla::Plugin::GitHub::Meta $Dist::Zilla::Plugin::GitHub::Meta::VERSION, Perl $], $^X" );
diag( "Testing Dist::Zilla::Plugin::GitHub::Update $Dist::Zilla::Plugin::GitHub::Update::VERSION, Perl $], $^X" );
diag( "Testing Dist::Zilla::PluginBundle::GitHub $Dist::Zilla::PluginBundle::GitHub::VERSION, Perl $], $^X" );
