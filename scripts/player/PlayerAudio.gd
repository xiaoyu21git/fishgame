extends Node
class_name PlayerAudio

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func play(stream: AudioStream):
    if stream:
        audio_player.stream = stream
        audio_player.play()
