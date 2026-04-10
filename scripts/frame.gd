extends Control

const ROOM_FACES = [
    "res://scenes/A.tscn",
    "res://scenes/B.tscn",
    "res://scenes/C.tscn",
    "res://scenes/D.tscn"
]

var current_face_index: int = 0
var current_scene_instance: Node = null
var is_transitioning: bool = false
var current_sub_scene_path: String = ""

@onready var room_holder: Node = $SubViewportContainer/SubViewport/RoomManager/RoomHolder
# 动态获取你刚刚添加的那个 Camera2D
@onready var camera: Camera2D = $SubViewportContainer/SubViewport/Camera2D
@onready var btn_prev: TextureButton = $Left
@onready var btn_next: TextureButton = $Right

var fade_rect: ColorRect
var transition_sfx: AudioStreamPlayer
var original_room_pos: Vector2

func _ready() -> void:
    original_room_pos = room_holder.position
        
    fade_rect = ColorRect.new()
    fade_rect.color = Color(0, 0, 0, 0)
    fade_rect.set_anchors_preset(PRESET_FULL_RECT)
    fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fade_rect.z_index = 101
    add_child(fade_rect)
    
    transition_sfx = AudioStreamPlayer.new()
    transition_sfx.stream = load("res://sounds/mixkit-quick-metal-transition-sweep-2639 (online-audio-converter.com).ogg")
    transition_sfx.volume_db = linear_to_db(0.2)
    add_child(transition_sfx)
    
    btn_prev.pressed.connect(_on_prev_pressed)
    btn_next.pressed.connect(_on_next_pressed)
    
    _setup_button_effects(btn_prev)
    _setup_button_effects(btn_next)
    
    _load_scene_instant(ROOM_FACES[current_face_index])

func _unhandled_input(event: InputEvent) -> void:
    if is_transitioning: return
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_A: _on_prev_pressed()
            KEY_D: _on_next_pressed()
            KEY_S: _on_back_pressed()
            KEY_ESCAPE:
                get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_prev_pressed() -> void:
    if is_transitioning or current_sub_scene_path != "": return
    var next_index = (current_face_index - 1 + ROOM_FACES.size()) % ROOM_FACES.size()
    _transition_to_scene(ROOM_FACES[next_index], "left")
    current_face_index = next_index

func _on_next_pressed() -> void:
    if is_transitioning or current_sub_scene_path != "": return
    var next_index = (current_face_index + 1) % ROOM_FACES.size()
    _transition_to_scene(ROOM_FACES[next_index], "right")
    current_face_index = next_index

func _on_back_pressed() -> void:
    if is_transitioning or current_sub_scene_path == "": return
    current_sub_scene_path = ""
    _transition_to_scene(ROOM_FACES[current_face_index], "zoom_out")

func go_to_sub_scene(scene_path: String) -> void:
    if is_transitioning: return
    current_sub_scene_path = scene_path
    _transition_to_scene(scene_path, "zoom_in")

func _load_scene_instant(scene_path: String) -> void:
    if current_scene_instance:
        current_scene_instance.queue_free()
    var scene_resource = load(scene_path)
    current_scene_instance = scene_resource.instantiate()
    room_holder.add_child(current_scene_instance)

# ----- 核心动画转场逻辑 -----
func _transition_to_scene(target_scene_path: String, trans_type: String) -> void:
    is_transitioning = true
    if transition_sfx.stream != null:
        transition_sfx.play()
        
    var slide_dist = 50.0
    var anim_time = 0.35
    
    var tween_out = create_tween()
    tween_out.set_parallel(true)
    tween_out.tween_property(fade_rect, "color:a", 1.0, anim_time).set_trans(Tween.TRANS_SINE)
    
    # 1. 旧场景退场动画（平移依然改变位置，缩放改为控制摄像机 Zoom）
    match trans_type:
        "right": 
            tween_out.tween_property(room_holder, "position:x", original_room_pos.x - slide_dist, anim_time).set_trans(Tween.TRANS_SINE)
        "left":  
            tween_out.tween_property(room_holder, "position:x", original_room_pos.x + slide_dist, anim_time).set_trans(Tween.TRANS_SINE)
        "zoom_in": # 相机放大10%，画面从中心放大
            tween_out.tween_property(camera, "zoom", Vector2(1.1, 1.1), anim_time).set_trans(Tween.TRANS_SINE)
        "zoom_out": # 相机缩小10%，画面从中心缩小
            tween_out.tween_property(camera, "zoom", Vector2(0.9, 0.9), anim_time).set_trans(Tween.TRANS_SINE)
            
    await tween_out.finished
    
    # 2. 替换场景
    if current_scene_instance:
        current_scene_instance.queue_free()
    var scene_resource = load(target_scene_path)
    current_scene_instance = scene_resource.instantiate()
    room_holder.add_child(current_scene_instance)
    
    # 3. 新场景进场前的初始状态设定
    room_holder.position = original_room_pos
    camera.zoom = Vector2.ONE # 默认缩放重置为 1.0
    
    match trans_type:
        "right": 
            room_holder.position.x = original_room_pos.x + slide_dist
        "left":  
            room_holder.position.x = original_room_pos.x - slide_dist
        "zoom_in": # 新场景一开始保持放大 10%
            camera.zoom = Vector2(1.1, 1.1)
        "zoom_out": # 新场景一开始保持缩小 10%
            camera.zoom = Vector2(0.9, 0.9)
            
    # 4. 新场景进场动画复原
    var tween_in = create_tween()
    tween_in.set_parallel(true)
    tween_in.tween_property(fade_rect, "color:a", 0.0, anim_time).set_trans(Tween.TRANS_SINE)
    
    if trans_type == "right" or trans_type == "left":
        tween_in.tween_property(room_holder, "position:x", original_room_pos.x, anim_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    elif trans_type == "zoom_in" or trans_type == "zoom_out":
        # 相机 Zoom 恢复为标准的 (1.0, 1.0)
        tween_in.tween_property(camera, "zoom", Vector2.ONE, anim_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        
    await tween_in.finished
    is_transitioning = false

func _setup_button_effects(btn: TextureButton) -> void:
    btn.pivot_offset = btn.size / 2.0
    btn.mouse_entered.connect(func():
        var t = create_tween()
        t.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15)
    )
    btn.mouse_exited.connect(func():
        var t = create_tween()
        t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
    )
    btn.button_down.connect(func():
        var t = create_tween()
        t.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.05)
    )
    btn.button_up.connect(func():
        var t = create_tween()
        t.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)
    )
    
