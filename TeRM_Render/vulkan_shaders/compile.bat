set compiler="%VULKAN_SDK%/Bin/glslc.exe"
%compiler% src/device_space_mesh.vert -o spirv/device_space_mesh_vert.spv
%compiler% src/device_space_mesh.frag -o spirv/device_space_mesh_frag.spv
%compiler% src/device_space_mesh_textured.vert -o spirv/device_space_mesh_textured_vert.spv
%compiler% src/device_space_mesh_textured.frag -o spirv/device_space_mesh_textured_frag.spv
