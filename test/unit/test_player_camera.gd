extends GutTest

var PlayerCameraScript: Script
var CameraStopAreaScript: Script

var _player: CharacterBody2D
var _camera


func before_each() -> void:
	PlayerCameraScript = load("res://player/camera/player_camera.gd")
	CameraStopAreaScript = load("res://levels/camera_stop_area.gd")
	_player = add_child_autofree(CharacterBody2D.new())
	_player.add_to_group("player")
	_camera = add_child_autofree(PlayerCameraScript.new())
	_camera.target = _player
	_camera.viewport_size = Vector2(320, 180)
	_camera.player_screen_x = 104.0
	_camera.left_edge_margin = 8.0
	_camera.follow_speed = 1000.0
	_camera.lookahead_distance = 0.0
	_camera.configure_bounds(Rect2(-120, -16, 2000, 360))
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


func test_vertical_dead_zone_ignores_small_player_y_changes() -> void:
	var original_y: float = _camera.get_target_camera_position().y
	_player.global_position.y += _camera.vertical_dead_zone * 0.5

	_camera.physics_update(0.1)

	assert_eq(_camera.get_target_camera_position().y, original_y)


func test_level_bounds_clamp_camera_center() -> void:
	_camera.configure_bounds(Rect2(0, 0, 320, 180))
	_player.global_position = Vector2(600, 300)

	_camera.snap_to_target()

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
