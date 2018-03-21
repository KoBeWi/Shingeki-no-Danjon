extends KinematicBody2D

const SPEED = 320
const MEDITATION_TIME = 3
const SKILL_TIMEOUT = 3

onready var UI = $Camera/UI
onready var fireball = load("res://Nodes/Projectiles/Fireball.tscn")
var texture_cache = {}

var direction = 3
var static_time = 0
var skill_time = 0

var attacking = false

func _ready():
	SkillBase.connect("new_skill", self, "new_skill")
	UI.get_node("HealthIndicator").max_value = PlayerStats.max_health
	UI.get_node("HealthIndicator").value = PlayerStats.health
	UI.get_node("ManaIndicator").max_value = PlayerStats.max_mana
	UI.get_node("ManaIndicator").value = PlayerStats.mana
	
	for anim in ["Body", "SwordAttack", "ShieldOn", "ShieldOff"]:
		for dir in ["Back", "Right", "Front", "Left"]:
			var texname = "res://Sprites/Player/" + dir + "/" + anim + ".png"
			texture_cache[texname] = load(texname)

func _physics_process(delta):
	var move = Vector2()
	
	static_time += delta
	if static_time >= MEDITATION_TIME: SkillBase.inc_stat("Meditation")
	
	if skill_time > 0:
		skill_time -= delta
		UI.get_node("SkillAcquiredPanel").modulate.a = clamp(skill_time / (SKILL_TIMEOUT-1), 0, 1)
		
		if skill_time <= 0:
			UI.get_node("SkillAcquiredPanel").visible = false
	
	if Input.is_key_pressed(KEY_UP):
		move.y = -1
		change_dir(0)
	if Input.is_key_pressed(KEY_DOWN):
		move.y = 1
		change_dir(2)
	if Input.is_key_pressed(KEY_LEFT):
		move.x = -1
		change_dir(3)
	if Input.is_key_pressed(KEY_RIGHT):
		move.x = 1
		change_dir(1)
	
	move = move.normalized() * SPEED
	
	if !attacking and Input.is_action_just_pressed("Attack"):
		Res.play_sample($Audio, "Sword")
		$Animation.play("SwordAttackRight")
		attacking = true
	
	if PlayerStats.mana > 10 and Input.is_action_just_pressed("Spell"):
		Res.play_sample($Audio, "Fireball")
		SkillBase.inc_stat("OffensiveMagic")
		var newf = fireball.instance()
		get_parent().add_child(newf)
		newf.position = position
		newf.direction = direction
		PlayerStats.mana -= 10
	
	if randi()%10 == 0: PlayerStats.mana += 1
	UI.get_node("ManaIndicator").value = PlayerStats.mana
	
	if SkillBase.has_skill("FastWalk") and Input.is_key_pressed(KEY_SHIFT): move *= 3
	SkillBase.inc_stat("PixelsTravelled", int(move.length()))
	
	if move != Vector2(): static_time = 0
	move_and_slide(move)

func damage(attacker, amount, knockback):
	Res.create_instance("DamageNumber").damage(self, amount)
	SkillBase.inc_stat("DamageTaken", amount)
	PlayerStats.health -= amount
	UI.get_node("HealthIndicator").value = PlayerStats.health
	move_and_slide((position - attacker.position).normalized() * 1000 * knockback)

func _on_animation_finished(anim_name):
	if anim_name == "SwordAttackRight":
		attacking = false

func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("enemies"):
		SkillBase.inc_stat("OneHanded")
		SkillBase.inc_stat("Melee")
		collider.get_parent().damage(10)

func new_skill(skill):
	Res.play_sample($Audio, "SkillAcquired")
	UI.get_node("SkillAcquiredPanel").visible = true
	UI.get_node("SkillAcquiredPanel/Name").text = skill
	skill_time = SKILL_TIMEOUT

func change_dir(dir):
	direction = dir
	var d = ["Back", "Right", "Front", "Left"][dir]
	change_texture($Body, d, "Body")
	change_texture($Body/RightArm, d, "SwordAttack", ["Left", "Back"])
	change_texture($Body/LeftArm, d, "ShieldOn", ["Right", "Back"])

func change_texture(sprite, direction, texture, on_back = []):
	sprite.texture = texture_cache["res://Sprites/Player/" + direction + "/" + texture + ".png"]
	sprite.show_behind_parent = on_back.has(direction)