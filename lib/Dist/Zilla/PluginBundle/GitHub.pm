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

has 'fork' => (
	is      => 'ro',
	isa     => 'Bool',
	lazy    => 1,
	default => sub {
			defined $_[0] -> payload -> {bugs} ?
				$_[0] -> payload -> {bugs} : 1
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

has 'metacpan' => (
	is   	=> 'ro',
	isa  	=> 'Bool',
	lazy    => 1,
	default => sub {
			defined $_[0] -> payload -> {metacpan} ?
				$_[0] -> payload -> {metacpan} : 0
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
			wiki => $self -> wiki,
			fork => $self -> fork
		}],

		['GitHub::Update' => {
			repo => $self -> repo,
			cpan => $self -> cpan,
			p3rl => $self -> p3rl,
			metacpan => $self -> metacpan
		}]
	);
}

=head1 ATTRIBUTES

=over

=item C<repo>

The name of the GitHub repository. By default the dist name (from dist.ini)
is used.

=item C<homepage>

The META homepage field will be set to the value of the homepage field set on
the GitHub repository's info if this option is set to true (default).

=item C<wiki>

The META homepage field will be set to the URL of the wiki of the GitHub
repository, if this option is set to true (default is false) and if the GitHub
Wiki happens to be activated (see the GitHub repository's C<Admin> panel).

=item C<bugs>

The META bugtracker web field will be set to the issue's page of the repository
on GitHub, if this options is set to true (default) and if the GitHub Issues happen to
be activated (see the GitHub repository's C<Admin> panel).

=item C<fork>

If the repository is a GitHub fork of another repository this option will make
all the information be taken from the original repository instead of the forked
one, if it's set to true (default).

=item C<cpan>

The GitHub homepage field will be set to the CPAN page of the module if this
option is set to true (default),

=item C<p3rl>

The GitHub homepage field will be set to the p3rl.org shortened URL (e.g.
C<http://p3rl.org/My::Module>) if this option is set to true (default is false).

This takes precedence over the C<cpan> option (if both are true, p3rl will
be used).

=item C<metacpan>

The GitHub homepage field will be set to the metacpan.org distribution URL (e.g.
C<http://metacpan.org/release/My-Module>) if this option is set to true (default
is false).

This takes precedence over the C<cpan> and C<p3rl> options (if all three are
true, metacpan will be used).

=back

=head1 SEE ALSO

L<Dist::Zilla::Plugin::GitHub::Meta>, L<Dist::Zilla::Plugin::GitHub::Update>

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

no Moose;

__PACKAGE__ -> meta -> make_immutable;

1; # End of Dist::Zilla::PluginBundle::GitHub
