extends Camera2D

# 相机在当前场景的初始位置，可在编辑器中调整
@export var start_position: Vector2 = Vector2(960, 540)

func _ready():
    # 场景加载时，立即将相机重置到初始位置
    position = start_position
    # 确保相机是当前视口的活动相机
    make_current()
