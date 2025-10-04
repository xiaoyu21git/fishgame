extends Node2D
class_name PlayerTools

var player: Player
var anim: Node
var audio: Node
var current_tool_index: int = 0
var tools: Array = []

@onready var tool_sprite: Sprite2D = $ToolSprite

func init(p, a, au):
    player = p
    anim = a
    audio = au

func _process_tools(delta):
    # 工具切换
    if Input.is_action_just_pressed("tool_next"):
        current_tool_index = (current_tool_index + 1) % tools.size()
        _update_tool_sprite()
    elif Input.is_action_just_pressed("tool_previous"):
        current_tool_index = (current_tool_index - 1 + tools.size()) % tools.size()
        _update_tool_sprite()

func _update_tool_sprite():
    if tools.is_empty():
        tool_sprite.visible = false
    else:
        tool_sprite.texture = tools[current_tool_index].tool_texture
        tool_sprite.visible = true
