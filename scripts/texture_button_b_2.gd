extends TextureButton

# 按钮放大比例
@export var hover_scale: float = 1.08

# 场景路径配置
@export var current_scene_path: String = "res://scenes/B.tscn"
@export var target_scene_path: String = "res://scenes/C.tscn"
@export var transition_direction: int = 1  # 1=RIGHT, 0=LEFT

var original_scale: Vector2

func _ready() -> void:
    original_scale = scale
    # 确保按钮以自身中心为原点缩放
    pivot_offset = size / 2
    # 确保能接收鼠标事件
    mouse_filter = MOUSE_FILTER_PASS
    # 连接鼠标事件
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    # 连接点击事件
    pressed.connect(_pressed)

func _on_mouse_entered() -> void:
    # 鼠标进入时立即放大
    scale = original_scale * hover_scale

func _on_mouse_exited() -> void:
    # 鼠标离开时立即复原
    scale = original_scale

func _pressed() -> void:
    # 按钮被点击时触发场景切换
    # 使用Engine.get_main_loop()来获取主循环
    var main_loop = Engine.get_main_loop()
    if main_loop and main_loop is SceneTree:
        var tree = main_loop as SceneTree
        tree.change_scene_to_file(target_scene_path)
    else:
        print("错误：无法获取场景树")
