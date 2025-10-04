extends CharacterBody2D
class_name Fish

# === 数据属性 ===
@export var fish_data: FishData
@export var current_state: int = 0  # 使用枚举 FishState

# === 节点引用 ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var vision_cone: Area2D = $VisionCone
@onready var wander_area: Area2D = $WanderArea
@onready var flee_timer: Timer = $FleeTimer
@onready var hide_timer: Timer = $HideTimer

# === 内部模块 ===
var stamina_system: FishStamina
var struggle_system: FishStruggle
var skill_system: FishSkillSystem
var sound_system: FishSound

# @onready var struggle_sounds: Array = [
# 	preload("res://audio/sfx/fish/small_splash1.mp3"),
# 	preload("res://audio/sfx/fish/small_splash2.mp3")
# ]

# === 状态枚举 ===
enum FishState { WANDER, ALERT, FLEE, FLEE_TO_HOLE, HIDING, CATCHED }

# === 内部状态 ===
var _wander_direction: Vector2 = Vector2.ZERO
var _wander_time: float = 0.0
var _player_ref: Node2D = null
var _target_hole_pos: Vector2 = Vector2.ZERO
var _flee_direction: Vector2 = Vector2.ZERO

# === 初始化 ===
func _ready() -> void:
	if fish_data == null:
		fish_data = FishData.new()

	stamina_system = FishStamina.new()
	stamina_system.setup(fish_data)

	struggle_system = FishStruggle.new()
	struggle_system.setup(fish_data)

	skill_system = FishSkillSystem.new()
	skill_system.setup(fish_data)

	sound_system = FishSound.new()

	_setup_fish()
	_set_new_wander_direction()

	if vision_cone:
		vision_cone.body_entered.connect(_on_vision_cone_body_entered)
		vision_cone.body_exited.connect(_on_vision_cone_body_exited)
	if flee_timer:
		flee_timer.timeout.connect(_on_flee_timeout)
	if hide_timer:
		hide_timer.timeout.connect(_on_hide_timeout)

# === 初始化外观 ===
func _setup_fish() -> void:
	if sprite:
		sprite.modulate = _get_fish_color()

func _get_fish_color() -> Color:
	match fish_data.fish_name:
		"小鱼": return Color.YELLOW
		"中型鱼": return Color.BLUE
		"大鱼": return Color.RED
		_: return Color.WHITE

# === 动画控制 ===
func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		anim.stop()
		return

	var abs_dir = direction.normalized()
	if abs(abs_dir.x) > abs(abs_dir.y):
		if abs_dir.x > 0:
			anim.play("right")
		else:
			anim.play("left")
	else:
		if abs_dir.y > 0:
			anim.play("down")
		else:
			anim.play("up")

# === 状态机逻辑 ===
func _physics_process(delta: float) -> void:
	stamina_system.update(delta)

	match current_state:
		FishState.WANDER:
			_update_wander(delta)
		FishState.ALERT:
			_update_alert(delta)
		FishState.FLEE:
			_update_flee(delta)
		FishState.FLEE_TO_HOLE:
			_update_flee_to_hole(delta)
		FishState.HIDING:
			_update_hiding(delta)
		FishState.CATCHED:
			_update_catched(delta)

	move_and_slide()

	_update_animation(velocity)

# === 状态更新函数 ===
func _update_wander(delta: float) -> void:
	velocity = _wander_direction * fish_data.speed
	_wander_time -= delta
	if _wander_time <= 0:
		_set_new_wander_direction()
	_check_boundaries()

func _update_alert(delta: float) -> void:
	if _player_ref:
		var dir_away = (global_position - _player_ref.global_position).normalized()
		velocity = dir_away * fish_data.speed * 0.6
		if global_position.distance_to(_player_ref.global_position) < fish_data.vision_range * 0.5:
			_enter_flee_state()

func _update_flee(delta: float) -> void:
	if not _player_ref:
		current_state = FishState.WANDER
		_set_new_wander_direction()
		return
	_flee_direction = (_flee_direction + (global_position - _player_ref.global_position).normalized()).normalized()
	velocity = _flee_direction * stamina_system.get_flee_speed(delta)
	stamina_system.consume(delta)

func _update_flee_to_hole(delta: float) -> void:
	if _target_hole_pos == Vector2.ZERO:
		_target_hole_pos = _find_nearest_hole_position()
		if _target_hole_pos == Vector2.ZERO:
			_enter_flee_state()
			return

	var dir = (_target_hole_pos - global_position)
	if dir.length() < 8.0:
		_enter_hiding()
		return

	dir = dir.normalized()
	velocity = dir * stamina_system.get_flee_speed(delta)
	stamina_system.consume(delta)

func _update_hiding(delta: float) -> void:
	velocity = Vector2.ZERO
	stamina_system.recover(delta)
	anim.stop() # 停止播放动画

func _update_catched(delta: float) -> void:
	struggle_system.update(delta)
	if struggle_system.should_escape():
		_perform_escape_from_capture()
		return
	if struggle_system._is_struggling():
		velocity = struggle_system.get_velocity()
		sound_system.play_struggle_sound()
	else:
		velocity = Vector2.ZERO

# === 状态切换 ===
func _enter_flee_state() -> void:
	current_state = FishState.FLEE
	_flee_direction = (global_position - _player_ref.global_position).normalized()
	stamina_system.start_flee()

func _enter_flee_to_hole() -> void:
	current_state = FishState.FLEE_TO_HOLE
	_target_hole_pos = _find_nearest_hole_position()
	stamina_system.start_flee()

func _enter_hiding() -> void:
	current_state = FishState.HIDING
	velocity = Vector2.ZERO
	hide_timer.start(randf_range(fish_data.hide_duration_range.x, fish_data.hide_duration_range.y))
	stamina_system.start_hide()

# === 捕抓接口 ===
func catch() -> int:
	current_state = FishState.CATCHED
	#struggle_system.start_struggle(struggle_sounds)
	return fish_data.value

func _perform_escape_from_capture() -> void:
	struggle_system.reset()
	_enter_flee_to_hole()

# === 信号处理 ===
func _on_vision_cone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_ref = body
		_enter_flee_to_hole()

func _on_vision_cone_body_exited(body: Node2D) -> void:
	if body == _player_ref:
		_player_ref = null
		if current_state != FishState.FLEE and current_state != FishState.FLEE_TO_HOLE:
			current_state = FishState.WANDER
			_set_new_wander_direction()

func _on_flee_timeout() -> void:
	if _player_ref:
		_enter_flee_state()
	else:
		current_state = FishState.WANDER
		_set_new_wander_direction()

func _on_hide_timeout() -> void:
	current_state = FishState.WANDER
	_target_hole_pos = Vector2.ZERO
	_set_new_wander_direction()
	stamina_system.reset_recovery_delay()

# === 辅助函数 ===
func _set_new_wander_direction() -> void:
	_wander_direction = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
	_wander_time = randf_range(1.0,3.0)

func _check_boundaries() -> void:
	var size = get_viewport().size
	if global_position.x < 0 or global_position.x > size.x:
		_wander_direction.x *= -1
		_flee_direction.x *= -1
	if global_position.y < 0 or global_position.y > size.y:
		_wander_direction.y *= -1
		_flee_direction.y *= -1

func _find_nearest_hole_position() -> Vector2:
	var best_pos = Vector2.ZERO
	var best_d = INF
	var holes = get_tree().get_nodes_in_group("hole")
	for h in holes:
		if not (h is Node2D):
			continue
		var d = global_position.distance_to(h.global_position)
		if d < best_d:
			best_d = d
			best_pos = h.global_position
	return best_pos

func randf_range(a: float, b: float) -> float:
	return lerp(a, b, randf())
