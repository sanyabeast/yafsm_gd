static func popup_on_target(popup: Popup, target: Control) -> void:
	popup.reset_size()
	var usable_rect: Rect2 = Rect2(Vector2.ZERO, DisplayServer.window_get_size_with_decorations())
	var cp_rect: Rect2 = Rect2(Vector2.ZERO, popup.get_size())
	for i in 4:
		if i > 1:
			cp_rect.position.y = target.global_position.y - cp_rect.size.y
		else:
			cp_rect.position.y = target.global_position.y + target.get_size().y

		if i & 1:
			cp_rect.position.x = target.global_position.x
		else:
			cp_rect.position.x = target.global_position.x - max(0, cp_rect.size.x - target.get_size().x)

		if usable_rect.encloses(cp_rect):
			break
	var main_window_position: Vector2i = DisplayServer.window_get_position()
	var popup_position: Vector2i = main_window_position + Vector2i(cp_rect.position)
	popup.set_position(popup_position)
	popup.popup()


static func get_complementary_color(color: Color) -> Color:
	var r: float = max(color.r, max(color.b, color.g)) + min(color.r, min(color.b, color.g)) - color.r
	var g: float = max(color.r, max(color.b, color.g)) + min(color.r, min(color.b, color.g)) - color.g
	var b: float = max(color.r, max(color.b, color.g)) + min(color.r, min(color.b, color.g)) - color.b
	return Color(r, g, b)


class CohenSutherland:
	const INSIDE: int = 0
	const LEFT: int = 1
	const RIGHT: int = 2
	const BOTTOM: int = 4
	const TOP: int = 8


	static func compute_code(x: float, y: float, x_min: float, y_min: float, x_max: float, y_max: float) -> int:
		var code: int = INSIDE
		if x < x_min:
			code |= LEFT
		elif x > x_max:
			code |= RIGHT
		
		if y < y_min:
			code |= BOTTOM
		elif y > y_max:
			code |= TOP
		
		return code


	static func line_intersect_rectangle(from: Vector2, to: Vector2, rect: Rect2) -> bool:
		var x_min: float = rect.position.x
		var y_min: float = rect.position.y
		var x_max: float = rect.end.x
		var y_max: float = rect.end.y

		var code0: int = compute_code(from.x, from.y, x_min, y_min, x_max, y_max)
		var code1: int = compute_code(to.x, to.y, x_min, y_min, x_max, y_max)

		var i: int = 0
		while true:
			i += 1
			if !(code0 | code1):
				return true
			elif code0 & code1:
				return false
			else:
				var x: float
				var y: float
				var code_out: int = max(code0, code1)

				if code_out & TOP:
					x = from.x + (to.x - from.x) * (y_max - from.y) / (to.y - from.y)
					y = y_max
				elif code_out & BOTTOM:
					x = from.x + (to.x - from.x) * (y_min - from.y) / (to.y - from.y)
					y = y_min
				elif code_out & RIGHT:
					y = from.y + (to.y - from.y) * (x_max - from.x) / (to.x - from.x)
					x = x_max
				elif code_out & LEFT:
					y = from.y + (to.y - from.y) * (x_min - from.x) / (to.x - from.x)
					x = x_min

				if code_out == code0:
					from.x = x
					from.y = y
					code0 = compute_code(from.x, from.y, x_min, y_min, x_max, y_max)
				else:
					to.x = x
					to.y = y
					code1 = compute_code(to.x ,to.y, x_min, y_min, x_max, y_max)
		
		return false
