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
# Levels are only ever added to these hashes.

has _intrinsic_tags => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[Int]]',
    default => sub { {} },
);

# The tags, cooked by constraint.

has _dungeon_tags => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[Int]]',
    default => sub { {} },
);

# Set to 1 whenever the iteration changes something.

has _reiterate_solver => (
    isa  => 'Bool',
    is   => 'rw',
);

use constant {
    DEFINITELY_NOT => -3,
    PROBABLY_NOT   => -2,
    LIKELY_NOT     => -1,
    NEUTRAL        => 0,
    LIKELY         => 1,
    PROBABLY       => 2,
    DEFINITELY     => 3,
};

################

sub _rate {
    my ($self, $level, $tag, $new) = @_;
    my $ref = \ (($self->_dungeon_tags->{$level} ||= {})->{$tag} ||= 0);

    return $$ref unless defined $new;

    if (abs($new) < $$ref || ($new > 0 && $$ref == -$new)) {
        die "Termination order for solver has been violated.  Attempting to rerate ($level,$tag) from $$ref to $new.";
    }

    if ($$ref != $new) {
        $self->_reiterate_solver(1);
    }

    $$ref = $new;
}

sub _solver {
    my ($self) = @_;

    my @levels = keys %{ $self->_intrinsic_tags };

    for my $level (@levels) {
        $self->_dungeon_tags{$level} = { %{ $self->_intrinsic_tags->{$level} } };
    }

    $self->_reiterate_solver(1);

    while($self->_reiterate_solver) {
        $self->_reiterate_solver(0);

        # A level cannot be Oracle and Minetown, or dungeons and mines
        for my $level (@levels) {
            $self->_constrain_disjunction($level, $self->branch_tags);
            $self->_constrain_disjunction($level, $self->level_type_tags);
        }

        # Two levels cannot be the Oracle
        for my $tag ($self->unique_tags) {
            $self->_constrain_disjunction(\@levels, $tag);
        }

        # Topographical connection rules go here?
    }
}

sub _get_candidate {
    my ($self, $level_set, $tag_set) = @_;

    my $candidate_rating = NEUTRAL;
    my ($candidate_level, $candidate_tag, @ties);

    for my $level (@$level_set) {
        for my $tag (@$tag_set) {

            my $rating = $self->_rate($level, $tag);
            next unless $rating > NEUTRAL;

            if ($rating == $candidate_rating) {
                push @ties, "$level,$tag";
            } else {
                $candidate_rating = $rating;
                $candidate_level = $level;
                $candidate_tag = $tag;
                @ties = "$level,$tag";
            }
        }
    }

    if ($candidate_rating == DEFINITELY && @ties > 1) {
        my $tielist = join ", ", map { "($_)" } @ties;

        die "All of $tielist were rated at definitely.  This indicates a bug in the recognizers."
    }

    return ($candidate_rating, $candidate_level, $candidate_tag, @ties);
}

# One definitely makes everything else d.not, etc
sub _constrain_disjunction {
    my ($self, $lset, $tset) = @_;

    $lset = [$lset] unless ref $lset;
    $tset = [$tset] unless ref $tset;

    my $candidate_rating = NEUTRAL;
    my ($candidate_rating, $candidate_level, $candidate_tag, @ties) =
        $self->_get_candidate($lset, $tset);

    for my $level (@$lset) {
        for my $tag (@$tset) {

            next if $level eq $candidate_level && $tag eq $candidate_tag;

            next if $self->_rate($level,$tag) < -$candidate_rating;

            $self->_rate($level,$tag, -$candidate_rating);
        }
    }
}

##########

sub rate {
    my $self = shift;
    string_ratings->[$self->_rate(@_)];
}

#XXX these are inefficient
sub candidate {
    my ($self, $tag) = @_;

    my ($rating, $name, $tag, @ties) = 
        $self->_get_candidate([ keys %{ $self->_dungeon_tags } ], [ $tag ]);

    return $self->stable2level($name);
}

sub classify {
    my ($self, $level) = @_;

    my ($rating, $name, $tag, @ties) = 
        $self->_get_candidate([ $self->level2stable($level) ],
            [ $self->level_type_tags ]);

    return $tag;
}

sub branch {
    my ($self, $level) = @_;

    my ($rating, $name, $tag, @ties) = 
        $self->_get_candidate([ $self->level2stable($level) ],
            [ $self->branch_tags ]);

    return $tag;
}

__PACKAGE__->meta->make_immutable;

1;
