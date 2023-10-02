class_name ZoomCamera
extends Camera2D

# Lower cap for the `_zoom_level`.
@export var min_zoom = 0.2
# Upper cap for the `_zoom_level`.
@export var max_zoom = 10.0
# Controls how much we increase or decrease the `_zoom_level` on every turn of the scroll wheel.
@export var zoom_factor = 0.1
# Duration of the zoom's tween animation.
@export var zoom_duration = 0.2

# The camera's target zoom level.
var _zoom_level = 1.0 : set = _set_zoom_level

var tween

func _ready():
	var vp = get_viewport_rect().size
	offset = vp * 0.5

func _set_zoom_level(value: float):
	if tween:
		tween.kill()
	tween = create_tween()
	# We limit the value between `min_zoom` and `max_zoom`
	_zoom_level = clamp(value, min_zoom, max_zoom)
	# Then, we ask the tween node to animate the camera's `zoom` property from its current value
	# to the target zoom level.
	tween.tween_property(
		self,
		"zoom",
		Vector2(_zoom_level, _zoom_level),
		zoom_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_LEFT:
			position -= event.relative
	if event.is_action_pressed("zoom_in"):
		# Inside a given class, we need to either write `self._zoom_level = ...` or explicitly
		# call the setter function to use it.
		_set_zoom_level(_zoom_level - zoom_factor)
	if event.is_action_pressed("zoom_out"):
		_set_zoom_level(_zoom_level + zoom_factor)
