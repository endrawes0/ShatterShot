extends Node

const MUSIC_CONFIG_RESOURCE_PATH: String = "res://data/music.tres"
const MENU_THEME_STREAM_PATH: String = "res://assets/music/MainMenuTheme.ogg"
const COMBAT_THEME_STREAM_PATH: String = "res://assets/music/CombatTheme.ogg"
const SHOP_THEME_STREAM_PATH: String = "res://assets/music/ShopTheme.ogg"
const REST_THEME_STREAM_PATH: String = "res://assets/music/RestTheme.ogg"
const MUSIC_MENU: String = "menu"
const MUSIC_COMBAT: String = "combat"
const MUSIC_SHOP: String = "shop"
const MUSIC_REST: String = "rest"
const BOUNCE_BASE_FREQ: float = 200.0
const BOUNCE_FREQ_VARIANCE: float = 20.0
const BOSS_DROP_FREQ_START: float = 60.0
const BOSS_DROP_FREQ_END: float = 20.0
const MUSIC_ATTENUATION: float = 0.5

var _music_players: Dictionary = {}
var _music_should_play: Dictionary = {}
var _music_tweens: Dictionary = {}
var _music_config: MusicConfig = null
var _settings_audio_master: float = 1.0
var _settings_audio_music: float = 1.0
var _settings_audio_sfx: float = 1.0
static var _bounce_stream: AudioStreamWAV = null
static var _boss_drop_stream: AudioStreamWAV = null

func _ready() -> void:
	_ensure_audio_buses()
	_load_music_config()

func set_audio_levels(master: float, music: float, sfx: float) -> void:
	_settings_audio_master = clampf(master, 0.0, 1.0)
	_settings_audio_music = clampf(music, 0.0, 1.0)
	_settings_audio_sfx = clampf(sfx, 0.0, 1.0)
	_apply_audio_settings()

func get_audio_master() -> float:
	return _settings_audio_master

func get_audio_music() -> float:
	return _settings_audio_music

func get_audio_sfx() -> float:
	return _settings_audio_sfx

func start_combat_music() -> void:
	_start_music_with_config(MUSIC_COMBAT)

func stop_combat_music() -> void:
	_stop_music_with_config(MUSIC_COMBAT)

func start_shop_music() -> void:
	_start_music_with_config(MUSIC_SHOP)

func stop_shop_music() -> void:
	_stop_music_with_config(MUSIC_SHOP)

func start_rest_music() -> void:
	_start_music_with_config(MUSIC_REST)

func stop_rest_music() -> void:
	_stop_music_with_config(MUSIC_REST)

func start_menu_music() -> void:
	_start_music_with_config(MUSIC_MENU)

func stop_menu_music() -> void:
	_stop_music_with_config(MUSIC_MENU)

func play_bounce_sfx(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	_ensure_bounce_stream()
	if player.stream == null:
		player.stream = _bounce_stream
	var min_ratio: float = (BOUNCE_BASE_FREQ - BOUNCE_FREQ_VARIANCE) / BOUNCE_BASE_FREQ
	var max_ratio: float = (BOUNCE_BASE_FREQ + BOUNCE_FREQ_VARIANCE) / BOUNCE_BASE_FREQ
	player.pitch_scale = randf_range(min_ratio, max_ratio)
	player.play()

func play_boss_drop_sfx(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	_ensure_boss_drop_stream()
	if player.stream == null:
		player.stream = _boss_drop_stream
	player.play()

func _ensure_audio_buses() -> void:
	_ensure_audio_bus("Music")
	_ensure_audio_bus("SFX")

func _ensure_audio_bus(name: String) -> void:
	var index: int = AudioServer.get_bus_index(name)
	if index != -1:
		return
	AudioServer.add_bus(AudioServer.get_bus_count())
	index = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, name)
	AudioServer.set_bus_send(index, "Master")

func _load_music_config() -> void:
	var loaded := ResourceLoader.load(MUSIC_CONFIG_RESOURCE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded is MusicConfig:
		_music_config = loaded
	else:
		_music_config = _build_default_music_config()

func _build_default_music_config() -> MusicConfig:
	var config := MusicConfig.new()
	config.menu = _build_track_config(MENU_THEME_STREAM_PATH, 1.6, 1.2)
	config.combat = _build_track_config(COMBAT_THEME_STREAM_PATH, 1.0, 2.0)
	config.shop = _build_track_config(SHOP_THEME_STREAM_PATH, 1.0, 2.0)
	config.rest = _build_track_config(REST_THEME_STREAM_PATH, 1.0, 4.0)
	return config

func _build_track_config(path: String, fade_in: float, fade_out: float) -> MusicTrackConfig:
	var track := MusicTrackConfig.new()
	track.stream = _load_audio_stream(path)
	track.fade_in = max(0.0, fade_in)
	track.fade_out = max(0.0, fade_out)
	return track

func _load_audio_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	return loaded as AudioStream

func _start_music_with_config(key: String) -> void:
	_stop_other_music(key)
	var track := _get_music_track(key)
	_start_music(key, track)

func _stop_music_with_config(key: String) -> void:
	var track := _get_music_track(key)
	_stop_music(key, track)

func _all_music_keys() -> Array[String]:
	return [MUSIC_MENU, MUSIC_COMBAT, MUSIC_SHOP, MUSIC_REST]

func _stop_other_music(active_key: String) -> void:
	for key in _all_music_keys():
		if key == active_key:
			continue
		var track := _get_music_track(key)
		_stop_music(key, track)

func _get_music_track(key: String) -> MusicTrackConfig:
	if _music_config == null:
		return null
	match key:
		MUSIC_MENU:
			return _music_config.menu
		MUSIC_COMBAT:
			return _music_config.combat
		MUSIC_SHOP:
			return _music_config.shop
		MUSIC_REST:
			return _music_config.rest
	return null

func _start_music(key: String, track: MusicTrackConfig) -> void:
	_music_should_play[key] = true
	if track == null or track.stream == null:
		return
	var fade_in: float = max(0.0, track.fade_in)
	_ensure_music_player(key, track.stream)
	_fade_in_music(key, fade_in)

func _stop_music(key: String, track: MusicTrackConfig) -> void:
	_music_should_play[key] = false
	if track == null:
		return
	var fade_out: float = max(0.0, track.fade_out)
	_fade_out_music(key, fade_out)

func _ensure_music_player(key: String, stream: AudioStream) -> AudioStreamPlayer:
	var player := _get_music_player(key)
	if player != null:
		if player.stream != stream:
			player.stream = stream
			_configure_stream_loop(player.stream)
		return player
	player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Music"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_stream_loop(player.stream)
	var on_finished := Callable(self, "_on_music_finished").bind(key)
	if not player.finished.is_connected(on_finished):
		player.finished.connect(on_finished)
	add_child(player)
	_music_players[key] = player
	return player

func _configure_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD

func _get_music_player(key: String) -> AudioStreamPlayer:
	if _music_players.has(key):
		var player: AudioStreamPlayer = _music_players.get(key)
		if player != null and is_instance_valid(player):
			return player
		_music_players.erase(key)
	return null

func _on_music_finished(key: String) -> void:
	if not bool(_music_should_play.get(key, false)):
		return
	var player := _get_music_player(key)
	if player and is_instance_valid(player):
		player.play()

func _fade_in_music(key: String, duration: float) -> void:
	var player := _get_music_player(key)
	if player == null:
		return
	_kill_music_tween(key)
	if not player.playing:
		player.volume_db = -80.0
		player.play()
	elif player.volume_db > -40.0:
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_music_tweens[key] = tween

func _fade_out_music(key: String, duration: float) -> void:
	var player := _get_music_player(key)
	if player == null:
		return
	if not player.playing:
		player.stop()
		return
	_kill_music_tween(key)
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -80.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if player and is_instance_valid(player):
			player.stop()
			player.volume_db = 0.0
	)
	_music_tweens[key] = tween

func _kill_music_tween(key: String) -> void:
	var tween: Tween = _music_tweens.get(key)
	if tween and tween.is_running():
		tween.kill()
	_music_tweens.erase(key)

func _apply_audio_settings() -> void:
	_apply_bus_volume("Master", _settings_audio_master)
	_apply_bus_volume("Music", _settings_audio_music * MUSIC_ATTENUATION)
	_apply_bus_volume("SFX", _settings_audio_sfx)

func _apply_bus_volume(name: String, value: float) -> void:
	var index: int = AudioServer.get_bus_index(name)
	if index == -1:
		return
	var db: float = -80.0 if value <= 0.0 else linear_to_db(value)
	AudioServer.set_bus_volume_db(index, db)

func _ensure_bounce_stream() -> void:
	if _bounce_stream != null:
		return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = 22050
	var freq: float = BOUNCE_BASE_FREQ
	var duration: float = 0.1
	var samples: int = int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t: float = float(i) / float(stream.mix_rate)
		var env: float = exp(-18.0 * t)
		var sample: float = sin(TAU * freq * t) * env * 0.5
		var value: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	stream.data = data
	_bounce_stream = stream

func _ensure_boss_drop_stream() -> void:
	if _boss_drop_stream != null:
		return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = 22050
	var duration: float = 0.48
	var samples: int = int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var rumble: float = 0.0
	for i in range(samples):
		var t: float = float(i) / float(stream.mix_rate)
		var env: float = exp(-5.5 * t)
		var lerp_t: float = clamp(t / duration, 0.0, 1.0)
		var freq: float = lerp(BOSS_DROP_FREQ_START, BOSS_DROP_FREQ_END, lerp_t)
		var base: float = sin(TAU * freq * t)
		var sub: float = sin(TAU * freq * 0.5 * t)
		var third: float = sin(TAU * freq * 1.5 * t)
		var high: float = sin(TAU * (freq * 2.5) * t)
		var white: float = randf() * 2.0 - 1.0
		rumble = rumble * 0.985 + white * 0.015
		var noise_env: float = exp(-2.4 * t)
		var noise: float = rumble * noise_env
		var echo_t: float = max(0.0, t - 0.07)
		var echo: float = sin(TAU * freq * echo_t) * 0.25 * exp(-7.0 * echo_t)
		var sample: float = (
			base * 0.7
			+ sub * 0.4
			+ third * 0.25
			+ high * 0.12
			+ noise * 0.45
			+ echo
		) * env
		var value: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	stream.data = data
	_boss_drop_stream = stream
