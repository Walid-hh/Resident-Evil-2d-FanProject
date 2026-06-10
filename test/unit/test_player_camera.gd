extends GutTest

var PlayerCameraScript: Script
var CameraStopAreaScript: Script
var CameraBoundsScript: Script

var _player: CharacterBody2D
var _camera


func before_each() -> void:
	PlayerCameraScript = load("res://player/camera/player_camera.gd")
	CameraStopAreaScript = load("res://levels/camera_stop_area.gd")
	CameraBoundsScript = load("res://levels/camera_bounds.gd")
	_player = add_child_autofree(CharacterBody2D.new())
	_player.add_to_group("player")
	_camera = add_child_autofree(PlayerCameraScript.new())
	_camera.target = _player
	_camera.viewport_size = Vector2(320, 180)
	_camera.player_screen_x = 104.0
	_camera.left_edge_margin = 8.0
	_camera.follow_speed = 1000.0
	_camera.vertical_follow_speed = 4.0
	_camera.lookahead_distance = 0.0
	_camera.configure_bounds(Rect2(-120, -200, 2000, 720))
	_player.set_meta("camera_is_on_floor", true)
	_player.global_position = Vector2(40, 130)
	_camera.snap_to_target()


func test_camera_progress_does_not_move_backward() -> void:
	_player.global_position.x = 220.0
	_camera.physics_update(0.1)
	var advanced_x: float = _camera.get_target_camera_position().x

	_player.global_position.x = 60.0
	_camera.physics_update(0.1)

	assert_eq(_camera.get_target_camera_position().x, advanced_x)


func test_left_edge_constraint_keeps_player_in_view() -> void:
	_camera.global_position.x = 100.0
	_player.global_position.x = -100.0

	_camera.physics_update(0.1)

	assert_eq(_player.global_position.x, _camera.get_screen_left() + _camera.left_edge_margin)
	assert_eq(_player.velocity.x, 0.0)


func test_grounded_player_eases_camera_toward_vertical_offset() -> void:
	_player.set_meta("camera_is_on_floor", true)
	_player.global_position.y = 300.0

	_camera.physics_update(0.1)

	assert_eq(_camera.get_target_camera_position().y, 252.0)
	assert_gt(_camera.global_position.y, 132.0)
	assert_lt(_camera.global_position.y, 252.0)

	var first_step_y := _camera.global_position.y
	_camera.physics_update(0.1)

	assert_gt(_camera.global_position.y, first_step_y)
	assert_lt(_camera.global_position.y, 252.0)


func test_vertical_lerp_ease_weight_changes_the_response_curve() -> void:
	_player.set_meta("camera_is_on_floor", true)
	_player.global_position.y = 300.0
	_camera.vertical_follow_speed = 5.0
	_camera.global_position.y = 132.0
	_camera.target_camera_position.y = 132.0
	_camera.vertical_follow_ease_weight = 0.0

	_camera.physics_update(0.1)
	var linear_y := _camera.global_position.y

	_camera.global_position.y = 132.0
	_camera.target_camera_position.y = 132.0
	_camera.vertical_follow_ease_weight = 1.0
	_camera.physics_update(0.1)
	var eased_y := _camera.global_position.y

	assert_gt(linear_y, eased_y)


func test_camera_holds_vertical_target_while_airborne_then_resumes_on_landing() -> void:
	_player.global_position.y = 300.0
	_player.set_meta("camera_is_on_floor", true)

	_camera.physics_update(0.1)

	var grounded_y := _camera.global_position.y
	assert_gt(grounded_y, 132.0)
	assert_lt(grounded_y, 252.0)

	_player.set_meta("camera_is_on_floor", false)
	_player.global_position.y = 70.0

	_camera.physics_update(0.1)

	assert_eq(_camera.get_target_camera_position().y, 252.0)
	assert_eq(_camera.global_position.y, grounded_y)

	_player.global_position.y = 100.0
	_player.set_meta("camera_is_on_floor", true)
	_camera.physics_update(0.1)

	assert_eq(_camera.get_target_camera_position().y, 52.0)
	assert_lt(_camera.global_position.y, grounded_y)
	assert_gt(_camera.global_position.y, 52.0)


func test_level_bounds_clamp_camera_center() -> void:
	_camera.configure_bounds(Rect2(0, 0, 320, 180))
	_player.global_position = Vector2(600, 300)

	_camera.snap_to_target()

	assert_eq(_camera.global_position, Vector2(160, 90))


func test_camera_bounds_returns_authored_rect() -> void:
	var bounds_node = add_child_autofree(CameraBoundsScript.new())
	bounds_node.bounds = Rect2(-32, -16, 640, 180)

	assert_eq(bounds_node.get_camera_bounds(), Rect2(-32, -16, 640, 180))


func test_camera_configures_from_level_camera_bounds() -> void:
	var bounds_node = add_child_autofree(CameraBoundsScript.new())
	bounds_node.bounds = Rect2(0, 0, 320, 180)
	_camera.global_position = Vector2(600, 300)
	_camera.target_camera_position = Vector2(600, 300)

	_camera._configure_from_level()

	assert_eq(_camera.camera_bounds, Rect2(0, 0, 320, 180))
	assert_eq(_camera.global_position, Vector2(160, 90))


func test_camera_stop_blocks_and_releases_forward_progress() -> void:
	_camera.request_camera_stop(160.0)
	_player.global_position.x = 400.0
	_camera.physics_update(0.1)

	assert_lte(_camera.get_target_camera_position().x, 160.0)

	_camera.release_camera_stop(160.0)
	_camera.physics_update(0.1)

	assert_gt(_camera.get_target_camera_position().x, 160.0)


func test_camera_stop_pins_player_to_both_edges_of_the_frame() -> void:
	_camera.request_camera_stop(160.0)
	_camera.global_position.x = 100.0
	_player.global_position.x = 400.0

	_camera.physics_update(0.1)

	assert_eq(_player.global_position.x, _camera.get_screen_right() - _camera.right_edge_margin)
	assert_eq(_player.velocity.x, 0.0)


func test_camera_stop_area_requests_and_releases_for_player() -> void:
	var stop_area = add_child_autofree(CameraStopAreaScript.new())
	stop_area.stop_camera_x = 160.0
	watch_signals(stop_area)

	stop_area._on_body_entered(_player)

	assert_signal_emitted_with_parameters(stop_area, "camera_stop_requested", [160.0])

	stop_area.release_stop()

	assert_signal_emitted_with_parameters(stop_area, "camera_stop_released", [160.0])
