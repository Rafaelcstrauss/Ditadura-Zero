extends Label

# Frequência do piscar (em segundos)
var intervalo: float = 0.5
var tempo: float = 0.0
var visivel: bool = true

func _process(delta: float) -> void:
	tempo += delta
	if tempo >= intervalo:
		visivel = !visivel
		self.visible = visivel
		tempo = 0.0
