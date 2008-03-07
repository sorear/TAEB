#!/usr/bin/env perl
package TAEB::AI::Behavior::GotoTile;
use Moose;
extends 'TAEB::AI::Behavior';

=head1 NAME

TAEB::AI::Behavior::GotoTile - generic go-to-a-tile-and-do-something behavior

=cut

sub prepare {
    my $self = shift;

    # are we on >? if so, head down
    my ($next, $currently) = $self->match_tile(TAEB->current_tile);
    if (defined($next) && length($next)) {
        $self->currently($currently);
        $self->next($next);
        return 100;
    }

    # find our >
    my $path = TAEB::World::Path->first_match(
        sub { ($self->match_tile(@_))[0] },
    );

    $self->if_path($path => $self->currently_heading);
}

sub urgencies {
    my $self = shift;

    return {
        100 => $self->using_urgency,
         50 => $self->heading_urgency,
    };
}

# you may override these methods to provide more Englishy descriptions
sub using_urgency     { "using " . shift->tile_description }
sub heading_urgency   { "heading towards " . shift->tile_description }
sub currently_heading { "Heading towards " . shift->tile_description }

=head2 match_tile Tile -> (Str, Str)

This will try to match the given tile. If successful, it returns the next
action and the "currently" string. Otherwise, return C<undef>.

=cut

sub match_tile {
    my $class = blessed($_[0]) || $_[0];
    confess "$class must override match_tile.";
}

=head2 tile_description

This returns a short string describing the tile that we're heading towards. For
example, the Descend behavior uses "the downstairs".

=cut

sub tile_description {
    my $class = blessed($_[0]) || $_[0];
    confess "$class must override tile_description.";
}

make_immutable;

1;

