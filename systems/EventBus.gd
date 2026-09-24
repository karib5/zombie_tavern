extends Node

## Global signal hub. Gameplay systems emit domain events here;
## unrelated systems (including the eventual tutorial layer) subscribe
## without the emitter ever referencing the listener.
##
## Intentionally empty for now — signals are added one at a time,
## alongside the system that first emits them, starting in Phase 5.

## Emitted by TavernAttackEvent.start_attack() (Phase 12), the moment an
## attack enters its WARNING state.
signal zombie_attack_started

## Emitted by TavernAttackEvent when all of a wave's zombies are dead
## (state -> COMPLETE).
signal zombie_attack_completed

## Emitted by TavernAttackEvent whenever a wave zombie's body enters the
## TavernDefenseArea for the first time.
signal zombie_breached_tavern(zombie: Node2D)
