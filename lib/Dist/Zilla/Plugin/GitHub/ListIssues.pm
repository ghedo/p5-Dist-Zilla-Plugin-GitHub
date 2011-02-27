package Dist::Zilla::Plugin::GitHub::Update;

use Moose;
use HTTP::Tiny;

use warnings;
use strict;

with 'Dist::Zilla::Role::BeforeRelease';

has login => (
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

In your F<dist.ini>:

    [GitHub::ListIssues]
    login  = LoginName
    token  = GitHubToken

=head1 DESCRIPTION

This Dist::Zilla plugin lists all (or some) the open issues for the
module being built before the release.

=cut

sub before_release {
	my $self 	= shift;
	my ($opts) 	= @_;
	my $base_url	= 'https://github.com/api/v2/json';
	my $repo_name	= $self -> zilla -> name;
	my ($login, $token);

	if ($self -> login) {
		$login = $self -> login;
	} else {
		$login = `git config github.user`;
	}

	if ($self -> token) {
		$token = $self -> token;
	} else {
		$token = `git config github.token`;
	}

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

=item C<login>

The GitHub login name. If not provided, will be used the value of
C<github.user> from the Git configuration, to set it, type:

    $ git config --global github.user LoginName

=item C<token>

The GitHub API token for the user. If not provided, will be used the
value of C<github.token> from the Git configuration, to set it, type:

    $ git config --global github.token GitHubToken
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

1; # End of Dist::Zilla::Plugin::GitHub::Update
