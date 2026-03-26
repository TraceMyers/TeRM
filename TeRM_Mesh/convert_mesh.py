import sys
import bpy
import struct 
import bmesh

def main():
    # this script expects two arguments after '--': the file coming in, and the filename going out
    # e.g. blender --background --python export_mesh.py -- input_mesh.fbx output_mesh.trm
    argv = sys.argv[sys.argv.index('--') + 1:]
    input_path = argv[0]
    output_path = argv[1]

    input_extension = input_path.rsplit('.', 1)[-1].lower()
    importers = {
        'fbx':  lambda p: bpy.ops.import_scene.fbx(filepath=p),
        'gltf': lambda p: bpy.ops.import_scene.gltf(filepath=p),
        'glb':  lambda p: bpy.ops.import_scene.gltf(filepath=p),
        'obj':  lambda p: bpy.ops.wm.obj_import(filepath=p),
        'dae':  lambda p: bpy.ops.wm.collada_import(filepath=p),
    }

    if input_extension not in importers:
        print(f"unsupported format {input_extension}");
        sys.exit(1)

    output_extension = output_path.rsplit('.', 1)[-1].lower()
    
    if output_extension is not "trm":
        print("the output file must have the extension .trm")
        sys.exit(1)

    # run the selected importer, which will populate the objects
    importers[input_extension](input_path)

    # according to claude, the loaded object *may* be active after import
    # this forced it to be the active object
    obj = bpy.context.selected_objects[0]
    bpy.context.view-layer.object.active = obj

    export_term_mesh(output_path)


def export_term_mesh(output_path: str):
    obj = bpy.context.active_object
    mesh = obj.data
    
    mesh_modifier = bmesh.new()
    mesh_modifier.from_mesh(obj.data)

    bmesh.ops.triangulate(mesh_modifier, faces=mesh_modifier.faces)

    mesh_modifier.to_mesh(mesh)
    mesh_modifier.free()

    mesh.calc_normals_split()
    mesh.calc_tangents()

    vertices = []
    indices = []

    for poly in mesh.polygons:
        for loop_index in poly.loop_indices:
            loop = mesh.loops[loop_index]
            vert = mesh.vertices[loop.vertex_index]
            
            v_position = vert.co
            v_normal = loop.normal
            tangent = loop.tangent
            bitangent_sign = loop.bitangent_sign

            if mesh.uv_layers and len(mesh.uv_layers) > 0:
                if len(mesh.uv_layers) <= 2:
                    uv0 = mesh.uv_layers[0].data[loop_index].uv
                    if len(mesh.uv_layers) == 2:
                        uv1 = mesh.uv_layers[1].data[loop_index].uv
                else:
                    print(f"mesh has {len(mesh.uv_layers)} uv layers, but only up to 2 are supported")
                    sys.exit(1)
            else:
                uv0 = (0, 0)
                uv1 = (0, 0)

            if mesh.color_attributes:
                color_layer = mesh.color_attributes[0]
                color = color_layer.data[loop_index].color
            else:
                color = (1.0, 1.0, 1.0, 1.0)

            vertices.append((
                *position, 
                *normal, 
                *tangent, bitangent_sign,
                *uv0,
                *uv1,
                *color,
                0, 0, 0, 0
            ))
        


if __name__ == '__main__':
    main()
