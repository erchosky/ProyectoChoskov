class_name GameSound
extends Node
var voices: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var cursor = 0
var enabled = true

func _ready() -> void:
	for i in 8:
		var voice = AudioStreamPlayer.new()
		voice.volume_db = -14
		add_child(voice)
		voices.append(voice)
	for id in ["shot", "rifle", "hit", "loot", "reload", "extract", "heal", "shotgun", "step", "dodge"]:
		streams[id] = load("res://assets/" + id + ".wav")

func play(id: String, volume: float = 1.0, pitch: float = 1.0) -> void:
	if not enabled or not streams.has(id):
		return
	var voice = voices[cursor]
	cursor = (cursor + 1) % voices.size()
	voice.volume_db = -14+linear_to_db(maxf(.01,volume))
	voice.pitch_scale = pitch
	voice.stream = streams[id]
	voice.play()

func _exit_tree() -> void:
	# Release audio playback before the scene and cached streams leave the tree.
	for voice in voices:
		voice.stop()
		voice.stream = null
	streams.clear()
