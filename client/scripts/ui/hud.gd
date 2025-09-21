extends Control


@onready var hunger_bar = $Hunger
@onready var energy_bar = $Energy
@onready var comfort_bar = $Comfort


func set_needs(h,e,c):
        hunger_bar.value = h
        energy_bar.value = e
        comfort_bar.value = c