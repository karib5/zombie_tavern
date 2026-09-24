extends Node

enum GameMode {
	PROTOTYPE,
}

var current_game_mode: GameMode = GameMode.PROTOTYPE

## Set once the player scene is instanced (Phase 2).
var player: Node2D = null
