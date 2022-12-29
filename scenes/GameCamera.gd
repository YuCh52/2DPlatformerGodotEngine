extends Camera2D

var targetPosition = Vector2.ZERO
# If the player leaves the seen the camera will navigate to the last known position of the player 

export(Color, RGB) var backgroundColor
export(OpenSimplexNoise) var shakeNoise

var xNoiseSampleVector = Vector2.RIGHT
var yNoiseSampleVector = Vector2.DOWN
var xNoiseSamplePos = Vector2.ZERO
var yNoiseSamplePos = Vector2.ZERO
var noiseSampleTravelRate = 500
var maxShakeOffset = 10
var currentShakePercentage = 0
var shakeDecay = 3.5

func _ready():
	VisualServer.set_default_clear_color(backgroundColor)
	# When the game runs it'll be a sky blue colour as the background


func _process(delta):
	acquire_target_position()
	
	global_position = lerp(targetPosition, global_position, pow(2, -15 * delta)) 
	
	if(currentShakePercentage > 0):
		xNoiseSamplePos += xNoiseSampleVector * noiseSampleTravelRate * delta
		yNoiseSamplePos += yNoiseSampleVector* noiseSampleTravelRate * delta
		var xSample = shakeNoise.get_noise_2d(xNoiseSamplePos.x, xNoiseSamplePos.y)
		var ySample = shakeNoise.get_noise_2d(yNoiseSamplePos.x, yNoiseSamplePos.y)
		
		var calculatedOffset = Vector2(xSample, ySample) * maxShakeOffset * pow(currentShakePercentage, 2) 
		offset = calculatedOffset
		
		currentShakePercentage = clamp(currentShakePercentage - shakeDecay * delta, 0, 1)
		

func apply_shake(percentage): 
	currentShakePercentage = clamp(currentShakePercentage + percentage, 0, 1)
	# Percentage will not go over 100%

func acquire_target_position():
	var acquired = get_target_position_from_node_group("player")
	if(!acquired):
		get_target_position_from_node_group("player_death")

func get_target_position_from_node_group(groupName):
	var nodes = get_tree().get_nodes_in_group(groupName)
	if(nodes.size() > 0):
		var node = nodes[0]
		targetPosition = node.global_position
		return true
	return false
