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
			var shape: CapsuleShape3D = CapsuleShape3D.new()
			shape.radius = 0.14
			shape.height = 0.36
			col_shape.shape = shape
			
			var mesh_inst: MeshInstance3D = MeshInstance3D.new()
			var cap_mesh: CapsuleMesh = CapsuleMesh.new()
			cap_mesh.radius = 0.14
			cap_mesh.height = 0.36
			mesh_inst.mesh = cap_mesh
			
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.albedo_color = [Color("ff6b81"), Color("70a1ff"), Color("7bed9f"), Color("eccc68")].pick_random()
			mat.roughness = 0.4
			mat.clearcoat_enabled = true
			mat.clearcoat = 0.5
			mesh_inst.material_override = mat
			add_child(mesh_inst)
			
		PrizeType.SPHERE:
			var shape: SphereShape3D = SphereShape3D.new()
			shape.radius = 0.16
			col_shape.shape = shape
			
			var mesh_inst: MeshInstance3D = MeshInstance3D.new()
			var sph_mesh: SphereMesh = SphereMesh.new()
			sph_mesh.radius = 0.16
			sph_mesh.height = 0.32
			mesh_inst.mesh = sph_mesh
			
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.albedo_color = [Color("ff4757"), Color("2ed573"), Color("1e90ff"), Color("ffa502")].pick_random()
			mat.metallic = 0.1
			mat.roughness = 0.2
			mat.clearcoat_enabled = true
			mat.clearcoat = 0.8
			mesh_inst.material_override = mat
			add_child(mesh_inst)
			
		PrizeType.CUBE:
			var shape: BoxShape3D = BoxShape3D.new()
			shape.size = Vector3(0.26, 0.26, 0.26)
			col_shape.shape = shape
			
			var mesh_inst: MeshInstance3D = MeshInstance3D.new()
			var box_mesh: BoxMesh = BoxMesh.new()
			box_mesh.size = Vector3(0.26, 0.26, 0.26)
			mesh_inst.mesh = box_mesh
			
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.albedo_color = [Color("a55eea"), Color("ff7f50"), Color("00d2d3")].pick_random()
			mat.metallic = 0.35
			mat.roughness = 0.25
			mat.clearcoat_enabled = true
			mat.clearcoat = 0.5
			mesh_inst.material_override = mat
			add_child(mesh_inst)
			
			# Add gold ribbon cross
			var ribbon: MeshInstance3D = MeshInstance3D.new()
			var rib_mesh: BoxMesh = BoxMesh.new()
			rib_mesh.size = Vector3(0.27, 0.05, 0.27)
			ribbon.mesh = rib_mesh
			var rib_mat: StandardMaterial3D = StandardMaterial3D.new()
			rib_mat.albedo_color = Color("f1c40f")
			rib_mat.metallic = 0.8
			rib_mat.roughness = 0.3
			ribbon.material_override = rib_mat
			add_child(ribbon)
			
		PrizeType.STAR:
			# Star shaped diamond / prism with gold glow
			var shape: SphereShape3D = SphereShape3D.new()
			shape.radius = 0.18
			col_shape.shape = shape
			
			var mesh_inst: MeshInstance3D = MeshInstance3D.new()
			var cyl_mesh: CylinderMesh = CylinderMesh.new()
			cyl_mesh.top_radius = 0.02
			cyl_mesh.bottom_radius = 0.18
			cyl_mesh.height = 0.32
			cyl_mesh.radial_segments = 5
			mesh_inst.mesh = cyl_mesh
			
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.albedo_color = Color("ffd700")
			mat.metallic = 0.85
			mat.roughness = 0.15
			mat.emission_enabled = true
			mat.emission = Color("ffae19")
			mat.emission_energy_multiplier = 0.6
			mat.clearcoat_enabled = true
			mat.clearcoat = 1.0
			mesh_inst.material_override = mat
			add_child(mesh_inst)

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	GameManager.add_points(points, global_position)
	queue_free()
