
init_renderer :: () -> bool {
    result: HRESULT;
    dxgi_factory_flags: u32;

    #if DEBUG {
        debug_interface: *ID3D12Debug1;
        if SUCCEEDED(D3D12GetDebugInterface(*uid(ID3D12Debug1_UUID), xx *debug_interface)) {
            ID3D12Debug1_EnableDebugLayer(debug_interface);
            // ID3D12Debug1_SetEnableGPUBasedValidation(debug_interface, .TRUE);
            // ID3D12Debug1_SetEnableSynchronizedCommandQueueValidation(debug_interface, .TRUE);
            dxgi_factory_flags |= DXGI_CREATE_FACTORY_DEBUG;
        }
    }

    return false;
}


#scope_module

#import "dxgi";
#import "d3d12"()(INCLUDE_DEBUG_BINDINGS=true);
#import "d3d_compiler";
#import "Windows";

#load "direct3d_backend.jai";
