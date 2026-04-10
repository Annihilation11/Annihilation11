extends TextureButton

# 导出变量，允许在编辑器中设置
@export var hover_scale: float = 1.05  # 悬浮时的放大倍数
@export var animation_duration: float = 0.1  # 动画持续时间（秒）
@export var click_sound_path: String = ""  # 点击音效的路径
@export var target_scene_path: String = ""  # 跳转场景的路径

# 缓动动画相关变量
var tween: Tween
var original_scale: Vector2
var original_pivot_offset: Vector2

func _ready():
    # 获取原始缩放
    original_scale = scale
    
    # 设置锚点为中心
    setup_pivot_center()
    
    # 创建并设置Tween
    tween = create_tween()
    tween.kill()  # 初始时停止动画
    
    # 连接信号
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    pressed.connect(_on_button_pressed)
    
    # 连接resized信号以在大小变化时更新锚点
    resized.connect(_on_resized)

func setup_pivot_center():
    # 计算中心点偏移
    var texture = texture_normal
    if texture:
        var texture_size = texture.get_size()
        original_pivot_offset = texture_size / 2
        pivot_offset = original_pivot_offset
    else:
        # 如果没有纹理，使用控件大小的一半
        original_pivot_offset = size / 2
        pivot_offset = original_pivot_offset

func _on_resized():
    # 当按钮大小改变时重新计算中心锚点
    setup_pivot_center()

func _on_mouse_entered():
    # 鼠标进入时放大
    animate_scale(original_scale * hover_scale)

func _on_mouse_exited():
    # 鼠标离开时恢复原始大小
    animate_scale(original_scale)

func _on_button_pressed():
    # 点击时立即恢复原始大小
    animate_scale(original_scale)
    
    # 播放音效
    if click_sound_path != "":
        play_sound(click_sound_path)
    
    # 跳转场景
    if target_scene_path != "":
        # 延迟一小段时间让音效开始播放
        await get_tree().create_timer(0.1).timeout
        change_scene(target_scene_path)

func animate_scale(target_scale: Vector2):
    # 停止当前动画
    if tween and tween.is_running():
        tween.kill()
    
    # 创建新动画
    tween = create_tween()
    tween.tween_property(self, "scale", target_scale, animation_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func play_sound(sound_path: String):
    # 创建AudioStreamPlayer播放音效
    var sound_player = AudioStreamPlayer.new()
    
    # 加载音效资源
    var sound_resource = load(sound_path)
    if sound_resource is AudioStream:
        sound_player.stream = sound_resource
        
        # 添加到场景树
        add_child(sound_player)
        
        # 播放音效
        sound_player.play()
        
        # 播放完成后自动释放
        await sound_player.finished
        sound_player.queue_free()
    else:
        printerr("无效的音效路径: ", sound_path)
        sound_player.queue_free()

func change_scene(scene_path: String):
    # 检查场景文件是否存在
    if ResourceLoader.exists(scene_path):
        # 使用change_scene_to_file进行场景切换（Godot 4推荐方式）
        get_tree().change_scene_to_file(scene_path)
    else:
        printerr("无效的场景路径: ", scene_path)
