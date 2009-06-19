package TAEB::Component::LevelClassifier::Sokoban;

use TAEB::OO;

sub examine {
    my ($self, $level) = @_;

    if (@{[ $level->tiles_of('stairsup') ]} >= 2
            && $level->z <= 10 && $level->z >= 6) {
        return ( sokofork => 1 );
    }
}

__PACKAGE__->meta->make_immutable;

1;
