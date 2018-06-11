extends TileMap

var hp = 5
var shake = 0
onready var origin = self.position

func _ready():
	Res.game.perma_state(self, "queue_free")

func _process(delta):
	if shake:
		var maxs = shake/4
		position = origin + Vector2(-maxs + randi() % (maxs*2+1), -maxs + randi() % (maxs*2+1))
		shake -= 1
	else:
		position = origin

func hit(hitter):
	if hp > 1:
		Res.play_sample(hitter, "WallHit")
		hp -= 1
		shake = 16
	else:
		Res.game.save_state(self)
		Res.play_sample(hitter, "Bricks")
		var fx = Res.create_instance("Effects/Rubble")
		$"/root/Game".add_child(fx)
		fx.position = hitter.position
		queue_free()