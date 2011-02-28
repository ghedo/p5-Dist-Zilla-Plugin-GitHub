package Dist::Zilla::PluginBundle::GitHub;

use Moose;

use warnings;
use strict;

extends 'Dist::Zilla::Plugin::GitHub';

with 'Dist::Zilla::Role::PluginBundle::Easy';

has '+repo' => (
	lazy    => 1,
	default => sub { $_[0] -> payload -> {repo} }
);

# GitHub::Meta

has 'homepage' => (
	is      => 'ro',
	isa     => 'Bool',
	lazy    => 1,
	default => sub {
			defined $_[0] -> payload -> {homepage} ?
				$_[0] -> payload -> {homepage} : 1
		}
);

has 'bugs' => (
	is      => 'ro',
	isa     => 'Bool',
	lazy    => 1,
	default => sub {
			defined $_[0] -> payload -> {bugs} ?
				$_[0] -> payload -> {bugs} : 1
		}
);

has 'wiki' => (
	is      => 'ro',
	isa     => 'Bool',
	lazy    => 1,
	default => sub {
			defined $_[0] -> payload -> {wiki} ?
				$_[0] -> payload -> {wiki} : 0
		}
);

# GitHub::Update

has 'cpan' => (
	is   	=> 'ro',
	isa  	=> 'Bool',
	lazy    => 1,
	default => sub {
			defined $_[0] -> payload -> {cpan} ?
				$_[0] -> payload -> {cpan} : 1
		}
);

has 'p3rl' => (
	is   	=> 'ro',
	isa  	=> 'Bool',
	lazy    => 1,
	default => sub {
			defined $_[0] -> payload -> {p3rl} ?
				$_[0] -> payload -> {p3rl} : 0
		}
);

=head1 NAME

Dist::Zilla::PluginBundle::GitHub - GitHub plugins all-in-one

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName
    $ git config --global github.token GitHubToken

then, in your F<dist.ini>:

    [@GitHub]
    repo = SomeRepo

=head1 DESCRIPTION

This bundle automatically adds all the GitHub plugins.

=cut

sub configure {
	my $self = shift;

	$self -> add_plugins(
		['GitHub::Meta' => {
			repo => $self -> repo,
			homepage => $self -> homepage,
			bugs => $self -> bugs,
			wiki => $self -> wiki
		}],

		['GitHub::Update' => {
			repo => $self -> repo,
			cpan => $self -> cpan,
			p3rl => $self -> p3rl
		}]
	);
}

=head1 ATTRIBUTES

=over

=item C<repo>

The name of the GitHub repository. By default the dist name (from dist.ini)
is used.

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
