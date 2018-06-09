extends TileMap

var hp = 5

func hit(hitter):
	##efekty
	if hp > 0:
		Res.play_sample(hitter, "WallHit")
		hp -= 1
	else:
		Res.play_sample(hitter, "Bricks")
		queue_free()