extends Resource
class_name AttackData

@export_group("Attack Data")
@export var animation_name: String = "attack_0"  # Attack animation
@export var attack_speed_multiplier: float = 1.0  # Affects attack speed
@export_range(0.0, 1.0, 0.05) var start_offset_percent: float = 0.2  # Time to start the animation
@export_range(0.0, 1.0, 0.05) var end_offset_percent: float = 0.8  # Time to end the animation

# ✅ **Combo properties**
@export_group("Combo")
@export_range(0.0, 1.0, 0.05) var : float = 0.3  # Time to chain attacks

# ✅ **Damage properties**
@export_group("Damage")
@export var per_attack_damage_modifier: int = 10  # Damage dealt by this attack
@export var critical_chance: float = 0.0  # Chance to deal critical damage
@export var critical_multiplier: float = 2.0  # Multiplier for critical damage

# ✅ **Hitbox properties**
@export_group("Hitbox")
@export var hitbox_scene: PackedScene  # Custom hitbox for this attack
@export var hitbox_start_time: float = 0.1  # When the hitbox activates
@export var hitbox_end_time: float = 0.3  # When the hitbox deactivates

# ✅ **VFX & Sound**
@export_group("VFX & Sound")
@export var vfx_scene: PackedScene  # Custom visual effect for this attack
@export var vfx_spawn_offset: Vector3 = Vector3.ZERO  # Where VFX should appear
@export var sound_effect: AudioStream  # Attack sound effect

# ✅ **Movement Properties**
@export_group("Movement")
@export var lunge_distance: float = 2.0  # If > 0, moves the player forward
@export var aim_assist_angle: float = 10.0  # Angle for auto-aiming

# ✅ **Status Effects**
@export_group("Status Effects")
@export var effect: String = ""  # E.g., "burn", "shock", "stun"
