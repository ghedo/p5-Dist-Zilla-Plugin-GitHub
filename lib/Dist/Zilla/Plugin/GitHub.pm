=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GitHub

=head1 VERSION

version 0.41

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

=head1 NAME

Dist::Zilla::Plugin::GitHub - Plugins to integrate Dist::Zilla with GitHub

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Alessandro Ghedini Karen Etheridge Mike Friedman Jeffrey Ryan Thalhammer Dave Rolsky Doherty Rafael Kitover Brian Phillips Ricardo Signes Alexandr Ciornii Vyacheslav Matyukhin Ioan Rogers Chris Weyl

=over 4

=item *

Alessandro Ghedini <alessandro@ghedini.me>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Mike Friedman <mike.friedman@10gen.com>

=item *

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Mike Doherty <doherty@cs.dal.ca>

=item *

Rafael Kitover <rkitover@cpan.org>

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=item *

Ioan Rogers <ioan.rogers@gmail.com>

=item *

Chris Weyl <cweyl@alumni.drew.edu>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alessandro Ghedini.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
