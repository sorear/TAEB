#!/usr/bin/env perl
package TAEB::AI::Personality::NHackBot;
use TAEB::OO;
extends 'TAEB::AI::Personality';

has path => (
    isa => 'TAEB::World::Path',
    trigger => sub {
        my ($self, $path) = @_;
        TAEB->info("Current path: @{[$path->path]}.") if $path;
    },
);

=head1 NAME

TAEB::AI::Personality::NHackBot - Know thy roots

=cut

sub next_action {
    my $self = shift;

    if (TAEB->vt->row_plaintext(23) =~ /Fain/) {
        $self->currently("Praying for satiation.");
        return "#pray\n";
    }

    if (TAEB->hp * 2 < TAEB->maxhp && !TAEB->senses->in_wereform) {
        $self->currently("Writing Elbereth.");
        return "E-  Elbereth\n";
    }

    my $fight;

    TAEB->each_adjacent(sub {
        my ($tile, $dir) = @_;
        $fight = $dir
            if $tile->has_monster;
    });

    $self->currently("Attacking a monster."),
        return $fight
            if $fight;

    # kick down doors
    if (TAEB->senses->can_kick) {
        TAEB->each_adjacent(sub {
            my ($tile, $dir) = @_;
            if ($tile->glyph eq ']') {
                $fight = chr(4) . $dir;
            }
        });

        $self->currently("Kicking down a door."),
            return $fight
                if $fight;
    }

    # track down monsters
    # XXX: this ignores @ due to annoyance
    if (TAEB->map_like(qr/[a-zA-Z~&';:]/)) {
        my $path = TAEB::World::Path->first_match(
            sub { shift->has_monster },
        );

        if ($path) {
            $self->currently("Heading towards a @{[$path->to->glyph]} monster.");
            $self->path($path);
            return substr($path->path, 0, 1);
        }
    }

    # track down doors
    if (TAEB->senses->can_kick && TAEB->map_like(qr/\]/)) {
        my $path = TAEB::World::Path->first_match(
            sub { shift->glyph eq ']' },
        );

        if ($path) {
            $self->currently("Heading towards a door.");
            $self->path($path);
            return substr($path->path, 0, 1);
        }
    }

    # track down gold
    if (TAEB->messages =~ /You see here (\d+|a) gold pieces?\./) {
        $self->currently("Picking up $1 gold.");
        return ',';
    }

    if (TAEB->map_like(qr/\$/)) {
        my $path = TAEB::World::Path->first_match(
            sub { shift->glyph eq '$' },
        );

        if ($path) {
            $self->currently("Heading towards gold.");
            $self->path($path);
            return substr($path->path, 0, 1);
        }
    }

    # explore
    my $path = TAEB::World::Path->first_match(
        sub {
            my $tile = shift;
            !$tile->explored && $tile->is_walkable
        },
    );

    if ($path) {
        $self->currently("Exploring.");
        $self->path($path);
        return substr($path->path, 0, 1);
    }

    # if we're on a >, go down
    if (TAEB->current_tile->floor_glyph eq '>') {
        $self->currently("Descending.");
        return '>';
    }

    # if there's a >, go to it
    if (TAEB->map_like(qr/>/)) {
        $path = TAEB::World::Path->first_match(
            sub { shift->floor_glyph eq '>' },
        );

        if ($path) {
            $self->currently("Heading towards stairs.");
            $self->path($path);
            return substr($path->path, 0, 1);
        }
    }

    # search
    $path = TAEB::World::Path->max_match(
        sub {
            my ($tile, $path) = @_;

            # search walls and solid rock
            return undef unless $tile->type eq 'wall' || $tile->type eq 'rock';
            return 1 / (($tile->searched + length $path) || 1);
        },
    );

    if (length($path->path) > 1) {
        $self->currently("Heading towards a search hotspot.");
        $self->path($path);
        return substr($path->path, 0, 1);
    }

    $self->currently("Searching the adjacent walls.");
    TAEB->each_adjacent(sub {
        my $tile = shift;
        $tile->searched($tile->searched + 10);
    });

    return '10s';
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

