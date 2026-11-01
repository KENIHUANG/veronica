extends SceneTree
## 导出全部挂画(calm / creepy)到一张对照图:SHOT_DIR/pictures.png
const Draw = preload("res://scripts/draw.gd")
func _initialize() -> void:
	var kinds := ["portrait", "nun", "ad", "landscape", "certificate", "family"]
	var sheet := Image.create(128 * 6 * 2, 160 * 2 * 2, false, Image.FORMAT_RGB8)
	for i in kinds.size():
		for c in 2:
			var img: Image = Draw.picture(kinds[i], c == 1).get_image()
			img.convert(Image.FORMAT_RGB8)
			img.resize(256, 320, Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(img, Rect2i(0, 0, 256, 320), Vector2i(i * 256, c * 320))
	var d := OS.get_environment("SHOT_DIR")
	sheet.save_png((d if d != "" else ".") + "/pictures.png")
	print("saved pictures")
	quit()
