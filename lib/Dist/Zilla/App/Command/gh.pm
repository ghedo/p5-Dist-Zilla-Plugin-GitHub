package Dist::Zilla::App::Command::gh;
# ABSTRACT: Use the GitHub plugins from the command-line

use strict;
use warnings;

our $VERSION = '0.49';

use Dist::Zilla::App -command;

=head1 SYNOPSIS

    # create a new GitHub repository for your dist
    $ dzil gh create [<repository>]

    # update GitHub repo information
    $ dzil gh update

=cut

sub abstract    { 'use the GitHub plugins from the command-line' }
sub description { 'Use the GitHub plugins from the command-line' }
sub usage_desc  { '%c %o [ update | create [<repository>] ]' }

sub opt_spec {
    [ 'profile|p=s',  'name of the profile to use',
        { default => 'default' }  ],

    [ 'provider|P=s', 'name of the profile provider to use',
        { default => 'Default' }  ],
}

sub execute {
    my ($self, $opt, $arg) = @_;

    my $zilla = $self->zilla;

    $_->gather_files for
        eval { Dist::Zilla::App->VERSION('7.000') }
            ? $zilla->plugins_with(-FileGatherer)
            : @{ $zilla->plugins_with(-FileGatherer) };

    if ($arg->[0] eq 'create') {
        require Dist::Zilla::Dist::Minter;

        my $minter = Dist::Zilla::Dist::Minter->_new_from_profile(
            [ $opt->provider, $opt->profile ], {
                chrome => $self->app->chrome,
                name   => $zilla->name,
            },
        );

        my $create = _find_plug($minter, 'GitHub::Create');
        my $root   = `pwd`; chomp $root;
        my $repo   = $arg->[1];

        $create->after_mint({
            mint_root => $root,
            repo      => $repo,
            descr     => $zilla->abstract
        });
    } elsif ($arg->[0] eq 'update') {
        _find_plug($zilla, 'GitHub::Update')->after_release;
    }
}

sub _find_plug {
    my ($self, $name) = @_;

    foreach (@{ $self->plugins }) {
        return $_ if $_->plugin_name =~ /$name/;
    }
}

1; # End of Dist::Zilla::App::Command::gh
