# This is the new (Jun09) level classifier.
#
# First step: scan levels for intrinsic properties.  We assign for each
# (level,tag) pair a rating:
#    definitely not: NO
#    probably not:   not without deliberate bonesing
#    likely not:     not likely, beware bones (but not neccessarily so)
#    ''              neutral
#    likely..definitely: analogout
#
# This is only done when the levels change.
#
# Second step is to run an iterative constraint solver over the dataset.
# Our termination condition is that any given rating can only become
# more definite, or flip to negative at the same definity; this defines
# a well-ordering over our state space, and by Kleene's theorem a fixed
# point will be reached.

package TAEB::Component::LevelClassifier;

use TAEB::OO;

# The tags, as they are computed on a level-by-level basis.

has _intrinsic_tags => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[String]]',
    default => sub { {} },
);

# The tags, cooked by constraint.

has _dungeon_tags => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[String]]',
    default => sub { {} },
);

# Set to 1 whenever the iteration changes something.

has _reiterate_solver => (
    isa  => 'Bool',
    is   => 'rw',
);

__PACKAGE__->meta->make_immutable;

1;
