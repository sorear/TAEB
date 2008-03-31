#!/usr/bin/env perl
package TAEB::Action::Descend;
use TAEB::OO;
extends 'TAEB::Action::Ascend';

use constant command => '>';
use constant complement_type => 'stairsup' => '<';

after done => sub {
    my $self    = shift;
    my $start   = $self->starting_tile;
    my $current = TAEB->current_tile;

    return unless $self->command eq '>';

    if (my $branch = $start->level->branch) {
        if ($branch eq 'mines' || $branch eq 'quest' || $branch eq 'gehennom') {
            $current->level->branch($branch);
        }
    }
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

