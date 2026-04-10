extends TextureButton

var rotate_sfx: AudioStreamPlayer
var tween: Tween
var is_changing_scene: bool = false # 新增：用于记录是否已经点击了跳转

func _ready() -> void:
    pivot_offset = size / 2.0
    
    rotate_sfx = AudioStreamPlayer.new()
    rotate_sfx.stream = load("res://sounds/mixkit-sci-fi-gear-turn-885 (online-audio-convert.ogg")
    
    # 将线性音量 0.5 (50%) 转换为分贝并赋值（大约是 -6.02 dB）
    rotate_sfx.volume_db = linear_to_db(1.38) 
    
    add_child(rotate_sfx)
    
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
    # 核心修复：如果正在切换场景，直接无视
    if is_changing_scene: return 
    if not is_inside_tree(): return

    if rotate_sfx.stream != null:
        rotate_sfx.play()
    
    if tween and tween.is_valid():
        tween.kill()
    
    tween = create_tween()
    tween.tween_property(self, "rotation_degrees", 180.0, 0.3).set_trans(Tween.TRANS_SINE)

func _on_mouse_exited() -> void:
    # 核心修复：如果正在切换场景，直接无视离开事件，不再播放声音！
    if is_changing_scene: return 
    if not is_inside_tree(): return

    if rotate_sfx.stream != null:
        rotate_sfx.play()
        
    if tween and tween.is_valid():
        tween.kill()
        
    tween = create_tween()
    tween.tween_property(self, "rotation_degrees", 0.0, 0.3).set_trans(Tween.TRANS_SINE)

func _on_pressed() -> void:
    # 一旦按下，标记为正在���换场景，彻底锁死上面的特效触发
    is_changing_scene = true 
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
