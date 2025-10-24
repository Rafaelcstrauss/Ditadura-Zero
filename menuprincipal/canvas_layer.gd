extends CanvasLayer

@onready var blur_rect: ColorRect = $ColorRect
var _mat: ShaderMaterial

func _ready():
	_mat = blur_rect.material as ShaderMaterial
	blur_rect.visible = false
	_mat.set_shader_parameter("strength", 0.0)
	get_tree().paused = false  # garante que o menu não congele

func play_fade():
	get_tree().paused = false  # sempre despausa quando volta pro menu
	blur_rect.visible = true
	_mat.set_shader_parameter("strength", 1.0)
	var tween := get_tree().create_tween()
	tween.tween_property(_mat, "shader_parameter/strength", 0.0, 1.5)
	tween.tween_callback(Callable(self, "_on_done"))

func _on_done():
	blur_rect.visible = false
