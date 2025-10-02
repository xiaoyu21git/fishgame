# SkillData.gd
extends Resource
class_name SkillData

# 技能类型枚举
enum FishSkill {
	NONE,
	INK_SPRAY,      # 喷墨汁
	SPEED_BOOST,    # 加速逃跑
	HEAL,           # 自我恢复体力
	SCATTER         # 扩散逃跑，吓退周围小鱼
}

# 基础属性
@export var skill_type: int = FishSkill.NONE
@export var cooldown: float = 5.0           # 冷却时间
@export var effect_strength: float = 1.0    # 技能强度，可用于不同技能解释
@export var duration: float = 2.0           # 持续时间，可选
@export var icon: Texture2D                  # Inspector 展示图标

# 运行时属性（不导出）
var last_used_time: float = -999.0
