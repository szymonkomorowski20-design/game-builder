class_name Hud
extends CanvasLayer
## HUD that only listens: bound to a Health (recipe 05) and a Wallet (recipe 11) through signals.
## Gameplay never touches HUD nodes — swapping the HUD design never breaks gameplay.

@export var health: Health

@onready var hp_bar: ProgressBar = $HpBar
@onready var coins_label: Label = $CoinsLabel

var _wallet: Wallet


func _ready() -> void:
	if health != null:
		hp_bar.max_value = health.max_health
		hp_bar.value = health.current
		health.damaged.connect(func(_a: int, remaining: int): hp_bar.value = remaining)
		health.healed.connect(func(_a: int, remaining: int): hp_bar.value = remaining)


func bind_wallet(w: Wallet) -> void:
	_wallet = w
	w.balance_changed.connect(_on_balance)
	_on_balance(w.balance)


func _on_balance(balance: int) -> void:
	var fmt := tr("HUD_COINS")
	if fmt == "HUD_COINS":   # no translation registered (recipe 22 not set up) — readable fallback
		fmt = "Coins: {n}"
	coins_label.text = fmt.format({"n": balance})
