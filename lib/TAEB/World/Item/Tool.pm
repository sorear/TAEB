package TAEB::World::Item::Tool;
use TAEB::OO;
extends 'TAEB::World::Item';
with 'TAEB::World::Item::Role::Chargeable';
with 'TAEB::World::Item::Role::Enchantable';
with 'TAEB::World::Item::Role::Erodable';
with 'TAEB::World::Item::Role::Lightable';
with 'TAEB::World::Item::Role::Wearable';

has '+class' => (
    default => 'tool',
);

has is_partly_used => (
    isa     => 'Bool',
    default => 0,
);

has candles_attached => (
    isa     => 'Int',
    default => 0,
);

__PACKAGE__->install_spoilers(qw/charge/);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

