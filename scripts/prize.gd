extends RigidBody3D
class_name Prize

enum PrizeType {
	CAPSULE,
	SPHERE,
	CUBE,
	STAR
}

@export var prize_type: PrizeType = PrizeType.SPHERE
@export var points: int = 10

var is_collected: bool = false

# Color palettes - richer and more appealing
const CAPSULE_COLORS: Array = [
	Color("ff6b9d"), Color("c44dff"), Color("45b7ff"), Color("ffd93d"),
	Color("6bcb77"), Color("ff8c42")
]
const SPHERE_COLORS: Array = [
	Color("ff4757"), Color("2ed573"), Color("1e90ff"), Color("ffa502"),
	Color("e056fd"), Color("7bed9f")
]
const CUBE_COLORS: Array = [
	Color("a55eea"), Color("ff6b6b"), Color("48dbfb"), Color("ff9ff3"),
	Color("00d2d3")
]

func _ready() -> void:
	continuous_cd = true
	# Give slightly randomized rotation at spawn
	rotation = Vector3(randf_range(-0.5, 0.5), randf_range(0, TAU), randf_range(-0.5, 0.5))
	
	# Tune physics material
	var phys_mat: PhysicsMaterial = PhysicsMaterial.new()
	phys_mat.friction = 0.85
	phys_mat.bounce = 0.12
	physics_material_override = phys_mat
	mass = 0.22
	
	setup_visuals()

func setup_type(p_type: PrizeType) -> void:
	prize_type = p_type
	match prize_type:
		PrizeType.CAPSULE:
			points = 10
		PrizeType.SPHERE:
			points = 10
		PrizeType.CUBE:
			points = 20
		PrizeType.STAR:
			points = 50
	setup_visuals()

func setup_visuals() -> void:
	# Hide any existing visual children
	for child in get_children():
		if child is VisualInstance3D or child is CollisionShape3D:
			child.queue_free()
	
	var col_shape: CollisionShape3D = CollisionShape3D.new()
	add_child(col_shape)
	
	match prize_type:
		PrizeType.CAPSULE:
			_build_capsule_prize(col_shape)
		PrizeType.SPHERE:
			_build_sphere_prize(col_shape)
		PrizeType.CUBE:
			_build_cube_prize(col_shape)
		PrizeType.STAR:
			_build_star_prize(col_shape)

func _build_capsule_prize(col_shape: CollisionShape3D) -> void:
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = 0.13
	shape.height = 0.34
	col_shape.shape = shape
	
	var base_color: Color = CAPSULE_COLORS.pick_random()
	
	# Main capsule body
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var cap_mesh: CapsuleMesh = CapsuleMesh.new()
	cap_mesh.radius = 0.13
	cap_mesh.height = 0.34
	cap_mesh.radial_segments = 20
	cap_mesh.rings = 8
	mesh_inst.mesh = cap_mesh
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.metallic = 0.15
	mat.roughness = 0.3
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.7
	mat.rim_enabled = true
	mat.rim = 0.15
	mat.rim_tint = 0.3
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Decorative stripe (ring around middle)
	var stripe: MeshInstance3D = MeshInstance3D.new()
	var stripe_mesh: TorusMesh = TorusMesh.new()
	stripe_mesh.inner_radius = 0.128
	stripe_mesh.outer_radius = 0.14
	stripe_mesh.ring_segments = 16
	stripe.mesh = stripe_mesh
	var stripe_mat: StandardMaterial3D = StandardMaterial3D.new()
	stripe_mat.albedo_color = Color.WHITE.lerp(base_color, 0.3)
	stripe_mat.metallic = 0.6
	stripe_mat.roughness = 0.2
	stripe.material_override = stripe_mat
	add_child(stripe)

func _build_sphere_prize(col_shape: CollisionShape3D) -> void:
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = 0.15
	col_shape.shape = shape
	
	var base_color: Color = SPHERE_COLORS.pick_random()
	
	# Main sphere
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var sph_mesh: SphereMesh = SphereMesh.new()
	sph_mesh.radius = 0.15
	sph_mesh.height = 0.3
	sph_mesh.radial_segments = 24
	sph_mesh.rings = 16
	mesh_inst.mesh = sph_mesh
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.metallic = 0.2
	mat.roughness = 0.15
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.9
	mat.rim_enabled = true
	mat.rim = 0.2
	mat.rim_tint = 0.2
	# Subtle emission for glow
	mat.emission_enabled = true
	mat.emission = base_color
	mat.emission_energy_multiplier = 0.08
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Add small star/highlight decal (dot on top)
	var dot: MeshInstance3D = MeshInstance3D.new()
	var dot_mesh: SphereMesh = SphereMesh.new()
	dot_mesh.radius = 0.035
	dot_mesh.height = 0.07
	dot.mesh = dot_mesh
	dot.position = Vector3(0, 0.14, 0)
	var dot_mat: StandardMaterial3D = StandardMaterial3D.new()
	dot_mat.albedo_color = Color.WHITE
	dot_mat.metallic = 0.5
	dot_mat.roughness = 0.1
	dot_mat.emission_enabled = true
	dot_mat.emission = Color.WHITE
	dot_mat.emission_energy_multiplier = 0.3
	dot.material_override = dot_mat
	add_child(dot)

func _build_cube_prize(col_shape: CollisionShape3D) -> void:
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.24, 0.24, 0.24)
	col_shape.shape = shape
	
	var base_color: Color = CUBE_COLORS.pick_random()
	
	# Main cube (gift box body)
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(0.24, 0.24, 0.24)
	mesh_inst.mesh = box_mesh
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.metallic = 0.25
	mat.roughness = 0.3
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.5
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Ribbon cross (horizontal)
	var ribbon_h: MeshInstance3D = MeshInstance3D.new()
	var rib_h_mesh: BoxMesh = BoxMesh.new()
	rib_h_mesh.size = Vector3(0.25, 0.035, 0.06)
	ribbon_h.mesh = rib_h_mesh
	var rib_mat: StandardMaterial3D = StandardMaterial3D.new()
	rib_mat.albedo_color = Color("f1c40f")
	rib_mat.metallic = 0.8
	rib_mat.roughness = 0.2
	rib_mat.clearcoat_enabled = true
	rib_mat.clearcoat = 0.6
	ribbon_h.material_override = rib_mat
	add_child(ribbon_h)
	
	# Ribbon cross (vertical)
	var ribbon_v: MeshInstance3D = MeshInstance3D.new()
	var rib_v_mesh: BoxMesh = BoxMesh.new()
	rib_v_mesh.size = Vector3(0.06, 0.035, 0.25)
	ribbon_v.mesh = rib_v_mesh
	ribbon_v.material_override = rib_mat
	add_child(ribbon_v)
	
	# Bow on top (two small flared cylinders)
	var bow: MeshInstance3D = MeshInstance3D.new()
	var bow_mesh: SphereMesh = SphereMesh.new()
	bow_mesh.radius = 0.04
	bow_mesh.height = 0.06
	bow.mesh = bow_mesh
	bow.position = Vector3(0, 0.14, 0)
	var bow_mat: StandardMaterial3D = StandardMaterial3D.new()
	bow_mat.albedo_color = Color("f39c12")
	bow_mat.metallic = 0.7
	bow_mat.roughness = 0.15
	bow_mat.emission_enabled = true
	bow_mat.emission = Color("f39c12")
	bow_mat.emission_energy_multiplier = 0.2
	bow.material_override = bow_mat
	add_child(bow)

func _build_star_prize(col_shape: CollisionShape3D) -> void:
	# Star / Diamond - premium rare prize
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = 0.17
	col_shape.shape = shape
	
	# Diamond body (faceted look using prism)
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var cyl_mesh: CylinderMesh = CylinderMesh.new()
	cyl_mesh.top_radius = 0.02
	cyl_mesh.bottom_radius = 0.17
	cyl_mesh.height = 0.3
	cyl_mesh.radial_segments = 6
	mesh_inst.mesh = cyl_mesh
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color("ffd700")
	mat.metallic = 0.92
	mat.roughness = 0.08
	mat.emission_enabled = true
	mat.emission = Color("ffb319")
	mat.emission_energy_multiplier = 1.2
	mat.clearcoat_enabled = true
	mat.clearcoat = 1.0
	mat.rim_enabled = true
	mat.rim = 0.4
	mat.rim_tint = 0.15
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Inverted diamond bottom
	var bottom: MeshInstance3D = MeshInstance3D.new()
	var bottom_mesh: CylinderMesh = CylinderMesh.new()
	bottom_mesh.top_radius = 0.17
	bottom_mesh.bottom_radius = 0.02
	bottom_mesh.height = 0.2
	bottom_mesh.radial_segments = 6
	bottom.mesh = bottom_mesh
	bottom.position = Vector3(0, -0.25, 0)
	bottom.material_override = mat
	add_child(bottom)
	
	# Point light on the star for premium glow
	var star_light: OmniLight3D = OmniLight3D.new()
	star_light.light_color = Color("ffd700")
	star_light.light_energy = 0.6
	star_light.omni_range = 0.8
	add_child(star_light)

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	GameManager.add_points(points, global_position)
	queue_free()
