# This is the new (Jun09) level classifier.
#
# First step: scan levels for intrinsic properties.  Properties are
# named with short strings like 'oracle'; each recognizer will return
# yes, no, or unknown for a given level,tag pair.  This is only done
# when the levels change.
#
# Second step is a process of local inference; given levels that always
# or never have other levels next to them, we assign that property to
# the corresponding level.
#
# Finally a uniqueness fixup is done, performing deductions by elimination
# on the levels.

package TAEB::Component::LevelClassifier;

use TAEB::OO;

# The tags, as they are computed on a level-by-level basis.
# Levels are only ever added to these hashes.

has _intrinsic_tags => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[Maybe[Bool]]]',
    default => sub { {} },
);

# The tags, cooked by constraint.

has _dungeon_tags => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[Maybe[Bool]]]',
    default => sub { {} },
);

# For unique things and exclusive types, store the holders here.

has _candidates => (
    is      => 'ro',
    isa     => 'HashRef[Maybe[String]]',
    default => sub { {} },
);

has _types => (
    is      => 'ro',
    isa     => 'HashRef[Maybe[String]]',
    default => sub { {} },
);

use constant special_tags => [qw/
    minetown minesend
    soko1 soko2 soko3 soko4
    questhome questlocate questgoal
    oracle bigroom rogue medusa castle
    valley asmodeus juiblex baalzebub wizard1 wizard2 wizard3
    orcus fakewiz1 fakewiz2 sanctum
    ludios
    vlad1 vlad2 vlad3
    earth fire air water astral/],

use constant unique_tags => [ @{ special_tags }, qw/
    minefork sokofork questfork ludiosfork vladfork vibratingsquare/ ];

my %_unique_tag = map { $_ => 1 } unique_tags;

#use constant branch_tags => [qw/mines sokoban quest dungeon gehennom ludios
#        planes vlad/],

use constant level_type_tags => [ @{ special_tags },
    qw/minefill dgnfill mazefill questfill1 questfill2/ ];

my %_level_type_tag = map { $_ => 1 } level_type_tags;

################

# Called by local_to_global to mark a property as true or false
sub _insert_one {
    my ($self, $level, $tag, $bool) = @_;

    if ($bool && $_unique_tag{$tag} &&
            ($self->_candidates->{$tag} ||= $level) ne $level) {
        warn "$level and " . $self->_candidates->{$tag} . " are both $tag??";
        $bool = 0;
    }

    if ($bool && $_level_type_tag{$tag} &&
            ($self->_types->{$level} ||= $tag) ne $tag) {
        warn "$level is both $tag and " . $self->_types->{$level} . "??";
        $bool = 0;
    }

    $self->_dungeon_tags->{$level}{$tag} = $bool;
}

sub _local_to_global {
    my ($self) = @_;

    while (my ($level, $info) = each %{ $self->_intrinsic_tags }) {
        while (my ($tag, $value) = each %$info) {
            $self->_insert_one($level, $tag, $value);
        }
    }
}

##########

sub is {
    my ($self, $level, $tag) = shift;
    $self->_dungeon_tags->{$level->stable_name}{$tag};
}

sub candidate {
    my ($self, $tag) = @_;

    $self->_candidates->{$tag};
}

sub classify {
    my ($self, $level) = @_;

    $self->_types->{$level->stable_name};
}

__PACKAGE__->meta->make_immutable;

1;
