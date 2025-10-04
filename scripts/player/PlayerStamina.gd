extends Node
class_name PlayerStamina

# 体力属性
var max_stamina: float = 100
var current_stamina: float = max_stamina
var stamina_recover: float = 20.0
var stamina_cost_run: float = 10.0
var stamina_cost_dash: float = 30.0
var stamina_bar: ProgressBar = null

func _ready():
    stamina_bar = get_parent().get_node_or_null("StaminaBar")

func _process_stamina(delta):
    if current_stamina < max_stamina:
        current_stamina = min(current_stamina + stamina_recover * delta, max_stamina)
        _update_stamina_bar()

func consume(amount: float):
    current_stamina = max(current_stamina - amount, 0)
    _update_stamina_bar()

func _update_stamina_bar():
    if stamina_bar:
        stamina_bar.value = current_stamina
        var ratio = current_stamina / max_stamina
        if ratio > 0.7:
            stamina_bar.modulate = Color(0, 1, 0)
        elif ratio > 0.3:
            stamina_bar.modulate = Color(1, 1, 0)
        else:
            stamina_bar.modulate = Color(1, 0, 0)
