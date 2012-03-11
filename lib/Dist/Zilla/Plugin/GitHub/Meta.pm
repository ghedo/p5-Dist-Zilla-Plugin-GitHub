package Dist::Zilla::Plugin::GitHub::Meta;

use Moose;
use JSON;

use strict;
use warnings;

extends 'Dist::Zilla::Plugin::GitHub';

with 'Dist::Zilla::Role::MetaProvider';

has 'homepage' => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1
);

has 'bugs' => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1
);

has 'wiki' => (
	is      => 'ro',
	isa     => 'Bool',
	default => 0
);

has 'fork' => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1
);

=head1 NAME

Dist::Zilla::Plugin::GitHub::Meta - Add GitHub repo info to META.{yml,json}

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName

then, in your F<dist.ini>:

    [GitHub::Meta]
    repo = SomeRepo

=head1 DESCRIPTION

This Dist::Zilla plugin adds some information about the distribution's
GitHub repository to the META.{yml,json} files, using the official L<CPAN::Meta>
specification.

It currently sets the following fields:

=over 4

=item * C<homepage>

The official home of this project on the web, taken from the GitHub repository
info. If the C<homepage> option is set to false this will be skipped (default is
true).

When offline, this is not set.

=item * C<repository>

=over 4

=item * C<web>

URL pointing to the GitHub page of the project.

=item * C<url>

URL pointing to the GitHub repository (C<git://...>).

=item * C<type>

This is set to C<git> by default.

=back

=item * C<bugtracker>

=over 4

=item * C<web>

URL pointing to the GitHub issues page of the project. If the C<bugs> option is
set to false (default is true) or the issues are disabled in the GitHub
repository, this will be skipped.

When offline, this is not set.

=back

=back

=cut

sub metadata {
	my $self 	= shift;
	my ($opts) 	= @_;
	my $repo_name	= $self -> repo ?
				$self -> repo :
				$self -> zilla -> name;
	my $offline	= 0;

	my ($login, undef, undef)  = $self -> _get_credentials(1);

	my $http	= HTTP::Tiny -> new;

	$self -> log("Getting GitHub repository info");

	my $url		= $self -> api."/repos/show/$login/$repo_name";
	my $response	= $http -> request('GET', $url);

	my $json_text = check_response($self, $response);
	$offline = 1 if not $json_text;

	$self -> log("Using offline repository information") if $offline;

	if (!$offline && $json_text -> {'repository'} -> {'fork'} == JSON::true() && $self -> fork == 1) {
		my $url		= $self -> api."/repos/show/".$json_text -> {'repository'} -> {'parent'};
		my $response	= $http -> request('GET', $url);

		$json_text = check_response($self, $response);
		return if not $json_text;
	}

	my ($git_web, $git_url, $homepage, $bugtracker, $wiki);

	$git_web  = $git_url = $offline ? "https://github.com/$login/$repo_name" : $json_text -> {'repository'} -> {'url'};
	$git_url  =~ s/https/git/;
	$git_url  .= '.git';
	$homepage = $offline ? undef : $json_text -> {'repository'} -> {'homepage'};

	if (!$offline && $json_text -> {'repository'} -> {'has_issues'} == JSON::true()) {
		$bugtracker = "$git_web/issues";
	}

	if (!$offline && $json_text -> {'repository'} -> {'has_wiki'} == JSON::true()) {
		$wiki = "$git_web/wiki";
	}

	my $meta -> {'resources'} = {
		'repository' => {
			'web'  => $git_web,
			'url'  => $git_url,
			'type' => 'git'
		}
	};

	if ($self -> wiki && $self -> wiki == 1 && $wiki) {
		$meta -> {'resources'} -> {'homepage'} = $wiki;
	} elsif ($self -> homepage && $self -> homepage == 1 && $homepage) {
		$meta -> {'resources'} -> {'homepage'} = $homepage;

	}

	if ($self -> bugs && $self -> bugs == 1 && $bugtracker) {
		$meta -> {'resources'} -> {'bugtracker'} = { 'web' => $bugtracker };
	}

	return $meta;

	sub check_response {
		my ($self, $response) = @_;

		if ($response && $response -> {'success'} eq '') {
			$self -> log("Err: Can't connect to GitHub.com");
			return;
		}

		my $json_text = decode_json $response -> {'content'};

		if ($json_text -> {'error'} && $json_text -> {'error'} ne "") {
			$self -> log("Err: ", $json_text -> {'error'});
			return;
		}

		return $json_text;
	 }
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

no Moose;

__PACKAGE__ -> meta -> make_immutable;

1; # End of Dist::Zilla::Plugin::GitHub::Meta
