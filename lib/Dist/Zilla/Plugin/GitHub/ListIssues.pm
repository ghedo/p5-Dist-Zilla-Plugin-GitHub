package Dist::Zilla::Plugin::GitHub::Update;

use Moose;
use HTTP::Tiny;

use warnings;
use strict;

with 'Dist::Zilla::Role::BeforeRelease';

has repo => (
	is      => 'ro',
	isa     => 'Maybe[Str]',
);

has token => (
	is   	=> 'ro',
	isa  	=> 'Maybe[Str]',
);

has count => (
	is   	=> 'ro',
	isa  	=> 'Int',
	default => -1
);

=head1 NAME

Dist::Zilla::Plugin::GitHub::Update - List module's GitHub issues before the release

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName
    $ git config --global github.token GitHubToken

then, in your F<dist.ini>:

    [GitHub::ListIssues]
    repo  = SomeRepo
    count = 5

=head1 DESCRIPTION

This Dist::Zilla plugin lists all (or some) the open issues for the
module being built before the release.

=cut

sub before_release {
	my $self 	= shift;
	my ($opts) 	= @_;
	my $base_url	= 'https://github.com/api/v2/json';
	my $repo_name	= $self -> repo || $self -> zilla -> name;

	my $login = `git config github.user`;

	my $token = `git config github.token`;

	chomp $login; chomp $token;

	$self -> log("Fetching GitHub issues");

	if (!$login || !$token) {
		$self -> log("Err: Provide valid GitHub login values");
		return;
	}

	my $http = HTTP::Tiny -> new();

	my $url 	= "$base_url/issues/list/$login/$repo_name/open";
	my $response	= $http -> request('GET', $url);

	if ($response -> {'status'} == 401) {
		$self -> log("Err: Not authorized");
	}

	my $json_text = decode_json $response -> {'content'};

	my $count = 1;
	foreach my $issue (@{ $json_text -> {'issues'} }) {
		$self -> log($issue -> {'title'}.' ('.$issue -> {'votes'}.'votes)');

		last if ($self -> {'count'} >= 0) && ($count == $self -> {'count'});
	}
}

=head1 ATTRIBUTES

=over

=item C<repo>

The name of the GitHub repository. By default the dist name (from dist.ini)
is used.

=item C<count>

The number of issues to list.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dist::Zilla::Plugin::GitHub::Update
