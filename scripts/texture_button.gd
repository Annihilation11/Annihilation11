extends TextureButton

@export var rotate_speed: float = 2.0
var hover_state: bool = false

func _ready():
    # 自动将轴心点设置为按钮中心
    pivot_offset = Vector2(size.x / 2, size.y / 2)
    
    # 连接鼠标进入/离开信号
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

func _process(delta):
    if is_hovered:
        rotation += delta * rotate_speed

func _on_mouse_entered():
    hover_state = true

func _on_mouse_exited():
    hover_state = false
