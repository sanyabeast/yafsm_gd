@tool
extends Container


var selected: bool = false:
	set = set_selected


func _init() -> void:
	focus_mode = FOCUS_CLICK
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	pivot_at_line_start()
	var from: Vector2 = Vector2.ZERO
	from.y += size.y / 2.0
	var to: Vector2 = size
	to.y -= size.y / 2.0
	var arrow: Texture2D = get_theme_icon("arrow", "FlowChartLine")
	var tint: Color = Color.WHITE
	if selected:
		tint = get_theme_stylebox("focus", "FlowChartLine").shadow_color
		draw_style_box(get_theme_stylebox("focus", "FlowChartLine"), Rect2(Vector2.ZERO, size))
	else:
		draw_style_box(get_theme_stylebox("normal", "FlowChartLine"), Rect2(Vector2.ZERO, size))
	
	
	draw_texture(arrow, Vector2.ZERO - arrow.get_size() / 2 + size / 2, tint)


func _get_minimum_size() -> Vector2:
	return Vector2(0, 5)


func pivot_at_line_start() -> void:
	pivot_offset.x = 0
	pivot_offset.y = size.y / 2.0


func join(from: Vector2, to: Vector2, offset: Variant = 0.0, clip_rects: Array = []) -> void:
	var perp_dir: Vector2 = from.direction_to(to).rotated(deg_to_rad(90.0)).normalized()
	from -= perp_dir * offset
	to -= perp_dir * offset

	var dist: float = from.distance_to(to)
	var dir: Vector2 = from.direction_to(to)
	var center: Vector2 = from + dir * dist / 2

	var clipped: Array = [[from, to]]
	var line_from: Vector2 = from
	var line_to: Vector2 = to
	for clip_rect in clip_rects:
		if clipped.size() == 0:
			break
		
		line_from = clipped[0][0]
		line_to = clipped[0][1]
		clipped = Geometry2D.clip_polyline_with_polygon(
			[line_from, line_to], 
			[clip_rect.position, Vector2(clip_rect.position.x, clip_rect.end.y), 
				clip_rect.end, Vector2(clip_rect.end.x, clip_rect.position.y)]
		)

	if clipped.size() > 0:
		from = clipped[0][0]
		to = clipped[0][1]
	else:
		from = center
		to = center + dir * 0.1

	
	from -= dir * 2.0
	to += dir * 2.0

	size.x = to.distance_to(from)
	position = from
	position.y -= size.y / 2.0
	rotation = Vector2.RIGHT.angle_to(dir)
	pivot_at_line_start()


func set_selected(v: bool) -> void:
	if selected != v:
		selected = v
		queue_redraw()


func get_from_pos() -> Vector2:
	return get_transform() * (position)


func get_to_pos() -> Vector2:
	return get_transform() * (position + size)
