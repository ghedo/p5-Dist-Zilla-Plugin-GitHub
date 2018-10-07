use strict;
use warnings;

use Dist::Zilla::Plugin::GitHub ();
use Git::Wrapper ();
use Test::More 0.96;

my @tests = (
    {
        remote => 'git@github.com:tester/Testing.git',
        repo_name => 'tester/Testing',
    },
    {
        remote => 'git@github.com:tester/Testing',
        repo_name => 'tester/Testing',
    },
);

for my $test (@tests) {
    subtest 'remote ' . $test->{remote}, sub {
        my $gh = Dist::Zilla::Plugin::GitHub->new;

        my $remote = $test->{remote};

        no warnings 'redefine', 'once';
        local *Git::Wrapper::remote = sub { "Fetch URL: $remote" };
        local *Dist::Zilla::Plugin::GitHub::log = sub {};

        is(
            $gh->_get_repo_name,
            $test->{repo_name},
            'expected repo name',
        );
    };
}

done_testing;
