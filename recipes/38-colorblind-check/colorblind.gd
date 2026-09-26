class_name Colorblind
extends RefCounted
## Colour-vision-deficiency simulation (Machado, Oliveira & Fernandes 2009, severity 1.0, applied in linear RGB)
## for two uses: a GUT check that the colours carrying information stay distinguishable, and the matching
## screen shader (colorblind_overlay.gdshader) for screenshots.

enum Mode { DEUTERANOPIA, PROTANOPIA, TRITANOPIA }

const MATRICES := {
	Mode.DEUTERANOPIA: [0.367322, 0.860646, -0.227968, 0.280085, 0.672501, 0.047413, -0.011820, 0.042940, 0.968881],
	Mode.PROTANOPIA: [0.152286, 1.052583, -0.204868, 0.114503, 0.786281, 0.099216, -0.003882, -0.048116, 1.051998],
	Mode.TRITANOPIA: [1.255528, -0.076749, -0.178779, -0.078411, 0.930809, 0.147602, 0.004733, 0.691367, 0.303900],
}


static func simulate(c: Color, mode: int) -> Color:
	var l := c.srgb_to_linear()
	var m: Array = MATRICES[mode]
	var r: float = m[0] * l.r + m[1] * l.g + m[2] * l.b
	var g: float = m[3] * l.r + m[4] * l.g + m[5] * l.b
	var b: float = m[6] * l.r + m[7] * l.g + m[8] * l.b
	return Color(clampf(r, 0.0, 1.0), clampf(g, 0.0, 1.0), clampf(b, 0.0, 1.0), c.a).linear_to_srgb()


## Perceptual-ish distance in sRGB with a luminance weight (0..~1.7). Below ~0.25 colours read as "the same"
## at a glance for small UI elements; use a stricter threshold for tiny icons.
static func distance(a: Color, b: Color) -> float:
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := a.b - b.b
	return sqrt(2.0 * dr * dr + 4.0 * dg * dg + 3.0 * db * db) / 3.0 * 1.7


## For every pair that must be told apart, returns the pairs that are NOT distinguishable in any mode:
## [{"a": Color, "b": Color, "mode": Mode, "distance": float}]
static func problems(pairs: Array, min_distance: float = 0.25) -> Array:
	var out: Array = []
	for pair in pairs:
		for mode in [Mode.DEUTERANOPIA, Mode.PROTANOPIA, Mode.TRITANOPIA]:
			var d := distance(simulate(pair[0], mode), simulate(pair[1], mode))
			if d < min_distance:
				out.append({"a": pair[0], "b": pair[1], "mode": mode, "distance": d})
	return out
