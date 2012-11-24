package Dist::Zilla::Plugin::GitHub;

use strict;
use warnings;

use JSON;
use Moose;
use Try::Tiny;
use HTTP::Tiny;
use Class::Load qw(try_load_class);

has 'repo' => (
	is      => 'ro',
	isa     => 'Maybe[Str]'
);

has 'api'  => (
	is      => 'ro',
	isa     => 'Str',
	default => 'https://api.github.com'
);

=head1 NAME

Dist::Zilla::Plugin::GitHub - Plugins to integrate Dist::Zilla with GitHub

=head1 DESCRIPTION

B<Dist::Zilla::Plugin::GitHub> ships a bunch of L<Dist::Zilla> plugins, aimed at
easing the maintainance of Dist::Zilla-managed modules with L<GitHub|https://github.com>.

The following is the list of the plugins shipped in this distribution:

=over 4

=item * L<Dist::Zilla::Plugin::GitHub::Create> Create GitHub repo on dzil new

=item * L<Dist::Zilla::Plugin::GitHub::Update> Update GitHub repo info on release

=item * L<Dist::Zilla::Plugin::GitHub::Meta> Add GitHub repo info to META.{yml,json}

=back
=cut

sub _get_credentials {
	my ($self, $nopass) = @_;

	my ($login, $pass, $token);

	my %identity = Config::Identity::GitHub -> load
		if try_load_class('Config::Identity::GitHub');

	if (%identity) {
		$login = $identity{'login'};
	} else {
		$login = `git config github.user`;  chomp $login;
	}

	if (!$login) {
		my $error = %identity ?
			"Err: missing value 'user' in ~/.github" :
			"Err: Missing value 'github.user' in git config";

		$self -> log($error);
		return;
	}

	if (!$nopass) {
		if (%identity) {
			$token = $identity{'token'};
			$pass  = $identity{'password'};
		} else {
			$token = `git config github.token`;    chomp $token;
			$pass  = `git config github.password`; chomp $pass;
		}

		if ($token) {
			$self -> log("Err: Login with GitHub token is deprecated");
			return (undef, undef);
		} elsif (!$pass) {
			require Term::ReadKey;

			Term::ReadKey::ReadMode('noecho');
			$pass = $self -> zilla -> chrome
					-> term_ui -> get_reply(
				prompt => "GitHub password for '$login'",
				allow  => sub {
					defined $_[0] and length $_[0]
				});
			Term::ReadKey::ReadMode('normal');
			print "\n";
		}
	}

	return ($login, $pass);
}

sub _get_repo_name {
	my ($self, $login) = @_;

	my $repo = $self -> repo ? $self -> repo : $self -> zilla -> name;

	return ($repo =~ /.*\/.*/ ? $repo : "$login/$repo");
}

sub _check_response {
	my ($self, $response) = @_;

	try {
		my $json_text = from_json $response -> {'content'};

		if (!$response -> {'success'}) {
			$self -> log("Err: ", $json_text -> {'message'});
			return;
		}

		return $json_text;
	} catch {
		$self -> log("Err: Can't connect to GitHub");

		return;
	}
}

=head1 ACKNOWLEDGMENTS

Both the GitHub::Create and the GitHub::Update modules used to be standalone
modules (named respectively L<Dist::Zilla::Plugin::GithubCreate> and
L<Dist::Zilla::Plugin::GithubUpdate>) that are now deprecated.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Dist::Zilla::Plugin::GitHub
