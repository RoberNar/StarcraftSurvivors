extends SceneTree
func _init():
	var w = load("res://assets/skins/sd/sprites/weapon_icons.png")
	print("weapon_icons: ", w)
	var t = load("res://assets/skins/sd/sprites/tech_icons_clean.png")
	print("tech_icons_clean: ", t)
	var atlas = AtlasTexture.new()
	atlas.atlas = w
	atlas.region = Rect2(0, 0, 48, 48)
	print("atlas: ", atlas, " size: ", atlas.get_size())
	quit()
