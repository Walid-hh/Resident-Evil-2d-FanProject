extends GutTest

var PlayerCameraScript: Script
var CameraStopAreaScript: Script
var CameraBoundsScript: Script
var TestLevelScene: PackedScene
var PlayerScene: PackedScene

var _player: CharacterBody2D
var _camera


class MockCameraTarget:
	extends CharacterBody2D

	var floor_state := true

	func camera_is_on_floor() -> bool:
		return floor_state


func before_each() -> void:
	PlayerCameraScript = load("res://player/camera/player_camera.gd")
	CameraStopAreaScript = load("res://levels/camera_stop_area.gd")
	CameraBoundsScript = load("res://levels/camera_bounds.gd")
	TestLevelScene = load("res://levels/test_level.tscn")
	PlayerScene = load("res://player/player.tscn")
	_player = add_child_autofree(CharacterBody2D.new())
	_player.add_to_group("player")
	_camera = add_child_autofree(PlayerCameraScript.new())
	_camera.target = _player
	_camera.viewport_size = Vector2(320, 180)
	_camera.player_screen_x = 104.0
	_camera.left_edge_margin = 8.0
	_camera.camera_tween_duration = 0.0
	_camera.camera_tween_speed_scale = 1.0
	_camera.lookahead_distance = 0.0
	_camera.configure_bounds(Rect2(-120, -200, 2000, 720))
	_player.global_position = Vector2(40, 130)
	_camera.snap_to_target()
	_camera.make_current()


func test_camera_progress_does_not_move_backward() -> void:
	_player.global_position.x = 220.0
	_camera.physics_update(0.1)
	var advanced_x: float = _camera.get_target_camera_position().x

	_player.global_position.x = 60.0
	_camera.physics_update(0.1)

	assert_eq(_camera.get_target_camera_position().x, advanced_x)


func test_camera_target_snaps_to_pixels() -> void:
	_player.global_position = Vector2(40.25, 300)
	_camera.physics_update(0.1)

	assert_eq(_camera.get_target_camera_position().x, roundf(_camera.get_target_camera_position().x))
	assert_eq(_camera.get_target_camera_position().y, roundf(_camera.get_target_camera_position().y))
	assert_eq(_camera.get_target_camera_position().y, 252.0)


func test_camera_holds_vertical_position_until_grounded() -> void:
	var floor_target: MockCameraTarget = add_child_autofree(MockCameraTarget.new())
	floor_target.global_position = Vector2(40, 130)
	floor_target.floor_state = true
	_camera.target = floor_target

	_camera.snap_to_target()
	var grounded_y: float = _camera.get_target_camera_position().y

	floor_target.global_position.y = 10.0
	floor_target.floor_state = false
	_camera.physics_update(0.1)

	assert_eq(_camera.get_target_camera_position().y, grounded_y)

	floor_target.global_position.y = 200.0
	floor_target.floor_state = true
	_camera.physics_update(0.1)

	assert_eq(_camera.get_target_camera_position().y, 152.0)


func test_camera_uses_tween_easing_for_motion() -> void:
	_camera.camera_tween_duration = 0.5
	_camera.camera_tween_speed_scale = 1.0
	_camera.camera_tween_transition = Tween.TRANS_QUAD
	_camera.camera_tween_ease = Tween.EASE_OUT
	_player.global_position.x = 220.25

	_camera.physics_update(0.25)

	var expected_x := roundf(Tween.interpolate_value(
		96.0,
		180.0,
		0.25,
		0.5,
		Tween.TRANS_QUAD,
		Tween.EASE_OUT
	))

	assert_eq(_camera.get_target_camera_position().x, expected_x)


func test_camera_update_does_not_move_player_left_of_visible_frame() -> void:
	_camera.global_position.x = 100.0
	_player.global_position.x = -100.0
	_player.velocity.x = -40.0

	_camera.physics_update(0.1)

	assert_eq(_player.global_position.x, -100.0)
	assert_eq(_player.velocity.x, -40.0)


func test_level_bounds_clamp_camera_center() -> void:
	_camera.configure_bounds(Rect2(0, 0, 320, 180))
	_player.global_position = Vector2(600, 300)

	_camera.snap_to_target()

	assert_eq(_camera.global_position, Vector2(160, 90))
	assert_eq(_camera.get_target_camera_position(), Vector2(160, 90))


func test_camera_bounds_returns_authored_rect() -> void:
	var bounds_node = add_child_autofree(CameraBoundsScript.new())
	bounds_node.bounds = Rect2(-32, -16, 640, 180)

	assert_eq(bounds_node.get_camera_bounds(), Rect2(-32, -16, 640, 180))


func test_camera_configures_from_level_camera_bounds() -> void:
	var bounds_node = add_child_autofree(CameraBoundsScript.new())
	bounds_node.add_to_group("camera_bounds")
	bounds_node.bounds = Rect2(0, 0, 320, 180)
	_camera.global_position = Vector2(600, 300)
	_camera.target_camera_position = Vector2(600, 300)

	_camera._configure_from_level()

	assert_eq(_camera.camera_bounds, Rect2(0, 0, 320, 180))
	assert_eq(_camera.global_position, Vector2(160, 90))
	assert_eq(_camera.get_target_camera_position(), Vector2(160, 90))


func test_initial_level_bounds_do_not_move_authored_player_spawn() -> void:
	var bounds_node = add_child_autofree(CameraBoundsScript.new())
	bounds_node.add_to_group("camera_bounds")
	bounds_node.bounds = Rect2(-750, -710, 1800, 1000)
	_player.global_position = Vector2(-416, 128)
	_camera.camera_bounds = Rect2(-120, -16, 2000, 180)
	_camera.global_position = Vector2.ZERO
	_camera.target_camera_position = Vector2.ZERO

	_camera._configure_from_level()
	_camera.snap_to_target()

	assert_eq(_player.global_position, Vector2(-416, 128))


func test_test_level_launch_preserves_authored_player_spawn() -> void:
	var level: Node = add_child_autofree(TestLevelScene.instantiate())
	var level_player := level.get_node("Player") as Node2D
	assert_eq(level_player.global_position, Vector2(384, 96))


func test_player_scene_has_camera_boundary_bodies() -> void:
	var player_scene: Node = add_child_autofree(PlayerScene.instantiate())
	var camera := player_scene.get_node("Camera")
	var left_boundary := camera.get_node("CameraLeftBoundary") as StaticBody2D
	var right_boundary := camera.get_node("CameraRightBoundary") as StaticBody2D
	var boundaries := [left_boundary, right_boundary]
	var static_body_count := 0

	for child in camera.get_children():
		if child is StaticBody2D:
			static_body_count += 1

	assert_eq(static_body_count, 2)
	assert_eq(boundaries.size(), 2)
	for boundary: StaticBody2D in boundaries:
		assert_eq(boundary.collision_layer, 2147483648)
		assert_eq(boundary.collision_mask, 2147483648)
		var collision_shape := boundary.get_node("CollisionShape2D") as CollisionShape2D
		assert_not_null(collision_shape)
		assert_true(collision_shape.shape is SegmentShape2D)


func test_camera_stop_blocks_and_releases_forward_progress() -> void:
	_camera.request_camera_stop(160.0)
	_player.global_position.x = 400.0
	_camera.physics_update(0.1)

	assert_lte(_camera.get_target_camera_position().x, 160.0)

	_camera.release_camera_stop(160.0)
	_camera.physics_update(0.1)

	assert_gt(_camera.get_target_camera_position().x, 160.0)


func test_camera_stop_does_not_move_player_outside_visible_frame() -> void:
	_camera.request_camera_stop(160.0)
	_camera.global_position.x = 100.0
	_player.global_position.x = 400.0
	_player.velocity.x = 80.0

	_camera.physics_update(0.1)

	assert_lte(_camera.get_target_camera_position().x, 160.0)
	assert_eq(_player.global_position.x, 400.0)
	assert_eq(_player.velocity.x, 80.0)


func test_camera_stop_area_requests_and_releases_for_player() -> void:
	var stop_area = add_child_autofree(CameraStopAreaScript.new())
	stop_area.stop_camera_x = 160.0
	watch_signals(stop_area)

	stop_area._on_body_entered(_player)

	assert_signal_emitted_with_parameters(stop_area, "camera_stop_requested", [160.0])

	stop_area.release_stop()

	assert_signal_emitted_with_parameters(stop_area, "camera_stop_released", [160.0])
