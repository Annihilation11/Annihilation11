
extends Node2D

# ============================================================
#  【九宫格灭灯游戏 - 三状态版 (0/1/2)】
#  点击一个格子 → 该格子及上下左右邻居状态 +1（mod 3）
#  目标：全部变为状态 0（熄灭）
#  纯数字显示，无颜色区分
# ============================================================

# ===================== 可修改参数区域 ========================

const GRID_SIZE := 3          # 网格行列数（3 = 九宫格）
const CELL_SIZE := 120        # 每个格子的边长（像素）
const CELL_GAP := 8           # 格子之间的间距（像素）
const GRID_OFFSET_X := 300    # 九宫格左上角 X 坐标（相对于窗口左边）
const GRID_OFFSET_Y := 200    # 九宫格左上角 Y 坐标（相对于窗口上边）

const BG_COLOR := Color(0.08, 0.08, 0.12)        # 背景颜色
const CELL_BG_COLOR := Color(0.15, 0.15, 0.2)    # 格子底色（统一）
const CELL_BORDER_COLOR := Color(1, 1, 1, 0.3)   # 格子边框颜色
const CELL_BORDER_WIDTH := 2.0                    # 格子边框粗细
const NUMBER_COLOR := Color.WHITE                 # 数字颜色
const NUMBER_FONT_SIZE := 48                      # 数字字号

# ===================== 可修改参数结束 ========================

var grid: Array = []  # 二维数组，存储每个格子的状态 (0/1/2)
var is_won := false

func _ready() -> void:
    z_index=100
    _init_grid()
    _shuffle_grid()
    queue_redraw()

# 初始化网格，全部为状态 0
func _init_grid() -> void:
    grid = []
    for row in range(GRID_SIZE):
        var row_arr := []
        for col in range(GRID_SIZE):
            row_arr.append(0)
        grid.append(row_arr)

# 随机打乱（模拟随机点击，保证有解）
func _shuffle_grid() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var click_times := rng.randi_range(10, 30)
    for i in range(click_times):
        var r := rng.randi_range(0, GRID_SIZE - 1)
        var c := rng.randi_range(0, GRID_SIZE - 1)
        _toggle(r, c)
    if _check_win():
        _shuffle_grid()

# 切换指定格子及其邻居的状态 +1 mod 3
func _toggle(row: int, col: int) -> void:
    var directions := [
        Vector2i(0, 0),    # 自身
        Vector2i(-1, 0),   # 上
        Vector2i(1, 0),    # 下
        Vector2i(0, -1),   # 左
        Vector2i(0, 1),    # 右
    ]
    for dir in directions:
        var r : int = row + dir.x
        var c : int = col + dir.y
        if r >= 0 and r < GRID_SIZE and c >= 0 and c < GRID_SIZE:
            grid[r][c] = (grid[r][c] + 1) % 3

# 检查是否全部为 0
func _check_win() -> bool:
    for row in range(GRID_SIZE):
        for col in range(GRID_SIZE):
            if grid[row][col] != 0:
                return false
    return true

# 鼠标点击
func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if is_won:
            is_won = false
            _init_grid()
            _shuffle_grid()
            queue_redraw()
            return

        var mouse_pos: Vector2 = event.position
        var cell_total := CELL_SIZE + CELL_GAP

        for row in range(GRID_SIZE):
            for col in range(GRID_SIZE):
                var x := GRID_OFFSET_X + col * cell_total
                var y := GRID_OFFSET_Y + row * cell_total
                var rect := Rect2(x, y, CELL_SIZE, CELL_SIZE)
                if rect.has_point(mouse_pos):
                    _toggle(row, col)
                    if _check_win():
                        is_won = true
                    queue_redraw()
                    return

# 绘制
func _draw() -> void:
    # 背景
    draw_rect(Rect2(0, 0, get_viewport_rect().size.x, get_viewport_rect().size.y), BG_COLOR)

    var cell_total := CELL_SIZE + CELL_GAP

    for row in range(GRID_SIZE):
        for col in range(GRID_SIZE):
            # ---- 格子位置 ----
            var x := GRID_OFFSET_X + col * cell_total
            var y := GRID_OFFSET_Y + row * cell_total
            var rect := Rect2(x, y, CELL_SIZE, CELL_SIZE)

            # 统一底色
            draw_rect(rect, CELL_BG_COLOR)
            # 边框
            draw_rect(rect, CELL_BORDER_COLOR, false, CELL_BORDER_WIDTH)

            # 纯数字
            var state: int = grid[row][col]
            var label := str(state)
            var text_pos := Vector2(
                x + CELL_SIZE / 2.0 - NUMBER_FONT_SIZE * 0.3,
                y + CELL_SIZE / 2.0 + NUMBER_FONT_SIZE * 0.35
            )
            draw_string(ThemeDB.fallback_font, text_pos, label,
                        HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, NUMBER_COLOR)

    # 胜利提示
    if is_won:
        var total_size := GRID_SIZE * CELL_SIZE + (GRID_SIZE - 1) * CELL_GAP
        var win_pos := Vector2(GRID_OFFSET_X, GRID_OFFSET_Y + total_size + 50)
        draw_string(ThemeDB.fallback_font, win_pos, "通关！点击任意位置重新开始",
                    HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.GREEN)
