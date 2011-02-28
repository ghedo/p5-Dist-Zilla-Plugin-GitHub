package Dist::Zilla::Plugin::GitHub::Meta;

use Moose;
use JSON;
use HTTP::Tiny;

use warnings;
use strict;

with 'Dist::Zilla::Role::MetaProvider';

has repo => (
	is      => 'ro',
	isa     => 'Maybe[Str]',
);

has homepage => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1,
);

has bugs => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1,
);

has wiki => (
	is      => 'ro',
	isa     => 'Bool',
	default => 0,
);

=head1 NAME

Dist::Zilla::Plugin::GitHub::Meta - Add GitHub repo info to META.{yml,json}

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName
    $ git config --global github.token GitHubToken

then, in your F<dist.ini>:

    [GitHub::Meta]
    repo = SomeRepo

=head1 DESCRIPTION

This Dist::Zilla plugin adds some information about the distribution's
GitHub repository to the META.{yml,json} files.

=cut

sub metadata {
	my $self 	= shift;
	my ($opts) 	= @_;
	my $base_url	= 'https://github.com/api/v2/json';
	my $repo_name	= $self -> repo || $self -> zilla -> name;

	my $login = `git config github.user`;

	my $token = `git config github.token`;

	chomp $login; chomp $token;

	$self -> log("Getting GitHub repository info");

	if (!$login || !$token) {
		$self -> log("Err: Provide valid GitHub login values");
		return;
	}

	my $http = HTTP::Tiny -> new();

	my $url = "$base_url/repos/show/$login/$repo_name";

	my $response	= $http -> request('GET', $url);

	if ($response -> {'status'} == 401) {
		$self -> log("Err: Not authorized");
	}

	my $json_text = decode_json $response -> {'content'};

	my ($git_web, $git_url, $homepage, $bugtracker, $wiki);

	$git_web  = $git_url = $json_text -> {'repository'} -> {'url'};
	$git_url  =~ s/https/git/;
	$git_url  .= '.git';
	$homepage = $json_text -> {'repository'} -> {'homepage'};

	if ($json_text -> {'repository'} -> {'has_issues'} == JSON::true()) {
		$bugtracker = "$git_web/issues";
	}

	if ($json_text -> {'repository'} -> {'has_wiki'} == JSON::true()) {
		$wiki = "$git_web/wiki";
	}

	my $meta -> {'resources'} = {
			'repository' => {
				'web'  => $git_web,
				'url'  => $git_url,
				'type' => 'git'
			}
		};

	if ($self -> homepage == 1) {
		$meta -> {'resources'} -> {'homepage'} = $homepage;
	}

	if ($self -> bugs == 1) {
		$meta -> {'resources'} -> {'bugtracker'} = { 'web' => $bugtracker };
	}

	if ($self -> wiki == 1) {
		$meta -> {'resources'} -> {'x_wiki'} = $wiki;
	}

	return $meta;
}

=head1 ATTRIBUTES

=over

=item C<repo>

The name of the GitHub repository. By default the dist name (from dist.ini)
is used.

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

1; # End of Dist::Zilla::Plugin::GitHub::Meta
