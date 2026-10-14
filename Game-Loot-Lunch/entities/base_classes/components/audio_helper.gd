class_name AudioHelper
extends RefCounted

## Configura um AudioStreamWAV para tocar em loop contínuo perfeitamente no Godot 4.
## No Godot 4, configurar apenas loop_mode = LOOP_FORWARD sem definir loop_end faz
## com que o áudio pare instantaneamente na amostra 0.
static func setup_wav_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		var bytes_per_sample: int = 2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1
		var channels: int = 2 if wav.stereo else 1
		if not wav.data.is_empty():
			wav.loop_end = wav.data.size() / (bytes_per_sample * channels)
