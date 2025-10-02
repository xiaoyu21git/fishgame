# GameEvents.gd
extends Node

# 定义信号 - 鱼被抓住
signal fish_caught(value: int, fish_name: String)
# 定义其他你可能需要的信号，例如：
# signal player_health_changed(new_health)
# signal game_over()

# 你可以在这里添加一些全局可访问的静态函数或常量（可选）
# static func some_utility_function():
#     pass
# GameEvents.gd


# 鱼相关事件

signal fish_spotted(fish_name: String)  # 鱼进入视野
signal fish_escaped(fish_name: String)  # 鱼逃跑

# 玩家事件
signal player_health_changed(new_health: int)
signal tool_changed(tool_name: String)

# 游戏状态事件
signal game_started()
signal game_paused()
signal game_resumed()
signal game_over(final_score: int)

# 工具函数
# static func emit_fish_caught(value: int, fish_name: String):
#     fish_caught.emit(value, fish_name)
