extends Node
class_name PlayerAnimation

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func play_walk():
    anim_player.play("walk")

func play_run():
    anim_player.play("run")

func play_idle():
    anim_player.play("idle")

func play_catch(success: bool):
    anim_player.play("catch_success" if success else "catch_fail")
