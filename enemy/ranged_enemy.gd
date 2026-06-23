class_name RangedEnemy extends Enemy

@onready var ranged_attack: EnemyRangedAttackController = %EnemyAttackController
@onready var camera_visibility: EnemyCameraVisibility = %EnemyCameraVisibility
@onready var projectile_spawn: Marker2D = %ProjectileSpawn
