package Dist::Zilla::Plugin::GitHub;

use Moose;
use HTTP::Tiny;

use strict;
use warnings;

has 'repo' => (
	is      => 'ro',
	isa     => 'Maybe[Str]'
);

has 'api'  => (
	is      => 'ro',
	isa     => 'Str',
	default => 'https://github.com/api/v2/json'
);

=head1 NAME

Dist::Zilla::Plugin::GitHub - Set of plugins for working with GitHub

=head1 DESCRIPTION

B<Dist::Zilla::Plugin::GitHub> ships a bunch of L<Dist::Zilla> plugins, aimed at
easing the maintainance of Dist::Zilla-managed modules with L<GitHub|https://github.com>.

The following is the list of the plugins shipped in this distribution:

=over 4

=item * L<Dist::Zilla::Plugin::GitHub::Create> Create GitHub repo on dzil new

=item * L<Dist::Zilla::Plugin::GitHub::Update> Update GitHub repo info on release

=item * L<Dist::Zilla::Plugin::GitHub::Meta> Add GitHub repo info to META.{yml,json}

=back

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
