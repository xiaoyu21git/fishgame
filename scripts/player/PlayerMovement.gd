extends Node
class_name PlayerMovement

# === 外部引用类型 ===
var stamina: PlayerStamina  # PlayerStamina 类型
var player: CharacterBody2D  # Player 节点引用
var sprite: Sprite2D  # 玩家精灵引用
# === 移动参数 ===
@export var walk_speed: float = 150.0
@export var run_speed: float = 200.0
@export var acceleration: float = 15.0
@export var friction: float = 20.0

# === 冲刺与残影 ===
@export var dash_multiplier: float = 2.5
@export var dash_time: float = 0.2
@export var dash_cooldown: float = 1.0
@export var ghost_interval: float = 0.05
@export var ghost_scene: PackedScene = preload("res://scenes/player/Ghost.tscn")

# === 内部变量 ===
var _current_speed: float = walk_speed
var _is_running: bool = false
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _ghost_timer: float = 0.0
var speed_multiplier: float = 1.0
var velocity: Vector2 = Vector2.ZERO

# === 初始化方法 ===
func init(p: CharacterBody2D, s: PlayerStamina,sp: Sprite2D) -> void:
	player = p
	stamina = s
	sprite = sp

# === 移动与冲刺处理 ===
func _process_movement(delta: float) -> void:
	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()

	# 冲刺逻辑
	if _is_dashing:
		_dash_timer -= delta
		velocity = input_dir * run_speed * dash_multiplier * speed_multiplier

		# 生成固定纹理残影
		_ghost_timer -= delta
		if _ghost_timer <= 0:
			_spawn_ghost()
			_ghost_timer = ghost_interval

		if _dash_timer <= 0:
			_is_dashing = false
			_dash_cooldown_timer = dash_cooldown

	elif input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * _current_speed * speed_multiplier, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)

	player.velocity = velocity
	player.move_and_slide()

	# 冲刺输入（Shift）
	if Input.is_action_just_pressed("sprint") and not _is_dashing and _dash_cooldown_timer <= 0:
		if stamina.current_stamina >= stamina.stamina_cost_dash and input_dir != Vector2.ZERO:
			_is_dashing = true
			_dash_timer = dash_time
			_ghost_timer = 0.0
			stamina.consume(stamina.stamina_cost_dash)

	# 跑步切换
	_is_running = Input.is_action_pressed("sprint") and stamina.current_stamina > 0
	_current_speed = run_speed if _is_running else walk_speed
	if _is_running:
		stamina.consume(stamina.stamina_cost_run * delta)

	# 非跑步/冲刺时体力恢复
	if not _is_running and not _is_dashing:
		stamina._process_stamina(delta)

	# 冲刺冷却计时
	_dash_cooldown_timer = max(_dash_cooldown_timer - delta, 0)

# === 生成残影 ===
func _spawn_ghost() -> void:
	if ghost_scene == null or player == null or sprite == null:
		return

	var ghost = ghost_scene.instantiate()
	get_tree().get_current_scene().add_child(ghost)  # 添加到场景中

	# 设置 Ghost 的位置、旋转、缩放
	ghost.global_position = player.global_position
	ghost.rotation = player.rotation
	ghost.scale = player.scale

	# 给 Ghost 设置纹理
	if ghost.has_method("set_texture"):
		ghost.set_texture(sprite.texture)
