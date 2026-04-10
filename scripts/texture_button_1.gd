extends TextureButton

# 直接使用你项目里的音效路径
const CLICK_SOUND_PATH: String = "res://sounds/mixkit-modern-technology-select-3124.wav"
var _click_sound: AudioStream = null
var _audio_player: AudioStreamPlayer2D = null

func _ready():
    # 预加载音效
    _click_sound = load(CLICK_SOUND_PATH) as AudioStream
    if not _click_sound:
        push_error("音效加载失败，请检查路径：" + CLICK_SOUND_PATH)

    _audio_player = AudioStreamPlayer2D.new()
    _audio_player.name = "BtnPrevSound"
    add_child(_audio_player)
    
    # 自动置顶到第100层
    z_index = 100

func _mouse_entered():
    create_tween().tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _mouse_exited():
    create_tween().tween_property(self, "scale", Vector2.ONE, 0.1)

func _pressed():
    scale = Vector2.ONE

    if _click_sound and _audio_player and not _audio_player.is_playing():
        _audio_player.stream = _click_sound
        _audio_player.play()

    var target_sv: SubViewport = get_parent() as SubViewport
    if target_sv:
        target_sv.go_prev()
    else:
        push_error("错误：按钮的父节点不是 SubViewport！")

func _exit_tree():
    if _audio_player:
        _audio_player.queue_free()
        _audio_player = null
