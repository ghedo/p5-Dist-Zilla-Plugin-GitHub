package Dist::Zilla::Plugin::GitHub::Update;

use Moose;

use strict;
use warnings;

extends 'Dist::Zilla::Plugin::GitHub';

with 'Dist::Zilla::Role::Releaser';

has 'cpan' => (
	is   	=> 'ro',
	isa  	=> 'Bool',
	default => 1
);

has 'p3rl' => (
	is   	=> 'ro',
	isa  	=> 'Bool',
	default => 0
);

has 'metacpan' => (
	is   	=> 'ro',
	isa  	=> 'Bool',
	default => 0
);

=head1 NAME

Dist::Zilla::Plugin::GitHub::Update - Update GitHub repo info on release

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName
    $ git config --global github.password GitHubPassword

Alternatively, the GitHub login token can be used instead of the password
(note that token-based login has been deprecated by GitHub):

    $ git config --global github.token GitHubToken

then, in your F<dist.ini>:

    [GitHub::Update]
    repo = SomeRepo
    cpan = 1

=head1 DESCRIPTION

This Dist::Zilla plugin updates the information of the GitHub repository
when C<dzil release> is run.

=cut

sub release {
	my $self 	= shift;
	my ($opts) 	= @_;
	my $repo_name	= $self -> repo ?
				$self -> repo :
				$self -> zilla -> name;

	my ($login, $pass, $token)  = $self -> _get_credentials(0);

	my $http = HTTP::Tiny -> new;

	$self -> log("Updating GitHub repository info");

	my @params;

	push @params, "login=$login", "token=$token" if $token;
	push @params, 'values[description]='.$self -> zilla -> abstract;

	if ($self -> metacpan == 1) {
		$self -> log("Using MetaCPAN URL");
		push @params, "values[homepage]=http://metacpan.org/release/$repo_name/"
	} elsif ($self -> p3rl == 1) {
		my $guess_name = $repo_name;
		$guess_name =~ s/\-/\:\:/g;

		$self -> log("Using P3rl URL");
		push @params, "values[homepage]=http://p3rl.org/$guess_name"
	} elsif ($self -> cpan == 1) {
		$self -> log("Using CPAN URL");
		push @params, "values[homepage]=http://search.cpan.org/dist/$repo_name/"
	}

	my $url 	= $self -> api."repos/show/$login/$repo_name";

	my $headers	= {
		'content-type' => 'application/x-www-form-urlencoded'
	};

	if ($pass) {
		require MIME::Base64;

		my $basic = MIME::Base64::encode_base64("$login:$pass", '');
		$headers -> {'authorization'} = "Basic $basic";
	}

	my $response	= $http -> request('POST', $url, {
		content => join("&", @params),
		headers => $headers 
	});

	if ($response -> {'status'} == 401) {
		$self -> log("Err: Not authorized");
		return;
	}
}

=head1 ATTRIBUTES

=over

=item C<repo>

The name of the GitHub repository. By default the dist name (from dist.ini)
is used.

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

1; # End of Dist::Zilla::Plugin::GitHub::Update
