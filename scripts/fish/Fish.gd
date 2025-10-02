extends CharacterBody2D
class_name Fish


# === 数据属性 ===
@export var fish_data: FishData
@export var current_state: int = 0  # 使用枚举 FishState

# 节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var vision_cone: Area2D = $VisionCone
@onready var wander_area: Area2D = $WanderArea
@onready var flee_timer: Timer = $FleeTimer
@onready var hide_timer: Timer = $HideTimer
var skill: SkillData = SkillData.new()

enum FishSkill { NONE, INK_SPRAY }

# 技能数据结构（可扩展）

# 内部状态
var _wander_direction: Vector2 = Vector2.ZERO
var _wander_time: float = 0.0
var _player_ref: Node2D = null

# 挣扎系统
var _is_struggling: bool = false
var _struggle_time: float = 0.0
var _struggle_force: float = 0.0

# 逃跑变量
var _current_flee_speed: float = 0.0
var _flee_acceleration: float = 600.0  # 每秒增加的速度
var _flee_direction: Vector2 = Vector2.ZERO

# 体力系统
@export var max_stamina: float = 100.0
var stamina: float = 100.0
@export var stamina_recovery_rate: float = 5.0        # 每秒自然恢复量
@export var stamina_recovery_delay: float = 3.0       # 使用后 / 逃跑后等待多少秒才开始自然恢复
var _stamina_recovery_countdown: float = 0.0

# 随机体力刷新（偶发）
@export var random_stamina_refresh_interval_range: Vector2 = Vector2(8.0, 20.0) # 随机间隔 (min,max)
@export var random_stamina_refresh_amount_range: Vector2 = Vector2(5.0, 25.0)  # 随机补充量 (min,max)
var _next_random_refresh_time: float = 0.0

# 隐蔽/钻洞行为
var _target_hole_pos: Vector2 = Vector2.ZERO
@export var hide_duration_range: Vector2 = Vector2(5.0, 12.0) # 躲藏随机时长

# 状态枚举
enum FishState { WANDER, ALERT, FLEE, FLEE_TO_HOLE, HIDING, CATCHED }

# 鱼的挣扎音效池
var fish_struggle_sounds = [
	#preload("res://resources/sounds/small_splash1.mp3"),
	# preload("res://resources/sounds/small_splash2.mp3")
]

# === 初始化 ===
func _ready() -> void:
	if fish_data == null:
		_setup_default_fish_data()

	_setup_fish()
	_set_new_wander_direction()

	# 初始化体力和随机刷新计时
	stamina = max_stamina
	_stamina_recovery_countdown = 0.0
	_schedule_next_random_refresh()

	# 连接信号（若节点不存在会在运行时报错，但不是 Parser Error）
	if vision_cone:
		vision_cone.body_entered.connect(_on_vision_cone_body_entered)
		vision_cone.body_exited.connect(_on_vision_cone_body_exited)
	if flee_timer:
		flee_timer.timeout.connect(_on_flee_timeout)
	if hide_timer:
		hide_timer.timeout.connect(_on_hide_timeout)

func _setup_default_fish_data() -> void:
	fish_data = FishData.new()
	fish_data.fish_name = "小鱼"
	fish_data.speed = 50.0
	fish_data.flee_speed = 140.0
	fish_data.wander_range = 100.0
	fish_data.vision_range = 80.0
	fish_data.value = 5
	fish_data.strength = 50
	fish_data.recovery = 1.0
	fish_data.duration = 5.0
	fish_data.effect = "None"

func _setup_fish() -> void:
	if sprite:
		sprite.modulate = _get_fish_color()

func _get_fish_color() -> Color:
	match fish_data.fish_name:
		"小鱼": return Color.YELLOW
		"中型鱼": return Color.BLUE
		"大鱼": return Color.RED
		_ : return Color.WHITE

# === 游戏逻辑 ===
func _physics_process(delta: float) -> void:
	# 随机体力刷新计时
	_update_random_stamina_refresh(delta)

	# 自然体力恢复计时
	if _stamina_recovery_countdown > 0.0:
		_stamina_recovery_countdown = max(0.0, _stamina_recovery_countdown - delta)
	else:
		_recover_stamina(delta)

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

	# 移动（CharacterBody2D 的 velocity 已在各状态中设置）
	move_and_slide()

# --- 游动 ---
func _update_wander(delta: float) -> void:
	velocity = _wander_direction * fish_data.speed
	_wander_time -= delta
	if _wander_time <= 0:
		_set_new_wander_direction()
	_check_boundaries()

# --- 警觉状态 ---
func _update_alert(delta: float) -> void:
	if _player_ref:
		var dir_away = (global_position - _player_ref.global_position).normalized()
		velocity = dir_away * fish_data.speed * 0.6
		if global_position.distance_to(_player_ref.global_position) < fish_data.vision_range * 0.5:
			_enter_flee_state()

# --- 逃跑状态 ---
func _update_flee(delta: float) -> void:
	if not _player_ref:
		# 若玩家离开视野，尝试寻找洞或回到漫游
		current_state = FishState.WANDER
		_set_new_wander_direction()
		return

	# 随机微调方向，模拟慌不择路
	if randf() < 0.3:
		_flee_direction = _flee_direction.rotated(randf_range(-PI/3, PI/3))

	# 保证基本远离玩家
	var dir_to_player = (global_position - _player_ref.global_position).normalized()
	_flee_direction = (_flee_direction + dir_to_player).normalized()

	# 根据体力调整加速度/最大速度（体力越低，最大逃跑速度越受限）
	var stamina_factor = clamp(stamina / max_stamina, 0.1, 1.0)
	_current_flee_speed += _flee_acceleration * delta * stamina_factor
	var max_allowed = lerp(fish_data.speed, fish_data.flee_speed, stamina_factor)
	_current_flee_speed = clamp(_current_flee_speed, fish_data.speed, max_allowed)

	# 扣减体力（逃跑消耗）
	_consume_stamina(20.0 * delta)  # 每秒消耗示例，按需调节

	velocity = _flee_direction * _current_flee_speed
	_check_boundaries()

# --- 逃跑并钻洞（优先寻找最近的洞） ---
func _update_flee_to_hole(delta: float) -> void:
	# 如果没有目标洞或洞不再有效 -> 尝试重新找洞或退回普通逃跑
	if _target_hole_pos == Vector2.ZERO:
		_target_hole_pos = _find_nearest_hole_position()
		if _target_hole_pos == Vector2.ZERO:
			# 没有洞，退回普通逃跑
			_enter_flee_state()
			return

	# 走向洞
	var dir = (_target_hole_pos - global_position)
	if dir.length() < 8.0:
		# 到达洞口 -> 进入躲藏
		_enter_hiding()
		return

	dir = dir.normalized()
	# 速度受体力影响
	var stamina_factor = clamp(stamina / max_stamina, 0.1, 1.0)
	var target_speed = lerp(fish_data.speed, fish_data.flee_speed, stamina_factor)
	_consume_stamina(15.0 * delta)
	velocity = dir * target_speed
	_check_boundaries()

# --- 躲藏状态（在洞里） ---
func _update_hiding(delta: float) -> void:
	# 基本上处于静止或缓慢恢复体力，直到 hide_timer 超时
	velocity = Vector2.ZERO

# --- 抓捕挣扎 ---
func _update_catched(delta: float) -> void:
	# 在被抓时，挣扎并可能概率逃脱
	if _is_struggling:
		_struggle_time -= delta

		# 随机抽动 + 旋转
		if randf() < 0.2:
			var random_dir = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
			velocity = random_dir * _struggle_force
			rotation += randf_range(-0.2, 0.2)

		# 渐渐衰减挣扎力
		_struggle_force = lerp(_struggle_force, 0.0, 0.05)

		# 播放挣扎音效
		if randf() < 0.05:
			_play_struggle_sound()

		# 检查逃脱概率（基于 fish_data.strength 与随机）
		if randf() < _escape_chance_per_second(delta):
			_perform_escape_from_capture()
			return

		# 结束挣扎
		if _struggle_time <= 0 or _struggle_force <= 5.0:
			_is_struggling = false
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

# --- 状态切换函数 ---
func _enter_flee_state() -> void:
	if _player_ref == null:
		return
	current_state = FishState.FLEE
	if flee_timer:
		flee_timer.start(randf_range(3.0,6.0))  # 逃跑持续时间
	_current_flee_speed = fish_data.speed * 0.5  # 初始逃跑速度
	_flee_direction = (global_position - _player_ref.global_position).normalized()
	# 逃跑后延迟体力自然恢复
	_stamina_recovery_countdown = stamina_recovery_delay

func _enter_flee_to_hole() -> void:
	current_state = FishState.FLEE_TO_HOLE
	_target_hole_pos = _find_nearest_hole_position()
	if _target_hole_pos == Vector2.ZERO:
		# 没洞，退回普通逃跑
		_enter_flee_state()
		return
	_stamina_recovery_countdown = stamina_recovery_delay

func _enter_hiding() -> void:
	current_state = FishState.HIDING
	velocity = Vector2.ZERO
	var t = randf_range(hide_duration_range.x, hide_duration_range.y)
	if hide_timer:
		hide_timer.start(t)

# === 捕抓接口 ===
func catch() -> int:
	# 外部调用抓捕（比如钩子或手）会调用此函数
	if current_state != FishState.CATCHED:
		current_state = FishState.CATCHED
		velocity = Vector2.ZERO

		# 初始化挣扎
		_struggle_time = fish_data.duration
		_struggle_force = fish_data.flee_speed * 0.6
		_is_struggling = true

		# 抓到后有一定概率直接逃脱（基于 strength）
		# 若没有立即逃脱，可能在挣扎中逃脱（handled in _update_catched）
		if randf() < _immediate_escape_chance():
			_perform_escape_from_capture()
			return 0 # 未被成功带走（按逻辑可返回 0 表示无收益）
		return fish_data.value
	return 0

func get_fish_value() -> int:
	return fish_data.value

# === 体力相关辅助 ===
func _consume_stamina(amount: float) -> void:
	stamina = max(0.0, stamina - amount)
	_stamina_recovery_countdown = stamina_recovery_delay

func _recover_stamina(delta: float) -> void:
	if stamina < max_stamina:
		stamina = min(max_stamina, stamina + stamina_recovery_rate * delta)

func _schedule_next_random_refresh() -> void:
	_next_random_refresh_time = randf_range(random_stamina_refresh_interval_range.x, random_stamina_refresh_interval_range.y)

func _update_random_stamina_refresh(delta: float) -> void:
	_next_random_refresh_time -= delta
	if _next_random_refresh_time <= 0.0:
		var amount = randf_range(random_stamina_refresh_amount_range.x, random_stamina_refresh_amount_range.y)
		stamina = min(max_stamina, stamina + amount)
		_schedule_next_random_refresh()

# === 抓捕逃脱相关 ===
func _immediate_escape_chance() -> float:
	# 依据 fish_data.strength 决定立即逃脱概率（0..1）
	return clamp(0.6 - fish_data.strength / 200.0, 0.05, 0.6)

func _escape_chance_per_second(delta: float) -> float:
	return clamp((fish_data.strength / 150.0) * delta, 0.01, 0.5)

func _perform_escape_from_capture() -> void:
	_is_struggling = false
	_struggle_time = 0.0
	if _player_ref:
		_flee_direction = (global_position - _player_ref.global_position).normalized()
	else:
		_flee_direction = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
	_current_flee_speed = fish_data.speed
	_enter_flee_to_hole()

# === 查找附近洞口（通过 group "hole"） ===
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

# === 边界处理 ===
func _set_new_wander_direction() -> void:
	_wander_direction = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
	_wander_time = randf_range(1.0,3.0)

func _check_boundaries() -> void:
	var size = get_viewport().size
	# 若撞到边界，则反向并微调
	if global_position.x < 0 or global_position.x > size.x:
		_wander_direction.x *= -1
		_flee_direction.x *= -1
	if global_position.y < 0 or global_position.y > size.y:
		_wander_direction.y *= -1
		_flee_direction.y *= -1

# === 信号处理 ===
func _on_vision_cone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_ref = body
		# 立即进入逃跑（优先逃向洞）
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
	# 躲藏结束，恢复漫游
	current_state = FishState.WANDER
	_target_hole_pos = Vector2.ZERO
	_set_new_wander_direction()
	# 触发一次体力恢复（躲藏里可以自然恢复）
	_stamina_recovery_countdown = 0.0

# === 音效 ===
func _play_struggle_sound() -> void:
	if fish_struggle_sounds.size() == 0:
		return
	var sound = fish_struggle_sounds[randi() % fish_struggle_sounds.size()]
	# 假设存在 SoundManager.play_sound(sound)
	if Engine.has_singleton("SoundManager"):
		Engine.get_singleton("SoundManager").play_sound(sound)

# === 帮助函数 ===
func randf_range(a: float, b: float) -> float:
	return lerp(a, b, randf())

func can_use_skill() -> bool:
	# 获取当前时间（秒）
	var current_time = Time.get_ticks_msec() / 1000.0  # 秒
	return current_time - skill.last_used_time >= skill.cooldown

func use_skill() -> void:
	pass
	# if not can_use_skill():
	# 	return
	# match skill.skill_type:
	# 	FishSkill.INK_SPRAY:
	# 	_emit_ink()
		#skill.last_used_time = Time.get_ticks_msec() / 1000.0
