extends AudioStreamPlayer

## Trilha da fase. Comeca muda e, no fim do primeiro frame, se alinha ao estado
## de pausa da arvore -- o menu de abertura pausa o jogo, entao a musica so
## entra quando a partida comeca. Dai em diante as notificacoes de pausa do
## proprio AudioStreamPlayer cuidam das trocas.

func _ready() -> void:
	play()
	stream_paused = true
	_sync_with_pause_state.call_deferred()


func _sync_with_pause_state() -> void:
	stream_paused = get_tree().paused
