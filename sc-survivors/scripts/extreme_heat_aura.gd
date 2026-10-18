class_name ExtremeHeatAura
extends Node2D

@onready var cloud_sprite: Sprite2D = $CloudSprite
@onready var cloud_sprite2: Sprite2D = $CloudSprite2

var anim_timer: float = 0.0
var fps: float = 12.0
var is_active: bool = false
var base_scale: Vector2 = Vector2(0.85, 0.85)

func _ready() -> void:
	visible = false
	var tex = SkinManager.get_sprite("extreme_heat_cloud")
	if not tex:
		tex = load("res://assets/skins/sd/sprites/extreme_heat_cloud.png")
	if cloud_sprite and tex:
		cloud_sprite.texture = tex
	if cloud_sprite2 and tex:
		cloud_sprite2.texture = tex

func activate() -> void:
	is_active = true
	visible = true
	anim_timer = 0.0
	modulate.a = 0.0
	scale = base_scale * 0.6
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", base_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func deactivate() -> void:
	is_active = false
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", base_scale * 0.7, 0.3)
	tw.chain().tween_callback(func():
		visible = false
	)

func _process(delta: float) -> void:
	if not visible:
		return
	anim_timer += delta
	var frame_idx = int(anim_timer * fps) % 10
	if cloud_sprite:
		cloud_sprite.frame = frame_idx
		cloud_sprite.rotation += delta * 0.15
	if cloud_sprite2:
		# Layered secondary frame with offset to create dense swirling cloud
		cloud_sprite2.frame = (frame_idx + 4) % 10
		cloud_sprite2.rotation -= delta * 0.12
	
	# Breathing pulse
	var pulse = 1.0 + sin(anim_timer * 5.0) * 0.05
	scale = base_scale * pulse
