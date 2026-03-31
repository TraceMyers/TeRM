set compiler="%VULKAN_SDK%/Bin/glslc.exe"
%compiler% src/billboard.vert -o spirv/billboard_vert.spv
%compiler% src/billboard.frag -o spirv/billboard_frag.spv
%compiler% src/mesh.vert -o spirv/mesh_vert.spv
%compiler% src/mesh.frag -o spirv/mesh_frag.spv
