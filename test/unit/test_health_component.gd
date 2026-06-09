extends GutTest


func test_ready_initializes_health_to_max_health() -> void:
	var health_component: HealthComponent = add_child_autofree(HealthComponent.new())

	assert_eq(health_component.health, health_component.max_health)


func test_take_damage_subtracts_positive_damage_and_clamps_to_zero() -> void:
	var health_component: HealthComponent = add_child_autofree(_make_health_component(5))

	health_component.take_damage(7)

	assert_eq(health_component.health, 0)


func test_take_damage_zero_leaves_health_unchanged() -> void:
	var health_component: HealthComponent = add_child_autofree(_make_health_component(5))
	watch_signals(health_component)

	health_component.take_damage(0)

	assert_eq(health_component.health, 5)
	assert_signal_not_emitted(health_component, "health_changed")


func test_take_damage_negative_leaves_health_unchanged() -> void:
	var health_component: HealthComponent = add_child_autofree(_make_health_component(5))
	watch_signals(health_component)

	health_component.take_damage(-3)

	assert_eq(health_component.health, 5)
	assert_signal_not_emitted(health_component, "health_changed")


func test_health_changed_emits_only_when_health_changes() -> void:
	var health_component: HealthComponent = add_child_autofree(_make_health_component(5))
	watch_signals(health_component)

	health_component.take_damage(0)
	health_component.take_damage(2)

	assert_signal_emit_count(health_component, "health_changed", 1)
	assert_signal_emitted_with_parameters(health_component, "health_changed", [3, 5])


func test_died_emits_once_when_health_first_reaches_zero() -> void:
	var health_component: HealthComponent = add_child_autofree(_make_health_component(5))
	var damage_source: HitBox2D = autofree(HitBox2D.new())
	watch_signals(health_component)

	health_component.take_damage(5, damage_source)
	health_component.take_damage(5, damage_source)

	assert_signal_emit_count(health_component, "died", 1)
	assert_signal_emitted_with_parameters(health_component, "died", [damage_source])


func test_hurt_box_adapter_forwards_hit_box_damage() -> void:
	var hurt_box: HurtBox2D = autofree(HurtBox2D.new())
	var hit_box: HitBox2D = autofree(HitBox2D.new())
	hit_box.damage = 2
	var health_component: HealthComponent = _make_health_component(5)
	health_component.hurt_box = hurt_box
	add_child_autofree(health_component)

	hurt_box.took_hit.emit(hit_box)

	assert_eq(health_component.health, 3)


func test_missing_hurt_box_does_not_crash_ready() -> void:
	var health_component: HealthComponent = HealthComponent.new()
	health_component.hurt_box = null

	add_child_autofree(health_component)

	assert_eq(health_component.health, health_component.max_health)


func test_set_max_health_before_and_after_ready_is_safe() -> void:
	var health_component: HealthComponent = HealthComponent.new()
	health_component.set_max_health(10)

	add_child_autofree(health_component)
	health_component.take_damage(4)
	health_component.set_max_health(3)

	assert_eq(health_component.max_health, 3)
	assert_eq(health_component.health, 3)


func _make_health_component(max_health: int) -> HealthComponent:
	var health_component: HealthComponent = HealthComponent.new()
	health_component.max_health = max_health
	return health_component
