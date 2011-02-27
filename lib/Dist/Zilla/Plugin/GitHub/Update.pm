package Dist::Zilla::Plugin::GitHub::Update;

use Moose;
use HTTP::Tiny;

use warnings;
use strict;

with 'Dist::Zilla::Role::Releaser';

has login => (
	is      => 'ro',
	isa     => 'Maybe[Str]',
);

has token => (
	is   	=> 'ro',
	isa  	=> 'Maybe[Str]',
);

has cpan => (
	is   	=> 'ro',
	isa  	=> 'Bool',
	default => 1
);

has p3rl => (
	is   	=> 'ro',
	isa  	=> 'Bool',
	default => 0
);

=head1 NAME

Dist::Zilla::Plugin::GitHub::Update - Update GitHub repo info on release

=head1 SYNOPSIS

In your F<dist.ini>:

    [GitHub::Update]
    login  = LoginName
    token  = GitHubToken
    cpan = 1

=head1 DESCRIPTION

This Dist::Zilla plugin updates the information of the GitHub repository
when C<dzil release> is run.

=cut

sub release {
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

	$self -> log("Updating GitHub repository info");

	if (!$login || !$token) {
		$self -> log("Err: Provide valid GitHub login values");
		return;
	}

	my $http = HTTP::Tiny -> new();

	my @params;

	push @params, "login=$login", "token=$token",
			'values[description]'.$self -> zilla -> abstract;

	if ($self -> p3rl == 1) {
		my $guess_name = $repo_name;
		$guess_name =~ s/\-/\:\:/g;
		push @params, "values[homepage]=http://p3rl.org/$guess_name"
	} elsif ($self -> cpan == 1) {
		push @params, "values[homepage]=http://search.cpan.org/dist/$repo_name/"
	}

	my $url 	= "$base_url/repos/show/$login/$repo_name";
	my $response	= $http -> request('POST', $url, {
		content => join("&", @params),
		headers => {'content-type' => 'application/x-www-form-urlencoded'}
	});

	if ($response -> {'status'} == 401) {
		$self -> log("Err: Not authorized");
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

1; # End of Dist::Zilla::Plugin::GitHub::Update
