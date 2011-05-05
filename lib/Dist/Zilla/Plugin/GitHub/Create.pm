package Dist::Zilla::Plugin::GitHub::Create;

use Moose;
use HTTP::Tiny;
use File::Basename;

use warnings;
use strict;

with 'Dist::Zilla::Role::AfterMint';

has 'public' => (
	is   	=> 'ro',
	isa  	=> 'Bool',
	default	=> 1
);

=head1 NAME

Dist::Zilla::Plugin::GitHub::Create - Create GitHub repo on dzil new

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName
    $ git config --global github.token GitHubToken

then, in your F<profile.ini>:

    [GitHub::Create]
    public = 1

=head1 DESCRIPTION

This Dist::Zilla plugin creates a new git repository on GitHub.com when
a new distribution is created with C<dzil new>.

=cut

sub after_mint {
	my $self 	= shift;
	my ($opts) 	= @_;
	my $repo_name 	= basename($opts -> {mint_root});

	my $login = `git config github.user`;  chomp $login;
	my $token = `git config github.token`; chomp $token;

	$self -> log("Creating new GitHub repository '$repo_name'");

	if (!$login || !$token) {
		$self -> log("Err: Provide valid GitHub login values");
		return;
	}

	my $http = HTTP::Tiny -> new();

	push my @params, "login=$login", "token=$token",
			'values[description]'.$self -> zilla -> abstract;

	push @params, "login=$login", "token=$token", "name=$repo_name",
			'public='.$self -> public;

	my $url 	= $self -> api.'/repos/create';
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

=item C<public>

Create a public repository if this is '1' (default), else create a private one.

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

1; # End of Dist::Zilla::Plugin::GitHub::Create
