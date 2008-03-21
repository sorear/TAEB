#!/usr/bin/env perl
package TAEB::World::Item::Scroll;
use TAEB::OO 'install_spoilers';
extends 'TAEB::World::Item';
with 'TAEB::World::Item::Role::Writable';

has '+class' => (
    default => 'scroll',
);

install_spoilers(qw/marker/);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

