use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::InstallGuide;

# ABSTRACT: build an INSTALL file
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::TextTemplate';

sub gather_files {
    my ($self, $arg) = @_;
    require Dist::Zilla::File::InMemory;
    (my $main_package = $self->zilla->name) =~ s!-!::!g;
    my $template = q|
This is the Perl distribution {{ $dist->name }}.

## Installation

{{ $dist->name }} installation is straightforward.
If your CPAN shell is set up, you should just be able to do

    % cpan {{ $package }}

Download it, unpack it, then build it as per the usual:

    % perl Makefile.PL
    % make && make test

Then install it:

    % make install

## Documentation

{{ $dist->name }} documentation is available as in POD.
So you can do:

    % perldoc {{ $package }}

to read the documentation with your favorite pager.
|;
    my $content = $self->fill_in_string(
        $template,
        {   dist    => \($self->zilla),
            package => $main_package
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

