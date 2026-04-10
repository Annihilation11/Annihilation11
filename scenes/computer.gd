extends TextureRect

func _ready() -> void:
    # 确保 TextureRect 能够拦截并接收鼠标事件
    mouse_filter = Control.MOUSE_FILTER_STOP
    
    # 绑定内置的 gui_input 信号
    # 注意：Godot 4.x 中 connect 推荐这种写法，如果你之前没有报错就保持不变
    if not gui_input.is_connected(_on_gui_input):
        gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
    # 检测是否为鼠标按钮事件
    if event is InputEventMouseButton:
        # 判断是否为鼠标左键，并且是“按下”状态
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            print("TextureRect 被点击了！准备进入 A1 特写...")
            
            # --- 核心修改在这里 ---
            # 获取当前主场景的根节点（也就是挂载了 MainController.gd 的那个节点）
            var main_controller = get_tree().current_scene
            
            # 确保获取到了主节点，并且主节点身上有我们写好的 go_to_sub_scene 方法
            if main_controller and main_controller.has_method("go_to_sub_scene"):
                main_controller.go_to_sub_scene("res://scenes/A1.tscn")
            else:
                push_error("跳转失败：找不到 MainController 节点或 go_to_sub_scene 方法！")
