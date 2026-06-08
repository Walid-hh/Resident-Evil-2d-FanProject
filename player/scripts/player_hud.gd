class_name PlayerHUD extends Control

@export var player: Player

@onready var handgun_canvas: TextureRect = %HandgunCanvas
@onready var handgun_ui: TextureRect = %HandgunUI
@onready var hg_focus_indicator: TextureRect = %HgFocusIndicator
@onready var shotgun_canvas: TextureRect = %ShotgunCanvas
@onready var shotgun_ui: TextureRect = %ShotgunUI
@onready var sg_focus_indicator: TextureRect = %SgFocusIndicator

var gun_texture_focus := preload("uid://binn02ettnoyj")
var gun_texture_no_focus := preload("uid://dohgkvavumgpc")
var handgun_ui_focus := preload("uid://dpnc3tlt85hsg")
var handgun_ui_no_focus := preload("uid://dwuy63ae3hj1w")
var shotgun_ui_focus := preload("uid://c1nircco8xit0")
var shotgun_ui_no_focus := preload("uid://cbgcri1yxkska")


func _ready() -> void:
	if player == null:
		return

	set_unlocked_weapon_visible.call_deferred()


func _physics_process(_delta: float) -> void:
	if player == null:
		return

	var active_config := player.get_active_weapon_config()
	if active_config == null:
		return

	match active_config.weapon_key:
		&"handgun":
			handgun_focus()
		&"shotgun":
			shotgun_focus()


func handgun_focus() -> void:
	set_handgun_focus()
	set_shotgun_no_focus()


func shotgun_focus() -> void:
	set_shotgun_focus()
	set_handgun_no_focus()


func set_handgun_focus() -> void:
	handgun_canvas.texture = gun_texture_focus
	handgun_ui.texture = handgun_ui_focus
	hg_focus_indicator.visible = true


func set_handgun_no_focus() -> void:
	handgun_canvas.texture = gun_texture_no_focus
	handgun_ui.texture = handgun_ui_no_focus
	hg_focus_indicator.visible = false


func set_shotgun_focus() -> void:
	shotgun_canvas.texture = gun_texture_focus
	shotgun_ui.texture = shotgun_ui_focus
	sg_focus_indicator.visible = true


func set_shotgun_no_focus() -> void:
	shotgun_canvas.texture = gun_texture_no_focus
	shotgun_ui.texture = shotgun_ui_no_focus
	sg_focus_indicator.visible = false


func set_unlocked_weapon_visible() -> void:
	if player == null:
		return

	for weapon_config: WeaponConfig in player.get_unlocked_weapon_configs():
		if weapon_config == null:
			continue

		if weapon_config.weapon_key == &"handgun":
			handgun_canvas.visible = true
			handgun_ui.texture = weapon_config.hud_ui_texture
		if weapon_config.weapon_key == &"shotgun":
			shotgun_canvas.visible = true
			shotgun_ui.texture = weapon_config.hud_ui_texture
