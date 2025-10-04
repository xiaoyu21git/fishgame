# FishSkillSystem.gd
extends Node
class_name FishSkillSystem

# 技能枚举
enum FishSkill { NONE, INK_SPRAY }

# 当前技能列表
var skills: Array = []

# 信号示例
signal emit_ink

# === 初始化技能系统 ===
func setup(fish_data: FishData) -> void:
	"""
	根据 FishData 的 effect 或其他字段初始化技能列表
	"""
	skills.clear()
	
	# 将 fish_data.effect 映射为技能类型
	var skill_type = FishSkill.NONE
	match fish_data.effect:
		"Ink": skill_type = FishSkill.INK_SPRAY
		_ : skill_type = FishSkill.NONE

	if skill_type != FishSkill.NONE:
		var skill = SkillData.new()
		skill.skill_type = skill_type
		skill.cooldown = fish_data.duration      # duration 可作为冷却时间参考
		skill.duration = fish_data.duration
		#skill.effect = fish_data.effect
		skill.last_used_time = -skill.cooldown   # 初始可立即使用
		skills.append(skill)

# 获取当前时间（秒）
func _current_time() -> float:
	return Time.get_ticks_msec() / 1000.0

# 判断技能是否可用
func can_use(skill_type: int) -> bool:
	var skill = _find_skill(skill_type)
	if skill == null:
		return false
	return _current_time() - skill.last_used_time >= skill.cooldown

# 使用技能
func use(skill_type: int) -> bool:
	var skill = _find_skill(skill_type)
	if skill == null:
		return false
	if not can_use(skill_type):
		return false

	skill.last_used_time = _current_time()
	_perform_skill_effect(skill)
	return true

# 内部查找技能
func _find_skill(skill_type: int) -> SkillData:
	for s in skills:
		if s.skill_type == skill_type:
			return s
	return null

# 技能效果触发（可根据技能类型扩展）
func _perform_skill_effect(skill: SkillData) -> void:
	match skill.skill_type:
		FishSkill.INK_SPRAY:
			_emit_ink()
		_:
			pass

# 喷墨技能触发
func _emit_ink() -> void:
	emit_signal("emit_ink")
