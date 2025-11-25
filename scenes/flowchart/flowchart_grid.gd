extends Control


var flowchart: Control


func _ready() -> void:
	flowchart = get_parent().get_parent()
	queue_redraw()


func _draw() -> void:
	self.position = flowchart.position
	self.size = flowchart.size*100

	var zoom: float = flowchart.zoom
	var snap: float = flowchart.snap
	var offset: Vector2 = -Vector2(1, 1)*10000
	var corrected_size: Vector2 = size/zoom
	var from: Vector2 = (offset / snap).floor()
	var l: Vector2 = (corrected_size / snap).floor() + Vector2(1, 1)
	var grid_minor: Color = flowchart.grid_minor_color
	var grid_major: Color = flowchart.grid_major_color

	var multi_line_vector_array: PackedVector2Array = PackedVector2Array()
	var multi_line_color_array: PackedColorArray = PackedColorArray()

	for i in range(from.x, from.x + l.x):
		var color: Color
		if int(abs(i)) % 10 == 0:
			color = grid_major
		else:
			color = grid_minor

		var base_ofs: float = i * snap
		multi_line_vector_array.append(Vector2(base_ofs, offset.y))
		multi_line_vector_array.append(Vector2(base_ofs, corrected_size.y))
		multi_line_color_array.append(color)

	for i in range(from.y, from.y + l.y):
		var color: Color
		if int(abs(i)) % 10 == 0:
			color = grid_major
		else:
			color = grid_minor

		var base_ofs: float = i * snap
		multi_line_vector_array.append(Vector2(offset.x, base_ofs))
		multi_line_vector_array.append(Vector2(corrected_size.x, base_ofs))
		multi_line_color_array.append(color)

	draw_multiline_colors(multi_line_vector_array, multi_line_color_array, -1)