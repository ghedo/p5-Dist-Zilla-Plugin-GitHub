package Dist::Zilla::Plugin::GitHub::Create;

use Moose;
use File::Basename;

use strict;
use warnings;

extends 'Dist::Zilla::Plugin::GitHub';

with 'Dist::Zilla::Role::AfterMint';

has 'public' => (
	is   	=> 'ro',
	isa  	=> 'Bool',
	default	=> 1
);

has 'remote' => (
	is   	=> 'ro',
	isa  	=> 'Str',
	default	=> 'origin'
);

has 'prompt' => (
        is      => 'ro',
        isa     => 'Bool',
        default => 0
);

=head1 NAME

Dist::Zilla::Plugin::GitHub::Create - Create GitHub repo on dzil new

=head1 SYNOPSIS

Configure git with your GitHub credentials:

    $ git config --global github.user LoginName
    $ git config --global github.password GitHubPassword

Alternatively, the GitHub login token can be used instead of the password
(note that token-based login has been deprecated by GitHub):

    $ git config --global github.token GitHubToken

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

        return if $self -> prompt and not $self -> _confirm;

	my $repo_name	= basename($opts -> {'mint_root'});

	my $login = `git config github.user`;  chomp $login;
	my $token = `git config github.token`; chomp $token;
	my $pass  = `git config github.password`;  chomp $pass;

	if (!$login) {
		$self -> log("Err: Provide valid GitHub login values");
		return;
	}

	if ($token) {
		$self -> log("Warn: Login with GitHub token is deprecated");
	} elsif (!$pass) {
		require Term::ReadKey;

		Term::ReadKey::ReadMode('noecho');
		$pass = $self -> zilla -> chrome -> term_ui -> get_reply(
			prompt => "GitHub password for '$login'",
			allow  => sub { defined $_[0] and length $_[0] },
		);
		Term::ReadKey::ReadMode('normal');
	}

	my $http = HTTP::Tiny -> new;

	$self -> log("Creating new GitHub repository '$repo_name'");

	my @params;

	push @params, "login=$login", "token=$token" if $token;
	push @params, "name=$repo_name", 'public='.$self -> public;

	my $url 	= $self -> api.'/repos/create';

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
	}

	my $git_dir = $opts -> {mint_root}."/.git";
	my $rem_ref = $git_dir."/refs/remotes/".$self -> remote;

	if ((-d $git_dir) && (!-d $rem_ref)) {
		my $remote_url = "git\@github.com:/$login/$repo_name.git";

		$self -> log("Setting GitHub remote '".$self -> remote."'");

		system(
			"git", "--git-dir=$git_dir", "remote", "add",
			$self -> remote, $remote_url
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
