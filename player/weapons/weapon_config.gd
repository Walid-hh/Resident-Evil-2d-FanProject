class_name WeaponConfig extends Resource

@export var weapon_key: StringName = &"weapon"
@export var projectile_scene: PackedScene
@export var fire_rate: float = 1.0
@export var spread_degrees: float = 0.0
@export var hud_ui_texture: Texture2D
@export var hud_ui_no_focus_texture: Texture2D
@export var unlocked_by_default := false
