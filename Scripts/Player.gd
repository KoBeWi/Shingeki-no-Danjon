extends KinematicBody2D

const SPEED = 320
const MEDITATION_TIME = 3
var GHOST = load("res://Nodes/Ghost.tscn")

onready var UI = $Camera/UI
onready var GHOST_EFFECT = $"/root/Game/GhostLayer/Effect"

var direction = -1
var static_time = 0
var motion_time = 0
var prev_move = Vector2()

var animations = {Body = "Idle", RightArm = "SwordAttack", LeftArm = "ShieldOn"}
var sprite_direction = "Front"

var ghost_mode = false
var is_ghost = false

var attacking = false
var shielding = false

func _ready():
	change_animation("Body", "Idle")
	change_animation("LeftArm", "ShieldOff")
	change_dir(2)
	reset_arms()

func _physics_process(delta):
	var move = Vector2()
	
	static_time += delta
	motion_time += delta
	if static_time >= MEDITATION_TIME: SkillBase.inc_stat("Meditation")
	
	if !ghost_mode:
		if Input.is_action_pressed("Up"):
			move.y = -1
			if prev_move.x == 0 or (direction == 0 and prev_move.y > 0): change_dir(0)
		if Input.is_action_pressed("Down"):
			move.y = 1
			if prev_move.x == 0 or (direction == 2 and prev_move.y < 0): change_dir(2)
		if Input.is_action_pressed("Left"):
			move.x = -1
			if prev_move.y == 0 or (direction == 1 and prev_move.x > 0): change_dir(3)
		if Input.is_action_pressed("Right"):
			move.x = 1
			if prev_move.y == 0 or (direction == 3 and prev_move.x < 0): change_dir(1)
	
	move = move.normalized() * SPEED
	
	if !is_ghost and !attacking and !ghost_mode and Input.is_action_just_pressed("Attack"):
		Res.play_sample(self, "Sword")
		$ArmAnimator.play("SwordAttack" + sprite_direction)
		attacking = true
	
	if !shielding and Input.is_action_just_pressed("Shield"):
		change_animation("LeftArm", "ShieldOn")
		shielding = true
	elif shielding and Input.is_action_just_released("Shield"):
		change_animation("LeftArm", "ShieldOff")
		shielding = false
	
	if Input.is_action_just_pressed("Spell1") and PlayerStats.get_skill(0) and PlayerStats.mana > PlayerStats.get_skill(0).cost:
		cast_spell(0)
	
	if randi()%10 == 0: PlayerStats.mana += 1
	UI.soft_refresh()
	
	if SkillBase.has_skill("FastWalk") and Input.is_key_pressed(KEY_SHIFT): move *= 3
	
	if Input.is_action_just_pressed("Ghost"):
		if is_ghost:
			get_parent().cancel_ghost()
		elif !ghost_mode:
			Res.play_sample(self, "GhostEnter")
			ghost_mode = GHOST.instance()
			ghost_mode.is_ghost = true
			ghost_mode.position.y += 8
			ghost_mode.get_node("Body/RightArm/Weapon").visible = false
#			ghost_mode.get_node("Body/LeftArm/Shield").visible = false
			
			add_child(ghost_mode)
			GHOST_EFFECT.visible = true
			GHOST_EFFECT.get_node("../AnimationPlayer").play("Activate")
	
	if move.length() > 0:
		static_time = 0
		change_animation("Body", "Walk")
	else:
		motion_time = 0
		change_animation("Body", "Idle")
	
	var rem = move_and_slide(move)
	if rem.length() == 0: motion_time = 0
	elif motion_time > 1: SkillBase.inc_stat("PixelsTravelled", int(rem.length()))
	prev_move = move
	
	if Input.is_key_pressed(KEY_F3): print(int(position.x / 800), ", ", int(position.y / 800)) ##debug

func damage(attacker, amount, knockback):
	Res.create_instance("DamageNumber").damage(self, amount)
	SkillBase.inc_stat("DamageTaken", amount)
	PlayerStats.health -= amount
	UI.soft_refresh()
	move_and_slide((position - attacker.position).normalized() * 1000 * knockback)
	if ghost_mode: cancel_ghost()

func _on_animation_finished(anim_name):
	if anim_name.find("SwordAttack") > -1: attacking = false

func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("enemies"):
		SkillBase.inc_stat("OneHanded")
		SkillBase.inc_stat("Melee")
		collider.get_parent().damage(PlayerStats.get_damage())

func change_dir(dir):
	if direction == dir: return
	direction = dir
	sprite_direction = ["Back", "Right", "Front", "Left"][dir]
	change_texture($Body, "Body" + animations["Body"])
	change_texture($Body/RightArm, "SwordAttack", ["Left", "Back"])
	update_weapon()
	change_texture($Body/LeftArm, animations["LeftArm"], ["Right", "Back"], {"Back": 1, "Front": 0})

func change_texture(sprite, texture, on_back = [], move_child = {}):
	sprite.texture = Res.get_resource("res://Sprites/Player/" + sprite_direction + "/" + texture + ".png")
	sprite.show_behind_parent = on_back.has(sprite_direction)
	if move_child.has(sprite_direction):
		$Body.move_child(sprite, move_child[sprite_direction])

func change_animation(part, animation):
	if animations[part] == animation: return
	
	match animation:
		"Idle":
			change_texture($Body, "BodyIdle")
			$Body.hframes = 2
			$BodyAnimator.playback_speed = 4
		"Walk":
			change_texture($Body, "BodyWalk")
			$Body.hframes = 9
			$BodyAnimator.playback_speed = 16
		"ShieldOn":
			change_texture($Body/LeftArm, "ShieldOn", ["Right", "Back"])
			$Body/LeftArm.hframes = 3
		"ShieldOff":
			change_texture($Body/LeftArm, "ShieldOff", ["Right", "Back"])
			$Body/LeftArm.hframes = 2
	
	match part:
		"Body": $BodyAnimator.play(animation)
		_: $ArmAnimator.play(animation)
	animations[part] = animation

func reset_arms():
	$Body/LeftArm.frame = 0
	$Body/RightArm.frame = 0
	$Body/RightArm/Weapon.frame = 0
	$AttackCollider/Shape.disabled = true

func weapon_sprite():
	if PlayerStats.equipment[3] > -1:
		return Res.items[PlayerStats.equipment[3]].sprite
	else:
		return "Sword1"

func update_weapon():
	change_texture($Body/RightArm/Weapon, "Weapons/" + weapon_sprite(), ["Front", "Right", "Left", "Back"])

func cancel_ghost():
	Res.play_sample(self, "GhostExit")
	ghost_mode.queue_free()
	ghost_mode = null
	GHOST_EFFECT.visible = false

func cast_spell(slot):
	var spell = PlayerStats.get_skill(slot)
	PlayerStats.mana -= spell.cost
	for stat in spell.stats:
		SkillBase.inc_stat(stat)
	
	var projectile = Res.create_instance("Projectiles/" + spell.projectile)
	get_parent().add_child(projectile)
	projectile.position = position
	if( direction == 2 ):
		projectile.position = position + Vector2(0,80)
	
	
	projectile.direction = direction
	projectile.intiated()
	
	projectile.damage = spell.damage
	for stat in spell.scalling.keys():
		projectile.damage += int(PlayerStats[stat] * spell.scalling[stat])
	
	if SkillBase.has_skill("FireAffinity"): projectile.damage *= 3 ##hack