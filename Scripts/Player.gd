extends KinematicBody2D

const SPEED = 320
const MEDITATION_TIME = 3
const SKILL_TIMEOUT = 3

onready var UI = $Camera/UI
var texture_cache = {}

var direction = 1
var static_time = 0
var skill_time = 0

var attacking = false

func _ready():
	PlayerStats.connect("level_up", self, "level_up")
	SkillBase.connect("new_skill", self, "new_skill")
	
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
		Res.play_sample(self, "Sword")
		$Animation.play("SwordAttackRight")
		attacking = true
	
	if Input.is_action_just_pressed("Spell1") and PlayerStats.get_skill(0) and PlayerStats.mana > PlayerStats.get_skill(0).cost:
		cast_spell(0)
	
	if randi()%10 == 0: PlayerStats.mana += 1
	UI.get_node("HUD/ManaIndicator").value = PlayerStats.mana
	
	if SkillBase.has_skill("FastWalk") and Input.is_key_pressed(KEY_SHIFT): move *= 3
	SkillBase.inc_stat("PixelsTravelled", int(move.length()))
	
	if move != Vector2(): static_time = 0
	move_and_slide(move)

func damage(attacker, amount, knockback):
	Res.create_instance("DamageNumber").damage(self, amount)
	SkillBase.inc_stat("DamageTaken", amount)
	PlayerStats.health -= amount
	UI.get_node("HUD/HealthIndicator").value = PlayerStats.health
	move_and_slide((position - attacker.position).normalized() * 1000 * knockback)

func _on_animation_finished(anim_name):
	if anim_name == "SwordAttackRight":
		attacking = false

func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("enemies"):
		SkillBase.inc_stat("OneHanded")
		SkillBase.inc_stat("Melee")
		collider.get_parent().damage(PlayerStats.get_damage())

func new_skill(skill):
	Res.play_sample(self, "SkillAcquired")
	UI.get_node("SkillAcquiredPanel").visible = true
	UI.get_node("SkillAcquiredPanel/Name").text = skill
	skill_time = SKILL_TIMEOUT
	
func level_up():
	Res.play_sample(self, "LevelUp")

func change_dir(dir):
	direction = dir
	var d = ["Back", "Right", "Front", "Left"][dir]
	change_texture($Body, d, "Body")
	change_texture($Body/RightArm, d, "SwordAttack", ["Left", "Back"])
	change_texture($Body/LeftArm, d, "ShieldOn", ["Right", "Back"])

func change_texture(sprite, direction, texture, on_back = []):
	sprite.texture = texture_cache["res://Sprites/Player/" + direction + "/" + texture + ".png"]
	sprite.show_behind_parent = on_back.has(direction)

func cast_spell(slot):
	var spell = PlayerStats.get_skill(slot)
	PlayerStats.mana -= spell.cost
	for stat in spell.stats:
		SkillBase.inc_stat(stat)
	
	var projectile = Res.create_instance("Projectiles/" + spell.projectile)
	get_parent().add_child(projectile)
	projectile.position = position
	projectile.direction = direction
	projectile.intiated()
	
	projectile.damage = spell.damage
	for stat in spell.scalling.keys():
		projectile.damage += int(PlayerStats[stat] * spell.scalling[stat])