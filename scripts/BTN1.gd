extends TextureButton

# 音效路径
const CLICK_SOUND_PATH: String = "res://sounds/mixkit-quick-metal-transition-sweep-2639 (online-audio-converter.com).ogg"
# 缓存音效资源
var _click_sound: AudioStream = null

func _ready():
    # 预加载音效
    _click_sound = load(CLICK_SOUND_PATH) as AudioStream
    if not _click_sound:
        print("警告：音效文件加载失败，请检查路径！")

# 鼠标进入时放大
func _mouse_entered():
    create_tween().tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

# 鼠标离开时恢复
func _mouse_exited():
    create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

# 向上递归查找 SubViewport 祖先节点
func find_subviewport_ancestor(node: Node) -> SubViewport:
    if not node:
        return null
    if node is SubViewport:
        return node as SubViewport
    return find_subviewport_ancestor(node.get_parent())

# 点击事件
func _pressed():
    # 立即恢复大小
    scale = Vector2(1.0, 1.0)
    
    # 播放音效
    if _click_sound:
        var audio_player = AudioStreamPlayer2D.new()
        audio_player.stream = _click_sound
        get_tree().root.add_child(audio_player)
        audio_player.play()
        audio_player.finished.connect(audio_player.queue_free)
    
    # 查找 SubViewport 并切换场景
    var target_viewport: SubViewport = find_subviewport_ancestor(self)
    if target_viewport:
        target_viewport.go_prev()
    else:
        print("错误：未找到 SubViewport 祖先节点！")
