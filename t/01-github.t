use strict;
use warnings;

use Dist::Zilla::Plugin::GitHub ();
use Test::Fatal qw( exception );
use Test::More 0.96;

my @tests = (
    {
        name    => 'have github.user',
        user    => 'tester',
        success => 1,
    },
    {
        name    => 'do not have github.user',
        user    => '',
        success => 0,
    }
);

for my $test (@tests) {
    subtest $test->{name}, sub {
        no warnings 'redefine';
        *Dist::Zilla::Plugin::GitHub::_get_git_github_user = sub {
            $test->{user};
        };

        if ($test->{success}) {
            is(
                exception { Dist::Zilla::Plugin::GitHub->new },
                undef,
                'no exception without github.user',
            );
            return;
        }
        like(
            exception { Dist::Zilla::Plugin::GitHub->new },
            qr{\QMissing value 'github.user' in git config},
            'exception when no github.user set',
        );
    };
}

done_testing;
