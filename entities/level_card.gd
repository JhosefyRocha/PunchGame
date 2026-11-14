extends Button

const THUMBNAIL_SIZE := Vector2i(62, 30)
const THUMBNAIL_DENSITY := 6
const THUMBNAIL_CROP := 0.5

const COLOR_TITLE := Color(1.0, 0.79, 0.34)
const COLOR_AVAILABLE := Color(1.0, 0.79, 0.34)
const COLOR_COMPLETED := Color(0.62, 0.9, 0.42)
const COLOR_LOCKED := Color(0.6, 0.58, 0.52)

@onready var thumbnail: TextureRect = $Thumbnail
@onready var shade: ColorRect = $Thumbnail/Shade
@onready var lock: Control = $Thumbnail/Lock
@onready var title_label: Label = $Title
@onready var status_label: Label = $Status

var level_index := -1


func setup(index: int) -> void:
	level_index = index
	var level: Dictionary = SaveManager.LEVELS[index]
	title_label.text = String(level["title"]).to_upper()
	thumbnail.texture = make_thumbnail(load(level["thumbnail"]) as Texture2D)
	refresh()


func refresh() -> void:
	var unlocked := SaveManager.is_level_unlocked(level_index)
	disabled = not unlocked
	focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_FORBIDDEN
	shade.visible = not unlocked
	lock.visible = not unlocked

	var status_color := COLOR_LOCKED
	if not unlocked:
		status_label.text = "BLOQUEADA"
	elif SaveManager.is_level_completed(level_index):
		status_label.text = "CONCLUÍDA"
		status_color = COLOR_COMPLETED
	else:
		status_label.text = "DISPONÍVEL"
		status_color = COLOR_AVAILABLE
	status_label.add_theme_color_override(&"font_color", status_color)
	title_label.add_theme_color_override(&"font_color", COLOR_TITLE if unlocked else COLOR_LOCKED)


func make_thumbnail(source: Texture2D) -> Texture2D:
	if source == null:
		return null
	var image := source.get_image()
	if image == null or image.is_empty():
		return source
	if image.is_compressed():
		image.decompress()

	var target := THUMBNAIL_SIZE * THUMBNAIL_DENSITY
	var crop_width := clampi(roundi(image.get_width() * THUMBNAIL_CROP), 1, image.get_width())
	var crop_height := clampi(roundi(crop_width * float(target.y) / float(target.x)), 1, image.get_height())
	var crop := image.get_region(Rect2i(0, 0, crop_width, crop_height))
	crop.resize(target.x, target.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(crop)
