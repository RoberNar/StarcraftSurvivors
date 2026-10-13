extends CanvasLayer

signal fade_out_completed
signal fade_in_completed

var color_rect: ColorRect
var current_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

func fade_out(duration: float = 0.4) -> Tween:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	current_tween = create_tween()
	current_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	current_tween.tween_property(color_rect, "color:a", 1.0, duration)
	current_tween.tween_callback(func():
		emit_signal("fade_out_completed")
	)
	return current_tween

func fade_in(duration: float = 0.4) -> Tween:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	current_tween = create_tween()
	current_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	current_tween.tween_property(color_rect, "color:a", 0.0, duration)
	current_tween.tween_callback(func():
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		emit_signal("fade_in_completed")
	)
	return current_tween

func fade_out_in(out_dur: float = 0.35, hold_dur: float = 0.1, in_dur: float = 0.35, midpoint_cb: Callable = Callable()) -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	current_tween = create_tween()
	current_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	current_tween.tween_property(color_rect, "color:a", 1.0, out_dur)
	current_tween.tween_callback(func():
		emit_signal("fade_out_completed")
	)
	if hold_dur > 0.0:
		current_tween.tween_interval(hold_dur)
	if midpoint_cb.is_valid():
		current_tween.tween_callback(midpoint_cb)
	current_tween.tween_property(color_rect, "color:a", 0.0, in_dur)
	current_tween.tween_callback(func():
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		emit_signal("fade_in_completed")
	)

func set_fade_alpha(alpha: float) -> void:
	color_rect.color.a = clampf(alpha, 0.0, 1.0)
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP if alpha > 0.01 else Control.MOUSE_FILTER_IGNORE
