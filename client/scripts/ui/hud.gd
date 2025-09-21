extends Control


@onready var hunger_bar = $Hunger
@onready var energy_bar = $Energy
@onready var comfort_bar = $Comfort
@onready var vignette = $Vignette


func set_needs(h,e,c):
	hunger_bar.value = h
	energy_bar.value = e
	comfort_bar.value = c


func faint():
	var tween = create_tween()
	tween.tween_property(vignette, "modulate:a", 1.0, 0.5)
	tween.tween_property(vignette, "modulate:a", 0.0, 2.5).set_delay(0.5)