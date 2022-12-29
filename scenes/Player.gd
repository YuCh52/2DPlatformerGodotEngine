extends KinematicBody2D

signal died 

var playerDeathScene = preload("res://scenes/PlayerDeath.tscn")

enum state {NORMAL, DASHING}

export(int, LAYERS_2D_PHYSICS) var dashHazardMask

var gravity = 1000 # higher the gravity and jump speed = less floaty jump
var velocity = Vector2.ZERO
var maxHorizontalSpeed = 145
var maxDashSpeed = 500
var minDashSpeed = 250
var horizontalAcceleration = 2000
var jumpSpeed = 325
var jumpTerminatiomMultiplier = 3
var hasDoubleJump = false
var hasDash  = false
var currentState = state.NORMAL
var isStateNew = true
var isDying = false

var defaultHazardMask = 0 


func _ready():
	$HazardArea.connect("area_entered", self, "on_hazard_area_entered")
	defaultHazardMask = $HazardArea.collision_mask
	# Storing the default state of the hazard area 

func _process(delta):
	
	match currentState:
		state.NORMAL:
			process_normal(delta)
		state.DASHING:
			dash(delta)
	isStateNew = false

func change_state(newState):
	currentState = newState
	isStateNew = true # everytime a state is changed the flag is reset to true 
	
func process_normal(delta):
	if(isStateNew):
		$DashArea/CollisionShape2D.disabled = true 
		$HazardArea.collision_mask = defaultHazardMask
	
	var moveVector = get_movement_vector()
	#Total Velocity#
	# Adding a percentage of accceleration every frame
	velocity.x += moveVector.x * horizontalAcceleration * delta
	if (moveVector.x == 0):
		velocity.x = lerp(velocity.x, 0, 0.1) #Decelerate
		velocity.x = lerp(0, velocity.x, pow(2, -50 * delta)) # Slowly slows down to 0
	velocity.x = clamp(velocity.x, -maxHorizontalSpeed, maxHorizontalSpeed)
	# Prevents the character from going over the speed limit 
	
	if (moveVector.y < 0 && (is_on_floor() || !$CoyoteTimer.is_stopped() || hasDoubleJump)):
		velocity.y = moveVector.y * jumpSpeed
		if (!is_on_floor() && $CoyoteTimer.is_stopped()):
			$"/root/Helpers".apply_camera_shake(0.75)
			hasDoubleJump = false # if in midair - double jump in use
		$CoyoteTimer.stop()
	
	if (velocity.y < 0 && !Input.is_action_pressed("jump")):
		velocity.y += gravity * jumpTerminatiomMultiplier * delta
	else:
		velocity.y += gravity * delta
	 # Increasing the Y velocity of the player by gravity amount per sec
	
	var wasOnFloor = is_on_floor()
	velocity = move_and_slide(velocity, Vector2.UP ) 
	# Sets velocity.y = 0 when the cac hits the ground 
	# Everytime move and slide is called it will update the internal state for the kinematic body
	
	if (wasOnFloor && !is_on_floor()):
		$CoyoteTimer.start()
	# As soon as the player leaves the platform timer is going to start
	
	if (is_on_floor()):
		hasDoubleJump = true
		hasDash = true
	
	if ( hasDash && Input.is_action_just_pressed("dash")):
		change_state(state.DASHING)
		call_deferred("change_state", state.DASHING)
		hasDash = false
	
	update_animation()

func dash(delta):
	if(isStateNew):
		$"/root/Helpers".apply_camera_shake(0.75)
		$DashArea/CollisionShape2D.disabled = false
		$AnimatedSprite.play("jump")
		$HazardArea.collision_mask = dashHazardMask
		# When in dash state the mask will be changed 
		var moveVector = get_movement_vector()
		var velocityMod = 1
		if(velocity.x != 0):
			velocityMod = sign(moveVector.x)
			# 1 or-1 depending if the value is negative or positive
		else:
			velocityMod = 1 if $AnimatedSprite.flip_h else -1 
		
		velocity = Vector2(velocityMod * maxDashSpeed, 0)
	
	
	velocity = move_and_slide(velocity, Vector2.UP)
	velocity.x = lerp(0, velocity.x, pow(2, -7 * delta))
	
	if (abs(velocity.x) < minDashSpeed):
		call_deferred("change_state", state.NORMAL)
	# If the velocity is less than minDashSpeed then the state will be chnaged to normal 

func get_movement_vector():
		# calculations on if we are going left or right 
		# moveVector tells us how the inputs look like
	var moveVector = Vector2.ZERO
	moveVector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	# Tells us from a scale 0-1 how the strong the action is (Key is pressed or not)
	# Also tells us which direction this is going in the x-axis
	moveVector.y = -1 if Input.is_action_just_pressed("jump") else 0
	# -1 is because we want to up the y-axis
	return moveVector

func update_animation():
	# Movement animation e.g. Idle, Running and Jumping 
	# Going left and right
	var moveVec = get_movement_vector()
	
	if (!is_on_floor()):
		$AnimatedSprite.play("jump")
	elif (moveVec.x != 0):
		$AnimatedSprite.play("run")
	else:
		$AnimatedSprite.play("idle")
	
	if (moveVec.x != 0):
		$AnimatedSprite.flip_h = true if moveVec.x > 0 else false
	# Going to update the sprite flip if an input is given
 
func kill():
	if(isDying):
		return
	
	isDying = true
	var playerDeathInstance = playerDeathScene.instance()
	playerDeathInstance.velocity = velocity
	get_parent().add_child_below_node(self, playerDeathInstance)
	playerDeathInstance.global_position = global_position
	emit_signal("died")

func on_hazard_area_entered(area2d):
	$"/root/Helpers".apply_camera_shake(1)
	call_deferred("kill")
