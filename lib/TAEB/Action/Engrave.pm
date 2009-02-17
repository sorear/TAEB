package TAEB::Action::Engrave;
use TAEB::OO;
extends 'TAEB::Action';
with 'TAEB::Action::Role::Item';

use constant command => 'E';

has '+item' => (
    default => '-',
);

has text => (
    traits  => [qw/TAEB::Provided/],
    isa     => 'Str',
    default => 'Elbereth',
);

has add_engraving => (
    traits  => [qw/TAEB::Provided/],
    isa     => 'Bool',
    default => 1,
);

has got_identifying_message => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

sub engrave_slot {
    my $self = shift;
    my $engraver = $self->item;

    return $engraver->slot if blessed $engraver;
    return $engraver;
}

sub respond_write_with    { shift->engrave_slot }
sub respond_write_what    { shift->text . "\n" }
sub respond_add_engraving { shift->add_engraving ? 'y' : 'n' }

sub msg_wand {
    my $self = shift;
    $self->got_identifying_message(1);
    $self->item->tracker->rule_out_all_but(@_);
}

sub done {
    my $self = shift;
    TAEB->current_tile->engraving(TAEB->current_tile->engraving . $self->text);
    return unless blessed $self->item;

    if ($self->item->match(type => 'wand')) {
        $self->item->spend_charge;
    }
    elsif ($self->item->match(identity => 'magic marker')) {
        $self->item->spend_charge(int(length($self->text) / 2));
    }

    return if $self->got_identifying_message;
    return if $self->item->identity; # perhaps we identified it?
    $self->item->tracker->no_engrave_message if $self->item->has_tracker;
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

