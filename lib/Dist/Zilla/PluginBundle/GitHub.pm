package Dist::Zilla::PluginBundle::GitHub;

use Moose;

use warnings;
use strict;

with 'Dist::Zilla::Role::PluginBundle::Easy';

has login => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub { $_[0] -> payload -> {login} }
);

has token => (
	is   	=> 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub { $_[0] -> payload -> {token} }
);

has cpan => (
	is   	=> 'ro',
	isa     => 'Bool',
	lazy    => 1,
	default => 1
);

has p3rl => (
	is   	=> 'ro',
	isa     => 'Bool',
	lazy    => 1,
	default => 0
);

=head1 NAME

Dist::Zilla::PluginBundle::GitHub - GitHub plugins all-in-one

=head1 SYNOPSIS

In your F<dist.ini>:

    [@GitHub]

=head1 DESCRIPTION

This bundle automatically adds all the GitHub plugins.

=cut

sub configure {
	my $self = shift;

	$self -> add_plugins(
		['GitHub::Meta' => {
			login => $self -> login,
			token => $self -> token
		}],

		['GitHub::Update' => {
			login => $self -> login,
			token => $self -> token,
			cpan  => $self -> cpan,
			p3rl  => $self -> p3rl
		}]
	);
}

=head1 ATTRIBUTES

=over

=item C<login>

The GitHub login name. If not provided, will be used the value of
C<github.user> from the Git configuration, to set it, type:

    $ git config --global github.user LoginName

=item C<token>

The GitHub API token for the user. If not provided, will be used the
value of C<github.token> from the Git configuration, to set it, type:

    $ git config --global github.token GitHubToken

=item C<cpan>

If set to '1' (default), the GitHub homepage field will be set to the
CPAN page of the module.

=item C<p3rl>

If set to '1' (default '0'), the GitHub homepage field will be set to the
p3rl.org shortened URL (e.g. C<http://p3rl.org/My::Module>).
This takes precedence over the C<cpan> option (if both '1', p3rl will
be used).

=back

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dist::Zilla::PluginBundle::GitHub
