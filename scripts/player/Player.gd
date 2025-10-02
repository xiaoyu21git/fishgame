extends CharacterBody2D
class_name Player


# === 导出的配置变量 ===
@export_category("移动设置")
@export var walk_speed: float = 150.0
@export var run_speed: float = 200.0
@export var acceleration: float = 15.0
@export var friction: float = 20.0

@export_category("冲刺设置")
@export var dash_multiplier: float = 2.5
@export var dash_time: float = 0.2
@export var dash_cooldown: float = 1.0
@export var ghost_interval: float = 0.05
@export var ghost_scene: PackedScene = preload("res://scenes/player/Ghost.tscn")  

@export_category("捕捉设置")
@export var catch_cooldown: float = 0.5
@export var catch_range: float = 80.0

@export_category("工具设置")
@export var available_tools: Array[ToolData] = []

# === 节点引用 ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var catch_area: Area2D = $CatchArea
@onready var tool_anchor: Node2D = $ToolAnchor
@onready var tool_sprite: Sprite2D = $ToolAnchor/ToolSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var stamina_bar: ProgressBar = $StaminaBar   # 直接挂在 Player 节点下的 ProgressBar
# === 内部变量 ===
var _current_speed: float = walk_speed
var _is_running: bool = false
var _catch_cooldown_timer: float = 0.0
var _current_tool_index: int = 0
var _current_tool_data: ToolData = null
var _fish_in_range: Array[Fish] = []

# 玩家基础速度
@export var base_speed: float = 200.0

# 当前速度倍率（墨汁减速时用）
var speed_multiplier: float = 1.0

# 冲刺相关
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _ghost_timer: float = 0.0


# === 体力属性 ===
@export var max_stamina: float = 100.0
@export var stamina_recover: float = 20.0   # 每秒恢复
@export var stamina_cost_run: float = 10.0  # 跑步每秒消耗
@export var stamina_cost_dash: float = 30.0 # 冲刺一次消耗
var stamina: float = max_stamina


# 物理层常量
const LAYER_PLAYER := 1
const LAYER_PLAYER_CATCH_AREA := 4
const LAYER_FISH := 2
const LAYER_ENVIRONMENT := 3


func _ready():
	# 设置物理层级
	_setup_collision_layers()
	
	# 初始化工具
	if available_tools.size() > 0:
		_current_tool_data = available_tools[0]
		_update_tool_display()
	
	# 连接捕捉区域的信号
	catch_area.body_entered.connect(_on_catch_area_body_entered)
	catch_area.body_exited.connect(_on_catch_area_body_exited)

func _setup_collision_layers():
	"""设置玩家所有碰撞层级"""
	
	# 玩家本体在"player"层 (第1层)
	collision_layer = 1 << (LAYER_PLAYER - 1)
	
	# 玩家碰撞环境障碍物
	collision_mask = 1 << (LAYER_ENVIRONMENT - 1)
	
	# 捕捉区域在"player_catch_area"层 (第4层)
	catch_area.collision_layer = 1 << (LAYER_PLAYER_CATCH_AREA - 1)
	
	# 捕捉区域只检测鱼
	catch_area.collision_mask = 1 << (LAYER_FISH - 1)
	
	# 设置捕捉区域形状大小
	var catch_shape: CollisionShape2D = catch_area.get_child(0)
	if catch_shape and catch_shape.shape is CircleShape2D:
		catch_shape.shape.radius = catch_range

func _physics_process(delta):
	# 处理输入
	_handle_input(delta)
	
	# 更新冷却计时器
	_update_cooldown_timer(delta)
	
	# 移动玩家
	_handle_movement(delta)
	
	# 更新工具方向
	_update_tool_direction()

func _handle_input( delta):
	# === 跑步切换 ===
	_is_running = Input.is_action_pressed("sprint") and stamina > 0
	_current_speed = run_speed if _is_running else walk_speed
	
	if _is_running:
		stamina -= stamina_cost_run * delta
		stamina = max(stamina, 0)

	# === 工具切换 ===
	if Input.is_action_just_pressed("tool_next"):
		_switch_to_next_tool()
	elif Input.is_action_just_pressed("tool_previous"):
		_switch_to_previous_tool()

	# === 冲刺输入（Shift） ===
	if Input.is_action_just_pressed("sprint") and not _is_dashing and _dash_cooldown_timer <= 0:
		if stamina >= stamina_cost_dash:  # 体力够才允许冲刺
			var input_dir = Vector2(
				Input.get_axis("move_left", "move_right"),
				Input.get_axis("move_up", "move_down")
			).normalized()

			if input_dir != Vector2.ZERO:
				_is_dashing = true
				_dash_timer = dash_time
				_ghost_timer = 0.0
				stamina -= stamina_cost_dash   # 冲刺瞬间扣除体力

	# === 捕捉输入 ===
	if Input.is_action_just_pressed("catch") and _catch_cooldown_timer <= 0:
		_attempt_catch()

	# === 体力恢复（不冲刺/不跑步时恢复） ===
	if not _is_running and not _is_dashing:
		stamina += stamina_recover * delta
		stamina = min(stamina, max_stamina)

	# === 更新体力条 UI ===
	_update_stamina_bar()
# 更新 UI
func _update_stamina_bar():
	var bar = get_node_or_null("StaminaBar")
	if bar:
		bar.value = stamina
		_update_stamina_color()

# 体力条变色
func _update_stamina_color():
	if stamina_bar:
		stamina_bar.value = stamina
		stamina_bar.max_value = max_stamina

		var ratio = stamina / max_stamina
		if ratio > 0.7:
			stamina_bar.modulate = Color(0, 1, 0)   # 绿色
		elif ratio > 0.3:
			stamina_bar.modulate = Color(1, 1, 0)   # 黄色
		else:
			stamina_bar.modulate = Color(1, 0, 0)   # 红色

func _handle_movement(delta):
	var input_direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()

	if _is_dashing:
		_dash_timer -= delta
		#velocity = input_direction * run_speed * dash_multiplier
		velocity = input_direction * base_speed * speed_multiplier

		# 生成残影
		_ghost_timer -= delta
		if _ghost_timer <= 0:
			_spawn_ghost()
			_ghost_timer = ghost_interval

		if _dash_timer <= 0:
			_is_dashing = false
			_dash_cooldown_timer = dash_cooldown

	elif input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * _current_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)

	move_and_slide()

func _update_tool_direction():
	"""根据鼠标或移动方向更新工具方向"""
	var mouse_pos = get_global_mouse_position()
	var look_direction = (mouse_pos - global_position).normalized()
	
	# 工具朝向鼠标
	tool_anchor.rotation = look_direction.angle()
	
	# 根据方向翻转精灵
	if look_direction.x != 0:
		sprite.flip_h = look_direction.x < 0
		tool_sprite.flip_v = look_direction.x < 0
func _spawn_ghost():
	if not ghost_scene:
		return
	var ghost = ghost_scene.instantiate()
	get_parent().add_child(ghost)
	ghost.global_position = global_position
	ghost.rotation = rotation
	ghost.scale = scale
	# 给 Ghost 设置材质或图像
	if ghost.has_method("set_texture"):
		ghost.set_texture(sprite.texture)


# ============ 冷却处理 ============
func _update_cooldown_timer(delta):
	if _catch_cooldown_timer > 0:
		_catch_cooldown_timer -= delta
	if _dash_cooldown_timer > 0:
		_dash_cooldown_timer -= delta
		
func _attempt_catch():
	"""尝试捕捉鱼"""
	if _catch_cooldown_timer > 0 or _fish_in_range.is_empty():
		return
	
	# 找到最近的鱼
	var closest_fish: Fish = null
	var closest_distance: float = INF
	
	for fish in _fish_in_range:
		var distance = global_position.distance_to(fish.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_fish = fish
	
	if closest_fish:
		# 计算捕捉成功率（基于距离和工具）
		var success_rate = _calculate_catch_success_rate(closest_distance)
		var caught = randf() < success_rate
		
		if caught:
			var fish_value = closest_fish.catch()
			_on_fish_caught(fish_value, closest_fish.fish_data.fish_name)
			#_play_catch_animation(true)
		else:
			#_play_catch_animation(false)
			print("捕捉失败！鱼逃走了")
	
	_catch_cooldown_timer = catch_cooldown

func _calculate_catch_success_rate(distance: float) -> float:
	"""计算捕捉成功率"""
	var base_rate = 0.8  # 基础成功率
	var distance_penalty = clamp(distance / catch_range, 0.0, 1.0) * 0.5
	var tool_bonus = _current_tool_data.success_bonus if _current_tool_data else 0.0
	
	return clamp(base_rate - distance_penalty + tool_bonus, 0.1, 0.95)

func _switch_to_next_tool():
	"""切换到下一个工具"""
	if available_tools.size() > 1:
		_current_tool_index = (_current_tool_index + 1) % available_tools.size()
		_current_tool_data = available_tools[_current_tool_index]
		_update_tool_display()

func _switch_to_previous_tool():
	"""切换到上一个工具"""
	if available_tools.size() > 1:
		_current_tool_index = (_current_tool_index - 1) % available_tools.size()
		_current_tool_data = available_tools[_current_tool_index]
		_update_tool_display()

func _update_tool_display():
	"""更新工具显示"""
	if _current_tool_data and _current_tool_data.tool_texture:
		tool_sprite.texture = _current_tool_data.tool_texture
		tool_sprite.visible = true
	else:
		tool_sprite.visible = false


func _play_movement_animation(direction: Vector2):
	"""播放移动动画"""
	if _is_running:
		animation_player.play("run")
	else:
		animation_player.play("walk")
	
	# 根据方向调整动画方向
	if abs(direction.x) > abs(direction.y):
		sprite.flip_h = direction.x < 0

func _play_idle_animation():
	"""播放闲置动画"""
	animation_player.play("idle")

func _play_catch_animation(success: bool):
	"""播放捕捉动画"""
	var anim_name = "catch_success" if success else "catch_fail"
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func _on_catch_area_body_entered(body: Node2D):
	"""有鱼进入捕捉范围"""
	if body is Fish:
		_fish_in_range.append(body)
		print("鱼进入范围: ", body.fish_data.fish_name)

func _on_catch_area_body_exited(body: Node2D):
	"""鱼离开捕捉范围"""
	if body is Fish:
		_fish_in_range.erase(body)
		print("鱼离开范围: ", body.fish_data.fish_name)

func _on_fish_caught(value: int, fish_name: String):
	"""成功捕捉到鱼"""
	print("捕捉成功！获得 %d 金币: %s" % [value, fish_name])
	# 这里可以触发UI更新、音效等
	if _current_tool_data and _current_tool_data.catch_sound:
		audio_player.stream = _current_tool_data.catch_sound
		audio_player.play()
	
	# 发送全局信号
	GameEvents.fish_caught.emit(value, fish_name)

# === 公共API ===
func get_current_tool() -> ToolData:
	return _current_tool_data

func get_fish_in_range_count() -> int:
	return _fish_in_range.size()

func is_catch_on_cooldown() -> bool:
	return _catch_cooldown_timer > 0

func apply_slow(factor: float):
	speed_multiplier = factor

func remove_slow():
	speed_multiplier = 1.0
