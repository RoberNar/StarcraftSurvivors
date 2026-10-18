class_name CivilianPlayer
extends CharacterBody2D

signal health_changed(current_hp: float, max_hp: float)
signal critical_hp_reached()
signal moved_first_time()

@export var move_speed: float = 175.0
@export var max_health: float = 80.0
var current_health: float = 80.0

var is_dead: bool = false
var is_invulnerable: bool = false
var can_move: bool = true
var has_moved: bool = false

# Animacion y 32 direcciones clasicas de StarCraft (17 columnas simetricas)
var current_dir32: int = 8
var facing_column: int = 8
var is_facing_left: bool = false
var walk_frame_index: int = 0
var walk_anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
@onready var bubble: Panel = $SpeechBubble
@onready var bubble_label: Label = $SpeechBubble/VBox/TextLabel

var is_suit_equipped: bool = false

func _ready() -> void:
	z_index = 5
	z_as_relative = false
	current_health = max_health
	if bubble:
		bubble.visible = false
	if GameManager.has_suit_equipped:
		set_suit_equipped(true)
	else:
		_load_textures()
		_set_sprite_frame(0)

func _load_textures() -> void:
	var civ_tex = load("res://assets/skins/sd/sprites/civilian.png")
	var shad_tex = load("res://assets/skins/sd/sprites/civilian_shadow.png")
	if civ_tex and sprite:
		sprite.texture = civ_tex
		sprite.hframes = 17
		sprite.vframes = 8
	if shad_tex and shadow:
		shadow.texture = shad_tex
		shadow.hframes = 17
		shadow.vframes = 8
		shadow.position = Vector2(2, -2)

func set_suit_equipped(val: bool) -> void:
	is_suit_equipped = val
	if is_suit_equipped:
		var is_medic = (has_node("/root/GameManager") and GameManager.selected_hero == "medic")
		var s_name = "medic" if is_medic else "marine"
		var tex = load("res://assets/skins/sd/sprites/%s.png" % s_name)
		var shad = load("res://assets/skins/sd/sprites/%s_shadow.png" % s_name)
		if sprite:
			sprite.texture = tex
			sprite.hframes = 17
			sprite.vframes = 14
		if shadow:
			shadow.texture = shad
			shadow.hframes = 17
			shadow.vframes = 14
			shadow.position = Vector2(0, 4)
	else:
		_load_textures()
	_set_sprite_frame(0 * 17 + facing_column)

func _physics_process(delta: float) -> void:
	if not can_move or is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(delta, false)
		return
	
	var input_vec = Vector2.ZERO
	input_vec.x = Input.get_axis("move_left", "move_right")
	input_vec.y = Input.get_axis("move_up", "move_down")
	input_vec = input_vec.normalized()
	
	velocity = input_vec * move_speed
	move_and_slide()
	
	var is_moving = velocity.length() > 5.0
	if is_moving:
		if not has_moved:
			has_moved = true
			emit_signal("moved_first_time")
		_update_direction(velocity.normalized())
	
	_update_animation(delta, is_moving)

func _update_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	var angle_sc = fposmod(dir.angle() + PI * 0.5, TAU)
	current_dir32 = int(round(angle_sc / (TAU / 32.0))) % 32
	if current_dir32 <= 16:
		facing_column = current_dir32
		is_facing_left = false
	else:
		facing_column = 32 - current_dir32
		is_facing_left = true

func _update_animation(delta: float, is_moving: bool) -> void:
	if is_suit_equipped:
		var is_medic = (has_node("/root/GameManager") and GameManager.selected_hero == "medic")
		if is_moving:
			walk_anim_timer += delta * 11.0
			if is_medic:
				var walk_subframe = int(walk_anim_timer) % 7 # 7 filas de caminata de la Médica (filas 6 a 12)
				_set_sprite_frame((6 + walk_subframe) * 17 + facing_column)
			else:
				var walk_subframe = int(walk_anim_timer) % 9 # 9 frames de caminata del Marine (filas 4 a 12)
				_set_sprite_frame((4 + walk_subframe) * 17 + facing_column)
		else:
			walk_anim_timer = 0.0
			_set_sprite_frame(0 * 17 + facing_column)
	else:
		if is_moving:
			walk_anim_timer += delta * 11.0
			var walk_subframe = int(walk_anim_timer) % 7 # 7 frames de caminata (filas 1 a 7)
			_set_sprite_frame((1 + walk_subframe) * 17 + facing_column)
		else:
			walk_anim_timer = 0.0
			_set_sprite_frame(0 * 17 + facing_column)

func _set_sprite_frame(f: int) -> void:
	if sprite:
		sprite.frame = f
		sprite.flip_h = is_facing_left
	if shadow:
		shadow.frame = f
		shadow.flip_h = is_facing_left

func take_damage(amount: float) -> void:
	if is_dead or is_invulnerable:
		return
	
	current_health -= amount
	emit_signal("health_changed", current_health, max_health)
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.06)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)
	
	if current_health <= 18.0 and not is_invulnerable:
		is_invulnerable = true
		current_health = 18.0
		emit_signal("critical_hp_reached")

func show_bubble(text: String, duration: float = 3.0, voice_id: String = "") -> void:
	if not bubble or not bubble_label:
		return
	bubble_label.text = text
	bubble.visible = true
	var voice_dur = 0.0
	if voice_id != "" and has_node("/root/AudioManager"):
		voice_dur = AudioManager.play_voice(voice_id)
		if voice_dur > 0.0:
			duration = max(duration, voice_dur + 0.4)
	var tw = create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(func():
		if is_instance_valid(bubble):
			bubble.visible = false
	)
