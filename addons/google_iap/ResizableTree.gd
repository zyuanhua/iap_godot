@tool
extends Tree
class_name ResizableTree

signal column_width_changed(column: int, new_width: int)

var dragging_column: int = -1
var drag_start_x: float = 0.0
var drag_start_width: int = 0
const DRAG_THRESHOLD: int = 6
const MIN_COLUMN_WIDTH: int = 40

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_check_column_drag_start(event.position)
		else:
			if dragging_column >= 0:
				dragging_column = -1
				accept_event()
	elif event is InputEventMouseMotion and dragging_column >= 0:
		var delta: float = event.position.x - drag_start_x
		var new_width: int = maxi(drag_start_width + int(delta), MIN_COLUMN_WIDTH)
		set_column_custom_minimum_width(dragging_column, new_width)
		emit_signal("column_width_changed", dragging_column, new_width)
		accept_event()

func _check_column_drag_start(mouse_pos: Vector2) -> void:
	if not column_titles_visible:
		return
	var title_bar_height: int = _get_title_bar_height()
	if mouse_pos.y > title_bar_height:
		return
	var cumulative_width: int = 0
	for col: int in range(columns):
		var col_width: int = get_column_width(col)
		var right_edge: int = cumulative_width + col_width
		if absf(mouse_pos.x - float(right_edge)) <= float(DRAG_THRESHOLD):
			dragging_column = col
			drag_start_x = mouse_pos.x
			drag_start_width = col_width
			accept_event()
			break
		cumulative_width += col_width

func _get_title_bar_height() -> int:
	var style: StyleBox = get_theme_stylebox("panel")
	var font: Font = get_theme_font("title_font")
	var font_size: int = get_theme_font_size("title_font_size")
	var separation: int = get_theme_constant("vseparation")
	var title_height: int = font.get_height(font_size) if font else 20
	return title_height + separation * 2 + (style.get_minimum_size().y if style else 0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_ENTER or what == NOTIFICATION_WM_MOUSE_EXIT:
		queue_redraw()

func _draw() -> void:
	if not column_titles_visible:
		return
	var mouse_pos: Vector2 = get_local_mouse_position()
	var title_bar_height: int = _get_title_bar_height()
	if mouse_pos.y > title_bar_height:
		return
	var cumulative_width: int = 0
	for col: int in range(columns):
		var col_width: int = get_column_width(col)
		var right_edge: int = cumulative_width + col_width
		if absf(mouse_pos.x - float(right_edge)) <= float(DRAG_THRESHOLD):
			var cursor: Input.CursorShape = Input.CURSOR_HSIZE
			Input.set_default_cursor_shape(cursor)
			return
		cumulative_width += col_width
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func set_column_widths(widths: Array[int]) -> void:
	for i: int in range(min(widths.size(), columns)):
		set_column_custom_minimum_width(i, widths[i])

func get_column_widths() -> Array[int]:
	var widths: Array[int] = []
	for i: int in range(columns):
		widths.append(get_column_width(i))
	return widths
