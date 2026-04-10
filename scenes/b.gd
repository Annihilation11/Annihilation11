extends Node2D

var grid: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
var buttons: Array[Button] = []
var labels: Array[Label] = [] # 专门用来存显示数字的标签
var is_game_over: bool = false
var click_audio: AudioStreamPlayer

# --- 新增的音效播放器 ---
var win_audio: AudioStreamPlayer
var handle_rotate_audio: AudioStreamPlayer
var handle_click2_audio: AudioStreamPlayer
var tr6_click_audio: AudioStreamPlayer

# --- 新增的节点引用 (请确保你的场景树里有这些名字的节点，路径不对请修改) ---
@onready var handle_rect = $Handle          # 【需要你确认的节点路径】假设你的handle节点叫 "Handle"
@onready var texture_rect_5 = $TextureRect5 # 【需要你确认的节点路径】
@onready var texture_rect_6 = $TextureRect6 # 【需要你确认的节点路径】

const HANDLE_ROTATED_ANGLE: float = 180.0



func _ready():
    randomize()
    
    # --- 动态创建并配置音效播放器 ---
    click_audio = AudioStreamPlayer.new()
    click_audio.stream = preload("res://sounds/futuristic-ui-negative-selection-davies-aguirre-1.ogg")
    click_audio.volume_db = linear_to_db(3.6)
    add_child(click_audio)
    
    # 1. 游戏胜利音效
    win_audio = AudioStreamPlayer.new()
    win_audio.stream = preload("res://sounds/mixkit-sci-fi-futuristic-object-open-2528(online-.ogg") # 【需要你复制的音效路径：胜利音效】
    add_child(win_audio)
    
    # 2. handle旋转音效
    handle_rotate_audio = AudioStreamPlayer.new()
    handle_rotate_audio.stream = preload("res://sounds/mixkit-gear-metallic-lock-sound-2858(online-audio.ogg") # 【需要你复制的音效路径：handle旋转】
    add_child(handle_rotate_audio)
    
    # 3. handle第二次点击音效(显示TR6)
    handle_click2_audio = AudioStreamPlayer.new()
    handle_click2_audio.stream = preload("res://sounds/mixkit-bike-wheel-spinning-1613(online-audio-conv.ogg") # 【需要你复制的音效路径：再次点击handle】
    add_child(handle_click2_audio)
    
    # 4. TR6点击音效(显示TR7)
    tr6_click_audio = AudioStreamPlayer.new()
    tr6_click_audio.stream = preload("res://sounds/mixkit-bike-wheel-spinning-1613(online-audio-conv.ogg") # 【需要你复制的音效路径：点击TR6】
    add_child(tr6_click_audio)

    # 初始化 TextureRect6 和 7 为不可见 (如果是通过透明度隐藏，可改为 modulate.a = 0)
    texture_rect_5.visible = false
    texture_rect_6.visible = false
    
    # 绑定 TextureRect 的点击事件
    handle_rect.gui_input.connect(_on_handle_gui_input)
    texture_rect_5.gui_input.connect(_on_tr6_gui_input)
    
    # 延迟一帧设置 handle 的中心点，保证旋转时绕着中心转
    call_deferred("_set_rect_pivot", handle_rect)
    
    # === 原本的按钮逻辑 ===
    var row_offsets = {
        0: Vector2(15, 4),   
        1: Vector2(4, 4),    
        2: Vector2(4, 4)     
    }
    
    var grid_container = $GridContainer
    for i in range(9):
        var btn = grid_container.get_child(i) as Button
        buttons.append(btn)
        
        btn.text = "" 
        
        var num_label = Label.new()
        btn.add_child(num_label)
        labels.append(num_label)
        
        num_label.set_anchors_preset(Control.PRESET_FULL_RECT)
        num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        num_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        
        num_label.add_theme_color_override("font_color", Color.BLACK)
        num_label.add_theme_font_size_override("font_size", 24)
        
        var row_index = floori(i / 3.0)
        var offset = row_offsets[row_index]
        
        num_label.offset_left += offset.x
        num_label.offset_right += offset.x
        num_label.offset_top += offset.y
        num_label.offset_bottom += offset.y
        
        call_deferred("_set_button_pivot", btn)
        
        var empty_style = StyleBoxEmpty.new()
        btn.add_theme_stylebox_override("focus", empty_style)
        
        btn.pressed.connect(_on_button_pressed.bind(i))
    
    generate_puzzle()
    update_ui()
    
    # --- 还原通关后的持久化状态 ---
    if GlobalState.handle_rotated:
        handle_rect.rotation_degrees = HANDLE_ROTATED_ANGLE
    if GlobalState.tr6_revealed:
        texture_rect_6.visible = true
    if GlobalState.tr7_revealed:
        texture_rect_5.visible = true

func _set_button_pivot(btn: Button):
    btn.pivot_offset = btn.size / 2.0

func _set_rect_pivot(rect: TextureRect):
    rect.pivot_offset = rect.size / 2.0

func generate_puzzle():
    # 将所有格子设为 1 作为固定题目
    for i in range(9):
        grid[i] = 1

func _on_button_pressed(index: int):
    if is_game_over:
        return
        
    var btn = buttons[index]
    click_audio.play()
    
    var tween = create_tween()
    tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.05)
    tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.05)
    
    toggle_lights(index, true)

func toggle_lights(index: int, is_player_action: bool = true):
    increment_cell(index)
    
    var row: int = floori(index / 3.0)
    var col: int = index % 3
    
    if row > 0: increment_cell(index - 3)
    if row < 2: increment_cell(index + 3)
    if col > 0: increment_cell(index - 1)
    if col < 2: increment_cell(index + 1)
    
    if is_player_action:
        update_ui()
        if check_win_condition():
            win_game()

func increment_cell(index: int):
    grid[index] = (grid[index] + 1) % 3

func update_ui():
    for i in range(9):
        labels[i].text = str(grid[i])

func check_win_condition() -> bool:
    for val in grid:
        if val != 0:
            return false
    return true

func win_game():
    if is_game_over: return # 防止重复触发
    is_game_over = true
    print("游戏胜利！")
    
    # 播放胜利音效
    win_audio.play()
    
    for btn in buttons:
        btn.disabled = true

# --- 处理 Handle 图片的点击事件 ---
func _on_handle_gui_input(event: InputEvent):
    # 只有游戏胜利后才能点击
    if not is_game_over: return
    
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if not GlobalState.handle_rotated:
            # 第一次点击：顺时针旋转180度并播放音效
            GlobalState.handle_rotated = true
            handle_rotate_audio.play()
            
            # 使用Tween做平滑旋转 (如果想瞬间旋转，可以直接写 handle_rect.rotation_degrees = 180)
            var tween = create_tween()
            tween.tween_property(handle_rect, "rotation_degrees", HANDLE_ROTATED_ANGLE, 0.3)
            
        elif not GlobalState.tr6_revealed:
            # 旋转过之后再次点击：让TextureRect6可见并播放音效
            GlobalState.tr6_revealed = true
            handle_click2_audio.play()
            texture_rect_6.visible = true
            
            # 【限制音效】从 1.0 秒播放到 2.0 秒
            handle_click2_audio.play(1.0)
            await get_tree().create_timer(1.0).timeout
            handle_click2_audio.stop()
            

# --- 处理 TextureRect6 的点击事件 ---
func _on_tr6_gui_input(event: InputEvent):
    # 必须等 TR6 已经显示出来才能点击
    if not GlobalState.tr6_revealed: return
    
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if not GlobalState.tr7_revealed:
            GlobalState.tr7_revealed = true
            tr6_click_audio.play()
            texture_rect_6.visible = true
            
  # 【限制音效】从 1.0 秒播放到 2.0 秒
            tr6_click_audio.play(1.0)
            await get_tree().create_timer(1.0).timeout
            tr6_click_audio.stop()           
