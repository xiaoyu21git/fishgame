extends CharacterBody2D
class_name FisherBot

@export var bot_name: String = "Bot"
@export var move_speed: float = 150.0

var target_fish: Node2D = null
@onready var rod_area: Area2D = $RodArea

func _ready():
    rod_area.body_entered.connect(_on_body_entered)
    rod_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
    if target_fish:
        var dir = (target_fish.global_position - global_position).normalized()
        velocity = dir * move_speed
    else:
        velocity = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized() * (move_speed * 0.5)

    move_and_slide()

func _on_body_entered(body: Node2D):
    if body.is_in_group("fish") and target_fish == null:
        target_fish = body
        print(bot_name, " 发现鱼: ", body.name)
        # 模拟捕获
        await get_tree().create_timer(randf_range(0.5, 1.5)).timeout
        if body and body.is_inside_tree():
            print(bot_name, " 捕获了 ", body.name)
            body.queue_free()
        target_fish = null

func _on_body_exited(body: Node2D):
    if body == target_fish:
        target_fish = null
