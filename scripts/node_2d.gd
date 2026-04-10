extends Node2D

# 房间资源路径
const ROOM_PATHS = [
    "res://scenes/A.tscn",
    "res://scenes/B.tscn",
    "res://scenes/C.tscn",
	"res://scenes/D.tscn"
]

# 核心：必须与场景树中的节点名完全一致（注意大小写和末尾的 s）
@onready var room_holder = $RoomHolder 

# 这里的宽度必须改为 1600，匹配你的 SubViewport Size
var view_width: float = 1600.0  
var current_index: int = 0
var is_moving: bool = false
var transition_time: float = 0.4 # 切换动画时间

func _ready():
    # 基础对齐：确保容器本身没有偏移
    self.position = Vector2.ZERO
    room_holder.position = Vector2.ZERO
    
    setup_rooms()

func setup_rooms():
    # 1. 清空编辑器中手动摆放的占位节点
    for child in room_holder.get_children():
        child.queue_free()
    
    # 2. 动态加载 A, B, C, D 并按 1600 像素间隔排列
    for i in range(ROOM_PATHS.size()):
        var room_scene = load(ROOM_PATHS[i])
        if room_scene:
            var inst = room_scene.instantiate()
            room_holder.add_child(inst)
            # 每个房间占据 1600 像素宽度
            inst.position = Vector2(i * view_width, 0)
    
    # 3. 添加循环代理副本实现无缝跳转 [D_copy] [A] [B] [C] [D] [A_copy]
    add_loop_proxies()
    
    # 4. 初始化位置：显示真正的第一个房间 A
    # 因为左边额外加了一个 D 副本，所以容器需要向左偏移 1600 像素
    room_holder.position.x = -view_width

func add_loop_proxies():
    var total_rooms = ROOM_PATHS.size()
    
    # 在右侧末尾添加 A 的副本
    var a_copy = load(ROOM_PATHS[0]).instantiate()
    room_holder.add_child(a_copy)
    a_copy.position = Vector2(total_rooms * view_width, 0)
    
    # 在左侧开头添加 D 的副本
    var d_copy = load(ROOM_PATHS[total_rooms - 1]).instantiate()
    room_holder.add_child(d_copy)
    d_copy.position = Vector2(-view_width, 0)

# 跳转接口 (由主界面的按钮调用)
func navigate(direction: int):
    if is_moving: return
    
    current_index += direction
    animate_to_current()

func animate_to_current():
    is_moving = true
    # 计算目标位置：由于左侧有 D 副本，index 0 对应的 x 是 -1600
    var target_x = -(current_index + 1) * view_width
    
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(room_holder, "position:x", target_x, transition_time)
    
    await tween.finished
    check_loop_reset()
    is_moving = false

func check_loop_reset():
    var total_rooms = ROOM_PATHS.size()
    
    # 如果走到了最后的 A 副本 (index = 4)，瞬间跳回到真正的 A (index = 0)
    if current_index >= total_rooms:
        current_index = 0
        room_holder.position.x = -view_width
    # 如果走到了最前的 D 副本 (index = -1)，瞬间跳回到真正的 D (index = 3)
    elif current_index < 0:
        current_index = total_rooms - 1
        room_holder.position.x = -total_rooms * view_width
