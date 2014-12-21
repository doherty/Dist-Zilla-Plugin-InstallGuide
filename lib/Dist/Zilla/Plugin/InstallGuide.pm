use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::InstallGuide;

# ABSTRACT: Build an INSTALL file
# VERSION
use Moose;
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::TextTemplate';
with 'Dist::Zilla::Role::FileMunger';
use List::Util 'first';

=head1 SYNOPSIS

In C<dist.ini>:

    [InstallGuide]

=for test_synopsis
1;
__END__

=head1 DESCRIPTION

This plugin adds a very simple F<INSTALL> file to the distribution, telling
the user how to install this distribution.

You should use this plugin in your L<Dist::Zilla> configuration after
C<[MakeMaker]> or C<[ModuleBuild]> so that it can determine what kind of
distribution you are building and which installation instructions are
appropriate.

=head1 METHODS

=cut

has template => (is => 'ro', isa => 'Str', default => <<'END_TEXT');
This is the Perl distribution {{ $dist->name }}.

Installing {{ $dist->name }} is straightforward.

## Installation with cpanm

If you have cpanm, you only need one line:

    % cpanm {{ $package }}

If you are installing into a system-wide directory, you may need to pass the
"-S" flag to cpanm, which uses sudo to install the module:

    % cpanm -S {{ $package }}

## Installing with the CPAN shell

Alternatively, if your CPAN shell is set up, you should just be able to do:

    % cpan {{ $package }}

## Manual installation

{{ $manual_installation }}
## Documentation

{{ $dist->name }} documentation is available as POD.
You can run perldoc from a shell to read the documentation:

    % perldoc {{ $package }}
END_TEXT

has makemaker_manual_installation => (is => 'ro', isa => 'Str', default => <<'END_TEXT');
As a last resort, you can manually install it. Download the tarball, untar it,
then build it:

    % perl Makefile.PL
    % make && make test

Then install it:

    % make install

If you are installing into a system-wide directory, you may need to run:

    % sudo make install
END_TEXT

has module_build_manual_installation => (is => 'ro', isa => 'Str', default => <<'END_TEXT');
As a last resort, you can manually install it. Download the tarball, untar it,
then build it:

    % perl Build.PL
    % ./Build && ./Build test

Then install it:

    % ./Build install

If you are installing into a system-wide directory, you may need to run:

    % sudo ./Build install
END_TEXT

=head2 gather_files

Creates the F<INSTALL> file.

=cut

sub gather_files {
    my $self = shift;

    require Dist::Zilla::File::InMemory;
    $self->add_file(Dist::Zilla::File::InMemory->new({
        name => 'INSTALL',
        content => $self->template,
    }));

    return;
}

=head2 munge_files

Inserts the appropriate installation instructions into F<INSTALL>.

=cut

sub munge_files {
    my $self = shift;

    my $zilla = $self->zilla;

    my $manual_installation = '';

    my %installer = (
        map {
            $_->isa('Dist::Zilla::Plugin::MakeMaker') ? ( 'Makefile.PL' => 1 ) : (),
            $_->does('Dist::Zilla::Role::BuildPL') ? ( 'Build.PL' => 1 ) : (),
        } @{ $zilla->plugins }
    );

    if ($installer{'Build.PL'}) {
        $manual_installation .= $self->module_build_manual_installation;
    }
    elsif ($installer{'Makefile.PL'}) {
        $manual_installation .= $self->makemaker_manual_installation;
    }
    unless ($manual_installation) {
        $self->log_fatal('neither Makefile.PL nor Build.PL is present, aborting');
    }

    (my $main_package = $zilla->name) =~ s!-!::!g;

    my $file = first { $_->name eq 'INSTALL' } @{ $zilla->files };

    my $content = $self->fill_in_string(
        $file->content,
        {   dist                => \$zilla,
            package             => $main_package,
            manual_installation => $manual_installation
        }
    );

    $file->content($content);
    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
