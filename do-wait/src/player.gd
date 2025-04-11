extends CharacterBody2D

@onready var _marker_2d: Marker2D = %Marker2D

const SPEED = 300.0

func _ready() -> void:
	await Do.wait(2)
	print("done")

func _physics_process(_delta: float) -> void:
	
	var direction := Input.get_vector("ui_up", "ui_down", "ui_left", "ui_right")
	if direction:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	look_at(get_global_mouse_position())

	move_and_slide()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept") or (event is InputEventMouseButton and event.is_pressed()):
		Do.do([
			shoot, 
			Do.tree_wait(self, 0.3)
		]).execute(3)


func shoot() -> void:
	var bullet := Bullet.new()
	bullet.avoid = self
	get_tree().root.add_child(bullet)
	bullet.global_transform = _marker_2d.global_transform


class Bullet extends Area2D:
	var collision_shape := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	var speed := 600
	var avoid: Node
	
	func _init() -> void:
		add_child(collision_shape)
		collision_shape.shape = shape
		body_entered.connect(_on_body_entered)

	func _physics_process(delta: float) -> void:
		position += transform.x * speed * delta

	func _on_body_entered(body: Node2D) -> void:
		if body == avoid:
			return
		queue_free()
