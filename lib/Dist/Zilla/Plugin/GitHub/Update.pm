package Dist::Zilla::Plugin::GitHub::Update;

use strict;
use warnings;

use JSON::MaybeXS;
use Moose;

extends 'Dist::Zilla::Plugin::GitHub';

with 'Dist::Zilla::Role::AfterRelease';

has 'cpan' => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1
);

has 'p3rl' => (
	is      => 'ro',
	isa     => 'Bool',
	default => 0
);

has 'metacpan' => (
	is      => 'ro',
	isa     => 'Bool',
	default => 0
);

has 'meta_home' => (
	is      => 'ro',
	isa     => 'Bool',
	default => 0
);

=head1 NAME

Dist::Zilla::Plugin::GitHub::Update - Update a GitHub repo's info on release

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName
    $ git config --global github.password GitHubPassword

Alternatively you can install L<Config::Identity> and write your credentials
in the (optionally GPG-encrypted) C<~/.github> file as follows:

    login LoginName
    password GitHubpassword

(if only the login name is set, the password will be asked interactively)

then, in your F<dist.ini>:

    # default config
    [GitHub::Meta]

    # to override the repo name
    [GitHub::Meta]
    repo = SomeRepo

See L</ATTRIBUTES> for more options.

=head1 DESCRIPTION

This Dist::Zilla plugin updates the information of the GitHub repository
when C<dzil release> is run.

=cut

sub after_release {
	my $self      = shift;
	my ($opts)    = @_;
	my $dist_name = $self -> zilla -> name;

	my ($login, $pass, $otp)  = $self -> _get_credentials(0);
	return if (!$login);

	my $repo_name = $self -> _get_repo_name($login);

	my $http = HTTP::Tiny -> new;

	$self -> log("Updating GitHub repository info");

	my ($params, $headers, $content);

	$repo_name =~ /\/(.*)$/;
	my $repo_name_only = $1;

	$params -> {'name'} = $repo_name_only;
	$params -> {'description'} = $self -> zilla -> abstract;

	my $meta_home = $self -> zilla -> distmeta
		-> {'resources'} -> {'homepage'};

	if ($meta_home && $self -> meta_home) {
		$self -> log("Using distmeta URL");
		$params -> {'homepage'} = $meta_home;
	} elsif ($self -> metacpan == 1) {
		$self -> log("Using MetaCPAN URL");
		$params -> {'homepage'} =
			"http://metacpan.org/release/$dist_name/"
	} elsif ($self -> p3rl == 1) {
		my $guess_name = $dist_name;
		$guess_name =~ s/\-/\:\:/g;

		$self -> log("Using P3rl URL");
		$params -> {'homepage'} = "http://p3rl.org/$guess_name"
	} elsif ($self -> cpan == 1) {
		$self -> log("Using CPAN URL");
		$params -> {'homepage'} =
			"http://search.cpan.org/dist/$dist_name/"
	}

	my $url = $self -> api."/repos/$repo_name";

        my $current = $self->_current_params($url);
        if ($current &&
            $current->{name} eq $params->{name} &&
            $current->{description} eq $params->{description} &&
            $current->{homepage} eq $params->{homepage}) {

            $self->log("GitHub repo info is up to date");
            return;
        }

	if ($pass) {
		require MIME::Base64;

		my $basic = MIME::Base64::encode_base64("$login:$pass", '');
		$headers -> {'Authorization'} = "Basic $basic";
	}

	if ($self -> prompt_2fa) {
		$headers -> { 'X-GitHub-OTP' } = $otp;
		$self -> log([ "Using two-factor authentication" ]);
	}

	$content = encode_json($params);

	my $response = $http -> request('PATCH', $url, {
		content => $content,
		headers => $headers
	});

	my $repo = $self -> _check_response($response);

	return if not $repo;

	if ($repo eq 'redo') {
		$self -> log("Retrying with two-factor authentication");
		$self -> prompt_2fa(1);
		$repo = $self -> after_release($opts);
		return if not $repo;
	}
}

sub _current_params {
    my $self  = shift;
    my ($url) = @_;

    my $http = HTTP::Tiny->new;

    my $response = $http->request('GET', $url);

    return $self->_check_response($response);
}

=head1 ATTRIBUTES

=over

=item C<repo>

The name of the GitHub repository. By default the name will be extracted from
the URL of the remote specified in the C<remote> option, and if that fails the
dist name (from dist.ini) is used. It can also be in the form C<user/repo>
when it belongs to another GitHub user/organization.

=item C<remote>

The name of the Git remote pointing to the GitHub repository (C<"origin"> by
default). This is used when trying to guess the repository name.

=item C<cpan>

The GitHub homepage field will be set to the CPAN page (search.cpan.org) of the
module if this option is set to true (default),

=item C<p3rl>

The GitHub homepage field will be set to the p3rl.org shortened URL
(e.g. C<http://p3rl.org/My::Module>) if this option is set to true (default is
false).

This takes precedence over the C<cpan> option (if both are true, p3rl will be
used).

=item C<metacpan>

The GitHub homepage field will be set to the metacpan.org distribution URL
(e.g. C<http://metacpan.org/release/My-Module>) if this option is set to true
(default is false).

This takes precedence over the C<cpan> and C<p3rl> options (if all three are
true, metacpan will be used).

=item C<meta_home>

The GitHub homepage field will be set to the value present in the dist meta
(e.g. the one set by other plugins) if this option is set to true (default is
false). If no value is present in the dist meta, this option is ignored.

This takes precedence over the C<metacpan>, C<cpan> and C<p3rl> options (if all
four are true, meta_home will be used).

=item C<prompt_2fa>

Prompt for GitHub two-factor authentication code if this option is set to true
(default is false). If this option is set to false but GitHub requires 2fa for
the login, it'll be automatically enabled.

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
