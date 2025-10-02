extends Area2D

@export var range: float = 100.0           # 生效范围
@export var duration: float = 2.0          # 墨汁持续时间（秒）
@export var slow_factor: float = 0.5       # 玩家减速比例

@onready var timer: Timer = $Timer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	# 设置 CollisionShape2D 半径
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = range
	# 设置 Sprite 大小与范围匹配
	sprite.scale = Vector2.ONE * (range / 32.0)  # 假设纹理尺寸 32x32
	timer.wait_time = duration
	timer.start()
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")
	timer.timeout.connect(_on_timeout)

# 存储受影响的玩家
var affected_players: Array = []

func _on_body_entered(body: Node):
	if body.is_in_group("player") and not affected_players.has(body):
		affected_players.append(body)
		# 调用玩家减速方法
		if "apply_slow" in body:
			body.apply_slow(slow_factor)

func _on_body_exited(body: Node):
	if body in affected_players:
		affected_players.erase(body)
		if "remove_slow" in body:
			body.remove_slow()

func _on_timeout():
	# 还原玩家状态
	for p in affected_players:
		if "remove_slow" in p:
			p.remove_slow()
	queue_free()
