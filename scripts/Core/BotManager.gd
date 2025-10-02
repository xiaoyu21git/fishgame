extends Node2D

@export var bot_scene: PackedScene
@export var bot_count: int = 3
@export var spawn_area: Vector2 = Vector2(800, 600)

func _ready():
	spawn_bots()

func spawn_bots():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(bot_count):
		var bot = bot_scene.instantiate()
		bot.bot_name = "Bot_" + str(i+1)
		bot.position = Vector2(
			rng.randi_range(50, spawn_area.x - 50),
			rng.randi_range(50, spawn_area.y - 50)
		)
		$BotContainer.add_child(bot)
