extends ColorRect

@export var umbral_vida_baja: int = 30
@export var fuerza_pulso: float = 0.30
@export var velocidad_pulso: float = 5.0

var material_efecto: ShaderMaterial
var tiempo_pulso: float = 0.0
var vida_baja: bool = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	crear_shader()

	visible = true


func _process(delta: float) -> void:
	if material_efecto == null:
		return

	if vida_baja:
		tiempo_pulso += delta * velocidad_pulso

		var pulso: float = abs(sin(tiempo_pulso)) * fuerza_pulso

		material_efecto.set_shader_parameter("pulso", pulso)
	else:
		material_efecto.set_shader_parameter("pulso", 0.0)


func crear_shader() -> void:
	material_efecto = ShaderMaterial.new()

	var shader: Shader = Shader.new()

	shader.code = """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float desaturacion = 0.0;
uniform float pulso = 0.0;

void fragment() {
	vec4 pantalla = texture(screen_texture, SCREEN_UV);

	float gris = dot(pantalla.rgb, vec3(0.299, 0.587, 0.114));
	pantalla.rgb = mix(pantalla.rgb, vec3(gris), desaturacion);

	vec2 centro = UV - vec2(0.5);
	float distancia = length(centro);

	float vignette = smoothstep(0.25, 0.75, distancia);

	vec3 color_pulso = vec3(0.75, 0.0, 0.0);
	pantalla.rgb = mix(pantalla.rgb, color_pulso, vignette * pulso);

	COLOR = pantalla;
}
"""

	material_efecto.shader = shader
	material = material_efecto


func actualizar_vida(vida_actual: int, vida_maxima: int) -> void:
	if material_efecto == null:
		return

	if vida_maxima <= 0:
		return

	var porcentaje_vida: float = clampf(float(vida_actual) / float(vida_maxima), 0.0, 1.0)

	var desaturacion: float = 1.0 - porcentaje_vida

	material_efecto.set_shader_parameter("desaturacion", desaturacion)

	if vida_actual <= umbral_vida_baja:
		vida_baja = true
	else:
		vida_baja = false
		tiempo_pulso = 0.0
		material_efecto.set_shader_parameter("pulso", 0.0)


func resetear_efecto() -> void:
	vida_baja = false
	tiempo_pulso = 0.0

	if material_efecto != null:
		material_efecto.set_shader_parameter("desaturacion", 0.0)
		material_efecto.set_shader_parameter("pulso", 0.0)
