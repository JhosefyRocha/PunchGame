# Auditoria do GDD — Punch

Data da auditoria: 20/08/2026  
Base analisada: GDD fornecido, cenas, scripts, configurações e artes presentes no projeto Godot 4.6.

## Resumo executivo

O projeto já possui um **vertical slice jogável de plataforma 2D**: Punch anda e pula, escala cipós, sofre dano em espinhos/água, possui três corações, liberta seis animais em duas fases e chega a uma tela de conclusão. O núcleo de resgate e travessia está funcional.

O principal desvio em relação ao GDD é que o jogo ainda não possui o ciclo de combate/arcade: o soco atual é somente animação, está na tecla **J** e não causa dano; não existem inimigos, pontuação, frutas ou demais coletáveis. Narrativa, desafio ecológico e batalha final também não estão representados.

### Diagnóstico por área

| Área | Estado | Observação |
|---|---|---|
| Plataforma e exploração | Implementado | Duas fases lineares, plataformas, rotas elevadas, câmera e transição de fase. |
| Vida e riscos | Implementado | Três corações; espinhos e água removem vida; invulnerabilidade temporária e tela de morte. |
| Resgate | Implementado | Seis gaiolas persistentes no percurso e HUD `RESGATES 0/6`. |
| Cipó | Implementado | W/S para subir/descer e Espaço para soltar. |
| Combate | Parcial | Há animação de soco na tecla J, sem hitbox, dano ou inimigos. |
| Pontuação e coletáveis | Ausente | Não há score, frutas, sementes nem ferramentas. |
| Menu | Parcial | Iniciar, controles, reiniciar e créditos existem; sair e remapeamento real não. |
| Narrativa e chefe | Ausente | Caçadores, desmatamento, pelúcia, caminhonete e batalha final não aparecem. |
| Regeneração da floresta | Parcial | A fase 2 tem arte mais verde, mas a mudança ocorre por troca de fase, não por progresso de resgates. |
| Web/60 FPS | Não comprovado | O projeto usa renderizador compatível, mas não há `export_presets.cfg` nem teste de desempenho web versionado. |

## 1. O que já está implementado

### Alinhado ao GDD

- **Protagonista em plataforma 2D pixel art:** Punch possui animações de idle, caminhada, salto, queda e soco.
- **Movimentação:** A/D e setas movem; W, Espaço ou seta para cima pulam. Isso cobre a intenção de WASD, embora S seja usado somente no cipó.
- **Sistema de três vidas:** `HealthManager` inicia com três vidas e o `HealthHUD` mostra três corações cheios/vazios.
- **Dano ambiental:** espinhos e água chamam `take_damage()`. Depois de um dano não fatal, Punch volta ao início da fase e fica invulnerável por um segundo.
- **Morte e reinício:** ao perder o último coração, aparece a tela “VOCÊ MORREU”, com opção de reiniciar a cena atual.
- **Fases de plataforma lineares:** há duas fases com câmera lateral, plataformas, obstáculos e rotas em alturas diferentes.
- **Cipós:** detecção por `Area2D`, subida/descida com W/S ou setas e soltura com Espaço.
- **Resgate de animais:** há seis gaiolas, três por fase, com IDs únicos e espécies distintas. Junto à gaiola, J abre a gaiola e registra o resgate.
- **HUD de objetivo:** o contador exibe `RESGATES atual/6` e acompanha o `RescueManager` entre as fases.
- **Riscos e desafio de travessia:** água, espinhos, saltos, plataformas elevadas e lacunas estão presentes.
- **Progressão entre fases:** a bandeira finaliza a fase 1, abre a tela de conclusão e conduz à fase 2 com fade.
- **Conclusão do protótipo:** a fase 2 termina em um agrupamento visual dos animais libertados e mostra o total resgatado.
- **Mudança visual macro:** a arte da fase 1 é dessaturada/amarelada e a da fase 2 é mais verde e viva, comunicando parte da recompensa ambiental.
- **Menu sobreposto:** existem Iniciar Jogo, Controles, Reiniciar Jogo e Créditos, além do menu de morte e de conclusão.
- **Base técnica:** projeto em Godot 4.6, renderizador GL Compatibility, pixel filtering e controle de versão Git.

### Elementos que aparecem, mas não cumprem integralmente o GDD

- **Ataque:** existe animação, mas J ativa o ataque e também interage com gaiolas. Não existe `Area2D` de golpe, janela ativa, dano, reação ou inimigo. O GDD exige E.
- **Bandeira:** visualmente pode parecer checkpoint, mas o script `finish_flag.gd` encerra a fase. Não salva/atualiza `respawn_position`.
- **Floresta mais viva:** há uma troca de fundo entre fases. O GDD propõe resposta visual “ao libertar animais e progredir”; atualmente cada resgate não altera o cenário.
- **Configurar teclas:** a tela apenas lista controles fixos. Não permite remapear nem salvar teclas.
- **Morte reinicia a fase:** o reinício existe, mas depende de o jogador apertar um botão na tela de morte; não é automático.
- **Áreas ocultas:** existem rotas elevadas, porém nenhuma área está explicitamente implementada como segredo, com descoberta ou recompensa própria.

## 2. O que está faltando

### Mecânicas centrais

- Ação separada `attack` na tecla **E**.
- Hitbox do soco, janela de dano, direção do golpe e prevenção de múltiplos danos no mesmo ataque.
- Inimigos/lenhadores com vida, patrulha, perseguição, contato ofensivo, dano, morte e feedback visual.
- Sistema de pontuação global e HUD de pontos.
- Pontos por inimigo derrotado, resgate, coletável e desafio concluído.
- Frutas que recuperem vida sem ultrapassar três corações.
- Sementes nativas e ferramentas de resgate, com inventário/contador e propósito no level design.
- Checkpoints reais, caso a bandeira mostrada deva cumprir esse papel.
- Cronômetro ou balanceamento mensurável que sustente ciclos de aproximadamente dois minutos por fase.

### Conteúdo e desafios

- Lenhadores/caçadores presentes nas fases.
- Mini-game ou decisão ecológica, como apagar focos de incêndio.
- Áreas ocultas sinalizadas e recompensadas.
- Batalha final contra o caçador na caminhonete ligada e cheia de gaiolas.
- Estados/ataques do chefe, objetivo ambiental da luta e condição de vitória.

### Narrativa

- Introdução da história de Punch e de sua ligação com a pelúcia de orangotango.
- Apresentação do tráfico de animais e do desmatamento como conflito.
- Desenvolvimento da condição de “herói acidental”.
- Revelação final da pelúcia na caminhonete.
- Diálogos, cutscenes, painéis ou storytelling ambiental que comuniquem esses fatos.
- Referência explícita à ODS 15 dentro da experiência ou da tela final.
- Créditos completos dos cinco integrantes; a tela atual credita apenas Enzo.

### Interface e fluxo

- Botão **Sair** no menu principal (em Web, pode virar “Voltar à página” ou ser ocultado).
- Tela funcional de remapeamento de teclas e persistência em arquivo de configuração.
- HUD de pontuação.
- HUD/feedback para sementes e ferramentas.
- Tutoriais separados para E (atacar) e J (interagir/resgatar), evitando a sobreposição atual.
- Introdução, pausa, tela de chefe e encerramento narrativo.

### Arte, áudio e técnica

- Sprites/animações dos lenhadores, caçador, caminhonete, frutas, sementes, ferramentas e incêndio.
- Feedback de acerto: flash, knockback, partículas, som e pequena pausa de impacto.
- Transição ecológica ligada ao número de resgates, e não apenas à mudança de cena.
- Música, efeitos sonoros e mixagem (não foram encontrados assets/sistemas de áudio).
- Preset de exportação HTML5 versionado e teste em navegador.
- Perfil de desempenho comprovando 60 FPS no alvo mínimo.
- Tela de créditos/licenças completa, incluindo equipe e atribuições dos assets usados.

## 3. Roadmap para cinco pessoas

A divisão abaixo é provisória e pode ser adaptada às competências reais da equipe.

### P0 — Fechar o loop jogável do GDD (3 a 5 dias)

**Meta:** Punch ataca um lenhador, recebe/causa dano, ganha pontos e coleta fruta.

| Responsável | Tarefa | Critério de aceite |
|---|---|---|
| Andrey — gameplay | Separar `attack` (E) de `interact` (J), criar hitbox e integrar ao Player. | Um soco causa exatamente um dano por alvo; o jogador pode virar e atacar nos dois lados. |
| Kenzo — IA | Criar cena do lenhador com patrulha, perseguição, vida, contato e morte. | Inimigo não cai de bordas, persegue dentro do alcance, causa dano respeitando invulnerabilidade e morre. |
| Enzo — sistemas/UI | Criar `ScoreManager`, HUD de score, cura no `HealthManager` e fruta coletável. | Score persiste entre fases, reinicia em nova partida e fruta cura até o máximo de três. |
| Gregório — design | Posicionar inimigos/frutas e rebalancear as duas fases para cerca de 2 minutos. | Playtest médio entre 1:30 e 2:30 sem exigir dano intencional. |
| Jhosefy — arte/QA | Produzir placeholders finais ou sprites, VFX/SFX básicos e matriz de testes. | Todos os estados possuem leitura visual; nenhum bloqueio nas duas fases. |

Decisões obrigatórias no início do P0:

- E = ataque e J = interação/resgate.
- Pontos sugeridos: inimigo 100, resgate 250, fruta 25, desafio ecológico 500.
- Ao zerar vidas: manter tela de morte com confirmação ou reiniciar automaticamente; não misturar os dois comportamentos.
- Definir se bandeira é fim de fase ou checkpoint. Se for checkpoint, criar outro objeto para a saída.

### P1 — Identidade e conteúdo do GDD (5 a 8 dias)

- Gregório: desenhar área oculta e mini-game de incêndio com começo, decisão, falha e recompensa.
- Andrey: implementar sementes/ferramentas, interação ecológica e feedback de conclusão.
- Kenzo: prototipar chefe-caçador/caminhonete com 2–3 padrões telegráficos e condição de vitória.
- Enzo: remapeamento de controles, persistência, telas narrativas, pontuação final e fluxo completo.
- Jhosefy: arte da caminhonete, chefe, pelúcia, fogo, coletáveis e quadros narrativos.

Critério de saída: é possível começar no menu, entender a motivação, jogar as fases, concluir ao menos um desafio ecológico, enfrentar o chefe e ver a revelação da pelúcia.

### P2 — Recompensa ecológica, polimento e entrega Web (3 a 5 dias)

- Fazer o ambiente responder a cada resgate (paleta, vegetação, animais livres e áudio em camadas).
- Adicionar feedback de combate, acessibilidade e clareza dos tutoriais.
- Completar créditos dos cinco integrantes e licenças.
- Criar preset Web, testar teclado/foco/áudio em navegador e medir FPS.
- Fazer playtests, corrigir softlocks, ajustar dificuldade e validar duração.

### Ordem de dependência

`Input separado → hitbox → inimigo → score/fruta → HUD/balanceamento → desafio ecológico → chefe/narrativa → polimento/Web`

## 4. Scripts-base em GDScript (Godot 4.x)

Os exemplos abaixo são bases de integração; os nomes dos nós e camadas precisam coincidir com as cenas. Para não conflitar com as alterações locais atuais, eles não substituem automaticamente `player.gd` ou `project.godot`.

### 4.1 Ataque do Punch com E e dano

No Input Map, crie:

- `attack`: tecla E;
- `interact`: tecla J (e altere `rescue_cage.gd` para usar essa ação).

Na cena do Player, adicione um `Area2D` chamado `AttackHitbox`, com `CollisionShape2D`. Configure sua máscara para detectar somente a camada de inimigos. O nó começa com `monitoring = false`.

Trecho para integrar a `entities/player.gd`:

```gdscript
@export var attack_damage := 1
@export var attack_duration := 0.16
@export var attack_offset := 14.0

@onready var attack_hitbox: Area2D = $AttackHitbox

var attack_targets_hit: Dictionary = {}


func _ready() -> void:
	# Preserve aqui o conteúdo que já existe no _ready atual.
	attack_hitbox.monitoring = false
	attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
	add_to_group(&"player")


func _physics_process(delta: float) -> void:
	# Preserve aqui gravidade, cipó, movimento e animações já existentes.
	if Input.is_action_just_pressed(&"attack") and not is_hitting and not is_dead:
		perform_attack()


func perform_attack() -> void:
	is_hitting = true
	velocity.x = 0.0
	attack_targets_hit.clear()

	var facing_sign := -1.0 if anim.flip_h else 1.0
	attack_hitbox.position.x = absf(attack_offset) * facing_sign
	attack_hitbox.monitoring = true
	anim.play(&"hit")

	await get_tree().create_timer(attack_duration).timeout
	attack_hitbox.monitoring = false
	attack_targets_hit.clear()


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if not is_hitting or attack_targets_hit.has(body):
		return
	if not body.has_method(&"take_damage"):
		return

	attack_targets_hit[body] = true
	body.take_damage(attack_damage, global_position)
```

No final da animação `hit`, mantenha a lógica existente que define `is_hitting = false` e volta para idle/walk/jump. Se a animação for menor do que `attack_duration`, desligue também a hitbox no callback de `animation_finished`.

Alteração da gaiola:

```gdscript
func _process(_delta: float) -> void:
	if player_nearby and not is_opening and Input.is_action_just_pressed(&"interact"):
		free_animal()
```

### 4.2 IA básica do lenhador/inimigo

Estrutura mínima da cena:

```text
Logger (CharacterBody2D, script abaixo)
├── AnimatedSprite2D
├── CollisionShape2D
├── LedgeRay (RayCast2D, apontado para baixo e à frente)
└── ContactArea (Area2D)
    └── CollisionShape2D
```

`entities/logger_enemy.gd`:

```gdscript
extends CharacterBody2D
class_name LoggerEnemy

@export var max_health := 3
@export var patrol_speed := 28.0
@export var chase_speed := 48.0
@export var patrol_distance := 72.0
@export var detection_distance := 100.0
@export var contact_damage := 1
@export var score_reward := 100
@export var knockback_force := 90.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ledge_ray: RayCast2D = $LedgeRay

var health: int
var origin_x: float
var direction := 1.0
var player: Node2D
var is_dead := false


func _ready() -> void:
	health = max_health
	origin_x = global_position.x
	add_to_group(&"enemies")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	player = get_tree().get_first_node_in_group(&"player") as Node2D
	var is_chasing := player != null and global_position.distance_to(player.global_position) <= detection_distance

	if is_chasing:
		direction = signf(player.global_position.x - global_position.x)
		velocity.x = direction * chase_speed
		sprite.play(&"walk")
	else:
		if absf(global_position.x - origin_x) >= patrol_distance:
			direction = -signf(global_position.x - origin_x)
		if is_on_floor() and not ledge_ray.is_colliding():
			direction *= -1.0
		velocity.x = direction * patrol_speed
		sprite.play(&"walk")

	sprite.flip_h = direction < 0.0
	ledge_ray.position.x = absf(ledge_ray.position.x) * direction
	move_and_slide()

	if is_on_wall():
		direction *= -1.0


func take_damage(amount: int, source_position: Vector2) -> void:
	if is_dead:
		return

	health -= amount
	velocity.x = signf(global_position.x - source_position.x) * knockback_force
	sprite.play(&"hurt")

	if health <= 0:
		die()


func die() -> void:
	is_dead = true
	ScoreManager.add_points(score_reward)
	set_collision_layer_value(2, false)
	$ContactArea.monitoring = false
	sprite.play(&"death")
	await sprite.animation_finished
	queue_free()


func _on_contact_area_body_entered(body: Node2D) -> void:
	if is_dead or not body.has_method(&"take_damage"):
		return
	body.take_damage(contact_damage)
```

Observações de integração:

- Ajuste a camada do inimigo para a mesma máscara da `AttackHitbox`.
- Posicione `LedgeRay` alguns pixels à frente; seu `target_position` deve apontar para baixo.
- O `take_damage()` atual do Player não recebe quantidade. Ou remova `contact_damage` da chamada, ou atualize o Player/`HealthManager` para aceitar quantidade.
- Para impedir que o inimigo atravesse o jogador durante perseguição, use colisões físicas coerentes ou pare a velocidade ao entrar no alcance de ataque.

### 4.3 ScoreManager

`systems/score_manager.gd` (autoload `ScoreManager`):

```gdscript
extends Node

signal score_changed(current_score: int)

var current_score := 0


func add_points(amount: int) -> void:
	if amount <= 0:
		return
	current_score += amount
	score_changed.emit(current_score)


func reset_score() -> void:
	current_score = 0
	score_changed.emit(current_score)
```

Adicione em `project.godot` pela interface Project Settings > Globals > Autoload:

```ini
ScoreManager="*res://systems/score_manager.gd"
```

HUD mínimo (`entities/score_hud.gd`, ligado a um `CanvasLayer` com filho `ScoreLabel`):

```gdscript
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel


func _ready() -> void:
	ScoreManager.score_changed.connect(_update_score)
	_update_score(ScoreManager.current_score)


func _update_score(value: int) -> void:
	score_label.text = "PONTOS  %06d" % value
```

Chame `ScoreManager.reset_score()` ao iniciar uma nova partida e ao escolher “Jogar novamente”; não chame na transição normal entre fases.

### 4.4 Cura no HealthManager e fruta coletável

Atualização sugerida para `systems/health_manager.gd`:

```gdscript
func lose_life(amount: int = 1) -> int:
	current_lives = maxi(0, current_lives - maxi(amount, 0))
	lives_changed.emit(current_lives, MAX_LIVES)
	return current_lives


func heal(amount: int = 1) -> int:
	var previous_lives := current_lives
	current_lives = mini(MAX_LIVES, current_lives + maxi(amount, 0))
	if current_lives != previous_lives:
		lives_changed.emit(current_lives, MAX_LIVES)
	return current_lives


func is_full_health() -> bool:
	return current_lives >= MAX_LIVES
```

Cena mínima da fruta: `Area2D` com `Sprite2D`, `CollisionShape2D` e o script a seguir.

`entities/fruit.gd`:

```gdscript
extends Area2D
class_name HealingFruit

@export var heal_amount := 1
@export var score_reward := 25
@export var consume_at_full_health := false

var collected := false


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group(&"player"):
		return
	if HealthManager.is_full_health() and not consume_at_full_health:
		return

	collected = true
	monitoring = false
	HealthManager.heal(heal_amount)
	ScoreManager.add_points(score_reward)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.35, 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	await tween.finished
	queue_free()
```

## 5. Testes de aceite prioritários

1. E ataca; J não ataca e abre uma gaiola quando Punch está próximo.
2. Um inimigo dentro da hitbox perde somente um ponto por soco, mesmo que permaneça sobreposto.
3. O golpe funciona olhando para esquerda e direita.
4. O lenhador patrulha sem cair, persegue somente no alcance e não age depois de morrer.
5. Contato inimigo–Punch remove vida uma vez durante a invulnerabilidade.
6. Fruta cura de 1/3 para 2/3 e nunca produz 4/3.
7. Pontos persistem da fase 1 para a fase 2 e zeram em Nova Partida/Jogar Novamente.
8. Morrer e reiniciar restaura vidas, inimigos e frutas conforme a regra escolhida.
9. Resgates continuam em 0–6 e não são duplicados ao recarregar/transitar.
10. Build Web abre, recebe foco do teclado, mantém 60 FPS no alvo e não apresenta erros no console.

## Conclusão

O protótipo valida bem travessia, risco e resgate, mas ainda não valida o diferencial completo do GDD: combate arcade com propósito ecológico e fechamento narrativo. A melhor próxima entrega é um vertical slice de uma única fase contendo **E para socar, um lenhador completo, score, uma fruta e um resgate**. Só depois disso vale investir no chefe e nas cutscenes, pois esses dependem dos mesmos contratos de dano, pontuação e interação.
