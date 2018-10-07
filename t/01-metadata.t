use strict;
use warnings;

use Dist::Zilla::Plugin::GitHub::Meta ();
use HTTP::Tiny ();
use Path::Tiny qw( path );
use Test::DZil qw( Builder simple_ini );
use Test::Fatal qw( exception );
use Test::More 0.96;

my @tests = (
    {
        name      => 'fail because repo is not found',
        continue  => 0,
        exception => 1,
    },
    {
        name      => 'succeed even when repo is not found',
        continue  => 1,
        exception => 0,
    },
);

for my $test (@tests) {
    subtest $test->{name}, sub {
        my $tzil = Builder->from_config(
            { dist_root => 'does-not-exist' },
            {
                add_files => {
                    path(qw(source dist.ini)) => simple_ini(
                        [ FakeRelease => ],
                        [
                            'GitHub::Meta' => {
                                continue_if_repo_not_found => $test->{continue},
                            },
                        ],
                    ),
                },
            },
        );

        no warnings 'redefine';
        *HTTP::Tiny::request = sub {
            my ($self, $method, $url) = @_;
            +{
                content => '{"message":":-)"}',
                status  => '404',
                success => 0,
                url     => $url,
            };
        };
        *Dist::Zilla::Plugin::GitHub::Meta::_get_repo_name = sub { 'sdf' };

        if ($test->{exception}) {
            like(
                exception { $tzil->release },
                qr{\Qincorrect repository URL (HTTP 404 from https://api.github.com/repos/sdf},
                'exception when repository URL detected incorrectly',
            );
            return;
        }

        is(
            exception { $tzil->release },
            undef,
            'no exception when repository URL detected incorrectly',
        );
    };
}

done_testing;
