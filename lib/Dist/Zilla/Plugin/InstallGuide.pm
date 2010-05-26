use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::InstallGuide;

# ABSTRACT: Build an INSTALL file
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::TextTemplate';

my $template = q|
This is the Perl distribution {{ $dist->name }}.

## Installation

{{ $dist->name }} installation is straightforward.

### Installation with cpanm

If you have cpanm, you only need one line:

    % cpanm {{ $package }}

### Installating with the CPAN shell

Alternatively, if your CPAN shell is set up, you should just be able to do:

    % cpan {{ $package }}

### Manual installation
{{ $manual_installation }}
## Documentation

{{ $dist->name }} documentation is available as in POD.
So you can do:

    % perldoc {{ $package }}

to read the documentation with your favorite pager.
|;

my $makemaker_manual_installation = q|
As a last resort, you can manually install it. Download it, unpack it, then
build it as per the usual:

    % perl Makefile.PL
    % make && make test

Then install it:

    % make install
|;

my $module_build_manual_installation = q|
As a last resort, you can manually install it. Download it, unpack it, then
build it:

    % perl Build.PL
    % ./Build && ./Build test

Then install it:

    % ./Build install
|;

sub setup_installer {
    my $self = shift;
    my $manual_installation;
    for (@{ $self->zilla->files }) {
        if ($_->name eq 'Makefile.PL') {
            $manual_installation = $makemaker_manual_installation;
            last;
        } elsif ($_->name eq 'Build.PL') {
            $manual_installation = $module_build_manual_installation;
            last;
        }
    }
    unless (defined $manual_installation) {
        $self->log_fatal('neither Makefile.PL nor Build.PL is present, aborting');
    }
    require Dist::Zilla::File::InMemory;
    (my $main_package = $self->zilla->name) =~ s!-!::!g;
    my $content = $self->fill_in_string(
        $template,
        {   dist                => \($self->zilla),
            package             => $main_package,
            manual_installation => $manual_installation
        }
    );
    my $file = Dist::Zilla::File::InMemory->new(
        {   content => $content,
            name    => 'INSTALL',
        }
    );
    $self->add_file($file);
    return;
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;

=pod

=for test_synopsis
1;
__END__

=head1 SYNOPSIS

In C<dist.ini>:

    [InstallGuide]

=head1 DESCRIPTION

This plugin adds a very simple F<INSTALL> file to the distribution, telling
the user how to install this distribution.

=function gather_files

Builds and writes the C<INSTALL> file.

