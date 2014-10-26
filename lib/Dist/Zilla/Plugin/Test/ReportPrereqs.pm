use 5.006;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::ReportPrereqs;
# ABSTRACT: Report on prerequisite versions during automated testing
our $VERSION = '0.002'; # VERSION

use Dist::Zilla 4 ();
use File::Slurp qw/read_file write_file/;
use File::Spec::Functions;

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::AfterBuild';

sub after_build {
  my ($self, $opt) = @_;
  my $build_root = $opt->{build_root};
  my $test_file = catfile($build_root, qw/t 00-report-prereqs.t/);
  my $guts = read_file($test_file);
  my $list = join("\n", map { "  $_" } $self->_module_list);
  $guts =~ s{INSERT_MODULE_LIST_HERE}{$list};
  write_file($test_file, $guts);
}

sub _module_list {
  my $self = shift;
  my $prereqs = $self->zilla->prereqs->as_string_hash;
  my %uniq = map {$_ => 1} map { keys %$_ } map { values %$_ } values %$prereqs;
  return sort keys %uniq; ## no critic
}

__PACKAGE__->meta->make_immutable;

1;




=pod

=head1 NAME

Dist::Zilla::Plugin::Test::ReportPrereqs - Report on prerequisite versions during automated testing

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # in dist.ini
  [Test::ReportPrereqs]

=head1 DESCRIPTION

This L<Dist::Zilla> plugin adds a t/00-report-prereqs.t test file.  If
AUTOMATED_TESTING is true, it reports the version of all modules listed in the
distribution metadata prerequisites (including 'recommends', 'suggests', etc.).

If a MYMETA.json file exists and L<CPAN::Meta> is installed on the testing
machine, MYMETA.json will be examined for prerequisites as it would include any
dynamic prerequisites.  Otherwise, a static list of prerequisites is used,
generated when distribution tarball was built.

Versions are reported based on the result of C<parse_version> from
L<ExtUtils::MakeMaker>, which means prerequisite modules are not actually
loaded (which avoids various edge cases with certain modules). Parse errors are
reported as "undef".  If a module is not installed, "missing" is reported
instead of a version string.

=for Pod::Coverage after_build

=head1 SEE ALSO

Other Dist::Zilla::Plugins do similar things in slightly different ways that didn't
suit my style and needs.

=over 4

=item *

L<Dist::Zilla::Plugin::Test::PrereqsFromMeta> -- requires prereqs to be satisfied

=item *

L<Dist::Zilla::Plugin::Test::ReportVersions> -- bundles a copy of YAML::Tiny, reads prereqs only from META.yml, and attempts to load them with C<require>

=item *

L<Dist::Zilla::Plugin::Test::ReportVersions::Tiny> -- static list only, loads modules with C<require>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-ReportPrereqs>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/dist-zilla-plugin-test-reportprereqs>

  git clone https://github.com/dagolden/dist-zilla-plugin-test-reportprereqs.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__DATA__
___[ t/00-report-prereqs.t ]___
#!perl

use strict;
use warnings;

use Test::More;

use ExtUtils::MakeMaker;
use File::Spec::Functions;
use List::Util qw/max/;

if ( $ENV{AUTOMATED_TESTING} ) {
  plan tests => 1;
}
else {
  plan skip_all => '$ENV{AUTOMATED_TESTING} not set';
}

my @modules = qw(
INSERT_MODULE_LIST_HERE
);

# replace modules with dynamic results from MYMETA.json if we can
if ( -f "MYMETA.json" && eval { require CPAN::Meta } ) {
  if ( my $meta = eval { CPAN::Meta->load_file("MYMETA.json") } ) {
    my $prereqs = $meta->prereqs;
    my %uniq = map {$_ => 1} map { keys %$_ } map { values %$_ } values %$prereqs;
    @modules = sort keys %uniq;
  }
}

my @reports = [qw/Version Module/];

for my $mod ( @modules ) {
  next if $mod eq 'perl';
  my $file = $mod;
  $file =~ s{::}{/}g;
  $file .= ".pm";
  my ($prefix) = grep { -e catfile($_, $file) } @INC;
  if ( $prefix ) {
    my $ver = MM->parse_version( catfile($prefix, $file) );
    $ver = "undef" unless defined $ver; # Newer MM should do this anyway
    push @reports, [$ver, $mod];
  }
  else {
    push @reports, ["missing", $mod];
  }
}
    
if ( @reports ) {
  my $vl = max map { length $_->[0] } @reports;
  my $ml = max map { length $_->[1] } @reports;
  splice @reports, 1, 0, ["-" x $vl, "-" x $ml];
  diag "Prerequisite Report:\n", map {sprintf("  %*s %*s\n",$vl,$_->[0],-$ml,$_->[1])} @reports;
}

pass;

# vim: ts=2 sts=2 sw=2 et:
