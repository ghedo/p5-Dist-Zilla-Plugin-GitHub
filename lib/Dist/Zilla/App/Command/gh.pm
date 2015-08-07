package Dist::Zilla::App::Command::gh;
our $VERSION = '0.42';
use strict;
use warnings;

use Dist::Zilla::App -command;

=head1 NAME

Dist::Zilla::App::Command::gh - Use the GitHub plugins from the command-line

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
        @{ $zilla->plugins_with(-FileGatherer) };

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

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dist::Zilla::App::Command::gh
