@tool
extends Node3D
#made by https://github.com/Rontorx

@export var gridmap: GridMap
@export var parent_node: Node3D
@export var tiles_count: Dictionary

@export_tool_button("Bake grid")
var button1 = bake_grid

func bake_grid():
	tiles_count.clear()
	var error_count = 0
	if gridmap == null or parent_node == null:
		print ("Assign gridmap and parent node")
		return

	for id in gridmap.mesh_library.get_item_list():
			tiles_count.set(gridmap.mesh_library.get_item_name(id), 0)
	await get_tree().physics_frame
	if parent_node.get_child_count() != 0:
		for mesh: MeshInstance3D in parent_node.get_children():
			if mesh.name.begins_with("@MeshInstance3D"):
				error_count = error_count + 1
				continue
			var base_name = mesh.name
			var clear_name = base_name.left(base_name.rfind("_"))
			tiles_count[clear_name] += 1

	var used_cells = gridmap.get_used_cells()
	var mesh_library: MeshLibrary = gridmap.mesh_library
	for cell in used_cells:
		var item = gridmap.get_cell_item(cell)
		if item == GridMap.INVALID_CELL_ITEM:
			continue

		var cell_mesh: Mesh = mesh_library.get_item_mesh(item)
		var cell_mesh_name: String = mesh_library.get_item_name(item)
		if cell_mesh == null:
			continue
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = cell_mesh.duplicate()
		mesh_instance.name = cell_mesh_name + str("_") + str(tiles_count[cell_mesh_name])
		parent_node.add_child(mesh_instance)
		mesh_instance.global_position = gridmap.map_to_local(cell)
		mesh_instance.owner = get_tree().edited_scene_root
		
		tiles_count[cell_mesh_name] += 1
		
		if !mesh_library.get_item_shapes(item).is_empty():
			
			var shapes_array: Array = mesh_library.get_item_shapes(item)
			var collision_shape: Shape3D = shapes_array[0]

			var static_instance = StaticBody3D.new()
			static_instance.collision_layer = gridmap.collision_layer
			static_instance.collision_mask = gridmap.collision_mask
			mesh_instance.add_child(static_instance)
			static_instance.owner = mesh_instance.get_tree().edited_scene_root

			var collision_instance = CollisionShape3D.new()
			collision_instance.shape = collision_shape
			static_instance.add_child(collision_instance)
			collision_instance.owner = static_instance.get_tree().edited_scene_root
			
		
	gridmap.clear()
	notify_property_list_changed()
	print("GridMap meshes baking complete, GridMap cleared, there were ", error_count, " name errors!")
