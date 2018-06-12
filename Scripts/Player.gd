extends KinematicBody2D

const SPEED = 320
const MEDITATION_TIME = 3
var GHOST = load("res://Nodes/Player.tscn")

onready var UI = $Camera/UI
onready var GHOST_EFFECT = $"/root/Game/GhostLayer/Effect"

var frame_counter = 0

var direction = -1
var static_time = 0
var motion_time = 0
var prev_move = Vector2()
var running = false
var knockback = Vector2()

var animations = {Body = "", RightArm = "", LeftArm = ""}
var sprite_direction = "Front"

var ghost_mode = false
var is_ghost = false

var attacking = false
var shielding = false
var current_element = 0

var charge_spin
var triggered_skill

var damaged
var dead = false

func _ready():
	change_animation("Body", "Idle")
	$BodyAnimator.play("Idle")
	change_animation("LeftArm", "ShieldOff")
	change_dir(2)
	reset_arms()
	
	PlayerStats.connect("equipment_changed", self, "update_weapon")
	PlayerStats.connect("equipment_changed", self, "update_shield")

func _physics_process(delta):
	if dead: return
	frame_counter += 1
	var move = Vector2()
	
	if is_ghost:
		is_ghost -= delta
		GHOST_EFFECT.material.set_shader_param("noise_power", 0.002 + max(2 - is_ghost, 0) * 0.02)
		if is_ghost <= 0: get_parent().cancel_ghost()
	
	static_time += delta
	motion_time += delta
	if static_time >= MEDITATION_TIME: SkillBase.inc_stat("Meditation")
	
	var elements_on = (!is_ghost and $Elements.visible)
	var not_move = (ghost_mode or elements_on or knockback.length_squared() > 0)
	
	if !not_move:
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
	elif knockback.length_squared() > 0:
		move = knockback * 50
		if move.length() > 5000: move = move.normalized() * 5000
		knockback /= 1.5
		if knockback.length_squared() < 1: knockback = Vector2()
	
	if !is_ghost and !attacking and !ghost_mode and !shielding and Input.is_action_just_pressed("Attack"):
		if PlayerStats.get_equipment("weapon"): Res.play_pitched_sample(self, "Sword")
		else: Res.play_pitched_sample(self, "Punch")
		$ArmAnimator.play("SwordAttack" + sprite_direction)
		attacking = true
		charge_spin = 1
	
	if charge_spin: charge_spin += delta
	
	if Input.is_action_just_released("Attack"):
		if charge_spin and charge_spin > 2:
			change_animation("Body", "SpinAttack")
			change_animation("LeftArm", "SpinAttack")
		charge_spin = null
	
	if !attacking and !shielding and PlayerStats.get_equipment("shield") and Input.is_action_pressed("Shield"):
		change_animation("LeftArm", "ShieldOn")
		shielding = true
	elif shielding and Input.is_action_just_released("Shield"):
		change_animation("LeftArm", "ShieldOff")
		shielding = false
	
	if Input.is_action_just_pressed("Spell1") and PlayerStats.get_skill(0) and PlayerStats.mana > PlayerStats.get_skill(0).cost:
		cast_spell(0)
	
	if PlayerStats.mana < PlayerStats.max_mana and frame_counter % 20 == 0: PlayerStats.mana += 1
	UI.soft_refresh()
	
	if move.length_squared() == 0: running = false
	if SkillBase.has_skill("FastWalk") and SkillBase.check_combo(["Dir", "Same"]): running = true
	if !not_move:
		move = move.normalized() * SPEED
		if running and !not_move: move *= 2

	if !elements_on:
		if Input.is_action_just_pressed("Magic"):#SkillBase.check_combo(["Magic", "Magic_"]):
#			print(SkillBase.current_combo)
			$Elements.visible = true
			SkillBase.current_combo.clear()
	else:
		if Input.is_action_pressed("Up"): current_element = 3
		elif Input.is_action_pressed("Right"): current_element = 2
		elif Input.is_action_pressed("Down"): current_element = 4
		elif Input.is_action_pressed("Left"): current_element = 1
		else: current_element = 0
		
		$Elements/Select.position = $Elements.get_child(current_element).position
		UI.get_node("HUD/Controls/ButtonElement").texture = Res.cache_resource("res://Sprites/UI/HUD/ButtonElement" + str(current_element) + ".png")
		
		if Input.is_action_just_released("Magic"): $Elements.visible = false
	
	if !elements_on and !ghost_mode:# and Input.is_action_pressed("Magic"):
		use_magic()
		if triggered_skill:
			triggered_skill[1] -= delta
			if triggered_skill[1] <= 0: trigger_skill()
	
	if Input.is_action_just_pressed("Ghost"):
		if is_ghost:
			get_parent().cancel_ghost()
		elif !ghost_mode:
			Res.play_sample(self, "GhostEnter")
			ghost_mode = GHOST.instance()
			ghost_mode.modulate = Color(1, 1, 1, 0.5)
			ghost_mode.is_ghost = 5
			ghost_mode.position.y += 8
			ghost_mode.remove_from_group("players")
			ghost_mode.add_to_group("ghosts")
			ghost_mode.name = "Ghost" ##tego nie powinno być, ale wrogowie sprawdzają name
			ghost_mode.get_node("Body/RightArm/Weapon").visible = false
			ghost_mode.get_node("Body/LeftArm/Shield").visible = false
			
			add_child(ghost_mode)
			GHOST_EFFECT.visible = true
			GHOST_EFFECT.get_node("../AnimationPlayer").play("Activate")
	
	if !damaged and !knockback:
		if move.length() > 0 and !not_move:
			static_time = 0
			PlayerStats.damage_equipment("boots")
			change_animation("Body", "Walk")
		else:
			motion_time = 0
			change_animation("Body", "Idle")
	else:
		damaged -= 1
		if damaged == 0: damaged = null
	
	var rem = move_and_slide(move)
	if rem.length() == 0: motion_time = 0
	elif motion_time > 1: SkillBase.inc_stat("PixelsTravelled", int(rem.length()))
	prev_move = move
	
	if Input.is_key_pressed(KEY_F3): print(int(position.x / 800), ", ", int(position.y / 800)) ##debug
	if Input.is_key_pressed(KEY_F1): PlayerStats.add_experience(1000) ##debug

func damage(attacker, amount, _knockback):
	if dead: return
	damaged = 16
	Res.play_pitched_sample(self, "PlayerHurt")
	
	amount = max(1, amount - PlayerStats.get_defense())
	var damage = amount
	
	if shielding : 
		damage = amount*(1-PlayerStats.shield_block) - PlayerStats.shield_amout
		
		if damage < 0:
			SkillBase.inc_stat("ShieldBlocks")
			PlayerStats.damage_equipment("shield")
			Res.play_sample(self, "ShieldBlock")
			damage = "BLOCKED"
	else:
		SkillBase.inc_stat("DamageTaken", damage)
		PlayerStats.health -= damage
		PlayerStats.damage_equipment("armor", 2)
		PlayerStats.damage_equipment("helmet")
		
	Res.create_instance("DamageNumber").damage(self, damage, "player")
	UI.soft_refresh()
	
	knockback += (position - attacker.position).normalized() * _knockback
	if ghost_mode: cancel_ghost()
	
	if PlayerStats.health <= 0:
		dead = true
		$Body/LeftArm.visible = false
		$Body/RightArm.visible = false
		change_animation("Body", "Death")
		Res.play_sample(self, "Dead")
		yield(get_tree().create_timer(3), "timeout")
		get_tree().change_scene("res://Scenes/TitleScreen.tscn")
	else:
		change_animation("Body", "Damage")

func _on_animation_finished(anim_name):
	if "SwordAttack" in anim_name: attacking = false
	elif "SpinAttack" in anim_name:
		change_animation("Body", "Idle")
		change_animation("RightArm", "SwordAttackFront")
		change_animation("LeftArm", "ShieldOff")
		reset_arms()

func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("enemies"):
		SkillBase.inc_stat("OneHanded")
		SkillBase.inc_stat("Melee")
		collider.get_parent().damage(PlayerStats.get_damage())

func change_dir(dir):
	if direction == dir or !dead and (Input.is_action_pressed("Attack") or Input.is_action_pressed("Shield")): return
#	running = false
	direction = dir
	sprite_direction = ["Back", "Right", "Front", "Left"][dir]
	change_texture($Body, "Body" + animations["Body"])
	change_texture($Body/RightArm, "SwordAttack", ["Left", "Back"])
	change_texture($Body/LeftArm, alt_animation(animations["LeftArm"]), ["Right", "Back"], {"Back": 1, "Front": 0})
	update_weapon()
	update_shield()

func alt_animation(anim):
	match anim:
		"ShieldOn", "ShieldOff": return "Shield"
		_: return anim

var textures = {}
func get_texture_hack(texture):
	if !textures.has(texture): textures[texture] = load(texture)
	
	return textures[texture]

func change_texture(sprite, texture, on_back = [], move_child = {}):
	var dir = sprite_direction
	if texture == "SpinAttack": dir = "Common"
	sprite.texture = get_texture_hack("res://Sprites/Player/" + dir + "/" + texture + ".png")
	sprite.show_behind_parent = on_back.has(sprite_direction)
	if move_child.has(sprite_direction):
		$Body.move_child(sprite, move_child[sprite_direction])

func change_animation(part, animation):
	if animations[part] == animation: return
	animations[part] = animation
	
	match animation:
		"Idle":
			change_texture($Body, "BodyIdle")
			$Body.hframes = 10
			$BodyAnimator.playback_speed = 16
			$Body.vframes = 1
		"Damage":
			change_texture($Body, "BodyDamage")
			$Body.hframes = 1
			$BodyAnimator.playback_speed = 1
			$Body.vframes = 1
		"SpinAttack":
			change_texture($Body, "SpinAttack")
			change_texture($Body/LeftArm, "SpinAttack")
			change_texture($Body/RightArm, "SpinAttack")
			$Body.hframes = 7
			$Body/LeftArm.hframes = 7
			$Body/RightArm.hframes = 7
			$ArmAnimator.playback_speed = 16
			$BodyAnimator.playback_speed = 16
		"Death":
			change_dir(2)
			change_texture($Body, "Death")
			$Body.hframes = 8
			$BodyAnimator.playback_speed = 10
			$Body.vframes = 1
		"Walk":
			change_texture($Body, "BodyWalk")
			$Body.hframes = 9
			$Body.vframes = 2
			$BodyAnimator.playback_speed = 16
		"ShieldOn":
			change_texture($Body/LeftArm, "Shield", ["Back"])
			$Body/LeftArm.hframes = 2
			update_shield()
		"ShieldOff":
			change_texture($Body/LeftArm, "Shield", ["Right", "Back"])
			$Body/LeftArm.hframes = 2
			update_shield()
	
	match part:
		"Body": $BodyAnimator.play(animation)
		_: $ArmAnimator.play(animation)

func reset_arms():
	$Body/RightArm.hframes = 10
	$Body/LeftArm.frame = 0
	$Body/RightArm.frame = 0
	$Body/RightArm/Weapon.frame = 0
	$AttackCollider/Shape.disabled = true

func weapon_sprite():
	if PlayerStats.get_equipment("weapon"):
		return Res.items[PlayerStats.get_equipment("weapon").id].sprite
	else:
		return "Stick" ##nie >:(

func shield_sprite():
	if PlayerStats.get_equipment("shield"):
		return Res.items[PlayerStats.get_equipment("shield").id].sprite
	else:
		return "" ##nope

func update_weapon():
	change_texture($Body/RightArm/Weapon, "Weapons/" + weapon_sprite(), ["Front", "Right", "Left", "Back"])

func update_shield():
	if shield_sprite() == "":
		$Body/LeftArm/Shield.visible = false
	else:
		$Body/LeftArm/Shield.visible = true
		var ordering = ["Back"]
		if animations.LeftArm != "ShieldOn": ordering.append("Right")
		change_texture($Body/LeftArm/Shield, "Shields/" + shield_sprite(), ordering)

func cancel_ghost():
	Res.play_sample(self, "GhostExit")
	ghost_mode.queue_free()
	ghost_mode = null
	GHOST_EFFECT.visible = false

func use_magic(): ##nie tylko magia :|
	for skill in SkillBase.get_active_skills():
		skill = Res.skills[skill]
		
		if (!skill.has("magic") or current_element == skill.magic) and SkillBase.check_combo(skill.combo) and (!triggered_skill
			or skill != triggered_skill[0] and (skill.combo.size() > triggered_skill[0].combo.size() or skill.combo.back().length() > triggered_skill[0].combo.back().length())):
			triggered_skill = [skill, 0.2]

func trigger_skill():
	var skill = triggered_skill[0]
	triggered_skill = null
	
	if skill.has("cost"):
		if PlayerStats.mana < skill.cost: return
		else: PlayerStats.mana -= skill.cost
	
	SkillBase.current_combo.clear()
	
	if skill.has("stats"): for stat in skill.stats: SkillBase.inc_stat(stat)
	
	if skill.has("projectile"):
		var projectile = Res.create_instance("Projectiles/" + skill.projectile)
		get_parent().add_child(projectile)
		projectile.position = position - Vector2(0,45)
		if( direction == 2 ):
			projectile.position = position + Vector2(0,80)
		
		
		projectile.direction = direction
		projectile.intiated()
		
		projectile.damage = skill.damage
		for stat in skill.scalling.keys():
			projectile.damage += int(PlayerStats[stat] * skill.scalling[stat])
		
		if SkillBase.has_skill("FireAffinity"): projectile.damage *= 3 ##hack

func _on_other_attack_hit(body):
	if body.is_in_group("secrets"):
		body.hit(self)