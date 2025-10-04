extends Area2D
class_name PlayerCatch

var player: Player
var tools: Node
var audio: Node
var catch_range: float = 80
var catch_cooldown: float = 0.5
var _catch_timer: float = 0
var _fish_in_range: Array = []

func init(p, t, a):
    player = p
    tools = t
    audio = a
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _process_catch(delta):
    if _catch_timer > 0:
        _catch_timer -= delta
    if Input.is_action_just_pressed("catch") and _catch_timer <= 0:
        _attempt_catch()

func _attempt_catch():
    if _fish_in_range.is_empty():
        return
    # 找到最近的鱼
    var closest = _fish_in_range[0]
    var dist = player.global_position.distance_to(closest.global_position)
    for fish in _fish_in_range:
        var d = player.global_position.distance_to(fish.global_position)
        if d < dist:
            closest = fish
            dist = d
    # 捕捉逻辑，可扩展
    var success = randf() < 0.8
    if success:
        print("捕获成功: ", closest.name)
    else:
        print("捕获失败")
    _catch_timer = catch_cooldown

func _on_body_entered(body):
    if body.is_in_group("Fish"):
        _fish_in_range.append(body)

func _on_body_exited(body):
    if body.is_in_group("Fish"):
        _fish_in_range.erase(body)
