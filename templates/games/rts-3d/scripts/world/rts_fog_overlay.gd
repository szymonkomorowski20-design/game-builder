class_name RtsFogOverlay
extends MeshInstance3D
## The player's fog of war over the map (recipe 62): a plane just above the ground whose shader darkens it by the fog
## texture — black where never seen, dim where explored, clear in sight — with linear filtering for soft edges.

const SHADER := "shader_type spatial;\nrender_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;\nuniform sampler2D fog : filter_linear, repeat_disable;\nvoid fragment() {\n\tvec2 px = 1.2 / vec2(textureSize(fog, 0));\n\tfloat v = 0.0;\n\tfor (int y = -1; y <= 1; y++) {\n\t\tfor (int x = -1; x <= 1; x++) {\n\t\t\tv += texture(fog, UV + vec2(float(x), float(y)) * px).r;\n\t\t}\n\t}\n\tv /= 9.0;\n\tALBEDO = vec3(0.0);\n\tALPHA = clamp(0.92 - v * 1.05, 0.0, 0.92);\n}\n"

@export var team := 0
@export var rate := 5.0

var game: RtsGame
var _tex: ImageTexture
var _t := 0.0


func _ready() -> void:
	game = get_parent() as RtsGame
	if not game.is_node_ready():
		await game.ready
	var plane := PlaneMesh.new()
	plane.size = Vector2(72, 72)
	mesh = plane
	position = Vector3(0, 0.04, 0)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	_tex = ImageTexture.create_from_image(game.fog(team).to_image())
	m.set_shader_parameter(&"fog", _tex)
	material_override = m


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = 1.0 / rate
		_tex.update(game.fog(team).to_image())
