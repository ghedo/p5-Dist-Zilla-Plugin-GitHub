package Dist::Zilla::Plugin::GitHub;
# ABSTRACT: Plugins to integrate Dist::Zilla with GitHub
use strict;
use warnings;

our $VERSION = '0.48';

use JSON::MaybeXS;
use Moose;
use Try::Tiny;
use HTTP::Tiny;
use Git::Wrapper;
use Class::Load qw(try_load_class);

has continue_if_repo_not_found => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has remote => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => 'origin'
);

has repo => (
    is      => 'ro',
    isa     => 'Maybe[Str]'
);

has api  => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.github.com'
);

has prompt_2fa => (
    is  => 'rw',
    isa => 'Bool',
    default => 0
);

has _login => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_login',
);

has _credentials => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    builder => '_build_credentials',
);

=head1 DESCRIPTION

B<Dist-Zilla-Plugin-GitHub> is a set of plugins for L<Dist::Zilla> intended
to more easily integrate L<GitHub|https://github.com> in the C<dzil> workflow.

The following is the list of the plugins shipped in this distribution:

=over 4

=item * L<Dist::Zilla::Plugin::GitHub::Create> Create GitHub repo on C<dzil new>

=item * L<Dist::Zilla::Plugin::GitHub::Update> Update GitHub repo info on release

=item * L<Dist::Zilla::Plugin::GitHub::Meta> Add GitHub repo info to F<META.{yml,json}>

=back

This distribution also provides a plugin bundle, L<Dist::Zilla::PluginBundle::GitHub>,
which provides L<GitHub::Meta|Dist::Zilla::Plugin::GitHub::Meta> and
L<[GitHub::Update|Dist::Zilla::Plugin::GitHub::Update> together in one convenient bundle.

This distribution also provides an additional C<dzil> command (L<dzil
gh|Dist::Zilla::App::Command::gh>) and a L<plugin
bundle|Dist::Zilla::PluginBundle::GitHub>.

=cut

sub _build_login {
    my $self = shift;

    my ($login);

    my %identity = Config::Identity::GitHub->load
        if try_load_class('Config::Identity::GitHub');

    if (%identity) {
        $login = $identity{login};
    } else {
        $login = `git config github.user`;  chomp $login;
    }

    if (!$login) {
        my $error = %identity ?
            "Err: missing value 'user' in ~/.github" :
            "Err: Missing value 'github.user' in git config";

        $self->log($error);
        return undef;
    }

    return $login;
}

sub _build_credentials {
    my $self = shift;

    my ($login, $pass, $token);

    $login = $self->_login;

    if (!$login) {
        return {};
    }

    my %identity = Config::Identity::GitHub->load
        if try_load_class('Config::Identity::GitHub');

    if (%identity) {
        $token = $identity{token};
        $pass  = $identity{password};
    } else {
        $token = `git config github.token`;    chomp $token;
        $pass  = `git config github.password`; chomp $pass;

        # modern "tokens" can be used as passwords with basic auth, so...
        # see https://help.github.com/articles/creating-an-access-token-for-command-line-use
        $pass ||= $token if $token;
    }

    $self->log("Err: Login with GitHub token is deprecated")
        if $token && !$pass;

    if (!$pass) {
        $pass = $self->zilla->chrome->prompt_str(
            "GitHub password for '$login'", { noecho => 1 },
        );
    }

    return {login => $login, pass => $pass};
}

sub _has_credentials {
    my $self = shift;
    return keys %{$self->_credentials};
}

sub _auth_headers {
    my $self = shift;

    my $credentials = $self->_credentials;

    my %headers;
    if ($credentials->{pass}) {
        require MIME::Base64;
        my $basic = MIME::Base64::encode_base64("$credentials->{login}:$credentials->{pass}", '');
        $headers{Authorization} = "Basic $basic";
    }

    # This can't be done at object creation because we autodetect the
    # need for 2FA when GitHub says we need it, so we won't know to
    # prompt at object creation time.
    if ($self->prompt_2fa) {
        my $otp = $self->zilla->chrome->prompt_str(
            "GitHub two-factor authentication code for '$credentials->{login}'",
            { noecho => 1 },
        );

        $headers{'X-GitHub-OTP'} = $otp;
        $self->log([ "Using two-factor authentication" ]);
    }

    return \%headers;
}

sub _get_repo_name {
    my ($self, $login) = @_;

    my $repo;
    my $git = Git::Wrapper->new('./');

    $repo = $self->repo if $self->repo;

    my $url;
    {
        local $ENV{LANG}='C';
        ($url) = map /Fetch URL: (.*)/,
            $git->remote('show', '-n', $self->remote);
    }

    $url =~ /github\.com.*?[:\/](.*)\.git$/;
    $repo = $1 unless $repo and not $1;

    $repo = $self->zilla->name unless $repo;

    if ($repo !~ /.*\/.*/) {
        $login = $self->_login;
        if (defined $login) {
            $repo = "$login/$repo";
        }
    }

    return $repo;
}

sub _check_response {
    my ($self, $response) = @_;

    try {
        my $json_text = decode_json($response->{content});

        if (!$response->{success}) {
            return 'redo' if (($response->{status} eq '401') and
                              ($response->{headers}{'x-github-otp'} =~ /^required/));

            if ($response->{status} eq '404' &&
                !$self->continue_if_repo_not_found) {
                die 'incorrect repository URL (HTTP 404 from ' . $response->{url} . ')';
            }
            $self->log("Err: ", $json_text->{message});
            return;
        }

        return $json_text;
    } catch {
        die $_ if $_ =~ 'incorrect repository URL';

        if ($response and !$response->{success} and
            $response->{status} eq '599') {
            #possibly HTTP::Tiny error
            $self->log("Err: ", $response->{content});
            return;
        }

        $self->log("Err: Can't connect to GitHub");

        return;
    }
}

__PACKAGE__->meta->make_immutable;
1; # End of Dist::Zilla::Plugin::GitHub
