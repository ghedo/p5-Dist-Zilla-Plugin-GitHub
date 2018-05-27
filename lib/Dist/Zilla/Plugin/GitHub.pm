package Dist::Zilla::Plugin::GitHub;
# ABSTRACT: Plugins to integrate Dist::Zilla with GitHub
use strict;
use warnings;

our $VERSION = '0.45';

use JSON::MaybeXS;
use Moose;
use Try::Tiny;
use HTTP::Tiny;
use Git::Wrapper;
use Class::Load qw(try_load_class);

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

has _credentials => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    builder => '_build_credentials',
);

=head1 DESCRIPTION

B<Dist::Zilla::Plugin::GitHub> is a set of plugins for L<Dist::Zilla> intended
to more easily integrate L<GitHub|https://github.com> in the C<dzil> workflow.

The following is the list of the plugins shipped in this distribution:

=over 4

=item * L<Dist::Zilla::Plugin::GitHub::Create> Create GitHub repo on dzil new

=item * L<Dist::Zilla::Plugin::GitHub::Update> Update GitHub repo info on release

=item * L<Dist::Zilla::Plugin::GitHub::Meta> Add GitHub repo info to META.{yml,json}

=back

This distribution also provides an additional C<dzil> command (L<dzil
gh|Dist::Zilla::App::Command::gh>) and a L<plugin
bundle|Dist::Zilla::PluginBundle::GitHub>.

=cut

sub _build_credentials {
    my $self = shift;

    my ($login, $pass, $token, $otp);

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
        return [];
    }

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

    if ($self->prompt_2fa) {
        $otp = $self->zilla->chrome->prompt_str(
            "GitHub two-factor authentication code for '$login'",
            { noecho => 1 },
        );
    }

    return {login => $login, pass => $pass, otp => $otp};
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

    if ($self->prompt_2fa) {
        $headers{'X-GitHub-OTP'} = $credentials->{otp};
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
        ($login, undef, undef) = $self->_get_credentials(1);
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

            $self->log("Err: ", $json_text->{message});
            return;
        }

        return $json_text;
    } catch {
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

1; # End of Dist::Zilla::Plugin::GitHub
