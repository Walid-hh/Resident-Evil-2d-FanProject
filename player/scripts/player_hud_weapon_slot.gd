extends TextureRect

@onready var weapon_icon: TextureRect = %WeaponIcon
@onready var focus_indicator: TextureRect = %FocusIndicator

var _weapon_config: WeaponConfig
var _is_active := false

var frame_focus_texture := preload("uid://binn02ettnoyj")
var frame_no_focus_texture := preload("uid://dohgkvavumgpc")


func _ready() -> void:
	_apply_weapon_config()
	_apply_active_state()


func setup(weapon_config: WeaponConfig) -> void:
	_weapon_config = weapon_config
	if is_node_ready():
		_apply_weapon_config()
		_apply_active_state()


func set_active(active: bool) -> void:
	_is_active = active
	if is_node_ready():
		_apply_active_state()


func get_weapon_config() -> WeaponConfig:
	return _weapon_config


func _apply_weapon_config() -> void:
	if weapon_icon == null:
		return

	weapon_icon.texture = _get_weapon_icon_texture()


func _apply_active_state() -> void:
	texture = frame_focus_texture if _is_active else frame_no_focus_texture
	if weapon_icon != null:
		weapon_icon.texture = _get_weapon_icon_texture()

	if focus_indicator != null:
		focus_indicator.visible = _is_active


func _get_weapon_icon_texture() -> Texture2D:
	if _weapon_config == null:
		return null
	if _is_active or _weapon_config.hud_ui_no_focus_texture == null:
		return _weapon_config.hud_ui_texture

	return _weapon_config.hud_ui_no_focus_texture
