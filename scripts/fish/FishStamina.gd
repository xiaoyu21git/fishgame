# FishStamina.gd
extends Node

class_name FishStamina

# 外部可配置参数
var max_stamina: float = 100.0
var recovery_rate: float = 5.0          # 每秒自然恢复量
var recovery_delay: float = 3.0         # 使用后等待多少秒才开始恢复
var random_refresh_interval_range: Vector2 = Vector2(8.0, 20.0) # 随机间隔 (min,max)
var random_refresh_amount_range: Vector2 = Vector2(5.0, 25.0)  # 随机补充量 (min,max)

# 内部状态
var stamina: float = 100.0
var _recovery_countdown: float = 0.0
var _next_random_refresh_time: float = 0.0



func setup(fish_data: FishData):
    max_stamina = fish_data.strength        # 或 fish_data.max_stamina，如果有的话
    stamina = max_stamina
    recovery_rate = fish_data.recovery
    _recovery_countdown = 0.0
    _schedule_next_random_refresh()

# 每帧更新
func update(delta: float) -> void:
    # 自然恢复计时
    if _recovery_countdown > 0.0:
        _recovery_countdown = max(0.0, _recovery_countdown - delta)
    else:
        _recover_stamina(delta)

    # 随机体力刷新
    _update_random_refresh(delta)

# 消耗体力（外部调用）
func consume(amount: float) -> void:
    stamina = max(0.0, stamina - amount)
    _recovery_countdown = recovery_delay

# 内部恢复体力
func _recover_stamina(delta: float) -> void:
    if stamina < max_stamina:
        stamina = min(max_stamina, stamina + recovery_rate * delta)

# 随机体力刷新调度
func _schedule_next_random_refresh() -> void:
    _next_random_refresh_time = randf_range(random_refresh_interval_range.x, random_refresh_interval_range.y)

func _update_random_refresh(delta: float) -> void:
    _next_random_refresh_time -= delta
    if _next_random_refresh_time <= 0.0:
        var amount = randf_range(random_refresh_amount_range.x, random_refresh_amount_range.y)
        stamina = min(max_stamina, stamina + amount)
        _schedule_next_random_refresh()

# 辅助函数
func randf_range(a: float, b: float) -> float:
    return lerp(a, b, randf())
