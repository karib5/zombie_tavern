extends Node

## Global signal hub. Gameplay systems emit domain events here;
## unrelated systems (including the eventual tutorial layer) subscribe
## without the emitter ever referencing the listener.
##
## Intentionally empty for now — signals are added one at a time,
## alongside the system that first emits them, starting in Phase 5.
