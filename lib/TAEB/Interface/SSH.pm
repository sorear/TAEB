#!/usr/bin/env perl
package TAEB::Interface::SSH;
use TAEB::OO;

=head1 NAME

TAEB::Interface::SSH - how TAEB talks to /dev/null

=cut

extends 'TAEB::Interface::Local';

has server => (
    isa     => 'Str',
    default => 'nethack1.devnull.net',
);

has account => (
    isa => 'Str',
);

has password => (
    isa => 'Str',
);

sub _build_pty {
    my $self = shift;

    TAEB->debug("Connecting to " . $self->server . ".");

    my $pty = IO::Pty::Easy->new;
    $pty->spawn('ssh', $self->server, '-l', $self->account);

    alarm 20;
    eval {
        local $SIG{ALRM};

        my $output = '';
        while (1) {
            $output .= $pty->read(0) || '';
            if ($output =~ /password/) {
                alarm 0;
                last;
            }
        }
    };

    die "Died ($@) while waiting for password prompt.\n" if $@;

    $pty->write($self->password . "\n\n", 0);

    TAEB->debug("Connected to " . $self->server . ".");

    return $pty;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

