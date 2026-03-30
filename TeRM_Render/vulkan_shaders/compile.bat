set compiler="%VULKAN_SDK%/Bin/glslc.exe"
%compiler% src/device_space_mesh.vert -o spirv/device_space_mesh_vert.spv
%compiler% src/device_space_mesh.frag -o spirv/device_space_mesh_frag.spv
%compiler% src/device_space_mesh_textured.vert -o spirv/device_space_mesh_textured_vert.spv
%compiler% src/device_space_mesh_textured.frag -o spirv/device_space_mesh_textured_frag.spv
%compiler% src/billboard.vert -o spirv/billboard_vert.spv
%compiler% src/billboard.frag -o spirv/billboard_frag.spv
%compiler% src/mesh.vert -o spirv/mesh_vert.spv
%compiler% src/mesh.frag -o spirv/mesh_frag.spv
