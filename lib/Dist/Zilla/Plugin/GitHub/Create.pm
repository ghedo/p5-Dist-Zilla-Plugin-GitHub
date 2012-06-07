package Dist::Zilla::Plugin::GitHub::Create;

use strict;
use warnings;

use JSON;
use Moose;
use File::Basename;

extends 'Dist::Zilla::Plugin::GitHub';

with 'Dist::Zilla::Role::AfterMint';

has 'public' => (
	is	=> 'ro',
	isa	=> 'Bool',
	default	=> 1
);

has 'remote' => (
	is	=> 'ro',
	isa	=> 'Str',
	default	=> 'origin'
);

has 'prompt' => (
        is	=> 'ro',
        isa	=> 'Bool',
        default	=> 0
);

=head1 NAME

Dist::Zilla::Plugin::GitHub::Create - Create GitHub repo on dzil new

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName
    $ git config --global github.password GitHubPassword

Alternatively, you can write your credentials in the (optionally GPG-encrypted)
C<~/.github> file as follows:

    login LoginName
    password GitHubpassword

then, in your F<profile.ini>:

    [GitHub::Create]
    public = 1

=head1 DESCRIPTION

This Dist::Zilla plugin creates a new git repository on GitHub.com when
a new distribution is created with C<dzil new>.

It will also add a new git remote pointing to the newly created GitHub
repository's private URL. See L</"ADDING REMOTE"> for more info.

=cut

sub after_mint {
	my $self	= shift;
	my ($opts)	= @_;

	my $root = $opts -> {'mint_root'};

	return if $self -> prompt and not $self -> _confirm;

	my $repo_name	= basename($root);

	my ($login, $pass)  = $self -> _get_credentials(0);

	my $http = HTTP::Tiny -> new;

	$self -> log("Creating new GitHub repository '$repo_name'");

	my ($params, $headers, $content);

	$params -> {'name'}   = $repo_name;
	$params -> {'public'} = $self -> public;

	my $url = $self -> api.'/user/repos';

	if ($pass) {
		require MIME::Base64;

		my $basic = MIME::Base64::encode_base64("$login:$pass", '');
		$headers -> {'authorization'} = "Basic $basic";
	}

	$content = to_json $params;

	my $response	= $http -> request('POST', $url, {
		content => $content,
		headers => $headers
	});

	my $repo = $self -> _check_response($response);
	return if not $repo;

	my $git_dir = "$root/.git";
	my $rem_ref = $git_dir."/refs/remotes/".$self -> remote;

	if ((-d $git_dir) && (!-d $rem_ref)) {
		my $ssh_url = $repo -> {'ssh_url'};

		$self -> log("Setting GitHub remote '".$self -> remote."'");

		system(
			"git", "--git-dir=$git_dir", "remote", "add",
			$self -> remote, $ssh_url
		);
	}
}

sub _confirm {
	my ($self) = @_;

	my $dist = $self -> zilla -> name;
	my $prompt = "Shall I create a GitHub repository for $dist?";

	return $self -> zilla -> chrome -> prompt_yn($prompt, {default => 1} );
}

=head1 ATTRIBUTES

=over

=item C<prompt>

Prompt for confirmation before creating a GitHub repository if this option is
set to true (default is false).

=item C<public>

Create a public repository if this option is set to true (default), otherwise
create a private repository.

=item C<remote>

Specifies the git remote name to be added (default 'origin'). This will point to
the newly created GitHub repository's private URL. See L</"ADDING REMOTE"> for
more info.

=back

=head1 ADDING REMOTE

By default C<GitHub::Create> adds a new git remote pointing to the newly created
GitHub repository's private URL B<if, and only if,> a git repository has already
been initialized, and if the remote doesn't already exist in that repository.

To take full advantage of this feature you should use, along with C<GitHub::Create>,
the L<Dist::Zilla::Plugin::Git::Init> plugin, leaving blank its C<remote> option,
as follows:

    [Git::Init]
    ; here goes your Git::Init config, remember
    ; to not set the 'remote' option
    [GitHub::Create]

You may set your preferred remote name, by setting the C<remote> option of the
C<GitHub::Create> plugin, as follows:

    [Git::Init]
    [GitHub::Create]
    remote = myremote

Remember to put C<[Git::Init]> B<before> C<[GitHub::Create]>.

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
