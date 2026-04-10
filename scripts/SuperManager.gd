extends Node

static var instance: SuperManager
@export var transition_time: float = 0.4
var is_transitioning: bool = false

# 环形场景顺序
var scene_order = ["A", "B", "C", "D"]

func _ready():
    if instance == null:
        instance = self
    else:
        queue_free()

# 上一场景逻辑
func goto_prev(current_scene: String):
    if is_transitioning: return
    var idx = scene_order.find(current_scene)
    var prev_idx = (idx - 1 + scene_order.size()) % scene_order.size()
    goto_scene_smooth(scene_order[prev_idx])

# 下一场景逻辑
func goto_next(current_scene: String):
    if is_transitioning: return
    var idx = scene_order.find(current_scene)
    var next_idx = (idx + 1) % scene_order.size()
    goto_scene_smooth(scene_order[next_idx])

# 核心转场（稳定版，无任何属性错误）
func goto_scene_smooth(scene_name: String):
    if is_transitioning:
        return
    is_transitioning = true

    var target_path = "res://scenes/" + scene_name + ".tscn"
    # 精准获取遮罩节点，避免空实例
    var transition_mask = get_node_or_null("/root/GlobalTransition/TransitionMask")
    if not transition_mask:
        # 无遮罩时直接切换，避免报错
        get_tree().change_scene_to_file(target_path)
        reset_camera()
        is_transitioning = false
        return

    # 1. 遮罩淡入（黑屏）
    transition_mask.visible = true
    var tween_fade_in = get_tree().create_tween()
    tween_fade_in.tween_property(transition_mask, "modulate:a", 1.0, transition_time)
    await tween_fade_in.finished

    # 2. 切换场景
    get_tree().change_scene_to_file(target_path)

    # 3. 重置相机（固定960,540居中）
    reset_camera()

    # 4. 遮罩淡出（亮屏）
    var tween_fade_out = get_tree().create_tween()
    tween_fade_out.tween_property(transition_mask, "modulate:a", 0.0, transition_time)
    await tween_fade_out.finished
    transition_mask.visible = false

    is_transitioning = false

# 独立相机重置函数（避免代码冗余，固定960,540）
func reset_camera():
    var current_scene = get_tree().current_scene
    if current_scene:
        var cam = current_scene.get_node_or_null("Camera2D")
        if cam:
            cam.position = Vector2(960, 540)  # 你的固定居中坐标
            cam.make_current()
