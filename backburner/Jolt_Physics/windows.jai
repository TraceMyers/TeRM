//
// This file was auto-generated using the following command:
//
// jai generate_bindings.jai
//



_CRT_SECURE_NO_WARNINGS :: 1;
JPH_VERSION_MAJOR :: 5;
JPH_VERSION_MINOR :: 5;
JPH_VERSION_PATCH :: 0;

JPH_VERSION_FEATURE_BIT_1 :: 0;

JPH_VERSION_FEATURE_BIT_2 :: 0;

JPH_VERSION_FEATURE_BIT_3 :: 0;

JPH_VERSION_FEATURE_BIT_4 :: 0;

JPH_VERSION_FEATURE_BIT_5 :: 0;

JPH_VERSION_FEATURE_BIT_6 :: 0;

JPH_VERSION_FEATURE_BIT_7 :: 0;

JPH_VERSION_FEATURE_BIT_8 :: 0;

JPH_VERSION_FEATURE_BIT_9 :: 0;

JPH_VERSION_FEATURE_BIT_10 :: 0;

JPH_VERSION_FEATURE_BIT_11 :: 0;

JPH_CPU_ARCH_BITS :: 64;

JPH_VECTOR_ALIGNMENT :: 16;
JPH_DVECTOR_ALIGNMENT :: 32;

JPH_CACHE_LINE_SIZE :: 64;

JPH_RVECTOR_ALIGNMENT :: JPH_VECTOR_ALIGNMENT;

JPH_OBJECT_LAYER_BITS :: 16;
// Jolt Physics Library (https://github.com/jrouwe/JoltPhysics)
// SPDX-FileCopyrightText: 2021 Jorrit Rouwe
// SPDX-License-Identifier: MIT

/// Normal memory allocation, must be at least 8 byte aligned on 32 bit platform and 16 byte aligned on 64 bit platform.
/// Note that you can override JPH_DEFAULT_ALLOCATE_ALIGNMENT if your allocator's alignment is different from the alignment as defined by `__STDCPP_DEFAULT_NEW_ALIGNMENT__`.
AllocateFunction :: #type (inSize: u64) -> *void #c_call;

/// Reallocate memory. inBlock can be nullptr in which case it must behave as a memory allocation.
ReallocateFunction :: #type (inBlock: *void, inOldSize: u64, inNewSize: u64) -> *void #c_call;

/// Free memory. inBlock can be nullptr in which case it must do nothing.
FreeFunction :: #type (inBlock: *void) -> void #c_call;

/// Aligned memory allocation.
AlignedAllocateFunction :: #type (inSize: u64, inAlignment: u64) -> *void #c_call;

/// Free aligned memory. inBlock can be nullptr in which case it must do nothing.
AlignedFreeFunction :: #type (inBlock: *void) -> void #c_call;

/// Register platform default allocation / free functions
RegisterDefaultAllocator :: () -> void #foreign jolt_release "?RegisterDefaultAllocator@JPH@@YAXXZ";

/// Trace function, needs to be overridden by application. This should output a line of text to the log / TTY.
TraceFunction :: #type (inFMT: *u8, __args: ..Any) -> void #c_call;

/// Function called when an assertion fails. This function should return true if a breakpoint needs to be triggered
AssertFailedFunction :: #type (inExpression: *u8, inMessage: *u8, inFile: *u8, inLine: u32) -> bool #c_call;

// Helper functions to pass message on to failed function
AssertLastParam :: struct {
    __empty_struct_padding: u8; // C++ makes empty structs have length 1
}

/// Default implementation of AllocatorHasReallocate which tells if an allocator has a reallocate function
AllocatorHasReallocate :: struct(T: Type) {
    using,except(T) allocatorhasreallocate__raw: AllocatorHasReallocate__RAW(T);
    #if size_of(AllocatorHasReallocate__RAW(T)) == 0 {
        __empty_struct_padding:      u8; // C++ makes empty structs have length 1
    }
}
// AllocatorHasReallocate without padding. Needed to generate a C++-equivalent struct layout when "inheriting" from AllocatorHasReallocate
AllocatorHasReallocate__RAW :: struct(T: Type) {
    sValue  :: false;
}

/// STL allocator that forwards to our allocation functions
STLAllocator :: struct(T: Type) {
    using,except(T) stlallocator__raw:      STLAllocator__RAW(T);
    #if size_of(STLAllocator__RAW(T)) == 0 {
        __empty_struct_padding: u8; // C++ makes empty structs have length 1
    }
}
// STLAllocator without padding. Needed to generate a C++-equivalent struct layout when "inheriting" from STLAllocator
STLAllocator__RAW :: struct(T: Type) {
    value_type :: T;

    /// Pointer to type
    pointer :: *T;
    const_pointer :: *T;

    /// Reference to type.
    /// Can be removed in C++20.
    reference :: *T;
    const_reference :: *T;

    size_type :: u64;
    difference_type :: ptrdiff_t;

    /// The allocator is stateless
    is_always_equal :: std.true_type;

    /// Allocator supports moving
    propagate_on_container_move_assignment :: std.true_type;

    /// Converting to allocator for other type
    rebind :: struct(T2: Type) {
        using,except(T2) rebind__raw:            rebind__RAW(T2);
        #if size_of(rebind__RAW(T2)) == 0 {
            __empty_struct_padding: u8; // C++ makes empty structs have length 1
        }
    }
        // rebind without padding. Needed to generate a C++-equivalent struct layout when "inheriting" from rebind
    rebind__RAW :: struct(T2: Type) {
        other :: STLAllocator(T2);
    }
}

// Declare STL containers that use our allocator
String :: std.basic_string(u8, std.char_traits(u8), STLAllocator(u8));
IStringStream :: std.basic_istringstream(u8, std.char_traits(u8), STLAllocator(u8));

/// Implements the FNV-1a hash algorithm
/// @see https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function
/// @param inData Data block of bytes
/// @param inSize Number of bytes
/// @param inSeed Seed of the hash (can be used to pass in the hash of a previous operation, otherwise leave default)
/// @return Hash
HashBytes :: (inData: *void, inSize: u32, inSeed: u64 = 14695981039346656037) -> u64 #foreign jolt_release "?HashBytes@JPH@@YA_KPEBXI_K@Z";

/// Calculate the FNV-1a hash of inString.
/// @see https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function
HashString :: (inString: *u8, inSeed: u64 = 14695981039346656037) -> u64 #foreign jolt_release "?HashString@JPH@@YA_KPEBD_K@Z";

/// A 64 bit hash function by Thomas Wang, Jan 1997
/// See: http://web.archive.org/web/20071223173210/http://www.concentric.net/~Ttwang/tech/inthash.htm
/// @param inValue Value to hash
/// @return Hash
Hash64 :: (inValue: u64) -> u64 #foreign jolt_release "?Hash64@JPH@@YA_K_K@Z";

/// Fallback hash function that calls T::GetHash()
Hash :: struct(T: Type) {
    using,except(T) hash__raw:              Hash__RAW(T);
    #if size_of(Hash__RAW(T)) == 0 {
        __empty_struct_padding: u8; // C++ makes empty structs have length 1
    }
}
// Hash without padding. Needed to generate a C++-equivalent struct layout when "inheriting" from Hash
Hash__RAW :: struct(T: Type) {}

/// Simple replacement for std::vector
///
/// Major differences:
/// - Memory is not initialized to zero (this was causing a lot of page faults when deserializing large MeshShapes / HeightFieldShapes)
/// - Iterators are simple pointers (for now)
/// - No exception safety
/// - No specialization like std::vector<bool> has
/// - Not all functions have been implemented
Array :: struct(T: Type, Allocator: Type = STLAllocator(T)) {
    #as allocator:          Allocator;

    value_type :: T;
    allocator_type :: Allocator;
    size_type :: u64;
    difference_type :: Allocator;
    pointer :: *T;
    const_pointer :: *T;
    reference :: *T;
    const_reference :: *T;

    const_iterator :: *T;
    iterator :: *T;

    /// An iterator that traverses the array in reverse order
    rev_it :: struct {
        mValue: *T;
    } #no_padding

    /// A const iterator that traverses the array in reverse order
    crev_it :: struct {
        mValue: *T;
    } #no_padding

    reverse_iterator :: rev_it;
    const_reverse_iterator :: crev_it;

    mSize:                  size_type = 0;
    mCapacity:              size_type = 0;
    mElements:              *T = null;
}

/// The constant \f$\pi\f$
JPH_PI: float : 3.141593;

/// A large floating point value which, when squared, is still much smaller than FLT_MAX
cLargeFloat: float : 999999986991104.0;

/// Convert a value from degrees to radians
DegreesToRadians :: (inV: float) -> float #foreign jolt_release "?DegreesToRadians@JPH@@YAMM@Z";

/// Convert a value from radians to degrees
RadiansToDegrees :: (inV: float) -> float #foreign jolt_release "?RadiansToDegrees@JPH@@YAMM@Z";

/// Convert angle in radians to the range \f$[-\pi, \pi]\f$
CenterAngleAroundZero :: (inV: float) -> float #foreign jolt_release "?CenterAngleAroundZero@JPH@@YAMM@Z";

/// Compute number of trailing zero bits (how many low bits are zero)
CountTrailingZeros :: (inValue: u32) -> u32 #foreign jolt_release "?CountTrailingZeros@JPH@@YAII@Z";

/// Compute the number of leading zero bits (how many high bits are zero)
CountLeadingZeros :: (inValue: u32) -> u32 #foreign jolt_release "?CountLeadingZeros@JPH@@YAII@Z";

/// Count the number of 1 bits in a value
CountBits :: (inValue: u32) -> u32 #foreign jolt_release "?CountBits@JPH@@YAII@Z";

/// Get the next higher power of 2 of a value, or the value itself if the value is already a power of 2
GetNextPowerOf2 :: (inValue: u32) -> u32 #foreign jolt_release "?GetNextPowerOf2@JPH@@YAII@Z";

/// Enum indicating which component to use when swizzling
SWIZZLE :: enum s32 {
    X      :: 0;
    Y      :: 1;
    Z      :: 2;
    W      :: 3;
    UNUSED :: 2;

    SWIZZLE_X      :: X;
    SWIZZLE_Y      :: Y;
    SWIZZLE_Z      :: Z;
    SWIZZLE_W      :: W;
    SWIZZLE_UNUSED :: UNUSED;
}

/// Sine of x (input in radians)
Sin :: (inX: float) -> float #foreign jolt_release "?Sin@JPH@@YAMM@Z";

/// Cosine of x (input in radians)
Cos :: (inX: float) -> float #foreign jolt_release "?Cos@JPH@@YAMM@Z";

/// Tangent of x (input in radians)
Tan :: (inX: float) -> float #foreign jolt_release "?Tan@JPH@@YAMM@Z";

/// Arc sine of x (returns value in the range [-PI / 2, PI / 2])
/// Note that all input values will be clamped to the range [-1, 1] and this function will not return NaNs like std::asin
ASin :: (inX: float) -> float #foreign jolt_release "?ASin@JPH@@YAMM@Z";

/// Arc cosine of x (returns value in the range [0, PI])
/// Note that all input values will be clamped to the range [-1, 1] and this function will not return NaNs like std::acos
ACos :: (inX: float) -> float #foreign jolt_release "?ACos@JPH@@YAMM@Z";

/// An approximation of ACos, max error is 4.2e-3 over the entire range [-1, 1], is approximately 2.5x faster than ACos
ACosApproximate :: (inX: float) -> float #foreign jolt_release "?ACosApproximate@JPH@@YAMM@Z";

/// Arc tangent of x (returns value in the range [-PI / 2, PI / 2])
ATan :: (inX: float) -> float #foreign jolt_release "?ATan@JPH@@YAMM@Z";

/// Simple variable length array backed by a fixed size buffer
StaticArray :: struct(T: Type, N: u32) {
    value_type :: T;

    size_type :: u32;

    Capacity:       u32 : N;

    const_iterator :: *T;

    iterator :: *T;

    Storage :: struct {
        using storage__raw:     Storage__RAW;
        #if size_of(Storage__RAW) == 0 {
            __empty_struct_padding: u8; // C++ makes empty structs have length 1
        }
    }
        // Storage without padding. Needed to generate a C++-equivalent struct layout when "inheriting" from Storage
    Storage__RAW :: struct {}

    mSize:          size_type = 0;
    mElements:      [N] Storage;
}

VertexList :: Array(Float3);

/// ID of a body. This is a way of reasoning about bodies in a multithreaded simulation while avoiding race conditions.
BodyID :: struct {
    cInvalidBodyID:       u32 : 4294967295; ///< The value for an invalid body ID
    cBroadPhaseBit:       u32 : 2147483648; ///< This bit is used by the broadphase
    cMaxBodyIndex:        u32 : 8388607; ///< Maximum value for body index (also the maximum amount of bodies supported - 1)
    cMaxSequenceNumber:   u8 : 255; ///< Maximum value for the sequence number
    cSequenceNumberShift: u32 : 23; ///< Number of bits to shift to get the sequence number

    /// Construct invalid body ID
    Constructor :: (this: *BodyID) -> void #cpp_method #foreign jolt_release "??0BodyID@JPH@@QEAA@XZ";

    /// Construct from index and sequence number combined in a single uint32 (use with care!)
    Constructor :: (this: *BodyID, inID: u32) -> void #cpp_method #foreign jolt_release "??0BodyID@JPH@@QEAA@I@Z";

    /// Construct from index and sequence number
    Constructor :: (this: *BodyID, inID: u32, inSequenceNumber: u8) -> void #cpp_method #foreign jolt_release "??0BodyID@JPH@@QEAA@IE@Z";

    /// Get index in body array
    GetIndex :: (this: *BodyID) -> u32 #cpp_method #foreign jolt_release "?GetIndex@BodyID@JPH@@QEBAIXZ";

    /// Returns the index and sequence number combined in an uint32
    GetIndexAndSequenceNumber :: (this: *BodyID) -> u32 #cpp_method #foreign jolt_release "?GetIndexAndSequenceNumber@BodyID@JPH@@QEBAIXZ";

    /// Check if the ID is valid
    IsInvalid :: (this: *BodyID) -> bool #cpp_method #foreign jolt_release "?IsInvalid@BodyID@JPH@@QEBA_NXZ";

    mID:                  u32;
}

/// Enum used by AddBody to determine if the body needs to be initially active
EActivation :: enum s32 {
    Activate     :: 0;
    DontActivate :: 1;
}

/// Class that makes another class non-copyable. Usage: Inherit from NonCopyable.
NonCopyable :: struct {
    using noncopyable__raw: NonCopyable__RAW;
    __empty_struct_padding: u8; // C++ makes empty structs have length 1
}
// NonCopyable without padding. Needed to generate a C++-equivalent struct layout when "inheriting" from NonCopyable
NonCopyable__RAW :: struct {}

ObjectLayer :: u16;

/// Constant value used to indicate an invalid object layer
cObjectLayerInvalid: ObjectLayer : ~0;

/// Filter class for object layers
ObjectLayerFilter :: struct {
    vtable:                 *ObjectLayerFilter_VTable;
    using noncopyable__raw: NonCopyable__RAW;
    #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Destructor
    virtual_Destructor :: (this: *ObjectLayerFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1ObjectLayerFilter@JPH@@UEAA@XZ";

    /// Function to filter out object layers when doing collision query test (return true to allow testing against objects with this layer)
    virtual_ShouldCollide :: (this: *ObjectLayerFilter, inLayer: ObjectLayer) -> bool #cpp_method #foreign jolt_release "?ShouldCollide@ObjectLayerFilter@JPH@@UEBA_NG@Z";
}
ObjectLayerFilter_VTable :: struct #type_info_none {
    Destructor:    #type (this: *ObjectLayerFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    ShouldCollide: #type (this: *ObjectLayerFilter, inLayer: ObjectLayer) -> bool #cpp_method;
}
ObjectLayerFilter_Destructor :: inline (this: *ObjectLayerFilter, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

ObjectLayerFilter_ShouldCollide :: inline (this: *ObjectLayerFilter, inLayer: ObjectLayer) -> bool { return this.vtable.ShouldCollide(this, inLayer); }

vtable :: (obj: *ObjectLayerFilter) -> *ObjectLayerFilter_VTable { return obj.vtable; }


/// Filter class to test if two objects can collide based on their object layer. Used while finding collision pairs.
ObjectLayerPairFilter :: struct {
    vtable:                 *ObjectLayerPairFilter_VTable;
    using noncopyable__raw: NonCopyable__RAW;
    #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}
ObjectLayerPairFilter_VTable :: struct #type_info_none {
    Destructor:    #type (this: *ObjectLayerPairFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    ShouldCollide: #type (this: *ObjectLayerPairFilter, inLayer1: ObjectLayer, inLayer2: ObjectLayer) -> bool #cpp_method;
}
ObjectLayerPairFilter_Destructor :: inline (this: *ObjectLayerPairFilter, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

ObjectLayerPairFilter_ShouldCollide :: inline (this: *ObjectLayerPairFilter, inLayer1: ObjectLayer, inLayer2: ObjectLayer) -> bool { return this.vtable.ShouldCollide(this, inLayer1, inLayer2); }

vtable :: (obj: *ObjectLayerPairFilter) -> *ObjectLayerPairFilter_VTable { return obj.vtable; }


/// Default filter class that uses the pair filter in combination with a specified layer to filter layers
DefaultObjectLayerFilter :: struct {
    #as using objectlayerfilter: ObjectLayerFilter;

    /// Constructor
    Constructor :: (this: *DefaultObjectLayerFilter, inObjectLayerPairFilter: *ObjectLayerPairFilter, inLayer: ObjectLayer) -> void #cpp_method #foreign jolt_release "??0DefaultObjectLayerFilter@JPH@@QEAA@AEBVObjectLayerPairFilter@1@G@Z";
    Constructor :: (this: *DefaultObjectLayerFilter, inObjectLayerPairFilter: ObjectLayerPairFilter, inLayer: ObjectLayer) #no_context {
        Constructor(this, *inObjectLayerPairFilter, inLayer);
    }

    mObjectLayerPairFilter:      *ObjectLayerPairFilter;
    mLayer:                      ObjectLayer;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    // See ObjectLayerFilter::ShouldCollide
    virtual_ShouldCollide :: (this: *DefaultObjectLayerFilter, inLayer: ObjectLayer) -> bool #cpp_method #foreign jolt_release "?ShouldCollide@DefaultObjectLayerFilter@JPH@@UEBA_NG@Z";
}

/// Allows objects from a specific layer only
SpecifiedObjectLayerFilter :: struct {
    #as using objectlayerfilter: ObjectLayerFilter;

    mLayer:                      ObjectLayer;
}

/// Motion type of a physics body
EMotionType :: enum u8 {
    Static    :: 0;
    Kinematic :: 1;
    Dynamic   :: 2;
}

/// Motion quality, or how well it detects collisions when it has a high velocity
EMotionQuality :: enum u8 {
    Discrete   :: 0;

    LinearCast :: 1;
}

/// Type of body
EBodyType :: enum u8 {
    RigidBody :: 0;
    SoftBody  :: 1;
}

/// How many types of bodies there are
cBodyTypeCount: u32 : 2;

/// Simple class to facilitate reference counting / releasing
/// Derive your class from RefTarget and you can reference it by using Ref<classname> or RefConst<classname>
///
/// Reference counting classes keep an integer which indicates how many references
/// to the object are active. Reference counting objects are derived from RefTarget
/// and staT & their life with a reference count of zero. They can then be assigned
/// to equivalents of pointers (Ref) which will increase the reference count immediately.
/// If the destructor of Ref is called or another object is assigned to the reference
/// counting pointer it will decrease the reference count of the object again. If this
/// reference count becomes zero, the object is destroyed.
///
/// This provides a very powerful mechanism to prevent memory leaks, but also gives
/// some responsibility to the programmer. The most notable point is that you cannot
/// have one object reference another and have the other reference the first one
/// back, because this way the reference count of both objects will never become
/// lower than 1, resulting in a memory leak. By carefully designing your classes
/// (and particularly identifying who owns who in the class hierarchy) you can avoid
/// these problems.
RefTarget :: struct(T: Type) {
    cEmbedded: u32 : 247389677; ///< A large value that gets added to the refcount to mark the object as embedded

    mRefCount: std.atomic(u32) = 0; ///< Current reference count
}

/// Pure virtual version of RefTarget
RefTargetVirtual :: struct {
    vtable: *RefTargetVirtual_VTable;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Virtual destructor
    virtual_Destructor :: (this: *RefTargetVirtual, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1RefTargetVirtual@JPH@@UEAA@XZ";
}
RefTargetVirtual_VTable :: struct #type_info_none {
    Destructor: #type (this: *RefTargetVirtual, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    AddRef:     #type (this: *RefTargetVirtual) -> void #cpp_method;

    Release:    #type (this: *RefTargetVirtual) -> void #cpp_method;
}
RefTargetVirtual_Destructor :: inline (this: *RefTargetVirtual, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

RefTargetVirtual_AddRef :: inline (this: *RefTargetVirtual) { this.vtable.AddRef(this); }

RefTargetVirtual_Release :: inline (this: *RefTargetVirtual) { this.vtable.Release(this); }

vtable :: (obj: *RefTargetVirtual) -> *RefTargetVirtual_VTable { return obj.vtable; }


// Forward declares
Ref :: struct(T: Type) {
    mPtr: *T; ///< Pointer to object that we are reference counting
}

/// Class for automatic referencing, this is the equivalent of a CONST pointer to type T
/// if you assign a value to this class it will increment the reference count by one
/// of this object, and if you assign something else it will decrease the reference
/// count of the first object again. If it reaches a reference count of zero it will
/// be deleted
RefConst :: struct(T: Type) {
    mPtr: *T; ///< Pointer to object that we are reference counting
}

// Classes
BodyCreationSettings :: struct {}
SoftBodyCreationSettings :: struct {}

TwoBodyConstraintSettings :: struct {}
TwoBodyConstraint :: struct {}

/// Class that provides operations on bodies using a body ID. Note that if you need to do multiple operations on a single body, it is more efficient to lock the body once and combine the operations.
/// All quantities are in world space unless otherwise specified.
BodyInterface :: struct {
    using noncopyable__raw: NonCopyable__RAW;

    /// Initialize the interface (should only be called by PhysicsSystem)
    Init :: (this: *BodyInterface, inBodyLockInterface: *BodyLockInterface, inBodyManager: *BodyManager, inBroadPhase: *BroadPhase) -> void #cpp_method #foreign jolt_release "?Init@BodyInterface@JPH@@QEAAXAEAVBodyLockInterface@2@AEAVBodyManager@2@AEAVBroadPhase@2@@Z";

    /// Create a rigid body
    /// @return Created body or null when out of bodies
    CreateBody :: (this: *BodyInterface, inSettings: *BodyCreationSettings) -> *Body #cpp_method #foreign jolt_release "?CreateBody@BodyInterface@JPH@@QEAAPEAVBody@2@AEBVBodyCreationSettings@2@@Z";
    CreateBody :: (this: *BodyInterface, inSettings: BodyCreationSettings) -> *Body #no_context {
        return CreateBody(this, *inSettings);
    }

    /// Create a soft body
    /// @return Created body or null when out of bodies
    CreateSoftBody :: (this: *BodyInterface, inSettings: *SoftBodyCreationSettings) -> *Body #cpp_method #foreign jolt_release "?CreateSoftBody@BodyInterface@JPH@@QEAAPEAVBody@2@AEBVSoftBodyCreationSettings@2@@Z";
    CreateSoftBody :: (this: *BodyInterface, inSettings: SoftBodyCreationSettings) -> *Body #no_context {
        return CreateSoftBody(this, *inSettings);
    }

    /// Create a rigid body with specified ID. This function can be used if a simulation is to run in sync between clients or if a simulation needs to be restored exactly.
    /// The ID created on the server can be replicated to the client and used to create a deterministic simulation.
    /// @return Created body or null when the body ID is invalid or a body of the same ID already exists.
    CreateBodyWithID :: (this: *BodyInterface, inBodyID: *BodyID, inSettings: *BodyCreationSettings) -> *Body #cpp_method #foreign jolt_release "?CreateBodyWithID@BodyInterface@JPH@@QEAAPEAVBody@2@AEBVBodyID@2@AEBVBodyCreationSettings@2@@Z";
    CreateBodyWithID :: (this: *BodyInterface, inBodyID: BodyID, inSettings: BodyCreationSettings) -> *Body #no_context {
        return CreateBodyWithID(this, *inBodyID, *inSettings);
    }

    /// Create a soft body with specified ID. See comments at CreateBodyWithID.
    CreateSoftBodyWithID :: (this: *BodyInterface, inBodyID: *BodyID, inSettings: *SoftBodyCreationSettings) -> *Body #cpp_method #foreign jolt_release "?CreateSoftBodyWithID@BodyInterface@JPH@@QEAAPEAVBody@2@AEBVBodyID@2@AEBVSoftBodyCreationSettings@2@@Z";
    CreateSoftBodyWithID :: (this: *BodyInterface, inBodyID: BodyID, inSettings: SoftBodyCreationSettings) -> *Body #no_context {
        return CreateSoftBodyWithID(this, *inBodyID, *inSettings);
    }

    /// Advanced use only. Creates a rigid body without specifying an ID. This body cannot be added to the physics system until it has been assigned a body ID.
    /// This can be used to decouple allocation from registering the body. A call to CreateBodyWithoutID followed by AssignBodyID is equivalent to calling CreateBodyWithID.
    /// @return Created body
    CreateBodyWithoutID :: (this: *BodyInterface, inSettings: *BodyCreationSettings) -> *Body #cpp_method #foreign jolt_release "?CreateBodyWithoutID@BodyInterface@JPH@@QEBAPEAVBody@2@AEBVBodyCreationSettings@2@@Z";
    CreateBodyWithoutID :: (this: *BodyInterface, inSettings: BodyCreationSettings) -> *Body #no_context {
        return CreateBodyWithoutID(this, *inSettings);
    }

    /// Advanced use only. Creates a body without specifying an ID. See comments at CreateBodyWithoutID.
    CreateSoftBodyWithoutID :: (this: *BodyInterface, inSettings: *SoftBodyCreationSettings) -> *Body #cpp_method #foreign jolt_release "?CreateSoftBodyWithoutID@BodyInterface@JPH@@QEBAPEAVBody@2@AEBVSoftBodyCreationSettings@2@@Z";
    CreateSoftBodyWithoutID :: (this: *BodyInterface, inSettings: SoftBodyCreationSettings) -> *Body #no_context {
        return CreateSoftBodyWithoutID(this, *inSettings);
    }

    /// Advanced use only. Destroy a body previously created with CreateBodyWithoutID that hasn't gotten an ID yet through the AssignBodyID function,
    /// or a body that has had its body ID unassigned through UnassignBodyIDs. Bodies that have an ID should be destroyed through DestroyBody.
    DestroyBodyWithoutID :: (this: *BodyInterface, inBody: *Body) -> void #cpp_method #foreign jolt_release "?DestroyBodyWithoutID@BodyInterface@JPH@@QEBAXPEAVBody@2@@Z";

    /// Advanced use only. Assigns the next available body ID to a body that was created using CreateBodyWithoutID. After this call, the body can be added to the physics system.
    /// @return false if the body already has an ID or out of body ids.
    AssignBodyID :: (this: *BodyInterface, ioBody: *Body) -> bool #cpp_method #foreign jolt_release "?AssignBodyID@BodyInterface@JPH@@QEAA_NPEAVBody@2@@Z";

    /// Advanced use only. Assigns a body ID to a body that was created using CreateBodyWithoutID. After this call, the body can be added to the physics system.
    /// @return false if the body already has an ID or if the ID is not valid.
    AssignBodyID :: (this: *BodyInterface, ioBody: *Body, inBodyID: *BodyID) -> bool #cpp_method #foreign jolt_release "?AssignBodyID@BodyInterface@JPH@@QEAA_NPEAVBody@2@AEBVBodyID@2@@Z";
    AssignBodyID :: (this: *BodyInterface, ioBody: *Body, inBodyID: BodyID) -> bool #no_context {
        return AssignBodyID(this, ioBody, *inBodyID);
    }

    /// Advanced use only. See UnassignBodyIDs. Unassigns the ID of a single body.
    UnassignBodyID :: (this: *BodyInterface, inBodyID: *BodyID) -> *Body #cpp_method #foreign jolt_release "?UnassignBodyID@BodyInterface@JPH@@QEAAPEAVBody@2@AEBVBodyID@2@@Z";
    UnassignBodyID :: (this: *BodyInterface, inBodyID: BodyID) -> *Body #no_context {
        return UnassignBodyID(this, *inBodyID);
    }

    /// Advanced use only. Removes a number of body IDs from their bodies and returns the body pointers. Before calling this, the body should have been removed from the physics system.
    /// The body can be destroyed through DestroyBodyWithoutID. This can be used to decouple deallocation. A call to UnassignBodyIDs followed by calls to DestroyBodyWithoutID is equivalent to calling DestroyBodies.
    /// @param inBodyIDs A list of body IDs
    /// @param inNumber Number of bodies in the list
    /// @param outBodies If not null on input, this will contain a list of body pointers corresponding to inBodyIDs that can be destroyed afterwards (caller assumes ownership over these).
    UnassignBodyIDs :: (this: *BodyInterface, inBodyIDs: *BodyID, inNumber: s32, outBodies: **Body) -> void #cpp_method #foreign jolt_release "?UnassignBodyIDs@BodyInterface@JPH@@QEAAXPEBVBodyID@2@HPEAPEAVBody@2@@Z";

    /// Destroy a body.
    /// Make sure that you remove the body from the physics system using BodyInterface::RemoveBody before calling this function.
    DestroyBody :: (this: *BodyInterface, inBodyID: *BodyID) -> void #cpp_method #foreign jolt_release "?DestroyBody@BodyInterface@JPH@@QEAAXAEBVBodyID@2@@Z";
    DestroyBody :: (this: *BodyInterface, inBodyID: BodyID) #no_context {
        DestroyBody(this, *inBodyID);
    }

    /// Destroy multiple bodies
    /// Make sure that you remove the bodies from the physics system using BodyInterface::RemoveBody before calling this function.
    DestroyBodies :: (this: *BodyInterface, inBodyIDs: *BodyID, inNumber: s32) -> void #cpp_method #foreign jolt_release "?DestroyBodies@BodyInterface@JPH@@QEAAXPEBVBodyID@2@H@Z";

    /// Add body to the physics system.
    /// Note that if you need to add multiple bodies, use the AddBodiesPrepare/AddBodiesFinalize function.
    /// Adding many bodies, one at a time, results in a really inefficient broadphase until PhysicsSystem::OptimizeBroadPhase is called or when PhysicsSystem::Update rebuilds the tree!
    /// After adding, to get a body by ID use the BodyLockRead or BodyLockWrite interface!
    AddBody :: (this: *BodyInterface, inBodyID: *BodyID, inActivationMode: EActivation) -> void #cpp_method #foreign jolt_release "?AddBody@BodyInterface@JPH@@QEAAXAEBVBodyID@2@W4EActivation@2@@Z";
    AddBody :: (this: *BodyInterface, inBodyID: BodyID, inActivationMode: EActivation) #no_context {
        AddBody(this, *inBodyID, inActivationMode);
    }

    /// Remove body from the physics system. Note that you need to add a body to the physics system before you can remove it.
    RemoveBody :: (this: *BodyInterface, inBodyID: *BodyID) -> void #cpp_method #foreign jolt_release "?RemoveBody@BodyInterface@JPH@@QEAAXAEBVBodyID@2@@Z";
    RemoveBody :: (this: *BodyInterface, inBodyID: BodyID) #no_context {
        RemoveBody(this, *inBodyID);
    }

    /// Check if a body has been added to the physics system.
    IsAdded :: (this: *BodyInterface, inBodyID: *BodyID) -> bool #cpp_method #foreign jolt_release "?IsAdded@BodyInterface@JPH@@QEBA_NAEBVBodyID@2@@Z";
    IsAdded :: (this: *BodyInterface, inBodyID: BodyID) -> bool #no_context {
        return IsAdded(this, *inBodyID);
    }

    /// Combines CreateBody and AddBody
    /// @return Created body ID or an invalid ID when out of bodies
    CreateAndAddBody :: (this: *BodyInterface, inSettings: *BodyCreationSettings, inActivationMode: EActivation) -> BodyID #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?CreateAndAddBody@BodyInterface@JPH@@QEAA?AVBodyID@2@AEBVBodyCreationSettings@2@W4EActivation@2@@Z";
    CreateAndAddBody :: (this: *BodyInterface, inSettings: BodyCreationSettings, inActivationMode: EActivation) -> BodyID #no_context {
        return CreateAndAddBody(this, *inSettings, inActivationMode);
    }

    /// Combines CreateSoftBody and AddBody
    /// @return Created body ID or an invalid ID when out of bodies
    CreateAndAddSoftBody :: (this: *BodyInterface, inSettings: *SoftBodyCreationSettings, inActivationMode: EActivation) -> BodyID #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?CreateAndAddSoftBody@BodyInterface@JPH@@QEAA?AVBodyID@2@AEBVSoftBodyCreationSettings@2@W4EActivation@2@@Z";
    CreateAndAddSoftBody :: (this: *BodyInterface, inSettings: SoftBodyCreationSettings, inActivationMode: EActivation) -> BodyID #no_context {
        return CreateAndAddSoftBody(this, *inSettings, inActivationMode);
    }

    /// Add state handle, used to keep track of a batch of bodies while adding them to the PhysicsSystem.
    AddState :: *void;

    /// Prepare adding inNumber bodies at ioBodies to the PhysicsSystem, returns a handle that should be used in AddBodiesFinalize/Abort.
    /// This can be done on a background thread without influencing the PhysicsSystem.
    /// ioBodies may be shuffled around by this function and should be kept that way until AddBodiesFinalize/Abort is called.
    AddBodiesPrepare :: (this: *BodyInterface, ioBodies: *BodyID, inNumber: s32) -> AddState #cpp_method #foreign jolt_release "?AddBodiesPrepare@BodyInterface@JPH@@QEAAPEAXPEAVBodyID@2@H@Z";

    /// Finalize adding bodies to the PhysicsSystem, supply the return value of AddBodiesPrepare in inAddState.
    /// Please ensure that the ioBodies array passed to AddBodiesPrepare is unmodified and passed again to this function.
    AddBodiesFinalize :: (this: *BodyInterface, ioBodies: *BodyID, inNumber: s32, inAddState: AddState, inActivationMode: EActivation) -> void #cpp_method #foreign jolt_release "?AddBodiesFinalize@BodyInterface@JPH@@QEAAXPEAVBodyID@2@HPEAXW4EActivation@2@@Z";

    /// Abort adding bodies to the PhysicsSystem, supply the return value of AddBodiesPrepare in inAddState.
    /// This can be done on a background thread without influencing the PhysicsSystem.
    /// Please ensure that the ioBodies array passed to AddBodiesPrepare is unmodified and passed again to this function.
    AddBodiesAbort :: (this: *BodyInterface, ioBodies: *BodyID, inNumber: s32, inAddState: AddState) -> void #cpp_method #foreign jolt_release "?AddBodiesAbort@BodyInterface@JPH@@QEAAXPEAVBodyID@2@HPEAX@Z";

    /// Remove inNumber bodies in ioBodies from the PhysicsSystem. Note that bodies need to be added to the physics system before they can be removed.
    /// ioBodies may be shuffled around by this function.
    RemoveBodies :: (this: *BodyInterface, ioBodies: *BodyID, inNumber: s32) -> void #cpp_method #foreign jolt_release "?RemoveBodies@BodyInterface@JPH@@QEAAXPEAVBodyID@2@H@Z";

    ///@name Activate / deactivate a body. Note that you need to add a body to the physics system before you can activate it.
    ///@{
    ActivateBody :: (this: *BodyInterface, inBodyID: *BodyID) -> void #cpp_method #foreign jolt_release "?ActivateBody@BodyInterface@JPH@@QEAAXAEBVBodyID@2@@Z";
    ActivateBody :: (this: *BodyInterface, inBodyID: BodyID) #no_context {
        ActivateBody(this, *inBodyID);
    }
    ActivateBodies :: (this: *BodyInterface, inBodyIDs: *BodyID, inNumber: s32) -> void #cpp_method #foreign jolt_release "?ActivateBodies@BodyInterface@JPH@@QEAAXPEBVBodyID@2@H@Z";
    ActivateBodiesInAABox :: (this: *BodyInterface, inBox: *AABox, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) -> void #cpp_method #foreign jolt_release "?ActivateBodiesInAABox@BodyInterface@JPH@@QEAAXAEBVAABox@2@AEBVBroadPhaseLayerFilter@2@AEBVObjectLayerFilter@2@@Z";
    ActivateBodiesInAABox :: (this: *BodyInterface, inBox: AABox, inBroadPhaseLayerFilter: BroadPhaseLayerFilter, inObjectLayerFilter: ObjectLayerFilter) #no_context {
        ActivateBodiesInAABox(this, *inBox, *inBroadPhaseLayerFilter, *inObjectLayerFilter);
    }
    DeactivateBody :: (this: *BodyInterface, inBodyID: *BodyID) -> void #cpp_method #foreign jolt_release "?DeactivateBody@BodyInterface@JPH@@QEAAXAEBVBodyID@2@@Z";
    DeactivateBody :: (this: *BodyInterface, inBodyID: BodyID) #no_context {
        DeactivateBody(this, *inBodyID);
    }
    DeactivateBodies :: (this: *BodyInterface, inBodyIDs: *BodyID, inNumber: s32) -> void #cpp_method #foreign jolt_release "?DeactivateBodies@BodyInterface@JPH@@QEAAXPEBVBodyID@2@H@Z";
    IsActive :: (this: *BodyInterface, inBodyID: *BodyID) -> bool #cpp_method #foreign jolt_release "?IsActive@BodyInterface@JPH@@QEBA_NAEBVBodyID@2@@Z";
    IsActive :: (this: *BodyInterface, inBodyID: BodyID) -> bool #no_context {
        return IsActive(this, *inBodyID);
    }
    ResetSleepTimer :: (this: *BodyInterface, inBodyID: *BodyID) -> void #cpp_method #foreign jolt_release "?ResetSleepTimer@BodyInterface@JPH@@QEAAXAEBVBodyID@2@@Z";
    ResetSleepTimer :: (this: *BodyInterface, inBodyID: BodyID) #no_context {
        ResetSleepTimer(this, *inBodyID);
    }

    /// Create a two body constraint
    CreateConstraint :: (this: *BodyInterface, inSettings: *TwoBodyConstraintSettings, inBodyID1: *BodyID, inBodyID2: *BodyID) -> *TwoBodyConstraint #cpp_method #foreign jolt_release "?CreateConstraint@BodyInterface@JPH@@QEAAPEAVTwoBodyConstraint@2@PEBVTwoBodyConstraintSettings@2@AEBVBodyID@2@1@Z";
    CreateConstraint :: (this: *BodyInterface, inSettings: *TwoBodyConstraintSettings, inBodyID1: BodyID, inBodyID2: BodyID) -> *TwoBodyConstraint #no_context {
        return CreateConstraint(this, inSettings, *inBodyID1, *inBodyID2);
    }

    /// Activate non-static bodies attached to a constraint.
    /// Note that the bodies involved in the constraint should be added to the physics system before activating a constraint.
    ActivateConstraint :: (this: *BodyInterface, inConstraint: *TwoBodyConstraint) -> void #cpp_method #foreign jolt_release "?ActivateConstraint@BodyInterface@JPH@@QEAAXPEBVTwoBodyConstraint@2@@Z";

    /// Get the current shape
    GetShape :: (this: *BodyInterface, inBodyID: *BodyID) -> RefConst(Shape) #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetShape@BodyInterface@JPH@@QEBA?AV?$RefConst@VShape@JPH@@@2@AEBVBodyID@2@@Z";
    GetShape :: (this: *BodyInterface, inBodyID: BodyID) -> RefConst(Shape) #no_context {
        return GetShape(this, *inBodyID);
    }

    /// Set a new shape on the body
    /// @param inBodyID Body ID of body that had its shape changed
    /// @param inShape The new shape
    /// @param inUpdateMassProperties When true, the mass and inertia tensor is recalculated
    /// @param inActivationMode Whether or not to activate the body
    SetShape :: (this: *BodyInterface, inBodyID: *BodyID, inShape: *Shape, inUpdateMassProperties: bool, inActivationMode: EActivation) -> void #cpp_method #foreign jolt_release "?SetShape@BodyInterface@JPH@@QEBAXAEBVBodyID@2@PEBVShape@2@_NW4EActivation@2@@Z";
    SetShape :: (this: *BodyInterface, inBodyID: BodyID, inShape: *Shape, inUpdateMassProperties: bool, inActivationMode: EActivation) #no_context {
        SetShape(this, *inBodyID, inShape, inUpdateMassProperties, inActivationMode);
    }

    /// Notify all systems to indicate that a shape has changed (usable for MutableCompoundShapes)
    /// @param inBodyID Body ID of body that had its shape changed
    /// @param inPreviousCenterOfMass Center of mass of the shape before the alterations
    /// @param inUpdateMassProperties When true, the mass and inertia tensor is recalculated
    /// @param inActivationMode Whether or not to activate the body
    NotifyShapeChanged :: (this: *BodyInterface, inBodyID: *BodyID, inPreviousCenterOfMass: Vec3, inUpdateMassProperties: bool, inActivationMode: EActivation) -> void #cpp_method #foreign jolt_release "?NotifyShapeChanged@BodyInterface@JPH@@QEBAXAEBVBodyID@2@VVec3@2@_NW4EActivation@2@@Z";
    NotifyShapeChanged :: (this: *BodyInterface, inBodyID: BodyID, inPreviousCenterOfMass: Vec3, inUpdateMassProperties: bool, inActivationMode: EActivation) #no_context {
        NotifyShapeChanged(this, *inBodyID, inPreviousCenterOfMass, inUpdateMassProperties, inActivationMode);
    }

    ///@name Object layer of a body
    ///@{
    SetObjectLayer :: (this: *BodyInterface, inBodyID: *BodyID, inLayer: ObjectLayer) -> void #cpp_method #foreign jolt_release "?SetObjectLayer@BodyInterface@JPH@@QEAAXAEBVBodyID@2@G@Z";
    SetObjectLayer :: (this: *BodyInterface, inBodyID: BodyID, inLayer: ObjectLayer) #no_context {
        SetObjectLayer(this, *inBodyID, inLayer);
    }
    GetObjectLayer :: (this: *BodyInterface, inBodyID: *BodyID) -> ObjectLayer #cpp_method #foreign jolt_release "?GetObjectLayer@BodyInterface@JPH@@QEBAGAEBVBodyID@2@@Z";
    GetObjectLayer :: (this: *BodyInterface, inBodyID: BodyID) -> ObjectLayer #no_context {
        return GetObjectLayer(this, *inBodyID);
    }

    ///@name Position and rotation of a body
    ///@{
    SetPositionAndRotation :: (this: *BodyInterface, inBodyID: *BodyID, inPosition: Vector3, inRotation: Quaternion, inActivationMode: EActivation) -> void #cpp_method #foreign jolt_release "?SetPositionAndRotation@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@VQuat@2@W4EActivation@2@@Z";
    SetPositionAndRotation :: (this: *BodyInterface, inBodyID: BodyID, inPosition: Vector3, inRotation: Quaternion, inActivationMode: EActivation) #no_context {
        SetPositionAndRotation(this, *inBodyID, inPosition, inRotation, inActivationMode);
    }
    SetPositionAndRotationWhenChanged :: (this: *BodyInterface, inBodyID: *BodyID, inPosition: Vector3, inRotation: Quaternion, inActivationMode: EActivation) -> void #cpp_method #foreign jolt_release "?SetPositionAndRotationWhenChanged@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@VQuat@2@W4EActivation@2@@Z";
    SetPositionAndRotationWhenChanged :: (this: *BodyInterface, inBodyID: BodyID, inPosition: Vector3, inRotation: Quaternion, inActivationMode: EActivation) #no_context {
        SetPositionAndRotationWhenChanged(this, *inBodyID, inPosition, inRotation, inActivationMode);
    }
    GetPositionAndRotation :: (this: *BodyInterface, inBodyID: *BodyID, outPosition: *Vec3, outRotation: *Quat) -> void #cpp_method #foreign jolt_release "?GetPositionAndRotation@BodyInterface@JPH@@QEBAXAEBVBodyID@2@AEAVVec3@2@AEAVQuat@2@@Z";
    GetPositionAndRotation :: (this: *BodyInterface, inBodyID: BodyID, outPosition: *Vec3, outRotation: *Quat) #no_context {
        GetPositionAndRotation(this, *inBodyID, outPosition, outRotation);
    }
    SetPosition :: (this: *BodyInterface, inBodyID: *BodyID, inPosition: Vector3, inActivationMode: EActivation) -> void #cpp_method #foreign jolt_release "?SetPosition@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@W4EActivation@2@@Z";
    SetPosition :: (this: *BodyInterface, inBodyID: BodyID, inPosition: Vector3, inActivationMode: EActivation) #no_context {
        SetPosition(this, *inBodyID, inPosition, inActivationMode);
    }
    GetPosition :: (this: *BodyInterface, inBodyID: *BodyID) -> Vec3 #cpp_method #foreign jolt_release "?GetPosition@BodyInterface@JPH@@QEBA?AVVec3@2@AEBVBodyID@2@@Z";
    GetPosition :: (this: *BodyInterface, inBodyID: BodyID) -> Vec3 #no_context {
        return GetPosition(this, *inBodyID);
    }
    GetCenterOfMassPosition :: (this: *BodyInterface, inBodyID: *BodyID) -> Vec3 #cpp_method #foreign jolt_release "?GetCenterOfMassPosition@BodyInterface@JPH@@QEBA?AVVec3@2@AEBVBodyID@2@@Z";
    GetCenterOfMassPosition :: (this: *BodyInterface, inBodyID: BodyID) -> Vec3 #no_context {
        return GetCenterOfMassPosition(this, *inBodyID);
    }
    SetRotation :: (this: *BodyInterface, inBodyID: *BodyID, inRotation: Quaternion, inActivationMode: EActivation) -> void #cpp_method #foreign jolt_release "?SetRotation@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VQuat@2@W4EActivation@2@@Z";
    SetRotation :: (this: *BodyInterface, inBodyID: BodyID, inRotation: Quaternion, inActivationMode: EActivation) #no_context {
        SetRotation(this, *inBodyID, inRotation, inActivationMode);
    }
    GetRotation :: (this: *BodyInterface, inBodyID: *BodyID) -> Quat #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetRotation@BodyInterface@JPH@@QEBA?AVQuat@2@AEBVBodyID@2@@Z";
    GetRotation :: (this: *BodyInterface, inBodyID: BodyID) -> Quat #no_context {
        return GetRotation(this, *inBodyID);
    }
    GetWorldTransform :: (this: *BodyInterface, inBodyID: *BodyID) -> Mat44 #cpp_method #foreign jolt_release "?GetWorldTransform@BodyInterface@JPH@@QEBA?AVMat44@2@AEBVBodyID@2@@Z";
    GetWorldTransform :: (this: *BodyInterface, inBodyID: BodyID) -> Mat44 #no_context {
        return GetWorldTransform(this, *inBodyID);
    }
    GetCenterOfMassTransform :: (this: *BodyInterface, inBodyID: *BodyID) -> Mat44 #cpp_method #foreign jolt_release "?GetCenterOfMassTransform@BodyInterface@JPH@@QEBA?AVMat44@2@AEBVBodyID@2@@Z";
    GetCenterOfMassTransform :: (this: *BodyInterface, inBodyID: BodyID) -> Mat44 #no_context {
        return GetCenterOfMassTransform(this, *inBodyID);
    }

    /// Set velocity of body such that it will be positioned at inTargetPosition/Rotation in inDeltaTime seconds (will activate body if needed)
    MoveKinematic :: (this: *BodyInterface, inBodyID: *BodyID, inTargetPosition: Vector3, inTargetRotation: Quaternion, inDeltaTime: float) -> void #cpp_method #foreign jolt_release "?MoveKinematic@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@VQuat@2@M@Z";
    MoveKinematic :: (this: *BodyInterface, inBodyID: BodyID, inTargetPosition: Vector3, inTargetRotation: Quaternion, inDeltaTime: float) #no_context {
        MoveKinematic(this, *inBodyID, inTargetPosition, inTargetRotation, inDeltaTime);
    }

    /// Linear or angular velocity (functions will activate body if needed).
    /// Note that the linear velocity is the velocity of the center of mass, which may not coincide with the position of your object, to correct for this: \f$VelocityCOM = Velocity - AngularVelocity \times ShapeCOM\f$
    SetLinearAndAngularVelocity :: (this: *BodyInterface, inBodyID: *BodyID, inLinearVelocity: Vec3, inAngularVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?SetLinearAndAngularVelocity@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@1@Z";
    SetLinearAndAngularVelocity :: (this: *BodyInterface, inBodyID: BodyID, inLinearVelocity: Vec3, inAngularVelocity: Vec3) #no_context {
        SetLinearAndAngularVelocity(this, *inBodyID, inLinearVelocity, inAngularVelocity);
    }
    GetLinearAndAngularVelocity :: (this: *BodyInterface, inBodyID: *BodyID, outLinearVelocity: *Vec3, outAngularVelocity: *Vec3) -> void #cpp_method #foreign jolt_release "?GetLinearAndAngularVelocity@BodyInterface@JPH@@QEBAXAEBVBodyID@2@AEAVVec3@2@1@Z";
    GetLinearAndAngularVelocity :: (this: *BodyInterface, inBodyID: BodyID, outLinearVelocity: *Vec3, outAngularVelocity: *Vec3) #no_context {
        GetLinearAndAngularVelocity(this, *inBodyID, outLinearVelocity, outAngularVelocity);
    }
    SetLinearVelocity :: (this: *BodyInterface, inBodyID: *BodyID, inLinearVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?SetLinearVelocity@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@@Z";
    SetLinearVelocity :: (this: *BodyInterface, inBodyID: BodyID, inLinearVelocity: Vec3) #no_context {
        SetLinearVelocity(this, *inBodyID, inLinearVelocity);
    }
    GetLinearVelocity :: (this: *BodyInterface, inBodyID: *BodyID) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetLinearVelocity@BodyInterface@JPH@@QEBA?AVVec3@2@AEBVBodyID@2@@Z";
    GetLinearVelocity :: (this: *BodyInterface, inBodyID: BodyID) -> Vec3 #no_context {
        return GetLinearVelocity(this, *inBodyID);
    }
    AddLinearVelocity :: (this: *BodyInterface, inBodyID: *BodyID, inLinearVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?AddLinearVelocity@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@@Z";
    AddLinearVelocity :: (this: *BodyInterface, inBodyID: BodyID, inLinearVelocity: Vec3) #no_context {
        AddLinearVelocity(this, *inBodyID, inLinearVelocity);
    }
    AddLinearAndAngularVelocity :: (this: *BodyInterface, inBodyID: *BodyID, inLinearVelocity: Vec3, inAngularVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?AddLinearAndAngularVelocity@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@1@Z";
    AddLinearAndAngularVelocity :: (this: *BodyInterface, inBodyID: BodyID, inLinearVelocity: Vec3, inAngularVelocity: Vec3) #no_context {
        AddLinearAndAngularVelocity(this, *inBodyID, inLinearVelocity, inAngularVelocity);
    }
    SetAngularVelocity :: (this: *BodyInterface, inBodyID: *BodyID, inAngularVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?SetAngularVelocity@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@@Z";
    SetAngularVelocity :: (this: *BodyInterface, inBodyID: BodyID, inAngularVelocity: Vec3) #no_context {
        SetAngularVelocity(this, *inBodyID, inAngularVelocity);
    }
    GetAngularVelocity :: (this: *BodyInterface, inBodyID: *BodyID) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetAngularVelocity@BodyInterface@JPH@@QEBA?AVVec3@2@AEBVBodyID@2@@Z";
    GetAngularVelocity :: (this: *BodyInterface, inBodyID: BodyID) -> Vec3 #no_context {
        return GetAngularVelocity(this, *inBodyID);
    }
    GetPointVelocity :: (this: *BodyInterface, inBodyID: *BodyID, inPoint: Vector3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetPointVelocity@BodyInterface@JPH@@QEBA?AVVec3@2@AEBVBodyID@2@V32@@Z";
    GetPointVelocity :: (this: *BodyInterface, inBodyID: BodyID, inPoint: Vector3) -> Vec3 #no_context {
        return GetPointVelocity(this, *inBodyID, inPoint);
    }

    /// Set the complete motion state of a body.
    /// Note that the linear velocity is the velocity of the center of mass, which may not coincide with the position of your object, to correct for this: \f$VelocityCOM = Velocity - AngularVelocity \times ShapeCOM\f$
    SetPositionRotationAndVelocity :: (this: *BodyInterface, inBodyID: *BodyID, inPosition: Vector3, inRotation: Quaternion, inLinearVelocity: Vec3, inAngularVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?SetPositionRotationAndVelocity@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@VQuat@2@11@Z";
    SetPositionRotationAndVelocity :: (this: *BodyInterface, inBodyID: BodyID, inPosition: Vector3, inRotation: Quaternion, inLinearVelocity: Vec3, inAngularVelocity: Vec3) #no_context {
        SetPositionRotationAndVelocity(this, *inBodyID, inPosition, inRotation, inLinearVelocity, inAngularVelocity);
    }

    ///@name Add forces to the body. Note that you should add a body to the physics system before applying forces or torques.
    ///@{
    AddForce :: (this: *BodyInterface, inBodyID: *BodyID, inForce: Vec3, inActivationMode: EActivation = .Activate) -> void #cpp_method #foreign jolt_release "?AddForce@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@W4EActivation@2@@Z";
    AddForce :: (this: *BodyInterface, inBodyID: BodyID, inForce: Vec3, inActivationMode: EActivation = .Activate) #no_context {
        AddForce(this, *inBodyID, inForce, inActivationMode);
    }
    AddForce :: (this: *BodyInterface, inBodyID: *BodyID, inForce: Vec3, inPoint: Vector3, inActivationMode: EActivation = .Activate) -> void #cpp_method #foreign jolt_release "?AddForce@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@1W4EActivation@2@@Z";
    AddForce :: (this: *BodyInterface, inBodyID: BodyID, inForce: Vec3, inPoint: Vector3, inActivationMode: EActivation = .Activate) #no_context {
        AddForce(this, *inBodyID, inForce, inPoint, inActivationMode);
    }
    AddTorque :: (this: *BodyInterface, inBodyID: *BodyID, inTorque: Vec3, inActivationMode: EActivation = .Activate) -> void #cpp_method #foreign jolt_release "?AddTorque@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@W4EActivation@2@@Z";
    AddTorque :: (this: *BodyInterface, inBodyID: BodyID, inTorque: Vec3, inActivationMode: EActivation = .Activate) #no_context {
        AddTorque(this, *inBodyID, inTorque, inActivationMode);
    }
    AddForceAndTorque :: (this: *BodyInterface, inBodyID: *BodyID, inForce: Vec3, inTorque: Vec3, inActivationMode: EActivation = .Activate) -> void #cpp_method #foreign jolt_release "?AddForceAndTorque@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@1W4EActivation@2@@Z";
    AddForceAndTorque :: (this: *BodyInterface, inBodyID: BodyID, inForce: Vec3, inTorque: Vec3, inActivationMode: EActivation = .Activate) #no_context {
        AddForceAndTorque(this, *inBodyID, inForce, inTorque, inActivationMode);
    }

    ///@name Add an impulse to the body. Note that you should add a body to the physics system before applying impulses.
    ///@{
    AddImpulse :: (this: *BodyInterface, inBodyID: *BodyID, inImpulse: Vec3) -> void #cpp_method #foreign jolt_release "?AddImpulse@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@@Z";
    AddImpulse :: (this: *BodyInterface, inBodyID: BodyID, inImpulse: Vec3) #no_context {
        AddImpulse(this, *inBodyID, inImpulse);
    }
    AddImpulse :: (this: *BodyInterface, inBodyID: *BodyID, inImpulse: Vec3, inPoint: Vector3) -> void #cpp_method #foreign jolt_release "?AddImpulse@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@1@Z";
    AddImpulse :: (this: *BodyInterface, inBodyID: BodyID, inImpulse: Vec3, inPoint: Vector3) #no_context {
        AddImpulse(this, *inBodyID, inImpulse, inPoint);
    }
    AddAngularImpulse :: (this: *BodyInterface, inBodyID: *BodyID, inAngularImpulse: Vec3) -> void #cpp_method #foreign jolt_release "?AddAngularImpulse@BodyInterface@JPH@@QEAAXAEBVBodyID@2@VVec3@2@@Z";
    AddAngularImpulse :: (this: *BodyInterface, inBodyID: BodyID, inAngularImpulse: Vec3) #no_context {
        AddAngularImpulse(this, *inBodyID, inAngularImpulse);
    }
    ApplyBuoyancyImpulse :: (this: *BodyInterface, inBodyID: *BodyID, inSurfacePosition: Vector3, inSurfaceNormal: Vec3, inBuoyancy: float, inLinearDrag: float, inAngularDrag: float, inFluidVelocity: Vec3, inGravity: Vec3, inDeltaTime: float) -> bool #cpp_method #foreign jolt_release "?ApplyBuoyancyImpulse@BodyInterface@JPH@@QEAA_NAEBVBodyID@2@VVec3@2@1MMM11M@Z";
    ApplyBuoyancyImpulse :: (this: *BodyInterface, inBodyID: BodyID, inSurfacePosition: Vector3, inSurfaceNormal: Vec3, inBuoyancy: float, inLinearDrag: float, inAngularDrag: float, inFluidVelocity: Vec3, inGravity: Vec3, inDeltaTime: float) -> bool #no_context {
        return ApplyBuoyancyImpulse(this, *inBodyID, inSurfacePosition, inSurfaceNormal, inBuoyancy, inLinearDrag, inAngularDrag, inFluidVelocity, inGravity, inDeltaTime);
    }

    ///@name Body type
    ///@{
    GetBodyType :: (this: *BodyInterface, inBodyID: *BodyID) -> EBodyType #cpp_method #foreign jolt_release "?GetBodyType@BodyInterface@JPH@@QEBA?AW4EBodyType@2@AEBVBodyID@2@@Z";
    GetBodyType :: (this: *BodyInterface, inBodyID: BodyID) -> EBodyType #no_context {
        return GetBodyType(this, *inBodyID);
    }

    ///@name Body motion type
    ///@{
    SetMotionType :: (this: *BodyInterface, inBodyID: *BodyID, inMotionType: EMotionType, inActivationMode: EActivation) -> void #cpp_method #foreign jolt_release "?SetMotionType@BodyInterface@JPH@@QEAAXAEBVBodyID@2@W4EMotionType@2@W4EActivation@2@@Z";
    SetMotionType :: (this: *BodyInterface, inBodyID: BodyID, inMotionType: EMotionType, inActivationMode: EActivation) #no_context {
        SetMotionType(this, *inBodyID, inMotionType, inActivationMode);
    }
    GetMotionType :: (this: *BodyInterface, inBodyID: *BodyID) -> EMotionType #cpp_method #foreign jolt_release "?GetMotionType@BodyInterface@JPH@@QEBA?AW4EMotionType@2@AEBVBodyID@2@@Z";
    GetMotionType :: (this: *BodyInterface, inBodyID: BodyID) -> EMotionType #no_context {
        return GetMotionType(this, *inBodyID);
    }

    ///@name Body motion quality
    ///@{
    SetMotionQuality :: (this: *BodyInterface, inBodyID: *BodyID, inMotionQuality: EMotionQuality) -> void #cpp_method #foreign jolt_release "?SetMotionQuality@BodyInterface@JPH@@QEAAXAEBVBodyID@2@W4EMotionQuality@2@@Z";
    SetMotionQuality :: (this: *BodyInterface, inBodyID: BodyID, inMotionQuality: EMotionQuality) #no_context {
        SetMotionQuality(this, *inBodyID, inMotionQuality);
    }
    GetMotionQuality :: (this: *BodyInterface, inBodyID: *BodyID) -> EMotionQuality #cpp_method #foreign jolt_release "?GetMotionQuality@BodyInterface@JPH@@QEBA?AW4EMotionQuality@2@AEBVBodyID@2@@Z";
    GetMotionQuality :: (this: *BodyInterface, inBodyID: BodyID) -> EMotionQuality #no_context {
        return GetMotionQuality(this, *inBodyID);
    }

    /// Get inverse inertia tensor in world space
    GetInverseInertia :: (this: *BodyInterface, inBodyID: *BodyID) -> Mat44 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetInverseInertia@BodyInterface@JPH@@QEBA?AVMat44@2@AEBVBodyID@2@@Z";
    GetInverseInertia :: (this: *BodyInterface, inBodyID: BodyID) -> Mat44 #no_context {
        return GetInverseInertia(this, *inBodyID);
    }

    ///@name Restitution
    ///@{
    SetRestitution :: (this: *BodyInterface, inBodyID: *BodyID, inRestitution: float) -> void #cpp_method #foreign jolt_release "?SetRestitution@BodyInterface@JPH@@QEAAXAEBVBodyID@2@M@Z";
    SetRestitution :: (this: *BodyInterface, inBodyID: BodyID, inRestitution: float) #no_context {
        SetRestitution(this, *inBodyID, inRestitution);
    }
    GetRestitution :: (this: *BodyInterface, inBodyID: *BodyID) -> float #cpp_method #foreign jolt_release "?GetRestitution@BodyInterface@JPH@@QEBAMAEBVBodyID@2@@Z";
    GetRestitution :: (this: *BodyInterface, inBodyID: BodyID) -> float #no_context {
        return GetRestitution(this, *inBodyID);
    }

    ///@name Friction
    ///@{
    SetFriction :: (this: *BodyInterface, inBodyID: *BodyID, inFriction: float) -> void #cpp_method #foreign jolt_release "?SetFriction@BodyInterface@JPH@@QEAAXAEBVBodyID@2@M@Z";
    SetFriction :: (this: *BodyInterface, inBodyID: BodyID, inFriction: float) #no_context {
        SetFriction(this, *inBodyID, inFriction);
    }
    GetFriction :: (this: *BodyInterface, inBodyID: *BodyID) -> float #cpp_method #foreign jolt_release "?GetFriction@BodyInterface@JPH@@QEBAMAEBVBodyID@2@@Z";
    GetFriction :: (this: *BodyInterface, inBodyID: BodyID) -> float #no_context {
        return GetFriction(this, *inBodyID);
    }

    ///@name Gravity factor
    ///@{
    SetGravityFactor :: (this: *BodyInterface, inBodyID: *BodyID, inGravityFactor: float) -> void #cpp_method #foreign jolt_release "?SetGravityFactor@BodyInterface@JPH@@QEAAXAEBVBodyID@2@M@Z";
    SetGravityFactor :: (this: *BodyInterface, inBodyID: BodyID, inGravityFactor: float) #no_context {
        SetGravityFactor(this, *inBodyID, inGravityFactor);
    }
    GetGravityFactor :: (this: *BodyInterface, inBodyID: *BodyID) -> float #cpp_method #foreign jolt_release "?GetGravityFactor@BodyInterface@JPH@@QEBAMAEBVBodyID@2@@Z";
    GetGravityFactor :: (this: *BodyInterface, inBodyID: BodyID) -> float #no_context {
        return GetGravityFactor(this, *inBodyID);
    }

    ///@name Max linear velocity
    ///@{
    SetMaxLinearVelocity :: (this: *BodyInterface, inBodyID: *BodyID, inLinearVelocity: float) -> void #cpp_method #foreign jolt_release "?SetMaxLinearVelocity@BodyInterface@JPH@@QEAAXAEBVBodyID@2@M@Z";
    SetMaxLinearVelocity :: (this: *BodyInterface, inBodyID: BodyID, inLinearVelocity: float) #no_context {
        SetMaxLinearVelocity(this, *inBodyID, inLinearVelocity);
    }
    GetMaxLinearVelocity :: (this: *BodyInterface, inBodyID: *BodyID) -> float #cpp_method #foreign jolt_release "?GetMaxLinearVelocity@BodyInterface@JPH@@QEBAMAEBVBodyID@2@@Z";
    GetMaxLinearVelocity :: (this: *BodyInterface, inBodyID: BodyID) -> float #no_context {
        return GetMaxLinearVelocity(this, *inBodyID);
    }

    ///@name Max angular velocity
    ///@{
    SetMaxAngularVelocity :: (this: *BodyInterface, inBodyID: *BodyID, inAngularVelocity: float) -> void #cpp_method #foreign jolt_release "?SetMaxAngularVelocity@BodyInterface@JPH@@QEAAXAEBVBodyID@2@M@Z";
    SetMaxAngularVelocity :: (this: *BodyInterface, inBodyID: BodyID, inAngularVelocity: float) #no_context {
        SetMaxAngularVelocity(this, *inBodyID, inAngularVelocity);
    }
    GetMaxAngularVelocity :: (this: *BodyInterface, inBodyID: *BodyID) -> float #cpp_method #foreign jolt_release "?GetMaxAngularVelocity@BodyInterface@JPH@@QEBAMAEBVBodyID@2@@Z";
    GetMaxAngularVelocity :: (this: *BodyInterface, inBodyID: BodyID) -> float #no_context {
        return GetMaxAngularVelocity(this, *inBodyID);
    }

    ///@name Manifold reduction
    ///@{
    SetUseManifoldReduction :: (this: *BodyInterface, inBodyID: *BodyID, inUseReduction: bool) -> void #cpp_method #foreign jolt_release "?SetUseManifoldReduction@BodyInterface@JPH@@QEAAXAEBVBodyID@2@_N@Z";
    SetUseManifoldReduction :: (this: *BodyInterface, inBodyID: BodyID, inUseReduction: bool) #no_context {
        SetUseManifoldReduction(this, *inBodyID, inUseReduction);
    }
    GetUseManifoldReduction :: (this: *BodyInterface, inBodyID: *BodyID) -> bool #cpp_method #foreign jolt_release "?GetUseManifoldReduction@BodyInterface@JPH@@QEBA_NAEBVBodyID@2@@Z";
    GetUseManifoldReduction :: (this: *BodyInterface, inBodyID: BodyID) -> bool #no_context {
        return GetUseManifoldReduction(this, *inBodyID);
    }

    ///@name Sensor
    ///@{
    SetIsSensor :: (this: *BodyInterface, inBodyID: *BodyID, inIsSensor: bool) -> void #cpp_method #foreign jolt_release "?SetIsSensor@BodyInterface@JPH@@QEAAXAEBVBodyID@2@_N@Z";
    SetIsSensor :: (this: *BodyInterface, inBodyID: BodyID, inIsSensor: bool) #no_context {
        SetIsSensor(this, *inBodyID, inIsSensor);
    }
    IsSensor :: (this: *BodyInterface, inBodyID: *BodyID) -> bool #cpp_method #foreign jolt_release "?IsSensor@BodyInterface@JPH@@QEBA_NAEBVBodyID@2@@Z";
    IsSensor :: (this: *BodyInterface, inBodyID: BodyID) -> bool #no_context {
        return IsSensor(this, *inBodyID);
    }

    ///@name Collision group
    ///@{
    SetCollisionGroup :: (this: *BodyInterface, inBodyID: *BodyID, inCollisionGroup: *CollisionGroup) -> void #cpp_method #foreign jolt_release "?SetCollisionGroup@BodyInterface@JPH@@QEAAXAEBVBodyID@2@AEBVCollisionGroup@2@@Z";
    SetCollisionGroup :: (this: *BodyInterface, inBodyID: BodyID, inCollisionGroup: CollisionGroup) #no_context {
        SetCollisionGroup(this, *inBodyID, *inCollisionGroup);
    }
    GetCollisionGroup :: (this: *BodyInterface, inBodyID: *BodyID) -> *CollisionGroup #cpp_method #foreign jolt_release "?GetCollisionGroup@BodyInterface@JPH@@QEBAAEBVCollisionGroup@2@AEBVBodyID@2@@Z";
    GetCollisionGroup :: (this: *BodyInterface, inBodyID: BodyID) -> *CollisionGroup #no_context {
        return GetCollisionGroup(this, *inBodyID);
    }

    /// Get transform and shape for this body, used to perform collision detection
    GetTransformedShape :: (this: *BodyInterface, inBodyID: *BodyID) -> TransformedShape #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetTransformedShape@BodyInterface@JPH@@QEBA?AVTransformedShape@2@AEBVBodyID@2@@Z";
    GetTransformedShape :: (this: *BodyInterface, inBodyID: BodyID) -> TransformedShape #no_context {
        return GetTransformedShape(this, *inBodyID);
    }

    /// Get the user data for a body
    GetUserData :: (this: *BodyInterface, inBodyID: *BodyID) -> u64 #cpp_method #foreign jolt_release "?GetUserData@BodyInterface@JPH@@QEBA_KAEBVBodyID@2@@Z";
    GetUserData :: (this: *BodyInterface, inBodyID: BodyID) -> u64 #no_context {
        return GetUserData(this, *inBodyID);
    }
    SetUserData :: (this: *BodyInterface, inBodyID: *BodyID, inUserData: u64) -> void #cpp_method #foreign jolt_release "?SetUserData@BodyInterface@JPH@@QEBAXAEBVBodyID@2@_K@Z";
    SetUserData :: (this: *BodyInterface, inBodyID: BodyID, inUserData: u64) #no_context {
        SetUserData(this, *inBodyID, inUserData);
    }

    /// Get the material for a particular sub shape
    GetMaterial :: (this: *BodyInterface, inBodyID: *BodyID, inSubShapeID: *SubShapeID) -> *PhysicsMaterial #cpp_method #foreign jolt_release "?GetMaterial@BodyInterface@JPH@@QEBAPEBVPhysicsMaterial@2@AEBVBodyID@2@AEBVSubShapeID@2@@Z";
    GetMaterial :: (this: *BodyInterface, inBodyID: BodyID, inSubShapeID: SubShapeID) -> *PhysicsMaterial #no_context {
        return GetMaterial(this, *inBodyID, *inSubShapeID);
    }

    /// Set the Body::EFlags::InvalidateContactCache flag for the specified body. This means that the collision cache is invalid for any body pair involving that body until the next physics step.
    InvalidateContactCache :: (this: *BodyInterface, inBodyID: *BodyID) -> void #cpp_method #foreign jolt_release "?InvalidateContactCache@BodyInterface@JPH@@QEAAXAEBVBodyID@2@@Z";
    InvalidateContactCache :: (this: *BodyInterface, inBodyID: BodyID) #no_context {
        InvalidateContactCache(this, *inBodyID);
    }

    /// Helper function to activate a single body
    ActivateBodyInternal :: (this: *BodyInterface, ioBody: *Body) -> void #cpp_method #foreign jolt_release "?ActivateBodyInternal@BodyInterface@JPH@@AEBAXAEAVBody@2@@Z";

    mBodyLockInterface:     *BodyLockInterface = null;
    mBodyManager:           *BodyManager = null;
    mBroadPhase:            *BroadPhase = null;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// Class function to filter out bodies, returns true if test should collide with body
BodyFilter :: struct {
    vtable:                 *BodyFilter_VTable;
    using noncopyable__raw: NonCopyable__RAW;
    #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Destructor
    virtual_Destructor :: (this: *BodyFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1BodyFilter@JPH@@UEAA@XZ";

    /// Filter function. Returns true if we should collide with inBodyID
    virtual_ShouldCollide :: (this: *BodyFilter, inBodyID: *BodyID) -> bool #cpp_method #foreign jolt_release "?ShouldCollide@BodyFilter@JPH@@UEBA_NAEBVBodyID@2@@Z";

    /// Filter function. Returns true if we should collide with inBody (this is called after the body is locked and makes it possible to filter based on body members)
    virtual_ShouldCollideLocked :: (this: *BodyFilter, inBody: *Body) -> bool #cpp_method #foreign jolt_release "?ShouldCollideLocked@BodyFilter@JPH@@UEBA_NAEBVBody@2@@Z";
}
BodyFilter_VTable :: struct #type_info_none {
    Destructor:          #type (this: *BodyFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    ShouldCollide:       #type (this: *BodyFilter, inBodyID: *BodyID) -> bool #cpp_method;

    ShouldCollideLocked: #type (this: *BodyFilter, inBody: *Body) -> bool #cpp_method;
}
BodyFilter_Destructor :: inline (this: *BodyFilter, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

BodyFilter_ShouldCollide :: inline (this: *BodyFilter, inBodyID: *BodyID) -> bool { return this.vtable.ShouldCollide(this, inBodyID); }

BodyFilter_ShouldCollideLocked :: inline (this: *BodyFilter, inBody: *Body) -> bool { return this.vtable.ShouldCollideLocked(this, inBody); }

vtable :: (obj: *BodyFilter) -> *BodyFilter_VTable { return obj.vtable; }


/// A simple body filter implementation that ignores a single, specified body
IgnoreSingleBodyFilter :: struct {
    #as using bodyfilter: BodyFilter;

    /// Constructor, pass the body you want to ignore
    Constructor :: (this: *IgnoreSingleBodyFilter, inBodyID: *BodyID) -> void #cpp_method #foreign jolt_release "??0IgnoreSingleBodyFilter@JPH@@QEAA@AEBVBodyID@1@@Z";
    Constructor :: (this: *IgnoreSingleBodyFilter, inBodyID: BodyID) #no_context {
        Constructor(this, *inBodyID);
    }

    mBodyID:              BodyID;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Filter function. Returns true if we should collide with inBodyID
    virtual_ShouldCollide :: (this: *IgnoreSingleBodyFilter, inBodyID: *BodyID) -> bool #cpp_method #foreign jolt_release "?ShouldCollide@IgnoreSingleBodyFilter@JPH@@UEBA_NAEBVBodyID@2@@Z";
}

/// A simple body filter implementation that ignores multiple, specified bodies
IgnoreMultipleBodiesFilter :: struct {
    #as using bodyfilter: BodyFilter;

    mBodyIDs:             Array(BodyID);
}

/// Ignores a single body and chains the filter to another filter
IgnoreSingleBodyFilterChained :: struct {
    #as using bodyfilter: BodyFilter;

    /// Constructor
    Constructor :: (this: *IgnoreSingleBodyFilterChained, inBodyID: BodyID, inFilter: *BodyFilter) -> void #cpp_method #foreign jolt_release "??0IgnoreSingleBodyFilterChained@JPH@@QEAA@VBodyID@1@AEBVBodyFilter@1@@Z";
    Constructor :: (this: *IgnoreSingleBodyFilterChained, inBodyID: BodyID, inFilter: BodyFilter) #no_context {
        Constructor(this, inBodyID, *inFilter);
    }

    mBodyID:              BodyID;
    mFilter:              *BodyFilter;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Filter function. Returns true if we should collide with inBodyID
    virtual_ShouldCollide :: (this: *IgnoreSingleBodyFilterChained, inBodyID: *BodyID) -> bool #cpp_method #foreign jolt_release "?ShouldCollide@IgnoreSingleBodyFilterChained@JPH@@UEBA_NAEBVBodyID@2@@Z";

    /// Filter function. Returns true if we should collide with inBody (this is called after the body is locked and makes it possible to filter based on body members)
    virtual_ShouldCollideLocked :: (this: *IgnoreSingleBodyFilterChained, inBody: *Body) -> bool #cpp_method #foreign jolt_release "?ShouldCollideLocked@IgnoreSingleBodyFilterChained@JPH@@UEBA_NAEBVBody@2@@Z";
}

/// A simple triangle and its material
Triangle :: struct {
    /// Constructor
    Constructor :: (this: *Triangle) -> void #cpp_method #foreign jolt_release "??0Triangle@JPH@@QEAA@XZ";

    /// Vertices
    mV:             [3] Float3;
    mMaterialIndex: u32 = 0; ///< Follows mV[3] so that we can read mV as 4 vectors
    mUserData:      u32 = 0; ///< User data that can be used for anything by the application, e.g. for tracking the original index of the triangle
}

TriangleList :: Array(Triangle);

/// Triangle with 32-bit indices
IndexedTriangleNoMaterial :: struct {
    Constructor :: (this: *IndexedTriangleNoMaterial, inI1: u32, inI2: u32, inI3: u32) -> void #cpp_method #foreign jolt_release "??0IndexedTriangleNoMaterial@JPH@@QEAA@III@Z";

    /// Check if triangle is degenerate
    IsDegenerate :: (this: *IndexedTriangleNoMaterial, inVertices: *VertexList) -> bool #cpp_method #foreign jolt_release "?IsDegenerate@IndexedTriangleNoMaterial@JPH@@QEBA_NAEBV?$Array@VFloat3@JPH@@V?$STLAllocator@VFloat3@JPH@@@2@@2@@Z";
    IsDegenerate :: (this: *IndexedTriangleNoMaterial, inVertices: VertexList) -> bool #no_context {
        return IsDegenerate(this, *inVertices);
    }

    /// Get center of triangle
    GetCentroid :: (this: *IndexedTriangleNoMaterial, inVertices: *VertexList) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetCentroid@IndexedTriangleNoMaterial@JPH@@QEBA?AVVec3@2@AEBV?$Array@VFloat3@JPH@@V?$STLAllocator@VFloat3@JPH@@@2@@2@@Z";
    GetCentroid :: (this: *IndexedTriangleNoMaterial, inVertices: VertexList) -> Vec3 #no_context {
        return GetCentroid(this, *inVertices);
    }

    mIdx: [3] u32;
}

/// Triangle with 32-bit indices and material index
IndexedTriangle :: struct {
    #as using indexedtrianglenomaterial: IndexedTriangleNoMaterial;

    /// Constructor
    Constructor :: (this: *IndexedTriangle, inI1: u32, inI2: u32, inI3: u32, inMaterialIndex: u32, inUserData: u32 = 0) -> void #cpp_method #foreign jolt_release "??0IndexedTriangle@JPH@@QEAA@IIIII@Z";

    /// Rotate the vertices so that the lowest vertex becomes the first. This does not change the represented triangle.
    GetLowestIndexFirst :: (this: *IndexedTriangle) -> IndexedTriangle #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetLowestIndexFirst@IndexedTriangle@JPH@@QEBA?AV12@XZ";

    /// Get the hash value of this structure
    GetHash :: (this: *IndexedTriangle) -> u64 #cpp_method #foreign jolt_release "?GetHash@IndexedTriangle@JPH@@QEBA_KXZ";

    mMaterialIndex:                      u32 = 0;
    mUserData:                           u32 = 0; ///< User data that can be used for anything by the application, e.g. for tracking the original index of the triangle
}

IndexedTriangleNoMaterialList :: Array(IndexedTriangleNoMaterial);
IndexedTriangleList :: Array(IndexedTriangle);

/// An infinite plane described by the formula X . Normal + Constant = 0.
Plane :: struct {
    Constructor :: (this: *Plane, inNormalAndConstant: Vec4) -> void #cpp_method #foreign jolt_release "??0Plane@JPH@@QEAA@VVec4@1@@Z";
    Constructor :: (this: *Plane, inNormal: Vec3, inConstant: float) -> void #cpp_method #foreign jolt_release "??0Plane@JPH@@QEAA@VVec3@1@M@Z";

    /// Create from point and normal
    sFromPointAndNormal :: (inPoint: Vec3, inNormal: Vec3) -> Plane #cpp_return_type_is_non_pod #foreign jolt_release "?sFromPointAndNormal@Plane@JPH@@SA?AV12@VVec3@2@0@Z";

    /// Create from 3 counter clockwise points
    sFromPointsCCW :: (inV1: Vec3, inV2: Vec3, inV3: Vec3) -> Plane #cpp_return_type_is_non_pod #foreign jolt_release "?sFromPointsCCW@Plane@JPH@@SA?AV12@VVec3@2@00@Z";

    // Properties
    GetNormal :: (this: *Plane) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetNormal@Plane@JPH@@QEBA?AVVec3@2@XZ";
    SetNormal :: (this: *Plane, inNormal: Vec3) -> void #cpp_method #foreign jolt_release "?SetNormal@Plane@JPH@@QEAAXVVec3@2@@Z";
    GetConstant :: (this: *Plane) -> float #cpp_method #foreign jolt_release "?GetConstant@Plane@JPH@@QEBAMXZ";

    /// Offset the plane (positive value means move it in the direction of the plane normal)
    Offset :: (this: *Plane, inDistance: float) -> Plane #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?Offset@Plane@JPH@@QEBA?AV12@M@Z";

    /// Transform the plane by a matrix
    GetTransformed :: (this: *Plane, inTransform: *Mat44) -> Plane #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetTransformed@Plane@JPH@@QEBA?AV12@AEBVMat44@2@@Z";

    /// Scale the plane, can handle non-uniform and negative scaling
    Scaled :: (this: *Plane, inScale: Vec3) -> Plane #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?Scaled@Plane@JPH@@QEBA?AV12@VVec3@2@@Z";

    /// Distance point to plane
    SignedDistance :: (this: *Plane, inPoint: Vec3) -> float #cpp_method #foreign jolt_release "?SignedDistance@Plane@JPH@@QEBAMVVec3@2@@Z";

    /// Project inPoint onto the plane
    ProjectPointOnPlane :: (this: *Plane, inPoint: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?ProjectPointOnPlane@Plane@JPH@@QEBA?AVVec3@2@V32@@Z";

    /// Returns intersection point between 3 planes
    sIntersectPlanes :: (inP1: *Plane, inP2: *Plane, inP3: *Plane, outPoint: *Vec3) -> bool #foreign jolt_release "?sIntersectPlanes@Plane@JPH@@SA_NAEBV12@00AEAVVec3@2@@Z";
    sIntersectPlanes :: (inP1: Plane, inP2: Plane, inP3: Plane, outPoint: *Vec3) -> bool #no_context {
        return sIntersectPlanes(*inP1, *inP2, *inP3, outPoint);
    }

    mNormalAndConstant: Vec4; ///< XYZ = normal, W = constant, plane: x . normal + constant = 0
}

/// Axis aligned box
AABox :: struct {
    /// Constructor
    Constructor :: (this: *AABox) -> void #cpp_method #foreign jolt_release "??0AABox@JPH@@QEAA@XZ";
    Constructor :: (this: *AABox, inMin: Vec3, inMax: Vec3) -> void #cpp_method #foreign jolt_release "??0AABox@JPH@@QEAA@VVec3@1@0@Z";

    /// Create box from 2 points
    sFromTwoPoints :: (inP1: Vec3, inP2: Vec3) -> AABox #cpp_return_type_is_non_pod #foreign jolt_release "?sFromTwoPoints@AABox@JPH@@SA?AV12@VVec3@2@0@Z";

    /// Create box from indexed triangle
    sFromTriangle :: (inVertices: *VertexList, inTriangle: *IndexedTriangle) -> AABox #cpp_return_type_is_non_pod #foreign jolt_release "?sFromTriangle@AABox@JPH@@SA?AV12@AEBV?$Array@VFloat3@JPH@@V?$STLAllocator@VFloat3@JPH@@@2@@2@AEBVIndexedTriangle@2@@Z";
    sFromTriangle :: (inVertices: VertexList, inTriangle: IndexedTriangle) -> AABox #no_context {
        return sFromTriangle(*inVertices, *inTriangle);
    }

    /// Reset the bounding box to an empty bounding box
    SetEmpty :: (this: *AABox) -> void #cpp_method #foreign jolt_release "?SetEmpty@AABox@JPH@@QEAAXXZ";

    /// Check if the bounding box is valid (max >= min)
    IsValid :: (this: *AABox) -> bool #cpp_method #foreign jolt_release "?IsValid@AABox@JPH@@QEBA_NXZ";

    /// Encapsulate point in bounding box
    Encapsulate :: (this: *AABox, inPos: Vec3) -> void #cpp_method #foreign jolt_release "?Encapsulate@AABox@JPH@@QEAAXVVec3@2@@Z";

    /// Encapsulate bounding box in bounding box
    Encapsulate :: (this: *AABox, inRHS: *AABox) -> void #cpp_method #foreign jolt_release "?Encapsulate@AABox@JPH@@QEAAXAEBV12@@Z";
    Encapsulate :: (this: *AABox, inRHS: AABox) #no_context {
        Encapsulate(this, *inRHS);
    }

    /// Encapsulate triangle in bounding box
    Encapsulate :: (this: *AABox, inVertices: *VertexList, inTriangle: *IndexedTriangle) -> void #cpp_method #foreign jolt_release "?Encapsulate@AABox@JPH@@QEAAXAEBV?$Array@VFloat3@JPH@@V?$STLAllocator@VFloat3@JPH@@@2@@2@AEBVIndexedTriangle@2@@Z";
    Encapsulate :: (this: *AABox, inVertices: VertexList, inTriangle: IndexedTriangle) #no_context {
        Encapsulate(this, *inVertices, *inTriangle);
    }

    /// Widen the box on both sides by inVector
    ExpandBy :: (this: *AABox, inVector: Vec3) -> void #cpp_method #foreign jolt_release "?ExpandBy@AABox@JPH@@QEAAXVVec3@2@@Z";

    /// Get center of bounding box
    GetCenter :: (this: *AABox) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetCenter@AABox@JPH@@QEBA?AVVec3@2@XZ";

    /// Get extent of bounding box (half of the size)
    GetExtent :: (this: *AABox) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetExtent@AABox@JPH@@QEBA?AVVec3@2@XZ";

    /// Get size of bounding box
    GetSize :: (this: *AABox) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetSize@AABox@JPH@@QEBA?AVVec3@2@XZ";

    /// Get surface area of bounding box
    GetSurfaceArea :: (this: *AABox) -> float #cpp_method #foreign jolt_release "?GetSurfaceArea@AABox@JPH@@QEBAMXZ";

    /// Get volume of bounding box
    GetVolume :: (this: *AABox) -> float #cpp_method #foreign jolt_release "?GetVolume@AABox@JPH@@QEBAMXZ";

    /// Check if this box contains a point
    Contains :: (this: *AABox, inOther: Vec3) -> bool #cpp_method #foreign jolt_release "?Contains@AABox@JPH@@QEBA_NVVec3@2@@Z";

    /// Check if this box overlaps with another box
    Overlaps :: (this: *AABox, inOther: *AABox) -> bool #cpp_method #foreign jolt_release "?Overlaps@AABox@JPH@@QEBA_NAEBV12@@Z";
    Overlaps :: (this: *AABox, inOther: AABox) -> bool #no_context {
        return Overlaps(this, *inOther);
    }

    /// Translate bounding box
    Translate :: (this: *AABox, inTranslation: Vec3) -> void #cpp_method #foreign jolt_release "?Translate@AABox@JPH@@QEAAXVVec3@2@@Z";

    /// Transform bounding box
    Transformed :: (this: *AABox, inMatrix: *Mat44) -> AABox #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?Transformed@AABox@JPH@@QEBA?AV12@AEBVMat44@2@@Z";

    /// Scale this bounding box, can handle non-uniform and negative scaling
    Scaled :: (this: *AABox, inScale: Vec3) -> AABox #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?Scaled@AABox@JPH@@QEBA?AV12@VVec3@2@@Z";

    /// Calculate the support vector for this convex shape.
    GetSupport :: (this: *AABox, inDirection: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetSupport@AABox@JPH@@QEBA?AVVec3@2@V32@@Z";

    /// Get the closest point on or in this box to inPoint
    GetClosestPoint :: (this: *AABox, inPoint: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetClosestPoint@AABox@JPH@@QEBA?AVVec3@2@V32@@Z";

    /// Get the squared distance between inPoint and this box (will be 0 if in Point is inside the box)
    GetSqDistanceTo :: (this: *AABox, inPoint: Vec3) -> float #cpp_method #foreign jolt_release "?GetSqDistanceTo@AABox@JPH@@QEBAMVVec3@2@@Z";

    /// Bounding box min and max
    mMin: Vec3;
    mMax: Vec3;
}

/// Light weight runtime type information system. This way we don't need to turn
/// on the default RTTI system of the compiler (introducing a possible overhead for every
/// class)
///
/// Notes:
///  - An extra virtual member function is added. This adds 8 bytes to the size of
///    an instance of the class (unless you are already using virtual functions).
///
/// To use RTTI on a specific class use:
///
/// Header file:
///
///		class Foo
///		{
///			JPH_DECLARE_RTTI_VIRTUAL_BASE(Foo)
///		}
///
///		class Bar : public Foo
///		{
///			JPH_DECLARE_RTTI_VIRTUAL(Bar)
///		};
///
/// Implementation file:
///
///		JPH_IMPLEMENT_RTTI_VIRTUAL_BASE(Foo)
///		{
///		}
///
///		JPH_IMPLEMENT_RTTI_VIRTUAL(Bar)
///		{
///			JPH_ADD_BASE_CLASS(Bar, Foo) // Multiple inheritance is allowed, just do JPH_ADD_BASE_CLASS for every base class
///		}
///
/// For abstract classes use:
///
/// Header file:
///
///		class Foo
///		{
///			JPH_DECLARE_RTTI_ABSTRACT_BASE(Foo)
///
///		public:
///			virtual void AbstractFunction() = 0;
///		}
///
///		class Bar : public Foo
///		{
///			JPH_DECLARE_RTTI_VIRTUAL(Bar)
///
///		public:
///			virtual void AbstractFunction() { } // Function is now implemented so this class is no longer abstract
///		};
///
/// Implementation file:
///
///		JPH_IMPLEMENT_RTTI_ABSTRACT_BASE(Foo)
///		{
///		}
///
///		JPH_IMPLEMENT_RTTI_VIRTUAL(Bar)
///		{
///			JPH_ADD_BASE_CLASS(Bar, Foo)
///		}
///
/// Example of usage in a program:
///
///		Foo *foo_ptr = new Foo;
///		Foo *bar_ptr = new Bar;
///
///		IsType(foo_ptr, RTTI(Bar)) returns false
///		IsType(bar_ptr, RTTI(Bar)) returns true
///
///		IsKindOf(foo_ptr, RTTI(Bar)) returns false
///		IsKindOf(bar_ptr, RTTI(Foo)) returns true
///		IsKindOf(bar_ptr, RTTI(Bar)) returns true
///
///		StaticCast<Bar>(foo_ptr) asserts and returns foo_ptr casted to Bar *
///		StaticCast<Bar>(bar_ptr) returns bar_ptr casted to Bar *
///
///		DynamicCast<Bar>(foo_ptr) returns nullptr
///		DynamicCast<Bar>(bar_ptr) returns bar_ptr casted to Bar *
///
/// Other feature of DynamicCast:
///
///		class A { int data[5]; };
///		class B { int data[7]; };
///		class C : public A, public B { int data[9]; };
///
///		C *c = new C;
///		A *a = c;
///
/// Note that:
///
///		B *b = (B *)a;
///
/// generates an invalid pointer,
///
///		B *b = StaticCast<B>(a);
///
/// doesn't compile, and
///
///		B *b = DynamicCast<B>(a);
///
/// does the correct cast
RTTI :: struct {
    /// Function to create an object
    pCreateObjectFunction :: #type () -> *void #c_call;

    /// Function to destroy an object
    pDestructObjectFunction :: #type (inObject: *void) -> void #c_call;

    /// Function to initialize the runtime type info structure
    pCreateRTTIFunction :: #type (inRTTI: *RTTI) -> void #c_call;

    /// Constructor
    Constructor :: (this: *RTTI, inName: *u8, inSize: s32, inCreateObject: pCreateObjectFunction, inDestructObject: pDestructObjectFunction) -> void #cpp_method #foreign jolt_release "??0RTTI@JPH@@QEAA@PEBDHP6APEAXXZP6AXPEAX@Z@Z";
    Constructor :: (this: *RTTI, inName: *u8, inSize: s32, inCreateObject: pCreateObjectFunction, inDestructObject: pDestructObjectFunction, inCreateRTTI: pCreateRTTIFunction) -> void #cpp_method #foreign jolt_release "??0RTTI@JPH@@QEAA@PEBDHP6APEAXXZP6AXPEAX@ZP6AXAEAV01@@Z@Z";

    // Properties
    GetName :: (this: *RTTI) -> *u8 #cpp_method #foreign jolt_release "?GetName@RTTI@JPH@@QEBAPEBDXZ";

    IsAbstract :: (this: *RTTI) -> bool #cpp_method #foreign jolt_release "?IsAbstract@RTTI@JPH@@QEBA_NXZ";
    GetBaseClassCount :: (this: *RTTI) -> s32 #cpp_method #foreign jolt_release "?GetBaseClassCount@RTTI@JPH@@QEBAHXZ";
    GetBaseClass :: (this: *RTTI, inIdx: s32) -> *RTTI #cpp_method #foreign jolt_release "?GetBaseClass@RTTI@JPH@@QEBAPEBV12@H@Z";
    GetHash :: (this: *RTTI) -> u32 #cpp_method #foreign jolt_release "?GetHash@RTTI@JPH@@QEBAIXZ";

    /// Create an object of this type (returns nullptr if the object is abstract)
    CreateObject :: (this: *RTTI) -> *void #cpp_method #foreign jolt_release "?CreateObject@RTTI@JPH@@QEBAPEAXXZ";

    /// Destruct object of this type (does nothing if the object is abstract)
    DestructObject :: (this: *RTTI, inObject: *void) -> void #cpp_method #foreign jolt_release "?DestructObject@RTTI@JPH@@QEBAXPEAX@Z";

    /// Add base class
    AddBaseClass :: (this: *RTTI, inRTTI: *RTTI, inOffset: s32) -> void #cpp_method #foreign jolt_release "?AddBaseClass@RTTI@JPH@@QEAAXPEBV12@H@Z";

    /// Test if this class is derived from class of type inRTTI
    IsKindOf :: (this: *RTTI, inRTTI: *RTTI) -> bool #cpp_method #foreign jolt_release "?IsKindOf@RTTI@JPH@@QEBA_NPEBV12@@Z";

    /// Cast inObject of this type to object of type inRTTI, returns nullptr if the cast is unsuccessful
    CastTo :: (this: *RTTI, inObject: *void, inRTTI: *RTTI) -> *void #cpp_method #foreign jolt_release "?CastTo@RTTI@JPH@@QEBAPEBXPEBXPEBV12@@Z";

    /// Base class information
    BaseClass :: struct {
        mRTTI:   *RTTI;
        mOffset: s32;
    }

    mName:                   *u8; ///< Class name
    mSize:                   s32; ///< Class size
    mBaseClasses:            StaticArray(BaseClass, 4) = 4; ///< Names of base classes
    mCreate:                 pCreateObjectFunction; ///< Pointer to a function that will create a new instance of this class
    mDestruct:               pDestructObjectFunction; ///< Pointer to a function that will destruct an object of this class
}

/// Classes must be derived from SerializableObject if you want to be able to save pointers or
/// reference counting pointers to objects of this or derived classes. The type will automatically
/// be determined during serialization and upon deserialization it will be restored correctly.
SerializableObject :: struct {
    vtable: *SerializableObject_VTable;

    sCreateRTTI :: (inRTTI: *RTTI) -> void #foreign jolt_release "?sCreateRTTI@SerializableObject@JPH@@SAXAEAVRTTI@2@@Z";

    /// Don't allow (copy) constructing this base class, but allow derived classes to (copy) construct themselves
    Constructor :: (this: *SerializableObject) -> void #cpp_method #foreign jolt_release "??0SerializableObject@JPH@@IEAA@XZ";

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_GetRTTI :: (this: *SerializableObject) -> *RTTI #cpp_method #foreign jolt_release "?GetRTTI@SerializableObject@JPH@@UEBAPEBVRTTI@2@XZ";
    virtual_CastTo :: (this: *SerializableObject, inRTTI: *RTTI) -> *void #cpp_method #foreign jolt_release "?CastTo@SerializableObject@JPH@@UEBAPEBXPEBVRTTI@2@@Z";

    /// Destructor
    virtual_Destructor :: (this: *SerializableObject, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1SerializableObject@JPH@@UEAA@XZ";
}
SerializableObject_VTable :: struct #type_info_none {
    GetRTTI:    #type (this: *SerializableObject) -> *RTTI #cpp_method;
    CastTo:     #type (this: *SerializableObject, inRTTI: *RTTI) -> *void #cpp_method;

    Destructor: #type (this: *SerializableObject, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;
}
SerializableObject_GetRTTI :: inline (this: *SerializableObject) -> *RTTI { return this.vtable.GetRTTI(this); }
SerializableObject_CastTo :: inline (this: *SerializableObject, inRTTI: *RTTI) -> *void { return this.vtable.CastTo(this, inRTTI); }

SerializableObject_Destructor :: inline (this: *SerializableObject, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

vtable :: (obj: *SerializableObject) -> *SerializableObject_VTable { return obj.vtable; }


/// Describes the mass and inertia properties of a body. Used during body construction only.
MassProperties :: struct {
    sCreateRTTI :: (inRTTI: *RTTI) -> void #foreign jolt_release "?sCreateRTTI@MassProperties@JPH@@SAXAEAVRTTI@2@@Z";

    /// Using eigendecomposition, decompose the inertia tensor into a diagonal matrix D and a right-handed rotation matrix R so that the inertia tensor is \f$R \: D \: R^{-1}\f$.
    /// @see https://en.wikipedia.org/wiki/Moment_of_inertia section 'Principal axes'
    /// @param outRotation The rotation matrix R
    /// @param outDiagonal The diagonal of the diagonal matrix D
    /// @return True if successful, false if failed
    DecomposePrincipalMomentsOfInertia :: (this: *MassProperties, outRotation: *Mat44, outDiagonal: *Vec3) -> bool #cpp_method #foreign jolt_release "?DecomposePrincipalMomentsOfInertia@MassProperties@JPH@@QEBA_NAEAVMat44@2@AEAVVec3@2@@Z";

    /// Set the mass and inertia of a box with edge size inBoxSize and density inDensity
    SetMassAndInertiaOfSolidBox :: (this: *MassProperties, inBoxSize: Vec3, inDensity: float) -> void #cpp_method #foreign jolt_release "?SetMassAndInertiaOfSolidBox@MassProperties@JPH@@QEAAXVVec3@2@M@Z";

    /// Set the mass and scale the inertia tensor to match the mass
    ScaleToMass :: (this: *MassProperties, inMass: float) -> void #cpp_method #foreign jolt_release "?ScaleToMass@MassProperties@JPH@@QEAAXM@Z";

    /// Calculates the size of the solid box that has an inertia tensor diagonal inInertiaDiagonal
    sGetEquivalentSolidBoxSize :: (inMass: float, inInertiaDiagonal: Vec3) -> Vec3 #cpp_return_type_is_non_pod #foreign jolt_release "?sGetEquivalentSolidBoxSize@MassProperties@JPH@@SA?AVVec3@2@MV32@@Z";

    /// Rotate the inertia by 3x3 matrix inRotation
    Rotate :: (this: *MassProperties, inRotation: *Mat44) -> void #cpp_method #foreign jolt_release "?Rotate@MassProperties@JPH@@QEAAXAEBVMat44@2@@Z";

    /// Translate the inertia by a vector inTranslation
    Translate :: (this: *MassProperties, inTranslation: Vec3) -> void #cpp_method #foreign jolt_release "?Translate@MassProperties@JPH@@QEAAXVVec3@2@@Z";

    /// Scale the mass and inertia by inScale, note that elements can be < 0 to flip the shape
    Scale :: (this: *MassProperties, inScale: Vec3) -> void #cpp_method #foreign jolt_release "?Scale@MassProperties@JPH@@QEAAXVVec3@2@@Z";

    /// Saves the state of this object in binary form to inStream.
    SaveBinaryState :: (this: *MassProperties, inStream: *StreamOut) -> void #cpp_method #foreign jolt_release "?SaveBinaryState@MassProperties@JPH@@QEBAXAEAVStreamOut@2@@Z";

    /// Restore the state of this object from inStream.
    RestoreBinaryState :: (this: *MassProperties, inStream: *StreamIn) -> void #cpp_method #foreign jolt_release "?RestoreBinaryState@MassProperties@JPH@@QEAAXAEAVStreamIn@2@@Z";

    /// Mass of the shape (kg)
    mMass:    float = 0.0;

    /// Inertia tensor of the shape (kg m^2)
    mInertia: Mat44;
}

/// How collision detection functions will treat back facing triangles
EBackFaceMode :: enum u8 {
    IgnoreBackFaces      :: 0;
    CollideWithBackFaces :: 1;
}

/// Traits to use for CastRay
CollisionCollectorTraitsCastRay :: struct {
    __empty_struct_padding:  u8; // C++ makes empty structs have length 1

    InitialEarlyOutFraction: float : 1.0; ///< Furthest hit: Fraction is 1 + epsilon
    ShouldEarlyOutFraction:  float : 0.0; ///< Closest hit: Fraction is 0
}

/// Traits to use for CastShape
CollisionCollectorTraitsCastShape :: struct {
    __empty_struct_padding:  u8; // C++ makes empty structs have length 1

    InitialEarlyOutFraction: float : 1.0; ///< Furthest hit: Fraction is 1 + epsilon
    ShouldEarlyOutFraction:  float : -FLOAT32_MAX; ///< Deepest hit: Penetration is infinite
}

/// Traits to use for CollideShape
CollisionCollectorTraitsCollideShape :: struct {
    __empty_struct_padding:  u8; // C++ makes empty structs have length 1

    InitialEarlyOutFraction: float : FLOAT32_MAX; ///< Most shallow hit: Separation is infinite
    ShouldEarlyOutFraction:  float : -FLOAT32_MAX; ///< Deepest hit: Penetration is infinite
}

/// Traits to use for CollidePoint
CollisionCollectorTraitsCollidePoint :: CollisionCollectorTraitsCollideShape;

/// Virtual interface that allows collecting multiple collision results
CollisionCollector :: struct(ResultTypeArg: Type, TraitsType: Type) {
    vtable:            *CollisionCollector_VTable;

    /// Declare ResultType so that derived classes can use it
    ResultType :: ResultTypeArg;

    /// The early out fraction determines the fraction below which the collector is still accepting a hit (can be used to reduce the amount of work)
    mEarlyOutFraction: float;

    /// Set by the collision detection functions to the current TransformedShape of the body that we're colliding against before calling the AddHit function
    mContext:          *TransformedShape = null;
}
CollisionCollector_VTable :: struct #type_info_none {
    Destructor: *void;
}

vtable :: (obj: *CollisionCollector) -> *CollisionCollector_VTable { return obj.vtable; }


/// Filter class
ShapeFilter :: struct {
    vtable:                 *ShapeFilter_VTable;
    using noncopyable__raw: NonCopyable__RAW;

    /// Used during NarrowPhase queries and TransformedShape queries. Set to the body ID of inShape2 before calling ShouldCollide.
    /// Provides context to the filter to indicate which body is colliding.
    mBodyID2:               BodyID;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Destructor
    virtual_Destructor :: (this: *ShapeFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1ShapeFilter@JPH@@UEAA@XZ";

    /// Filter function to determine if we should collide with a shape. Returns true if the filter passes.
    /// This overload is called when the query doesn't have a source shape (e.g. ray cast / collide point)
    /// @param inShape2 Shape we're colliding against
    /// @param inSubShapeIDOfShape2 The sub shape ID that will lead from the root shape to inShape2 (i.e. the shape of mBodyID2)
    virtual_ShouldCollide :: (this: /*const*/ *ShapeFilter, inShape2: /*const*/ *Shape, inSubShapeIDOfShape2: /*const reference*/ *SubShapeID) -> bool #cpp_method #foreign jolt_release "?ShouldCollide@ShapeFilter@JPH@@UEBA_NPEBVShape@2@AEBVSubShapeID@2@@Z";

    /// Filter function to determine if two shapes should collide. Returns true if the filter passes.
    /// This overload is called when querying a shape vs a shape (e.g. collide object / cast object).
    /// It is called at each level of the shape hierarchy, so if you have a compound shape with a box, this function will be called twice.
    /// It will not be called on triangles that are part of another shape, i.e a mesh shape will not trigger a callback per triangle. You can filter out individual triangles in the CollisionCollector::AddHit function by their sub shape ID.
    /// @param inShape1 1st shape that is colliding
    /// @param inSubShapeIDOfShape1 The sub shape ID that will lead from the root shape to inShape1 (i.e. the shape that is used to collide or cast against shape 2)
    /// @param inShape2 2nd shape that is colliding
    /// @param inSubShapeIDOfShape2 The sub shape ID that will lead from the root shape to inShape2 (i.e. the shape of mBodyID2)
    virtual_ShouldCollide_1 :: (this: /*const*/ *ShapeFilter, inShape1: /*const*/ *Shape, inSubShapeIDOfShape1: /*const reference*/ *SubShapeID, inShape2: /*const*/ *Shape, inSubShapeIDOfShape2: /*const reference*/ *SubShapeID) -> bool #cpp_method #foreign jolt_release "?ShouldCollide@ShapeFilter@JPH@@UEBA_NPEBVShape@2@AEBVSubShapeID@2@01@Z";
}
ShapeFilter_VTable :: struct #type_info_none {
    Destructor:      #type (this: *ShapeFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    ShouldCollide:   #type (this: /*const*/ *ShapeFilter, inShape1: /*const*/ *Shape, inSubShapeIDOfShape1: /*const reference*/ *SubShapeID, inShape2: /*const*/ *Shape, inSubShapeIDOfShape2: /*const reference*/ *SubShapeID) -> bool #cpp_method;

    ShouldCollide_1: #type (this: /*const*/ *ShapeFilter, inShape2: /*const*/ *Shape, inSubShapeIDOfShape2: /*const reference*/ *SubShapeID) -> bool #cpp_method;
}
ShapeFilter_Destructor :: inline (this: *ShapeFilter, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

ShapeFilter_ShouldCollide :: inline (this: /*const*/ *ShapeFilter, inShape1: /*const*/ *Shape, inSubShapeIDOfShape1: /*const reference*/ *SubShapeID, inShape2: /*const*/ *Shape, inSubShapeIDOfShape2: /*const reference*/ *SubShapeID) -> bool { return this.vtable.ShouldCollide(this, inShape1, inSubShapeIDOfShape1, inShape2, inSubShapeIDOfShape2); }

ShapeFilter_ShouldCollide_1 :: inline (this: /*const*/ *ShapeFilter, inShape2: /*const*/ *Shape, inSubShapeIDOfShape2: /*const reference*/ *SubShapeID) -> bool { return this.vtable.ShouldCollide_1(this, inShape2, inSubShapeIDOfShape2); }

vtable :: (obj: *ShapeFilter) -> *ShapeFilter_VTable { return obj.vtable; }


/// Helper class to reverse the order of the shapes in the ShouldCollide function
ReversedShapeFilter :: struct {
    #as using shapefilter: ShapeFilter;

    /// Constructor
    Constructor :: (this: *ReversedShapeFilter, inFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "??0ReversedShapeFilter@JPH@@QEAA@AEBVShapeFilter@1@@Z";
    Constructor :: (this: *ReversedShapeFilter, inFilter: ShapeFilter) #no_context {
        Constructor(this, *inFilter);
    }

    mFilter:               *ShapeFilter;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_ShouldCollide :: (this: /*const*/ *ReversedShapeFilter, inShape2: /*const*/ *Shape, inSubShapeIDOfShape2: /*const reference*/ *SubShapeID) -> bool #cpp_method #foreign jolt_release "?ShouldCollide@ReversedShapeFilter@JPH@@UEBA_NPEBVShape@2@AEBVSubShapeID@2@@Z";

    virtual_ShouldCollide_1 :: (this: /*const*/ *ReversedShapeFilter, inShape1: /*const*/ *Shape, inSubShapeIDOfShape1: /*const reference*/ *SubShapeID, inShape2: /*const*/ *Shape, inSubShapeIDOfShape2: /*const reference*/ *SubShapeID) -> bool #cpp_method #foreign jolt_release "?ShouldCollide@ReversedShapeFilter@JPH@@UEBA_NPEBVShape@2@AEBVSubShapeID@2@01@Z";
}

/// Type to use for passing arguments to a function
ColorArg :: Color;

/// Class that holds an RGBA color with 8-bits per component
Color :: struct {
    Constructor :: (this: *Color, inColor: u32) -> void #cpp_method #foreign jolt_release "??0Color@JPH@@QEAA@I@Z";
    Constructor :: (this: *Color, inRed: u8, inGreen: u8, inBlue: u8, inAlpha: u8 = 255) -> void #cpp_method #foreign jolt_release "??0Color@JPH@@QEAA@EEEE@Z";

    /// Convert to uint32
    GetUInt32 :: (this: *Color) -> u32 #cpp_method #foreign jolt_release "?GetUInt32@Color@JPH@@QEBAIXZ";

    /// Get a visually distinct color
    sGetDistinctColor :: (inIndex: s32) -> Color #cpp_return_type_is_non_pod #foreign jolt_release "?sGetDistinctColor@Color@JPH@@SA?AV12@H@Z";

    union {
        mU32: u32; ///< Combined value for red, green, blue and alpha
        struct {
            r: u8; ///< Red channel
            g: u8; ///< Green channel
            b: u8; ///< Blue channel
            a: u8; ///< Alpha channel
        }
    }
}

/// Helper class that either contains a valid result or an error
Result :: struct(_Type: Type) {
    union {
        mResult: _Type; ///< The actual result object
        mError:  String; ///< The error description if the result failed
    }

    /// State of the result
    EState :: enum u8 {
        Invalid :: 0;
        Valid   :: 0;
        Error   :: 0;
    }

    mState: EState;
}

/// A vector consisting of 16 bytes
BVec16 :: struct {
    Type :: __m128i;

    Constructor :: (this: *BVec16, inRHS: Type) -> void #cpp_method #foreign jolt_release "??0BVec16@JPH@@QEAA@T__m128i@@@Z";

    /// Vector with all zeros
    sZero :: () -> BVec16 #cpp_return_type_is_non_pod #foreign jolt_release "?sZero@BVec16@JPH@@SA?AV12@XZ";

    /// Replicate int inV across all components
    sReplicate :: (inV: u8) -> BVec16 #cpp_return_type_is_non_pod #foreign jolt_release "?sReplicate@BVec16@JPH@@SA?AV12@E@Z";

    /// Load 16 bytes from memory
    sLoadByte16 :: (inV: *u8) -> BVec16 #cpp_return_type_is_non_pod #foreign jolt_release "?sLoadByte16@BVec16@JPH@@SA?AV12@PEBE@Z";

    /// Equals (component wise), highest bit of each component that is set is considered true
    sEquals :: (inV1: BVec16, inV2: BVec16) -> BVec16 #cpp_return_type_is_non_pod #foreign jolt_release "?sEquals@BVec16@JPH@@SA?AV12@V12@0@Z";

    /// Logical and (component wise)
    sAnd :: (inV1: BVec16, inV2: BVec16) -> BVec16 #cpp_return_type_is_non_pod #foreign jolt_release "?sAnd@BVec16@JPH@@SA?AV12@V12@0@Z";

    /// Store if mU8[0] is true in bit 0, mU8[1] in bit 1, etc. (true is when highest bit of component is set)
    GetTrues :: (this: *BVec16) -> s32 #cpp_method #foreign jolt_release "?GetTrues@BVec16@JPH@@QEBAHXZ";

    union {
        mValue: Type;
        mU8:    [16] u8;
        mU64:   [2] u64;
    }
}

/// Helper class for implementing an UnorderedSet or UnorderedMap
/// Based on CppCon 2017: Matt Kulukundis "Designing a Fast, Efficient, Cache-friendly Hash Table, Step by Step"
/// See: https://www.youtube.com/watch?v=ncHmEUmJZf4
HashTable :: struct(Key: Type, KeyValue: Type, HashTableDetail: Type, Hash: Type, KeyEqual: Type) {
    /// Properties
    value_type :: KeyValue;
    size_type :: u32;
    difference_type :: ptrdiff_t;

    /// Base class for iterators
    IteratorBase :: struct(Table: Type, Iterator: Type) {
        /// Properties
        difference_type :: Table;
        value_type :: Table;
        iterator_category :: std.forward_iterator_tag;

        mTable:            *Table;
        mIndex:            size_type;
    }

    /// Non-const iterator
    iterator :: struct {
        #as using iteratorbase: IteratorBase(HashTable, iterator);

        Base :: IteratorBase(HashTable, iterator);

        /// Properties
        reference :: *Base;
        pointer :: *Base;
    }

    /// Const iterator
    const_iterator :: struct {
        #as using iteratorbase: IteratorBase(HashTable, const_iterator);

        Base :: IteratorBase(HashTable, const_iterator);

        /// Properties
        reference :: *Base;
        pointer :: *Base;
    }

    /// Max load factor is cMaxLoadFactorNumerator / cMaxLoadFactorDenominator
    cMaxLoadFactorNumerator:        u64 : 7;
    cMaxLoadFactorDenominator:      u64 : 8;

    /// If we can recover this fraction of deleted elements, we'll reshuffle the buckets in place rather than growing the table
    cMaxDeletedElementsNumerator:   u64 : 1;
    cMaxDeletedElementsDenominator: u64 : 8;

    /// Values that the control bytes can have
    cBucketEmpty:                   u8 : 0;
    cBucketDeleted:                 u8 : 127;
    cBucketUsed:                    u8 : 128; // Lowest 7 bits are lowest 7 bits of the hash value

    /// The buckets, an array of size mMaxSize
    mData:                          *KeyValue = null;

    /// Control bytes, an array of size mMaxSize + 15
    mControl:                       *u8 = null;

    /// Number of elements in the table
    mSize:                          size_type = 0;

    /// Max number of elements that can be stored in the table
    mMaxSize:                       size_type = 0;

    /// Number of elements we can add to the table before we need to grow
    mLoadLeft:                      size_type = 0;
}

/// Internal helper class to provide context for UnorderedMap
UnorderedMapDetail :: struct(Key: Type, Value: Type) {
    using,except(Key, Value) unorderedmapdetail__raw: UnorderedMapDetail__RAW(Key, Value);
    #if size_of(UnorderedMapDetail__RAW(Key, Value)) == 0 {
        __empty_struct_padding:  u8; // C++ makes empty structs have length 1
    }
}
// UnorderedMapDetail without padding. Needed to generate a C++-equivalent struct layout when "inheriting" from UnorderedMapDetail
UnorderedMapDetail__RAW :: struct(Key: Type, Value: Type) {}

/// Hash Map class
/// @tparam Key Key type
/// @tparam Value Value type
/// @tparam Hash Hash function (note should be 64-bits)
/// @tparam KeyEqual Equality comparison function
UnorderedMap :: struct(Key: Type, Value: Type, Hash: Type = Hash(Key), KeyEqual: Type = std.equal_to(Key)) {
    #as using,except(Key, Hash, KeyEqual, value_type, size_type, iterator, const_iterator) hashtable:  HashTable(Key, std.pair(Key, Value), UnorderedMapDetail(Key, Value), Hash, KeyEqual);

    Base :: HashTable(Key, std.pair(Key, Value), UnorderedMapDetail(Key, Value), Hash, KeyEqual);

    size_type :: Base;
    iterator :: Base;
    const_iterator :: Base;
    value_type :: Base;
}

/// Internal helper class to provide context for UnorderedSet
UnorderedSetDetail :: struct(Key: Type) {
    using,except(Key) unorderedsetdetail__raw: UnorderedSetDetail__RAW(Key);
    #if size_of(UnorderedSetDetail__RAW(Key)) == 0 {
        __empty_struct_padding:  u8; // C++ makes empty structs have length 1
    }
}
// UnorderedSetDetail without padding. Needed to generate a C++-equivalent struct layout when "inheriting" from UnorderedSetDetail
UnorderedSetDetail__RAW :: struct(Key: Type) {}

/// Hash Set class
/// @tparam Key Key type
/// @tparam Hash Hash function (note should be 64-bits)
/// @tparam KeyEqual Equality comparison function
UnorderedSet :: struct(Key: Type, Hash: Type = Hash(Key), KeyEqual: Type = std.equal_to(Key)) {
    #as using,except(Key, Hash, KeyEqual) hashtable: HashTable(Key, Key, UnorderedSetDetail(Key), Hash, KeyEqual);
}

/// Simple binary input stream
StreamIn :: struct {
    vtable:                 *StreamIn_VTable;
    using noncopyable__raw: NonCopyable__RAW;

    /// Read a Vec3 (don't read W)
    Read :: (this: *StreamIn, outVec: *Vec3) -> void #cpp_method #foreign jolt_release "?Read@StreamIn@JPH@@QEAAXAEAVVec3@2@@Z";
    #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}
StreamIn_VTable :: struct #type_info_none {
    Destructor: #type (this: *StreamIn, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    ReadBytes:  #type (this: *StreamIn, outData: *void, inNumBytes: u64) -> void #cpp_method;

    IsEOF:      #type (this: *StreamIn) -> bool #cpp_method;

    IsFailed:   #type (this: *StreamIn) -> bool #cpp_method;
}
StreamIn_Destructor :: inline (this: *StreamIn, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

StreamIn_ReadBytes :: inline (this: *StreamIn, outData: *void, inNumBytes: u64) { this.vtable.ReadBytes(this, outData, inNumBytes); }

StreamIn_IsEOF :: inline (this: *StreamIn) -> bool { return this.vtable.IsEOF(this); }

StreamIn_IsFailed :: inline (this: *StreamIn) -> bool { return this.vtable.IsFailed(this); }

vtable :: (obj: *StreamIn) -> *StreamIn_VTable { return obj.vtable; }


/// Simple binary output stream
StreamOut :: struct {
    vtable:                 *StreamOut_VTable;
    using noncopyable__raw: NonCopyable__RAW;

    /// Write a Vec3 (don't write W)
    Write :: (this: *StreamOut, inVec: *Vec3) -> void #cpp_method #foreign jolt_release "?Write@StreamOut@JPH@@QEAAXAEBVVec3@2@@Z";
    Write :: (this: *StreamOut, inVec: Vec3) #no_context {
        Write(this, *inVec);
    }
    #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}
StreamOut_VTable :: struct #type_info_none {
    Destructor: #type (this: *StreamOut, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    WriteBytes: #type (this: *StreamOut, inData: *void, inNumBytes: u64) -> void #cpp_method;

    IsFailed:   #type (this: *StreamOut) -> bool #cpp_method;
}
StreamOut_Destructor :: inline (this: *StreamOut, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

StreamOut_WriteBytes :: inline (this: *StreamOut, inData: *void, inNumBytes: u64) { this.vtable.WriteBytes(this, inData, inNumBytes); }

StreamOut_IsFailed :: inline (this: *StreamOut) -> bool { return this.vtable.IsFailed(this); }

vtable :: (obj: *StreamOut) -> *StreamOut_VTable { return obj.vtable; }


/// This class is responsible for creating instances of classes based on their name or hash and is mainly used for deserialization of saved data.
Factory :: struct {
    /// Create an object
    CreateObject :: (this: *Factory, inName: *u8) -> *void #cpp_method #foreign jolt_release "?CreateObject@Factory@JPH@@QEAAPEAXPEBD@Z";

    /// Find type info for a specific class by name
    Find :: (this: *Factory, inName: *u8) -> *RTTI #cpp_method #foreign jolt_release "?Find@Factory@JPH@@QEAAPEBVRTTI@2@PEBD@Z";

    /// Find type info for a specific class by hash
    Find :: (this: *Factory, inHash: u32) -> *RTTI #cpp_method #foreign jolt_release "?Find@Factory@JPH@@QEAAPEBVRTTI@2@I@Z";

    /// Register an object with the factory. Returns false on failure.
    Register :: (this: *Factory, inRTTI: *RTTI) -> bool #cpp_method #foreign jolt_release "?Register@Factory@JPH@@QEAA_NPEBVRTTI@2@@Z";

    /// Register a list of objects with the factory. Returns false on failure.
    Register :: (this: *Factory, inRTTIs: **RTTI, inNumber: u32) -> bool #cpp_method #foreign jolt_release "?Register@Factory@JPH@@QEAA_NPEAPEBVRTTI@2@I@Z";

    /// Unregisters all types
    Clear :: (this: *Factory) -> void #cpp_method #foreign jolt_release "?Clear@Factory@JPH@@QEAAXXZ";

    /// Get all registered classes
    GetAllClasses :: (this: *Factory) -> Array(*RTTI) #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetAllClasses@Factory@JPH@@QEBA?AV?$Array@PEBVRTTI@JPH@@V?$STLAllocator@PEBVRTTI@JPH@@@2@@2@XZ";

    ClassHashMap :: UnorderedMap(u32, *RTTI);

    // Map of class hash to type info
    mClassHashMap: ClassHashMap;
}

StreamUtils :: struct {
    ObjectToIDMap :: struct(_Type: Type) {
        #as using unorderedmap: UnorderedMap(*_Type, u32);
    }

    IDToObjectMap :: struct(_Type: Type) {
        #as using array: Array(Ref(_Type));
    }
}

RayCast :: struct {}
RayCastSettings :: struct {}
ShapeCast :: struct {}
ShapeCastSettings :: struct {}
RayCastResult :: struct {}
ShapeCastResult :: struct {}
CollidePointResult :: struct {}
CollideShapeResult :: struct {}

CollideSoftBodyVertexIterator :: struct {}

CastRayCollector :: CollisionCollector(RayCastResult, CollisionCollectorTraitsCastRay);
CastShapeCollector :: CollisionCollector(ShapeCastResult, CollisionCollectorTraitsCastShape);
CollidePointCollector :: CollisionCollector(CollidePointResult, CollisionCollectorTraitsCollidePoint);
CollideShapeCollector :: CollisionCollector(CollideShapeResult, CollisionCollectorTraitsCollideShape);
TransformedShapeCollector :: CollisionCollector(TransformedShape, CollisionCollectorTraitsCollideShape);

ShapeRefC :: RefConst(Shape);
ShapeList :: Array(ShapeRefC);
PhysicsMaterialRefC :: RefConst(PhysicsMaterial);
PhysicsMaterialList :: Array(PhysicsMaterialRefC);

/// Shapes are categorized in groups, each shape can return which group it belongs to through its Shape::GetType function.
EShapeType :: enum u8 {
    Convex      :: 0;
    Compound    :: 1;
    Decorated   :: 2;
    Mesh        :: 3;
    HeightField :: 4;
    SoftBody    :: 5;

    User1       :: 6;
    User2       :: 7;
    User3       :: 8;
    User4       :: 9;

    Plane       :: 10;
    Empty       :: 11;
}

/// This enumerates all shape types, each shape can return its type through Shape::GetSubType
EShapeSubType :: enum u8 {
    Sphere             :: 0;
    Box                :: 1;
    Triangle           :: 2;
    Capsule            :: 3;
    TaperedCapsule     :: 4;
    Cylinder           :: 5;
    ConvexHull         :: 6;

    StaticCompound     :: 7;
    MutableCompound    :: 8;

    RotatedTranslated  :: 9;
    Scaled             :: 10;
    OffsetCenterOfMass :: 11;

    Mesh               :: 12;
    HeightField        :: 13;
    SoftBody           :: 14;

    User1              :: 15;
    User2              :: 16;
    User3              :: 17;
    User4              :: 18;
    User5              :: 19;
    User6              :: 20;
    User7              :: 21;
    User8              :: 22;

    UserConvex1        :: 23;
    UserConvex2        :: 24;
    UserConvex3        :: 25;
    UserConvex4        :: 26;
    UserConvex5        :: 27;
    UserConvex6        :: 28;
    UserConvex7        :: 29;
    UserConvex8        :: 30;

    Plane              :: 31;
    TaperedCylinder    :: 32;
    Empty              :: 33;
}

/// Class that can construct shapes and that is serializable using the ObjectStream system.
/// Can be used to store shape data in 'uncooked' form (i.e. in a form that is still human readable and authorable).
/// Once the shape has been created using the Create() function, the data will be moved into the Shape class
/// in a form that is optimized for collision detection. After this, the ShapeSettings object is no longer needed
/// and can be destroyed. Each shape class has a derived class of the ShapeSettings object to store shape specific
/// data.
ShapeSettings :: struct {
    #as using,except(vtable, sCreateRTTI) serializableobject: SerializableObject;
    #as using reftarget:    RefTarget(ShapeSettings);

    sCreateRTTI :: (inRTTI: *RTTI) -> void #foreign jolt_release "?sCreateRTTI@ShapeSettings@JPH@@SAXAEAVRTTI@2@@Z";

    ShapeResult :: Result(Ref(Shape));

    /// User data (to be used freely by the application)
    mUserData:              u64 = 0;

    mCachedResult:          ShapeResult;
    #overlay (serializableobject) vtable: *ShapeSettings_VTable; // Overlay parent's vtable with ShapeSettings’s vtable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_GetRTTI :: (this: *ShapeSettings) -> *RTTI #cpp_method #foreign jolt_release "?GetRTTI@ShapeSettings@JPH@@UEBAPEBVRTTI@2@XZ";
    virtual_CastTo :: (this: *ShapeSettings, inRTTI: *RTTI) -> *void #cpp_method #foreign jolt_release "?CastTo@ShapeSettings@JPH@@UEBAPEBXPEBVRTTI@2@@Z";
}
ShapeSettings_VTable :: struct #type_info_none {
    using vtable: SerializableObject_VTable;

    Create:       #type (this: *ShapeSettings) -> ShapeSettings.ShapeResult #cpp_method;
}
ShapeSettings_Create :: inline (this: *ShapeSettings) -> ShapeSettings.ShapeResult { return this.vtable.Create(this); }

vtable :: (obj: *ShapeSettings) -> *ShapeSettings_VTable { return obj.vtable; }


/// Function table for functions on shapes
ShapeFunctions :: struct {
    /// Construct a shape
    mConstruct: #type () -> *Shape #c_call = null;

    /// Color of the shape when drawing
    mColor:     Color;

    /// Get an entry in the registry for a particular sub type
    sGet :: (inSubType: EShapeSubType) -> *ShapeFunctions #foreign jolt_release "?sGet@ShapeFunctions@JPH@@SAAEAV12@W4EShapeSubType@2@@Z";
}

/// Base class for all shapes (collision volume of a body). Defines a virtual interface for collision detection.
Shape :: struct {
    vtable:                             *Shape_VTable;
    #as using reftarget:                RefTarget(Shape);
    #as using noncopyable:              NonCopyable;

    ShapeResult :: ShapeSettings.ShapeResult;

    /// Constructor
    Constructor :: (this: *Shape, inType: EShapeType, inSubType: EShapeSubType) -> void #cpp_method #foreign jolt_release "??0Shape@JPH@@QEAA@W4EShapeType@1@W4EShapeSubType@1@@Z";
    Constructor :: (this: *Shape, inType: EShapeType, inSubType: EShapeSubType, inSettings: *ShapeSettings, outResult: *ShapeResult) -> void #cpp_method #foreign jolt_release "??0Shape@JPH@@QEAA@W4EShapeType@1@W4EShapeSubType@1@AEBVShapeSettings@1@AEAV?$Result@V?$Ref@VShape@JPH@@@JPH@@@1@@Z";
    Constructor :: (this: *Shape, inType: EShapeType, inSubType: EShapeSubType, inSettings: ShapeSettings, outResult: *ShapeResult) #no_context {
        Constructor(this, inType, inSubType, *inSettings, outResult);
    }

    /// Get type
    GetType :: (this: *Shape) -> EShapeType #cpp_method #foreign jolt_release "?GetType@Shape@JPH@@QEBA?AW4EShapeType@2@XZ";
    GetSubType :: (this: *Shape) -> EShapeSubType #cpp_method #foreign jolt_release "?GetSubType@Shape@JPH@@QEBA?AW4EShapeSubType@2@XZ";

    /// User data (to be used freely by the application)
    GetUserData :: (this: *Shape) -> u64 #cpp_method #foreign jolt_release "?GetUserData@Shape@JPH@@QEBA_KXZ";
    SetUserData :: (this: *Shape, inUserData: u64) -> void #cpp_method #foreign jolt_release "?SetUserData@Shape@JPH@@QEAAX_K@Z";

    /// Type definition for a supporting face
    SupportingFace :: StaticArray(Vec3, 32);

    /// Scale this shape. Note that not all shapes support all scales, this will return a shape that matches the scale as accurately as possible. See Shape::IsValidScale for more information.
    /// @param inScale The scale to use for this shape (note: this scale is applied to the entire shape in the space it was created, most other functions apply the scale in the space of the leaf shapes and from the center of mass!)
    ScaleShape :: (this: *Shape, inScale: Vec3) -> ShapeResult #cpp_method #foreign jolt_release "?ScaleShape@Shape@JPH@@QEBA?AV?$Result@V?$Ref@VShape@JPH@@@JPH@@@2@VVec3@2@@Z";

    /// An opaque buffer that holds shape specific information during GetTrianglesStart/Next.
    GetTrianglesContext :: struct {
        mData: [4288] u8;

        _:     [0] u8 #align 16; // Force GetTrianglesContext alignment to match the C/C++ equivalent
    }

    /// This is the minimum amount of triangles that should be requested through GetTrianglesNext.
    cGetTrianglesMinTrianglesRequested: s32 : 32;

    /// Creates a Shape of the correct type and restores its contents from the binary stream inStream.
    sRestoreFromBinaryState :: (inStream: *StreamIn) -> ShapeResult #foreign jolt_release "?sRestoreFromBinaryState@Shape@JPH@@SA?AV?$Result@V?$Ref@VShape@JPH@@@JPH@@@2@AEAVStreamIn@2@@Z";

    ShapeToIDMap :: UnorderedMap(Shape);
    IDToShapeMap :: Array(Shape);
    MaterialToIDMap :: UnorderedMap(PhysicsMaterial);
    IDToMaterialMap :: Array(PhysicsMaterial);

    /// Save this shape, all its children and its materials. Pass in an empty map in ioShapeMap / ioMaterialMap or reuse the same map while saving multiple shapes to the same stream in order to avoid writing duplicates.
    SaveWithChildren :: (this: *Shape, inStream: *StreamOut, ioShapeMap: *ShapeToIDMap, ioMaterialMap: *MaterialToIDMap) -> void #cpp_method #foreign jolt_release "?SaveWithChildren@Shape@JPH@@QEBAXAEAVStreamOut@2@AEAV?$UnorderedMap@PEBVShape@JPH@@IU?$Hash@PEBVShape@JPH@@@2@U?$equal_to@PEBVShape@JPH@@@std@@@2@AEAV?$UnorderedMap@PEBVPhysicsMaterial@JPH@@IU?$Hash@PEBVPhysicsMaterial@JPH@@@2@U?$equal_to@PEBVPhysicsMaterial@JPH@@@std@@@2@@Z";

    /// Restore a shape, all its children and materials. Pass in an empty map in ioShapeMap / ioMaterialMap or reuse the same map while reading multiple shapes from the same stream in order to restore duplicates.
    sRestoreWithChildren :: (inStream: *StreamIn, ioShapeMap: *IDToShapeMap, ioMaterialMap: *IDToMaterialMap) -> ShapeResult #foreign jolt_release "?sRestoreWithChildren@Shape@JPH@@SA?AV?$Result@V?$Ref@VShape@JPH@@@JPH@@@2@AEAVStreamIn@2@AEAV?$Array@V?$Ref@VShape@JPH@@@JPH@@V?$STLAllocator@V?$Ref@VShape@JPH@@@JPH@@@2@@2@AEAV?$Array@V?$Ref@VPhysicsMaterial@JPH@@@JPH@@V?$STLAllocator@V?$Ref@VPhysicsMaterial@JPH@@@JPH@@@2@@2@@Z";

    /// Class that holds information about the shape that can be used for logging / data collection purposes
    Stats :: struct {
        Constructor :: (this: *Stats, inSizeBytes: u64, inNumTriangles: u32) -> void #cpp_method #foreign jolt_release "??0Stats@Shape@JPH@@QEAA@_KI@Z";

        mSizeBytes:    u64; ///< Amount of memory used by this shape (size in bytes)
        mNumTriangles: u32; ///< Number of triangles in this shape (when applicable)
    }

    VisitedShapes :: UnorderedSet(*Shape);

    /// A fallback version of CollidePoint that uses a ray cast and counts the number of hits to determine if the point is inside the shape. Odd number of hits means inside, even number of hits means outside.
    sCollidePointUsingRayCast :: (inShape: *Shape, inPoint: Vec3, inSubShapeIDCreator: *SubShapeIDCreator, ioCollector: *CollidePointCollector, inShapeFilter: *ShapeFilter) -> void #foreign jolt_release "?sCollidePointUsingRayCast@Shape@JPH@@KAXAEBV12@VVec3@2@AEBVSubShapeIDCreator@2@AEAV?$CollisionCollector@VCollidePointResult@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVShapeFilter@2@@Z";
    sCollidePointUsingRayCast :: (inShape: Shape, inPoint: Vec3, inSubShapeIDCreator: SubShapeIDCreator, ioCollector: *CollidePointCollector, inShapeFilter: ShapeFilter) #no_context {
        sCollidePointUsingRayCast(*inShape, inPoint, *inSubShapeIDCreator, ioCollector, *inShapeFilter);
    }

    mUserData:                          u64 = 0;
    mShapeType:                         EShapeType;
    mShapeSubType:                      EShapeSubType;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Destructor
    virtual_Destructor :: (this: *Shape, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1Shape@JPH@@UEAA@XZ";

    /// Check if this shape can only be used to create a static body or if it can also be dynamic/kinematic
    virtual_MustBeStatic :: (this: *Shape) -> bool #cpp_method #foreign jolt_release "?MustBeStatic@Shape@JPH@@UEBA_NXZ";

    /// All shapes are centered around their center of mass. This function returns the center of mass position that needs to be applied to transform the shape to where it was created.
    virtual_GetCenterOfMass :: (this: *Shape) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetCenterOfMass@Shape@JPH@@UEBA?AVVec3@2@XZ";

    /// Get world space bounds including convex radius.
    /// This shape is scaled by inScale in local space first.
    /// This function can be overridden to return a closer fitting world space bounding box, by default it will just transform what GetLocalBounds() returns.
    virtual_GetWorldSpaceBounds :: (this: *Shape, inCenterOfMassTransform: *Mat44, inScale: Vec3) -> AABox #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetWorldSpaceBounds@Shape@JPH@@UEBA?AVAABox@2@AEBVMat44@2@VVec3@2@@Z";

    /// Get the leaf shape for a particular sub shape ID.
    /// @param inSubShapeID The full sub shape ID that indicates the path to the leaf shape
    /// @param outRemainder What remains of the sub shape ID after removing the path to the leaf shape (could e.g. refer to a triangle within a MeshShape)
    /// @return The shape or null if the sub shape ID is invalid
    virtual_GetLeafShape :: (this: *Shape, inSubShapeID: *SubShapeID, outRemainder: *SubShapeID) -> *Shape #cpp_method #foreign jolt_release "?GetLeafShape@Shape@JPH@@UEBAPEBV12@AEBVSubShapeID@2@AEAV32@@Z";

    /// Get the vertices of the face that faces inDirection the most (includes any convex radius). Note that this function can only return faces of
    /// convex shapes or triangles, which is why a sub shape ID to get to that leaf must be provided.
    /// @param inSubShapeID Sub shape ID of target shape
    /// @param inDirection Direction that the face should be facing (in local space to this shape)
    /// @param inCenterOfMassTransform Transform to transform outVertices with
    /// @param inScale Scale in local space of the shape (scales relative to its center of mass)
    /// @param outVertices Resulting face. The returned face can be empty if the shape doesn't have polygons to return (e.g. because it's a sphere). The face will be returned in world space.
    virtual_GetSupportingFace :: (this: *Shape, inSubShapeID: *SubShapeID, inDirection: Vec3, inScale: Vec3, inCenterOfMassTransform: *Mat44, outVertices: *SupportingFace) -> void #cpp_method #foreign jolt_release "?GetSupportingFace@Shape@JPH@@UEBAXAEBVSubShapeID@2@VVec3@2@1AEBVMat44@2@AEAV?$StaticArray@VVec3@JPH@@$0CA@@2@@Z";

    /// Get the user data of a particular sub shape ID. Corresponds with the value stored in Shape::GetUserData of the leaf shape pointed to by inSubShapeID.
    virtual_GetSubShapeUserData :: (this: *Shape, inSubShapeID: *SubShapeID) -> u64 #cpp_method #foreign jolt_release "?GetSubShapeUserData@Shape@JPH@@UEBA_KAEBVSubShapeID@2@@Z";

    /// Get the direct child sub shape and its transform for a sub shape ID.
    /// @param inSubShapeID Sub shape ID that indicates the path to the leaf shape
    /// @param inPositionCOM The position of the center of mass of this shape
    /// @param inRotation The orientation of this shape
    /// @param inScale Scale in local space of the shape (scales relative to its center of mass)
    /// @param outRemainder The remainder of the sub shape ID after removing the sub shape
    /// @return Direct child sub shape and its transform, note that the body ID and sub shape ID will be invalid
    virtual_GetSubShapeTransformedShape :: (this: *Shape, inSubShapeID: *SubShapeID, inPositionCOM: Vec3, inRotation: Quaternion, inScale: Vec3, outRemainder: *SubShapeID) -> TransformedShape #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetSubShapeTransformedShape@Shape@JPH@@UEBA?AVTransformedShape@2@AEBVSubShapeID@2@VVec3@2@VQuat@2@1AEAV42@@Z";

    /// Collect the leaf transformed shapes of all leaf shapes of this shape.
    /// inBox is the world space axis aligned box which leaf shapes should collide with.
    /// inPositionCOM/inRotation/inScale describes the transform of this shape.
    /// inSubShapeIDCreator represents the current sub shape ID of this shape.
    virtual_CollectTransformedShapes :: (this: *Shape, inBox: *AABox, inPositionCOM: Vec3, inRotation: Quaternion, inScale: Vec3, inSubShapeIDCreator: *SubShapeIDCreator, ioCollector: *TransformedShapeCollector, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CollectTransformedShapes@Shape@JPH@@UEBAXAEBVAABox@2@VVec3@2@VQuat@2@1AEBVSubShapeIDCreator@2@AEAV?$CollisionCollector@VTransformedShape@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVShapeFilter@2@@Z";

    /// Transforms this shape and all of its children with inTransform, resulting shape(s) are passed to ioCollector.
    /// Note that not all shapes support all transforms (especially true for scaling), the resulting shape will try to match the transform as accurately as possible.
    /// @param inCenterOfMassTransform The transform (rotation, translation, scale) that the center of mass of the shape should get
    /// @param ioCollector The transformed shapes will be passed to this collector
    virtual_TransformShape :: (this: *Shape, inCenterOfMassTransform: *Mat44, ioCollector: *TransformedShapeCollector) -> void #cpp_method #foreign jolt_release "?TransformShape@Shape@JPH@@UEBAXAEBVMat44@2@AEAV?$CollisionCollector@VTransformedShape@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@@Z";

    /// Saves the contents of the shape in binary form to inStream.
    virtual_SaveBinaryState :: (this: *Shape, inStream: *StreamOut) -> void #cpp_method #foreign jolt_release "?SaveBinaryState@Shape@JPH@@UEBAXAEAVStreamOut@2@@Z";

    /// Outputs the material references that this shape has to outMaterials.
    virtual_SaveMaterialState :: (this: *Shape, outMaterials: *PhysicsMaterialList) -> void #cpp_method #foreign jolt_release "?SaveMaterialState@Shape@JPH@@UEBAXAEAV?$Array@V?$RefConst@VPhysicsMaterial@JPH@@@JPH@@V?$STLAllocator@V?$RefConst@VPhysicsMaterial@JPH@@@JPH@@@2@@2@@Z";

    /// Restore the material references after calling sRestoreFromBinaryState. Note that the exact same materials need to be provided in the same order as returned by SaveMaterialState.
    virtual_RestoreMaterialState :: (this: *Shape, inMaterials: *PhysicsMaterialRefC, inNumMaterials: u32) -> void #cpp_method #foreign jolt_release "?RestoreMaterialState@Shape@JPH@@UEAAXPEBV?$RefConst@VPhysicsMaterial@JPH@@@2@I@Z";

    /// Outputs the shape references that this shape has to outSubShapes.
    virtual_SaveSubShapeState :: (this: *Shape, outSubShapes: *ShapeList) -> void #cpp_method #foreign jolt_release "?SaveSubShapeState@Shape@JPH@@UEBAXAEAV?$Array@V?$RefConst@VShape@JPH@@@JPH@@V?$STLAllocator@V?$RefConst@VShape@JPH@@@JPH@@@2@@2@@Z";

    /// Restore the shape references after calling sRestoreFromBinaryState. Note that the exact same shapes need to be provided in the same order as returned by SaveSubShapeState.
    virtual_RestoreSubShapeState :: (this: *Shape, inSubShapes: *ShapeRefC, inNumShapes: u32) -> void #cpp_method #foreign jolt_release "?RestoreSubShapeState@Shape@JPH@@UEAAXPEBV?$RefConst@VShape@JPH@@@2@I@Z";

    /// Get the combined stats of this shape and its children.
    /// @param ioVisitedShapes is used to track which shapes have already been visited, to avoid calculating the wrong memory size.
    virtual_GetStatsRecursive :: (this: *Shape, ioVisitedShapes: *VisitedShapes) -> Stats #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetStatsRecursive@Shape@JPH@@UEBA?AUStats@12@AEAV?$UnorderedSet@PEBVShape@JPH@@U?$Hash@PEBVShape@JPH@@@2@U?$equal_to@PEBVShape@JPH@@@std@@@2@@Z";

    /// Test if inScale is a valid scale for this shape. Some shapes can only be scaled uniformly, compound shapes cannot handle shapes
    /// being rotated and scaled (this would cause shearing), scale can never be zero. When the scale is invalid, the function will return false.
    ///
    /// Here's a list of supported scales:
    /// * SphereShape: Scale must be uniform (signs of scale are ignored).
    /// * BoxShape: Any scale supported (signs of scale are ignored).
    /// * TriangleShape: Any scale supported when convex radius is zero, otherwise only uniform scale supported.
    /// * CapsuleShape: Scale must be uniform (signs of scale are ignored).
    /// * TaperedCapsuleShape: Scale must be uniform (sign of Y scale can be used to flip the capsule).
    /// * CylinderShape: Scale must be uniform in XZ plane, Y can scale independently (signs of scale are ignored).
    /// * RotatedTranslatedShape: Scale must not cause shear in the child shape.
    /// * CompoundShape: Scale must not cause shear in any of the child shapes.
    virtual_IsValidScale :: (this: *Shape, inScale: Vec3) -> bool #cpp_method #foreign jolt_release "?IsValidScale@Shape@JPH@@UEBA_NVVec3@2@@Z";

    /// This function will make sure that if you wrap this shape in a ScaledShape that the scale is valid.
    /// Note that this involves discarding components of the scale that are invalid, so the resulting scaled shape may be different than the requested scale.
    /// Compare the return value of this function with the scale you passed in to detect major inconsistencies and possibly warn the user.
    /// @param inScale Local space scale for this shape.
    /// @return Scale that can be used to wrap this shape in a ScaledShape. IsValidScale will return true for this scale.
    virtual_MakeScaleValid :: (this: *Shape, inScale: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?MakeScaleValid@Shape@JPH@@UEBA?AVVec3@2@V32@@Z";

    /// This function should not be called directly, it is used by sRestoreFromBinaryState.
    virtual_RestoreBinaryState :: (this: *Shape, inStream: *StreamIn) -> void #cpp_method #foreign jolt_release "?RestoreBinaryState@Shape@JPH@@MEAAXAEAVStreamIn@2@@Z";
}
Shape_VTable :: struct #type_info_none {
    Destructor:                  #type (this: *Shape, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    MustBeStatic:                #type (this: *Shape) -> bool #cpp_method;

    GetCenterOfMass:             #type (this: *Shape) -> Vec3 #cpp_method #cpp_return_type_is_non_pod;

    GetLocalBounds:              #type (this: *Shape) -> AABox #cpp_method #cpp_return_type_is_non_pod;

    GetSubShapeIDBitsRecursive:  #type (this: *Shape) -> u32 #cpp_method;

    GetWorldSpaceBounds:         #type (this: *Shape, inCenterOfMassTransform: *Mat44, inScale: Vec3) -> AABox #cpp_method #cpp_return_type_is_non_pod;

    GetInnerRadius:              #type (this: *Shape) -> float #cpp_method;

    GetMassProperties:           #type (this: *Shape) -> MassProperties #cpp_method;

    GetLeafShape:                #type (this: *Shape, inSubShapeID: *SubShapeID, outRemainder: *SubShapeID) -> *Shape #cpp_method;

    GetMaterial:                 #type (this: *Shape, inSubShapeID: *SubShapeID) -> *PhysicsMaterial #cpp_method;

    GetSurfaceNormal:            #type (this: *Shape, inSubShapeID: *SubShapeID, inLocalSurfacePosition: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod;

    GetSupportingFace:           #type (this: *Shape, inSubShapeID: *SubShapeID, inDirection: Vec3, inScale: Vec3, inCenterOfMassTransform: *Mat44, outVertices: *Shape.SupportingFace) -> void #cpp_method;

    GetSubShapeUserData:         #type (this: *Shape, inSubShapeID: *SubShapeID) -> u64 #cpp_method;

    GetSubShapeTransformedShape: #type (this: *Shape, inSubShapeID: *SubShapeID, inPositionCOM: Vec3, inRotation: Quaternion, inScale: Vec3, outRemainder: *SubShapeID) -> TransformedShape #cpp_method #cpp_return_type_is_non_pod;

    GetSubmergedVolume:          #type (this: *Shape, inCenterOfMassTransform: *Mat44, inScale: Vec3, inSurface: *Plane, outTotalVolume: *float, outSubmergedVolume: *float, outCenterOfBuoyancy: *Vec3) -> void #cpp_method;

    CastRay:                     #type (this: /*const*/ *Shape, inRay: /*const reference*/ *RayCast, inRayCastSettings: /*const reference*/ *RayCastSettings, inSubShapeIDCreator: /*const reference*/ *SubShapeIDCreator, ioCollector: /*reference*/ *CastRayCollector, inShapeFilter: /*const reference*/ *ShapeFilter) -> void #cpp_method;

    CastRay_1:                   #type (this: /*const*/ *Shape, inRay: /*const reference*/ *RayCast, inSubShapeIDCreator: /*const reference*/ *SubShapeIDCreator, ioHit: /*reference*/ *RayCastResult) -> bool #cpp_method;

    CollidePoint:                #type (this: *Shape, inPoint: Vec3, inSubShapeIDCreator: *SubShapeIDCreator, ioCollector: *CollidePointCollector, inShapeFilter: *ShapeFilter) -> void #cpp_method;

    CollideSoftBodyVertices:     #type (this: *Shape, inCenterOfMassTransform: *Mat44, inScale: Vec3, inVertices: *CollideSoftBodyVertexIterator, inNumVertices: u32, inCollidingShapeIndex: s32) -> void #cpp_method;

    CollectTransformedShapes:    #type (this: *Shape, inBox: *AABox, inPositionCOM: Vec3, inRotation: Quaternion, inScale: Vec3, inSubShapeIDCreator: *SubShapeIDCreator, ioCollector: *TransformedShapeCollector, inShapeFilter: *ShapeFilter) -> void #cpp_method;

    TransformShape:              #type (this: *Shape, inCenterOfMassTransform: *Mat44, ioCollector: *TransformedShapeCollector) -> void #cpp_method;

    GetTrianglesStart:           #type (this: *Shape, ioContext: *Shape.GetTrianglesContext, inBox: *AABox, inPositionCOM: Vec3, inRotation: Quaternion, inScale: Vec3) -> void #cpp_method;

    GetTrianglesNext:            #type (this: *Shape, ioContext: *Shape.GetTrianglesContext, inMaxTrianglesRequested: s32, outTriangleVertices: *Float3, outMaterials: **PhysicsMaterial = null) -> s32 #cpp_method;

    SaveBinaryState:             #type (this: *Shape, inStream: *StreamOut) -> void #cpp_method;

    SaveMaterialState:           #type (this: *Shape, outMaterials: *PhysicsMaterialList) -> void #cpp_method;

    RestoreMaterialState:        #type (this: *Shape, inMaterials: *PhysicsMaterialRefC, inNumMaterials: u32) -> void #cpp_method;

    SaveSubShapeState:           #type (this: *Shape, outSubShapes: *ShapeList) -> void #cpp_method;

    RestoreSubShapeState:        #type (this: *Shape, inSubShapes: *ShapeRefC, inNumShapes: u32) -> void #cpp_method;

    GetStats:                    #type (this: *Shape) -> Shape.Stats #cpp_method #cpp_return_type_is_non_pod;

    GetStatsRecursive:           #type (this: *Shape, ioVisitedShapes: *Shape.VisitedShapes) -> Shape.Stats #cpp_method #cpp_return_type_is_non_pod;

    GetVolume:                   #type (this: *Shape) -> float #cpp_method;

    IsValidScale:                #type (this: *Shape, inScale: Vec3) -> bool #cpp_method;

    MakeScaleValid:              #type (this: *Shape, inScale: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod;

    RestoreBinaryState:          #type (this: *Shape, inStream: *StreamIn) -> void #cpp_method;
}
Shape_Destructor :: inline (this: *Shape, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

Shape_MustBeStatic :: inline (this: *Shape) -> bool { return this.vtable.MustBeStatic(this); }

Shape_GetCenterOfMass :: inline (this: *Shape) -> Vec3 { return this.vtable.GetCenterOfMass(this); }

Shape_GetLocalBounds :: inline (this: *Shape) -> AABox { return this.vtable.GetLocalBounds(this); }

Shape_GetSubShapeIDBitsRecursive :: inline (this: *Shape) -> u32 { return this.vtable.GetSubShapeIDBitsRecursive(this); }

Shape_GetWorldSpaceBounds :: inline (this: *Shape, inCenterOfMassTransform: *Mat44, inScale: Vec3) -> AABox { return this.vtable.GetWorldSpaceBounds(this, inCenterOfMassTransform, inScale); }

Shape_GetInnerRadius :: inline (this: *Shape) -> float { return this.vtable.GetInnerRadius(this); }

Shape_GetMassProperties :: inline (this: *Shape) -> MassProperties { return this.vtable.GetMassProperties(this); }

Shape_GetLeafShape :: inline (this: *Shape, inSubShapeID: *SubShapeID, outRemainder: *SubShapeID) -> *Shape { return this.vtable.GetLeafShape(this, inSubShapeID, outRemainder); }

Shape_GetMaterial :: inline (this: *Shape, inSubShapeID: *SubShapeID) -> *PhysicsMaterial { return this.vtable.GetMaterial(this, inSubShapeID); }

Shape_GetSurfaceNormal :: inline (this: *Shape, inSubShapeID: *SubShapeID, inLocalSurfacePosition: Vec3) -> Vec3 { return this.vtable.GetSurfaceNormal(this, inSubShapeID, inLocalSurfacePosition); }

Shape_GetSupportingFace :: inline (this: *Shape, inSubShapeID: *SubShapeID, inDirection: Vec3, inScale: Vec3, inCenterOfMassTransform: *Mat44, outVertices: *Shape.SupportingFace) { this.vtable.GetSupportingFace(this, inSubShapeID, inDirection, inScale, inCenterOfMassTransform, outVertices); }

Shape_GetSubShapeUserData :: inline (this: *Shape, inSubShapeID: *SubShapeID) -> u64 { return this.vtable.GetSubShapeUserData(this, inSubShapeID); }

Shape_GetSubShapeTransformedShape :: inline (this: *Shape, inSubShapeID: *SubShapeID, inPositionCOM: Vec3, inRotation: Quaternion, inScale: Vec3, outRemainder: *SubShapeID) -> TransformedShape { return this.vtable.GetSubShapeTransformedShape(this, inSubShapeID, inPositionCOM, inRotation, inScale, outRemainder); }

Shape_GetSubmergedVolume :: inline (this: *Shape, inCenterOfMassTransform: *Mat44, inScale: Vec3, inSurface: *Plane, outTotalVolume: *float, outSubmergedVolume: *float, outCenterOfBuoyancy: *Vec3) { this.vtable.GetSubmergedVolume(this, inCenterOfMassTransform, inScale, inSurface, outTotalVolume, outSubmergedVolume, outCenterOfBuoyancy); }

Shape_CastRay :: inline (this: /*const*/ *Shape, inRay: /*const reference*/ *RayCast, inRayCastSettings: /*const reference*/ *RayCastSettings, inSubShapeIDCreator: /*const reference*/ *SubShapeIDCreator, ioCollector: /*reference*/ *CastRayCollector, inShapeFilter: /*const reference*/ *ShapeFilter) { this.vtable.CastRay(this, inRay, inRayCastSettings, inSubShapeIDCreator, ioCollector, inShapeFilter); }

Shape_CastRay_1 :: inline (this: /*const*/ *Shape, inRay: /*const reference*/ *RayCast, inSubShapeIDCreator: /*const reference*/ *SubShapeIDCreator, ioHit: /*reference*/ *RayCastResult) -> bool { return this.vtable.CastRay_1(this, inRay, inSubShapeIDCreator, ioHit); }

Shape_CollidePoint :: inline (this: *Shape, inPoint: Vec3, inSubShapeIDCreator: *SubShapeIDCreator, ioCollector: *CollidePointCollector, inShapeFilter: *ShapeFilter) { this.vtable.CollidePoint(this, inPoint, inSubShapeIDCreator, ioCollector, inShapeFilter); }

Shape_CollideSoftBodyVertices :: inline (this: *Shape, inCenterOfMassTransform: *Mat44, inScale: Vec3, inVertices: *CollideSoftBodyVertexIterator, inNumVertices: u32, inCollidingShapeIndex: s32) { this.vtable.CollideSoftBodyVertices(this, inCenterOfMassTransform, inScale, inVertices, inNumVertices, inCollidingShapeIndex); }

Shape_CollectTransformedShapes :: inline (this: *Shape, inBox: *AABox, inPositionCOM: Vec3, inRotation: Quaternion, inScale: Vec3, inSubShapeIDCreator: *SubShapeIDCreator, ioCollector: *TransformedShapeCollector, inShapeFilter: *ShapeFilter) { this.vtable.CollectTransformedShapes(this, inBox, inPositionCOM, inRotation, inScale, inSubShapeIDCreator, ioCollector, inShapeFilter); }

Shape_TransformShape :: inline (this: *Shape, inCenterOfMassTransform: *Mat44, ioCollector: *TransformedShapeCollector) { this.vtable.TransformShape(this, inCenterOfMassTransform, ioCollector); }

Shape_GetTrianglesStart :: inline (this: *Shape, ioContext: *Shape.GetTrianglesContext, inBox: *AABox, inPositionCOM: Vec3, inRotation: Quaternion, inScale: Vec3) { this.vtable.GetTrianglesStart(this, ioContext, inBox, inPositionCOM, inRotation, inScale); }

Shape_GetTrianglesNext :: inline (this: *Shape, ioContext: *Shape.GetTrianglesContext, inMaxTrianglesRequested: s32, outTriangleVertices: *Float3, outMaterials: **PhysicsMaterial = null) -> s32 { return this.vtable.GetTrianglesNext(this, ioContext, inMaxTrianglesRequested, outTriangleVertices, outMaterials); }

Shape_SaveBinaryState :: inline (this: *Shape, inStream: *StreamOut) { this.vtable.SaveBinaryState(this, inStream); }

Shape_SaveMaterialState :: inline (this: *Shape, outMaterials: *PhysicsMaterialList) { this.vtable.SaveMaterialState(this, outMaterials); }

Shape_RestoreMaterialState :: inline (this: *Shape, inMaterials: *PhysicsMaterialRefC, inNumMaterials: u32) { this.vtable.RestoreMaterialState(this, inMaterials, inNumMaterials); }

Shape_SaveSubShapeState :: inline (this: *Shape, outSubShapes: *ShapeList) { this.vtable.SaveSubShapeState(this, outSubShapes); }

Shape_RestoreSubShapeState :: inline (this: *Shape, inSubShapes: *ShapeRefC, inNumShapes: u32) { this.vtable.RestoreSubShapeState(this, inSubShapes, inNumShapes); }

Shape_GetStats :: inline (this: *Shape) -> Shape.Stats { return this.vtable.GetStats(this); }

Shape_GetStatsRecursive :: inline (this: *Shape, ioVisitedShapes: *Shape.VisitedShapes) -> Shape.Stats { return this.vtable.GetStatsRecursive(this, ioVisitedShapes); }

Shape_GetVolume :: inline (this: *Shape) -> float { return this.vtable.GetVolume(this); }

Shape_IsValidScale :: inline (this: *Shape, inScale: Vec3) -> bool { return this.vtable.IsValidScale(this, inScale); }

Shape_MakeScaleValid :: inline (this: *Shape, inScale: Vec3) -> Vec3 { return this.vtable.MakeScaleValid(this, inScale); }

Shape_RestoreBinaryState :: inline (this: *Shape, inStream: *StreamIn) { this.vtable.RestoreBinaryState(this, inStream); }

vtable :: (obj: *Shape) -> *Shape_VTable { return obj.vtable; }


/// An object layer can be mapped to a broadphase layer. Objects with the same broadphase layer will end up in the same sub structure (usually a tree) of the broadphase.
/// When there are many layers, this reduces the total amount of sub structures the broad phase needs to manage. Usually you want objects that don't collide with each other
/// in different broad phase layers, but there could be exceptions if objects layers only contain a minor amount of objects so it is not beneficial to give each layer its
/// own sub structure in the broadphase.
/// Note: This class requires explicit casting from and to Type to avoid confusion with ObjectLayer
BroadPhaseLayer :: struct {
    Type :: u8;

    Constructor :: (this: *BroadPhaseLayer, inValue: Type) -> void #cpp_method #foreign jolt_release "??0BroadPhaseLayer@JPH@@QEAA@E@Z";

    mValue: Type;
}

/// Constant value used to indicate an invalid broad phase layer
cBroadPhaseLayerInvalid: BroadPhaseLayer : 255;

/// Interface that the application should implement to allow mapping object layers to broadphase layers
BroadPhaseLayerInterface :: struct {
    vtable:                 *BroadPhaseLayerInterface_VTable;
    using noncopyable__raw: NonCopyable__RAW;
    #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}
BroadPhaseLayerInterface_VTable :: struct #type_info_none {
    Destructor:             #type (this: *BroadPhaseLayerInterface, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    GetNumBroadPhaseLayers: #type (this: *BroadPhaseLayerInterface) -> u32 #cpp_method;

    GetBroadPhaseLayer:     #type (this: *BroadPhaseLayerInterface, inLayer: ObjectLayer) -> BroadPhaseLayer #cpp_method #cpp_return_type_is_non_pod;
}
BroadPhaseLayerInterface_Destructor :: inline (this: *BroadPhaseLayerInterface, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

BroadPhaseLayerInterface_GetNumBroadPhaseLayers :: inline (this: *BroadPhaseLayerInterface) -> u32 { return this.vtable.GetNumBroadPhaseLayers(this); }

BroadPhaseLayerInterface_GetBroadPhaseLayer :: inline (this: *BroadPhaseLayerInterface, inLayer: ObjectLayer) -> BroadPhaseLayer { return this.vtable.GetBroadPhaseLayer(this, inLayer); }

vtable :: (obj: *BroadPhaseLayerInterface) -> *BroadPhaseLayerInterface_VTable { return obj.vtable; }


/// Class to test if an object can collide with a broadphase layer. Used while finding collision pairs.
ObjectVsBroadPhaseLayerFilter :: struct {
    vtable:                 *ObjectVsBroadPhaseLayerFilter_VTable;
    using noncopyable__raw: NonCopyable__RAW;
    #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}
ObjectVsBroadPhaseLayerFilter_VTable :: struct #type_info_none {
    Destructor:    #type (this: *ObjectVsBroadPhaseLayerFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    ShouldCollide: #type (this: *ObjectVsBroadPhaseLayerFilter, inLayer1: ObjectLayer, inLayer2: BroadPhaseLayer) -> bool #cpp_method;
}
ObjectVsBroadPhaseLayerFilter_Destructor :: inline (this: *ObjectVsBroadPhaseLayerFilter, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

ObjectVsBroadPhaseLayerFilter_ShouldCollide :: inline (this: *ObjectVsBroadPhaseLayerFilter, inLayer1: ObjectLayer, inLayer2: BroadPhaseLayer) -> bool { return this.vtable.ShouldCollide(this, inLayer1, inLayer2); }

vtable :: (obj: *ObjectVsBroadPhaseLayerFilter) -> *ObjectVsBroadPhaseLayerFilter_VTable { return obj.vtable; }


/// Filter class for broadphase layers
BroadPhaseLayerFilter :: struct {
    vtable:                 *BroadPhaseLayerFilter_VTable;
    using noncopyable__raw: NonCopyable__RAW;
    #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Destructor
    virtual_Destructor :: (this: *BroadPhaseLayerFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1BroadPhaseLayerFilter@JPH@@UEAA@XZ";

    /// Function to filter out broadphase layers when doing collision query test (return true to allow testing against objects with this layer)
    virtual_ShouldCollide :: (this: *BroadPhaseLayerFilter, inLayer: BroadPhaseLayer) -> bool #cpp_method #foreign jolt_release "?ShouldCollide@BroadPhaseLayerFilter@JPH@@UEBA_NVBroadPhaseLayer@2@@Z";
}
BroadPhaseLayerFilter_VTable :: struct #type_info_none {
    Destructor:    #type (this: *BroadPhaseLayerFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    ShouldCollide: #type (this: *BroadPhaseLayerFilter, inLayer: BroadPhaseLayer) -> bool #cpp_method;
}
BroadPhaseLayerFilter_Destructor :: inline (this: *BroadPhaseLayerFilter, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

BroadPhaseLayerFilter_ShouldCollide :: inline (this: *BroadPhaseLayerFilter, inLayer: BroadPhaseLayer) -> bool { return this.vtable.ShouldCollide(this, inLayer); }

vtable :: (obj: *BroadPhaseLayerFilter) -> *BroadPhaseLayerFilter_VTable { return obj.vtable; }


/// Default filter class that uses the pair filter in combination with a specified layer to filter layers
DefaultBroadPhaseLayerFilter :: struct {
    #as using broadphaselayerfilter: BroadPhaseLayerFilter;

    /// Constructor
    Constructor :: (this: *DefaultBroadPhaseLayerFilter, inObjectVsBroadPhaseLayerFilter: *ObjectVsBroadPhaseLayerFilter, inLayer: ObjectLayer) -> void #cpp_method #foreign jolt_release "??0DefaultBroadPhaseLayerFilter@JPH@@QEAA@AEBVObjectVsBroadPhaseLayerFilter@1@G@Z";
    Constructor :: (this: *DefaultBroadPhaseLayerFilter, inObjectVsBroadPhaseLayerFilter: ObjectVsBroadPhaseLayerFilter, inLayer: ObjectLayer) #no_context {
        Constructor(this, *inObjectVsBroadPhaseLayerFilter, inLayer);
    }

    mObjectVsBroadPhaseLayerFilter:  *ObjectVsBroadPhaseLayerFilter;
    mLayer:                          ObjectLayer;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    // See BroadPhaseLayerFilter::ShouldCollide
    virtual_ShouldCollide :: (this: *DefaultBroadPhaseLayerFilter, inLayer: BroadPhaseLayer) -> bool #cpp_method #foreign jolt_release "?ShouldCollide@DefaultBroadPhaseLayerFilter@JPH@@UEBA_NVBroadPhaseLayer@2@@Z";
}

/// Allows objects from a specific broad phase layer only
SpecifiedBroadPhaseLayerFilter :: struct {
    #as using broadphaselayerfilter: BroadPhaseLayerFilter;

    mLayer:                          BroadPhaseLayer;
}

/// Abstract class that checks if two CollisionGroups collide
GroupFilter :: struct {
    #as using,except(vtable, sCreateRTTI) serializableobject: SerializableObject;
    #as using reftarget:    RefTarget(GroupFilter);

    sCreateRTTI :: (inRTTI: *RTTI) -> void #foreign jolt_release "?sCreateRTTI@GroupFilter@JPH@@SAXAEAVRTTI@2@@Z";

    GroupFilterResult :: Result(Ref(GroupFilter));

    /// Creates a GroupFilter of the correct type and restores its contents from the binary stream inStream.
    sRestoreFromBinaryState :: (inStream: *StreamIn) -> GroupFilterResult #foreign jolt_release "?sRestoreFromBinaryState@GroupFilter@JPH@@SA?AV?$Result@V?$Ref@VGroupFilter@JPH@@@JPH@@@2@AEAVStreamIn@2@@Z";

    /// Don't allow (copy) constructing this base class, but allow derived classes to (copy) construct themselves
    Constructor :: (this: *GroupFilter) -> void #cpp_method #foreign jolt_release "??0GroupFilter@JPH@@IEAA@XZ";
    #overlay (serializableobject) vtable: *GroupFilter_VTable; // Overlay parent's vtable with GroupFilter’s vtable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_GetRTTI :: (this: *GroupFilter) -> *RTTI #cpp_method #foreign jolt_release "?GetRTTI@GroupFilter@JPH@@UEBAPEBVRTTI@2@XZ";
    virtual_CastTo :: (this: *GroupFilter, inRTTI: *RTTI) -> *void #cpp_method #foreign jolt_release "?CastTo@GroupFilter@JPH@@UEBAPEBXPEBVRTTI@2@@Z";

    /// Virtual destructor
    virtual_Destructor :: (this: *GroupFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1GroupFilter@JPH@@UEAA@XZ";

    /// Saves the contents of the group filter in binary form to inStream.
    virtual_SaveBinaryState :: (this: *GroupFilter, inStream: *StreamOut) -> void #cpp_method #foreign jolt_release "?SaveBinaryState@GroupFilter@JPH@@UEBAXAEAVStreamOut@2@@Z";

    /// This function should not be called directly, it is used by sRestoreFromBinaryState.
    virtual_RestoreBinaryState :: (this: *GroupFilter, inStream: *StreamIn) -> void #cpp_method #foreign jolt_release "?RestoreBinaryState@GroupFilter@JPH@@MEAAXAEAVStreamIn@2@@Z";
}
GroupFilter_VTable :: struct #type_info_none {
    using vtable:       SerializableObject_VTable;

    CanCollide:         #type (this: *GroupFilter, inGroup1: *CollisionGroup, inGroup2: *CollisionGroup) -> bool #cpp_method;

    SaveBinaryState:    #type (this: *GroupFilter, inStream: *StreamOut) -> void #cpp_method;

    RestoreBinaryState: #type (this: *GroupFilter, inStream: *StreamIn) -> void #cpp_method;
}
GroupFilter_CanCollide :: inline (this: *GroupFilter, inGroup1: *CollisionGroup, inGroup2: *CollisionGroup) -> bool { return this.vtable.CanCollide(this, inGroup1, inGroup2); }

GroupFilter_SaveBinaryState :: inline (this: *GroupFilter, inStream: *StreamOut) { this.vtable.SaveBinaryState(this, inStream); }

GroupFilter_RestoreBinaryState :: inline (this: *GroupFilter, inStream: *StreamIn) { this.vtable.RestoreBinaryState(this, inStream); }

vtable :: (obj: *GroupFilter) -> *GroupFilter_VTable { return obj.vtable; }


/// Two objects collide with each other if:
/// - Both don't have a group filter
/// - The first group filter says that the objects can collide
/// - Or if there's no filter for the first object, the second group filter says the objects can collide
CollisionGroup :: struct {
    sCreateRTTI :: (inRTTI: *RTTI) -> void #foreign jolt_release "?sCreateRTTI@CollisionGroup@JPH@@SAXAEAVRTTI@2@@Z";

    GroupID :: u32;
    SubGroupID :: u32;

    cInvalidGroup:    GroupID : ~0;
    cInvalidSubGroup: SubGroupID : ~0;

    /// Default constructor
    Constructor :: (this: *CollisionGroup) -> void #cpp_method #foreign jolt_release "??0CollisionGroup@JPH@@QEAA@XZ";

    /// Set the collision group filter
    SetGroupFilter :: (this: *CollisionGroup, inFilter: *GroupFilter) -> void #cpp_method #foreign jolt_release "?SetGroupFilter@CollisionGroup@JPH@@QEAAXPEBVGroupFilter@2@@Z";

    /// Get the collision group filter
    GetGroupFilter :: (this: *CollisionGroup) -> *GroupFilter #cpp_method #foreign jolt_release "?GetGroupFilter@CollisionGroup@JPH@@QEBAPEBVGroupFilter@2@XZ";

    /// Set the main group id for this object
    SetGroupID :: (this: *CollisionGroup, inID: GroupID) -> void #cpp_method #foreign jolt_release "?SetGroupID@CollisionGroup@JPH@@QEAAXI@Z";

    GetGroupID :: (this: *CollisionGroup) -> GroupID #cpp_method #foreign jolt_release "?GetGroupID@CollisionGroup@JPH@@QEBAIXZ";

    /// Add this object to a sub group
    SetSubGroupID :: (this: *CollisionGroup, inID: SubGroupID) -> void #cpp_method #foreign jolt_release "?SetSubGroupID@CollisionGroup@JPH@@QEAAXI@Z";

    GetSubGroupID :: (this: *CollisionGroup) -> SubGroupID #cpp_method #foreign jolt_release "?GetSubGroupID@CollisionGroup@JPH@@QEBAIXZ";

    /// Check if this object collides with another object
    CanCollide :: (this: *CollisionGroup, inOther: *CollisionGroup) -> bool #cpp_method #foreign jolt_release "?CanCollide@CollisionGroup@JPH@@QEBA_NAEBV12@@Z";
    CanCollide :: (this: *CollisionGroup, inOther: CollisionGroup) -> bool #no_context {
        return CanCollide(this, *inOther);
    }

    /// Saves the state of this object in binary form to inStream. Does not save group filter.
    SaveBinaryState :: (this: *CollisionGroup, inStream: *StreamOut) -> void #cpp_method #foreign jolt_release "?SaveBinaryState@CollisionGroup@JPH@@QEBAXAEAVStreamOut@2@@Z";

    /// Restore the state of this object from inStream. Does not save group filter.
    RestoreBinaryState :: (this: *CollisionGroup, inStream: *StreamIn) -> void #cpp_method #foreign jolt_release "?RestoreBinaryState@CollisionGroup@JPH@@QEAAXAEAVStreamIn@2@@Z";

    mGroupFilter:     RefConst(GroupFilter);
    mGroupID:         GroupID = cInvalidGroup;
    mSubGroupID:      SubGroupID = cInvalidSubGroup;
}

/// @brief A sub shape id contains a path to an element (usually a triangle or other primitive type) of a compound shape
///
/// Each sub shape knows how many bits it needs to encode its ID, so knows how many bits to take from the sub shape ID.
///
/// For example:
/// * We have a CompoundShape A with 5 child shapes (identify sub shape using 3 bits AAA)
/// * One of its child shapes is CompoundShape B which has 3 child shapes (identify sub shape using 2 bits BB)
/// * One of its child shapes is MeshShape C which contains enough triangles to need 7 bits to identify a triangle (identify sub shape using 7 bits CCCCCCC, note that MeshShape is block based and sorts triangles spatially, you can't assume that the first triangle will have bit pattern 0000000).
///
/// The bit pattern of the sub shape ID to identify a triangle in MeshShape C will then be CCCCCCCBBAAA.
///
/// A sub shape ID will become invalid when the structure of the shape changes. For example, if a child shape is removed from a compound shape, the sub shape ID will no longer be valid.
/// This can be a problem when caching sub shape IDs from one frame to the next. See comments at ContactListener::OnContactPersisted / OnContactRemoved.
SubShapeID :: struct {
    /// Underlying storage type
    Type :: u32;

    /// Type that is bigger than the underlying storage type for operations that would otherwise overflow
    BiggerType :: u64;

    /// How many bits we can store in this ID
    MaxBits:    u32 : 8 * 4;

    /// Constructor
    Constructor :: (this: *SubShapeID) -> void #cpp_method #foreign jolt_release "??0SubShapeID@JPH@@QEAA@XZ";

    /// Get the next id in the chain of ids (pops parents before children)
    PopID :: (this: *SubShapeID, inBits: u32, outRemainder: *SubShapeID) -> Type #cpp_method #foreign jolt_release "?PopID@SubShapeID@JPH@@QEBAIIAEAV12@@Z";

    /// Get the value of the path to the sub shape ID
    GetValue :: (this: *SubShapeID) -> Type #cpp_method #foreign jolt_release "?GetValue@SubShapeID@JPH@@QEBAIXZ";

    /// An empty SubShapeID has all bits set
    cEmpty:     Type : ~0;

    /// Constructor
    Constructor :: (this: *SubShapeID, inValue: *Type) -> void #cpp_method #foreign jolt_release "??0SubShapeID@JPH@@AEAA@AEBI@Z";
    Constructor :: (this: *SubShapeID, inValue: Type) #no_context {
        Constructor(this, *inValue);
    }

    /// Adds an id at a particular position in the chain
    /// (this should really only be called by the SubShapeIDCreator)
    PushID :: (this: *SubShapeID, inValue: Type, inFirstBit: u32, inBits: u32) -> void #cpp_method #foreign jolt_release "?PushID@SubShapeID@JPH@@AEAAXIII@Z";

    mValue:     Type = cEmpty;
}

/// A sub shape id creator can be used to create a new sub shape id by recursing through the shape
/// hierarchy and pushing new ID's onto the chain
SubShapeIDCreator :: struct {
    /// Add a new id to the chain of id's and return it
    PushID :: (this: *SubShapeIDCreator, inValue: u32, inBits: u32) -> SubShapeIDCreator #cpp_method #foreign jolt_release "?PushID@SubShapeIDCreator@JPH@@QEBA?AV12@II@Z";

    // Get the resulting sub shape ID
    GetID :: (this: *SubShapeIDCreator) -> *SubShapeID #cpp_method #foreign jolt_release "?GetID@SubShapeIDCreator@JPH@@QEBAAEBVSubShapeID@2@XZ";

    /// Get the number of bits that have been written to the sub shape ID so far
    GetNumBitsWritten :: (this: *SubShapeIDCreator) -> u32 #cpp_method #foreign jolt_release "?GetNumBitsWritten@SubShapeIDCreator@JPH@@QEBAIXZ";

    mID:         SubShapeID;
    mCurrentBit: u32 = 0;
}

RRayCast :: struct {}
RShapeCast :: struct {}
CollideShapeSettings :: struct {}

/// Temporary data structure that contains a shape and a transform.
/// This structure can be obtained from a body (e.g. after a broad phase query) under lock protection.
/// The lock can then be released and collision detection operations can be safely performed since
/// the class takes a reference on the shape and does not use anything from the body anymore.
TransformedShape :: struct {
    /// Constructor
    Constructor :: (this: *TransformedShape) -> void #cpp_method #foreign jolt_release "??0TransformedShape@JPH@@QEAA@XZ";
    Constructor :: (this: *TransformedShape, inPositionCOM: Vector3, inRotation: Quaternion, inShape: *Shape, inBodyID: *BodyID, inSubShapeIDCreator: *SubShapeIDCreator) -> void #cpp_method #foreign jolt_release "??0TransformedShape@JPH@@QEAA@VVec3@1@VQuat@1@PEBVShape@1@AEBVBodyID@1@AEBVSubShapeIDCreator@1@@Z";
    Constructor :: (this: *TransformedShape, inPositionCOM: Vector3, inRotation: Quaternion, inShape: *Shape, inBodyID: BodyID, inSubShapeIDCreator: SubShapeIDCreator = SubShapeIDCreator.{}) #no_context {
        Constructor(this, inPositionCOM, inRotation, inShape, *inBodyID, *inSubShapeIDCreator);
    }

    /// Cast a ray and find the closest hit. Returns true if it finds a hit. Hits further than ioHit.mFraction will not be considered and in this case ioHit will remain unmodified (and the function will return false).
    /// Convex objects will be treated as solid (meaning if the ray starts inside, you'll get a hit fraction of 0) and back face hits are returned.
    /// If you want the surface normal of the hit use GetWorldSpaceSurfaceNormal(ioHit.mSubShapeID2, inRay.GetPointOnRay(ioHit.mFraction)) on this object.
    CastRay :: (this: *TransformedShape, inRay: *RRayCast, ioHit: *RayCastResult) -> bool #cpp_method #foreign jolt_release "?CastRay@TransformedShape@JPH@@QEBA_NAEBURRayCast@2@AEAVRayCastResult@2@@Z";
    CastRay :: (this: *TransformedShape, inRay: RRayCast, ioHit: *RayCastResult) -> bool #no_context {
        return CastRay(this, *inRay, ioHit);
    }

    /// Cast a ray, allows collecting multiple hits. Note that this version is more flexible but also slightly slower than the CastRay function that returns only a single hit.
    /// If you want the surface normal of the hit use GetWorldSpaceSurfaceNormal(collected sub shape ID, inRay.GetPointOnRay(collected fraction)) on this object.
    CastRay :: (this: *TransformedShape, inRay: *RRayCast, inRayCastSettings: *RayCastSettings, ioCollector: *CastRayCollector, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CastRay@TransformedShape@JPH@@QEBAXAEBURRayCast@2@AEBVRayCastSettings@2@AEAV?$CollisionCollector@VRayCastResult@JPH@@VCollisionCollectorTraitsCastRay@2@@2@AEBVShapeFilter@2@@Z";
    CastRay :: (this: *TransformedShape, inRay: RRayCast, inRayCastSettings: RayCastSettings, ioCollector: *CastRayCollector, inShapeFilter: ShapeFilter) #no_context {
        CastRay(this, *inRay, *inRayCastSettings, ioCollector, *inShapeFilter);
    }

    /// Check if inPoint is inside any shapes. For this tests all shapes are treated as if they were solid.
    /// For a mesh shape, this test will only provide sensible information if the mesh is a closed manifold.
    /// For each shape that collides, ioCollector will receive a hit
    CollidePoint :: (this: *TransformedShape, inPoint: Vector3, ioCollector: *CollidePointCollector, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CollidePoint@TransformedShape@JPH@@QEBAXVVec3@2@AEAV?$CollisionCollector@VCollidePointResult@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVShapeFilter@2@@Z";
    CollidePoint :: (this: *TransformedShape, inPoint: Vector3, ioCollector: *CollidePointCollector, inShapeFilter: ShapeFilter) #no_context {
        CollidePoint(this, inPoint, ioCollector, *inShapeFilter);
    }

    /// Collide a shape and report any hits to ioCollector
    /// @param inShape Shape to test
    /// @param inShapeScale Scale in local space of shape
    /// @param inCenterOfMassTransform Center of mass transform for the shape
    /// @param inCollideShapeSettings Settings
    /// @param inBaseOffset All hit results will be returned relative to this offset, can be zero to get results in world position, but when you're testing far from the origin you get better precision by picking a position that's closer e.g. mShapePositionCOM since floats are most accurate near the origin
    /// @param ioCollector Collector that receives the hits
    /// @param inShapeFilter Filter that allows you to reject collisions
    CollideShape :: (this: *TransformedShape, inShape: *Shape, inShapeScale: Vec3, inCenterOfMassTransform: Matrix4, inCollideShapeSettings: *CollideShapeSettings, inBaseOffset: Vector3, ioCollector: *CollideShapeCollector, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CollideShape@TransformedShape@JPH@@QEBAXPEBVShape@2@VVec3@2@AEBVMat44@2@AEBVCollideShapeSettings@2@1AEAV?$CollisionCollector@VCollideShapeResult@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVShapeFilter@2@@Z";
    CollideShape :: (this: *TransformedShape, inShape: *Shape, inShapeScale: Vec3, inCenterOfMassTransform: Matrix4, inCollideShapeSettings: CollideShapeSettings, inBaseOffset: Vector3, ioCollector: *CollideShapeCollector, inShapeFilter: ShapeFilter) #no_context {
        CollideShape(this, inShape, inShapeScale, inCenterOfMassTransform, *inCollideShapeSettings, inBaseOffset, ioCollector, *inShapeFilter);
    }

    /// Cast a shape and report any hits to ioCollector
    /// @param inShapeCast The shape cast and its position and direction
    /// @param inShapeCastSettings Settings for the shape cast
    /// @param inBaseOffset All hit results will be returned relative to this offset, can be zero to get results in world position, but when you're testing far from the origin you get better precision by picking a position that's closer e.g. mShapePositionCOM or inShapeCast.mCenterOfMassStart.GetTranslation() since floats are most accurate near the origin
    /// @param ioCollector Collector that receives the hits
    /// @param inShapeFilter Filter that allows you to reject collisions
    CastShape :: (this: *TransformedShape, inShapeCast: *RShapeCast, inShapeCastSettings: *ShapeCastSettings, inBaseOffset: Vector3, ioCollector: *CastShapeCollector, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CastShape@TransformedShape@JPH@@QEBAXAEBURShapeCast@2@AEBVShapeCastSettings@2@VVec3@2@AEAV?$CollisionCollector@VShapeCastResult@JPH@@VCollisionCollectorTraitsCastShape@2@@2@AEBVShapeFilter@2@@Z";
    CastShape :: (this: *TransformedShape, inShapeCast: RShapeCast, inShapeCastSettings: ShapeCastSettings, inBaseOffset: Vector3, ioCollector: *CastShapeCollector, inShapeFilter: ShapeFilter) #no_context {
        CastShape(this, *inShapeCast, *inShapeCastSettings, inBaseOffset, ioCollector, *inShapeFilter);
    }

    /// Collect the leaf transformed shapes of all leaf shapes of this shape
    /// inBox is the world space axis aligned box which leaf shapes should collide with
    CollectTransformedShapes :: (this: *TransformedShape, inBox: *AABox, ioCollector: *TransformedShapeCollector, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CollectTransformedShapes@TransformedShape@JPH@@QEBAXAEBVAABox@2@AEAV?$CollisionCollector@VTransformedShape@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVShapeFilter@2@@Z";
    CollectTransformedShapes :: (this: *TransformedShape, inBox: AABox, ioCollector: *TransformedShapeCollector, inShapeFilter: ShapeFilter) #no_context {
        CollectTransformedShapes(this, *inBox, ioCollector, *inShapeFilter);
    }

    /// Use the context from Shape
    GetTrianglesContext :: Shape.GetTrianglesContext;

    /// To start iterating over triangles, call this function first.
    /// To get the actual triangles call GetTrianglesNext.
    /// @param ioContext A temporary buffer and should remain untouched until the last call to GetTrianglesNext.
    /// @param inBox The world space bounding in which you want to get the triangles.
    /// @param inBaseOffset All hit results will be returned relative to this offset, can be zero to get results in world position, but when you're testing far from the origin you get better precision by picking a position that's closer e.g. inBox.GetCenter() since floats are most accurate near the origin
    GetTrianglesStart :: (this: *TransformedShape, ioContext: *GetTrianglesContext, inBox: *AABox, inBaseOffset: Vector3) -> void #cpp_method #foreign jolt_release "?GetTrianglesStart@TransformedShape@JPH@@QEBAXAEAUGetTrianglesContext@Shape@2@AEBVAABox@2@VVec3@2@@Z";
    GetTrianglesStart :: (this: *TransformedShape, ioContext: *GetTrianglesContext, inBox: AABox, inBaseOffset: Vector3) #no_context {
        GetTrianglesStart(this, ioContext, *inBox, inBaseOffset);
    }

    /// Call this repeatedly to get all triangles in the box.
    /// outTriangleVertices should be large enough to hold 3 * inMaxTriangleRequested entries
    /// outMaterials (if it is not null) should contain inMaxTrianglesRequested entries
    /// The function returns the amount of triangles that it found (which will be <= inMaxTrianglesRequested), or 0 if there are no more triangles.
    /// Note that the function can return a value < inMaxTrianglesRequested and still have more triangles to process (triangles can be returned in blocks)
    /// Note that the function may return triangles outside of the requested box, only coarse culling is performed on the returned triangles
    GetTrianglesNext :: (this: *TransformedShape, ioContext: *GetTrianglesContext, inMaxTrianglesRequested: s32, outTriangleVertices: *Float3, outMaterials: **PhysicsMaterial = null) -> s32 #cpp_method #foreign jolt_release "?GetTrianglesNext@TransformedShape@JPH@@QEBAHAEAUGetTrianglesContext@Shape@2@HPEAVFloat3@2@PEAPEBVPhysicsMaterial@2@@Z";

    /// Get/set the scale of the shape as a Vec3
    GetShapeScale :: (this: *TransformedShape) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetShapeScale@TransformedShape@JPH@@QEBA?AVVec3@2@XZ";
    SetShapeScale :: (this: *TransformedShape, inScale: Vec3) -> void #cpp_method #foreign jolt_release "?SetShapeScale@TransformedShape@JPH@@QEAAXVVec3@2@@Z";

    /// Calculates the transform for this shape's center of mass (excluding scale)
    GetCenterOfMassTransform :: (this: *TransformedShape) -> Mat44 #cpp_method #foreign jolt_release "?GetCenterOfMassTransform@TransformedShape@JPH@@QEBA?AVMat44@2@XZ";

    /// Calculates the inverse of the transform for this shape's center of mass (excluding scale)
    GetInverseCenterOfMassTransform :: (this: *TransformedShape) -> Mat44 #cpp_method #foreign jolt_release "?GetInverseCenterOfMassTransform@TransformedShape@JPH@@QEBA?AVMat44@2@XZ";

    /// Make inSubShapeID relative to mShape. When mSubShapeIDCreator is not empty, this is needed in order to get the correct path to the sub shape.
    MakeSubShapeIDRelativeToShape :: (this: *TransformedShape, inSubShapeID: *SubShapeID) -> SubShapeID #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?MakeSubShapeIDRelativeToShape@TransformedShape@JPH@@QEBA?AVSubShapeID@2@AEBV32@@Z";
    MakeSubShapeIDRelativeToShape :: (this: *TransformedShape, inSubShapeID: SubShapeID) -> SubShapeID #no_context {
        return MakeSubShapeIDRelativeToShape(this, *inSubShapeID);
    }

    /// Get surface normal of a particular sub shape and its world space surface position on this body.
    /// Note: When you have a CollideShapeResult or ShapeCastResult you should use -mPenetrationAxis.Normalized() as contact normal as GetWorldSpaceSurfaceNormal will only return face normals (and not vertex or edge normals).
    GetWorldSpaceSurfaceNormal :: (this: *TransformedShape, inSubShapeID: *SubShapeID, inPosition: Vector3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetWorldSpaceSurfaceNormal@TransformedShape@JPH@@QEBA?AVVec3@2@AEBVSubShapeID@2@V32@@Z";
    GetWorldSpaceSurfaceNormal :: (this: *TransformedShape, inSubShapeID: SubShapeID, inPosition: Vector3) -> Vec3 #no_context {
        return GetWorldSpaceSurfaceNormal(this, *inSubShapeID, inPosition);
    }

    /// Get the vertices of the face that faces inDirection the most (includes any convex radius). Note that this function can only return faces of
    /// convex shapes or triangles, which is why a sub shape ID to get to that leaf must be provided.
    /// @param inSubShapeID Sub shape ID of target shape
    /// @param inDirection Direction that the face should be facing (in world space)
    /// @param inBaseOffset The vertices will be returned relative to this offset, can be zero to get results in world position, but when you're testing far from the origin you get better precision by picking a position that's closer e.g. mShapePositionCOM since floats are most accurate near the origin
    /// @param outVertices Resulting face. Note the returned face can have a single point if the shape doesn't have polygons to return (e.g. because it's a sphere). The face will be returned in world space.
    GetSupportingFace :: (this: *TransformedShape, inSubShapeID: *SubShapeID, inDirection: Vec3, inBaseOffset: Vector3, outVertices: *Shape.SupportingFace) -> void #cpp_method #foreign jolt_release "?GetSupportingFace@TransformedShape@JPH@@QEBAXAEBVSubShapeID@2@VVec3@2@1AEAV?$StaticArray@VVec3@JPH@@$0CA@@2@@Z";
    GetSupportingFace :: (this: *TransformedShape, inSubShapeID: SubShapeID, inDirection: Vec3, inBaseOffset: Vector3, outVertices: *Shape.SupportingFace) #no_context {
        GetSupportingFace(this, *inSubShapeID, inDirection, inBaseOffset, outVertices);
    }

    /// Get material of a particular sub shape
    GetMaterial :: (this: *TransformedShape, inSubShapeID: *SubShapeID) -> *PhysicsMaterial #cpp_method #foreign jolt_release "?GetMaterial@TransformedShape@JPH@@QEBAPEBVPhysicsMaterial@2@AEBVSubShapeID@2@@Z";
    GetMaterial :: (this: *TransformedShape, inSubShapeID: SubShapeID) -> *PhysicsMaterial #no_context {
        return GetMaterial(this, *inSubShapeID);
    }

    /// Helper function to return the body id from a transformed shape. If the transformed shape is null an invalid body ID will be returned.
    sGetBodyID :: (inTS: *TransformedShape) -> BodyID #cpp_return_type_is_non_pod #foreign jolt_release "?sGetBodyID@TransformedShape@JPH@@SA?AVBodyID@2@PEBV12@@Z";

    mShapePositionCOM:   Vec3; ///< Center of mass world position of the shape
    mShapeRotation:      Quat; ///< Rotation of the shape
    mShape:              RefConst(Shape); ///< The shape itself
    mShapeScale:         Float3 = 1; ///< Not stored as Vec3 to get a nicely packed structure
    mBodyID:             BodyID; ///< Optional body ID from which this shape comes
    mSubShapeIDCreator:  SubShapeIDCreator; ///< Optional sub shape ID creator for the shape (can be used when expanding compound shapes into multiple transformed shapes)
}

Sphere :: struct {
    Constructor :: (this: *Sphere, inCenter: Vec3, inRadius: float) -> void #cpp_method #foreign jolt_release "??0Sphere@JPH@@QEAA@VVec3@1@M@Z";

    // Properties
    GetCenter :: (this: *Sphere) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetCenter@Sphere@JPH@@QEBA?AVVec3@2@XZ";
    GetRadius :: (this: *Sphere) -> float #cpp_method #foreign jolt_release "?GetRadius@Sphere@JPH@@QEBAMXZ";

    /// Create the minimal sphere that encapsulates this sphere and inPoint
    EncapsulatePoint :: (this: *Sphere, inPoint: Vec3) -> void #cpp_method #foreign jolt_release "?EncapsulatePoint@Sphere@JPH@@QEAAXVVec3@2@@Z";

    mCenter: Float3;
    mRadius: float;
}

/// Enum used in BodyCreationSettings and MotionProperties to indicate which degrees of freedom a body has
EAllowedDOFs :: enum u8 {
    None         :: 0;
    All          :: 63;
    TranslationX :: 1;
    TranslationY :: 2;
    TranslationZ :: 4;
    RotationX    :: 8;
    RotationY    :: 16;
    RotationZ    :: 32;
    Plane2D      :: 35;
}

BodyAccess :: struct {
    __empty_struct_padding: u8; // C++ makes empty structs have length 1

    /// Access rules, used to detect race conditions during simulation
    EAccess :: enum u8 {
        None      :: 0;
        Read      :: 1;
        ReadWrite :: 3;
    }

    /// Grant a scope specific access rights on the current thread
    Grant :: struct {
        __empty_struct_padding: u8; // C++ makes empty structs have length 1
    }
}

/// Enum that determines if an object can go to sleep
ECanSleep :: enum s32 {
    notSleep :: 0;
    Sleep    :: 1;

    CannotSleep :: notSleep;
    CanSleep    :: Sleep;
}

/// The Body class only keeps track of state for static bodies, the MotionProperties class keeps the additional state needed for a moving Body. It has a 1-on-1 relationship with the body.
MotionProperties :: struct {
    /// Motion quality, or how well it detects collisions when it has a high velocity
    GetMotionQuality :: (this: *MotionProperties) -> EMotionQuality #cpp_method #foreign jolt_release "?GetMotionQuality@MotionProperties@JPH@@QEBA?AW4EMotionQuality@2@XZ";

    /// Get the allowed degrees of freedom that this body has (this can be changed by calling SetMassProperties)
    GetAllowedDOFs :: (this: *MotionProperties) -> EAllowedDOFs #cpp_method #foreign jolt_release "?GetAllowedDOFs@MotionProperties@JPH@@QEBA?AW4EAllowedDOFs@2@XZ";

    /// If this body can go to sleep.
    GetAllowSleeping :: (this: *MotionProperties) -> bool #cpp_method #foreign jolt_release "?GetAllowSleeping@MotionProperties@JPH@@QEBA_NXZ";

    /// Get world space linear velocity of the center of mass
    GetLinearVelocity :: (this: *MotionProperties) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetLinearVelocity@MotionProperties@JPH@@QEBA?AVVec3@2@XZ";

    /// Set world space linear velocity of the center of mass
    SetLinearVelocity :: (this: *MotionProperties, inLinearVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?SetLinearVelocity@MotionProperties@JPH@@QEAAXVVec3@2@@Z";

    /// Set world space linear velocity of the center of mass, will make sure the value is clamped against the maximum linear velocity
    SetLinearVelocityClamped :: (this: *MotionProperties, inLinearVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?SetLinearVelocityClamped@MotionProperties@JPH@@QEAAXVVec3@2@@Z";

    /// Get world space angular velocity of the center of mass
    GetAngularVelocity :: (this: *MotionProperties) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetAngularVelocity@MotionProperties@JPH@@QEBA?AVVec3@2@XZ";

    /// Set world space angular velocity of the center of mass
    SetAngularVelocity :: (this: *MotionProperties, inAngularVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?SetAngularVelocity@MotionProperties@JPH@@QEAAXVVec3@2@@Z";

    /// Set world space angular velocity of the center of mass, will make sure the value is clamped against the maximum angular velocity
    SetAngularVelocityClamped :: (this: *MotionProperties, inAngularVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?SetAngularVelocityClamped@MotionProperties@JPH@@QEAAXVVec3@2@@Z";

    /// Set velocity of body such that it will be rotate/translate by inDeltaPosition/Rotation in inDeltaTime seconds.
    MoveKinematic :: (this: *MotionProperties, inDeltaPosition: Vec3, inDeltaRotation: Quaternion, inDeltaTime: float) -> void #cpp_method #foreign jolt_release "?MoveKinematic@MotionProperties@JPH@@QEAAXVVec3@2@VQuat@2@M@Z";

    /// Maximum linear velocity that a body can achieve. Used to prevent the system from exploding.
    GetMaxLinearVelocity :: (this: *MotionProperties) -> float #cpp_method #foreign jolt_release "?GetMaxLinearVelocity@MotionProperties@JPH@@QEBAMXZ";
    SetMaxLinearVelocity :: (this: *MotionProperties, inLinearVelocity: float) -> void #cpp_method #foreign jolt_release "?SetMaxLinearVelocity@MotionProperties@JPH@@QEAAXM@Z";

    /// Maximum angular velocity that a body can achieve. Used to prevent the system from exploding.
    GetMaxAngularVelocity :: (this: *MotionProperties) -> float #cpp_method #foreign jolt_release "?GetMaxAngularVelocity@MotionProperties@JPH@@QEBAMXZ";
    SetMaxAngularVelocity :: (this: *MotionProperties, inAngularVelocity: float) -> void #cpp_method #foreign jolt_release "?SetMaxAngularVelocity@MotionProperties@JPH@@QEAAXM@Z";

    /// Clamp velocity according to limit
    ClampLinearVelocity :: (this: *MotionProperties) -> void #cpp_method #foreign jolt_release "?ClampLinearVelocity@MotionProperties@JPH@@QEAAXXZ";

    ClampAngularVelocity :: (this: *MotionProperties) -> void #cpp_method #foreign jolt_release "?ClampAngularVelocity@MotionProperties@JPH@@QEAAXXZ";

    /// Get linear damping: dv/dt = -c * v. c. Value should be zero or positive and is usually close to 0.
    GetLinearDamping :: (this: *MotionProperties) -> float #cpp_method #foreign jolt_release "?GetLinearDamping@MotionProperties@JPH@@QEBAMXZ";
    SetLinearDamping :: (this: *MotionProperties, inLinearDamping: float) -> void #cpp_method #foreign jolt_release "?SetLinearDamping@MotionProperties@JPH@@QEAAXM@Z";

    /// Get angular damping: dw/dt = -c * w. c. Value should be zero or positive and is usually close to 0.
    GetAngularDamping :: (this: *MotionProperties) -> float #cpp_method #foreign jolt_release "?GetAngularDamping@MotionProperties@JPH@@QEBAMXZ";
    SetAngularDamping :: (this: *MotionProperties, inAngularDamping: float) -> void #cpp_method #foreign jolt_release "?SetAngularDamping@MotionProperties@JPH@@QEAAXM@Z";

    /// Get gravity factor (1 = normal gravity, 0 = no gravity)
    GetGravityFactor :: (this: *MotionProperties) -> float #cpp_method #foreign jolt_release "?GetGravityFactor@MotionProperties@JPH@@QEBAMXZ";
    SetGravityFactor :: (this: *MotionProperties, inGravityFactor: float) -> void #cpp_method #foreign jolt_release "?SetGravityFactor@MotionProperties@JPH@@QEAAXM@Z";

    /// Set the mass and inertia tensor
    SetMassProperties :: (this: *MotionProperties, inAllowedDOFs: EAllowedDOFs, inMassProperties: *MassProperties) -> void #cpp_method #foreign jolt_release "?SetMassProperties@MotionProperties@JPH@@QEAAXW4EAllowedDOFs@2@AEBVMassProperties@2@@Z";
    SetMassProperties :: (this: *MotionProperties, inAllowedDOFs: EAllowedDOFs, inMassProperties: MassProperties) #no_context {
        SetMassProperties(this, inAllowedDOFs, *inMassProperties);
    }

    /// Get inverse mass (1 / mass). Should only be called on a dynamic object (static or kinematic bodies have infinite mass so should be treated as 1 / mass = 0)
    GetInverseMass :: (this: *MotionProperties) -> float #cpp_method #foreign jolt_release "?GetInverseMass@MotionProperties@JPH@@QEBAMXZ";
    GetInverseMassUnchecked :: (this: *MotionProperties) -> float #cpp_method #foreign jolt_release "?GetInverseMassUnchecked@MotionProperties@JPH@@QEBAMXZ";

    /// Set the inverse mass (1 / mass).
    /// Note that mass and inertia are linearly related (e.g. inertia of a sphere with mass m and radius r is \f$2/5 \: m \: r^2\f$).
    /// If you change mass, inertia should probably change as well. You can use ScaleToMass to update mass and inertia at the same time.
    /// If all your translation degrees of freedom are restricted, make sure this is zero (see EAllowedDOFs).
    SetInverseMass :: (this: *MotionProperties, inInverseMass: float) -> void #cpp_method #foreign jolt_release "?SetInverseMass@MotionProperties@JPH@@QEAAXM@Z";

    /// Diagonal of inverse inertia matrix: D. Should only be called on a dynamic object (static or kinematic bodies have infinite mass so should be treated as D = 0)
    GetInverseInertiaDiagonal :: (this: *MotionProperties) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetInverseInertiaDiagonal@MotionProperties@JPH@@QEBA?AVVec3@2@XZ";

    /// Rotation (R) that takes inverse inertia diagonal to local space: \f$I_{body}^{-1} = R \: D \: R^{-1}\f$
    GetInertiaRotation :: (this: *MotionProperties) -> Quat #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetInertiaRotation@MotionProperties@JPH@@QEBA?AVQuat@2@XZ";

    /// Set the inverse inertia tensor in local space by setting the diagonal and the rotation: \f$I_{body}^{-1} = R \: D \: R^{-1}\f$.
    /// Note that mass and inertia are linearly related (e.g. inertia of a sphere with mass m and radius r is \f$2/5 \: m \: r^2\f$).
    /// If you change inertia, mass should probably change as well. You can use ScaleToMass to update mass and inertia at the same time.
    /// If all your rotation degrees of freedom are restricted, make sure this is zero (see EAllowedDOFs).
    SetInverseInertia :: (this: *MotionProperties, inDiagonal: Vec3, inRot: Quaternion) -> void #cpp_method #foreign jolt_release "?SetInverseInertia@MotionProperties@JPH@@QEAAXVVec3@2@VQuat@2@@Z";

    /// Get inverse inertia matrix (\f$I_{body}^{-1}\f$). Will be a matrix of zeros for a static or kinematic object.
    GetLocalSpaceInverseInertia :: (this: *MotionProperties) -> Mat44 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetLocalSpaceInverseInertia@MotionProperties@JPH@@QEBA?AVMat44@2@XZ";

    /// Same as GetLocalSpaceInverseInertia() but doesn't check if the body is dynamic
    GetLocalSpaceInverseInertiaUnchecked :: (this: *MotionProperties) -> Mat44 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetLocalSpaceInverseInertiaUnchecked@MotionProperties@JPH@@QEBA?AVMat44@2@XZ";

    /// Get inverse inertia matrix (\f$I^{-1}\f$) for a given object rotation (translation will be ignored). Zero if object is static or kinematic.
    GetInverseInertiaForRotation :: (this: *MotionProperties, inRotation: *Mat44) -> Mat44 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetInverseInertiaForRotation@MotionProperties@JPH@@QEBA?AVMat44@2@AEBV32@@Z";

    /// Multiply a vector with the inverse world space inertia tensor (\f$I_{world}^{-1}\f$). Zero if object is static or kinematic.
    MultiplyWorldSpaceInverseInertiaByVector :: (this: *MotionProperties, inBodyRotation: Quaternion, inV: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?MultiplyWorldSpaceInverseInertiaByVector@MotionProperties@JPH@@QEBA?AVVec3@2@VQuat@2@V32@@Z";

    /// Velocity of point inPoint (in center of mass space, e.g. on the surface of the body) of the body (unit: m/s)
    GetPointVelocityCOM :: (this: *MotionProperties, inPointRelativeToCOM: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetPointVelocityCOM@MotionProperties@JPH@@QEBA?AVVec3@2@V32@@Z";

    // Get the total amount of force applied to the center of mass this time step (through Body::AddForce calls). Note that it will reset to zero after PhysicsSystem::Update.
    GetAccumulatedForce :: (this: *MotionProperties) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetAccumulatedForce@MotionProperties@JPH@@QEBA?AVVec3@2@XZ";

    // Get the total amount of torque applied to the center of mass this time step (through Body::AddForce/Body::AddTorque calls). Note that it will reset to zero after PhysicsSystem::Update.
    GetAccumulatedTorque :: (this: *MotionProperties) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetAccumulatedTorque@MotionProperties@JPH@@QEBA?AVVec3@2@XZ";

    // Reset the total accumulated force, note that this will be done automatically after every time step.
    ResetForce :: (this: *MotionProperties) -> void #cpp_method #foreign jolt_release "?ResetForce@MotionProperties@JPH@@QEAAXXZ";

    // Reset the total accumulated torque, note that this will be done automatically after every time step.
    ResetTorque :: (this: *MotionProperties) -> void #cpp_method #foreign jolt_release "?ResetTorque@MotionProperties@JPH@@QEAAXXZ";

    /// Returns a vector where the linear components that are not allowed by mAllowedDOFs are set to 0 and the rest to 0xffffffff
    GetLinearDOFsMask :: (this: *MotionProperties) -> UVec4 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetLinearDOFsMask@MotionProperties@JPH@@QEBA?AVUVec4@2@XZ";

    /// Takes a translation vector inV and returns a vector where the components that are not allowed by mAllowedDOFs are set to 0
    LockTranslation :: (this: *MotionProperties, inV: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?LockTranslation@MotionProperties@JPH@@QEBA?AVVec3@2@V32@@Z";

    /// Returns a vector where the angular components that are not allowed by mAllowedDOFs are set to 0 and the rest to 0xffffffff
    GetAngularDOFsMask :: (this: *MotionProperties) -> UVec4 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetAngularDOFsMask@MotionProperties@JPH@@QEBA?AVUVec4@2@XZ";

    /// Takes an angular velocity / torque vector inV and returns a vector where the components that are not allowed by mAllowedDOFs are set to 0
    LockAngular :: (this: *MotionProperties, inV: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?LockAngular@MotionProperties@JPH@@QEBA?AVVec3@2@V32@@Z";

    /// Used only when this body is dynamic and colliding. Override for the number of solver velocity iterations to run, 0 means use the default in PhysicsSettings::mNumVelocitySteps. The number of iterations to use is the max of all contacts and constraints in the island.
    SetNumVelocityStepsOverride :: (this: *MotionProperties, inN: u32) -> void #cpp_method #foreign jolt_release "?SetNumVelocityStepsOverride@MotionProperties@JPH@@QEAAXI@Z";
    GetNumVelocityStepsOverride :: (this: *MotionProperties) -> u32 #cpp_method #foreign jolt_release "?GetNumVelocityStepsOverride@MotionProperties@JPH@@QEBAIXZ";

    /// Used only when this body is dynamic and colliding. Override for the number of solver position iterations to run, 0 means use the default in PhysicsSettings::mNumPositionSteps. The number of iterations to use is the max of all contacts and constraints in the island.
    SetNumPositionStepsOverride :: (this: *MotionProperties, inN: u32) -> void #cpp_method #foreign jolt_release "?SetNumPositionStepsOverride@MotionProperties@JPH@@QEAAXI@Z";
    GetNumPositionStepsOverride :: (this: *MotionProperties) -> u32 #cpp_method #foreign jolt_release "?GetNumPositionStepsOverride@MotionProperties@JPH@@QEBAIXZ";

    ///@name Update linear and angular velocity (used during constraint solving)
    ///@{
    AddLinearVelocityStep :: (this: *MotionProperties, inLinearVelocityChange: Vec3) -> void #cpp_method #foreign jolt_release "?AddLinearVelocityStep@MotionProperties@JPH@@QEAAXVVec3@2@@Z";
    SubLinearVelocityStep :: (this: *MotionProperties, inLinearVelocityChange: Vec3) -> void #cpp_method #foreign jolt_release "?SubLinearVelocityStep@MotionProperties@JPH@@QEAAXVVec3@2@@Z";
    AddAngularVelocityStep :: (this: *MotionProperties, inAngularVelocityChange: Vec3) -> void #cpp_method #foreign jolt_release "?AddAngularVelocityStep@MotionProperties@JPH@@QEAAXVVec3@2@@Z";
    SubAngularVelocityStep :: (this: *MotionProperties, inAngularVelocityChange: Vec3) -> void #cpp_method #foreign jolt_release "?SubAngularVelocityStep@MotionProperties@JPH@@QEAAXVVec3@2@@Z";

    /// Apply the gyroscopic force (aka Dzhanibekov effect, see https://en.wikipedia.org/wiki/Tennis_racket_theorem)
    ApplyGyroscopicForceInternal :: (this: *MotionProperties, inBodyRotation: Quaternion, inDeltaTime: float) -> void #cpp_method #foreign jolt_release "?ApplyGyroscopicForceInternal@MotionProperties@JPH@@QEAAXVQuat@2@M@Z";

    /// Apply all accumulated forces, torques and drag (should only be called by the PhysicsSystem)
    ApplyForceTorqueAndDragInternal :: (this: *MotionProperties, inBodyRotation: Quaternion, inGravity: Vec3, inDeltaTime: float) -> void #cpp_method #foreign jolt_release "?ApplyForceTorqueAndDragInternal@MotionProperties@JPH@@QEAAXVQuat@2@VVec3@2@M@Z";

    /// Access to the island index
    GetIslandIndexInternal :: (this: *MotionProperties) -> u32 #cpp_method #foreign jolt_release "?GetIslandIndexInternal@MotionProperties@JPH@@QEBAIXZ";
    SetIslandIndexInternal :: (this: *MotionProperties, inIndex: u32) -> void #cpp_method #foreign jolt_release "?SetIslandIndexInternal@MotionProperties@JPH@@QEAAXI@Z";

    /// Access to the index in the active bodies array
    GetIndexInActiveBodiesInternal :: (this: *MotionProperties) -> u32 #cpp_method #foreign jolt_release "?GetIndexInActiveBodiesInternal@MotionProperties@JPH@@QEBAIXZ";

    /// Reset spheres to center around inPoints with radius 0
    ResetSleepTestSpheres :: (this: *MotionProperties, inPoints: *Vec3) -> void #cpp_method #foreign jolt_release "?ResetSleepTestSpheres@MotionProperties@JPH@@QEAAXPEBVVec3@2@@Z";

    /// Reset the sleep test timer without resetting the sleep test spheres
    ResetSleepTestTimer :: (this: *MotionProperties) -> void #cpp_method #foreign jolt_release "?ResetSleepTestTimer@MotionProperties@JPH@@QEAAXXZ";

    /// Accumulate sleep time and return if a body can go to sleep
    AccumulateSleepTime :: (this: *MotionProperties, inDeltaTime: float, inTimeBeforeSleep: float) -> ECanSleep #cpp_method #foreign jolt_release "?AccumulateSleepTime@MotionProperties@JPH@@QEAA?AW4ECanSleep@2@MM@Z";

    /// Saving state for replay
    SaveState :: (this: *MotionProperties, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?SaveState@MotionProperties@JPH@@QEBAXAEAVStateRecorder@2@@Z";

    /// Restoring state for replay
    RestoreState :: (this: *MotionProperties, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?RestoreState@MotionProperties@JPH@@QEAAXAEAVStateRecorder@2@@Z";

    cInactiveIndex:            u32 : 0xffff_ffff; ///< Constant indicating that body is not active

    mLinearVelocity:           Vec3; ///< World space linear velocity of the center of mass (m/s)
    mAngularVelocity:          Vec3; ///< World space angular velocity (rad/s)
    mInvInertiaDiagonal:       Vec3; ///< Diagonal of inverse inertia matrix: D
    mInertiaRotation:          Quat; ///< Rotation (R) that takes inverse inertia diagonal to local space: Ibody^-1 = R * D * R^-1

    mForce:                    Float3 = 0; ///< Accumulated world space force (N). Note loaded through intrinsics so ensure that the 4 bytes after this are readable!
    mTorque:                   Float3 = 0; ///< Accumulated world space torque (N m). Note loaded through intrinsics so ensure that the 4 bytes after this are readable!
    mInvMass:                  float; ///< Inverse mass of the object (1/kg)
    mLinearDamping:            float; ///< Linear damping: dv/dt = -c * v. Value should be zero or positive and is usually close to 0.
    mAngularDamping:           float; ///< Angular damping: dw/dt = -c * w. Value should be zero or positive and is usually close to 0.
    mMaxLinearVelocity:        float; ///< Maximum linear velocity that this body can reach (m/s)
    mMaxAngularVelocity:       float; ///< Maximum angular velocity that this body can reach (rad/s)
    mGravityFactor:            float; ///< Factor to multiply gravity with
    mIndexInActiveBodies:      u32 = cInactiveIndex; ///< If the body is active, this is the index in the active body list or cInactiveIndex if it is not active (note that there are 2 lists, one for rigid and one for soft bodies)
    mIslandIndex:              u32 = cInactiveIndex; ///< Index of the island that this body is part of, when the body has not yet been updated or is not active this is cInactiveIndex

    mMotionQuality:            EMotionQuality; ///< Motion quality, or how well it detects collisions when it has a high velocity
    mAllowSleeping:            bool; ///< If this body can go to sleep
    mAllowedDOFs:              EAllowedDOFs = .All; ///< Allowed degrees of freedom for this body
    mNumVelocityStepsOverride: u8 = 0; ///< Used only when this body is dynamic and colliding. Override for the number of solver velocity iterations to run, 0 means use the default in PhysicsSettings::mNumVelocitySteps. The number of iterations to use is the max of all contacts and constraints in the island.
    mNumPositionStepsOverride: u8 = 0; ///< Used only when this body is dynamic and colliding. Override for the number of solver position iterations to run, 0 means use the default in PhysicsSettings::mNumPositionSteps. The number of iterations to use is the max of all contacts and constraints in the island.

    mSleepTestSpheres:         [3] Sphere; ///< Measure motion for 3 points on the body to see if it is resting: COM, COM + largest bounding box axis, COM + second largest bounding box axis
    mSleepTestTimer:           float; ///< How long this body has been within the movement tolerance

    mCachedBodyType:           EBodyType; ///< Copied from Body::mBodyType and cached for asserting purposes
    mCachedMotionType:         EMotionType; ///< Copied from Body::mMotionType and cached for asserting purposes
}

/// Create a formatted text string for debugging purposes.
/// Note that this function has an internal buffer of 1024 characters, so long strings will be trimmed.
StringFormat_CFormat :: (inFMT: *u8, __args: ..Any) -> String #foreign jolt_release "?StringFormat@JPH@@YA?AV?$basic_string@DU?$char_traits@D@std@@V?$STLAllocator@D@JPH@@@std@@PEBDZZ";
StringFormat :: (inFMT: string, __args: ..Any) -> String {
    push_allocator(temp);
    formatted_text_builder: String_Builder;
    print_to_builder(*formatted_text_builder, inFMT, ..__args);
    append(*formatted_text_builder, "\0");
    formatted_text := builder_to_string(*formatted_text_builder);
    return StringFormat_CFormat("%s", formatted_text.data);
} @PrintLike

/// Converts the lower 4 bits of inNibble to a string that represents the number in binary format
NibbleToBinary :: (inNibble: u32) -> *u8 #foreign jolt_release "?NibbleToBinary@JPH@@YAPEBDI@Z";

Body :: struct {
    using noncopyable__raw: NonCopyable__RAW;

    /// Get the id of this body
    GetID :: (this: *Body) -> *BodyID #cpp_method #foreign jolt_release "?GetID@Body@JPH@@QEBAAEBVBodyID@2@XZ";

    /// Get the type of body (rigid or soft)
    GetBodyType :: (this: *Body) -> EBodyType #cpp_method #foreign jolt_release "?GetBodyType@Body@JPH@@QEBA?AW4EBodyType@2@XZ";

    /// Check if this body is a rigid body
    IsRigidBody :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?IsRigidBody@Body@JPH@@QEBA_NXZ";

    /// Check if this body is a soft body
    IsSoftBody :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?IsSoftBody@Body@JPH@@QEBA_NXZ";

    /// If this body is currently actively simulating (true) or sleeping (false)
    IsActive :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?IsActive@Body@JPH@@QEBA_NXZ";

    /// Check if this body is static (not movable)
    IsStatic :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?IsStatic@Body@JPH@@QEBA_NXZ";

    /// Check if this body is kinematic (keyframed), which means that it will move according to its current velocity, but forces don't affect it
    IsKinematic :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?IsKinematic@Body@JPH@@QEBA_NXZ";

    /// Check if this body is dynamic, which means that it moves and forces can act on it
    IsDynamic :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?IsDynamic@Body@JPH@@QEBA_NXZ";

    /// Check if a body could be made kinematic or dynamic (if it was created dynamic or with mAllowDynamicOrKinematic set to true)
    CanBeKinematicOrDynamic :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?CanBeKinematicOrDynamic@Body@JPH@@QEBA_NXZ";

    /// Change the body to a sensor. A sensor will receive collision callbacks, but will not cause any collision responses and can be used as a trigger volume.
    /// The cheapest sensor (in terms of CPU usage) is a sensor with motion type Static (they can be moved around using BodyInterface::SetPosition/SetPositionAndRotation).
    /// These sensors will only detect collisions with active Dynamic or Kinematic bodies. As soon as a body go to sleep, the contact point with the sensor will be lost.
    /// If you make a sensor Dynamic or Kinematic and activate them, the sensor will be able to detect collisions with sleeping bodies too. An active sensor will never go to sleep automatically.
    /// When you make a Dynamic or Kinematic sensor, make sure it is in an ObjectLayer that does not collide with Static bodies or other sensors to avoid extra overhead in the broad phase.
    SetIsSensor :: (this: *Body, inIsSensor: bool) -> void #cpp_method #foreign jolt_release "?SetIsSensor@Body@JPH@@QEAAX_N@Z";

    /// Check if this body is a sensor.
    IsSensor :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?IsSensor@Body@JPH@@QEBA_NXZ";

    /// If kinematic objects can generate contact points against other kinematic or static objects.
    /// Note that turning this on can be CPU intensive as much more collision detection work will be done without any effect on the simulation (kinematic objects are not affected by other kinematic/static objects).
    /// This can be used to make sensors detect static objects. Note that the sensor must be kinematic and active for it to detect static objects.
    SetCollideKinematicVsNonDynamic :: (this: *Body, inCollide: bool) -> void #cpp_method #foreign jolt_release "?SetCollideKinematicVsNonDynamic@Body@JPH@@QEAAX_N@Z";

    /// Check if kinematic objects can generate contact points against other kinematic or static objects.
    GetCollideKinematicVsNonDynamic :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?GetCollideKinematicVsNonDynamic@Body@JPH@@QEBA_NXZ";

    /// If PhysicsSettings::mUseManifoldReduction is true, this allows turning off manifold reduction for this specific body.
    /// Manifold reduction by default will combine contacts with similar normals that come from different SubShapeIDs (e.g. different triangles in a mesh shape or different compound shapes).
    /// If the application requires tracking exactly which SubShapeIDs are in contact, you can turn off manifold reduction. Note that this comes at a performance cost.
    /// Consider using BodyInterface::SetUseManifoldReduction if the body could already be in contact with other bodies to ensure that the contact cache is invalidated and you get the correct contact callbacks.
    SetUseManifoldReduction :: (this: *Body, inUseReduction: bool) -> void #cpp_method #foreign jolt_release "?SetUseManifoldReduction@Body@JPH@@QEAAX_N@Z";

    /// Check if this body can use manifold reduction.
    GetUseManifoldReduction :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?GetUseManifoldReduction@Body@JPH@@QEBA_NXZ";

    /// Checks if the combination of this body and inBody2 should use manifold reduction
    GetUseManifoldReductionWithBody :: (this: *Body, inBody2: *Body) -> bool #cpp_method #foreign jolt_release "?GetUseManifoldReductionWithBody@Body@JPH@@QEBA_NAEBV12@@Z";
    GetUseManifoldReductionWithBody :: (this: *Body, inBody2: Body) -> bool #no_context {
        return GetUseManifoldReductionWithBody(this, *inBody2);
    }

    /// Set to indicate that the gyroscopic force should be applied to this body (aka Dzhanibekov effect, see https://en.wikipedia.org/wiki/Tennis_racket_theorem)
    SetApplyGyroscopicForce :: (this: *Body, inApply: bool) -> void #cpp_method #foreign jolt_release "?SetApplyGyroscopicForce@Body@JPH@@QEAAX_N@Z";

    /// Check if the gyroscopic force is being applied for this body
    GetApplyGyroscopicForce :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?GetApplyGyroscopicForce@Body@JPH@@QEBA_NXZ";

    /// Set to indicate that extra effort should be made to try to remove ghost contacts (collisions with internal edges of a mesh). This is more expensive but makes bodies move smoother over a mesh with convex edges.
    SetEnhancedInternalEdgeRemoval :: (this: *Body, inApply: bool) -> void #cpp_method #foreign jolt_release "?SetEnhancedInternalEdgeRemoval@Body@JPH@@QEAAX_N@Z";

    /// Check if enhanced internal edge removal is turned on
    GetEnhancedInternalEdgeRemoval :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?GetEnhancedInternalEdgeRemoval@Body@JPH@@QEBA_NXZ";

    /// Checks if the combination of this body and inBody2 should use enhanced internal edge removal
    GetEnhancedInternalEdgeRemovalWithBody :: (this: *Body, inBody2: *Body) -> bool #cpp_method #foreign jolt_release "?GetEnhancedInternalEdgeRemovalWithBody@Body@JPH@@QEBA_NAEBV12@@Z";
    GetEnhancedInternalEdgeRemovalWithBody :: (this: *Body, inBody2: Body) -> bool #no_context {
        return GetEnhancedInternalEdgeRemovalWithBody(this, *inBody2);
    }

    /// Get the bodies motion type.
    GetMotionType :: (this: *Body) -> EMotionType #cpp_method #foreign jolt_release "?GetMotionType@Body@JPH@@QEBA?AW4EMotionType@2@XZ";

    /// Set the motion type of this body. Consider using BodyInterface::SetMotionType instead of this function if the body may be active or if it needs to be activated.
    SetMotionType :: (this: *Body, inMotionType: EMotionType) -> void #cpp_method #foreign jolt_release "?SetMotionType@Body@JPH@@QEAAXW4EMotionType@2@@Z";

    /// Get broadphase layer, this determines in which broad phase sub-tree the object is placed
    GetBroadPhaseLayer :: (this: *Body) -> BroadPhaseLayer #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetBroadPhaseLayer@Body@JPH@@QEBA?AVBroadPhaseLayer@2@XZ";

    /// Get object layer, this determines which other objects it collides with
    GetObjectLayer :: (this: *Body) -> ObjectLayer #cpp_method #foreign jolt_release "?GetObjectLayer@Body@JPH@@QEBAGXZ";

    /// Collision group and sub-group ID, determines which other objects it collides with
    GetCollisionGroup :: (this: /*const*/ *Body) -> *CollisionGroup #cpp_method #foreign jolt_release "?GetCollisionGroup@Body@JPH@@QEBAAEBVCollisionGroup@2@XZ";
    GetCollisionGroup_1 :: (this: *Body) -> *CollisionGroup #cpp_method #foreign jolt_release "?GetCollisionGroup@Body@JPH@@QEAAAEAVCollisionGroup@2@XZ";
    SetCollisionGroup :: (this: *Body, inGroup: *CollisionGroup) -> void #cpp_method #foreign jolt_release "?SetCollisionGroup@Body@JPH@@QEAAXAEBVCollisionGroup@2@@Z";
    SetCollisionGroup :: (this: *Body, inGroup: CollisionGroup) #no_context {
        SetCollisionGroup(this, *inGroup);
    }

    /// If this body can go to sleep. Note that disabling sleeping on a sleeping object will not wake it up.
    GetAllowSleeping :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?GetAllowSleeping@Body@JPH@@QEBA_NXZ";
    SetAllowSleeping :: (this: *Body, inAllow: bool) -> void #cpp_method #foreign jolt_release "?SetAllowSleeping@Body@JPH@@QEAAX_N@Z";

    /// Resets the sleep timer. This does not wake up the body if it is sleeping, but allows resetting the system that detects when a body is sleeping.
    ResetSleepTimer :: (this: *Body) -> void #cpp_method #foreign jolt_release "?ResetSleepTimer@Body@JPH@@QEAAXXZ";

    /// Friction (dimensionless number, usually between 0 and 1, 0 = no friction, 1 = friction force equals force that presses the two bodies together). Note that bodies can have negative friction but the combined friction (see PhysicsSystem::SetCombineFriction) should never go below zero.
    GetFriction :: (this: *Body) -> float #cpp_method #foreign jolt_release "?GetFriction@Body@JPH@@QEBAMXZ";
    SetFriction :: (this: *Body, inFriction: float) -> void #cpp_method #foreign jolt_release "?SetFriction@Body@JPH@@QEAAXM@Z";

    /// Restitution (dimensionless number, usually between 0 and 1, 0 = completely inelastic collision response, 1 = completely elastic collision response). Note that bodies can have negative restitution but the combined restitution (see PhysicsSystem::SetCombineRestitution) should never go below zero.
    GetRestitution :: (this: *Body) -> float #cpp_method #foreign jolt_release "?GetRestitution@Body@JPH@@QEBAMXZ";
    SetRestitution :: (this: *Body, inRestitution: float) -> void #cpp_method #foreign jolt_release "?SetRestitution@Body@JPH@@QEAAXM@Z";

    /// Get world space linear velocity of the center of mass (unit: m/s)
    GetLinearVelocity :: (this: *Body) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetLinearVelocity@Body@JPH@@QEBA?AVVec3@2@XZ";

    /// Set world space linear velocity of the center of mass, will make sure the value is clamped against the maximum linear velocity.
    /// If you want the body to wake up when it is sleeping, use BodyInterface::SetLinearVelocity instead.
    SetLinearVelocityClamped :: (this: *Body, inLinearVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?SetLinearVelocityClamped@Body@JPH@@QEAAXVVec3@2@@Z";

    /// Get world space angular velocity of the center of mass (unit: rad/s)
    GetAngularVelocity :: (this: *Body) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetAngularVelocity@Body@JPH@@QEBA?AVVec3@2@XZ";

    /// Set world space angular velocity of the center of mass, will make sure the value is clamped against the maximum angular velocity.
    /// If you want the body to wake up when it is sleeping, use BodyInterface::SetAngularVelocity instead.
    SetAngularVelocityClamped :: (this: *Body, inAngularVelocity: Vec3) -> void #cpp_method #foreign jolt_release "?SetAngularVelocityClamped@Body@JPH@@QEAAXVVec3@2@@Z";

    /// Velocity of point inPoint (in center of mass space, e.g. on the surface of the body) of the body (unit: m/s)
    GetPointVelocityCOM :: (this: *Body, inPointRelativeToCOM: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetPointVelocityCOM@Body@JPH@@QEBA?AVVec3@2@V32@@Z";

    /// Velocity of point inPoint (in world space, e.g. on the surface of the body) of the body (unit: m/s)
    GetPointVelocity :: (this: *Body, inPoint: Vector3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetPointVelocity@Body@JPH@@QEBA?AVVec3@2@V32@@Z";

    /// Add force (unit: N) at center of mass for the next time step, will be reset after the next call to PhysicsSystem::Update.
    /// If you want the body to wake up when it is sleeping, use BodyInterface::AddForce instead.
    AddForce :: (this: *Body, inForce: Vec3) -> void #cpp_method #foreign jolt_release "?AddForce@Body@JPH@@QEAAXVVec3@2@@Z";

    /// Add force (unit: N) at world space position inPosition for the next time step, will be reset after the next call to PhysicsSystem::Update.
    /// If you want the body to wake up when it is sleeping, use BodyInterface::AddForce instead.
    AddForce :: (this: *Body, inForce: Vec3, inPosition: Vector3) -> void #cpp_method #foreign jolt_release "?AddForce@Body@JPH@@QEAAXVVec3@2@0@Z";

    /// Add torque (unit: N m) for the next time step, will be reset after the next call to PhysicsSystem::Update.
    /// If you want the body to wake up when it is sleeping, use BodyInterface::AddTorque instead.
    AddTorque :: (this: *Body, inTorque: Vec3) -> void #cpp_method #foreign jolt_release "?AddTorque@Body@JPH@@QEAAXVVec3@2@@Z";

    /// Get inverse inertia tensor in world space
    GetInverseInertia :: (this: *Body) -> Mat44 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetInverseInertia@Body@JPH@@QEBA?AVMat44@2@XZ";

    /// Add impulse to center of mass (unit: kg m/s).
    /// If you want the body to wake up when it is sleeping, use BodyInterface::AddImpulse instead.
    AddImpulse :: (this: *Body, inImpulse: Vec3) -> void #cpp_method #foreign jolt_release "?AddImpulse@Body@JPH@@QEAAXVVec3@2@@Z";

    /// Add impulse to point in world space (unit: kg m/s).
    /// If you want the body to wake up when it is sleeping, use BodyInterface::AddImpulse instead.
    AddImpulse :: (this: *Body, inImpulse: Vec3, inPosition: Vector3) -> void #cpp_method #foreign jolt_release "?AddImpulse@Body@JPH@@QEAAXVVec3@2@0@Z";

    /// Add angular impulse in world space (unit: N m s).
    /// If you want the body to wake up when it is sleeping, use BodyInterface::AddAngularImpulse instead.
    AddAngularImpulse :: (this: *Body, inAngularImpulse: Vec3) -> void #cpp_method #foreign jolt_release "?AddAngularImpulse@Body@JPH@@QEAAXVVec3@2@@Z";

    /// Set velocity of body such that it will be positioned at inTargetPosition/Rotation in inDeltaTime seconds.
    /// If you want the body to wake up when it is sleeping, use BodyInterface::MoveKinematic instead.
    MoveKinematic :: (this: *Body, inTargetPosition: Vector3, inTargetRotation: Quaternion, inDeltaTime: float) -> void #cpp_method #foreign jolt_release "?MoveKinematic@Body@JPH@@QEAAXVVec3@2@VQuat@2@M@Z";

    /// Gets the properties needed to do buoyancy calculations
    /// @param inSurfacePosition Position of the fluid surface in world space
    /// @param inSurfaceNormal Normal of the fluid surface (should point up)
    /// @param outTotalVolume On return this contains the total volume of the shape
    /// @param outSubmergedVolume On return this contains the submerged volume of the shape
    /// @param outRelativeCenterOfBuoyancy On return this contains the center of mass of the submerged volume relative to the center of mass of the body
    GetSubmergedVolume :: (this: *Body, inSurfacePosition: Vector3, inSurfaceNormal: Vec3, outTotalVolume: *float, outSubmergedVolume: *float, outRelativeCenterOfBuoyancy: *Vec3) -> void #cpp_method #foreign jolt_release "?GetSubmergedVolume@Body@JPH@@QEBAXVVec3@2@0AEAM1AEAV32@@Z";

    /// Applies an impulse to the body that simulates fluid buoyancy and drag.
    /// If you want the body to wake up when it is sleeping, use BodyInterface::ApplyBuoyancyImpulse instead.
    /// @param inSurfacePosition Position of the fluid surface in world space
    /// @param inSurfaceNormal Normal of the fluid surface (should point up)
    /// @param inBuoyancy The buoyancy factor for the body. 1 = neutral body, < 1 sinks, > 1 floats. Note that we don't use the fluid density since it is harder to configure than a simple number between [0, 2]
    /// @param inLinearDrag Linear drag factor that slows down the body when in the fluid (approx. 0.5)
    /// @param inAngularDrag Angular drag factor that slows down rotation when the body is in the fluid (approx. 0.01)
    /// @param inFluidVelocity The average velocity of the fluid (in m/s) in which the body resides
    /// @param inGravity The gravity vector (pointing down)
    /// @param inDeltaTime Delta time of the next simulation step (in s)
    /// @return true if an impulse was applied, false if the body was not in the fluid
    ApplyBuoyancyImpulse :: (this: *Body, inSurfacePosition: Vector3, inSurfaceNormal: Vec3, inBuoyancy: float, inLinearDrag: float, inAngularDrag: float, inFluidVelocity: Vec3, inGravity: Vec3, inDeltaTime: float) -> bool #cpp_method #foreign jolt_release "?ApplyBuoyancyImpulse@Body@JPH@@QEAA_NVVec3@2@0MMM00M@Z";

    /// Applies an impulse to the body that simulates fluid buoyancy and drag.
    /// If you want the body to wake up when it is sleeping, use BodyInterface::ApplyBuoyancyImpulse instead.
    /// @param inTotalVolume Total volume of the shape of this body (m^3)
    /// @param inSubmergedVolume Submerged volume of the shape of this body (m^3)
    /// @param inRelativeCenterOfBuoyancy The center of mass of the submerged volume relative to the center of mass of the body
    /// @param inBuoyancy The buoyancy factor for the body. 1 = neutral body, < 1 sinks, > 1 floats. Note that we don't use the fluid density since it is harder to configure than a simple number between [0, 2]
    /// @param inLinearDrag Linear drag factor that slows down the body when in the fluid (approx. 0.5)
    /// @param inAngularDrag Angular drag factor that slows down rotation when the body is in the fluid (approx. 0.01)
    /// @param inFluidVelocity The average velocity of the fluid (in m/s) in which the body resides
    /// @param inGravity The gravity vector (pointing down)
    /// @param inDeltaTime Delta time of the next simulation step (in s)
    /// @return true if an impulse was applied, false if the body was not in the fluid
    ApplyBuoyancyImpulse :: (this: *Body, inTotalVolume: float, inSubmergedVolume: float, inRelativeCenterOfBuoyancy: Vec3, inBuoyancy: float, inLinearDrag: float, inAngularDrag: float, inFluidVelocity: Vec3, inGravity: Vec3, inDeltaTime: float) -> bool #cpp_method #foreign jolt_release "?ApplyBuoyancyImpulse@Body@JPH@@QEAA_NMMVVec3@2@MMM00M@Z";

    /// Check if this body has been added to the physics system
    IsInBroadPhase :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?IsInBroadPhase@Body@JPH@@QEBA_NXZ";

    /// Check if this body has been changed in such a way that the collision cache should be considered invalid for any body interacting with this body
    IsCollisionCacheInvalid :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?IsCollisionCacheInvalid@Body@JPH@@QEBA_NXZ";

    /// Get the shape of this body
    GetShape :: (this: *Body) -> *Shape #cpp_method #foreign jolt_release "?GetShape@Body@JPH@@QEBAPEBVShape@2@XZ";

    /// World space position of the body
    GetPosition :: (this: *Body) -> Vec3 #cpp_method #foreign jolt_release "?GetPosition@Body@JPH@@QEBA?AVVec3@2@XZ";

    /// World space rotation of the body
    GetRotation :: (this: *Body) -> Quat #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetRotation@Body@JPH@@QEBA?AVQuat@2@XZ";

    /// Calculates the transform of this body
    GetWorldTransform :: (this: *Body) -> Mat44 #cpp_method #foreign jolt_release "?GetWorldTransform@Body@JPH@@QEBA?AVMat44@2@XZ";

    /// Gets the world space position of this body's center of mass
    GetCenterOfMassPosition :: (this: *Body) -> Vec3 #cpp_method #foreign jolt_release "?GetCenterOfMassPosition@Body@JPH@@QEBA?AVVec3@2@XZ";

    /// Calculates the transform for this body's center of mass
    GetCenterOfMassTransform :: (this: *Body) -> Mat44 #cpp_method #foreign jolt_release "?GetCenterOfMassTransform@Body@JPH@@QEBA?AVMat44@2@XZ";

    /// Calculates the inverse of the transform for this body's center of mass
    GetInverseCenterOfMassTransform :: (this: *Body) -> Mat44 #cpp_method #foreign jolt_release "?GetInverseCenterOfMassTransform@Body@JPH@@QEBA?AVMat44@2@XZ";

    /// Get world space bounding box
    GetWorldSpaceBounds :: (this: *Body) -> *AABox #cpp_method #foreign jolt_release "?GetWorldSpaceBounds@Body@JPH@@QEBAAEBVAABox@2@XZ";

    /// Access to the motion properties
    GetMotionProperties :: (this: /*const*/ *Body) -> *MotionProperties #cpp_method #foreign jolt_release "?GetMotionProperties@Body@JPH@@QEBAPEBVMotionProperties@2@XZ";
    GetMotionProperties_1 :: (this: *Body) -> *MotionProperties #cpp_method #foreign jolt_release "?GetMotionProperties@Body@JPH@@QEAAPEAVMotionProperties@2@XZ";

    /// Access to the motion properties (version that does not check if the object is kinematic or dynamic)
    GetMotionPropertiesUnchecked :: (this: /*const*/ *Body) -> *MotionProperties #cpp_method #foreign jolt_release "?GetMotionPropertiesUnchecked@Body@JPH@@QEBAPEBVMotionProperties@2@XZ";
    GetMotionPropertiesUnchecked_1 :: (this: *Body) -> *MotionProperties #cpp_method #foreign jolt_release "?GetMotionPropertiesUnchecked@Body@JPH@@QEAAPEAVMotionProperties@2@XZ";

    /// Access to the user data, can be used for anything by the application
    GetUserData :: (this: *Body) -> u64 #cpp_method #foreign jolt_release "?GetUserData@Body@JPH@@QEBA_KXZ";
    SetUserData :: (this: *Body, inUserData: u64) -> void #cpp_method #foreign jolt_release "?SetUserData@Body@JPH@@QEAAX_K@Z";

    /// Get surface normal of a particular sub shape and its world space surface position on this body
    GetWorldSpaceSurfaceNormal :: (this: *Body, inSubShapeID: *SubShapeID, inPosition: Vector3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetWorldSpaceSurfaceNormal@Body@JPH@@QEBA?AVVec3@2@AEBVSubShapeID@2@V32@@Z";
    GetWorldSpaceSurfaceNormal :: (this: *Body, inSubShapeID: SubShapeID, inPosition: Vector3) -> Vec3 #no_context {
        return GetWorldSpaceSurfaceNormal(this, *inSubShapeID, inPosition);
    }

    /// Get the transformed shape of this body, which can be used to do collision detection outside of a body lock
    GetTransformedShape :: (this: *Body) -> TransformedShape #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetTransformedShape@Body@JPH@@QEBA?AVTransformedShape@2@XZ";

    /// Debug function to convert a body back to a body creation settings object to be able to save/recreate the body later
    GetBodyCreationSettings :: (this: *Body) -> BodyCreationSettings #cpp_method #foreign jolt_release "?GetBodyCreationSettings@Body@JPH@@QEBA?AVBodyCreationSettings@2@XZ";

    /// Debug function to convert a soft body back to a soft body creation settings object to be able to save/recreate the body later
    GetSoftBodyCreationSettings :: (this: *Body) -> SoftBodyCreationSettings #cpp_method #foreign jolt_release "?GetSoftBodyCreationSettings@Body@JPH@@QEBA?AVSoftBodyCreationSettings@2@XZ";

    /// Helper function for BroadPhase::FindCollidingPairs that returns true when two bodies can collide
    /// It assumes that body 1 is dynamic and active and guarantees that it body 1 collides with body 2 that body 2 will not collide with body 1 in order to avoid finding duplicate collision pairs
    sFindCollidingPairsCanCollide :: (inBody1: *Body, inBody2: *Body) -> bool #foreign jolt_release "?sFindCollidingPairsCanCollide@Body@JPH@@SA_NAEBV12@0@Z";
    sFindCollidingPairsCanCollide :: (inBody1: Body, inBody2: Body) -> bool #no_context {
        return sFindCollidingPairsCanCollide(*inBody1, *inBody2);
    }

    /// Update position using an Euler step (used during position integrate & constraint solving)
    AddPositionStep :: (this: *Body, inLinearVelocityTimesDeltaTime: Vec3) -> void #cpp_method #foreign jolt_release "?AddPositionStep@Body@JPH@@QEAAXVVec3@2@@Z";
    SubPositionStep :: (this: *Body, inLinearVelocityTimesDeltaTime: Vec3) -> void #cpp_method #foreign jolt_release "?SubPositionStep@Body@JPH@@QEAAXVVec3@2@@Z";

    /// Update rotation using an Euler step (used during position integrate & constraint solving)
    AddRotationStep :: (this: *Body, inAngularVelocityTimesDeltaTime: Vec3) -> void #cpp_method #foreign jolt_release "?AddRotationStep@Body@JPH@@QEAAXVVec3@2@@Z";

    SubRotationStep :: (this: *Body, inAngularVelocityTimesDeltaTime: Vec3) -> void #cpp_method #foreign jolt_release "?SubRotationStep@Body@JPH@@QEAAXVVec3@2@@Z";

    /// Flag if body is in the broadphase (should only be called by the BroadPhase)
    SetInBroadPhaseInternal :: (this: *Body, inInBroadPhase: bool) -> void #cpp_method #foreign jolt_release "?SetInBroadPhaseInternal@Body@JPH@@QEAAX_N@Z";

    /// Invalidate the contact cache (should only be called by the BodyManager), will be reset the next simulation step. Returns true if the contact cache was still valid.
    InvalidateContactCacheInternal :: (this: *Body) -> bool #cpp_method #foreign jolt_release "?InvalidateContactCacheInternal@Body@JPH@@QEAA_NXZ";

    /// Reset the collision cache invalid flag (should only be called by the BodyManager).
    ValidateContactCacheInternal :: (this: *Body) -> void #cpp_method #foreign jolt_release "?ValidateContactCacheInternal@Body@JPH@@QEAAXXZ";

    /// Updates world space bounding box (should only be called by the PhysicsSystem)
    CalculateWorldSpaceBoundsInternal :: (this: *Body) -> void #cpp_method #foreign jolt_release "?CalculateWorldSpaceBoundsInternal@Body@JPH@@QEAAXXZ";

    /// Function to update body's position (should only be called by the BodyInterface since it also requires updating the broadphase)
    SetPositionAndRotationInternal :: (this: *Body, inPosition: Vector3, inRotation: Quaternion, inResetSleepTimer := true) -> void #cpp_method #foreign jolt_release "?SetPositionAndRotationInternal@Body@JPH@@QEAAXVVec3@2@VQuat@2@_N@Z";

    /// Updates the center of mass and optionally mass properties after shifting the center of mass or changes to the shape (should only be called by the BodyInterface since it also requires updating the broadphase)
    /// @param inPreviousCenterOfMass Center of mass of the shape before the alterations
    /// @param inUpdateMassProperties When true, the mass and inertia tensor is recalculated
    UpdateCenterOfMassInternal :: (this: *Body, inPreviousCenterOfMass: Vec3, inUpdateMassProperties: bool) -> void #cpp_method #foreign jolt_release "?UpdateCenterOfMassInternal@Body@JPH@@QEAAXVVec3@2@_N@Z";

    /// Function to update a body's shape (should only be called by the BodyInterface since it also requires updating the broadphase)
    /// @param inShape The new shape for this body
    /// @param inUpdateMassProperties When true, the mass and inertia tensor is recalculated
    SetShapeInternal :: (this: *Body, inShape: *Shape, inUpdateMassProperties: bool) -> void #cpp_method #foreign jolt_release "?SetShapeInternal@Body@JPH@@QEAAXPEBVShape@2@_N@Z";

    /// Access to the index in the BodyManager::mActiveBodies list
    GetIndexInActiveBodiesInternal :: (this: *Body) -> u32 #cpp_method #foreign jolt_release "?GetIndexInActiveBodiesInternal@Body@JPH@@QEBAIXZ";

    /// Update eligibility for sleeping
    UpdateSleepStateInternal :: (this: *Body, inDeltaTime: float, inMaxMovement: float, inTimeBeforeSleep: float) -> ECanSleep #cpp_method #foreign jolt_release "?UpdateSleepStateInternal@Body@JPH@@QEAA?AW4ECanSleep@2@MMM@Z";

    /// Saving state for replay
    SaveState :: (this: *Body, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?SaveState@Body@JPH@@QEBAXAEAVStateRecorder@2@@Z";

    /// Restoring state for replay
    RestoreState :: (this: *Body, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?RestoreState@Body@JPH@@QEAAXAEAVStateRecorder@2@@Z";

    cInactiveIndex:         u32 : MotionProperties.cInactiveIndex; ///< Constant indicating that body is not active

    Constructor :: (this: *Body) -> void #cpp_method #foreign jolt_release "??0Body@JPH@@AEAA@XZ";

    Constructor :: (this: *Body, unknown0: bool) -> void #cpp_method #foreign jolt_release "??0Body@JPH@@AEAA@_N@Z";

    Destructor :: (this: *Body) -> void #cpp_method #foreign jolt_release "??1Body@JPH@@AEAA@XZ";

    GetSleepTestPoints :: (this: *Body, outPoints: *Vec3) -> void #cpp_method #foreign jolt_release "?GetSleepTestPoints@Body@JPH@@AEBAXPEAVVec3@2@@Z";

    EFlags :: enum u8 {
        IsSensor                     :: 1;
        CollideKinematicVsNonDynamic :: 2;
        IsInBroadPhase               :: 4;
        InvalidateContactCache       :: 8;
        UseManifoldReduction         :: 16;
        ApplyGyroscopicForce         :: 32;
        EnhancedInternalEdgeRemoval  :: 64;
    }

    mPosition:              Vec3; ///< World space position of center of mass
    mRotation:              Quat; ///< World space rotation of center of mass
    mBounds:                AABox; ///< World space bounding box of the body

    mShape:                 RefConst(Shape); ///< Shape representing the volume of this body
    mMotionProperties:      *MotionProperties = null; ///< If this is a keyframed or dynamic object, this object holds all information about the movement
    mUserData:              u64 = 0; ///< User data, can be used for anything by the application
    mCollisionGroup:        CollisionGroup; ///< The collision group this body belongs to (determines if two objects can collide)

    mFriction:              float; ///< Friction of the body (dimensionless number, usually between 0 and 1, 0 = no friction, 1 = friction force equals force that presses the two bodies together). Note that bodies can have negative friction but the combined friction (see PhysicsSystem::SetCombineFriction) should never go below zero.
    mRestitution:           float; ///< Restitution of body (dimensionless number, usually between 0 and 1, 0 = completely inelastic collision response, 1 = completely elastic collision response). Note that bodies can have negative restitution but the combined restitution (see PhysicsSystem::SetCombineRestitution) should never go below zero.
    mID:                    BodyID; ///< ID of the body (index in the bodies array)

    mObjectLayer:           ObjectLayer; ///< The collision layer this body belongs to (determines if two objects can collide)

    mBodyType:              EBodyType; ///< Type of body (rigid or soft)
    mBroadPhaseLayer:       BroadPhaseLayer; ///< The broad phase layer this body belongs to
    mMotionType:            EMotionType; ///< Type of motion (static, dynamic or kinematic)
    mFlags:                 std.atomic(u8) = 0; ///< See EFlags for possible flags
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// Functionality to get the processors cycle counter
GetProcessorTickCount :: () -> u64 #foreign jolt_release "?GetProcessorTickCount@JPH@@YA_KXZ";

// On other platforms just use the STL implementation
MutexBase :: std.mutex;
SharedMutexBase :: std.shared_mutex;

/// Very simple wrapper around MutexBase which tracks lock contention in the profiler
/// and asserts that locks/unlocks take place on the same thread
Mutex :: struct {
    #as using mutexbase: MutexBase;

    try_lock :: (this: *Mutex) -> bool #cpp_method #foreign jolt_release "?try_lock@Mutex@JPH@@QEAA_NXZ";

    lock :: (this: *Mutex) -> void #cpp_method #foreign jolt_release "?lock@Mutex@JPH@@QEAAXXZ";

    unlock :: (this: *Mutex) -> void #cpp_method #foreign jolt_release "?unlock@Mutex@JPH@@QEAAXXZ";

    mLockedThreadID:     std.id;
}

/// Very simple wrapper around SharedMutexBase which tracks lock contention in the profiler
/// and asserts that locks/unlocks take place on the same thread
SharedMutex :: struct {
    #as using sharedmutexbase: SharedMutexBase;

    try_lock :: (this: *SharedMutex) -> bool #cpp_method #foreign jolt_release "?try_lock@SharedMutex@JPH@@QEAA_NXZ";

    lock :: (this: *SharedMutex) -> void #cpp_method #foreign jolt_release "?lock@SharedMutex@JPH@@QEAAXXZ";

    unlock :: (this: *SharedMutex) -> void #cpp_method #foreign jolt_release "?unlock@SharedMutex@JPH@@QEAAXXZ";

    lock_shared :: (this: *SharedMutex) -> void #cpp_method #foreign jolt_release "?lock_shared@SharedMutex@JPH@@QEAAXXZ";

    mLockedThreadID:           std.id;
}

/// A mutex array protects a number of resources with a limited amount of mutexes.
/// It uses hashing to find the mutex of a particular object.
/// The idea is that if the amount of threads is much smaller than the amount of mutexes
/// that there is a relatively small chance that two different objects map to the same mutex.
MutexArray :: struct(MutexType: Type) {
    using noncopyable__raw: NonCopyable__RAW;

    /// Align the mutex to a cache line to ensure there is no false sharing (this is platform dependent, we do this to be safe)
    MutexStorage :: struct {
        mMutex: MutexType;
    }

    mMutexStorage:          *MutexStorage = null;
    mNumMutexes:            u32 = 0;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

BodyActivationListener :: struct {}

/// Array of bodies
BodyVector :: Array(*Body);

/// Array of body ID's
BodyIDVector :: Array(BodyID);

/// A token that indicates the context of a lock (we use 1 per physics system and we use the body manager pointer because it's convenient)
BodyManager :: struct {
    using noncopyable__raw:    NonCopyable__RAW;

    /// Destructor
    Destructor :: (this: *BodyManager) -> void #cpp_method #foreign jolt_release "??1BodyManager@JPH@@QEAA@XZ";

    /// Initialize the manager
    Init :: (this: *BodyManager, inMaxBodies: u32, inNumBodyMutexes: u32, inLayerInterface: *BroadPhaseLayerInterface) -> void #cpp_method #foreign jolt_release "?Init@BodyManager@JPH@@QEAAXIIAEBVBroadPhaseLayerInterface@2@@Z";
    Init :: (this: *BodyManager, inMaxBodies: u32, inNumBodyMutexes: u32, inLayerInterface: BroadPhaseLayerInterface) #no_context {
        Init(this, inMaxBodies, inNumBodyMutexes, *inLayerInterface);
    }

    /// Gets the current amount of bodies that are in the body manager
    GetNumBodies :: (this: *BodyManager) -> u32 #cpp_method #foreign jolt_release "?GetNumBodies@BodyManager@JPH@@QEBAIXZ";

    /// Gets the max bodies that we can support
    GetMaxBodies :: (this: *BodyManager) -> u32 #cpp_method #foreign jolt_release "?GetMaxBodies@BodyManager@JPH@@QEBAIXZ";

    /// Helper struct that counts the number of bodies of each type
    BodyStats :: struct {
        mNumBodies:                u32 = 0; ///< Total number of bodies in the body manager
        mMaxBodies:                u32 = 0; ///< Max allowed number of bodies in the body manager (as configured in Init(...))

        mNumBodiesStatic:          u32 = 0; ///< Number of static bodies

        mNumBodiesDynamic:         u32 = 0; ///< Number of dynamic bodies
        mNumActiveBodiesDynamic:   u32 = 0; ///< Number of dynamic bodies that are currently active

        mNumBodiesKinematic:       u32 = 0; ///< Number of kinematic bodies
        mNumActiveBodiesKinematic: u32 = 0; ///< Number of kinematic bodies that are currently active

        mNumSoftBodies:            u32 = 0; ///< Number of soft bodies
        mNumActiveSoftBodies:      u32 = 0; ///< Number of soft bodies that are currently active
    }

    /// Get stats about the bodies in the body manager (slow, iterates through all bodies)
    GetBodyStats :: (this: *BodyManager) -> BodyStats #cpp_method #foreign jolt_release "?GetBodyStats@BodyManager@JPH@@QEBA?AUBodyStats@12@XZ";

    /// Create a body using creation settings. The returned body will not be part of the body manager yet.
    AllocateBody :: (this: *BodyManager, inBodyCreationSettings: *BodyCreationSettings) -> *Body #cpp_method #foreign jolt_release "?AllocateBody@BodyManager@JPH@@QEBAPEAVBody@2@AEBVBodyCreationSettings@2@@Z";
    AllocateBody :: (this: *BodyManager, inBodyCreationSettings: BodyCreationSettings) -> *Body #no_context {
        return AllocateBody(this, *inBodyCreationSettings);
    }

    /// Create a soft body using creation settings. The returned body will not be part of the body manager yet.
    AllocateSoftBody :: (this: *BodyManager, inSoftBodyCreationSettings: *SoftBodyCreationSettings) -> *Body #cpp_method #foreign jolt_release "?AllocateSoftBody@BodyManager@JPH@@QEBAPEAVBody@2@AEBVSoftBodyCreationSettings@2@@Z";
    AllocateSoftBody :: (this: *BodyManager, inSoftBodyCreationSettings: SoftBodyCreationSettings) -> *Body #no_context {
        return AllocateSoftBody(this, *inSoftBodyCreationSettings);
    }

    /// Free a body that has not been added to the body manager yet (if it has, use DestroyBodies).
    FreeBody :: (this: *BodyManager, inBody: *Body) -> void #cpp_method #foreign jolt_release "?FreeBody@BodyManager@JPH@@QEBAXPEAVBody@2@@Z";

    /// Add a body to the body manager, assigning it the next available ID. Returns false if no more IDs are available.
    AddBody :: (this: *BodyManager, ioBody: *Body) -> bool #cpp_method #foreign jolt_release "?AddBody@BodyManager@JPH@@QEAA_NPEAVBody@2@@Z";

    /// Add a body to the body manager, assigning it a custom ID. Returns false if the ID is not valid.
    AddBodyWithCustomID :: (this: *BodyManager, ioBody: *Body, inBodyID: *BodyID) -> bool #cpp_method #foreign jolt_release "?AddBodyWithCustomID@BodyManager@JPH@@QEAA_NPEAVBody@2@AEBVBodyID@2@@Z";
    AddBodyWithCustomID :: (this: *BodyManager, ioBody: *Body, inBodyID: BodyID) -> bool #no_context {
        return AddBodyWithCustomID(this, ioBody, *inBodyID);
    }

    /// Remove a list of bodies from the body manager
    RemoveBodies :: (this: *BodyManager, inBodyIDs: *BodyID, inNumber: s32, outBodies: **Body) -> void #cpp_method #foreign jolt_release "?RemoveBodies@BodyManager@JPH@@QEAAXPEBVBodyID@2@HPEAPEAVBody@2@@Z";

    /// Remove a set of bodies from the body manager and frees them.
    DestroyBodies :: (this: *BodyManager, inBodyIDs: *BodyID, inNumber: s32) -> void #cpp_method #foreign jolt_release "?DestroyBodies@BodyManager@JPH@@QEAAXPEBVBodyID@2@H@Z";

    /// Activate a list of bodies.
    /// This function should only be called when an exclusive lock for the bodies are held.
    ActivateBodies :: (this: *BodyManager, inBodyIDs: *BodyID, inNumber: s32) -> void #cpp_method #foreign jolt_release "?ActivateBodies@BodyManager@JPH@@QEAAXPEBVBodyID@2@H@Z";

    /// Deactivate a list of bodies.
    /// This function should only be called when an exclusive lock for the bodies are held.
    DeactivateBodies :: (this: *BodyManager, inBodyIDs: *BodyID, inNumber: s32) -> void #cpp_method #foreign jolt_release "?DeactivateBodies@BodyManager@JPH@@QEAAXPEBVBodyID@2@H@Z";

    /// Update the motion quality for a body
    SetMotionQuality :: (this: *BodyManager, ioBody: *Body, inMotionQuality: EMotionQuality) -> void #cpp_method #foreign jolt_release "?SetMotionQuality@BodyManager@JPH@@QEAAXAEAVBody@2@W4EMotionQuality@2@@Z";

    /// Get copy of the list of active bodies under protection of a lock.
    GetActiveBodies :: (this: *BodyManager, inType: EBodyType, outBodyIDs: *BodyIDVector) -> void #cpp_method #foreign jolt_release "?GetActiveBodies@BodyManager@JPH@@QEBAXW4EBodyType@2@AEAV?$Array@VBodyID@JPH@@V?$STLAllocator@VBodyID@JPH@@@2@@2@@Z";

    /// Get the list of active bodies. Note: Not thread safe. The active bodies list can change at any moment.
    GetActiveBodiesUnsafe :: (this: *BodyManager, inType: EBodyType) -> *BodyID #cpp_method #foreign jolt_release "?GetActiveBodiesUnsafe@BodyManager@JPH@@QEBAPEBVBodyID@2@W4EBodyType@2@@Z";

    /// Get the number of active bodies.
    GetNumActiveBodies :: (this: *BodyManager, inType: EBodyType) -> u32 #cpp_method #foreign jolt_release "?GetNumActiveBodies@BodyManager@JPH@@QEBAIW4EBodyType@2@@Z";

    /// Get the number of active bodies that are using continuous collision detection
    GetNumActiveCCDBodies :: (this: *BodyManager) -> u32 #cpp_method #foreign jolt_release "?GetNumActiveCCDBodies@BodyManager@JPH@@QEBAIXZ";

    /// Listener that is notified whenever a body is activated/deactivated
    SetBodyActivationListener :: (this: *BodyManager, inListener: *BodyActivationListener) -> void #cpp_method #foreign jolt_release "?SetBodyActivationListener@BodyManager@JPH@@QEAAXPEAVBodyActivationListener@2@@Z";

    /// Check if this is a valid body pointer. When a body is freed the memory that the pointer occupies is reused to store a freelist.
    sIsValidBodyPointer :: (inBody: *Body) -> bool #foreign jolt_release "?sIsValidBodyPointer@BodyManager@JPH@@SA_NPEBVBody@2@@Z";

    /// Get all bodies. Note that this can contain invalid body pointers, call sIsValidBodyPointer to check.
    GetBodies :: (this: /*const*/ *BodyManager) -> *BodyVector #cpp_method #foreign jolt_release "?GetBodies@BodyManager@JPH@@QEBAAEBV?$Array@PEAVBody@JPH@@V?$STLAllocator@PEAVBody@JPH@@@2@@2@XZ";

    /// Get all bodies. Note that this can contain invalid body pointers, call sIsValidBodyPointer to check.
    GetBodies_1 :: (this: *BodyManager) -> *BodyVector #cpp_method #foreign jolt_release "?GetBodies@BodyManager@JPH@@QEAAAEAV?$Array@PEAVBody@JPH@@V?$STLAllocator@PEAVBody@JPH@@@2@@2@XZ";

    /// Get all body IDs under the protection of a lock
    GetBodyIDs :: (this: *BodyManager, outBodies: *BodyIDVector) -> void #cpp_method #foreign jolt_release "?GetBodyIDs@BodyManager@JPH@@QEBAXAEAV?$Array@VBodyID@JPH@@V?$STLAllocator@VBodyID@JPH@@@2@@2@@Z";

    /// Access a body (not protected by lock)
    GetBody :: (this: /*const*/ *BodyManager, inID: /*const reference*/ *BodyID) -> *Body #cpp_method #foreign jolt_release "?GetBody@BodyManager@JPH@@QEBAAEBVBody@2@AEBVBodyID@2@@Z";
    GetBody :: (this: *BodyManager, inID: BodyID) -> *Body #no_context {
        return GetBody(this, *inID);
    }

    /// Access a body (not protected by lock)
    GetBody_1 :: (this: *BodyManager, inID: /*const reference*/ *BodyID) -> *Body #cpp_method #foreign jolt_release "?GetBody@BodyManager@JPH@@QEAAAEAVBody@2@AEBVBodyID@2@@Z";
    GetBody_1 :: (this: *BodyManager, inID: BodyID) -> *Body #no_context {
        return GetBody_1(this, *inID);
    }

    /// Access a body, will return a nullptr if the body ID is no longer valid (not protected by lock)
    TryGetBody :: (this: *BodyManager, inID: *BodyID) -> *Body #cpp_method #foreign jolt_release "?TryGetBody@BodyManager@JPH@@QEAAPEAVBody@2@AEBVBodyID@2@@Z";
    TryGetBody :: (this: *BodyManager, inID: BodyID) -> *Body #no_context {
        return TryGetBody(this, *inID);
    }

    /// Bodies are protected using an array of mutexes (so a fixed number, not 1 per body). Each bit in this mask indicates a locked mutex.
    MutexMask :: u64;

    ///@name Batch body mutex access (do not use directly)
    ///@{
    GetAllBodiesMutexMask :: (this: *BodyManager) -> MutexMask #cpp_method #foreign jolt_release "?GetAllBodiesMutexMask@BodyManager@JPH@@QEBA_KXZ";
    GetMutexMask :: (this: *BodyManager, inBodies: *BodyID, inNumber: s32) -> MutexMask #cpp_method #foreign jolt_release "?GetMutexMask@BodyManager@JPH@@QEBA_KPEBVBodyID@2@H@Z";
    LockRead :: (this: *BodyManager, inMutexMask: MutexMask) -> void #cpp_method #foreign jolt_release "?LockRead@BodyManager@JPH@@QEBAX_K@Z";
    UnlockRead :: (this: *BodyManager, inMutexMask: MutexMask) -> void #cpp_method #foreign jolt_release "?UnlockRead@BodyManager@JPH@@QEBAX_K@Z";
    LockWrite :: (this: *BodyManager, inMutexMask: MutexMask) -> void #cpp_method #foreign jolt_release "?LockWrite@BodyManager@JPH@@QEBAX_K@Z";
    UnlockWrite :: (this: *BodyManager, inMutexMask: MutexMask) -> void #cpp_method #foreign jolt_release "?UnlockWrite@BodyManager@JPH@@QEBAX_K@Z";

    /// Lock all bodies. This should only be done during PhysicsSystem::Update().
    LockAllBodies :: (this: *BodyManager) -> void #cpp_method #foreign jolt_release "?LockAllBodies@BodyManager@JPH@@QEBAXXZ";

    /// Unlock all bodies. This should only be done during PhysicsSystem::Update().
    UnlockAllBodies :: (this: *BodyManager) -> void #cpp_method #foreign jolt_release "?UnlockAllBodies@BodyManager@JPH@@QEBAXXZ";

    /// Function to update body's layer (should only be called by the BodyInterface since it also requires updating the broadphase)
    SetBodyObjectLayerInternal :: (this: *BodyManager, ioBody: *Body, inLayer: ObjectLayer) -> void #cpp_method #foreign jolt_release "?SetBodyObjectLayerInternal@BodyManager@JPH@@QEBAXAEAVBody@2@G@Z";

    /// Set the Body::EFlags::InvalidateContactCache flag for the specified body. This means that the collision cache is invalid for any body pair involving that body until the next physics step.
    InvalidateContactCacheForBody :: (this: *BodyManager, ioBody: *Body) -> void #cpp_method #foreign jolt_release "?InvalidateContactCacheForBody@BodyManager@JPH@@QEAAXAEAVBody@2@@Z";

    /// Reset the Body::EFlags::InvalidateContactCache flag for all bodies. All contact pairs in the contact cache will now by valid again.
    ValidateContactCacheForAllBodies :: (this: *BodyManager) -> void #cpp_method #foreign jolt_release "?ValidateContactCacheForAllBodies@BodyManager@JPH@@QEAAXXZ";

    /// Saving state for replay
    SaveState :: (this: *BodyManager, inStream: *StateRecorder, inFilter: *StateRecorderFilter) -> void #cpp_method #foreign jolt_release "?SaveState@BodyManager@JPH@@QEBAXAEAVStateRecorder@2@PEBVStateRecorderFilter@2@@Z";

    /// Restoring state for replay. Returns false if failed.
    RestoreState :: (this: *BodyManager, inStream: *StateRecorder) -> bool #cpp_method #foreign jolt_release "?RestoreState@BodyManager@JPH@@QEAA_NAEAVStateRecorder@2@@Z";

    /// Save the state of a single body for replay
    SaveBodyState :: (this: *BodyManager, inBody: *Body, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?SaveBodyState@BodyManager@JPH@@QEBAXAEBVBody@2@AEAVStateRecorder@2@@Z";
    SaveBodyState :: (this: *BodyManager, inBody: Body, inStream: *StateRecorder) #no_context {
        SaveBodyState(this, *inBody, inStream);
    }

    /// Save the state of a single body for replay
    RestoreBodyState :: (this: *BodyManager, inBody: *Body, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?RestoreBodyState@BodyManager@JPH@@QEAAXAEAVBody@2@AEAVStateRecorder@2@@Z";

    /// Per thread override of the locked state, to be used by the PhysicsSystem only!
    GrantActiveBodiesAccess :: struct {
        __empty_struct_padding: u8; // C++ makes empty structs have length 1
    }

    GetNextSequenceNumber :: (this: *BodyManager, inBodyIndex: s32) -> u8 #cpp_method #foreign jolt_release "?GetNextSequenceNumber@BodyManager@JPH@@AEAAEH@Z";

    /// Add a single body to mActiveBodies, note doesn't lock the active body mutex!
    AddBodyToActiveBodies :: (this: *BodyManager, ioBody: *Body) -> void #cpp_method #foreign jolt_release "?AddBodyToActiveBodies@BodyManager@JPH@@AEAAXAEAVBody@2@@Z";

    /// Remove a single body from mActiveBodies, note doesn't lock the active body mutex!
    RemoveBodyFromActiveBodies :: (this: *BodyManager, ioBody: *Body) -> void #cpp_method #foreign jolt_release "?RemoveBodyFromActiveBodies@BodyManager@JPH@@AEAAXAEAVBody@2@@Z";

    /// Helper function to remove a body from the manager
    RemoveBodyInternal :: (this: *BodyManager, inBodyID: *BodyID) -> *Body #cpp_method #foreign jolt_release "?RemoveBodyInternal@BodyManager@JPH@@AEAAPEAVBody@2@AEBVBodyID@2@@Z";
    RemoveBodyInternal :: (this: *BodyManager, inBodyID: BodyID) -> *Body #no_context {
        return RemoveBodyInternal(this, *inBodyID);
    }

    /// Helper function to delete a body (which could actually be a BodyWithMotionProperties)
    sDeleteBody :: (inBody: *Body) -> void #foreign jolt_release "?sDeleteBody@BodyManager@JPH@@CAXPEAVBody@2@@Z";

    /// List of pointers to all bodies. Contains invalid pointers for deleted bodies, check with sIsValidBodyPointer. Note that this array is reserved to the max bodies that is passed in the Init function so that adding bodies will not reallocate the array.
    mBodies:                   BodyVector;

    /// Current number of allocated bodies
    mNumBodies:                u32 = 0;

    /// Indicates that there are no more freed body IDs
    cBodyIDFreeListEnd:        u64 : ~0;

    /// Bit that indicates a pointer in mBodies is actually the index of the next freed body. We use the lowest bit because we know that Bodies need to be 16 byte aligned so addresses can never end in a 1 bit.
    cIsFreedBody:              u64 : 1;

    /// Amount of bits to shift to get an index to the next freed body
    cFreedBodyIndexShift:      u32 : 1;

    /// Index of first entry in mBodies that is unused
    mBodyIDFreeListStart:      u64 = cBodyIDFreeListEnd;

    /// Protects mBodies array (but not the bodies it points to), mNumBodies and mBodyIDFreeListStart
    mBodiesMutex:              Mutex;

    /// An array of mutexes protecting the bodies in the mBodies array
    BodyMutexes :: MutexArray(SharedMutex);
    mBodyMutexes:              BodyMutexes;

    /// List of next sequence number for a body ID
    mBodySequenceNumbers:      Array(u8);

    /// Mutex that protects the mActiveBodies array
    mActiveBodiesMutex:        Mutex;

    /// List of all active dynamic bodies (size is equal to max amount of bodies)
    mActiveBodies:             [2] *BodyID;

    /// How many bodies there are in the list of active bodies
    mNumActiveBodies:          [2] std.atomic(u32) #align 4;

    /// How many of the active bodies have continuous collision detection enabled
    mNumActiveCCDBodies:       u32 = 0;

    /// Mutex that protects the mBodiesCacheInvalid array
    mBodiesCacheInvalidMutex:  Mutex;

    /// List of all bodies that should have their cache invalidated
    mBodiesCacheInvalid:       BodyIDVector;

    /// Listener that is notified whenever a body is activated/deactivated
    mActivationListener:       *BodyActivationListener = null;

    /// Cached broadphase layer interface
    mBroadPhaseLayerInterface: *BroadPhaseLayerInterface = null;

    /// Debug system that tries to limit changes to active bodies during the PhysicsSystem::Update()
    mActiveBodiesLocked        := false;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// This is the list of locks used by the physics engine, they need to be locked in a particular order (from top of the list to bottom of the list) in order to prevent deadlocks
EPhysicsLockTypes :: enum s32 {
    BroadPhaseQuery  :: 1;
    PerBody          :: 2;
    BodiesList       :: 4;
    BroadPhaseUpdate :: 8;
    ConstraintsList  :: 16;
    ActiveBodiesList :: 32;
}

PhysicsLockContext :: *BodyManager;

/// Helpers to safely lock the different mutexes that are part of the physics system while preventing deadlock
/// Class that keeps track per thread which lock are taken and if the order of locking is correct
PhysicsLock :: struct {
    __empty_struct_padding: u8; // C++ makes empty structs have length 1

    LockData :: struct {
        mLockedMutexes: u32 = 0;
        mContext:       PhysicsLockContext = null;
    }
}

/// Helper class that is similar to std::unique_lock
UniqueLock :: struct(LockType: Type) {
    using noncopyable__raw: NonCopyable__RAW;

    mLock:                  *LockType;

    mContext:               PhysicsLockContext;
    mType:                  EPhysicsLockTypes;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// Helper class that is similar to std::shared_lock
SharedLock :: struct(LockType: Type) {
    using noncopyable__raw: NonCopyable__RAW;

    mLock:                  *LockType;

    mContext:               PhysicsLockContext;
    mType:                  EPhysicsLockTypes;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// Base class interface for locking a body. Usually you will use BodyLockRead / BodyLockWrite / BodyLockMultiRead / BodyLockMultiWrite instead.
BodyLockInterface :: struct {
    vtable:                 *BodyLockInterface_VTable;
    using noncopyable__raw: NonCopyable__RAW;

    /// Redefine MutexMask
    MutexMask :: BodyManager.MutexMask;

    /// Convert body ID to body
    TryGetBody :: (this: *BodyLockInterface, inBodyID: *BodyID) -> *Body #cpp_method #foreign jolt_release "?TryGetBody@BodyLockInterface@JPH@@QEBAPEAVBody@2@AEBVBodyID@2@@Z";
    TryGetBody :: (this: *BodyLockInterface, inBodyID: BodyID) -> *Body #no_context {
        return TryGetBody(this, *inBodyID);
    }

    mBodyManager:           *BodyManager;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_Destructor :: (this: *BodyLockInterface, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1BodyLockInterface@JPH@@UEAA@XZ";
}
BodyLockInterface_VTable :: struct #type_info_none {
    Destructor:    #type (this: *BodyLockInterface, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    LockRead:      #type (this: /*const*/ *BodyLockInterface, inMutexMask: BodyLockInterface.MutexMask) -> void #cpp_method;

    LockRead_1:    #type (this: /*const*/ *BodyLockInterface, inBodyID: /*const reference*/ *BodyID) -> *SharedMutex #cpp_method;

    UnlockRead:    #type (this: /*const*/ *BodyLockInterface, inMutexMask: BodyLockInterface.MutexMask) -> void #cpp_method;

    UnlockRead_1:  #type (this: /*const*/ *BodyLockInterface, inMutex: *SharedMutex) -> void #cpp_method;

    LockWrite:     #type (this: /*const*/ *BodyLockInterface, inMutexMask: BodyLockInterface.MutexMask) -> void #cpp_method;

    LockWrite_1:   #type (this: /*const*/ *BodyLockInterface, inBodyID: /*const reference*/ *BodyID) -> *SharedMutex #cpp_method;

    UnlockWrite:   #type (this: /*const*/ *BodyLockInterface, inMutexMask: BodyLockInterface.MutexMask) -> void #cpp_method;

    UnlockWrite_1: #type (this: /*const*/ *BodyLockInterface, inMutex: *SharedMutex) -> void #cpp_method;

    GetMutexMask:  #type (this: *BodyLockInterface, inBodies: *BodyID, inNumber: s32) -> BodyLockInterface.MutexMask #cpp_method;
}
BodyLockInterface_Destructor :: inline (this: *BodyLockInterface, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

BodyLockInterface_LockRead :: inline (this: /*const*/ *BodyLockInterface, inMutexMask: BodyLockInterface.MutexMask) { this.vtable.LockRead(this, inMutexMask); }

BodyLockInterface_LockRead_1 :: inline (this: /*const*/ *BodyLockInterface, inBodyID: /*const reference*/ *BodyID) -> *SharedMutex { return this.vtable.LockRead_1(this, inBodyID); }

BodyLockInterface_UnlockRead :: inline (this: /*const*/ *BodyLockInterface, inMutexMask: BodyLockInterface.MutexMask) { this.vtable.UnlockRead(this, inMutexMask); }

BodyLockInterface_UnlockRead_1 :: inline (this: /*const*/ *BodyLockInterface, inMutex: *SharedMutex) { this.vtable.UnlockRead_1(this, inMutex); }

BodyLockInterface_LockWrite :: inline (this: /*const*/ *BodyLockInterface, inMutexMask: BodyLockInterface.MutexMask) { this.vtable.LockWrite(this, inMutexMask); }

BodyLockInterface_LockWrite_1 :: inline (this: /*const*/ *BodyLockInterface, inBodyID: /*const reference*/ *BodyID) -> *SharedMutex { return this.vtable.LockWrite_1(this, inBodyID); }

BodyLockInterface_UnlockWrite :: inline (this: /*const*/ *BodyLockInterface, inMutexMask: BodyLockInterface.MutexMask) { this.vtable.UnlockWrite(this, inMutexMask); }

BodyLockInterface_UnlockWrite_1 :: inline (this: /*const*/ *BodyLockInterface, inMutex: *SharedMutex) { this.vtable.UnlockWrite_1(this, inMutex); }

BodyLockInterface_GetMutexMask :: inline (this: *BodyLockInterface, inBodies: *BodyID, inNumber: s32) -> BodyLockInterface.MutexMask { return this.vtable.GetMutexMask(this, inBodies, inNumber); }

vtable :: (obj: *BodyLockInterface) -> *BodyLockInterface_VTable { return obj.vtable; }


/// Implementation that performs no locking (assumes the lock has already been taken)
BodyLockInterfaceNoLock :: struct {
    #as using bodylockinterface: BodyLockInterface;
}

/// Implementation that uses the body manager to lock the correct mutex for a body
BodyLockInterfaceLocking :: struct {
    #as using bodylockinterface: BodyLockInterface;
}

/// Base class for locking bodies for the duration of the scope of this class (do not use directly)
BodyLockBase :: struct(Write: bool, BodyType: Type) {
    using noncopyable__raw: NonCopyable__RAW;

    mBodyLockInterface:     *BodyLockInterface;
    mBodyLockMutex:         *SharedMutex;
    mBody:                  *BodyType;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// A body lock takes a body ID and locks the underlying body so that other threads cannot access its members
///
/// The common usage pattern is:
///
///		BodyLockInterface lock_interface = physics_system.GetBodyLockInterface(); // Or non-locking interface if the lock is already taken
///		BodyID body_id = ...; // Obtain ID to body
///
///		// Scoped lock
///		{
///			BodyLockRead lock(lock_interface, body_id);
///			if (lock.Succeeded()) // body_id may no longer be valid
///			{
///				const Body &body = lock.GetBody();
///
///				// Do something with body
///				...
///			}
///		}
BodyLockRead :: struct {
    #as using bodylockbase: BodyLockBase(false, Body);
}

/// Specialization that locks a body for writing to. @see BodyLockRead for usage patterns.
BodyLockWrite :: struct {
    #as using bodylockbase: BodyLockBase(true, Body);
}

BroadPhaseCastResult :: struct {}

OrientedBox :: struct {}
AABoxCast :: struct {}

// Various collector configurations
RayCastBodyCollector :: CollisionCollector(BroadPhaseCastResult, CollisionCollectorTraitsCastRay);
CastShapeBodyCollector :: CollisionCollector(BroadPhaseCastResult, CollisionCollectorTraitsCastShape);
CollideShapeBodyCollector :: CollisionCollector(BodyID, CollisionCollectorTraitsCollideShape);

/// Interface to the broadphase that can perform collision queries. These queries will only test the bounding box of the body to quickly determine a potential set of colliding bodies.
/// The shapes of the bodies are not tested, if you want this then you should use the NarrowPhaseQuery interface.
BroadPhaseQuery :: struct {
    vtable:                 *BroadPhaseQuery_VTable;
    using noncopyable__raw: NonCopyable__RAW;
    #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Virtual destructor
    virtual_Destructor :: (this: *BroadPhaseQuery, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1BroadPhaseQuery@JPH@@UEAA@XZ";
}
BroadPhaseQuery_VTable :: struct #type_info_none {
    Destructor:         #type (this: *BroadPhaseQuery, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    CastRay:            #type (this: *BroadPhaseQuery, inRay: *RayCast, ioCollector: *RayCastBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) -> void #cpp_method;

    CollideAABox:       #type (this: *BroadPhaseQuery, inBox: *AABox, ioCollector: *CollideShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) -> void #cpp_method;

    CollideSphere:      #type (this: *BroadPhaseQuery, inCenter: Vec3, inRadius: float, ioCollector: *CollideShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) -> void #cpp_method;

    CollidePoint:       #type (this: *BroadPhaseQuery, inPoint: Vec3, ioCollector: *CollideShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) -> void #cpp_method;

    CollideOrientedBox: #type (this: *BroadPhaseQuery, inBox: *OrientedBox, ioCollector: *CollideShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) -> void #cpp_method;

    CastAABox:          #type (this: *BroadPhaseQuery, inBox: *AABoxCast, ioCollector: *CastShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) -> void #cpp_method;

    GetBounds:          #type (this: *BroadPhaseQuery) -> AABox #cpp_method #cpp_return_type_is_non_pod;
}
BroadPhaseQuery_Destructor :: inline (this: *BroadPhaseQuery, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

BroadPhaseQuery_CastRay :: inline (this: *BroadPhaseQuery, inRay: *RayCast, ioCollector: *RayCastBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) { this.vtable.CastRay(this, inRay, ioCollector, inBroadPhaseLayerFilter, inObjectLayerFilter); }

BroadPhaseQuery_CollideAABox :: inline (this: *BroadPhaseQuery, inBox: *AABox, ioCollector: *CollideShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) { this.vtable.CollideAABox(this, inBox, ioCollector, inBroadPhaseLayerFilter, inObjectLayerFilter); }

BroadPhaseQuery_CollideSphere :: inline (this: *BroadPhaseQuery, inCenter: Vec3, inRadius: float, ioCollector: *CollideShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) { this.vtable.CollideSphere(this, inCenter, inRadius, ioCollector, inBroadPhaseLayerFilter, inObjectLayerFilter); }

BroadPhaseQuery_CollidePoint :: inline (this: *BroadPhaseQuery, inPoint: Vec3, ioCollector: *CollideShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) { this.vtable.CollidePoint(this, inPoint, ioCollector, inBroadPhaseLayerFilter, inObjectLayerFilter); }

BroadPhaseQuery_CollideOrientedBox :: inline (this: *BroadPhaseQuery, inBox: *OrientedBox, ioCollector: *CollideShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) { this.vtable.CollideOrientedBox(this, inBox, ioCollector, inBroadPhaseLayerFilter, inObjectLayerFilter); }

BroadPhaseQuery_CastAABox :: inline (this: *BroadPhaseQuery, inBox: *AABoxCast, ioCollector: *CastShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) { this.vtable.CastAABox(this, inBox, ioCollector, inBroadPhaseLayerFilter, inObjectLayerFilter); }

BroadPhaseQuery_GetBounds :: inline (this: *BroadPhaseQuery) -> AABox { return this.vtable.GetBounds(this); }

vtable :: (obj: *BroadPhaseQuery) -> *BroadPhaseQuery_VTable { return obj.vtable; }


/// Class that provides an interface for doing precise collision detection against the broad and then the narrow phase.
/// Unlike a BroadPhaseQuery, the NarrowPhaseQuery will test against shapes and will return collision information against triangles, spheres etc.
NarrowPhaseQuery :: struct {
    using noncopyable__raw: NonCopyable__RAW;

    /// Initialize the interface (should only be called by PhysicsSystem)
    Init :: (this: *NarrowPhaseQuery, inBodyLockInterface: *BodyLockInterface, inBroadPhaseQuery: *BroadPhaseQuery) -> void #cpp_method #foreign jolt_release "?Init@NarrowPhaseQuery@JPH@@QEAAXAEAVBodyLockInterface@2@AEAVBroadPhaseQuery@2@@Z";

    /// Cast a ray and find the closest hit. Returns true if it finds a hit. Hits further than ioHit.mFraction will not be considered and in this case ioHit will remain unmodified (and the function will return false).
    /// Convex objects will be treated as solid (meaning if the ray starts inside, you'll get a hit fraction of 0) and back face hits against triangles are returned.
    /// If you want the surface normal of the hit use Body::GetWorldSpaceSurfaceNormal(ioHit.mSubShapeID2, inRay.GetPointOnRay(ioHit.mFraction)) on body with ID ioHit.mBodyID.
    CastRay :: (this: *NarrowPhaseQuery, inRay: *RRayCast, ioHit: *RayCastResult, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter, inBodyFilter: *BodyFilter) -> bool #cpp_method #foreign jolt_release "?CastRay@NarrowPhaseQuery@JPH@@QEBA_NAEBURRayCast@2@AEAVRayCastResult@2@AEBVBroadPhaseLayerFilter@2@AEBVObjectLayerFilter@2@AEBVBodyFilter@2@@Z";
    CastRay :: (this: *NarrowPhaseQuery, inRay: RRayCast, ioHit: *RayCastResult, inBroadPhaseLayerFilter: BroadPhaseLayerFilter, inObjectLayerFilter: ObjectLayerFilter, inBodyFilter: BodyFilter) -> bool #no_context {
        return CastRay(this, *inRay, ioHit, *inBroadPhaseLayerFilter, *inObjectLayerFilter, *inBodyFilter);
    }

    /// Cast a ray, allows collecting multiple hits. Note that this version is more flexible but also slightly slower than the CastRay function that returns only a single hit.
    /// If you want the surface normal of the hit use Body::GetWorldSpaceSurfaceNormal(collected sub shape ID, inRay.GetPointOnRay(collected fraction)) on body with collected body ID.
    CastRay :: (this: *NarrowPhaseQuery, inRay: *RRayCast, inRayCastSettings: *RayCastSettings, ioCollector: *CastRayCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter, inBodyFilter: *BodyFilter, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CastRay@NarrowPhaseQuery@JPH@@QEBAXAEBURRayCast@2@AEBVRayCastSettings@2@AEAV?$CollisionCollector@VRayCastResult@JPH@@VCollisionCollectorTraitsCastRay@2@@2@AEBVBroadPhaseLayerFilter@2@AEBVObjectLayerFilter@2@AEBVBodyFilter@2@AEBVShapeFilter@2@@Z";
    CastRay :: (this: *NarrowPhaseQuery, inRay: RRayCast, inRayCastSettings: RayCastSettings, ioCollector: *CastRayCollector, inBroadPhaseLayerFilter: BroadPhaseLayerFilter, inObjectLayerFilter: ObjectLayerFilter, inBodyFilter: BodyFilter, inShapeFilter: ShapeFilter) #no_context {
        CastRay(this, *inRay, *inRayCastSettings, ioCollector, *inBroadPhaseLayerFilter, *inObjectLayerFilter, *inBodyFilter, *inShapeFilter);
    }

    /// Check if inPoint is inside any shapes. For this tests all shapes are treated as if they were solid.
    /// For a mesh shape, this test will only provide sensible information if the mesh is a closed manifold.
    /// For each shape that collides, ioCollector will receive a hit
    CollidePoint :: (this: *NarrowPhaseQuery, inPoint: Vector3, ioCollector: *CollidePointCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter, inBodyFilter: *BodyFilter, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CollidePoint@NarrowPhaseQuery@JPH@@QEBAXVVec3@2@AEAV?$CollisionCollector@VCollidePointResult@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVBroadPhaseLayerFilter@2@AEBVObjectLayerFilter@2@AEBVBodyFilter@2@AEBVShapeFilter@2@@Z";
    CollidePoint :: (this: *NarrowPhaseQuery, inPoint: Vector3, ioCollector: *CollidePointCollector, inBroadPhaseLayerFilter: BroadPhaseLayerFilter, inObjectLayerFilter: ObjectLayerFilter, inBodyFilter: BodyFilter, inShapeFilter: ShapeFilter) #no_context {
        CollidePoint(this, inPoint, ioCollector, *inBroadPhaseLayerFilter, *inObjectLayerFilter, *inBodyFilter, *inShapeFilter);
    }

    /// Collide a shape with the system
    /// @param inShape Shape to test
    /// @param inShapeScale Scale in local space of shape
    /// @param inCenterOfMassTransform Center of mass transform for the shape
    /// @param inCollideShapeSettings Settings
    /// @param inBaseOffset All hit results will be returned relative to this offset, can be zero to get results in world position, but when you're testing far from the origin you get better precision by picking a position that's closer e.g. inCenterOfMassTransform.GetTranslation() since floats are most accurate near the origin
    /// @param ioCollector Collector that receives the hits
    /// @param inBroadPhaseLayerFilter Filter that filters at broadphase level
    /// @param inObjectLayerFilter Filter that filters at layer level
    /// @param inBodyFilter Filter that filters at body level
    /// @param inShapeFilter Filter that filters at shape level
    CollideShape :: (this: *NarrowPhaseQuery, inShape: *Shape, inShapeScale: Vec3, inCenterOfMassTransform: Matrix4, inCollideShapeSettings: *CollideShapeSettings, inBaseOffset: Vector3, ioCollector: *CollideShapeCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter, inBodyFilter: *BodyFilter, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CollideShape@NarrowPhaseQuery@JPH@@QEBAXPEBVShape@2@VVec3@2@AEBVMat44@2@AEBVCollideShapeSettings@2@1AEAV?$CollisionCollector@VCollideShapeResult@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVBroadPhaseLayerFilter@2@AEBVObjectLayerFilter@2@AEBVBodyFilter@2@AEBVShapeFilter@2@@Z";
    CollideShape :: (this: *NarrowPhaseQuery, inShape: *Shape, inShapeScale: Vec3, inCenterOfMassTransform: Matrix4, inCollideShapeSettings: CollideShapeSettings, inBaseOffset: Vector3, ioCollector: *CollideShapeCollector, inBroadPhaseLayerFilter: BroadPhaseLayerFilter, inObjectLayerFilter: ObjectLayerFilter, inBodyFilter: BodyFilter, inShapeFilter: ShapeFilter) #no_context {
        CollideShape(this, inShape, inShapeScale, inCenterOfMassTransform, *inCollideShapeSettings, inBaseOffset, ioCollector, *inBroadPhaseLayerFilter, *inObjectLayerFilter, *inBodyFilter, *inShapeFilter);
    }

    /// Same as CollideShape, but uses InternalEdgeRemovingCollector to remove internal edges from the collision results (a.k.a. ghost collisions)
    CollideShapeWithInternalEdgeRemoval :: (this: *NarrowPhaseQuery, inShape: *Shape, inShapeScale: Vec3, inCenterOfMassTransform: Matrix4, inCollideShapeSettings: *CollideShapeSettings, inBaseOffset: Vector3, ioCollector: *CollideShapeCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter, inBodyFilter: *BodyFilter, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CollideShapeWithInternalEdgeRemoval@NarrowPhaseQuery@JPH@@QEBAXPEBVShape@2@VVec3@2@AEBVMat44@2@AEBVCollideShapeSettings@2@1AEAV?$CollisionCollector@VCollideShapeResult@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVBroadPhaseLayerFilter@2@AEBVObjectLayerFilter@2@AEBVBodyFilter@2@AEBVShapeFilter@2@@Z";
    CollideShapeWithInternalEdgeRemoval :: (this: *NarrowPhaseQuery, inShape: *Shape, inShapeScale: Vec3, inCenterOfMassTransform: Matrix4, inCollideShapeSettings: CollideShapeSettings, inBaseOffset: Vector3, ioCollector: *CollideShapeCollector, inBroadPhaseLayerFilter: BroadPhaseLayerFilter, inObjectLayerFilter: ObjectLayerFilter, inBodyFilter: BodyFilter, inShapeFilter: ShapeFilter) #no_context {
        CollideShapeWithInternalEdgeRemoval(this, inShape, inShapeScale, inCenterOfMassTransform, *inCollideShapeSettings, inBaseOffset, ioCollector, *inBroadPhaseLayerFilter, *inObjectLayerFilter, *inBodyFilter, *inShapeFilter);
    }

    /// Cast a shape and report any hits to ioCollector
    /// @param inShapeCast The shape cast and its position and direction
    /// @param inShapeCastSettings Settings for the shape cast
    /// @param inBaseOffset All hit results will be returned relative to this offset, can be zero to get results in world position, but when you're testing far from the origin you get better precision by picking a position that's closer e.g. inShapeCast.mCenterOfMassStart.GetTranslation() since floats are most accurate near the origin
    /// @param ioCollector Collector that receives the hits
    /// @param inBroadPhaseLayerFilter Filter that filters at broadphase level
    /// @param inObjectLayerFilter Filter that filters at layer level
    /// @param inBodyFilter Filter that filters at body level
    /// @param inShapeFilter Filter that filters at shape level
    CastShape :: (this: *NarrowPhaseQuery, inShapeCast: *RShapeCast, inShapeCastSettings: *ShapeCastSettings, inBaseOffset: Vector3, ioCollector: *CastShapeCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter, inBodyFilter: *BodyFilter, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CastShape@NarrowPhaseQuery@JPH@@QEBAXAEBURShapeCast@2@AEBVShapeCastSettings@2@VVec3@2@AEAV?$CollisionCollector@VShapeCastResult@JPH@@VCollisionCollectorTraitsCastShape@2@@2@AEBVBroadPhaseLayerFilter@2@AEBVObjectLayerFilter@2@AEBVBodyFilter@2@AEBVShapeFilter@2@@Z";
    CastShape :: (this: *NarrowPhaseQuery, inShapeCast: RShapeCast, inShapeCastSettings: ShapeCastSettings, inBaseOffset: Vector3, ioCollector: *CastShapeCollector, inBroadPhaseLayerFilter: BroadPhaseLayerFilter, inObjectLayerFilter: ObjectLayerFilter, inBodyFilter: BodyFilter, inShapeFilter: ShapeFilter) #no_context {
        CastShape(this, *inShapeCast, *inShapeCastSettings, inBaseOffset, ioCollector, *inBroadPhaseLayerFilter, *inObjectLayerFilter, *inBodyFilter, *inShapeFilter);
    }

    /// Collect all leaf transformed shapes that fall inside world space box inBox
    CollectTransformedShapes :: (this: *NarrowPhaseQuery, inBox: *AABox, ioCollector: *TransformedShapeCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter, inBodyFilter: *BodyFilter, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CollectTransformedShapes@NarrowPhaseQuery@JPH@@QEBAXAEBVAABox@2@AEAV?$CollisionCollector@VTransformedShape@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVBroadPhaseLayerFilter@2@AEBVObjectLayerFilter@2@AEBVBodyFilter@2@AEBVShapeFilter@2@@Z";
    CollectTransformedShapes :: (this: *NarrowPhaseQuery, inBox: AABox, ioCollector: *TransformedShapeCollector, inBroadPhaseLayerFilter: BroadPhaseLayerFilter, inObjectLayerFilter: ObjectLayerFilter, inBodyFilter: BodyFilter, inShapeFilter: ShapeFilter) #no_context {
        CollectTransformedShapes(this, *inBox, ioCollector, *inBroadPhaseLayerFilter, *inObjectLayerFilter, *inBodyFilter, *inShapeFilter);
    }

    mBodyLockInterface:     *BodyLockInterface = null;
    mBroadPhaseQuery:       *BroadPhaseQuery = null;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// A pair of bodies and their sub shape ID's. Can be used as a key in a map to find a contact point.
SubShapeIDPair :: struct {
    /// Constructor
    Constructor :: (this: *SubShapeIDPair) -> void #cpp_method #foreign jolt_release "??0SubShapeIDPair@JPH@@QEAA@XZ";
    Constructor :: (this: *SubShapeIDPair, inBody1ID: *BodyID, inSubShapeID1: *SubShapeID, inBody2ID: *BodyID, inSubShapeID2: *SubShapeID) -> void #cpp_method #foreign jolt_release "??0SubShapeIDPair@JPH@@QEAA@AEBVBodyID@1@AEBVSubShapeID@1@01@Z";
    Constructor :: (this: *SubShapeIDPair, inBody1ID: BodyID, inSubShapeID1: SubShapeID, inBody2ID: BodyID, inSubShapeID2: SubShapeID) #no_context {
        Constructor(this, *inBody1ID, *inSubShapeID1, *inBody2ID, *inSubShapeID2);
    }

    GetBody1ID :: (this: *SubShapeIDPair) -> *BodyID #cpp_method #foreign jolt_release "?GetBody1ID@SubShapeIDPair@JPH@@QEBAAEBVBodyID@2@XZ";
    GetSubShapeID1 :: (this: *SubShapeIDPair) -> *SubShapeID #cpp_method #foreign jolt_release "?GetSubShapeID1@SubShapeIDPair@JPH@@QEBAAEBVSubShapeID@2@XZ";
    GetBody2ID :: (this: *SubShapeIDPair) -> *BodyID #cpp_method #foreign jolt_release "?GetBody2ID@SubShapeIDPair@JPH@@QEBAAEBVBodyID@2@XZ";
    GetSubShapeID2 :: (this: *SubShapeIDPair) -> *SubShapeID #cpp_method #foreign jolt_release "?GetSubShapeID2@SubShapeIDPair@JPH@@QEBAAEBVSubShapeID@2@XZ";

    GetHash :: (this: *SubShapeIDPair) -> u64 #cpp_method #foreign jolt_release "?GetHash@SubShapeIDPair@JPH@@QEBA_KXZ";

    mBody1ID:     BodyID;
    mSubShapeID1: SubShapeID;
    mBody2ID:     BodyID;
    mSubShapeID2: SubShapeID;
}

/// Array of contact points
ContactPoints :: StaticArray(Vec3, 64);

/// Manifold class, describes the contact surface between two bodies
ContactManifold :: struct {
    /// Swaps shape 1 and 2
    SwapShapes :: (this: *ContactManifold) -> ContactManifold #cpp_method #foreign jolt_release "?SwapShapes@ContactManifold@JPH@@QEBA?AV12@XZ";

    mBaseOffset:               Vec3; ///< Offset to which all the contact points are relative
    mWorldSpaceNormal:         Vec3; ///< Normal for this manifold, direction along which to move body 2 out of collision along the shortest path
    mPenetrationDepth:         float; ///< Penetration depth (move shape 2 by this distance to resolve the collision). If this value is negative, this is a speculative contact point and may not actually result in a velocity change as during solving the bodies may not actually collide.
    mSubShapeID1:              SubShapeID; ///< Sub shapes that formed this manifold (note that when multiple manifolds are combined because they're coplanar, we lose some information here because we only keep track of one sub shape pair that we encounter, see description at Body::SetUseManifoldReduction)
    mSubShapeID2:              SubShapeID;
    mRelativeContactPointsOn1: ContactPoints; ///< Contact points on the surface of shape 1 relative to mBaseOffset.
    mRelativeContactPointsOn2: ContactPoints; ///< Contact points on the surface of shape 2 relative to mBaseOffset. If there's no penetration, this will be the same as mRelativeContactPointsOn1. If there is penetration they will be different.
}

/// When a contact point is added or persisted, the callback gets a chance to override certain properties of the contact constraint.
/// The values are filled in with their defaults by the system so the callback doesn't need to modify anything, but it can if it wants to.
ContactSettings :: struct {
    mCombinedFriction:               float; ///< Combined friction for the body pair (see: PhysicsSystem::SetCombineFriction)
    mCombinedRestitution:            float; ///< Combined restitution for the body pair (see: PhysicsSystem::SetCombineRestitution)
    mInvMassScale1:                  float = 1.0; ///< Scale factor for the inverse mass of body 1 (0 = infinite mass, 1 = use original mass, 2 = body has half the mass). For the same contact pair, you should strive to keep the value the same over time.
    mInvInertiaScale1:               float = 1.0; ///< Scale factor for the inverse inertia of body 1 (usually same as mInvMassScale1)
    mInvMassScale2:                  float = 1.0; ///< Scale factor for the inverse mass of body 2 (0 = infinite mass, 1 = use original mass, 2 = body has half the mass). For the same contact pair, you should strive to keep the value the same over time.
    mInvInertiaScale2:               float = 1.0; ///< Scale factor for the inverse inertia of body 2 (usually same as mInvMassScale2)
    mIsSensor:                       bool; ///< If the contact should be treated as a sensor vs body contact (no collision response)
    mRelativeLinearSurfaceVelocity:  Vec3; ///< Relative linear surface velocity between the bodies (world space surface velocity of body 2 - world space surface velocity of body 1), can be used to create a conveyor belt effect
    mRelativeAngularSurfaceVelocity: Vec3; ///< Relative angular surface velocity between the bodies (world space angular surface velocity of body 2 - world space angular surface velocity of body 1). Note that this angular velocity is relative to the center of mass of body 1, so if you want it relative to body 2's center of mass you need to add body 2 angular velocity x (body 1 world space center of mass - body 2 world space center of mass) to mRelativeLinearSurfaceVelocity.
}

/// Return value for the OnContactValidate callback. Determines if the contact is being processed or not.
/// Results are ordered so that the strongest accept has the lowest number and the strongest reject the highest number (which allows for easy combining of results)
ValidateResult :: enum s32 {
    AcceptAllContactsForThisBodyPair :: 0;
    AcceptContact                    :: 1;
    RejectContact                    :: 2;
    RejectAllContactsForThisBodyPair :: 3;
}

/// A listener class that receives collision contact events. It can be registered through PhysicsSystem::SetContactListener.
/// Only a single contact listener can be registered. A common pattern is to create a contact listener that casts Body::GetUserData
/// to a game object and then forwards the call to a handler specific for that game object.
/// Typically this is done on both objects involved in a collision event.
///
/// Note that contact listener callbacks are called from multiple threads at the same time when all bodies are locked, this means you cannot
/// use PhysicsSystem::GetBodyInterface / PhysicsSystem::GetBodyLockInterface but must use PhysicsSystem::GetBodyInterfaceNoLock / PhysicsSystem::GetBodyLockInterfaceNoLock instead.
/// If you use a locking interface, the simulation will deadlock. You're only allowed to read from the bodies and you can't change physics state.
/// During OnContactRemoved you cannot access the bodies at all, see the comments at that function.
///
/// While a callback can come from multiple threads, all callbacks relating to a single body pair are serialized.
/// For EMotionQuality::Discrete bodies, during every 'collision step' in a PhysicsSystem::Update, you will receive at most one OnContactAdded/Persisted/Removed call per body/sub shape pair.
/// For EMotionQuality::LinearCast bodies, you may get an OnContactAdded followed by an OnContactPersisted for the same body/sub shape pair.
/// This happens when a body collides both in the discrete and the continuous collision detection stage.
ContactListener :: struct {
    vtable: *ContactListener_VTable;
}
ContactListener_VTable :: struct #type_info_none {
    Destructor:         #type (this: *ContactListener, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    OnContactValidate:  #type (this: *ContactListener, inBody1: *Body, inBody2: *Body, inBaseOffset: Vector3, inCollisionResult: *CollideShapeResult) -> ValidateResult #cpp_method;

    OnContactAdded:     #type (this: *ContactListener, inBody1: *Body, inBody2: *Body, inManifold: *ContactManifold, ioSettings: *ContactSettings) -> void #cpp_method;

    OnContactPersisted: #type (this: *ContactListener, inBody1: *Body, inBody2: *Body, inManifold: *ContactManifold, ioSettings: *ContactSettings) -> void #cpp_method;

    OnContactRemoved:   #type (this: *ContactListener, inSubShapePair: *SubShapeIDPair) -> void #cpp_method;
}
ContactListener_Destructor :: inline (this: *ContactListener, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

ContactListener_OnContactValidate :: inline (this: *ContactListener, inBody1: *Body, inBody2: *Body, inBaseOffset: Vector3, inCollisionResult: *CollideShapeResult) -> ValidateResult { return this.vtable.OnContactValidate(this, inBody1, inBody2, inBaseOffset, inCollisionResult); }

ContactListener_OnContactAdded :: inline (this: *ContactListener, inBody1: *Body, inBody2: *Body, inManifold: *ContactManifold, ioSettings: *ContactSettings) { this.vtable.OnContactAdded(this, inBody1, inBody2, inManifold, ioSettings); }

ContactListener_OnContactPersisted :: inline (this: *ContactListener, inBody1: *Body, inBody2: *Body, inManifold: *ContactManifold, ioSettings: *ContactSettings) { this.vtable.OnContactPersisted(this, inBody1, inBody2, inManifold, ioSettings); }

ContactListener_OnContactRemoved :: inline (this: *ContactListener, inSubShapePair: *SubShapeIDPair) { this.vtable.OnContactRemoved(this, inSubShapePair); }

vtable :: (obj: *ContactListener) -> *ContactListener_VTable { return obj.vtable; }


/// Allocator for a lock free hash map
LFHMAllocator :: struct {
    using noncopyable__raw: NonCopyable__RAW;

    /// Destructor
    Destructor :: (this: *LFHMAllocator) -> void #cpp_method #foreign jolt_release "??1LFHMAllocator@JPH@@QEAA@XZ";

    /// Initialize the allocator
    /// @param inObjectStoreSizeBytes Number of bytes to reserve for all key value pairs
    Init :: (this: *LFHMAllocator, inObjectStoreSizeBytes: u32) -> void #cpp_method #foreign jolt_release "?Init@LFHMAllocator@JPH@@QEAAXI@Z";

    /// Clear all allocations
    Clear :: (this: *LFHMAllocator) -> void #cpp_method #foreign jolt_release "?Clear@LFHMAllocator@JPH@@QEAAXXZ";

    /// Allocate a new block of data
    /// @param inBlockSize Size of block to allocate (will potentially return a smaller block if memory is full).
    /// @param ioBegin Should be the start of the first free byte in current memory block on input, will contain the start of the first free byte in allocated block on return.
    /// @param ioEnd Should be the byte beyond the current memory block on input, will contain the byte beyond the allocated block on return.
    Allocate :: (this: *LFHMAllocator, inBlockSize: u32, ioBegin: *u32, ioEnd: *u32) -> void #cpp_method #foreign jolt_release "?Allocate@LFHMAllocator@JPH@@QEAAXIAEAI0@Z";

    mObjectStore:           *u8 = null; ///< This contains a contiguous list of objects (possibly of varying size)
    mObjectStoreSizeBytes:  u32 = 0; ///< The size of mObjectStore in bytes
    mWriteOffset:           std.atomic(u32) = 0; ///< Next offset to write to in mObjectStore
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// Allocator context object for a lock free hash map that allocates a larger memory block at once and hands it out in smaller portions.
/// This avoids contention on the atomic LFHMAllocator::mWriteOffset.
LFHMAllocatorContext :: struct {
    using noncopyable__raw: NonCopyable__RAW;

    /// Construct a new allocator context
    Constructor :: (this: *LFHMAllocatorContext, inAllocator: *LFHMAllocator, inBlockSize: u32) -> void #cpp_method #foreign jolt_release "??0LFHMAllocatorContext@JPH@@QEAA@AEAVLFHMAllocator@1@I@Z";

    /// @brief Allocate data block
    /// @param inSize Size of block to allocate.
    /// @param inAlignment Alignment of block to allocate.
    /// @param outWriteOffset Offset in buffer where block is located
    /// @return True if allocation succeeded
    Allocate :: (this: *LFHMAllocatorContext, inSize: u32, inAlignment: u32, outWriteOffset: *u32) -> bool #cpp_method #foreign jolt_release "?Allocate@LFHMAllocatorContext@JPH@@QEAA_NIIAEAI@Z";

    mAllocator:             *LFHMAllocator;
    mBlockSize:             u32;
    mBegin:                 u32 = 0;
    mEnd:                   u32 = 0;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// Very simple lock free hash map that only allows insertion, retrieval and provides a fixed amount of buckets and fixed storage.
/// Note: This class currently assumes key and value are simple types that need no calls to the destructor.
LockFreeHashMap :: struct(Key: Type, Value: Type) {
    using noncopyable__raw: NonCopyable__RAW;

    MapType :: LockFreeHashMap(Key, Value);

    /// A key / value pair that is inserted in the map
    KeyValue :: struct {
        mKey:        Key; ///< Key for this entry
        mNextOffset: u32; ///< Offset in mObjectStore of next KeyValue entry with same hash
        mValue:      Value; ///< Value for this entry + optionally extra bytes
    }

    /// Value of an invalid handle
    cInvalidHandle:         u32 : 0xffff_ffff;

    /// Non-const iterator
    Iterator :: struct {
        mMap:    *MapType;
        mBucket: u32;
        mOffset: u32;
    } #no_padding

    mAllocator:             *LFHMAllocator; ///< Allocator used to allocate key value pairs

    mNumKeyValues:          std.atomic(u32) = 0; ///< Number of key value pairs in the store

    mBuckets:               *std.atomic(u32) = null; ///< This contains the offset in mObjectStore of the first object with a particular hash
    mNumBuckets:            u32 = 0; ///< Current number of buckets
    mMaxBuckets:            u32 = 0; ///< Maximum number of buckets
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// Enum used by PhysicsSystem to report error conditions during the PhysicsSystem::Update call. This is a bit field, multiple errors can trigger in the same update.
EPhysicsUpdateError :: enum u32 {
    None                   :: 0;
    ManifoldCacheFull      :: 1;
    BodyPairCacheFull      :: 2;
    ContactConstraintsFull :: 4;
}

/// Structure that holds a body pair
BodyPair :: struct {
    /// Constructor
    Constructor :: (this: *BodyPair) -> void #cpp_method #foreign jolt_release "??0BodyPair@JPH@@QEAA@XZ";
    Constructor :: (this: *BodyPair, inA: BodyID, inB: BodyID) -> void #cpp_method #foreign jolt_release "??0BodyPair@JPH@@QEAA@VBodyID@1@0@Z";

    /// Get the hash value of this object
    GetHash :: (this: *BodyPair) -> u64 #cpp_method #foreign jolt_release "?GetHash@BodyPair@JPH@@QEBA_KXZ";

    mBodyA: BodyID;
    mBodyB: BodyID;

    _:      [0] u64; // Force BodyPair alignment to match the C/C++ equivalent
}

/// This structure describes the surface of (part of) a shape. You should inherit from it to define additional
/// information that is interesting for the simulation. The 2 materials involved in a contact could be used
/// to decide which sound or particle effects to play.
///
/// If you inherit from this material, don't forget to create a suitable default material in sDefault
PhysicsMaterial :: struct {
    #as using,except(vtable, sCreateRTTI) serializableobject: SerializableObject;
    #as using reftarget:    RefTarget(PhysicsMaterial);

    sCreateRTTI :: (inRTTI: *RTTI) -> void #foreign jolt_release "?sCreateRTTI@PhysicsMaterial@JPH@@SAXAEAVRTTI@2@@Z";

    /// Constructor
    Constructor :: (this: *PhysicsMaterial) -> void #cpp_method #foreign jolt_release "??0PhysicsMaterial@JPH@@QEAA@XZ";

    PhysicsMaterialResult :: Result(Ref(PhysicsMaterial));

    /// Creates a PhysicsMaterial of the correct type and restores its contents from the binary stream inStream.
    sRestoreFromBinaryState :: (inStream: *StreamIn) -> PhysicsMaterialResult #foreign jolt_release "?sRestoreFromBinaryState@PhysicsMaterial@JPH@@SA?AV?$Result@V?$Ref@VPhysicsMaterial@JPH@@@JPH@@@2@AEAVStreamIn@2@@Z";
    #overlay (serializableobject) vtable: *PhysicsMaterial_VTable; // Overlay parent's vtable with PhysicsMaterial’s vtable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_GetRTTI :: (this: *PhysicsMaterial) -> *RTTI #cpp_method #foreign jolt_release "?GetRTTI@PhysicsMaterial@JPH@@UEBAPEBVRTTI@2@XZ";
    virtual_CastTo :: (this: *PhysicsMaterial, inRTTI: *RTTI) -> *void #cpp_method #foreign jolt_release "?CastTo@PhysicsMaterial@JPH@@UEBAPEBXPEBVRTTI@2@@Z";

    virtual_Destructor :: (this: *PhysicsMaterial, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1PhysicsMaterial@JPH@@UEAA@XZ";

    // Properties
    virtual_GetDebugName :: (this: *PhysicsMaterial) -> *u8 #cpp_method #foreign jolt_release "?GetDebugName@PhysicsMaterial@JPH@@UEBAPEBDXZ";
    virtual_GetDebugColor :: (this: *PhysicsMaterial) -> Color #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetDebugColor@PhysicsMaterial@JPH@@UEBA?AVColor@2@XZ";

    /// Saves the contents of the material in binary form to inStream.
    virtual_SaveBinaryState :: (this: *PhysicsMaterial, inStream: *StreamOut) -> void #cpp_method #foreign jolt_release "?SaveBinaryState@PhysicsMaterial@JPH@@UEBAXAEAVStreamOut@2@@Z";

    /// This function should not be called directly, it is used by sRestoreFromBinaryState.
    virtual_RestoreBinaryState :: (this: *PhysicsMaterial, inStream: *StreamIn) -> void #cpp_method #foreign jolt_release "?RestoreBinaryState@PhysicsMaterial@JPH@@MEAAXAEAVStreamIn@2@@Z";
}
PhysicsMaterial_VTable :: struct #type_info_none {
    using vtable:       SerializableObject_VTable;

    GetDebugName:       #type (this: *PhysicsMaterial) -> *u8 #cpp_method;
    GetDebugColor:      #type (this: *PhysicsMaterial) -> Color #cpp_method #cpp_return_type_is_non_pod;

    SaveBinaryState:    #type (this: *PhysicsMaterial, inStream: *StreamOut) -> void #cpp_method;

    RestoreBinaryState: #type (this: *PhysicsMaterial, inStream: *StreamIn) -> void #cpp_method;
}
PhysicsMaterial_GetDebugName :: inline (this: *PhysicsMaterial) -> *u8 { return this.vtable.GetDebugName(this); }
PhysicsMaterial_GetDebugColor :: inline (this: *PhysicsMaterial) -> Color { return this.vtable.GetDebugColor(this); }

PhysicsMaterial_SaveBinaryState :: inline (this: *PhysicsMaterial, inStream: *StreamOut) { this.vtable.SaveBinaryState(this, inStream); }

PhysicsMaterial_RestoreBinaryState :: inline (this: *PhysicsMaterial, inStream: *StreamIn) { this.vtable.RestoreBinaryState(this, inStream); }

vtable :: (obj: *PhysicsMaterial) -> *PhysicsMaterial_VTable { return obj.vtable; }


/// Class that constructs a ConvexShape (abstract)
ConvexShapeSettings :: struct {
    #as using,except(sCreateRTTI) shapesettings: ShapeSettings;

    sCreateRTTI :: (inRTTI: *RTTI) -> void #foreign jolt_release "?sCreateRTTI@ConvexShapeSettings@JPH@@SAXAEAVRTTI@2@@Z";

    /// Constructor
    Constructor :: (this: *ConvexShapeSettings) -> void #cpp_method #foreign jolt_release "??0ConvexShapeSettings@JPH@@QEAA@XZ";
    Constructor :: (this: *ConvexShapeSettings, inMaterial: *PhysicsMaterial) -> void #cpp_method #foreign jolt_release "??0ConvexShapeSettings@JPH@@QEAA@PEBVPhysicsMaterial@1@@Z";

    mMaterial:         RefConst(PhysicsMaterial); ///< Material assigned to this shape
    mDensity:          float = 1000.0; ///< Uniform density of the interior of the convex object (kg / m^3)

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_GetRTTI :: (this: *ConvexShapeSettings) -> *RTTI #cpp_method #foreign jolt_release "?GetRTTI@ConvexShapeSettings@JPH@@UEBAPEBVRTTI@2@XZ";
    virtual_CastTo :: (this: *ConvexShapeSettings, inRTTI: *RTTI) -> *void #cpp_method #foreign jolt_release "?CastTo@ConvexShapeSettings@JPH@@UEBAPEBXPEBVRTTI@2@@Z";
}

/// Base class for all convex shapes. Defines a virtual interface.
ConvexShape :: struct {
    #as using,except(vtable) shape:            Shape;

    /// Constructor
    Constructor :: (this: *ConvexShape, inSubType: EShapeSubType) -> void #cpp_method #foreign jolt_release "??0ConvexShape@JPH@@QEAA@W4EShapeSubType@1@@Z";
    Constructor :: (this: *ConvexShape, inSubType: EShapeSubType, inSettings: *ConvexShapeSettings, outResult: *Shape.ShapeResult) -> void #cpp_method #foreign jolt_release "??0ConvexShape@JPH@@QEAA@W4EShapeSubType@1@AEBVConvexShapeSettings@1@AEAV?$Result@V?$Ref@VShape@JPH@@@JPH@@@1@@Z";
    Constructor :: (this: *ConvexShape, inSubType: EShapeSubType, inSettings: ConvexShapeSettings, outResult: *Shape.ShapeResult) #no_context {
        Constructor(this, inSubType, *inSettings, outResult);
    }
    Constructor :: (this: *ConvexShape, inSubType: EShapeSubType, inMaterial: *PhysicsMaterial) -> void #cpp_method #foreign jolt_release "??0ConvexShape@JPH@@QEAA@W4EShapeSubType@1@PEBVPhysicsMaterial@1@@Z";

    /// Function that provides an interface for GJK
    Support :: struct {
        vtable: *Support_VTable;

        // Virtual functions:
        // Normally you should call them via the vtable.
        // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
        // or need to create a vtable yourself.

        /// Warning: Virtual destructor will not be called on this object!
        virtual_Destructor :: (this: *Support, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1Support@ConvexShape@JPH@@UEAA@XZ";
    }
    Support_VTable :: struct #type_info_none {
        Destructor:      #type (this: *ConvexShape.Support, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

        GetSupport:      #type (this: *ConvexShape.Support, inDirection: Vec3) -> Vec3 #cpp_method #cpp_return_type_is_non_pod;

        GetConvexRadius: #type (this: *ConvexShape.Support) -> float #cpp_method;
    }
    Support_Destructor :: inline (this: *Support, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

    Support_GetSupport :: inline (this: *Support, inDirection: Vec3) -> Vec3 { return this.vtable.GetSupport(this, inDirection); }

    Support_GetConvexRadius :: inline (this: *Support) -> float { return this.vtable.GetConvexRadius(this); }

    vtable :: (obj: *Support) -> *Support_VTable { return obj.vtable; }


    /// Buffer to hold a Support object, used to avoid dynamic memory allocations
    SupportBuffer :: struct {
        mData: [4160] u8;

        _:     [0] u8 #align 16; // Force SupportBuffer alignment to match the C/C++ equivalent
    }

    /// How the GetSupport function should behave
    ESupportMode :: enum s32 {
        ExcludeConvexRadius :: 0;
        IncludeConvexRadius :: 1;
        Default             :: 2;
    }

    GetMaterial :: (this: /*const*/ *ConvexShape) -> *PhysicsMaterial #cpp_method #foreign jolt_release "?GetMaterial@ConvexShape@JPH@@QEBAPEBVPhysicsMaterial@2@XZ";

    /// Get density of the shape (kg / m^3)
    GetDensity :: (this: *ConvexShape) -> float #cpp_method #foreign jolt_release "?GetDensity@ConvexShape@JPH@@QEBAMXZ";

    // Register shape functions with the registry
    sRegister :: () -> void #foreign jolt_release "?sRegister@ConvexShape@JPH@@SAXXZ";

    /// Vertex list that forms a unit sphere
    sUnitSphereTriangles: StaticArray(Vec3, 384) : 384;

    // Class for GetTrianglesStart/Next
    CSGetTrianglesContext :: struct {}

    // Helper functions called by CollisionDispatch
    sCollideConvexVsConvex :: (inShape1: *Shape, inShape2: *Shape, inScale1: Vec3, inScale2: Vec3, inCenterOfMassTransform1: *Mat44, inCenterOfMassTransform2: *Mat44, inSubShapeIDCreator1: *SubShapeIDCreator, inSubShapeIDCreator2: *SubShapeIDCreator, inCollideShapeSettings: *CollideShapeSettings, ioCollector: *CollideShapeCollector, inShapeFilter: *ShapeFilter) -> void #foreign jolt_release "?sCollideConvexVsConvex@ConvexShape@JPH@@CAXPEBVShape@2@0VVec3@2@1AEBVMat44@2@2AEBVSubShapeIDCreator@2@3AEBVCollideShapeSettings@2@AEAV?$CollisionCollector@VCollideShapeResult@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVShapeFilter@2@@Z";
    sCollideConvexVsConvex :: (inShape1: *Shape, inShape2: *Shape, inScale1: Vec3, inScale2: Vec3, inCenterOfMassTransform1: *Mat44, inCenterOfMassTransform2: *Mat44, inSubShapeIDCreator1: SubShapeIDCreator, inSubShapeIDCreator2: SubShapeIDCreator, inCollideShapeSettings: CollideShapeSettings, ioCollector: *CollideShapeCollector, inShapeFilter: ShapeFilter) #no_context {
        sCollideConvexVsConvex(inShape1, inShape2, inScale1, inScale2, inCenterOfMassTransform1, inCenterOfMassTransform2, *inSubShapeIDCreator1, *inSubShapeIDCreator2, *inCollideShapeSettings, ioCollector, *inShapeFilter);
    }
    sCastConvexVsConvex :: (inShapeCast: *ShapeCast, inShapeCastSettings: *ShapeCastSettings, inShape: *Shape, inScale: Vec3, inShapeFilter: *ShapeFilter, inCenterOfMassTransform2: *Mat44, inSubShapeIDCreator1: *SubShapeIDCreator, inSubShapeIDCreator2: *SubShapeIDCreator, ioCollector: *CastShapeCollector) -> void #foreign jolt_release "?sCastConvexVsConvex@ConvexShape@JPH@@CAXAEBUShapeCast@2@AEBVShapeCastSettings@2@PEBVShape@2@VVec3@2@AEBVShapeFilter@2@AEBVMat44@2@AEBVSubShapeIDCreator@2@6AEAV?$CollisionCollector@VShapeCastResult@JPH@@VCollisionCollectorTraitsCastShape@2@@2@@Z";
    sCastConvexVsConvex :: (inShapeCast: ShapeCast, inShapeCastSettings: ShapeCastSettings, inShape: *Shape, inScale: Vec3, inShapeFilter: ShapeFilter, inCenterOfMassTransform2: *Mat44, inSubShapeIDCreator1: SubShapeIDCreator, inSubShapeIDCreator2: SubShapeIDCreator, ioCollector: *CastShapeCollector) #no_context {
        sCastConvexVsConvex(*inShapeCast, *inShapeCastSettings, inShape, inScale, *inShapeFilter, inCenterOfMassTransform2, *inSubShapeIDCreator1, *inSubShapeIDCreator2, ioCollector);
    }

    mMaterial:            RefConst(PhysicsMaterial); ///< Material assigned to this shape
    mDensity:             float = 1000.0; ///< Uniform density of the interior of the convex object (kg / m^3)
    #overlay (shape) vtable: *ConvexShape_VTable; // Overlay parent's vtable with ConvexShape’s vtable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    // See Shape::GetSubShapeIDBitsRecursive
    virtual_GetSubShapeIDBitsRecursive :: (this: *ConvexShape) -> u32 #cpp_method #foreign jolt_release "?GetSubShapeIDBitsRecursive@ConvexShape@JPH@@UEBAIXZ";

    // See Shape::GetMaterial
    virtual_GetMaterial_1 :: (this: /*const*/ *ConvexShape, inSubShapeID: /*const reference*/ *SubShapeID) -> *PhysicsMaterial #cpp_method #foreign jolt_release "?GetMaterial@ConvexShape@JPH@@UEBAPEBVPhysicsMaterial@2@AEBVSubShapeID@2@@Z";

    // See Shape::CastRay
    virtual_CastRay :: (this: /*const*/ *ConvexShape, inRay: /*const reference*/ *RayCast, inSubShapeIDCreator: /*const reference*/ *SubShapeIDCreator, ioHit: /*reference*/ *RayCastResult) -> bool #cpp_method #foreign jolt_release "?CastRay@ConvexShape@JPH@@UEBA_NAEBURayCast@2@AEBVSubShapeIDCreator@2@AEAVRayCastResult@2@@Z";
    virtual_CastRay_1 :: (this: /*const*/ *ConvexShape, inRay: /*const reference*/ *RayCast, inRayCastSettings: /*const reference*/ *RayCastSettings, inSubShapeIDCreator: /*const reference*/ *SubShapeIDCreator, ioCollector: /*reference*/ *CastRayCollector, inShapeFilter: /*const reference*/ *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CastRay@ConvexShape@JPH@@UEBAXAEBURayCast@2@AEBVRayCastSettings@2@AEBVSubShapeIDCreator@2@AEAV?$CollisionCollector@VRayCastResult@JPH@@VCollisionCollectorTraitsCastRay@2@@2@AEBVShapeFilter@2@@Z";

    // See: Shape::CollidePoint
    virtual_CollidePoint :: (this: *ConvexShape, inPoint: Vec3, inSubShapeIDCreator: *SubShapeIDCreator, ioCollector: *CollidePointCollector, inShapeFilter: *ShapeFilter) -> void #cpp_method #foreign jolt_release "?CollidePoint@ConvexShape@JPH@@UEBAXVVec3@2@AEBVSubShapeIDCreator@2@AEAV?$CollisionCollector@VCollidePointResult@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVShapeFilter@2@@Z";

    // See Shape::GetTrianglesStart
    virtual_GetTrianglesStart :: (this: *ConvexShape, ioContext: *Shape.GetTrianglesContext, inBox: *AABox, inPositionCOM: Vec3, inRotation: Quaternion, inScale: Vec3) -> void #cpp_method #foreign jolt_release "?GetTrianglesStart@ConvexShape@JPH@@UEBAXAEAUGetTrianglesContext@Shape@2@AEBVAABox@2@VVec3@2@VQuat@2@2@Z";

    // See Shape::GetTrianglesNext
    virtual_GetTrianglesNext :: (this: *ConvexShape, ioContext: *Shape.GetTrianglesContext, inMaxTrianglesRequested: s32, outTriangleVertices: *Float3, outMaterials: **PhysicsMaterial = null) -> s32 #cpp_method #foreign jolt_release "?GetTrianglesNext@ConvexShape@JPH@@UEBAHAEAUGetTrianglesContext@Shape@2@HPEAVFloat3@2@PEAPEBVPhysicsMaterial@2@@Z";

    // See Shape
    virtual_SaveBinaryState :: (this: *ConvexShape, inStream: *StreamOut) -> void #cpp_method #foreign jolt_release "?SaveBinaryState@ConvexShape@JPH@@UEBAXAEAVStreamOut@2@@Z";
    virtual_SaveMaterialState :: (this: *ConvexShape, outMaterials: *PhysicsMaterialList) -> void #cpp_method #foreign jolt_release "?SaveMaterialState@ConvexShape@JPH@@UEBAXAEAV?$Array@V?$RefConst@VPhysicsMaterial@JPH@@@JPH@@V?$STLAllocator@V?$RefConst@VPhysicsMaterial@JPH@@@JPH@@@2@@2@@Z";
    virtual_RestoreMaterialState :: (this: *ConvexShape, inMaterials: *PhysicsMaterialRefC, inNumMaterials: u32) -> void #cpp_method #foreign jolt_release "?RestoreMaterialState@ConvexShape@JPH@@UEAAXPEBV?$RefConst@VPhysicsMaterial@JPH@@@2@I@Z";

    // See: Shape::RestoreBinaryState
    virtual_RestoreBinaryState :: (this: *ConvexShape, inStream: *StreamIn) -> void #cpp_method #foreign jolt_release "?RestoreBinaryState@ConvexShape@JPH@@MEAAXAEAVStreamIn@2@@Z";
}
ConvexShape_VTable :: struct #type_info_none {
    using vtable:       Shape_VTable;

    GetSupportFunction: #type (this: *ConvexShape, inMode: ConvexShape.ESupportMode, inBuffer: *ConvexShape.SupportBuffer, inScale: Vec3) -> *ConvexShape.Support #cpp_method;
}
ConvexShape_GetSupportFunction :: inline (this: *ConvexShape, inMode: ConvexShape.ESupportMode, inBuffer: *ConvexShape.SupportBuffer, inScale: Vec3) -> *ConvexShape.Support { return this.vtable.GetSupportFunction(this, inMode, inBuffer, inScale); }

vtable :: (obj: *ConvexShape) -> *ConvexShape_VTable { return obj.vtable; }


/// Class used in other constraint parts to calculate the required bias factor in the lagrange multiplier for creating springs
SpringPart :: struct {
    CalculateSpringPropertiesHelper :: (this: *SpringPart, inDeltaTime: float, inInvEffectiveMass: float, inBias: float, inC: float, inStiffness: float, inDamping: float, outEffectiveMass: *float) -> void #cpp_method #foreign jolt_release "?CalculateSpringPropertiesHelper@SpringPart@JPH@@AEAAXMMMMMMAEAM@Z";

    /// Turn off the spring and set a bias only
    ///
    /// @param inBias Bias term (b) for the constraint impulse: lambda = J v + b
    CalculateSpringPropertiesWithBias :: (this: *SpringPart, inBias: float) -> void #cpp_method #foreign jolt_release "?CalculateSpringPropertiesWithBias@SpringPart@JPH@@QEAAXM@Z";

    /// Calculate spring properties based on frequency and damping ratio
    ///
    /// @param inDeltaTime Time step
    /// @param inInvEffectiveMass Inverse effective mass K
    /// @param inBias Bias term (b) for the constraint impulse: lambda = J v + b
    ///	@param inC Value of the constraint equation (C). Set to zero if you don't want to drive the constraint to zero with a spring.
    ///	@param inFrequency Oscillation frequency (Hz). Set to zero if you don't want to drive the constraint to zero with a spring.
    ///	@param inDamping Damping factor (0 = no damping, 1 = critical damping). Set to zero if you don't want to drive the constraint to zero with a spring.
    /// @param outEffectiveMass On return, this contains the new effective mass K^-1
    CalculateSpringPropertiesWithFrequencyAndDamping :: (this: *SpringPart, inDeltaTime: float, inInvEffectiveMass: float, inBias: float, inC: float, inFrequency: float, inDamping: float, outEffectiveMass: *float) -> void #cpp_method #foreign jolt_release "?CalculateSpringPropertiesWithFrequencyAndDamping@SpringPart@JPH@@QEAAXMMMMMMAEAM@Z";

    /// Calculate spring properties with spring Stiffness (k) and damping (c), this is based on the spring equation: F = -k * x - c * v
    ///
    /// @param inDeltaTime Time step
    /// @param inInvEffectiveMass Inverse effective mass K
    /// @param inBias Bias term (b) for the constraint impulse: lambda = J v + b
    ///	@param inC Value of the constraint equation (C). Set to zero if you don't want to drive the constraint to zero with a spring.
    ///	@param inStiffness Spring stiffness k. Set to zero if you don't want to drive the constraint to zero with a spring.
    ///	@param inDamping Spring damping coefficient c. Set to zero if you don't want to drive the constraint to zero with a spring.
    /// @param outEffectiveMass On return, this contains the new effective mass K^-1
    CalculateSpringPropertiesWithStiffnessAndDamping :: (this: *SpringPart, inDeltaTime: float, inInvEffectiveMass: float, inBias: float, inC: float, inStiffness: float, inDamping: float, outEffectiveMass: *float) -> void #cpp_method #foreign jolt_release "?CalculateSpringPropertiesWithStiffnessAndDamping@SpringPart@JPH@@QEAAXMMMMMMAEAM@Z";

    /// Returns if this spring is active
    IsActive :: (this: *SpringPart) -> bool #cpp_method #foreign jolt_release "?IsActive@SpringPart@JPH@@QEBA_NXZ";

    /// Get total bias b, including supplied bias and bias for spring: lambda = J v + b
    GetBias :: (this: *SpringPart, inTotalLambda: float) -> float #cpp_method #foreign jolt_release "?GetBias@SpringPart@JPH@@QEBAMM@Z";

    mBias:     float = 0.0;
    mSoftness: float = 0.0;
}

/// Enum used by constraints to specify how the spring is defined
ESpringMode :: enum u8 {
    FrequencyAndDamping :: 0;
    StiffnessAndDamping :: 1;
}

/// Settings for a linear or angular spring
SpringSettings :: struct {
    sCreateRTTI :: (inRTTI: *RTTI) -> void #foreign jolt_release "?sCreateRTTI@SpringSettings@JPH@@SAXAEAVRTTI@2@@Z";

    /// Constructor
    Constructor :: (this: *SpringSettings) -> void #cpp_method #foreign jolt_release "??0SpringSettings@JPH@@QEAA@XZ";

    Constructor :: (this: *SpringSettings, inMode: ESpringMode, inFrequencyOrStiffness: float, inDamping: float) -> void #cpp_method #foreign jolt_release "??0SpringSettings@JPH@@QEAA@W4ESpringMode@1@MM@Z";

    /// Saves the contents of the spring settings in binary form to inStream.
    SaveBinaryState :: (this: *SpringSettings, inStream: *StreamOut) -> void #cpp_method #foreign jolt_release "?SaveBinaryState@SpringSettings@JPH@@QEBAXAEAVStreamOut@2@@Z";

    /// Restores contents from the binary stream inStream.
    RestoreBinaryState :: (this: *SpringSettings, inStream: *StreamIn) -> void #cpp_method #foreign jolt_release "?RestoreBinaryState@SpringSettings@JPH@@QEAAXAEAVStreamIn@2@@Z";

    /// Check if the spring has a valid frequency / stiffness, if not the spring will be hard
    HasStiffness :: (this: *SpringSettings) -> bool #cpp_method #foreign jolt_release "?HasStiffness@SpringSettings@JPH@@QEBA_NXZ";

    /// Selects the way in which the spring is defined
    /// If the mode is StiffnessAndDamping then mFrequency becomes the stiffness (k) and mDamping becomes the damping ratio (c) in the spring equation F = -k * x - c * v. Otherwise the properties are as documented.
    mMode:    ESpringMode = .FrequencyAndDamping;

    union {
        /// Valid when mSpringMode = ESpringMode::FrequencyAndDamping.
        /// If mFrequency > 0 the constraint will be soft and mFrequency specifies the oscillation frequency in Hz.
        /// If mFrequency <= 0, mDamping is ignored and the constraint will have hard limits (as hard as the time step / the number of velocity / position solver steps allows).
        mFrequency: float = 0.0;

        /// Valid when mSpringMode = ESpringMode::StiffnessAndDamping.
        /// If mStiffness > 0 the constraint will be soft and mStiffness specifies the stiffness (k) in the spring equation F = -k * x - c * v for a linear or T = -k * theta - c * w for an angular spring.
        /// If mStiffness <= 0, mDamping is ignored and the constraint will have hard limits (as hard as the time step / the number of velocity / position solver steps allows).
        ///
        /// Note that stiffness values are large numbers. To calculate a ballpark value for the needed stiffness you can use:
        /// force = stiffness * delta_spring_length = mass * gravity <=> stiffness = mass * gravity / delta_spring_length.
        /// So if your object weighs 1500 kg and the spring compresses by 2 meters, you need a stiffness in the order of 1500 * 9.81 / 2 ~ 7500 N/m.
        mStiffness: float;
    }

    /// When mSpringMode = ESpringMode::FrequencyAndDamping mDamping is the damping ratio (0 = no damping, 1 = critical damping).
    /// When mSpringMode = ESpringMode::StiffnessAndDamping mDamping is the damping (c) in the spring equation F = -k * x - c * v for a linear or T = -k * theta - c * w for an angular spring.
    /// Note that if you set mDamping = 0, you will not get an infinite oscillation. Because we integrate physics using an explicit Euler scheme, there is always energy loss.
    /// This is done to keep the simulation from exploding, because with a damping of 0 and even the slightest rounding error, the oscillation could become bigger and bigger until the simulation explodes.
    mDamping: float = 0.0;
}

/// A bit field that determines which aspects of the simulation to save
EStateRecorderState :: enum u8 {
    None        :: 0;
    Global      :: 1;
    Bodies      :: 2;
    Contacts    :: 4;
    Constraints :: 8;
    All         :: 15;
}

/// User callbacks that allow determining which parts of the simulation should be saved by a StateRecorder
StateRecorderFilter :: struct {
    vtable: *StateRecorderFilter_VTable;
}
StateRecorderFilter_VTable :: struct #type_info_none {
    Destructor:           #type (this: *StateRecorderFilter, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    ShouldSaveBody:       #type (this: *StateRecorderFilter, inBody: *Body) -> bool #cpp_method;

    ShouldSaveConstraint: #type (this: *StateRecorderFilter, inConstraint: *Constraint) -> bool #cpp_method;

    ShouldSaveContact:    #type (this: *StateRecorderFilter, inBody1: *BodyID, inBody2: *BodyID) -> bool #cpp_method;

    ShouldRestoreContact: #type (this: *StateRecorderFilter, inBody1: *BodyID, inBody2: *BodyID) -> bool #cpp_method;
}
StateRecorderFilter_Destructor :: inline (this: *StateRecorderFilter, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

StateRecorderFilter_ShouldSaveBody :: inline (this: *StateRecorderFilter, inBody: *Body) -> bool { return this.vtable.ShouldSaveBody(this, inBody); }

StateRecorderFilter_ShouldSaveConstraint :: inline (this: *StateRecorderFilter, inConstraint: *Constraint) -> bool { return this.vtable.ShouldSaveConstraint(this, inConstraint); }

StateRecorderFilter_ShouldSaveContact :: inline (this: *StateRecorderFilter, inBody1: *BodyID, inBody2: *BodyID) -> bool { return this.vtable.ShouldSaveContact(this, inBody1, inBody2); }

StateRecorderFilter_ShouldRestoreContact :: inline (this: *StateRecorderFilter, inBody1: *BodyID, inBody2: *BodyID) -> bool { return this.vtable.ShouldRestoreContact(this, inBody1, inBody2); }

vtable :: (obj: *StateRecorderFilter) -> *StateRecorderFilter_VTable { return obj.vtable; }


/// Class that records the state of a physics system. Can be used to check if the simulation is deterministic by putting the recorder in validation mode.
/// Can be used to restore the state to an earlier point in time. Note that only the state that is modified by the simulation is saved, configuration settings
/// like body friction or restitution, motion quality etc. are not saved and need to be saved by the user if desired.
StateRecorder :: struct {
    #as using streamin: StreamIn;
    #as using,except(vtable, noncopyable__raw, noncopyable) streamout:      StreamOut;

    IsValidating :: (this: *StateRecorder) -> bool #cpp_method #foreign jolt_release "?IsValidating@StateRecorder@JPH@@QEBA_NXZ";

    IsLastPart :: (this: *StateRecorder) -> bool #cpp_method #foreign jolt_release "?IsLastPart@StateRecorder@JPH@@QEBA_NXZ";

    mIsValidating       := false;
    mIsLastPart         := true;
}

/// Constraint that constrains motion along 1 axis
///
/// @see "Constraints Derivation for Rigid Body Simulation in 3D" - Daniel Chappuis, section 2.1.1
/// (we're not using the approximation of eq 27 but instead add the U term as in eq 55)
///
/// Constraint equation (eq 25):
///
/// \f[C = (p_2 - p_1) \cdot n\f]
///
/// Jacobian (eq 28):
///
/// \f[J = \begin{bmatrix} -n^T & (-(r_1 + u) \times n)^T & n^T & (r_2 \times n)^T \end{bmatrix}\f]
///
/// Used terms (here and below, everything in world space):\n
/// n = constraint axis (normalized).\n
/// p1, p2 = constraint points.\n
/// r1 = p1 - x1.\n
/// r2 = p2 - x2.\n
/// u = x2 + r2 - x1 - r1 = p2 - p1.\n
/// x1, x2 = center of mass for the bodies.\n
/// v = [v1, w1, v2, w2].\n
/// v1, v2 = linear velocity of body 1 and 2.\n
/// w1, w2 = angular velocity of body 1 and 2.\n
/// M = mass matrix, a diagonal matrix of the mass and inertia with diagonal [m1, I1, m2, I2].\n
/// \f$K^{-1} = \left( J M^{-1} J^T \right)^{-1}\f$ = effective mass.\n
/// b = velocity bias.\n
/// \f$\beta\f$ = baumgarte constant.
AxisConstraintPart :: struct {
    /// Internal helper function to calculate the inverse effective mass
    CalculateInverseEffectiveMass :: (this: *AxisConstraintPart, inBody1: *Body, inR1PlusU: Vec3, inBody2: *Body, inR2: Vec3, inWorldSpaceAxis: Vec3) -> float #cpp_method #foreign jolt_release "?CalculateInverseEffectiveMass@AxisConstraintPart@JPH@@AEAAMAEBVBody@2@VVec3@2@011@Z";
    CalculateInverseEffectiveMass :: (this: *AxisConstraintPart, inBody1: Body, inR1PlusU: Vec3, inBody2: Body, inR2: Vec3, inWorldSpaceAxis: Vec3) -> float #no_context {
        return CalculateInverseEffectiveMass(this, *inBody1, inR1PlusU, *inBody2, inR2, inWorldSpaceAxis);
    }

    /// Internal helper function to calculate the inverse effective mass, version that supports mass scaling
    CalculateInverseEffectiveMassWithMassOverride :: (this: *AxisConstraintPart, inBody1: *Body, inInvMass1: float, inInvInertiaScale1: float, inR1PlusU: Vec3, inBody2: *Body, inInvMass2: float, inInvInertiaScale2: float, inR2: Vec3, inWorldSpaceAxis: Vec3) -> float #cpp_method #foreign jolt_release "?CalculateInverseEffectiveMassWithMassOverride@AxisConstraintPart@JPH@@AEAAMAEBVBody@2@MMVVec3@2@0MM11@Z";
    CalculateInverseEffectiveMassWithMassOverride :: (this: *AxisConstraintPart, inBody1: Body, inInvMass1: float, inInvInertiaScale1: float, inR1PlusU: Vec3, inBody2: Body, inInvMass2: float, inInvInertiaScale2: float, inR2: Vec3, inWorldSpaceAxis: Vec3) -> float #no_context {
        return CalculateInverseEffectiveMassWithMassOverride(this, *inBody1, inInvMass1, inInvInertiaScale1, inR1PlusU, *inBody2, inInvMass2, inInvInertiaScale2, inR2, inWorldSpaceAxis);
    }

    /// Calculate properties used during the functions below
    /// @param inBody1 The first body that this constraint is attached to
    /// @param inBody2 The second body that this constraint is attached to
    /// @param inR1PlusU See equations above (r1 + u)
    /// @param inR2 See equations above (r2)
    /// @param inWorldSpaceAxis Axis along which the constraint acts (normalized, pointing from body 1 to 2)
    /// @param inBias Bias term (b) for the constraint impulse: lambda = J v + b
    CalculateConstraintProperties :: (this: *AxisConstraintPart, inBody1: *Body, inR1PlusU: Vec3, inBody2: *Body, inR2: Vec3, inWorldSpaceAxis: Vec3, inBias: float = 0.0) -> void #cpp_method #foreign jolt_release "?CalculateConstraintProperties@AxisConstraintPart@JPH@@QEAAXAEBVBody@2@VVec3@2@011M@Z";
    CalculateConstraintProperties :: (this: *AxisConstraintPart, inBody1: Body, inR1PlusU: Vec3, inBody2: Body, inR2: Vec3, inWorldSpaceAxis: Vec3, inBias: float = 0.0) #no_context {
        CalculateConstraintProperties(this, *inBody1, inR1PlusU, *inBody2, inR2, inWorldSpaceAxis, inBias);
    }

    /// Calculate properties used during the functions below, version that supports mass scaling
    /// @param inBody1 The first body that this constraint is attached to
    /// @param inBody2 The second body that this constraint is attached to
    /// @param inInvMass1 The inverse mass of body 1 (only used when body 1 is dynamic)
    /// @param inInvMass2 The inverse mass of body 2 (only used when body 2 is dynamic)
    /// @param inInvInertiaScale1 Scale factor for the inverse inertia of body 1
    /// @param inInvInertiaScale2 Scale factor for the inverse inertia of body 2
    /// @param inR1PlusU See equations above (r1 + u)
    /// @param inR2 See equations above (r2)
    /// @param inWorldSpaceAxis Axis along which the constraint acts (normalized, pointing from body 1 to 2)
    /// @param inBias Bias term (b) for the constraint impulse: lambda = J v + b
    CalculateConstraintPropertiesWithMassOverride :: (this: *AxisConstraintPart, inBody1: *Body, inInvMass1: float, inInvInertiaScale1: float, inR1PlusU: Vec3, inBody2: *Body, inInvMass2: float, inInvInertiaScale2: float, inR2: Vec3, inWorldSpaceAxis: Vec3, inBias: float = 0.0) -> void #cpp_method #foreign jolt_release "?CalculateConstraintPropertiesWithMassOverride@AxisConstraintPart@JPH@@QEAAXAEBVBody@2@MMVVec3@2@0MM11M@Z";
    CalculateConstraintPropertiesWithMassOverride :: (this: *AxisConstraintPart, inBody1: Body, inInvMass1: float, inInvInertiaScale1: float, inR1PlusU: Vec3, inBody2: Body, inInvMass2: float, inInvInertiaScale2: float, inR2: Vec3, inWorldSpaceAxis: Vec3, inBias: float = 0.0) #no_context {
        CalculateConstraintPropertiesWithMassOverride(this, *inBody1, inInvMass1, inInvInertiaScale1, inR1PlusU, *inBody2, inInvMass2, inInvInertiaScale2, inR2, inWorldSpaceAxis, inBias);
    }

    /// Calculate properties used during the functions below
    /// @param inDeltaTime Time step
    /// @param inBody1 The first body that this constraint is attached to
    /// @param inBody2 The second body that this constraint is attached to
    /// @param inR1PlusU See equations above (r1 + u)
    /// @param inR2 See equations above (r2)
    /// @param inWorldSpaceAxis Axis along which the constraint acts (normalized, pointing from body 1 to 2)
    /// @param inBias Bias term (b) for the constraint impulse: lambda = J v + b
    ///	@param inC Value of the constraint equation (C).
    ///	@param inStiffness Spring stiffness k.
    ///	@param inDamping Spring damping coefficient c.
    CalculateConstraintPropertiesWithStiffnessAndDamping :: (this: *AxisConstraintPart, inDeltaTime: float, inBody1: *Body, inR1PlusU: Vec3, inBody2: *Body, inR2: Vec3, inWorldSpaceAxis: Vec3, inBias: float, inC: float, inStiffness: float, inDamping: float) -> void #cpp_method #foreign jolt_release "?CalculateConstraintPropertiesWithStiffnessAndDamping@AxisConstraintPart@JPH@@QEAAXMAEBVBody@2@VVec3@2@011MMMM@Z";
    CalculateConstraintPropertiesWithStiffnessAndDamping :: (this: *AxisConstraintPart, inDeltaTime: float, inBody1: Body, inR1PlusU: Vec3, inBody2: Body, inR2: Vec3, inWorldSpaceAxis: Vec3, inBias: float, inC: float, inStiffness: float, inDamping: float) #no_context {
        CalculateConstraintPropertiesWithStiffnessAndDamping(this, inDeltaTime, *inBody1, inR1PlusU, *inBody2, inR2, inWorldSpaceAxis, inBias, inC, inStiffness, inDamping);
    }

    /// Selects one of the above functions based on the spring settings
    CalculateConstraintPropertiesWithSettings :: (this: *AxisConstraintPart, inDeltaTime: float, inBody1: *Body, inR1PlusU: Vec3, inBody2: *Body, inR2: Vec3, inWorldSpaceAxis: Vec3, inBias: float, inC: float, inSpringSettings: *SpringSettings) -> void #cpp_method #foreign jolt_release "?CalculateConstraintPropertiesWithSettings@AxisConstraintPart@JPH@@QEAAXMAEBVBody@2@VVec3@2@011MMAEBVSpringSettings@2@@Z";
    CalculateConstraintPropertiesWithSettings :: (this: *AxisConstraintPart, inDeltaTime: float, inBody1: Body, inR1PlusU: Vec3, inBody2: Body, inR2: Vec3, inWorldSpaceAxis: Vec3, inBias: float, inC: float, inSpringSettings: SpringSettings) #no_context {
        CalculateConstraintPropertiesWithSettings(this, inDeltaTime, *inBody1, inR1PlusU, *inBody2, inR2, inWorldSpaceAxis, inBias, inC, *inSpringSettings);
    }

    /// Deactivate this constraint
    Deactivate :: (this: *AxisConstraintPart) -> void #cpp_method #foreign jolt_release "?Deactivate@AxisConstraintPart@JPH@@QEAAXXZ";

    /// Check if constraint is active
    IsActive :: (this: *AxisConstraintPart) -> bool #cpp_method #foreign jolt_release "?IsActive@AxisConstraintPart@JPH@@QEBA_NXZ";

    /// Must be called from the WarmStartVelocityConstraint call to apply the previous frame's impulses
    /// @param ioBody1 The first body that this constraint is attached to
    /// @param ioBody2 The second body that this constraint is attached to
    /// @param inWorldSpaceAxis Axis along which the constraint acts (normalized)
    /// @param inWarmStartImpulseRatio Ratio of new step to old time step (dt_new / dt_old) for scaling the lagrange multiplier of the previous frame
    WarmStart :: (this: *AxisConstraintPart, ioBody1: *Body, ioBody2: *Body, inWorldSpaceAxis: Vec3, inWarmStartImpulseRatio: float) -> void #cpp_method #foreign jolt_release "?WarmStart@AxisConstraintPart@JPH@@QEAAXAEAVBody@2@0VVec3@2@M@Z";

    /// Iteratively update the velocity constraint. Makes sure d/dt C(...) = 0, where C is the constraint equation.
    /// @param ioBody1 The first body that this constraint is attached to
    /// @param ioBody2 The second body that this constraint is attached to
    /// @param inWorldSpaceAxis Axis along which the constraint acts (normalized)
    /// @param inMinLambda Minimum value of constraint impulse to apply (N s)
    /// @param inMaxLambda Maximum value of constraint impulse to apply (N s)
    SolveVelocityConstraint :: (this: *AxisConstraintPart, ioBody1: *Body, ioBody2: *Body, inWorldSpaceAxis: Vec3, inMinLambda: float, inMaxLambda: float) -> bool #cpp_method #foreign jolt_release "?SolveVelocityConstraint@AxisConstraintPart@JPH@@QEAA_NAEAVBody@2@0VVec3@2@MM@Z";

    /// Iteratively update the velocity constraint. Makes sure d/dt C(...) = 0, where C is the constraint equation.
    /// @param ioBody1 The first body that this constraint is attached to
    /// @param ioBody2 The second body that this constraint is attached to
    /// @param inInvMass1 The inverse mass of body 1 (only used when body 1 is dynamic)
    /// @param inInvMass2 The inverse mass of body 2 (only used when body 2 is dynamic)
    /// @param inWorldSpaceAxis Axis along which the constraint acts (normalized)
    /// @param inMinLambda Minimum value of constraint impulse to apply (N s)
    /// @param inMaxLambda Maximum value of constraint impulse to apply (N s)
    SolveVelocityConstraintWithMassOverride :: (this: *AxisConstraintPart, ioBody1: *Body, inInvMass1: float, ioBody2: *Body, inInvMass2: float, inWorldSpaceAxis: Vec3, inMinLambda: float, inMaxLambda: float) -> bool #cpp_method #foreign jolt_release "?SolveVelocityConstraintWithMassOverride@AxisConstraintPart@JPH@@QEAA_NAEAVBody@2@M0MVVec3@2@MM@Z";

    /// Iteratively update the position constraint. Makes sure C(...) = 0.
    /// @param ioBody1 The first body that this constraint is attached to
    /// @param ioBody2 The second body that this constraint is attached to
    /// @param inWorldSpaceAxis Axis along which the constraint acts (normalized)
    /// @param inC Value of the constraint equation (C)
    /// @param inBaumgarte Baumgarte constant (fraction of the error to correct)
    SolvePositionConstraint :: (this: *AxisConstraintPart, ioBody1: *Body, ioBody2: *Body, inWorldSpaceAxis: Vec3, inC: float, inBaumgarte: float) -> bool #cpp_method #foreign jolt_release "?SolvePositionConstraint@AxisConstraintPart@JPH@@QEBA_NAEAVBody@2@0VVec3@2@MM@Z";

    /// Iteratively update the position constraint. Makes sure C(...) = 0.
    /// @param ioBody1 The first body that this constraint is attached to
    /// @param ioBody2 The second body that this constraint is attached to
    /// @param inInvMass1 The inverse mass of body 1 (only used when body 1 is dynamic)
    /// @param inInvMass2 The inverse mass of body 2 (only used when body 2 is dynamic)
    /// @param inWorldSpaceAxis Axis along which the constraint acts (normalized)
    /// @param inC Value of the constraint equation (C)
    /// @param inBaumgarte Baumgarte constant (fraction of the error to correct)
    SolvePositionConstraintWithMassOverride :: (this: *AxisConstraintPart, ioBody1: *Body, inInvMass1: float, ioBody2: *Body, inInvMass2: float, inWorldSpaceAxis: Vec3, inC: float, inBaumgarte: float) -> bool #cpp_method #foreign jolt_release "?SolvePositionConstraintWithMassOverride@AxisConstraintPart@JPH@@QEBA_NAEAVBody@2@M0MVVec3@2@MM@Z";

    /// Override total lagrange multiplier, can be used to set the initial value for warm starting
    SetTotalLambda :: (this: *AxisConstraintPart, inLambda: float) -> void #cpp_method #foreign jolt_release "?SetTotalLambda@AxisConstraintPart@JPH@@QEAAXM@Z";

    /// Return lagrange multiplier
    GetTotalLambda :: (this: *AxisConstraintPart) -> float #cpp_method #foreign jolt_release "?GetTotalLambda@AxisConstraintPart@JPH@@QEBAMXZ";

    /// Save state of this constraint part
    SaveState :: (this: *AxisConstraintPart, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?SaveState@AxisConstraintPart@JPH@@QEBAXAEAVStateRecorder@2@@Z";

    /// Restore state of this constraint part
    RestoreState :: (this: *AxisConstraintPart, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?RestoreState@AxisConstraintPart@JPH@@QEAAXAEAVStateRecorder@2@@Z";

    mR1PlusUxAxis:       Float3;
    mR2xAxis:            Float3;
    mInvI1_R1PlusUxAxis: Float3;
    mInvI2_R2xAxis:      Float3;
    mEffectiveMass:      float = 0.0;
    mSpringPart:         SpringPart;
    mTotalLambda:        float = 0.0;
}

/// Templatized vector class
Vector :: struct(Rows: u32) {
    mF32: [Rows] float;
}

/// Templatized matrix class
Matrix :: struct(Rows: u32, Cols: u32) {
    using,except(Rows, Cols) matrix__raw:            Matrix__RAW(Rows, Cols);
    #if size_of(Matrix__RAW(Rows, Cols)) == 0 {
        __empty_struct_padding: u8; // C++ makes empty structs have length 1
    }
}
// Matrix without padding. Needed to generate a C++-equivalent struct layout when "inheriting" from Matrix
Matrix__RAW :: struct(Rows: u32, Cols: u32) {}

/// Specialization of SetInversed for 2x2 matrix
SetInversed :: (this: *void /* Unknown type */, inM: *[2] Matrix(2, 2)) -> bool #cpp_method #foreign jolt_release "?SetInversed@?$Matrix@$01$01@JPH@@QEAA_NAEBV12@@Z";
SetInversed :: (this: *void /* Unknown type */, inM: [2] Matrix(2, 2)) -> bool #no_context {
    return SetInversed(this, *inM);
}

/**
Constrains movement on 2 axis

@see "Constraints Derivation for Rigid Body Simulation in 3D" - Daniel Chappuis, section 2.3.1

Constraint equation (eq 51):

\f[C = \begin{bmatrix} (p_2 - p_1) \cdot n_1 \\ (p_2 - p_1) \cdot n_2\end{bmatrix}\f]

Jacobian (transposed) (eq 55):

\f[J^T = \begin{bmatrix}
-n_1					& -n_2					\\
-(r_1 + u) \times n_1	& -(r_1 + u) \times n_2	\\
n_1						& n_2					\\
r_2 \times n_1			& r_2 \times n_2
\end{bmatrix}\f]

Used terms (here and below, everything in world space):\n
n1, n2 = constraint axis (normalized).\n
p1, p2 = constraint points.\n
r1 = p1 - x1.\n
r2 = p2 - x2.\n
u = x2 + r2 - x1 - r1 = p2 - p1.\n
x1, x2 = center of mass for the bodies.\n
v = [v1, w1, v2, w2].\n
v1, v2 = linear velocity of body 1 and 2.\n
w1, w2 = angular velocity of body 1 and 2.\n
M = mass matrix, a diagonal matrix of the mass and inertia with diagonal [m1, I1, m2, I2].\n
\f$K^{-1} = \left( J M^{-1} J^T \right)^{-1}\f$ = effective mass.\n
b = velocity bias.\n
\f$\beta\f$ = baumgarte constant.
**/
DualAxisConstraintPart :: struct {
    Mat22 :: Matrix(2, 2);

    /// Internal helper function to update velocities of bodies after Lagrange multiplier is calculated
    ApplyVelocityStep :: (this: *DualAxisConstraintPart, ioBody1: *Body, ioBody2: *Body, inN1: Vec3, inN2: Vec3, inLambda: *Vec2) -> bool #cpp_method #foreign jolt_release "?ApplyVelocityStep@DualAxisConstraintPart@JPH@@AEBA_NAEAVBody@2@0VVec3@2@1AEBV?$Vector@$01@2@@Z";
    ApplyVelocityStep :: (this: *DualAxisConstraintPart, ioBody1: *Body, ioBody2: *Body, inN1: Vec3, inN2: Vec3, inLambda: Vec2) -> bool #no_context {
        return ApplyVelocityStep(this, ioBody1, ioBody2, inN1, inN2, *inLambda);
    }

    /// Internal helper function to calculate the lagrange multiplier
    CalculateLagrangeMultiplier :: (this: *DualAxisConstraintPart, inBody1: *Body, inBody2: *Body, inN1: Vec3, inN2: Vec3, outLambda: *Vec2) -> void #cpp_method #foreign jolt_release "?CalculateLagrangeMultiplier@DualAxisConstraintPart@JPH@@AEBAXAEBVBody@2@0VVec3@2@1AEAV?$Vector@$01@2@@Z";
    CalculateLagrangeMultiplier :: (this: *DualAxisConstraintPart, inBody1: Body, inBody2: Body, inN1: Vec3, inN2: Vec3, outLambda: *Vec2) #no_context {
        CalculateLagrangeMultiplier(this, *inBody1, *inBody2, inN1, inN2, outLambda);
    }

    /// Calculate properties used during the functions below
    /// All input vectors are in world space
    CalculateConstraintProperties :: (this: *DualAxisConstraintPart, inBody1: *Body, inRotation1: *Mat44, inR1PlusU: Vec3, inBody2: *Body, inRotation2: *Mat44, inR2: Vec3, inN1: Vec3, inN2: Vec3) -> void #cpp_method #foreign jolt_release "?CalculateConstraintProperties@DualAxisConstraintPart@JPH@@QEAAXAEBVBody@2@AEBVMat44@2@VVec3@2@01222@Z";
    CalculateConstraintProperties :: (this: *DualAxisConstraintPart, inBody1: Body, inRotation1: *Mat44, inR1PlusU: Vec3, inBody2: Body, inRotation2: *Mat44, inR2: Vec3, inN1: Vec3, inN2: Vec3) #no_context {
        CalculateConstraintProperties(this, *inBody1, inRotation1, inR1PlusU, *inBody2, inRotation2, inR2, inN1, inN2);
    }

    /// Deactivate this constraint
    Deactivate :: (this: *DualAxisConstraintPart) -> void #cpp_method #foreign jolt_release "?Deactivate@DualAxisConstraintPart@JPH@@QEAAXXZ";

    /// Must be called from the WarmStartVelocityConstraint call to apply the previous frame's impulses
    /// All input vectors are in world space
    WarmStart :: (this: *DualAxisConstraintPart, ioBody1: *Body, ioBody2: *Body, inN1: Vec3, inN2: Vec3, inWarmStartImpulseRatio: float) -> void #cpp_method #foreign jolt_release "?WarmStart@DualAxisConstraintPart@JPH@@QEAAXAEAVBody@2@0VVec3@2@1M@Z";

    /// Iteratively update the velocity constraint. Makes sure d/dt C(...) = 0, where C is the constraint equation.
    /// All input vectors are in world space
    SolveVelocityConstraint :: (this: *DualAxisConstraintPart, ioBody1: *Body, ioBody2: *Body, inN1: Vec3, inN2: Vec3) -> bool #cpp_method #foreign jolt_release "?SolveVelocityConstraint@DualAxisConstraintPart@JPH@@QEAA_NAEAVBody@2@0VVec3@2@1@Z";

    /// Iteratively update the position constraint. Makes sure C(...) = 0.
    /// All input vectors are in world space
    SolvePositionConstraint :: (this: *DualAxisConstraintPart, ioBody1: *Body, ioBody2: *Body, inU: Vec3, inN1: Vec3, inN2: Vec3, inBaumgarte: float) -> bool #cpp_method #foreign jolt_release "?SolvePositionConstraint@DualAxisConstraintPart@JPH@@QEBA_NAEAVBody@2@0VVec3@2@11M@Z";

    /// Save state of this constraint part
    SaveState :: (this: *DualAxisConstraintPart, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?SaveState@DualAxisConstraintPart@JPH@@QEBAXAEAVStateRecorder@2@@Z";

    /// Restore state of this constraint part
    RestoreState :: (this: *DualAxisConstraintPart, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?RestoreState@DualAxisConstraintPart@JPH@@QEAAXAEAVStateRecorder@2@@Z";

    mR1PlusUxN1:       Vec3;
    mR1PlusUxN2:       Vec3;
    mR2xN1:            Vec3;
    mR2xN2:            Vec3;
    mInvI1_R1PlusUxN1: Vec3;
    mInvI1_R1PlusUxN2: Vec3;
    mInvI2_R2xN1:      Vec3;
    mInvI2_R2xN2:      Vec3;
    mEffectiveMass:    Mat22;
    mTotalLambda:      Vec2;
}

/// A contact constraint manager manages all contacts between two bodies
///
/// WARNING: This class is an internal part of PhysicsSystem, it has no functions that can be called by users of the library.
ContactConstraintManager :: struct {
    using noncopyable__raw:      NonCopyable__RAW;

    /// Constructor
    Constructor :: (this: *ContactConstraintManager, inPhysicsSettings: *PhysicsSettings) -> void #cpp_method #foreign jolt_release "??0ContactConstraintManager@JPH@@QEAA@AEBUPhysicsSettings@1@@Z";
    Constructor :: (this: *ContactConstraintManager, inPhysicsSettings: PhysicsSettings) #no_context {
        Constructor(this, *inPhysicsSettings);
    }
    Destructor :: (this: *ContactConstraintManager) -> void #cpp_method #foreign jolt_release "??1ContactConstraintManager@JPH@@QEAA@XZ";

    /// Initialize the system.
    /// @param inMaxBodyPairs Maximum amount of body pairs to process (anything else will fall through the world), this number should generally be much higher than the max amount of contact points as there will be lots of bodies close that are not actually touching
    /// @param inMaxContactConstraints Maximum amount of contact constraints to process (anything else will fall through the world)
    Init :: (this: *ContactConstraintManager, inMaxBodyPairs: u32, inMaxContactConstraints: u32) -> void #cpp_method #foreign jolt_release "?Init@ContactConstraintManager@JPH@@QEAAXII@Z";

    /// Callback function to combine the restitution or friction of two bodies
    /// Note that when merging manifolds (when PhysicsSettings::mUseManifoldReduction is true) you will only get a callback for the merged manifold.
    /// It is not possible in that case to get all sub shape ID pairs that were colliding, you'll get the first encountered pair.
    CombineFunction :: #type (inBody1: *Body, inSubShapeID1: *SubShapeID, inBody2: *Body, inSubShapeID2: *SubShapeID) -> float #c_call;

    GetCombineFriction :: (this: *ContactConstraintManager) -> CombineFunction #cpp_method #foreign jolt_release "?GetCombineFriction@ContactConstraintManager@JPH@@QEBAP6AMAEBVBody@2@AEBVSubShapeID@2@01@ZXZ";

    GetCombineRestitution :: (this: *ContactConstraintManager) -> CombineFunction #cpp_method #foreign jolt_release "?GetCombineRestitution@ContactConstraintManager@JPH@@QEBAP6AMAEBVBody@2@AEBVSubShapeID@2@01@ZXZ";

    /// Get the max number of contact constraints that are allowed
    GetMaxConstraints :: (this: *ContactConstraintManager) -> u32 #cpp_method #foreign jolt_release "?GetMaxConstraints@ContactConstraintManager@JPH@@QEBAIXZ";

    /// Check with the listener if inBody1 and inBody2 could collide, returns false if not
    ValidateContactPoint :: (this: *ContactConstraintManager, inBody1: *Body, inBody2: *Body, inBaseOffset: Vector3, inCollisionResult: *CollideShapeResult) -> ValidateResult #cpp_method #foreign jolt_release "?ValidateContactPoint@ContactConstraintManager@JPH@@QEBA?AW4ValidateResult@2@AEBVBody@2@0VVec3@2@AEBVCollideShapeResult@2@@Z";
    ValidateContactPoint :: (this: *ContactConstraintManager, inBody1: Body, inBody2: Body, inBaseOffset: Vector3, inCollisionResult: CollideShapeResult) -> ValidateResult #no_context {
        return ValidateContactPoint(this, *inBody1, *inBody2, inBaseOffset, *inCollisionResult);
    }

    /// Sets up the constraint buffer. Should be called before starting collision detection.
    PrepareConstraintBuffer :: (this: *ContactConstraintManager, inContext: *PhysicsUpdateContext) -> void #cpp_method #foreign jolt_release "?PrepareConstraintBuffer@ContactConstraintManager@JPH@@QEAAXPEAVPhysicsUpdateContext@2@@Z";

    /// Max 4 contact points are needed for a stable manifold
    MaxContactPoints:            s32 : 4;

    /// Contacts are allocated in a lock free hash map
    ContactAllocator :: struct {
        #as using lfhmallocatorcontext: LFHMAllocatorContext;

        mNumBodyPairs:                  u32 = 0; ///< Total number of body pairs added using this allocator
        mNumManifolds:                  u32 = 0; ///< Total number of manifolds added using this allocator
        mErrors:                        EPhysicsUpdateError = .None; ///< Errors reported on this allocator
    }

    /// Get a new allocator context for storing contacts. Note that you should call this once and then add multiple contacts using the context.
    GetContactAllocator :: (this: *ContactConstraintManager) -> ContactAllocator #cpp_method #foreign jolt_release "?GetContactAllocator@ContactConstraintManager@JPH@@QEAA?AVContactAllocator@12@XZ";

    /// Check if the contact points from the previous frame are reusable and if so copy them.
    /// When the cache was usable and the pair has been handled: outPairHandled = true.
    /// When a contact constraint was produced: outConstraintCreated = true.
    GetContactsFromCache :: (this: *ContactConstraintManager, ioContactAllocator: *ContactAllocator, inBody1: *Body, inBody2: *Body, outPairHandled: *bool, outConstraintCreated: *bool) -> void #cpp_method #foreign jolt_release "?GetContactsFromCache@ContactConstraintManager@JPH@@QEAAXAEAVContactAllocator@12@AEAVBody@2@1AEA_N2@Z";

    /// Handle used to keep track of the current body pair
    BodyPairHandle :: *void;

    /// Create a handle for a colliding body pair so that contact constraints can be added between them.
    /// Needs to be called once per body pair per frame before calling AddContactConstraint.
    AddBodyPair :: (this: *ContactConstraintManager, ioContactAllocator: *ContactAllocator, inBody1: *Body, inBody2: *Body) -> BodyPairHandle #cpp_method #foreign jolt_release "?AddBodyPair@ContactConstraintManager@JPH@@QEAAPEAXAEAVContactAllocator@12@AEBVBody@2@1@Z";
    AddBodyPair :: (this: *ContactConstraintManager, ioContactAllocator: *ContactAllocator, inBody1: Body, inBody2: Body) -> BodyPairHandle #no_context {
        return AddBodyPair(this, ioContactAllocator, *inBody1, *inBody2);
    }

    /// Add a contact constraint for this frame.
    ///
    /// @param ioContactAllocator The allocator that reserves memory for the contacts
    /// @param inBodyPair The handle for the contact cache for this body pair
    /// @param inBody1 The first body that is colliding
    /// @param inBody2 The second body that is colliding
    /// @param inManifold The manifold that describes the collision
    /// @return true if a contact constraint was created (can be false in the case of a sensor)
    ///
    /// This is using the approach described in 'Modeling and Solving Constraints' by Erin Catto presented at GDC 2009 (and later years with slight modifications).
    /// We're using the formulas from slide 50 - 53 combined.
    ///
    /// Euler velocity integration:
    ///
    /// v1' = v1 + M^-1 P
    ///
    /// Impulse:
    ///
    /// P = J^T lambda
    ///
    /// Constraint force:
    ///
    /// lambda = -K^-1 J v1
    ///
    /// Inverse effective mass:
    ///
    /// K = J M^-1 J^T
    ///
    /// Constraint equation (limits movement in 1 axis):
    ///
    /// C = (p2 - p1) . n
    ///
    /// Jacobian (for position constraint)
    ///
    /// J = [-n, -r1 x n, n, r2 x n]
    ///
    /// n = contact normal (pointing away from body 1).
    /// p1, p2 = positions of collision on body 1 and 2.
    /// r1, r2 = contact point relative to center of mass of body 1 and body 2 (r1 = p1 - x1, r2 = p2 - x2).
    /// v1, v2 = (linear velocity, angular velocity): 6 vectors containing linear and angular velocity for body 1 and 2.
    /// M = mass matrix, a diagonal matrix of the mass and inertia with diagonal [m1, I1, m2, I2].
    AddContactConstraint :: (this: *ContactConstraintManager, ioContactAllocator: *ContactAllocator, inBodyPair: BodyPairHandle, inBody1: *Body, inBody2: *Body, inManifold: *ContactManifold) -> bool #cpp_method #foreign jolt_release "?AddContactConstraint@ContactConstraintManager@JPH@@QEAA_NAEAVContactAllocator@12@PEAXAEAVBody@2@2AEBVContactManifold@2@@Z";
    AddContactConstraint :: (this: *ContactConstraintManager, ioContactAllocator: *ContactAllocator, inBodyPair: BodyPairHandle, inBody1: *Body, inBody2: *Body, inManifold: ContactManifold) -> bool #no_context {
        return AddContactConstraint(this, ioContactAllocator, inBodyPair, inBody1, inBody2, *inManifold);
    }

    /// Finalizes the contact cache, the contact cache that was generated during the calls to AddContactConstraint in this update
    /// will be used from now on to read from. After finalizing the contact cache, the contact removed callbacks will be called.
    /// inExpectedNumBodyPairs / inExpectedNumManifolds are the amount of body pairs / manifolds found in the previous step and is
    /// used to determine the amount of buckets the contact cache hash map will use in the next update.
    FinalizeContactCacheAndCallContactPointRemovedCallbacks :: (this: *ContactConstraintManager, inExpectedNumBodyPairs: u32, inExpectedNumManifolds: u32) -> void #cpp_method #foreign jolt_release "?FinalizeContactCacheAndCallContactPointRemovedCallbacks@ContactConstraintManager@JPH@@QEAAXII@Z";

    /// Check if 2 bodies were in contact during the last simulation step. Since contacts are only detected between active bodies, at least one of the bodies must be active.
    /// Uses the read collision cache to determine if 2 bodies are in contact.
    WereBodiesInContact :: (this: *ContactConstraintManager, inBody1ID: *BodyID, inBody2ID: *BodyID) -> bool #cpp_method #foreign jolt_release "?WereBodiesInContact@ContactConstraintManager@JPH@@QEBA_NAEBVBodyID@2@0@Z";
    WereBodiesInContact :: (this: *ContactConstraintManager, inBody1ID: BodyID, inBody2ID: BodyID) -> bool #no_context {
        return WereBodiesInContact(this, *inBody1ID, *inBody2ID);
    }

    /// Get the number of contact constraints that were found
    GetNumConstraints :: (this: *ContactConstraintManager) -> u32 #cpp_method #foreign jolt_release "?GetNumConstraints@ContactConstraintManager@JPH@@QEBAIXZ";

    /// Sort contact constraints deterministically
    SortContacts :: (this: *ContactConstraintManager, inConstraintIdxBegin: *u32, inConstraintIdxEnd: *u32) -> void #cpp_method #foreign jolt_release "?SortContacts@ContactConstraintManager@JPH@@QEBAXPEAI0@Z";

    /// Get the affected bodies for a given constraint
    GetAffectedBodies :: (this: *ContactConstraintManager, inConstraintIdx: u32, outBody1: **Body, outBody2: **Body) -> void #cpp_method #foreign jolt_release "?GetAffectedBodies@ContactConstraintManager@JPH@@QEBAXIAEAPEBVBody@2@0@Z";

    /// Solve velocity constraints, when almost nothing changes this should only apply very small impulses
    /// since we're warm starting with the total impulse applied in the last frame above.
    ///
    /// Friction wise we're using the Coulomb friction model which says that:
    ///
    /// |F_T| <= mu |F_N|
    ///
    /// Where F_T is the tangential force, F_N is the normal force and mu is the friction coefficient
    ///
    /// In impulse terms this becomes:
    ///
    /// |lambda_T| <= mu |lambda_N|
    ///
    /// And the constraint that needs to be applied is exactly the same as a non penetration constraint
    /// except that we use a tangent instead of a normal. The tangent should point in the direction of the
    /// tangential velocity of the point:
    ///
    /// J = [-T, -r1 x T, T, r2 x T]
    ///
    /// Where T is the tangent.
    ///
    /// See slide 42 and 43.
    ///
    /// Restitution is implemented as a velocity bias (see slide 41):
    ///
    /// b = e v_n^-
    ///
    /// e = the restitution coefficient, v_n^- is the normal velocity prior to the collision
    ///
    /// Restitution is only applied when v_n^- is large enough and the points are moving towards collision
    SolveVelocityConstraints :: (this: *ContactConstraintManager, inConstraintIdxBegin: *u32, inConstraintIdxEnd: *u32) -> bool #cpp_method #foreign jolt_release "?SolveVelocityConstraints@ContactConstraintManager@JPH@@QEAA_NPEBI0@Z";

    /// Save back the lambdas to the contact cache for the next warm start
    StoreAppliedImpulses :: (this: *ContactConstraintManager, inConstraintIdxBegin: *u32, inConstraintIdxEnd: *u32) -> void #cpp_method #foreign jolt_release "?StoreAppliedImpulses@ContactConstraintManager@JPH@@QEBAXPEBI0@Z";

    /// Solve position constraints.
    /// This is using the approach described in 'Modeling and Solving Constraints' by Erin Catto presented at GDC 2007.
    /// On slide 78 it is suggested to split up the Baumgarte stabilization for positional drift so that it does not
    /// actually add to the momentum. We combine an Euler velocity integrate + a position integrate and then discard the velocity
    /// change.
    ///
    /// Constraint force:
    ///
    /// lambda = -K^-1 b
    ///
    /// Baumgarte stabilization:
    ///
    /// b = beta / dt C
    ///
    /// beta = baumgarte stabilization factor.
    /// dt = delta time.
    SolvePositionConstraints :: (this: *ContactConstraintManager, inConstraintIdxBegin: *u32, inConstraintIdxEnd: *u32) -> bool #cpp_method #foreign jolt_release "?SolvePositionConstraints@ContactConstraintManager@JPH@@QEAA_NPEBI0@Z";

    /// Recycle the constraint buffer. Should be called between collision simulation steps.
    RecycleConstraintBuffer :: (this: *ContactConstraintManager) -> void #cpp_method #foreign jolt_release "?RecycleConstraintBuffer@ContactConstraintManager@JPH@@QEAAXXZ";

    /// Terminate the constraint buffer. Should be called after simulation ends.
    FinishConstraintBuffer :: (this: *ContactConstraintManager) -> void #cpp_method #foreign jolt_release "?FinishConstraintBuffer@ContactConstraintManager@JPH@@QEAAXXZ";

    /// Called by continuous collision detection to notify the contact listener that a contact was added
    /// @param ioContactAllocator The allocator that reserves memory for the contacts
    /// @param inBody1 The first body that is colliding
    /// @param inBody2 The second body that is colliding
    /// @param inManifold The manifold that describes the collision
    /// @param outSettings The calculated contact settings (may be overridden by the contact listener)
    OnCCDContactAdded :: (this: *ContactConstraintManager, ioContactAllocator: *ContactAllocator, inBody1: *Body, inBody2: *Body, inManifold: *ContactManifold, outSettings: *ContactSettings) -> void #cpp_method #foreign jolt_release "?OnCCDContactAdded@ContactConstraintManager@JPH@@QEAAXAEAVContactAllocator@12@AEBVBody@2@1AEBVContactManifold@2@AEAVContactSettings@2@@Z";
    OnCCDContactAdded :: (this: *ContactConstraintManager, ioContactAllocator: *ContactAllocator, inBody1: Body, inBody2: Body, inManifold: ContactManifold, outSettings: *ContactSettings) #no_context {
        OnCCDContactAdded(this, ioContactAllocator, *inBody1, *inBody2, *inManifold, outSettings);
    }

    /// Saving state for replay
    SaveState :: (this: *ContactConstraintManager, inStream: *StateRecorder, inFilter: *StateRecorderFilter) -> void #cpp_method #foreign jolt_release "?SaveState@ContactConstraintManager@JPH@@QEBAXAEAVStateRecorder@2@PEBVStateRecorderFilter@2@@Z";

    /// Restoring state for replay. Returns false when failed.
    RestoreState :: (this: *ContactConstraintManager, inStream: *StateRecorder, inFilter: *StateRecorderFilter) -> bool #cpp_method #foreign jolt_release "?RestoreState@ContactConstraintManager@JPH@@QEAA_NAEAVStateRecorder@2@PEBVStateRecorderFilter@2@@Z";

    /// Local space contact point, used for caching impulses
    CachedContactPoint :: struct {
        /// Saving / restoring state for replay
        SaveState :: (this: *CachedContactPoint, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?SaveState@CachedContactPoint@ContactConstraintManager@JPH@@QEBAXAEAVStateRecorder@3@@Z";
        RestoreState :: (this: *CachedContactPoint, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?RestoreState@CachedContactPoint@ContactConstraintManager@JPH@@QEAAXAEAVStateRecorder@3@@Z";

        /// Local space positions on body 1 and 2.
        /// Note: these values are read through sLoadFloat3Unsafe.
        mPosition1:            Float3;
        mPosition2:            Float3;

        /// Total applied impulse during the last update that it was used
        mNonPenetrationLambda: float;
        mFrictionLambda:       Vector(2) = 2;
    }

    /// A single cached manifold
    CachedManifold :: struct {
        /// Calculate size in bytes needed beyond the size of the class to store inNumContactPoints
        sGetRequiredExtraSize :: (inNumContactPoints: s32) -> s32 #foreign jolt_release "?sGetRequiredExtraSize@CachedManifold@ContactConstraintManager@JPH@@SAHH@Z";

        /// Calculate total class size needed for storing inNumContactPoints
        sGetRequiredTotalSize :: (inNumContactPoints: s32) -> s32 #foreign jolt_release "?sGetRequiredTotalSize@CachedManifold@ContactConstraintManager@JPH@@SAHH@Z";

        /// Saving / restoring state for replay
        SaveState :: (this: *CachedManifold, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?SaveState@CachedManifold@ContactConstraintManager@JPH@@QEBAXAEAVStateRecorder@3@@Z";
        RestoreState :: (this: *CachedManifold, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?RestoreState@CachedManifold@ContactConstraintManager@JPH@@QEAAXAEAVStateRecorder@3@@Z";

        /// Handle to next cached contact points in ManifoldCache::mCachedManifolds for the same body pair
        mNextWithSameBodyPair: u32;

        /// Contact normal in the space of 2.
        /// Note: this value is read through sLoadFloat3Unsafe.
        mContactNormal:        Float3;

        /// Flags for this cached manifold
        EFlags :: enum u16 {
            ontactPersisted :: 1;
            CDContact       :: 2;

            ContactPersisted :: ontactPersisted;
            CCDContact       :: CDContact;
        }

        /// @see EFlags
        mFlags:                std.atomic(u16) = 0;

        /// Number of contact points in the array below
        mNumContactPoints:     u16;

        /// Contact points that this manifold consists of
        mContactPoints:        [1] CachedContactPoint #align 4;
    }

    /// Define a map that maps SubShapeIDPair -> manifold
    ManifoldMap :: LockFreeHashMap(SubShapeIDPair, CachedManifold);

    /// Start of list of contact points for a particular pair of bodies
    CachedBodyPair :: struct {
        /// Saving / restoring state for replay
        SaveState :: (this: *CachedBodyPair, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?SaveState@CachedBodyPair@ContactConstraintManager@JPH@@QEBAXAEAVStateRecorder@3@@Z";
        RestoreState :: (this: *CachedBodyPair, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?RestoreState@CachedBodyPair@ContactConstraintManager@JPH@@QEAAXAEAVStateRecorder@3@@Z";

        /// Local space position difference from Body A to Body B.
        /// Note: this value is read through sLoadFloat3Unsafe
        mDeltaPosition:       Float3;

        /// Local space rotation difference from Body A to Body B, fourth component of quaternion is not stored but is guaranteed >= 0.
        /// Note: this value is read through sLoadFloat3Unsafe
        mDeltaRotation:       Float3;

        /// Handle to first manifold in ManifoldCache::mCachedManifolds
        mFirstCachedManifold: u32;
    }

    /// Define a map that maps BodyPair -> CachedBodyPair
    BodyPairMap :: LockFreeHashMap(BodyPair, CachedBodyPair);

    /// Holds all caches that are needed to quickly find cached body pairs / manifolds
    ManifoldCache :: struct {
        /// Initialize the cache
        Init :: (this: *ManifoldCache, inMaxBodyPairs: u32, inMaxContactConstraints: u32, inCachedManifoldsSize: u32) -> void #cpp_method #foreign jolt_release "?Init@ManifoldCache@ContactConstraintManager@JPH@@QEAAXIII@Z";

        /// Reset all entries from the cache
        Clear :: (this: *ManifoldCache) -> void #cpp_method #foreign jolt_release "?Clear@ManifoldCache@ContactConstraintManager@JPH@@QEAAXXZ";

        /// Prepare cache before creating new contacts.
        /// inExpectedNumBodyPairs / inExpectedNumManifolds are the amount of body pairs / manifolds found in the previous step and is used to determine the amount of buckets the contact cache hash map will use.
        Prepare :: (this: *ManifoldCache, inExpectedNumBodyPairs: u32, inExpectedNumManifolds: u32) -> void #cpp_method #foreign jolt_release "?Prepare@ManifoldCache@ContactConstraintManager@JPH@@QEAAXII@Z";

        /// Get a new allocator context for storing contacts. Note that you should call this once and then add multiple contacts using the context.
        GetContactAllocator :: (this: *ManifoldCache) -> ContactAllocator #cpp_method #foreign jolt_release "?GetContactAllocator@ManifoldCache@ContactConstraintManager@JPH@@QEAA?AVContactAllocator@23@XZ";

        ContactPointRemovedCallbacks :: (this: *ManifoldCache, inListener: *ContactListener) -> void #cpp_method #foreign jolt_release "?ContactPointRemovedCallbacks@ManifoldCache@ContactConstraintManager@JPH@@QEAAXPEAVContactListener@3@@Z";

        /// Saving / restoring state for replay
        SaveState :: (this: *ManifoldCache, inStream: *StateRecorder, inFilter: *StateRecorderFilter) -> void #cpp_method #foreign jolt_release "?SaveState@ManifoldCache@ContactConstraintManager@JPH@@QEBAXAEAVStateRecorder@3@PEBVStateRecorderFilter@3@@Z";
        RestoreState :: (this: *ManifoldCache, inReadCache: *ManifoldCache, inStream: *StateRecorder, inFilter: *StateRecorderFilter) -> bool #cpp_method #foreign jolt_release "?RestoreState@ManifoldCache@ContactConstraintManager@JPH@@QEAA_NAEBV123@AEAVStateRecorder@3@PEBVStateRecorderFilter@3@@Z";
        RestoreState :: (this: *ManifoldCache, inReadCache: ManifoldCache, inStream: *StateRecorder, inFilter: *StateRecorderFilter) -> bool #no_context {
            return RestoreState(this, *inReadCache, inStream, inFilter);
        }

        /// Block size used when allocating new blocks in the contact cache
        cAllocatorBlockSize: u32 : 4096;

        /// Allocator used by both mCachedManifolds and mCachedBodyPairs, this makes it more likely that a body pair and its manifolds are close in memory
        mAllocator:          LFHMAllocator;

        /// Simple hash map for SubShapeIDPair -> CachedManifold
        mCachedManifolds:    ManifoldMap;

        /// Simple hash map for BodyPair -> CachedBodyPair
        mCachedBodyPairs:    BodyPairMap;

        mIsFinalized         := false; ///< Marks if this buffer is complete
    }

    mCache:                      [2] ManifoldCache #align 8; ///< We have one cache to read from and one to write to
    mCacheWriteIdx:              s32 = 0; ///< Which cache we're currently writing to

    /// World space contact point, used for solving penetrations
    WorldContactPoint :: struct {
        /// Calculate constraint properties below
        CalculateNonPenetrationConstraintProperties :: (this: *WorldContactPoint, inBody1: *Body, inInvMass1: float, inInvInertiaScale1: float, inBody2: *Body, inInvMass2: float, inInvInertiaScale2: float, inWorldSpacePosition1: Vector3, inWorldSpacePosition2: Vector3, inWorldSpaceNormal: Vec3) -> void #cpp_method #foreign jolt_release "?CalculateNonPenetrationConstraintProperties@WorldContactPoint@ContactConstraintManager@JPH@@QEAAXAEBVBody@3@MM0MMVVec3@3@11@Z";
        CalculateNonPenetrationConstraintProperties :: (this: *WorldContactPoint, inBody1: Body, inInvMass1: float, inInvInertiaScale1: float, inBody2: Body, inInvMass2: float, inInvInertiaScale2: float, inWorldSpacePosition1: Vector3, inWorldSpacePosition2: Vector3, inWorldSpaceNormal: Vec3) #no_context {
            CalculateNonPenetrationConstraintProperties(this, *inBody1, inInvMass1, inInvInertiaScale1, *inBody2, inInvMass2, inInvInertiaScale2, inWorldSpacePosition1, inWorldSpacePosition2, inWorldSpaceNormal);
        }

        /// The constraint parts
        mNonPenetrationConstraint: AxisConstraintPart;
        mFrictionConstraint1:      AxisConstraintPart;
        mFrictionConstraint2:      AxisConstraintPart;

        /// Contact cache
        mContactPoint:             *CachedContactPoint;
    }

    WorldContactPoints :: StaticArray(WorldContactPoint, xx MaxContactPoints);

    /// Contact constraint class, used for solving penetrations
    ContactConstraint :: struct {
        /// Convert the world space normal to a Vec3
        GetWorldSpaceNormal :: (this: *ContactConstraint) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetWorldSpaceNormal@ContactConstraint@ContactConstraintManager@JPH@@QEBA?AVVec3@3@XZ";

        /// Get the tangents for this contact constraint
        GetTangents :: (this: *ContactConstraint, outTangent1: *Vec3, outTangent2: *Vec3) -> void #cpp_method #foreign jolt_release "?GetTangents@ContactConstraint@ContactConstraintManager@JPH@@QEBAXAEAVVec3@3@0@Z";

        mBody1:            *Body;
        mBody2:            *Body;
        mSortKey:          u64;
        mWorldSpaceNormal: Float3;
        mCombinedFriction: float;
        mInvMass1:         float;
        mInvInertiaScale1: float;
        mInvMass2:         float;
        mInvInertiaScale2: float;
        mContactPoints:    WorldContactPoints;
    }

    /// The maximum value that can be passed to Init for inMaxContactConstraints. Note you should really use a lower value, using this value will cost a lot of memory!
    cMaxContactConstraintsLimit: u32 : ~0 / 864;

    /// The maximum value that can be passed to Init for inMaxBodyPairs. Note you should really use a lower value, using this value will cost a lot of memory!
    cMaxBodyPairsLimit:          u32 : ~0 / 40;

    /// Internal helper function to calculate the friction and non-penetration constraint properties.
    CalculateFrictionAndNonPenetrationConstraintProperties :: (this: *ContactConstraintManager, ioConstraint: *ContactConstraint, inSettings: *ContactSettings, inDeltaTime: float, inGravityDeltaTime: Vec3, inTransformBody1: Matrix4, inTransformBody2: Matrix4, inBody1: *Body, inBody2: *Body) -> void #cpp_method #foreign jolt_release "?CalculateFrictionAndNonPenetrationConstraintProperties@ContactConstraintManager@JPH@@AEAAXAEAVContactConstraint@12@AEBVContactSettings@2@MVVec3@2@AEBVMat44@2@3AEBVBody@2@4@Z";
    CalculateFrictionAndNonPenetrationConstraintProperties :: (this: *ContactConstraintManager, ioConstraint: *ContactConstraint, inSettings: ContactSettings, inDeltaTime: float, inGravityDeltaTime: Vec3, inTransformBody1: Matrix4, inTransformBody2: Matrix4, inBody1: Body, inBody2: Body) #no_context {
        CalculateFrictionAndNonPenetrationConstraintProperties(this, ioConstraint, *inSettings, inDeltaTime, inGravityDeltaTime, inTransformBody1, inTransformBody2, *inBody1, *inBody2);
    }

    /// The main physics settings instance
    mPhysicsSettings:            *PhysicsSettings;

    /// Listener that is notified whenever a contact point between two bodies is added/updated/removed
    mContactListener:            *ContactListener = null;

    /// Functions that are used to combine friction and restitution of 2 bodies
    mCombineFriction:            CombineFunction;
    mCombineRestitution:         CombineFunction;

    /// The constraints that were added this frame
    mConstraints:                *ContactConstraint = null;
    mMaxConstraints:             u32 = 0;
    mNumConstraints:             std.atomic(u32) = 0;

    /// Context used for this physics update
    mUpdateContext:              *PhysicsUpdateContext;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// Enum to identify constraint type
EConstraintType :: enum s32 {
    Constraint        :: 0;
    TwoBodyConstraint :: 1;
}

/// Enum to identify constraint sub type
EConstraintSubType :: enum s32 {
    Fixed         :: 0;
    Point         :: 1;
    Hinge         :: 2;
    Slider        :: 3;
    Distance      :: 4;
    Cone          :: 5;
    SwingTwist    :: 6;
    SixDOF        :: 7;
    Path          :: 8;
    Vehicle       :: 9;
    RackAndPinion :: 10;
    Gear          :: 11;
    Pulley        :: 12;

    User1         :: 13;
    User2         :: 14;
    User3         :: 15;
    User4         :: 16;
}

/// Certain constraints support setting them up in local or world space. This governs what is used.
EConstraintSpace :: enum s32 {
    LocalToBodyCOM :: 0;
    WorldSpace     :: 1;
}

/// Class used to store the configuration of a constraint. Allows run-time creation of constraints.
ConstraintSettings :: struct {
    #as using,except(vtable, sCreateRTTI) serializableobject:    SerializableObject;
    #as using reftarget:       RefTarget(ConstraintSettings);

    sCreateRTTI :: (inRTTI: *RTTI) -> void #foreign jolt_release "?sCreateRTTI@ConstraintSettings@JPH@@SAXAEAVRTTI@2@@Z";

    ConstraintResult :: Result(Ref(ConstraintSettings));

    /// Creates a constraint of the correct type and restores its contents from the binary stream inStream.
    sRestoreFromBinaryState :: (inStream: *StreamIn) -> ConstraintResult #foreign jolt_release "?sRestoreFromBinaryState@ConstraintSettings@JPH@@SA?AV?$Result@V?$Ref@VConstraintSettings@JPH@@@JPH@@@2@AEAVStreamIn@2@@Z";

    /// If this constraint is enabled initially. Use Constraint::SetEnabled to toggle after creation.
    mEnabled                   := true;

    /// Priority of the constraint when solving. Higher numbers are more likely to be solved correctly.
    /// Note that if you want a deterministic simulation and you cannot guarantee the order in which constraints are added/removed, you can make the priority for all constraints unique to get a deterministic ordering.
    mConstraintPriority:       u32 = 0;

    /// Used only when the constraint is active. Override for the number of solver velocity iterations to run, 0 means use the default in PhysicsSettings::mNumVelocitySteps. The number of iterations to use is the max of all contacts and constraints in the island.
    mNumVelocityStepsOverride: u32 = 0;

    /// Used only when the constraint is active. Override for the number of solver position iterations to run, 0 means use the default in PhysicsSettings::mNumPositionSteps. The number of iterations to use is the max of all contacts and constraints in the island.
    mNumPositionStepsOverride: u32 = 0;

    /// Size of constraint when drawing it through the debug renderer
    mDrawConstraintSize:       float = 1.0;

    /// User data value (can be used by application)
    mUserData:                 u64 = 0;

    /// Don't allow (copy) constructing this base class, but allow derived classes to (copy) construct themselves
    Constructor :: (this: *ConstraintSettings) -> void #cpp_method #foreign jolt_release "??0ConstraintSettings@JPH@@IEAA@XZ";
    #overlay (serializableobject) vtable: *ConstraintSettings_VTable; // Overlay parent's vtable with ConstraintSettings’s vtable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    virtual_GetRTTI :: (this: *ConstraintSettings) -> *RTTI #cpp_method #foreign jolt_release "?GetRTTI@ConstraintSettings@JPH@@UEBAPEBVRTTI@2@XZ";
    virtual_CastTo :: (this: *ConstraintSettings, inRTTI: *RTTI) -> *void #cpp_method #foreign jolt_release "?CastTo@ConstraintSettings@JPH@@UEBAPEBXPEBVRTTI@2@@Z";

    /// Saves the contents of the constraint settings in binary form to inStream.
    virtual_SaveBinaryState :: (this: *ConstraintSettings, inStream: *StreamOut) -> void #cpp_method #foreign jolt_release "?SaveBinaryState@ConstraintSettings@JPH@@UEBAXAEAVStreamOut@2@@Z";

    /// This function should not be called directly, it is used by sRestoreFromBinaryState.
    virtual_RestoreBinaryState :: (this: *ConstraintSettings, inStream: *StreamIn) -> void #cpp_method #foreign jolt_release "?RestoreBinaryState@ConstraintSettings@JPH@@MEAAXAEAVStreamIn@2@@Z";
}
ConstraintSettings_VTable :: struct #type_info_none {
    using vtable:       SerializableObject_VTable;

    SaveBinaryState:    #type (this: *ConstraintSettings, inStream: *StreamOut) -> void #cpp_method;

    RestoreBinaryState: #type (this: *ConstraintSettings, inStream: *StreamIn) -> void #cpp_method;
}
ConstraintSettings_SaveBinaryState :: inline (this: *ConstraintSettings, inStream: *StreamOut) { this.vtable.SaveBinaryState(this, inStream); }

ConstraintSettings_RestoreBinaryState :: inline (this: *ConstraintSettings, inStream: *StreamIn) { this.vtable.RestoreBinaryState(this, inStream); }

vtable :: (obj: *ConstraintSettings) -> *ConstraintSettings_VTable { return obj.vtable; }


/// Base class for all physics constraints. A constraint removes one or more degrees of freedom for a rigid body.
Constraint :: struct {
    vtable:                    *Constraint_VTable;
    #as using reftarget:       RefTarget(Constraint);
    #as using noncopyable:     NonCopyable;

    /// Constructor
    Constructor :: (this: *Constraint, inSettings: *ConstraintSettings) -> void #cpp_method #foreign jolt_release "??0Constraint@JPH@@QEAA@AEBVConstraintSettings@1@@Z";
    Constructor :: (this: *Constraint, inSettings: ConstraintSettings) #no_context {
        Constructor(this, *inSettings);
    }

    /// Priority of the constraint when solving. Higher numbers have are more likely to be solved correctly.
    /// Note that if you want a deterministic simulation and you cannot guarantee the order in which constraints are added/removed, you can make the priority for all constraints unique to get a deterministic ordering.
    GetConstraintPriority :: (this: *Constraint) -> u32 #cpp_method #foreign jolt_release "?GetConstraintPriority@Constraint@JPH@@QEBAIXZ";

    GetNumVelocityStepsOverride :: (this: *Constraint) -> u32 #cpp_method #foreign jolt_release "?GetNumVelocityStepsOverride@Constraint@JPH@@QEBAIXZ";

    GetNumPositionStepsOverride :: (this: *Constraint) -> u32 #cpp_method #foreign jolt_release "?GetNumPositionStepsOverride@Constraint@JPH@@QEBAIXZ";

    /// Helper function to copy settings back to constraint settings for this base class
    ToConstraintSettings :: (this: *Constraint, outSettings: *ConstraintSettings) -> void #cpp_method #foreign jolt_release "?ToConstraintSettings@Constraint@JPH@@IEBAXAEAVConstraintSettings@2@@Z";

    /// Index that indicates this constraint is not in the constraint manager
    cInvalidConstraintIndex:   u32 : 4294967295;

    /// Index in the mConstraints list of the ConstraintManager for easy finding
    mConstraintIndex:          u32 = cInvalidConstraintIndex #align 4;

    /// Priority of the constraint when solving. Higher numbers have are more likely to be solved correctly.
    mConstraintPriority:       u32 = 0;

    /// Used only when the constraint is active. Override for the number of solver velocity iterations to run, 0 means use the default in PhysicsSettings::mNumVelocitySteps. The number of iterations to use is the max of all contacts and constraints in the island.
    mNumVelocityStepsOverride: u8 = 0;

    /// Used only when the constraint is active. Override for the number of solver position iterations to run, 0 means use the default in PhysicsSettings::mNumPositionSteps. The number of iterations to use is the max of all contacts and constraints in the island.
    mNumPositionStepsOverride: u8 = 0;

    /// If this constraint is currently enabled
    mEnabled                   := true;

    /// User data value (can be used by application)
    mUserData:                 u64;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Virtual destructor
    virtual_Destructor :: (this: *Constraint, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1Constraint@JPH@@UEAA@XZ";

    /// Get the type of a constraint
    virtual_GetType :: (this: *Constraint) -> EConstraintType #cpp_method #foreign jolt_release "?GetType@Constraint@JPH@@UEBA?AW4EConstraintType@2@XZ";

    ///@name Solver interface
    ///@{
    virtual_IsActive :: (this: *Constraint) -> bool #cpp_method #foreign jolt_release "?IsActive@Constraint@JPH@@UEBA_NXZ";

    /// Saving state for replay
    virtual_SaveState :: (this: *Constraint, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?SaveState@Constraint@JPH@@UEBAXAEAVStateRecorder@2@@Z";

    /// Restoring state for replay
    virtual_RestoreState :: (this: *Constraint, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?RestoreState@Constraint@JPH@@UEAAXAEAVStateRecorder@2@@Z";
}
Constraint_VTable :: struct #type_info_none {
    Destructor:                  #type (this: *Constraint, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    GetType:                     #type (this: *Constraint) -> EConstraintType #cpp_method;

    GetSubType:                  #type (this: *Constraint) -> EConstraintSubType #cpp_method;

    NotifyShapeChanged:          #type (this: *Constraint, inBodyID: *BodyID, inDeltaCOM: Vec3) -> void #cpp_method;

    ResetWarmStart:              #type (this: *Constraint) -> void #cpp_method;

    IsActive:                    #type (this: *Constraint) -> bool #cpp_method;
    SetupVelocityConstraint:     #type (this: *Constraint, inDeltaTime: float) -> void #cpp_method;
    WarmStartVelocityConstraint: #type (this: *Constraint, inWarmStartImpulseRatio: float) -> void #cpp_method;
    SolveVelocityConstraint:     #type (this: *Constraint, inDeltaTime: float) -> bool #cpp_method;
    SolvePositionConstraint:     #type (this: *Constraint, inDeltaTime: float, inBaumgarte: float) -> bool #cpp_method;

    BuildIslands:                #type (this: *Constraint, inConstraintIndex: u32, ioBuilder: *IslandBuilder, inBodyManager: *BodyManager) -> void #cpp_method;

    BuildIslandSplits:           #type (this: *Constraint, ioSplitter: *LargeIslandSplitter) -> u32 #cpp_method;

    SaveState:                   #type (this: *Constraint, inStream: *StateRecorder) -> void #cpp_method;

    RestoreState:                #type (this: *Constraint, inStream: *StateRecorder) -> void #cpp_method;

    GetConstraintSettings:       #type (this: *Constraint) -> Ref(ConstraintSettings) #cpp_method #cpp_return_type_is_non_pod;
}
Constraint_Destructor :: inline (this: *Constraint, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

Constraint_GetType :: inline (this: *Constraint) -> EConstraintType { return this.vtable.GetType(this); }

Constraint_GetSubType :: inline (this: *Constraint) -> EConstraintSubType { return this.vtable.GetSubType(this); }

Constraint_NotifyShapeChanged :: inline (this: *Constraint, inBodyID: *BodyID, inDeltaCOM: Vec3) { this.vtable.NotifyShapeChanged(this, inBodyID, inDeltaCOM); }

Constraint_ResetWarmStart :: inline (this: *Constraint) { this.vtable.ResetWarmStart(this); }

Constraint_IsActive :: inline (this: *Constraint) -> bool { return this.vtable.IsActive(this); }
Constraint_SetupVelocityConstraint :: inline (this: *Constraint, inDeltaTime: float) { this.vtable.SetupVelocityConstraint(this, inDeltaTime); }
Constraint_WarmStartVelocityConstraint :: inline (this: *Constraint, inWarmStartImpulseRatio: float) { this.vtable.WarmStartVelocityConstraint(this, inWarmStartImpulseRatio); }
Constraint_SolveVelocityConstraint :: inline (this: *Constraint, inDeltaTime: float) -> bool { return this.vtable.SolveVelocityConstraint(this, inDeltaTime); }
Constraint_SolvePositionConstraint :: inline (this: *Constraint, inDeltaTime: float, inBaumgarte: float) -> bool { return this.vtable.SolvePositionConstraint(this, inDeltaTime, inBaumgarte); }

Constraint_BuildIslands :: inline (this: *Constraint, inConstraintIndex: u32, ioBuilder: *IslandBuilder, inBodyManager: *BodyManager) { this.vtable.BuildIslands(this, inConstraintIndex, ioBuilder, inBodyManager); }

Constraint_BuildIslandSplits :: inline (this: *Constraint, ioSplitter: *LargeIslandSplitter) -> u32 { return this.vtable.BuildIslandSplits(this, ioSplitter); }

Constraint_SaveState :: inline (this: *Constraint, inStream: *StateRecorder) { this.vtable.SaveState(this, inStream); }

Constraint_RestoreState :: inline (this: *Constraint, inStream: *StateRecorder) { this.vtable.RestoreState(this, inStream); }

Constraint_GetConstraintSettings :: inline (this: *Constraint) -> Ref(ConstraintSettings) { return this.vtable.GetConstraintSettings(this); }

vtable :: (obj: *Constraint) -> *Constraint_VTable { return obj.vtable; }


/// A list of constraints
Constraints :: Array(Ref(Constraint));

/// A constraint manager manages all constraints of the same type
///
/// WARNING: This class is an internal part of PhysicsSystem, it has no functions that can be called by users of the library.
/// Its functionality is exposed through PhysicsSystem and BodyInterface.
ConstraintManager :: struct {
    using noncopyable__raw: NonCopyable__RAW;

    /// Add a new constraint. This is thread safe.
    Add :: (this: *ConstraintManager, inConstraints: **Constraint, inNumber: s32) -> void #cpp_method #foreign jolt_release "?Add@ConstraintManager@JPH@@QEAAXPEAPEAVConstraint@2@H@Z";

    /// Remove a constraint. This is thread safe.
    Remove :: (this: *ConstraintManager, inConstraint: **Constraint, inNumber: s32) -> void #cpp_method #foreign jolt_release "?Remove@ConstraintManager@JPH@@QEAAXPEAPEAVConstraint@2@H@Z";

    /// Get a list of all constraints
    GetConstraints :: (this: *ConstraintManager) -> Constraints #cpp_method #foreign jolt_release "?GetConstraints@ConstraintManager@JPH@@QEBA?AV?$Array@V?$Ref@VConstraint@JPH@@@JPH@@V?$STLAllocator@V?$Ref@VConstraint@JPH@@@JPH@@@2@@2@XZ";

    /// Get total number of constraints
    GetNumConstraints :: (this: *ConstraintManager) -> u32 #cpp_method #foreign jolt_release "?GetNumConstraints@ConstraintManager@JPH@@QEBAIXZ";

    /// Determine the active constraints of a subset of the constraints
    GetActiveConstraints :: (this: *ConstraintManager, inStartConstraintIdx: u32, inEndConstraintIdx: u32, outActiveConstraints: **Constraint, outNumActiveConstraints: *u32) -> void #cpp_method #foreign jolt_release "?GetActiveConstraints@ConstraintManager@JPH@@QEBAXIIPEAPEAVConstraint@2@AEAI@Z";

    /// Link bodies to form islands
    sBuildIslands :: (inActiveConstraints: **Constraint, inNumActiveConstraints: u32, ioBuilder: *IslandBuilder, inBodyManager: *BodyManager) -> void #foreign jolt_release "?sBuildIslands@ConstraintManager@JPH@@SAXPEAPEAVConstraint@2@IAEAVIslandBuilder@2@AEAVBodyManager@2@@Z";

    /// In order to have a deterministic simulation, we need to sort the constraints of an island before solving them
    sSortConstraints :: (inActiveConstraints: **Constraint, inConstraintIdxBegin: *u32, inConstraintIdxEnd: *u32) -> void #foreign jolt_release "?sSortConstraints@ConstraintManager@JPH@@SAXPEAPEAVConstraint@2@PEAI1@Z";

    /// Prior to solving the velocity constraints, you must call SetupVelocityConstraints once to precalculate values that are independent of velocity
    sSetupVelocityConstraints :: (inActiveConstraints: **Constraint, inNumActiveConstraints: u32, inDeltaTime: float) -> void #foreign jolt_release "?sSetupVelocityConstraints@ConstraintManager@JPH@@SAXPEAPEAVConstraint@2@IM@Z";

    /// This function is called multiple times to iteratively come to a solution that meets all velocity constraints
    sSolveVelocityConstraints :: (inActiveConstraints: **Constraint, inConstraintIdxBegin: *u32, inConstraintIdxEnd: *u32, inDeltaTime: float) -> bool #foreign jolt_release "?sSolveVelocityConstraints@ConstraintManager@JPH@@SA_NPEAPEAVConstraint@2@PEBI1M@Z";

    /// This function is called multiple times to iteratively come to a solution that meets all position constraints
    sSolvePositionConstraints :: (inActiveConstraints: **Constraint, inConstraintIdxBegin: *u32, inConstraintIdxEnd: *u32, inDeltaTime: float, inBaumgarte: float) -> bool #foreign jolt_release "?sSolvePositionConstraints@ConstraintManager@JPH@@SA_NPEAPEAVConstraint@2@PEBI1MM@Z";

    /// Save state of constraints
    SaveState :: (this: *ConstraintManager, inStream: *StateRecorder, inFilter: *StateRecorderFilter) -> void #cpp_method #foreign jolt_release "?SaveState@ConstraintManager@JPH@@QEBAXAEAVStateRecorder@2@PEBVStateRecorderFilter@2@@Z";

    /// Restore the state of constraints. Returns false if failed.
    RestoreState :: (this: *ConstraintManager, inStream: *StateRecorder) -> bool #cpp_method #foreign jolt_release "?RestoreState@ConstraintManager@JPH@@QEAA_NAEAVStateRecorder@2@@Z";

    /// Lock all constraints. This should only be done during PhysicsSystem::Update().
    LockAllConstraints :: (this: *ConstraintManager) -> void #cpp_method #foreign jolt_release "?LockAllConstraints@ConstraintManager@JPH@@QEAAXXZ";
    UnlockAllConstraints :: (this: *ConstraintManager) -> void #cpp_method #foreign jolt_release "?UnlockAllConstraints@ConstraintManager@JPH@@QEAAXXZ";

    mLockContext:           PhysicsLockContext;

    mConstraints:           Constraints;
    mConstraintsMutex:      Mutex;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// Keeps track of connected bodies and builds islands for multithreaded velocity/position update
IslandBuilder :: struct {
    using noncopyable__raw: NonCopyable__RAW;

    /// Destructor
    Destructor :: (this: *IslandBuilder) -> void #cpp_method #foreign jolt_release "??1IslandBuilder@JPH@@QEAA@XZ";

    /// Initialize the island builder with the maximum amount of bodies that could be active
    Init :: (this: *IslandBuilder, inMaxActiveBodies: u32) -> void #cpp_method #foreign jolt_release "?Init@IslandBuilder@JPH@@QEAAXI@Z";

    /// Prepare for simulation step by allocating space for the contact constraints
    PrepareContactConstraints :: (this: *IslandBuilder, inMaxContactConstraints: u32, inTempAllocator: *TempAllocator) -> void #cpp_method #foreign jolt_release "?PrepareContactConstraints@IslandBuilder@JPH@@QEAAXIPEAVTempAllocator@2@@Z";

    /// Prepare for simulation step by allocating space for the non-contact constraints
    PrepareNonContactConstraints :: (this: *IslandBuilder, inNumConstraints: u32, inTempAllocator: *TempAllocator) -> void #cpp_method #foreign jolt_release "?PrepareNonContactConstraints@IslandBuilder@JPH@@QEAAXIPEAVTempAllocator@2@@Z";

    /// Link two bodies by their index in the BodyManager::mActiveBodies list to form islands
    LinkBodies :: (this: *IslandBuilder, inFirst: u32, inSecond: u32) -> void #cpp_method #foreign jolt_release "?LinkBodies@IslandBuilder@JPH@@QEAAXII@Z";

    /// Link a constraint to a body by their index in the BodyManager::mActiveBodies
    LinkConstraint :: (this: *IslandBuilder, inConstraintIndex: u32, inFirst: u32, inSecond: u32) -> void #cpp_method #foreign jolt_release "?LinkConstraint@IslandBuilder@JPH@@QEAAXIII@Z";

    /// Link a contact to a body by their index in the BodyManager::mActiveBodies
    LinkContact :: (this: *IslandBuilder, inContactIndex: u32, inFirst: u32, inSecond: u32) -> void #cpp_method #foreign jolt_release "?LinkContact@IslandBuilder@JPH@@QEAAXIII@Z";

    /// Finalize the islands after all bodies have been Link()-ed
    Finalize :: (this: *IslandBuilder, inActiveBodies: *BodyID, inNumActiveBodies: u32, inNumContacts: u32, inTempAllocator: *TempAllocator) -> void #cpp_method #foreign jolt_release "?Finalize@IslandBuilder@JPH@@QEAAXPEBVBodyID@2@IIPEAVTempAllocator@2@@Z";

    /// Get the amount of islands formed
    GetNumIslands :: (this: *IslandBuilder) -> u32 #cpp_method #foreign jolt_release "?GetNumIslands@IslandBuilder@JPH@@QEBAIXZ";

    /// Get iterator for a particular island, return false if there are no constraints
    GetBodiesInIsland :: (this: *IslandBuilder, inIslandIndex: u32, outBodiesBegin: **BodyID, outBodiesEnd: **BodyID) -> void #cpp_method #foreign jolt_release "?GetBodiesInIsland@IslandBuilder@JPH@@QEBAXIAEAPEAVBodyID@2@0@Z";
    GetConstraintsInIsland :: (this: *IslandBuilder, inIslandIndex: u32, outConstraintsBegin: **u32, outConstraintsEnd: **u32) -> bool #cpp_method #foreign jolt_release "?GetConstraintsInIsland@IslandBuilder@JPH@@QEBA_NIAEAPEAI0@Z";
    GetContactsInIsland :: (this: *IslandBuilder, inIslandIndex: u32, outContactsBegin: **u32, outContactsEnd: **u32) -> bool #cpp_method #foreign jolt_release "?GetContactsInIsland@IslandBuilder@JPH@@QEBA_NIAEAPEAI0@Z";

    /// The number of position iterations for each island
    SetNumPositionSteps :: (this: *IslandBuilder, inIslandIndex: u32, inNumPositionSteps: u32) -> void #cpp_method #foreign jolt_release "?SetNumPositionSteps@IslandBuilder@JPH@@QEAAXII@Z";
    GetNumPositionSteps :: (this: *IslandBuilder, inIslandIndex: u32) -> u32 #cpp_method #foreign jolt_release "?GetNumPositionSteps@IslandBuilder@JPH@@QEBAII@Z";

    /// After you're done calling the three functions above, call this function to free associated data
    ResetIslands :: (this: *IslandBuilder, inTempAllocator: *TempAllocator) -> void #cpp_method #foreign jolt_release "?ResetIslands@IslandBuilder@JPH@@QEAAXPEAVTempAllocator@2@@Z";

    /// Returns the index of the lowest body in the group
    GetLowestBodyIndex :: (this: *IslandBuilder, inActiveBodyIndex: u32) -> u32 #cpp_method #foreign jolt_release "?GetLowestBodyIndex@IslandBuilder@JPH@@AEBAII@Z";

    // Helper functions to build various islands
    BuildBodyIslands :: (this: *IslandBuilder, inActiveBodies: *BodyID, inNumActiveBodies: u32, inTempAllocator: *TempAllocator) -> void #cpp_method #foreign jolt_release "?BuildBodyIslands@IslandBuilder@JPH@@AEAAXPEBVBodyID@2@IPEAVTempAllocator@2@@Z";
    BuildConstraintIslands :: (this: *IslandBuilder, inConstraintToBody: *u32, inNumConstraints: u32, outConstraints: **u32, outConstraintsEnd: **u32, inTempAllocator: *TempAllocator) -> void #cpp_method #foreign jolt_release "?BuildConstraintIslands@IslandBuilder@JPH@@AEBAXPEBIIAEAPEAI1PEAVTempAllocator@2@@Z";

    /// Sorts the islands so that the islands with most constraints go first
    SortIslands :: (this: *IslandBuilder, inTempAllocator: *TempAllocator) -> void #cpp_method #foreign jolt_release "?SortIslands@IslandBuilder@JPH@@AEAAXPEAVTempAllocator@2@@Z";

    /// Intermediate data structure that for each body keeps track what the lowest index of the body is that it is connected to
    BodyLink :: struct {
        mLinkedTo:    std.atomic(u32); ///< An index in mBodyLinks pointing to another body in this island with a lower index than this body
        mIslandIndex: u32; ///< The island index of this body (filled in during Finalize)
    }

    mBodyLinks:             *BodyLink = null; ///< Maps bodies to the first body in the island
    mConstraintLinks:       *u32 = null; ///< Maps constraint index to body index (which maps to island index)
    mContactLinks:          *u32 = null; ///< Maps contact constraint index to body index (which maps to island index)

    mBodyIslands:           *BodyID = null; ///< Bodies ordered by island
    mBodyIslandEnds:        *u32 = null; ///< End index of each body island

    mConstraintIslands:     *u32 = null; ///< Constraints ordered by island
    mConstraintIslandEnds:  *u32 = null; ///< End index of each constraint island

    mContactIslands:        *u32 = null; ///< Contacts ordered by island
    mContactIslandEnds:     *u32 = null; ///< End index of each contact island

    mIslandsSorted:         *u32 = null; ///< A list of island indices in order of most constraints first

    mNumPositionSteps:      *u8 = null; ///< Number of position steps for each island

    mMaxActiveBodies:       u32; ///< Maximum size of the active bodies list (see BodyManager::mActiveBodies)
    mNumActiveBodies:       u32 = 0; ///< Number of active bodies passed to
    mNumConstraints:        u32 = 0; ///< Size of the constraint list (see ConstraintManager::mConstraints)
    mMaxContacts:           u32 = 0; ///< Maximum amount of contacts supported
    mNumContacts:           u32 = 0; ///< Size of the contacts list (see ContactConstraintManager::mNumConstraints)
    mNumIslands:            u32 = 0; ///< Final number of islands
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

CalculateSolverSteps :: struct {}

/// Assigns bodies in large islands to multiple groups that can run in parallel
///
/// This basically implements what is described in: High-Performance Physical Simulations on Next-Generation Architecture with Many Cores by Chen et al.
/// See: http://web.eecs.umich.edu/~msmelyan/papers/physsim_onmanycore_itj.pdf section "PARALLELIZATION METHODOLOGY"
///
/// WARNING: This class is an internal part of PhysicsSystem, it has no functions that can be called by users of the library.
LargeIslandSplitter :: struct {
    using noncopyable__raw:         NonCopyable__RAW;

    SplitMask :: u32;

    cNumSplits:                     u32 : 4 * 8;
    cNonParallelSplitIdx:           u32 : cNumSplits - 1;
    cLargeIslandTreshold:           u32 : 128; ///< If the number of constraints + contacts in an island is larger than this, we will try to split the island

    /// Status code for retrieving a batch
    EStatus :: enum s32 {
        WaitingForBatch :: 0;
        BatchRetrieved  :: 1;
        AllBatchesDone  :: 2;
    }

    /// Describes a split of constraints and contacts
    Split :: struct {
        GetNumContacts :: (this: *Split) -> u32 #cpp_method #foreign jolt_release "?GetNumContacts@Split@LargeIslandSplitter@JPH@@QEBAIXZ";
        GetNumConstraints :: (this: *Split) -> u32 #cpp_method #foreign jolt_release "?GetNumConstraints@Split@LargeIslandSplitter@JPH@@QEBAIXZ";
        GetNumItems :: (this: *Split) -> u32 #cpp_method #foreign jolt_release "?GetNumItems@Split@LargeIslandSplitter@JPH@@QEBAIXZ";

        mContactBufferBegin:    u32; ///< Begin of the contact buffer (offset relative to mContactAndConstraintIndices)
        mContactBufferEnd:      u32; ///< End of the contact buffer

        mConstraintBufferBegin: u32; ///< Begin of the constraint buffer (offset relative to mContactAndConstraintIndices)
        mConstraintBufferEnd:   u32; ///< End of the constraint buffer
    }

    /// Structure that describes the resulting splits from the large island splitter
    Splits :: struct {
        /// Reset current status so that no work can be picked up from this split
        ResetStatus :: (this: *Splits) -> void #cpp_method #foreign jolt_release "?ResetStatus@Splits@LargeIslandSplitter@JPH@@QEAAXXZ";

        /// Make the first batch available to other threads
        StartFirstBatch :: (this: *Splits) -> void #cpp_method #foreign jolt_release "?StartFirstBatch@Splits@LargeIslandSplitter@JPH@@QEAAXXZ";

        /// Fetch the next batch to process
        FetchNextBatch :: (this: *Splits, outConstraintsBegin: *u32, outConstraintsEnd: *u32, outContactsBegin: *u32, outContactsEnd: *u32, outFirstIteration: *bool) -> EStatus #cpp_method #foreign jolt_release "?FetchNextBatch@Splits@LargeIslandSplitter@JPH@@QEAA?AW4EStatus@23@AEAI000AEA_N@Z";

        /// Mark a batch as processed
        MarkBatchProcessed :: (this: *Splits, inNumProcessed: u32, outLastIteration: *bool, outFinalBatch: *bool) -> void #cpp_method #foreign jolt_release "?MarkBatchProcessed@Splits@LargeIslandSplitter@JPH@@QEAAXIAEA_N0@Z";

        EIterationStatus :: enum u64 {
            IterationMask  :: 18446462598732840960;
            IterationShift :: 48;
            SplitMask      :: 281470681743360;
            SplitShift     :: 32;
            ItemMask       :: 4294967295;

            StatusIterationMask  :: IterationMask;
            StatusIterationShift :: IterationShift;
            StatusSplitMask      :: SplitMask;
            StatusSplitShift     :: SplitShift;
            StatusItemMask       :: ItemMask;
        }

        sGetIteration :: (inStatus: u64) -> s32 #foreign jolt_release "?sGetIteration@Splits@LargeIslandSplitter@JPH@@SAH_K@Z";

        sGetSplit :: (inStatus: u64) -> u32 #foreign jolt_release "?sGetSplit@Splits@LargeIslandSplitter@JPH@@SAI_K@Z";

        sGetItem :: (inStatus: u64) -> u32 #foreign jolt_release "?sGetItem@Splits@LargeIslandSplitter@JPH@@SAI_K@Z";

        mSplits:           [32] Split; ///< Data per split
        mIslandIndex:      u32; ///< Index of the island that was split
        mNumSplits:        u32; ///< Number of splits that were created (excluding the non-parallel split)
        mNumIterations:    s32; ///< Number of iterations to do
        mNumVelocitySteps: s32; ///< Number of velocity steps to do (cached for 2nd sub step)
        mNumPositionSteps: s32; ///< Number of position steps to do
        mStatus:           std.atomic(u64); ///< Status of the split, see EIterationStatus
        mItemsProcessed:   std.atomic(u32); ///< Number of items that have been marked as processed
    }

    /// Destructor
    Destructor :: (this: *LargeIslandSplitter) -> void #cpp_method #foreign jolt_release "??1LargeIslandSplitter@JPH@@QEAA@XZ";

    /// Prepare the island splitter by allocating memory
    Prepare :: (this: *LargeIslandSplitter, inIslandBuilder: *IslandBuilder, inNumActiveBodies: u32, inTempAllocator: *TempAllocator) -> void #cpp_method #foreign jolt_release "?Prepare@LargeIslandSplitter@JPH@@QEAAXAEBVIslandBuilder@2@IPEAVTempAllocator@2@@Z";
    Prepare :: (this: *LargeIslandSplitter, inIslandBuilder: IslandBuilder, inNumActiveBodies: u32, inTempAllocator: *TempAllocator) #no_context {
        Prepare(this, *inIslandBuilder, inNumActiveBodies, inTempAllocator);
    }

    /// Assign two bodies to a split. Returns the split index.
    AssignSplit :: (this: *LargeIslandSplitter, inBody1: *Body, inBody2: *Body) -> u32 #cpp_method #foreign jolt_release "?AssignSplit@LargeIslandSplitter@JPH@@QEAAIPEBVBody@2@0@Z";

    /// Force a body to be in a non parallel split. Returns the split index.
    AssignToNonParallelSplit :: (this: *LargeIslandSplitter, inBody: *Body) -> u32 #cpp_method #foreign jolt_release "?AssignToNonParallelSplit@LargeIslandSplitter@JPH@@QEAAIPEBVBody@2@@Z";

    /// Splits up an island, the created splits will be added to the list of batches and can be fetched with FetchNextBatch. Returns false if the island did not need splitting.
    SplitIsland :: (this: *LargeIslandSplitter, inIslandIndex: u32, inIslandBuilder: *IslandBuilder, inBodyManager: *BodyManager, inContactManager: *ContactConstraintManager, inActiveConstraints: **Constraint, ioStepsCalculator: *CalculateSolverSteps) -> bool #cpp_method #foreign jolt_release "?SplitIsland@LargeIslandSplitter@JPH@@QEAA_NIAEBVIslandBuilder@2@AEBVBodyManager@2@AEBVContactConstraintManager@2@PEAPEAVConstraint@2@AEAVCalculateSolverSteps@2@@Z";
    SplitIsland :: (this: *LargeIslandSplitter, inIslandIndex: u32, inIslandBuilder: IslandBuilder, inBodyManager: BodyManager, inContactManager: ContactConstraintManager, inActiveConstraints: **Constraint, ioStepsCalculator: *CalculateSolverSteps) -> bool #no_context {
        return SplitIsland(this, inIslandIndex, *inIslandBuilder, *inBodyManager, *inContactManager, inActiveConstraints, ioStepsCalculator);
    }

    /// Fetch the next batch to process, returns a handle in outSplitIslandIndex that must be provided to MarkBatchProcessed when complete
    FetchNextBatch :: (this: *LargeIslandSplitter, outSplitIslandIndex: *u32, outConstraintsBegin: **u32, outConstraintsEnd: **u32, outContactsBegin: **u32, outContactsEnd: **u32, outFirstIteration: *bool) -> EStatus #cpp_method #foreign jolt_release "?FetchNextBatch@LargeIslandSplitter@JPH@@QEAA?AW4EStatus@12@AEAIAEAPEAI111AEA_N@Z";

    /// Mark a batch as processed
    MarkBatchProcessed :: (this: *LargeIslandSplitter, inSplitIslandIndex: u32, inConstraintsBegin: *u32, inConstraintsEnd: *u32, inContactsBegin: *u32, inContactsEnd: *u32, outLastIteration: *bool, outFinalBatch: *bool) -> void #cpp_method #foreign jolt_release "?MarkBatchProcessed@LargeIslandSplitter@JPH@@QEAAXIPEBI000AEA_N1@Z";

    /// Get the island index of the island that was split for a particular split island index
    GetIslandIndex :: (this: *LargeIslandSplitter, inSplitIslandIndex: u32) -> u32 #cpp_method #foreign jolt_release "?GetIslandIndex@LargeIslandSplitter@JPH@@QEBAII@Z";

    /// Prepare the island splitter for iterating over the split islands again for position solving. Marks all batches as startable.
    PrepareForSolvePositions :: (this: *LargeIslandSplitter) -> void #cpp_method #foreign jolt_release "?PrepareForSolvePositions@LargeIslandSplitter@JPH@@QEAAXXZ";

    /// Reset the island splitter
    Reset :: (this: *LargeIslandSplitter, inTempAllocator: *TempAllocator) -> void #cpp_method #foreign jolt_release "?Reset@LargeIslandSplitter@JPH@@QEAAXPEAVTempAllocator@2@@Z";

    cSplitCombineTreshold:          u32 : 32; ///< If the number of constraints + contacts in a split is lower than this, we will merge this split into the 'non-parallel split'
    cBatchSize:                     u32 : 16; ///< Number of items to process in a constraint batch

    mNumActiveBodies:               u32 = 0; ///< Cached number of active bodies

    mSplitMasks:                    *SplitMask = null; ///< Bits that indicate for each body in the BodyManager::mActiveBodies list which split they already belong to

    mContactAndConstraintsSplitIdx: *u32 = null; ///< Buffer to store the split index per constraint or contact
    mContactAndConstraintIndices:   *u32 = null; ///< Buffer to store the ordered constraint indices per split
    mContactAndConstraintsSize:     u32 = 0; ///< Total size of mContactAndConstraintsSplitIdx and mContactAndConstraintIndices
    mContactAndConstraintsNextFree: std.atomic(u32) = 0; ///< Next element that is free in both buffers

    mNumSplitIslands:               u32 = 0; ///< Total number of islands that required splitting
    mSplitIslands:                  *Splits = null; ///< List of islands that required splitting
    mNextSplitIsland:               std.atomic(u32) = 0; ///< Next split island to pick from mSplitIslands
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

BodyPairCollector :: CollisionCollector(BodyPair, CollisionCollectorTraitsCollideShape);

/// Used to do coarse collision detection operations to quickly prune out bodies that will not collide.
BroadPhase :: struct {
    #as using,except(vtable) broadphasequery: BroadPhaseQuery;

    /// Context used during broadphase update
    UpdateState :: struct {
        mData: [4] *void;
    }

    /// Handle used during adding bodies to the broadphase
    AddState :: *void;

    /// Link to the body manager that manages the bodies in this broadphase
    mBodyManager:        *BodyManager = null;
    #overlay (broadphasequery) vtable: *BroadPhase_VTable; // Overlay parent's vtable with BroadPhase’s vtable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Initialize the broadphase.
    /// @param inBodyManager The body manager singleton
    /// @param inLayerInterface Interface that maps object layers to broadphase layers.
    /// Note that the broadphase takes a pointer to the data inside inObjectToBroadPhaseLayer so this object should remain static.
    virtual_Init :: (this: *BroadPhase, inBodyManager: *BodyManager, inLayerInterface: *BroadPhaseLayerInterface) -> void #cpp_method #foreign jolt_release "?Init@BroadPhase@JPH@@UEAAXPEAVBodyManager@2@AEBVBroadPhaseLayerInterface@2@@Z";

    /// Should be called after many objects have been inserted to make the broadphase more efficient, usually done on startup only
    virtual_Optimize :: (this: *BroadPhase) -> void #cpp_method #foreign jolt_release "?Optimize@BroadPhase@JPH@@UEAAXXZ";

    /// Must be called just before updating the broadphase when none of the body mutexes are locked
    virtual_FrameSync :: (this: *BroadPhase) -> void #cpp_method #foreign jolt_release "?FrameSync@BroadPhase@JPH@@UEAAXXZ";

    /// Must be called before UpdatePrepare to prevent modifications from being made to the tree
    virtual_LockModifications :: (this: *BroadPhase) -> void #cpp_method #foreign jolt_release "?LockModifications@BroadPhase@JPH@@UEAAXXZ";

    /// Update the broadphase, needs to be called frequently to update the internal state when bodies have been modified.
    /// The UpdatePrepare() function can run in a background thread without influencing the broadphase
    virtual_UpdatePrepare :: (this: *BroadPhase) -> UpdateState #cpp_method #foreign jolt_release "?UpdatePrepare@BroadPhase@JPH@@UEAA?AUUpdateState@12@XZ";

    /// Finalizing the update will quickly apply the changes
    virtual_UpdateFinalize :: (this: *BroadPhase, inUpdateState: *UpdateState) -> void #cpp_method #foreign jolt_release "?UpdateFinalize@BroadPhase@JPH@@UEAAXAEBUUpdateState@12@@Z";

    /// Must be called after UpdateFinalize to allow modifications to the broadphase
    virtual_UnlockModifications :: (this: *BroadPhase) -> void #cpp_method #foreign jolt_release "?UnlockModifications@BroadPhase@JPH@@UEAAXXZ";

    /// Prepare adding inNumber bodies at ioBodies to the broadphase, returns a handle that should be used in AddBodiesFinalize/Abort.
    /// This can be done on a background thread without influencing the broadphase.
    /// ioBodies may be shuffled around by this function and should be kept that way until AddBodiesFinalize/Abort is called.
    virtual_AddBodiesPrepare :: (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32) -> AddState #cpp_method #foreign jolt_release "?AddBodiesPrepare@BroadPhase@JPH@@UEAAPEAXPEAVBodyID@2@H@Z";

    /// Abort adding bodies to the broadphase, supply the return value of AddBodiesPrepare in inAddState.
    /// This can be done on a background thread without influencing the broadphase.
    /// Please ensure that the ioBodies array passed to AddBodiesPrepare is unmodified and passed again to this function.
    virtual_AddBodiesAbort :: (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32, inAddState: AddState) -> void #cpp_method #foreign jolt_release "?AddBodiesAbort@BroadPhase@JPH@@UEAAXPEAVBodyID@2@HPEAX@Z";
}
BroadPhase_VTable :: struct #type_info_none {
    using vtable:             BroadPhaseQuery_VTable;

    Init:                     #type (this: *BroadPhase, inBodyManager: *BodyManager, inLayerInterface: *BroadPhaseLayerInterface) -> void #cpp_method;

    Optimize:                 #type (this: *BroadPhase) -> void #cpp_method;

    FrameSync:                #type (this: *BroadPhase) -> void #cpp_method;

    LockModifications:        #type (this: *BroadPhase) -> void #cpp_method;

    UpdatePrepare:            #type (this: *BroadPhase) -> BroadPhase.UpdateState #cpp_method;

    UpdateFinalize:           #type (this: *BroadPhase, inUpdateState: *BroadPhase.UpdateState) -> void #cpp_method;

    UnlockModifications:      #type (this: *BroadPhase) -> void #cpp_method;

    AddBodiesPrepare:         #type (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32) -> BroadPhase.AddState #cpp_method;

    AddBodiesFinalize:        #type (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32, inAddState: BroadPhase.AddState) -> void #cpp_method;

    AddBodiesAbort:           #type (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32, inAddState: BroadPhase.AddState) -> void #cpp_method;

    RemoveBodies:             #type (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32) -> void #cpp_method;

    NotifyBodiesAABBChanged:  #type (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32, inTakeLock := true) -> void #cpp_method;

    NotifyBodiesLayerChanged: #type (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32) -> void #cpp_method;

    FindCollidingPairs:       #type (this: *BroadPhase, ioActiveBodies: *BodyID, inNumActiveBodies: s32, inSpeculativeContactDistance: float, inObjectVsBroadPhaseLayerFilter: *ObjectVsBroadPhaseLayerFilter, inObjectLayerPairFilter: *ObjectLayerPairFilter, ioPairCollector: *BodyPairCollector) -> void #cpp_method;

    CastAABoxNoLock:          #type (this: *BroadPhase, inBox: *AABoxCast, ioCollector: *CastShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) -> void #cpp_method;
}
BroadPhase_Init :: inline (this: *BroadPhase, inBodyManager: *BodyManager, inLayerInterface: *BroadPhaseLayerInterface) { this.vtable.Init(this, inBodyManager, inLayerInterface); }

BroadPhase_Optimize :: inline (this: *BroadPhase) { this.vtable.Optimize(this); }

BroadPhase_FrameSync :: inline (this: *BroadPhase) { this.vtable.FrameSync(this); }

BroadPhase_LockModifications :: inline (this: *BroadPhase) { this.vtable.LockModifications(this); }

BroadPhase_UpdatePrepare :: inline (this: *BroadPhase) -> BroadPhase.UpdateState { return this.vtable.UpdatePrepare(this); }

BroadPhase_UpdateFinalize :: inline (this: *BroadPhase, inUpdateState: *BroadPhase.UpdateState) { this.vtable.UpdateFinalize(this, inUpdateState); }

BroadPhase_UnlockModifications :: inline (this: *BroadPhase) { this.vtable.UnlockModifications(this); }

BroadPhase_AddBodiesPrepare :: inline (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32) -> BroadPhase.AddState { return this.vtable.AddBodiesPrepare(this, ioBodies, inNumber); }

BroadPhase_AddBodiesFinalize :: inline (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32, inAddState: BroadPhase.AddState) { this.vtable.AddBodiesFinalize(this, ioBodies, inNumber, inAddState); }

BroadPhase_AddBodiesAbort :: inline (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32, inAddState: BroadPhase.AddState) { this.vtable.AddBodiesAbort(this, ioBodies, inNumber, inAddState); }

BroadPhase_RemoveBodies :: inline (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32) { this.vtable.RemoveBodies(this, ioBodies, inNumber); }

BroadPhase_NotifyBodiesAABBChanged :: inline (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32, inTakeLock := true) { this.vtable.NotifyBodiesAABBChanged(this, ioBodies, inNumber, inTakeLock); }

BroadPhase_NotifyBodiesLayerChanged :: inline (this: *BroadPhase, ioBodies: *BodyID, inNumber: s32) { this.vtable.NotifyBodiesLayerChanged(this, ioBodies, inNumber); }

BroadPhase_FindCollidingPairs :: inline (this: *BroadPhase, ioActiveBodies: *BodyID, inNumActiveBodies: s32, inSpeculativeContactDistance: float, inObjectVsBroadPhaseLayerFilter: *ObjectVsBroadPhaseLayerFilter, inObjectLayerPairFilter: *ObjectLayerPairFilter, ioPairCollector: *BodyPairCollector) { this.vtable.FindCollidingPairs(this, ioActiveBodies, inNumActiveBodies, inSpeculativeContactDistance, inObjectVsBroadPhaseLayerFilter, inObjectLayerPairFilter, ioPairCollector); }

BroadPhase_CastAABoxNoLock :: inline (this: *BroadPhase, inBox: *AABoxCast, ioCollector: *CastShapeBodyCollector, inBroadPhaseLayerFilter: *BroadPhaseLayerFilter, inObjectLayerFilter: *ObjectLayerFilter) { this.vtable.CastAABoxNoLock(this, inBox, ioCollector, inBroadPhaseLayerFilter, inObjectLayerFilter); }

vtable :: (obj: *BroadPhase) -> *BroadPhase_VTable { return obj.vtable; }


/// A class that allows units of work (Jobs) to be scheduled across multiple threads.
/// It allows dependencies between the jobs so that the jobs form a graph.
///
/// The pattern for using this class is:
///
///		// Create job system
///		JobSystem *job_system = new JobSystemThreadPool(...);
///
///		// Create some jobs
///		JobHandle second_job = job_system->CreateJob("SecondJob", Color::sRed, []() { ... }, 1); // Create a job with 1 dependency
///		JobHandle first_job = job_system->CreateJob("FirstJob", Color::sGreen, [second_job]() { ....; second_job.RemoveDependency(); }, 0); // Job can start immediately, will start second job when it's done
///		JobHandle third_job = job_system->CreateJob("ThirdJob", Color::sBlue, []() { ... }, 0); // This job can run immediately as well and can run in parallel to job 1 and 2
///
///		// Add the jobs to the barrier so that we can execute them while we're waiting
///		Barrier *barrier = job_system->CreateBarrier();
///		barrier->AddJob(first_job);
///		barrier->AddJob(second_job);
///		barrier->AddJob(third_job);
///		job_system->WaitForJobs(barrier);
///
///		// Clean up
///		job_system->DestroyBarrier(barrier);
///		delete job_system;
///
///	Jobs are guaranteed to be started in the order that their dependency counter becomes zero (in case they're scheduled on a background thread)
///	or in the order they're added to the barrier (when dependency count is zero and when executing on the thread that calls WaitForJobs).
///
/// If you want to implement your own job system, inherit from JobSystem and implement:
///
/// * JobSystem::GetMaxConcurrency - This should return the maximum number of jobs that can run in parallel.
/// * JobSystem::CreateJob - This should create a Job object and return it to the caller.
/// * JobSystem::FreeJob - This should free the memory associated with the job object. It is called by the Job destructor when it is Release()-ed for the last time.
/// * JobSystem::QueueJob/QueueJobs - These should store the job pointer in an internal queue to run immediately (dependencies are tracked internally, this function is called when the job can run).
/// The Job objects are reference counted and are guaranteed to stay alive during the QueueJob(s) call. If you store the job in your own data structure you need to call AddRef() to take a reference.
/// After the job has been executed you need to call Release() to release the reference. Make sure you no longer dereference the job pointer after calling Release().
///
/// JobSystem::Barrier is used to track the completion of a set of jobs. Jobs will be created by other jobs and added to the barrier while it is being waited on. This means that you cannot
/// create a dependency graph beforehand as the graph changes while jobs are running. Implement the following functions:
///
/// * Barrier::AddJob/AddJobs - Add a job to the barrier, any call to WaitForJobs will now also wait for this job to complete.
/// If you store the job in a data structure in the Barrier you need to call AddRef() on the job to keep it alive and Release() after you're done with it.
/// * Barrier::OnJobFinished - This function is called when a job has finished executing, you can use this to track completion and remove the job from the list of jobs to wait on.
///
/// The functions on JobSystem that need to be implemented to support barriers are:
///
/// * JobSystem::CreateBarrier - Create a new barrier.
/// * JobSystem::DestroyBarrier - Destroy a barrier.
/// * JobSystem::WaitForJobs - This is the main function that is used to wait for all jobs that have been added to a Barrier. WaitForJobs can execute jobs that have
/// been added to the barrier while waiting. It is not wise to execute other jobs that touch physics structures as this can cause race conditions and deadlocks. Please keep in mind that the barrier is
/// only intended to wait on the completion of the Jolt jobs added to it, if you scheduled any jobs in your engine's job system to execute the Jolt jobs as part of QueueJob/QueueJobs, you might still need
/// to wait for these in this function after the barrier is finished waiting.
///
/// An example implementation is JobSystemThreadPool. If you don't want to write the Barrier class you can also inherit from JobSystemWithBarrier.
JobSystem :: struct {
    vtable:                 *JobSystem_VTable;
    using noncopyable__raw: NonCopyable__RAW;

    /// A job handle contains a reference to a job. The job will be deleted as soon as there are no JobHandles.
    /// referring to the job and when it is not in the job queue / being processed.
    JobHandle :: struct {
        #as using ref: Ref(Job);

        /// Constructor
        Constructor :: (this: *JobHandle) -> void #cpp_method #foreign jolt_release "??0JobHandle@JobSystem@JPH@@QEAA@XZ";
        CopyConstructor :: (this: *JobHandle, inHandle: *JobHandle) -> void #cpp_method #foreign jolt_release "??0JobHandle@JobSystem@JPH@@QEAA@AEBV012@@Z";
        CopyConstructor :: (this: *JobHandle, inHandle: JobHandle) #no_context {
            CopyConstructor(this, *inHandle);
        }

        /// Constructor, only to be used by JobSystem
        Constructor :: (this: *JobHandle, inJob: *Job) -> void #cpp_method #foreign jolt_release "??0JobHandle@JobSystem@JPH@@QEAA@PEAVJob@12@@Z";

        /// Check if this handle contains a job
        IsValid :: (this: *JobHandle) -> bool #cpp_method #foreign jolt_release "?IsValid@JobHandle@JobSystem@JPH@@QEBA_NXZ";

        /// Add to the dependency counter.
        AddDependency :: (this: *JobHandle, inCount: s32 = 1) -> void #cpp_method #foreign jolt_release "?AddDependency@JobHandle@JobSystem@JPH@@QEBAXH@Z";

        /// Remove from the dependency counter. Job will start whenever the dependency counter reaches zero
        /// and if it does it is no longer valid to call the AddDependency/RemoveDependency functions.
        RemoveDependency :: (this: *JobHandle, inCount: s32 = 1) -> void #cpp_method #foreign jolt_release "?RemoveDependency@JobHandle@JobSystem@JPH@@QEBAXH@Z";

        /// Remove a dependency from a batch of jobs at once, this can be more efficient than removing them one by one as it requires less locking
        sRemoveDependencies :: (inHandles: *JobHandle, inNumHandles: u32, inCount: s32 = 1) -> void #foreign jolt_release "?sRemoveDependencies@JobHandle@JobSystem@JPH@@SAXPEBV123@IH@Z";
    }

    /// A job barrier keeps track of a number of jobs and allows waiting until they are all completed.
    Barrier :: struct {
        vtable:                 *Barrier_VTable;
        using noncopyable__raw: NonCopyable__RAW;
        #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable

        // Virtual functions:
        // Normally you should call them via the vtable.
        // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
        // or need to create a vtable yourself.

        /// Destructor, you should call JobSystem::DestroyBarrier instead of destructing this object directly
        virtual_Destructor :: (this: *Barrier, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1Barrier@JobSystem@JPH@@MEAA@XZ";
    }
    Barrier_VTable :: struct #type_info_none {
        AddJob:        #type (this: *JobSystem.Barrier, inJob: *JobSystem.JobHandle) -> void #cpp_method;

        AddJobs:       #type (this: *JobSystem.Barrier, inHandles: *JobSystem.JobHandle, inNumHandles: u32) -> void #cpp_method;

        Destructor:    #type (this: *JobSystem.Barrier, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

        OnJobFinished: #type (this: *JobSystem.Barrier, inJob: *JobSystem.Job) -> void #cpp_method;
    }
    Barrier_AddJob :: inline (this: *Barrier, inJob: *JobHandle) { this.vtable.AddJob(this, inJob); }

    Barrier_AddJobs :: inline (this: *Barrier, inHandles: *JobHandle, inNumHandles: u32) { this.vtable.AddJobs(this, inHandles, inNumHandles); }

    Barrier_Destructor :: inline (this: *Barrier, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

    Barrier_OnJobFinished :: inline (this: *Barrier, inJob: *Job) { this.vtable.OnJobFinished(this, inJob); }

    vtable :: (obj: *Barrier) -> *Barrier_VTable { return obj.vtable; }


    /// Main function of the job
    JobFunction :: std.function(#type () -> void #c_call);

    /// A class that contains information for a single unit of work
    Job :: struct {
        /// Constructor
        Constructor :: (this: *Job, inJobName: *u8, inColor: ColorArg, inJobSystem: *JobSystem, inJobFunction: *JobFunction, inNumDependencies: u32) -> void #cpp_method #foreign jolt_release "??0Job@JobSystem@JPH@@QEAA@PEBDVColor@2@PEAV12@AEBV?$function@$$A6AXXZ@std@@I@Z";
        Constructor :: (this: *Job, inJobName: *u8, inColor: ColorArg, inJobSystem: *JobSystem, inJobFunction: JobFunction, inNumDependencies: u32) #no_context {
            Constructor(this, inJobName, inColor, inJobSystem, *inJobFunction, inNumDependencies);
        }

        /// Get the jobs system to which this job belongs
        GetJobSystem :: (this: *Job) -> *JobSystem #cpp_method #foreign jolt_release "?GetJobSystem@Job@JobSystem@JPH@@QEAAPEAV23@XZ";

        /// Add or release a reference to this object
        AddRef :: (this: *Job) -> void #cpp_method #foreign jolt_release "?AddRef@Job@JobSystem@JPH@@QEAAXXZ";

        Release :: (this: *Job) -> void #cpp_method #foreign jolt_release "?Release@Job@JobSystem@JPH@@QEAAXXZ";

        /// Add to the dependency counter.
        AddDependency :: (this: *Job, inCount: s32) -> void #cpp_method #foreign jolt_release "?AddDependency@Job@JobSystem@JPH@@QEAAXH@Z";

        /// Remove from the dependency counter. Returns true whenever the dependency counter reaches zero
        /// and if it does it is no longer valid to call the AddDependency/RemoveDependency functions.
        RemoveDependency :: (this: *Job, inCount: s32) -> bool #cpp_method #foreign jolt_release "?RemoveDependency@Job@JobSystem@JPH@@QEAA_NH@Z";

        /// Remove from the dependency counter. Job will be queued whenever the dependency counter reaches zero
        /// and if it does it is no longer valid to call the AddDependency/RemoveDependency functions.
        RemoveDependencyAndQueue :: (this: *Job, inCount: s32) -> void #cpp_method #foreign jolt_release "?RemoveDependencyAndQueue@Job@JobSystem@JPH@@QEAAXH@Z";

        /// Set the job barrier that this job belongs to and returns false if this was not possible because the job already finished
        SetBarrier :: (this: *Job, inBarrier: *Barrier) -> bool #cpp_method #foreign jolt_release "?SetBarrier@Job@JobSystem@JPH@@QEAA_NPEAVBarrier@23@@Z";

        /// Run the job function, returns the number of dependencies that this job still has or cExecutingState or cDoneState
        Execute :: (this: *Job) -> u32 #cpp_method #foreign jolt_release "?Execute@Job@JobSystem@JPH@@QEAAIXZ";

        /// Test if the job can be executed
        CanBeExecuted :: (this: *Job) -> bool #cpp_method #foreign jolt_release "?CanBeExecuted@Job@JobSystem@JPH@@QEBA_NXZ";

        /// Test if the job finished executing
        IsDone :: (this: *Job) -> bool #cpp_method #foreign jolt_release "?IsDone@Job@JobSystem@JPH@@QEBA_NXZ";

        cExecutingState:   u32 : 3772834016; ///< Value of mNumDependencies when job is executing
        cDoneState:        u32 : 3503345872; ///< Value of mNumDependencies when job is done executing

        cBarrierDoneState: s64 : ~0; ///< Value to use when the barrier has been triggered

        mJobSystem:        *JobSystem; ///< The job system we belong to
        mBarrier:          std.atomic(s64) = 0; ///< Barrier that this job is associated with (is a Barrier pointer)
        mJobFunction:      JobFunction; ///< Main job function
        mReferenceCount:   std.atomic(u32) = 0; ///< Amount of JobHandles pointing to this job
        mNumDependencies:  std.atomic(u32); ///< Amount of jobs that need to complete before this job can run
    }
    #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Destructor
    virtual_Destructor :: (this: *JobSystem, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1JobSystem@JPH@@UEAA@XZ";
}
JobSystem_VTable :: struct #type_info_none {
    Destructor:        #type (this: *JobSystem, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    GetMaxConcurrency: #type (this: *JobSystem) -> s32 #cpp_method;

    CreateJob:         #type (this: *JobSystem, inName: *u8, inColor: ColorArg, inJobFunction: *JobSystem.JobFunction, inNumDependencies: u32 = 0) -> JobSystem.JobHandle #cpp_method #cpp_return_type_is_non_pod;

    CreateBarrier:     #type (this: *JobSystem) -> *JobSystem.Barrier #cpp_method;

    DestroyBarrier:    #type (this: *JobSystem, inBarrier: *JobSystem.Barrier) -> void #cpp_method;

    WaitForJobs:       #type (this: *JobSystem, inBarrier: *JobSystem.Barrier) -> void #cpp_method;

    QueueJob:          #type (this: *JobSystem, inJob: *JobSystem.Job) -> void #cpp_method;

    QueueJobs:         #type (this: *JobSystem, inJobs: **JobSystem.Job, inNumJobs: u32) -> void #cpp_method;

    FreeJob:           #type (this: *JobSystem, inJob: *JobSystem.Job) -> void #cpp_method;
}
JobSystem_Destructor :: inline (this: *JobSystem, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

JobSystem_GetMaxConcurrency :: inline (this: *JobSystem) -> s32 { return this.vtable.GetMaxConcurrency(this); }

JobSystem_CreateJob :: inline (this: *JobSystem, inName: *u8, inColor: ColorArg, inJobFunction: *JobSystem.JobFunction, inNumDependencies: u32 = 0) -> JobSystem.JobHandle { return this.vtable.CreateJob(this, inName, inColor, inJobFunction, inNumDependencies); }

JobSystem_CreateBarrier :: inline (this: *JobSystem) -> *JobSystem.Barrier { return this.vtable.CreateBarrier(this); }

JobSystem_DestroyBarrier :: inline (this: *JobSystem, inBarrier: *JobSystem.Barrier) { this.vtable.DestroyBarrier(this, inBarrier); }

JobSystem_WaitForJobs :: inline (this: *JobSystem, inBarrier: *JobSystem.Barrier) { this.vtable.WaitForJobs(this, inBarrier); }

JobSystem_QueueJob :: inline (this: *JobSystem, inJob: *JobSystem.Job) { this.vtable.QueueJob(this, inJob); }

JobSystem_QueueJobs :: inline (this: *JobSystem, inJobs: **JobSystem.Job, inNumJobs: u32) { this.vtable.QueueJobs(this, inJobs, inNumJobs); }

JobSystem_FreeJob :: inline (this: *JobSystem, inJob: *JobSystem.Job) { this.vtable.FreeJob(this, inJob); }

vtable :: (obj: *JobSystem) -> *JobSystem_VTable { return obj.vtable; }


JobHandle :: JobSystem.JobHandle;

/// Allocator for temporary allocations.
/// This allocator works as a stack: The blocks must always be freed in the reverse order as they are allocated.
/// Note that allocations and frees can take place from different threads, but the order is guaranteed though
/// job dependencies, so it is not needed to use any form of locking.
TempAllocator :: struct {
    vtable:                 *TempAllocator_VTable;
    using noncopyable__raw: NonCopyable__RAW;

    /// If this allocator needs to fall back to aligned allocations because JPH_RVECTOR_ALIGNMENT is bigger than the platform default
    needs_aligned_allocate  :: false;
    #overlay (vtable) #as noncopyable: NonCopyable; // Support cast to NonCopyable

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    /// Destructor
    virtual_Destructor :: (this: *TempAllocator, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method #foreign jolt_release "??1TempAllocator@JPH@@UEAA@XZ";
}
TempAllocator_VTable :: struct #type_info_none {
    Destructor: #type (this: *TempAllocator, flags: Msvc_Destructor_Flags = .NONE) -> void #cpp_method;

    Allocate:   #type (this: *TempAllocator, inSize: u32) -> *void #cpp_method;

    Free:       #type (this: *TempAllocator, inAddress: *void, inSize: u32) -> void #cpp_method;
}
TempAllocator_Destructor :: inline (this: *TempAllocator, flags: Msvc_Destructor_Flags = .NONE) { this.vtable.Destructor(this, flags); }

TempAllocator_Allocate :: inline (this: *TempAllocator, inSize: u32) -> *void { return this.vtable.Allocate(this, inSize); }

TempAllocator_Free :: inline (this: *TempAllocator, inAddress: *void, inSize: u32) { this.vtable.Free(this, inAddress, inSize); }

vtable :: (obj: *TempAllocator) -> *TempAllocator_VTable { return obj.vtable; }


/// Default implementation of the temp allocator that allocates a large block through malloc upfront
TempAllocatorImpl :: struct {
    #as using tempallocator: TempAllocator;

    mBase:                   *u8; ///< Base address of the memory block
    mSize:                   u64; ///< Size of the memory block
    mTop:                    u64 = 0; ///< End of currently allocated area
}

/// Implementation of the TempAllocator that just falls back to malloc/free
/// Note: This can be quite slow when running in the debugger as large memory blocks need to be initialized with 0xcd
TempAllocatorMalloc :: struct {
    #as using tempallocator: TempAllocator;

    // Virtual functions:
    // Normally you should call them via the vtable.
    // But these bindings can be useful if you need to call the parent implementation in a sub-struct’s overwritten method
    // or need to create a vtable yourself.

    // See: TempAllocator
    virtual_Allocate :: (this: *TempAllocatorMalloc, inSize: u32) -> *void #cpp_method #foreign jolt_release "?Allocate@TempAllocatorMalloc@JPH@@UEAAPEAXI@Z";

    // See: TempAllocator
    virtual_Free :: (this: *TempAllocatorMalloc, inAddress: *void, inSize: u32) -> void #cpp_method #foreign jolt_release "?Free@TempAllocatorMalloc@JPH@@UEAAXPEAXI@Z";
}

/// Implementation of the TempAllocator that tries to allocate from a large preallocated block, but falls back to malloc when it is exhausted
TempAllocatorImplWithMallocFallback :: struct {
    #as using tempallocator: TempAllocator;

    mAllocator:              TempAllocatorImpl;
    mFallbackAllocator:      TempAllocatorMalloc;
}

/// STL allocator that wraps around TempAllocator
STLTempAllocator :: struct(T: Type) {
    value_type :: T;

    /// Pointer to type
    pointer :: *T;
    const_pointer :: *T;

    /// Reference to type.
    /// Can be removed in C++20.
    reference :: *T;
    const_reference :: *T;

    size_type :: u64;
    difference_type :: ptrdiff_t;

    /// The allocator is not stateless (depends on the temp allocator)
    is_always_equal :: std.false_type;

    /// Converting to allocator for other type
    rebind :: struct(T2: Type) {
        using,except(T2) rebind__raw:            rebind__RAW(T2);
        #if size_of(rebind__RAW(T2)) == 0 {
            __empty_struct_padding: u8; // C++ makes empty structs have length 1
        }
    }
        // rebind without padding. Needed to generate a C++-equivalent struct layout when "inheriting" from rebind
    rebind__RAW :: struct(T2: Type) {
        other :: STLTempAllocator(T2);
    }

    mAllocator:      *TempAllocator;
}

SoftBodyUpdateContext :: struct {}

/// @cond INTERNAL
/// Internal information used during the PhysicsSystem::Update call
///
/// WARNING: This class is an internal part of PhysicsSystem, it has no functions that can be called by users of the library.
PhysicsUpdateContext :: struct {
    using noncopyable__raw:  NonCopyable__RAW;

    /// Destructor
    Constructor :: (this: *PhysicsUpdateContext, inTempAllocator: *TempAllocator) -> void #cpp_method #foreign jolt_release "??0PhysicsUpdateContext@JPH@@QEAA@AEAVTempAllocator@1@@Z";
    Destructor :: (this: *PhysicsUpdateContext) -> void #cpp_method #foreign jolt_release "??1PhysicsUpdateContext@JPH@@QEAA@XZ";

    cMaxConcurrency:         s32 : 32; ///< Maximum supported amount of concurrent jobs

    JobHandleArray :: StaticArray(JobHandle, xx cMaxConcurrency);

    BodyPairQueue :: struct {
        mWriteIdx: std.atomic(u32) = 0; ///< Next index to write in mBodyPair array (need to add thread index * mMaxBodyPairsPerQueue and modulo mMaxBodyPairsPerQueue)
        mPadding1: [60] u8; ///< Moved to own cache line to avoid conflicts with consumer jobs

        mReadIdx:  std.atomic(u32) = 0; ///< Next index to read in mBodyPair array (need to add thread index * mMaxBodyPairsPerQueue and modulo mMaxBodyPairsPerQueue)
        mPadding2: [60] u8; ///< Moved to own cache line to avoid conflicts with producer/consumer jobs
    }

    BodyPairQueues :: StaticArray(BodyPairQueue, xx cMaxConcurrency);

    JobMask :: u32;

    /// Structure that contains data needed for each collision step.
    Step :: struct {
        Constructor :: (this: *Step) -> void #cpp_method #foreign jolt_release "??0Step@PhysicsUpdateContext@JPH@@QEAA@XZ";
        CopyConstructor :: (this: *Step, unknown0: *Step) -> void #cpp_method #foreign jolt_release "??0Step@PhysicsUpdateContext@JPH@@QEAA@AEBU012@@Z";
        CopyConstructor :: (this: *Step, unknown0: Step) #no_context {
            CopyConstructor(this, *unknown0);
        }

        mContext:                            *PhysicsUpdateContext; ///< The physics update context

        mIsFirst:                            bool; ///< If this is the first step
        mIsLast:                             bool; ///< If this is the last step

        mBroadPhaseUpdateState:              BroadPhase.UpdateState; ///< Handle returned by Broadphase::UpdatePrepare

        mNumActiveBodiesAtStepStart:         u32; ///< Number of bodies that were active at the start of the physics update step. Only these bodies will receive gravity (they are the first N in the active body list).

        mDetermineActiveConstraintReadIdx:   std.atomic(u32) = 0; ///< Next constraint for determine active constraints
        mPadding1:                           [60] u8; ///< Padding to avoid sharing cache line with the next atomic

        mNumActiveConstraints:               std.atomic(u32) = 0; ///< Number of constraints in the mActiveConstraints array
        mPadding2:                           [60] u8; ///< Padding to avoid sharing cache line with the next atomic

        mSetupVelocityConstraintsReadIdx:    std.atomic(u32) = 0; ///< Next constraint for setting up velocity constraints
        mPadding3:                           [60] u8; ///< Padding to avoid sharing cache line with the next atomic

        mStepListenerReadIdx:                std.atomic(u32) = 0; ///< Next step listener to call
        mPadding4:                           [60] u8; ///< Padding to avoid sharing cache line with the next atomic

        mApplyGravityReadIdx:                std.atomic(u32) = 0; ///< Next body to apply gravity to
        mPadding5:                           [60] u8; ///< Padding to avoid sharing cache line with the next atomic

        mActiveBodyReadIdx:                  std.atomic(u32) = 0; ///< Index of fist active body that has not yet been processed by the broadphase
        mPadding6:                           [60] u8; ///< Padding to avoid sharing cache line with the next atomic

        mBodyPairQueues:                     BodyPairQueues; ///< Queues in which to put body pairs that need to be tested by the narrowphase

        mMaxBodyPairsPerQueue:               u32; ///< Amount of body pairs that we can queue per queue

        mActiveFindCollisionJobs:            std.atomic(JobMask); ///< A bitmask that indicates which jobs are still active

        mNumBodyPairs:                       std.atomic(u32) = 0; ///< The number of body pairs found in this step (used to size the contact cache in the next step)
        mNumManifolds:                       std.atomic(u32) = 0; ///< The number of manifolds found in this step (used to size the contact cache in the next step)

        mSolveVelocityConstraintsNextIsland: std.atomic(u32) = 0; ///< Next island that needs to be processed for the solve velocity constraints step (doesn't need own cache line since position jobs don't run at same time)
        mSolvePositionConstraintsNextIsland: std.atomic(u32) = 0; ///< Next island that needs to be processed for the solve position constraints step (doesn't need own cache line since velocity jobs don't run at same time)

        /// Contains the information needed to cast a body through the scene to do continuous collision detection
        CCDBody :: struct {
            Constructor :: (this: *CCDBody, inBodyID1: BodyID, inDeltaPosition: Vec3, inLinearCastThresholdSq: float, inMaxPenetration: float) -> void #cpp_method #foreign jolt_release "??0CCDBody@Step@PhysicsUpdateContext@JPH@@QEAA@VBodyID@3@VVec3@3@MM@Z";

            mDeltaPosition:         Vec3; ///< Desired rotation step
            mContactNormal:         Vec3; ///< World space normal of closest hit (only valid if mFractionPlusSlop < 1)
            mContactPointOn2:       Vec3; ///< World space contact point on body 2 of closest hit (only valid if mFractionPlusSlop < 1)
            mBodyID1:               BodyID; ///< Body 1 (the body that is performing collision detection)
            mBodyID2:               BodyID; ///< Body 2 (the body of the closest hit, only valid if mFractionPlusSlop < 1)
            mSubShapeID2:           SubShapeID; ///< Sub shape of body 2 that was hit (only valid if mFractionPlusSlop < 1)
            mFraction:              float = 1.0; ///< Fraction at which the hit occurred
            mFractionPlusSlop:      float = 1.0; ///< Fraction at which the hit occurred + extra delta to allow body to penetrate by mMaxPenetration
            mLinearCastThresholdSq: float; ///< Maximum allowed squared movement before doing a linear cast (determined by inner radius of shape)
            mMaxPenetration:        float; ///< Maximum allowed penetration (determined by inner radius of shape)
            mContactSettings:       ContactSettings; ///< The contact settings for this contact
        }

        mIntegrateVelocityReadIdx:           std.atomic(u32) = 0; ///< Next active body index to take when integrating velocities
        mCCDBodies:                          *CCDBody = null; ///< List of bodies that need to do continuous collision detection
        mCCDBodiesCapacity:                  u32 = 0; ///< Capacity of the mCCDBodies list
        mNumCCDBodies:                       std.atomic(u32) = 0; ///< Number of CCD bodies in mCCDBodies
        mNextCCDBody:                        std.atomic(u32) = 0; ///< Next unprocessed body index in mCCDBodies
        mActiveBodyToCCDBody:                *s32 = null; ///< A mapping between an index in BodyManager::mActiveBodies and the index in mCCDBodies
        mNumActiveBodyToCCDBody:             u32 = 0; ///< Number of indices in mActiveBodyToCCDBody

        mBroadPhasePrepare:                  JobHandle; ///< Prepares the new tree in the background
        mStepListeners:                      JobHandleArray; ///< Listeners to notify of the beginning of a physics step
        mDetermineActiveConstraints:         JobHandleArray; ///< Determine which constraints will be active during this step
        mApplyGravity:                       JobHandleArray; ///< Update velocities of bodies with gravity
        mFindCollisions:                     JobHandleArray; ///< Find all collisions between active bodies an the world
        mUpdateBroadphaseFinalize:           JobHandle; ///< Swap the newly built tree with the current tree
        mSetupVelocityConstraints:           JobHandleArray; ///< Calculate properties for all constraints in the constraint manager
        mBuildIslandsFromConstraints:        JobHandle; ///< Go over all constraints and assign the bodies they're attached to to an island
        mFinalizeIslands:                    JobHandle; ///< Finalize calculation simulation islands
        mBodySetIslandIndex:                 JobHandle; ///< Set the current island index on each body (not used by the simulation, only for drawing purposes)
        mSolveVelocityConstraints:           JobHandleArray; ///< Solve the constraints in the velocity domain
        mPreIntegrateVelocity:               JobHandle; ///< Setup integration of all body positions
        mIntegrateVelocity:                  JobHandleArray; ///< Integrate all body positions
        mPostIntegrateVelocity:              JobHandle; ///< Finalize integration of all body positions
        mResolveCCDContacts:                 JobHandle; ///< Updates the positions and velocities for all bodies that need continuous collision detection
        mSolvePositionConstraints:           JobHandleArray; ///< Solve all constraints in the position domain
        mContactRemovedCallbacks:            JobHandle; ///< Calls the contact removed callbacks
        mSoftBodyPrepare:                    JobHandle; ///< Prepares updating the soft bodies
        mSoftBodyCollide:                    JobHandleArray; ///< Finds all colliding shapes for soft bodies
        mSoftBodySimulate:                   JobHandleArray; ///< Simulates all particles
        mSoftBodyFinalize:                   JobHandle; ///< Finalizes the soft body update
        mStartNextStep:                      JobHandle; ///< Job that kicks the next step (empty for the last step)
    }

    Steps :: Array(Step, STLTempAllocator(Step));

    /// Maximum amount of concurrent jobs on this machine
    GetMaxConcurrency :: (this: *PhysicsUpdateContext) -> s32 #cpp_method #foreign jolt_release "?GetMaxConcurrency@PhysicsUpdateContext@JPH@@QEBAHXZ";

    mPhysicsSystem:          *PhysicsSystem; ///< The physics system we belong to
    mTempAllocator:          *TempAllocator; ///< Temporary allocator used during the update
    mJobSystem:              *JobSystem; ///< Job system that processes jobs
    mBarrier:                *JobSystem.Barrier; ///< Barrier used to wait for all physics jobs to complete

    mStepDeltaTime:          float; ///< Delta time for a simulation step (collision step)
    mWarmStartImpulseRatio:  float; ///< Ratio of this step delta time vs last step
    mErrors:                 std.atomic(u32) = 0; ///< Errors that occurred during the update, actual type is EPhysicsUpdateError

    mActiveConstraints:      **Constraint = null; ///< Constraints that were active at the start of the physics update step (activating bodies can activate constraints and we need a consistent snapshot). Only these constraints will be resolved.

    mBodyPairs:              *BodyPair = null; ///< A list of body pairs found by the broadphase

    mIslandBuilder:          *IslandBuilder; ///< Keeps track of connected bodies and builds islands for multithreaded velocity/position update

    mSteps:                  Steps;

    mNumSoftBodies:          u32; ///< Number of active soft bodies in the simulation
    mSoftBodyUpdateContexts: *SoftBodyUpdateContext = null; ///< Contexts for updating soft bodies
    mSoftBodyToCollide:      std.atomic(u32) = 0; ///< Next soft body to take when running SoftBodyCollide jobs
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

/// If objects are closer than this distance, they are considered to be colliding (used for GJK) (unit: meter)
cDefaultCollisionTolerance: float : 0.0001;

cDefaultPenetrationTolerance: float : 0.0001; ///< Stop when there's less than 1% change

/// How much padding to add around objects
cDefaultConvexRadius: float : 0.05;

/// Used by (Tapered)CapsuleShape to determine when supporting face is an edge rather than a point (unit: meter)
cCapsuleProjectionSlop: float : 0.02;

/// Maximum amount of jobs to allow
cMaxPhysicsJobs: s32 : 2048;

/// Maximum amount of barriers to allow
cMaxPhysicsBarriers: s32 : 8;

PhysicsSettings :: struct {
    /// Size of body pairs array, corresponds to the maximum amount of potential body pairs that can be in flight at any time.
    /// Setting this to a low value will use less memory but slow down simulation as threads may run out of narrow phase work.
    mMaxInFlightBodyPairs:                 s32 = 16384;

    /// How many PhysicsStepListeners to notify in 1 batch
    mStepListenersBatchSize:               s32 = 8;

    /// How many step listener batches are needed before spawning another job (set to INT_MAX if no parallelism is desired)
    mStepListenerBatchesPerJob:            s32 = 1;

    /// Baumgarte stabilization factor (how much of the position error to 'fix' in 1 update) (unit: dimensionless, 0 = nothing, 1 = 100%)
    mBaumgarte:                            float = 0.2;

    /// Radius around objects inside which speculative contact points will be detected. Note that if this is too big
    /// you will get ghost collisions as speculative contacts are based on the closest points during the collision detection
    /// step which may not be the actual closest points by the time the two objects hit (unit: meters)
    mSpeculativeContactDistance:           float = 0.02;

    /// How much bodies are allowed to sink into each other (unit: meters)
    mPenetrationSlop:                      float = 0.02;

    /// Fraction of its inner radius a body must move per step to enable casting for the LinearCast motion quality
    mLinearCastThreshold:                  float = 0.75;

    /// Fraction of its inner radius a body may penetrate another body for the LinearCast motion quality
    mLinearCastMaxPenetration:             float = 0.25;

    /// Max distance to use to determine if two points are on the same plane for determining the contact manifold between two shape faces (unit: meter)
    mManifoldTolerance:                    float = 0.001;

    /// Maximum distance to correct in a single iteration when solving position constraints (unit: meters)
    mMaxPenetrationDistance:               float = 0.2;

    mBodyPairCacheMaxDeltaPositionSq:      float; ///< 1 mm

    mBodyPairCacheCosMaxDeltaRotationDiv2: float = 0.999848; ///< cos(2 degrees / 2)

    mContactNormalCosMaxDeltaRotation:     float = 0.996195; ///< cos(5 degree)

    mContactPointPreserveLambdaMaxDistSq:  float; ///< 1 cm

    /// Number of solver velocity iterations to run
    /// Note that this needs to be >= 2 in order for friction to work (friction is applied using the non-penetration impulse from the previous iteration)
    mNumVelocitySteps:                     u32 = 10;

    /// Number of solver position iterations to run
    mNumPositionSteps:                     u32 = 2;

    /// Minimal velocity needed before a collision can be elastic. If the relative velocity between colliding objects
    /// in the direction of the contact normal is lower than this, the restitution will be zero regardless of the configured
    /// value. This lets an object settle sooner. Must be a positive number. (unit: m)
    mMinVelocityForRestitution:            float = 1.0;

    /// Time before object is allowed to go to sleep (unit: seconds)
    mTimeBeforeSleep:                      float = 0.5;

    /// To detect if an object is sleeping, we use 3 points:
    /// - The center of mass.
    /// - The centers of the faces of the bounding box that are furthest away from the center.
    /// The movement of these points is tracked and if the velocity of all 3 points is lower than this value,
    /// the object is allowed to go to sleep. Must be a positive number. (unit: m/s)
    mPointVelocitySleepThreshold:          float = 0.03;

    /// By default the simulation is deterministic, it is possible to turn this off by setting this setting to false. This will make the simulation run faster but it will no longer be deterministic.
    mDeterministicSimulation               := true;

    /// Whether or not to use warm starting for constraints (initially applying previous frames impulses)
    mConstraintWarmStart                   := true;

    /// Whether or not to use the body pair cache, which removes the need for narrow phase collision detection when orientation between two bodies didn't change
    mUseBodyPairContactCache               := true;

    /// Whether or not to reduce manifolds with similar contact normals into one contact manifold (see description at Body::SetUseManifoldReduction)
    mUseManifoldReduction                  := true;

    /// If we split up large islands into smaller parallel batches of work (to improve performance)
    mUseLargeIslandSplitter                := true;

    /// If objects can go to sleep or not
    mAllowSleeping                         := true;

    /// When false, we prevent collision against non-active (shared) edges. Mainly for debugging the algorithm.
    mCheckActiveEdges                      := true;
}

PhysicsStepListener :: struct {}
SoftBodyContactListener :: struct {}
SimShapeFilter :: struct {}

/// The main class for the physics system. It contains all rigid bodies and simulates them.
///
/// The main simulation is performed by the Update() call on multiple threads (if the JobSystem is configured to use them). Please refer to the general architecture overview in the Docs folder for more information.
PhysicsSystem :: struct {
    using noncopyable__raw:               NonCopyable__RAW;

    Destructor :: (this: *PhysicsSystem) -> void #cpp_method #foreign jolt_release "??1PhysicsSystem@JPH@@QEAA@XZ";

    /// The maximum value that can be passed to Init for inMaxBodies.
    cMaxBodiesLimit:                      u32 : BodyID.cMaxBodyIndex + 1;

    /// The maximum value that can be passed to Init for inMaxBodyPairs.
    /// Note you should really use a lower value, using this value will cost a lot of memory!
    /// On a 32 bit platform, you'll run out of memory way before you reach this limit.
    cMaxBodyPairsLimit:                   u32 : ContactConstraintManager.cMaxBodyPairsLimit;

    /// The maximum value that can be passed to Init for inMaxContactConstraints.
    /// Note you should really use a lower value, using this value will cost a lot of memory!
    /// On a 32 bit platform, you'll run out of memory way before you reach this limit.
    cMaxContactConstraintsLimit:          u32 : ContactConstraintManager.cMaxContactConstraintsLimit;

    /// Initialize the system.
    /// @param inMaxBodies Maximum number of bodies to support.
    /// @param inNumBodyMutexes Number of body mutexes to use. Should be a power of 2 in the range [1, 64], use 0 to auto detect.
    /// @param inMaxBodyPairs Maximum amount of body pairs to process (anything else will fall through the world), this number should generally be much higher than the max amount of contact points as there will be lots of bodies close that are not actually touching.
    /// @param inMaxContactConstraints Maximum amount of contact constraints to process (anything else will fall through the world).
    /// @param inBroadPhaseLayerInterface Information on the mapping of object layers to broad phase layers. Since this is a virtual interface, the instance needs to stay alive during the lifetime of the PhysicsSystem.
    /// @param inObjectVsBroadPhaseLayerFilter Filter callback function that is used to determine if an object layer collides with a broad phase layer. Since this is a virtual interface, the instance needs to stay alive during the lifetime of the PhysicsSystem.
    /// @param inObjectLayerPairFilter Filter callback function that is used to determine if two object layers collide. Since this is a virtual interface, the instance needs to stay alive during the lifetime of the PhysicsSystem.
    Init :: (this: *PhysicsSystem, inMaxBodies: u32, inNumBodyMutexes: u32, inMaxBodyPairs: u32, inMaxContactConstraints: u32, inBroadPhaseLayerInterface: *BroadPhaseLayerInterface, inObjectVsBroadPhaseLayerFilter: *ObjectVsBroadPhaseLayerFilter, inObjectLayerPairFilter: *ObjectLayerPairFilter) -> void #cpp_method #foreign jolt_release "?Init@PhysicsSystem@JPH@@QEAAXIIIIAEBVBroadPhaseLayerInterface@2@AEBVObjectVsBroadPhaseLayerFilter@2@AEBVObjectLayerPairFilter@2@@Z";
    Init :: (this: *PhysicsSystem, inMaxBodies: u32, inNumBodyMutexes: u32, inMaxBodyPairs: u32, inMaxContactConstraints: u32, inBroadPhaseLayerInterface: BroadPhaseLayerInterface, inObjectVsBroadPhaseLayerFilter: ObjectVsBroadPhaseLayerFilter, inObjectLayerPairFilter: ObjectLayerPairFilter) #no_context {
        Init(this, inMaxBodies, inNumBodyMutexes, inMaxBodyPairs, inMaxContactConstraints, *inBroadPhaseLayerInterface, *inObjectVsBroadPhaseLayerFilter, *inObjectLayerPairFilter);
    }

    GetSoftBodyContactListener :: (this: *PhysicsSystem) -> *SoftBodyContactListener #cpp_method #foreign jolt_release "?GetSoftBodyContactListener@PhysicsSystem@JPH@@QEBAPEAVSoftBodyContactListener@2@XZ";

    GetCombineFriction :: (this: *PhysicsSystem) -> ContactConstraintManager.CombineFunction #cpp_method #foreign jolt_release "?GetCombineFriction@PhysicsSystem@JPH@@QEBAP6AMAEBVBody@2@AEBVSubShapeID@2@01@ZXZ";

    GetCombineRestitution :: (this: *PhysicsSystem) -> ContactConstraintManager.CombineFunction #cpp_method #foreign jolt_release "?GetCombineRestitution@PhysicsSystem@JPH@@QEBAP6AMAEBVBody@2@AEBVSubShapeID@2@01@ZXZ";

    GetSimShapeFilter :: (this: *PhysicsSystem) -> *SimShapeFilter #cpp_method #foreign jolt_release "?GetSimShapeFilter@PhysicsSystem@JPH@@QEBAPEBVSimShapeFilter@2@XZ";

    /// Advanced use only: This function is similar to CollisionDispatch::sCollideShapeVsShape but only used to collide bodies during simulation.
    /// inBody1 The first body to collide.
    /// inBody2 The second body to collide.
    /// inCenterOfMassTransform1 The center of mass transform of the first body (note this will not be the actual world space position of the body, it will be made relative to some position so we can drop down to single precision).
    /// inCenterOfMassTransform2 The center of mass transform of the second body.
    /// ioCollideShapeSettings Settings that control the collision detection. Note that the implementation can freely overwrite the shape settings if needed, the caller provides a temporary that will not be used after the function returns.
    /// ioCollector The collector that will receive the contact points.
    /// inShapeFilter The shape filter that can be used to exclude shapes from colliding with each other.
    SimCollideBodyVsBody :: std.function(#type (inBody1: *Body, inBody2: *Body, inCenterOfMassTransform1: *Mat44, inCenterOfMassTransform2: *Mat44, ioCollideShapeSettings: *CollideShapeSettings, ioCollector: *CollideShapeCollector, inShapeFilter: *ShapeFilter) -> void #c_call);

    /// Advanced use only: Default function that is used to collide two bodies during simulation.
    sDefaultSimCollideBodyVsBody :: (inBody1: *Body, inBody2: *Body, inCenterOfMassTransform1: *Mat44, inCenterOfMassTransform2: *Mat44, ioCollideShapeSettings: *CollideShapeSettings, ioCollector: *CollideShapeCollector, inShapeFilter: *ShapeFilter) -> void #foreign jolt_release "?sDefaultSimCollideBodyVsBody@PhysicsSystem@JPH@@SAXAEBVBody@2@0AEBVMat44@2@1AEAVCollideShapeSettings@2@AEAV?$CollisionCollector@VCollideShapeResult@JPH@@VCollisionCollectorTraitsCollideShape@2@@2@AEBVShapeFilter@2@@Z";
    sDefaultSimCollideBodyVsBody :: (inBody1: Body, inBody2: Body, inCenterOfMassTransform1: *Mat44, inCenterOfMassTransform2: *Mat44, ioCollideShapeSettings: *CollideShapeSettings, ioCollector: *CollideShapeCollector, inShapeFilter: ShapeFilter) #no_context {
        sDefaultSimCollideBodyVsBody(*inBody1, *inBody2, inCenterOfMassTransform1, inCenterOfMassTransform2, ioCollideShapeSettings, ioCollector, *inShapeFilter);
    }

    GetPhysicsSettings :: (this: *PhysicsSystem) -> *PhysicsSettings #cpp_method #foreign jolt_release "?GetPhysicsSettings@PhysicsSystem@JPH@@QEBAAEBUPhysicsSettings@2@XZ";

    GetBodyInterface :: (this: *PhysicsSystem) -> *BodyInterface #cpp_method #foreign jolt_release "?GetBodyInterface@PhysicsSystem@JPH@@QEAAAEAVBodyInterface@2@XZ";

    GetBodyInterfaceNoLock :: (this: *PhysicsSystem) -> *BodyInterface #cpp_method #foreign jolt_release "?GetBodyInterfaceNoLock@PhysicsSystem@JPH@@QEAAAEAVBodyInterface@2@XZ";

    /// Access to the broadphase interface that allows coarse collision queries
    GetBroadPhaseQuery :: (this: *PhysicsSystem) -> *BroadPhaseQuery #cpp_method #foreign jolt_release "?GetBroadPhaseQuery@PhysicsSystem@JPH@@QEBAAEBVBroadPhaseQuery@2@XZ";

    /// Interface that allows fine collision queries against first the broad phase and then the narrow phase.
    GetNarrowPhaseQuery :: (this: *PhysicsSystem) -> *NarrowPhaseQuery #cpp_method #foreign jolt_release "?GetNarrowPhaseQuery@PhysicsSystem@JPH@@QEBAAEBVNarrowPhaseQuery@2@XZ";
    GetNarrowPhaseQueryNoLock :: (this: *PhysicsSystem) -> *NarrowPhaseQuery #cpp_method #foreign jolt_release "?GetNarrowPhaseQueryNoLock@PhysicsSystem@JPH@@QEBAAEBVNarrowPhaseQuery@2@XZ";

    /// Add constraint to the world
    AddConstraint :: (this: *PhysicsSystem, inConstraint: *Constraint) -> void #cpp_method #foreign jolt_release "?AddConstraint@PhysicsSystem@JPH@@QEAAXPEAVConstraint@2@@Z";

    /// Batch add constraints.
    AddConstraints :: (this: *PhysicsSystem, inConstraints: **Constraint, inNumber: s32) -> void #cpp_method #foreign jolt_release "?AddConstraints@PhysicsSystem@JPH@@QEAAXPEAPEAVConstraint@2@H@Z";

    /// Batch remove constraints.
    RemoveConstraints :: (this: *PhysicsSystem, inConstraints: **Constraint, inNumber: s32) -> void #cpp_method #foreign jolt_release "?RemoveConstraints@PhysicsSystem@JPH@@QEAAXPEAPEAVConstraint@2@H@Z";

    /// Get a list of all constraints
    GetConstraints :: (this: *PhysicsSystem) -> Constraints #cpp_method #foreign jolt_release "?GetConstraints@PhysicsSystem@JPH@@QEBA?AV?$Array@V?$Ref@VConstraint@JPH@@@JPH@@V?$STLAllocator@V?$Ref@VConstraint@JPH@@@JPH@@@2@@2@XZ";

    /// Optimize the broadphase, needed only if you've added many bodies prior to calling Update() for the first time.
    /// Don't call this every frame as PhysicsSystem::Update spreads out the same work over multiple frames.
    /// If you add many bodies through BodyInterface::AddBodiesPrepare/AddBodiesFinalize and if the bodies in a batch are
    /// in a roughly unoccupied space (e.g. a new level section) then a call to OptimizeBroadPhase is also not needed
    /// as batch adding creates an efficient bounding volume hierarchy.
    /// Don't call this function while bodies are being modified from another thread or use the locking BodyInterface to modify bodies.
    OptimizeBroadPhase :: (this: *PhysicsSystem) -> void #cpp_method #foreign jolt_release "?OptimizeBroadPhase@PhysicsSystem@JPH@@QEAAXXZ";

    /// Adds a new step listener
    AddStepListener :: (this: *PhysicsSystem, inListener: *PhysicsStepListener) -> void #cpp_method #foreign jolt_release "?AddStepListener@PhysicsSystem@JPH@@QEAAXPEAVPhysicsStepListener@2@@Z";

    /// Removes a step listener
    RemoveStepListener :: (this: *PhysicsSystem, inListener: *PhysicsStepListener) -> void #cpp_method #foreign jolt_release "?RemoveStepListener@PhysicsSystem@JPH@@QEAAXPEAVPhysicsStepListener@2@@Z";

    /// Simulate the system.
    /// The world steps for a total of inDeltaTime seconds. This is divided in inCollisionSteps iterations.
    /// Each iteration consists of collision detection followed by an integration step.
    /// This function internally spawns jobs using inJobSystem and waits for them to complete, so no jobs will be running when this function returns.
    /// The temp allocator is used, for example, to store the list of bodies that are in contact, how they form islands together
    /// and data to solve the contacts between bodies. At the end of the Update call, all allocated memory will have been freed.
    Update :: (this: *PhysicsSystem, inDeltaTime: float, inCollisionSteps: s32, inTempAllocator: *TempAllocator, inJobSystem: *JobSystem) -> EPhysicsUpdateError #cpp_method #foreign jolt_release "?Update@PhysicsSystem@JPH@@QEAA?AW4EPhysicsUpdateError@2@MHPEAVTempAllocator@2@PEAVJobSystem@2@@Z";

    /// Saving state for replay
    SaveState :: (this: *PhysicsSystem, inStream: *StateRecorder, inState: EStateRecorderState = .All, inFilter: *StateRecorderFilter = null) -> void #cpp_method #foreign jolt_release "?SaveState@PhysicsSystem@JPH@@QEBAXAEAVStateRecorder@2@W4EStateRecorderState@2@PEBVStateRecorderFilter@2@@Z";

    /// Restoring state for replay. Returns false if failed.
    RestoreState :: (this: *PhysicsSystem, inStream: *StateRecorder, inFilter: *StateRecorderFilter = null) -> bool #cpp_method #foreign jolt_release "?RestoreState@PhysicsSystem@JPH@@QEAA_NAEAVStateRecorder@2@PEBVStateRecorderFilter@2@@Z";

    /// Saving state of a single body.
    SaveBodyState :: (this: *PhysicsSystem, inBody: *Body, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?SaveBodyState@PhysicsSystem@JPH@@QEBAXAEBVBody@2@AEAVStateRecorder@2@@Z";
    SaveBodyState :: (this: *PhysicsSystem, inBody: Body, inStream: *StateRecorder) #no_context {
        SaveBodyState(this, *inBody, inStream);
    }

    /// Restoring state of a single body.
    RestoreBodyState :: (this: *PhysicsSystem, ioBody: *Body, inStream: *StateRecorder) -> void #cpp_method #foreign jolt_release "?RestoreBodyState@PhysicsSystem@JPH@@QEAAXAEAVBody@2@AEAVStateRecorder@2@@Z";

    GetGravity :: (this: *PhysicsSystem) -> Vec3 #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetGravity@PhysicsSystem@JPH@@QEBA?AVVec3@2@XZ";

    /// Returns a locking interface that won't actually lock the body. Use with great care!
    GetBodyLockInterfaceNoLock :: (this: *PhysicsSystem) -> *BodyLockInterfaceNoLock #cpp_method #foreign jolt_release "?GetBodyLockInterfaceNoLock@PhysicsSystem@JPH@@QEBAAEBVBodyLockInterfaceNoLock@2@XZ";

    /// Returns a locking interface that locks the body so other threads cannot modify it.
    GetBodyLockInterface :: (this: *PhysicsSystem) -> *BodyLockInterfaceLocking #cpp_method #foreign jolt_release "?GetBodyLockInterface@PhysicsSystem@JPH@@QEBAAEBVBodyLockInterfaceLocking@2@XZ";

    /// Get an broadphase layer filter that uses the default pair filter and a specified object layer to determine if broadphase layers collide
    GetDefaultBroadPhaseLayerFilter :: (this: *PhysicsSystem, inLayer: ObjectLayer) -> DefaultBroadPhaseLayerFilter #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetDefaultBroadPhaseLayerFilter@PhysicsSystem@JPH@@QEBA?AVDefaultBroadPhaseLayerFilter@2@G@Z";

    /// Get an object layer filter that uses the default pair filter and a specified layer to determine if layers collide
    GetDefaultLayerFilter :: (this: *PhysicsSystem, inLayer: ObjectLayer) -> DefaultObjectLayerFilter #cpp_method #cpp_return_type_is_non_pod #foreign jolt_release "?GetDefaultLayerFilter@PhysicsSystem@JPH@@QEBA?AVDefaultObjectLayerFilter@2@G@Z";

    /// Helper struct that counts the number of bodies of each type
    BodyStats :: BodyManager.BodyStats;

    /// Get copy of the list of all bodies under protection of a lock.
    /// @param outBodyIDs On return, this will contain the list of BodyIDs
    GetBodies :: (this: *PhysicsSystem, outBodyIDs: *BodyIDVector) -> void #cpp_method #foreign jolt_release "?GetBodies@PhysicsSystem@JPH@@QEBAXAEAV?$Array@VBodyID@JPH@@V?$STLAllocator@VBodyID@JPH@@@2@@2@@Z";

    CCDBody :: PhysicsUpdateContext.Step.CCDBody;

    // Various job entry points
    JobStepListeners :: (this: *PhysicsSystem, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobStepListeners@PhysicsSystem@JPH@@AEAAXPEAUStep@PhysicsUpdateContext@2@@Z";
    JobDetermineActiveConstraints :: (this: *PhysicsSystem, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobDetermineActiveConstraints@PhysicsSystem@JPH@@AEBAXPEAUStep@PhysicsUpdateContext@2@@Z";
    JobApplyGravity :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobApplyGravity@PhysicsSystem@JPH@@AEAAXPEBVPhysicsUpdateContext@2@PEAUStep@32@@Z";
    JobSetupVelocityConstraints :: (this: *PhysicsSystem, inDeltaTime: float, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobSetupVelocityConstraints@PhysicsSystem@JPH@@AEBAXMPEAUStep@PhysicsUpdateContext@2@@Z";
    JobBuildIslandsFromConstraints :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobBuildIslandsFromConstraints@PhysicsSystem@JPH@@AEAAXPEAVPhysicsUpdateContext@2@PEAUStep@32@@Z";
    JobFindCollisions :: (this: *PhysicsSystem, ioStep: *PhysicsUpdateContext.Step, inJobIndex: s32) -> void #cpp_method #foreign jolt_release "?JobFindCollisions@PhysicsSystem@JPH@@AEAAXPEAUStep@PhysicsUpdateContext@2@H@Z";
    JobFinalizeIslands :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext) -> void #cpp_method #foreign jolt_release "?JobFinalizeIslands@PhysicsSystem@JPH@@AEAAXPEAVPhysicsUpdateContext@2@@Z";
    JobBodySetIslandIndex :: (this: *PhysicsSystem) -> void #cpp_method #foreign jolt_release "?JobBodySetIslandIndex@PhysicsSystem@JPH@@AEAAXXZ";
    JobSolveVelocityConstraints :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobSolveVelocityConstraints@PhysicsSystem@JPH@@AEAAXPEAVPhysicsUpdateContext@2@PEAUStep@32@@Z";
    JobPreIntegrateVelocity :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobPreIntegrateVelocity@PhysicsSystem@JPH@@AEAAXPEAVPhysicsUpdateContext@2@PEAUStep@32@@Z";
    JobIntegrateVelocity :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobIntegrateVelocity@PhysicsSystem@JPH@@AEAAXPEBVPhysicsUpdateContext@2@PEAUStep@32@@Z";
    JobPostIntegrateVelocity :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobPostIntegrateVelocity@PhysicsSystem@JPH@@AEBAXPEAVPhysicsUpdateContext@2@PEAUStep@32@@Z";
    JobFindCCDContacts :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobFindCCDContacts@PhysicsSystem@JPH@@AEAAXPEBVPhysicsUpdateContext@2@PEAUStep@32@@Z";
    JobResolveCCDContacts :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobResolveCCDContacts@PhysicsSystem@JPH@@AEAAXPEAVPhysicsUpdateContext@2@PEAUStep@32@@Z";
    JobContactRemovedCallbacks :: (this: *PhysicsSystem, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobContactRemovedCallbacks@PhysicsSystem@JPH@@AEAAXPEBUStep@PhysicsUpdateContext@2@@Z";
    JobSolvePositionConstraints :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobSolvePositionConstraints@PhysicsSystem@JPH@@AEAAXPEAVPhysicsUpdateContext@2@PEAUStep@32@@Z";
    JobSoftBodyPrepare :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?JobSoftBodyPrepare@PhysicsSystem@JPH@@AEAAXPEAVPhysicsUpdateContext@2@PEAUStep@32@@Z";
    JobSoftBodyCollide :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext) -> void #cpp_method #foreign jolt_release "?JobSoftBodyCollide@PhysicsSystem@JPH@@AEBAXPEAVPhysicsUpdateContext@2@@Z";
    JobSoftBodySimulate :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext, inThreadIndex: u32) -> void #cpp_method #foreign jolt_release "?JobSoftBodySimulate@PhysicsSystem@JPH@@AEBAXPEAVPhysicsUpdateContext@2@I@Z";
    JobSoftBodyFinalize :: (this: *PhysicsSystem, ioContext: *PhysicsUpdateContext) -> void #cpp_method #foreign jolt_release "?JobSoftBodyFinalize@PhysicsSystem@JPH@@AEAAXPEAVPhysicsUpdateContext@2@@Z";

    /// Tries to spawn a new FindCollisions job if max concurrency hasn't been reached yet
    TrySpawnJobFindCollisions :: (this: *PhysicsSystem, ioStep: *PhysicsUpdateContext.Step) -> void #cpp_method #foreign jolt_release "?TrySpawnJobFindCollisions@PhysicsSystem@JPH@@AEBAXPEAUStep@PhysicsUpdateContext@2@@Z";

    ContactAllocator :: ContactConstraintManager.ContactAllocator;

    /// Process narrow phase for a single body pair
    ProcessBodyPair :: (this: *PhysicsSystem, ioContactAllocator: *ContactAllocator, inBodyPair: *BodyPair) -> void #cpp_method #foreign jolt_release "?ProcessBodyPair@PhysicsSystem@JPH@@AEAAXAEAVContactAllocator@ContactConstraintManager@2@AEBUBodyPair@2@@Z";
    ProcessBodyPair :: (this: *PhysicsSystem, ioContactAllocator: *ContactAllocator, inBodyPair: BodyPair) #no_context {
        ProcessBodyPair(this, ioContactAllocator, *inBodyPair);
    }

    /// This helper batches up bodies that need to put to sleep to avoid contention on the activation mutex
    BodiesToSleep :: struct {}

    /// Called at the end of JobSolveVelocityConstraints to check if bodies need to go to sleep and to update their bounding box in the broadphase
    CheckSleepAndUpdateBounds :: (this: *PhysicsSystem, inIslandIndex: u32, ioContext: *PhysicsUpdateContext, ioStep: *PhysicsUpdateContext.Step, ioBodiesToSleep: *BodiesToSleep) -> void #cpp_method #foreign jolt_release "?CheckSleepAndUpdateBounds@PhysicsSystem@JPH@@AEAAXIPEBVPhysicsUpdateContext@2@PEBUStep@32@AEAVBodiesToSleep@12@@Z";

    /// Number of constraints to process at once in JobDetermineActiveConstraints
    cDetermineActiveConstraintsBatchSize: s32 : 64;

    /// Number of constraints to process at once in JobSetupVelocityConstraints, we want a low number of threads working on this so we take fairly large batches
    cSetupVelocityConstraintsBatchSize:   s32 : 256;

    /// Number of bodies to process at once in JobApplyGravity
    cApplyGravityBatchSize:               s32 : 64;

    /// Number of active bodies to test for collisions per batch
    cActiveBodiesBatchSize:               s32 : 16;

    /// Number of active bodies to integrate velocities for
    cIntegrateVelocityBatchSize:          s32 : 64;

    /// Number of contacts that need to be queued before another narrow phase job is started
    cNarrowPhaseBatchSize:                s32 : 16;

    /// Number of continuous collision shape casts that need to be queued before another job is started
    cNumCCDBodiesPerJob:                  s32 : 4;

    /// Broadphase layer filter that decides if two objects can collide
    mObjectVsBroadPhaseLayerFilter:       *ObjectVsBroadPhaseLayerFilter = null;

    /// Object layer filter that decides if two objects can collide
    mObjectLayerPairFilter:               *ObjectLayerPairFilter = null;

    /// The body manager keeps track which bodies are in the simulation
    mBodyManager:                         BodyManager;

    /// Body locking interfaces
    mBodyLockInterfaceNoLock:             BodyLockInterfaceNoLock;
    mBodyLockInterfaceLocking:            BodyLockInterfaceLocking;

    /// Body interfaces
    mBodyInterfaceNoLock:                 BodyInterface;
    mBodyInterfaceLocking:                BodyInterface;

    /// Narrow phase query interface
    mNarrowPhaseQueryNoLock:              NarrowPhaseQuery;
    mNarrowPhaseQueryLocking:             NarrowPhaseQuery;

    /// The broadphase does quick collision detection between body pairs
    mBroadPhase:                          *BroadPhase = null;

    /// The soft body contact listener
    mSoftBodyContactListener:             *SoftBodyContactListener = null;

    /// The shape filter that is used to filter out sub shapes during simulation
    mSimShapeFilter:                      *SimShapeFilter = null;

    /// The collision function that is used to collide two shapes during simulation
    mSimCollideBodyVsBody:                SimCollideBodyVsBody;

    /// Simulation settings
    mPhysicsSettings:                     PhysicsSettings;

    /// The contact manager resolves all contacts during a simulation step
    mContactManager:                      ContactConstraintManager;

    /// All non-contact constraints
    mConstraintManager:                   ConstraintManager;

    /// Keeps track of connected bodies and builds islands for multithreaded velocity/position update
    mIslandBuilder:                       IslandBuilder;

    /// Will split large islands into smaller groups of bodies that can be processed in parallel
    mLargeIslandSplitter:                 LargeIslandSplitter;

    /// Mutex protecting mStepListeners
    mStepListenersMutex:                  Mutex;

    /// List of physics step listeners
    StepListeners :: Array(*PhysicsStepListener);
    mStepListeners:                       StepListeners;

    /// This is the global gravity vector
    mGravity:                             Vec3 = .{0, -9.81, 0};

    /// Previous frame's delta time of one sub step to allow scaling previous frame's constraint impulses
    mPreviousStepDeltaTime:               float = 0.0;
    #overlay (noncopyable__raw) #as noncopyable: NonCopyable; // Support cast to NonCopyable
}

//
// #elsewhere declarations that were moved out of namespaces / structs:
//


// User defined allocation / free functions
Allocate: AllocateFunction #elsewhere jolt_release "?Allocate@JPH@@3P6APEAX_K@ZEA";
Reallocate: ReallocateFunction #elsewhere jolt_release "?Reallocate@JPH@@3P6APEAXPEAX_K1@ZEA";
Free: FreeFunction #elsewhere jolt_release "?Free@JPH@@3P6AXPEAX@ZEA";
AlignedAllocate: AlignedAllocateFunction #elsewhere jolt_release "?AlignedAllocate@JPH@@3P6APEAX_K0@ZEA";
AlignedFree: AlignedFreeFunction #elsewhere jolt_release "?AlignedFree@JPH@@3P6AXPEAX@ZEA";

Trace: TraceFunction #elsewhere jolt_release "?Trace@JPH@@3P6AXPEBDZZEA";

/// Predefined colors
Color_sBlack: Color #elsewhere jolt_release "?sBlack@Color@JPH@@2V12@B";
Color_sDarkRed: Color #elsewhere jolt_release "?sDarkRed@Color@JPH@@2V12@B";
Color_sRed: Color #elsewhere jolt_release "?sRed@Color@JPH@@2V12@B";
Color_sDarkGreen: Color #elsewhere jolt_release "?sDarkGreen@Color@JPH@@2V12@B";
Color_sGreen: Color #elsewhere jolt_release "?sGreen@Color@JPH@@2V12@B";
Color_sDarkBlue: Color #elsewhere jolt_release "?sDarkBlue@Color@JPH@@2V12@B";
Color_sBlue: Color #elsewhere jolt_release "?sBlue@Color@JPH@@2V12@B";
Color_sYellow: Color #elsewhere jolt_release "?sYellow@Color@JPH@@2V12@B";
Color_sPurple: Color #elsewhere jolt_release "?sPurple@Color@JPH@@2V12@B";
Color_sCyan: Color #elsewhere jolt_release "?sCyan@Color@JPH@@2V12@B";
Color_sOrange: Color #elsewhere jolt_release "?sOrange@Color@JPH@@2V12@B";
Color_sDarkOrange: Color #elsewhere jolt_release "?sDarkOrange@Color@JPH@@2V12@B";
Color_sGrey: Color #elsewhere jolt_release "?sGrey@Color@JPH@@2V12@B";
Color_sLightGrey: Color #elsewhere jolt_release "?sLightGrey@Color@JPH@@2V12@B";
Color_sWhite: Color #elsewhere jolt_release "?sWhite@Color@JPH@@2V12@B";

/// Singleton factory instance
Factory_sInstance: *Factory #elsewhere jolt_release "?sInstance@Factory@JPH@@2PEAV12@EA";

ShapeFunctions_sRegistry: [34] ShapeFunctions #elsewhere jolt_release "?sRegistry@ShapeFunctions@JPH@@0PAV12@A";

/// An invalid collision group
CollisionGroup_sInvalid: CollisionGroup #elsewhere jolt_release "?sInvalid@CollisionGroup@JPH@@2V12@B";

/// A dummy body that can be used by constraints to attach a constraint to the world instead of another body
Body_sFixedToWorld: Body #elsewhere jolt_release "?sFixedToWorld@Body@JPH@@2V12@A";

/// Default material that is used when a shape has no materials defined
PhysicsMaterial_sDefault: RefConst(PhysicsMaterial) #elsewhere jolt_release "?sDefault@PhysicsMaterial@JPH@@2V?$RefConst@VPhysicsMaterial@JPH@@@2@A";

#scope_file

#import "Basic"; // For assert, push_context

jolt_release :: #library,no_dll "windows/Jolt_Release";

#run {
    assert(size_of(AssertLastParam) == 1, "AssertLastParam has size % instead of 1", size_of(AssertLastParam));

    {
        info := type_info(BodyID);
        for info.members {
            if it.name == {
                case "mID";
                    assert(it.offset_in_bytes == 0, "BodyID.mID has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyID.mID has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(BodyID) == 4, "BodyID has size % instead of 4", size_of(BodyID));
    }

    assert(size_of(NonCopyable) == 1, "NonCopyable has size % instead of 1", size_of(NonCopyable));

    {
        info := type_info(ObjectLayerFilter);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "ObjectLayerFilter.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "ObjectLayerFilter.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(ObjectLayerFilter) == 8, "ObjectLayerFilter has size % instead of 8", size_of(ObjectLayerFilter));
    }

    {
        info := type_info(ObjectLayerPairFilter);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "ObjectLayerPairFilter.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "ObjectLayerPairFilter.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(ObjectLayerPairFilter) == 8, "ObjectLayerPairFilter has size % instead of 8", size_of(ObjectLayerPairFilter));
    }

    {
        info := type_info(DefaultObjectLayerFilter);
        for info.members {
            if it.name == {
                case "objectlayerfilter";
                    assert(it.offset_in_bytes == 0, "DefaultObjectLayerFilter.objectlayerfilter has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "DefaultObjectLayerFilter.objectlayerfilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mObjectLayerPairFilter";
                    assert(it.offset_in_bytes == 8, "DefaultObjectLayerFilter.mObjectLayerPairFilter has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "DefaultObjectLayerFilter.mObjectLayerPairFilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mLayer";
                    assert(it.offset_in_bytes == 16, "DefaultObjectLayerFilter.mLayer has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 2, "DefaultObjectLayerFilter.mLayer has unexpected size % instead of 2", it.type.runtime_size);
            }
        }
        assert(size_of(DefaultObjectLayerFilter) == 24, "DefaultObjectLayerFilter has size % instead of 24", size_of(DefaultObjectLayerFilter));
    }

    {
        info := type_info(SpecifiedObjectLayerFilter);
        for info.members {
            if it.name == {
                case "objectlayerfilter";
                    assert(it.offset_in_bytes == 0, "SpecifiedObjectLayerFilter.objectlayerfilter has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "SpecifiedObjectLayerFilter.objectlayerfilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mLayer";
                    assert(it.offset_in_bytes == 8, "SpecifiedObjectLayerFilter.mLayer has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 2, "SpecifiedObjectLayerFilter.mLayer has unexpected size % instead of 2", it.type.runtime_size);
            }
        }
        assert(size_of(SpecifiedObjectLayerFilter) == 16, "SpecifiedObjectLayerFilter has size % instead of 16", size_of(SpecifiedObjectLayerFilter));
    }

    assert(size_of(RefTargetVirtual) == 8, "RefTargetVirtual has size % instead of 8", size_of(RefTargetVirtual));

    {
        info := type_info(BodyInterface);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "BodyInterface.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "BodyInterface.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mBodyLockInterface";
                    assert(it.offset_in_bytes == 0, "BodyInterface.mBodyLockInterface has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "BodyInterface.mBodyLockInterface has unexpected size % instead of 8", it.type.runtime_size);
                case "mBodyManager";
                    assert(it.offset_in_bytes == 8, "BodyInterface.mBodyManager has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "BodyInterface.mBodyManager has unexpected size % instead of 8", it.type.runtime_size);
                case "mBroadPhase";
                    assert(it.offset_in_bytes == 16, "BodyInterface.mBroadPhase has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "BodyInterface.mBroadPhase has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(BodyInterface) == 24, "BodyInterface has size % instead of 24", size_of(BodyInterface));
    }

    {
        info := type_info(BodyFilter);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "BodyFilter.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "BodyFilter.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(BodyFilter) == 8, "BodyFilter has size % instead of 8", size_of(BodyFilter));
    }

    {
        info := type_info(IgnoreSingleBodyFilter);
        for info.members {
            if it.name == {
                case "bodyfilter";
                    assert(it.offset_in_bytes == 0, "IgnoreSingleBodyFilter.bodyfilter has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IgnoreSingleBodyFilter.bodyfilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mBodyID";
                    assert(it.offset_in_bytes == 8, "IgnoreSingleBodyFilter.mBodyID has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IgnoreSingleBodyFilter.mBodyID has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(IgnoreSingleBodyFilter) == 16, "IgnoreSingleBodyFilter has size % instead of 16", size_of(IgnoreSingleBodyFilter));
    }

    {
        info := type_info(IgnoreMultipleBodiesFilter);
        for info.members {
            if it.name == {
                case "bodyfilter";
                    assert(it.offset_in_bytes == 0, "IgnoreMultipleBodiesFilter.bodyfilter has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IgnoreMultipleBodiesFilter.bodyfilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mBodyIDs";
                    assert(it.offset_in_bytes == 8, "IgnoreMultipleBodiesFilter.mBodyIDs has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "IgnoreMultipleBodiesFilter.mBodyIDs has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(IgnoreMultipleBodiesFilter) == 32, "IgnoreMultipleBodiesFilter has size % instead of 32", size_of(IgnoreMultipleBodiesFilter));
    }

    {
        info := type_info(IgnoreSingleBodyFilterChained);
        for info.members {
            if it.name == {
                case "bodyfilter";
                    assert(it.offset_in_bytes == 0, "IgnoreSingleBodyFilterChained.bodyfilter has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IgnoreSingleBodyFilterChained.bodyfilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mBodyID";
                    assert(it.offset_in_bytes == 8, "IgnoreSingleBodyFilterChained.mBodyID has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IgnoreSingleBodyFilterChained.mBodyID has unexpected size % instead of 4", it.type.runtime_size);
                case "mFilter";
                    assert(it.offset_in_bytes == 16, "IgnoreSingleBodyFilterChained.mFilter has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IgnoreSingleBodyFilterChained.mFilter has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(IgnoreSingleBodyFilterChained) == 24, "IgnoreSingleBodyFilterChained has size % instead of 24", size_of(IgnoreSingleBodyFilterChained));
    }

    {
        info := type_info(Triangle);
        for info.members {
            if it.name == {
                case "mV";
                    assert(it.offset_in_bytes == 0, "Triangle.mV has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 36, "Triangle.mV has unexpected size % instead of 36", it.type.runtime_size);
                case "mMaterialIndex";
                    assert(it.offset_in_bytes == 36, "Triangle.mMaterialIndex has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Triangle.mMaterialIndex has unexpected size % instead of 4", it.type.runtime_size);
                case "mUserData";
                    assert(it.offset_in_bytes == 40, "Triangle.mUserData has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Triangle.mUserData has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(Triangle) == 44, "Triangle has size % instead of 44", size_of(Triangle));
    }

    {
        info := type_info(IndexedTriangleNoMaterial);
        for info.members {
            if it.name == {
                case "mIdx";
                    assert(it.offset_in_bytes == 0, "IndexedTriangleNoMaterial.mIdx has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "IndexedTriangleNoMaterial.mIdx has unexpected size % instead of 12", it.type.runtime_size);
            }
        }
        assert(size_of(IndexedTriangleNoMaterial) == 12, "IndexedTriangleNoMaterial has size % instead of 12", size_of(IndexedTriangleNoMaterial));
    }

    {
        info := type_info(IndexedTriangle);
        for info.members {
            if it.name == {
                case "indexedtrianglenomaterial";
                    assert(it.offset_in_bytes == 0, "IndexedTriangle.indexedtrianglenomaterial has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "IndexedTriangle.indexedtrianglenomaterial has unexpected size % instead of 12", it.type.runtime_size);
                case "mMaterialIndex";
                    assert(it.offset_in_bytes == 12, "IndexedTriangle.mMaterialIndex has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IndexedTriangle.mMaterialIndex has unexpected size % instead of 4", it.type.runtime_size);
                case "mUserData";
                    assert(it.offset_in_bytes == 16, "IndexedTriangle.mUserData has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IndexedTriangle.mUserData has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(IndexedTriangle) == 20, "IndexedTriangle has size % instead of 20", size_of(IndexedTriangle));
    }

    {
        info := type_info(Plane);
        for info.members {
            if it.name == {
                case "mNormalAndConstant";
                    assert(it.offset_in_bytes == 0, "Plane.mNormalAndConstant has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "Plane.mNormalAndConstant has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(Plane) == 16, "Plane has size % instead of 16", size_of(Plane));
    }

    {
        info := type_info(AABox);
        for info.members {
            if it.name == {
                case "mMin";
                    assert(it.offset_in_bytes == 0, "AABox.mMin has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "AABox.mMin has unexpected size % instead of 16", it.type.runtime_size);
                case "mMax";
                    assert(it.offset_in_bytes == 16, "AABox.mMax has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "AABox.mMax has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(AABox) == 32, "AABox has size % instead of 32", size_of(AABox));
    }

    {
        info := type_info(RTTI.BaseClass);
        for info.members {
            if it.name == {
                case "mRTTI";
                    assert(it.offset_in_bytes == 0, "RTTI.BaseClass.mRTTI has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "RTTI.BaseClass.mRTTI has unexpected size % instead of 8", it.type.runtime_size);
                case "mOffset";
                    assert(it.offset_in_bytes == 8, "RTTI.BaseClass.mOffset has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "RTTI.BaseClass.mOffset has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(RTTI.BaseClass) == 16, "RTTI.BaseClass has size % instead of 16", size_of(RTTI.BaseClass));
    }

    {
        info := type_info(RTTI);
        for info.members {
            if it.name == {
                case "mName";
                    assert(it.offset_in_bytes == 0, "RTTI.mName has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "RTTI.mName has unexpected size % instead of 8", it.type.runtime_size);
                case "mSize";
                    assert(it.offset_in_bytes == 8, "RTTI.mSize has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "RTTI.mSize has unexpected size % instead of 4", it.type.runtime_size);
                case "mBaseClasses";
                    assert(it.offset_in_bytes == 16, "RTTI.mBaseClasses has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 72, "RTTI.mBaseClasses has unexpected size % instead of 72", it.type.runtime_size);
                case "mCreate";
                    assert(it.offset_in_bytes == 88, "RTTI.mCreate has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "RTTI.mCreate has unexpected size % instead of 8", it.type.runtime_size);
                case "mDestruct";
                    assert(it.offset_in_bytes == 96, "RTTI.mDestruct has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "RTTI.mDestruct has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(RTTI) == 104, "RTTI has size % instead of 104", size_of(RTTI));
    }

    assert(size_of(SerializableObject) == 8, "SerializableObject has size % instead of 8", size_of(SerializableObject));

    {
        info := type_info(MassProperties);
        for info.members {
            if it.name == {
                case "mMass";
                    assert(it.offset_in_bytes == 0, "MassProperties.mMass has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "MassProperties.mMass has unexpected size % instead of 4", it.type.runtime_size);
                case "mInertia";
                    assert(it.offset_in_bytes == 16, "MassProperties.mInertia has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "MassProperties.mInertia has unexpected size % instead of 64", it.type.runtime_size);
            }
        }
        assert(size_of(MassProperties) == 80, "MassProperties has size % instead of 80", size_of(MassProperties));
    }

    assert(size_of(CollisionCollectorTraitsCastRay) == 1, "CollisionCollectorTraitsCastRay has size % instead of 1", size_of(CollisionCollectorTraitsCastRay));

    assert(size_of(CollisionCollectorTraitsCastShape) == 1, "CollisionCollectorTraitsCastShape has size % instead of 1", size_of(CollisionCollectorTraitsCastShape));

    assert(size_of(CollisionCollectorTraitsCollideShape) == 1, "CollisionCollectorTraitsCollideShape has size % instead of 1", size_of(CollisionCollectorTraitsCollideShape));

    {
        info := type_info(ShapeFilter);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "ShapeFilter.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "ShapeFilter.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mBodyID2";
                    assert(it.offset_in_bytes == 8, "ShapeFilter.mBodyID2 has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ShapeFilter.mBodyID2 has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(ShapeFilter) == 16, "ShapeFilter has size % instead of 16", size_of(ShapeFilter));
    }

    {
        info := type_info(ReversedShapeFilter);
        for info.members {
            if it.name == {
                case "shapefilter";
                    assert(it.offset_in_bytes == 0, "ReversedShapeFilter.shapefilter has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "ReversedShapeFilter.shapefilter has unexpected size % instead of 16", it.type.runtime_size);
                case "mFilter";
                    assert(it.offset_in_bytes == 16, "ReversedShapeFilter.mFilter has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ReversedShapeFilter.mFilter has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(ReversedShapeFilter) == 24, "ReversedShapeFilter has size % instead of 24", size_of(ReversedShapeFilter));
    }

    assert(size_of(Color) == 4, "Color has size % instead of 4", size_of(Color));

    assert(size_of(BVec16) == 16, "BVec16 has size % instead of 16", size_of(BVec16));

    {
        info := type_info(StreamIn);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "StreamIn.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "StreamIn.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(StreamIn) == 8, "StreamIn has size % instead of 8", size_of(StreamIn));
    }

    {
        info := type_info(StreamOut);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "StreamOut.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "StreamOut.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(StreamOut) == 8, "StreamOut has size % instead of 8", size_of(StreamOut));
    }

    {
        info := type_info(Factory);
        for info.members {
            if it.name == {
                case "mClassHashMap";
                    assert(it.offset_in_bytes == 32, "Factory.mClassHashMap has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "Factory.mClassHashMap has unexpected size % instead of 32", it.type.runtime_size);
            }
        }
        assert(size_of(Factory) == 64, "Factory has size % instead of 64", size_of(Factory));
    }

    {
        info := type_info(ShapeSettings);
        for info.members {
            if it.name == {
                case "serializableobject";
                    assert(it.offset_in_bytes == 0, "ShapeSettings.serializableobject has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ShapeSettings.serializableobject has unexpected size % instead of 8", it.type.runtime_size);
                case "reftarget";
                    assert(it.offset_in_bytes == 8, "ShapeSettings.reftarget has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ShapeSettings.reftarget has unexpected size % instead of 4", it.type.runtime_size);
                case "mUserData";
                    assert(it.offset_in_bytes == 16, "ShapeSettings.mUserData has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ShapeSettings.mUserData has unexpected size % instead of 8", it.type.runtime_size);
                case "mCachedResult";
                    assert(it.offset_in_bytes == 24, "ShapeSettings.mCachedResult has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 40, "ShapeSettings.mCachedResult has unexpected size % instead of 40", it.type.runtime_size);
            }
        }
        assert(size_of(ShapeSettings) == 64, "ShapeSettings has size % instead of 64", size_of(ShapeSettings));
    }

    {
        info := type_info(ShapeFunctions);
        for info.members {
            if it.name == {
                case "mConstruct";
                    assert(it.offset_in_bytes == 0, "ShapeFunctions.mConstruct has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ShapeFunctions.mConstruct has unexpected size % instead of 8", it.type.runtime_size);
                case "mColor";
                    assert(it.offset_in_bytes == 8, "ShapeFunctions.mColor has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ShapeFunctions.mColor has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(ShapeFunctions) == 16, "ShapeFunctions has size % instead of 16", size_of(ShapeFunctions));
    }

    {
        info := type_info(Shape.GetTrianglesContext);
        for info.members {
            if it.name == {
                case "mData";
                    assert(it.offset_in_bytes == 0, "Shape.GetTrianglesContext.mData has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4288, "Shape.GetTrianglesContext.mData has unexpected size % instead of 4288", it.type.runtime_size);
            }
        }
        assert(size_of(Shape.GetTrianglesContext) == 4288, "Shape.GetTrianglesContext has size % instead of 4288", size_of(Shape.GetTrianglesContext));
    }

    {
        info := type_info(Shape.Stats);
        for info.members {
            if it.name == {
                case "mSizeBytes";
                    assert(it.offset_in_bytes == 0, "Shape.Stats.mSizeBytes has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "Shape.Stats.mSizeBytes has unexpected size % instead of 8", it.type.runtime_size);
                case "mNumTriangles";
                    assert(it.offset_in_bytes == 8, "Shape.Stats.mNumTriangles has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Shape.Stats.mNumTriangles has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(Shape.Stats) == 16, "Shape.Stats has size % instead of 16", size_of(Shape.Stats));
    }

    {
        info := type_info(Shape);
        for info.members {
            if it.name == {
                case "reftarget";
                    assert(it.offset_in_bytes == 8, "Shape.reftarget has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Shape.reftarget has unexpected size % instead of 4", it.type.runtime_size);
                case "noncopyable";
                    assert(it.offset_in_bytes == 12, "Shape.noncopyable has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "Shape.noncopyable has unexpected size % instead of 1", it.type.runtime_size);
                case "mUserData";
                    assert(it.offset_in_bytes == 16, "Shape.mUserData has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "Shape.mUserData has unexpected size % instead of 8", it.type.runtime_size);
                case "mShapeType";
                    assert(it.offset_in_bytes == 24, "Shape.mShapeType has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "Shape.mShapeType has unexpected size % instead of 1", it.type.runtime_size);
                case "mShapeSubType";
                    assert(it.offset_in_bytes == 25, "Shape.mShapeSubType has unexpected offset % instead of 25", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "Shape.mShapeSubType has unexpected size % instead of 1", it.type.runtime_size);
            }
        }
        assert(size_of(Shape) == 32, "Shape has size % instead of 32", size_of(Shape));
    }

    {
        info := type_info(BroadPhaseLayer);
        for info.members {
            if it.name == {
                case "mValue";
                    assert(it.offset_in_bytes == 0, "BroadPhaseLayer.mValue has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "BroadPhaseLayer.mValue has unexpected size % instead of 1", it.type.runtime_size);
            }
        }
        assert(size_of(BroadPhaseLayer) == 1, "BroadPhaseLayer has size % instead of 1", size_of(BroadPhaseLayer));
    }

    {
        info := type_info(BroadPhaseLayerInterface);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "BroadPhaseLayerInterface.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "BroadPhaseLayerInterface.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(BroadPhaseLayerInterface) == 8, "BroadPhaseLayerInterface has size % instead of 8", size_of(BroadPhaseLayerInterface));
    }

    {
        info := type_info(ObjectVsBroadPhaseLayerFilter);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "ObjectVsBroadPhaseLayerFilter.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "ObjectVsBroadPhaseLayerFilter.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(ObjectVsBroadPhaseLayerFilter) == 8, "ObjectVsBroadPhaseLayerFilter has size % instead of 8", size_of(ObjectVsBroadPhaseLayerFilter));
    }

    {
        info := type_info(BroadPhaseLayerFilter);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "BroadPhaseLayerFilter.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "BroadPhaseLayerFilter.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(BroadPhaseLayerFilter) == 8, "BroadPhaseLayerFilter has size % instead of 8", size_of(BroadPhaseLayerFilter));
    }

    {
        info := type_info(DefaultBroadPhaseLayerFilter);
        for info.members {
            if it.name == {
                case "broadphaselayerfilter";
                    assert(it.offset_in_bytes == 0, "DefaultBroadPhaseLayerFilter.broadphaselayerfilter has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "DefaultBroadPhaseLayerFilter.broadphaselayerfilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mObjectVsBroadPhaseLayerFilter";
                    assert(it.offset_in_bytes == 8, "DefaultBroadPhaseLayerFilter.mObjectVsBroadPhaseLayerFilter has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "DefaultBroadPhaseLayerFilter.mObjectVsBroadPhaseLayerFilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mLayer";
                    assert(it.offset_in_bytes == 16, "DefaultBroadPhaseLayerFilter.mLayer has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 2, "DefaultBroadPhaseLayerFilter.mLayer has unexpected size % instead of 2", it.type.runtime_size);
            }
        }
        assert(size_of(DefaultBroadPhaseLayerFilter) == 24, "DefaultBroadPhaseLayerFilter has size % instead of 24", size_of(DefaultBroadPhaseLayerFilter));
    }

    {
        info := type_info(SpecifiedBroadPhaseLayerFilter);
        for info.members {
            if it.name == {
                case "broadphaselayerfilter";
                    assert(it.offset_in_bytes == 0, "SpecifiedBroadPhaseLayerFilter.broadphaselayerfilter has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "SpecifiedBroadPhaseLayerFilter.broadphaselayerfilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mLayer";
                    assert(it.offset_in_bytes == 8, "SpecifiedBroadPhaseLayerFilter.mLayer has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "SpecifiedBroadPhaseLayerFilter.mLayer has unexpected size % instead of 1", it.type.runtime_size);
            }
        }
        assert(size_of(SpecifiedBroadPhaseLayerFilter) == 16, "SpecifiedBroadPhaseLayerFilter has size % instead of 16", size_of(SpecifiedBroadPhaseLayerFilter));
    }

    {
        info := type_info(GroupFilter);
        for info.members {
            if it.name == {
                case "serializableobject";
                    assert(it.offset_in_bytes == 0, "GroupFilter.serializableobject has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "GroupFilter.serializableobject has unexpected size % instead of 8", it.type.runtime_size);
                case "reftarget";
                    assert(it.offset_in_bytes == 8, "GroupFilter.reftarget has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "GroupFilter.reftarget has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(GroupFilter) == 16, "GroupFilter has size % instead of 16", size_of(GroupFilter));
    }

    {
        info := type_info(CollisionGroup);
        for info.members {
            if it.name == {
                case "mGroupFilter";
                    assert(it.offset_in_bytes == 0, "CollisionGroup.mGroupFilter has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "CollisionGroup.mGroupFilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mGroupID";
                    assert(it.offset_in_bytes == 8, "CollisionGroup.mGroupID has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "CollisionGroup.mGroupID has unexpected size % instead of 4", it.type.runtime_size);
                case "mSubGroupID";
                    assert(it.offset_in_bytes == 12, "CollisionGroup.mSubGroupID has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "CollisionGroup.mSubGroupID has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(CollisionGroup) == 16, "CollisionGroup has size % instead of 16", size_of(CollisionGroup));
    }

    {
        info := type_info(SubShapeID);
        for info.members {
            if it.name == {
                case "mValue";
                    assert(it.offset_in_bytes == 0, "SubShapeID.mValue has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "SubShapeID.mValue has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(SubShapeID) == 4, "SubShapeID has size % instead of 4", size_of(SubShapeID));
    }

    {
        info := type_info(SubShapeIDCreator);
        for info.members {
            if it.name == {
                case "mID";
                    assert(it.offset_in_bytes == 0, "SubShapeIDCreator.mID has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "SubShapeIDCreator.mID has unexpected size % instead of 4", it.type.runtime_size);
                case "mCurrentBit";
                    assert(it.offset_in_bytes == 4, "SubShapeIDCreator.mCurrentBit has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "SubShapeIDCreator.mCurrentBit has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(SubShapeIDCreator) == 8, "SubShapeIDCreator has size % instead of 8", size_of(SubShapeIDCreator));
    }

    {
        info := type_info(TransformedShape);
        for info.members {
            if it.name == {
                case "mShapePositionCOM";
                    assert(it.offset_in_bytes == 0, "TransformedShape.mShapePositionCOM has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "TransformedShape.mShapePositionCOM has unexpected size % instead of 16", it.type.runtime_size);
                case "mShapeRotation";
                    assert(it.offset_in_bytes == 16, "TransformedShape.mShapeRotation has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "TransformedShape.mShapeRotation has unexpected size % instead of 16", it.type.runtime_size);
                case "mShape";
                    assert(it.offset_in_bytes == 32, "TransformedShape.mShape has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "TransformedShape.mShape has unexpected size % instead of 8", it.type.runtime_size);
                case "mShapeScale";
                    assert(it.offset_in_bytes == 40, "TransformedShape.mShapeScale has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "TransformedShape.mShapeScale has unexpected size % instead of 12", it.type.runtime_size);
                case "mBodyID";
                    assert(it.offset_in_bytes == 52, "TransformedShape.mBodyID has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "TransformedShape.mBodyID has unexpected size % instead of 4", it.type.runtime_size);
                case "mSubShapeIDCreator";
                    assert(it.offset_in_bytes == 56, "TransformedShape.mSubShapeIDCreator has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "TransformedShape.mSubShapeIDCreator has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(TransformedShape) == 64, "TransformedShape has size % instead of 64", size_of(TransformedShape));
    }

    {
        info := type_info(Sphere);
        for info.members {
            if it.name == {
                case "mCenter";
                    assert(it.offset_in_bytes == 0, "Sphere.mCenter has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "Sphere.mCenter has unexpected size % instead of 12", it.type.runtime_size);
                case "mRadius";
                    assert(it.offset_in_bytes == 12, "Sphere.mRadius has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Sphere.mRadius has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(Sphere) == 16, "Sphere has size % instead of 16", size_of(Sphere));
    }

    assert(size_of(BodyAccess.Grant) == 1, "BodyAccess.Grant has size % instead of 1", size_of(BodyAccess.Grant));

    assert(size_of(BodyAccess) == 1, "BodyAccess has size % instead of 1", size_of(BodyAccess));

    {
        info := type_info(MotionProperties);
        for info.members {
            if it.name == {
                case "mLinearVelocity";
                    assert(it.offset_in_bytes == 0, "MotionProperties.mLinearVelocity has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "MotionProperties.mLinearVelocity has unexpected size % instead of 16", it.type.runtime_size);
                case "mAngularVelocity";
                    assert(it.offset_in_bytes == 16, "MotionProperties.mAngularVelocity has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "MotionProperties.mAngularVelocity has unexpected size % instead of 16", it.type.runtime_size);
                case "mInvInertiaDiagonal";
                    assert(it.offset_in_bytes == 32, "MotionProperties.mInvInertiaDiagonal has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "MotionProperties.mInvInertiaDiagonal has unexpected size % instead of 16", it.type.runtime_size);
                case "mInertiaRotation";
                    assert(it.offset_in_bytes == 48, "MotionProperties.mInertiaRotation has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "MotionProperties.mInertiaRotation has unexpected size % instead of 16", it.type.runtime_size);
                case "mForce";
                    assert(it.offset_in_bytes == 64, "MotionProperties.mForce has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "MotionProperties.mForce has unexpected size % instead of 12", it.type.runtime_size);
                case "mTorque";
                    assert(it.offset_in_bytes == 76, "MotionProperties.mTorque has unexpected offset % instead of 76", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "MotionProperties.mTorque has unexpected size % instead of 12", it.type.runtime_size);
                case "mInvMass";
                    assert(it.offset_in_bytes == 88, "MotionProperties.mInvMass has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "MotionProperties.mInvMass has unexpected size % instead of 4", it.type.runtime_size);
                case "mLinearDamping";
                    assert(it.offset_in_bytes == 92, "MotionProperties.mLinearDamping has unexpected offset % instead of 92", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "MotionProperties.mLinearDamping has unexpected size % instead of 4", it.type.runtime_size);
                case "mAngularDamping";
                    assert(it.offset_in_bytes == 96, "MotionProperties.mAngularDamping has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "MotionProperties.mAngularDamping has unexpected size % instead of 4", it.type.runtime_size);
                case "mMaxLinearVelocity";
                    assert(it.offset_in_bytes == 100, "MotionProperties.mMaxLinearVelocity has unexpected offset % instead of 100", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "MotionProperties.mMaxLinearVelocity has unexpected size % instead of 4", it.type.runtime_size);
                case "mMaxAngularVelocity";
                    assert(it.offset_in_bytes == 104, "MotionProperties.mMaxAngularVelocity has unexpected offset % instead of 104", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "MotionProperties.mMaxAngularVelocity has unexpected size % instead of 4", it.type.runtime_size);
                case "mGravityFactor";
                    assert(it.offset_in_bytes == 108, "MotionProperties.mGravityFactor has unexpected offset % instead of 108", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "MotionProperties.mGravityFactor has unexpected size % instead of 4", it.type.runtime_size);
                case "mIndexInActiveBodies";
                    assert(it.offset_in_bytes == 112, "MotionProperties.mIndexInActiveBodies has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "MotionProperties.mIndexInActiveBodies has unexpected size % instead of 4", it.type.runtime_size);
                case "mIslandIndex";
                    assert(it.offset_in_bytes == 116, "MotionProperties.mIslandIndex has unexpected offset % instead of 116", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "MotionProperties.mIslandIndex has unexpected size % instead of 4", it.type.runtime_size);
                case "mMotionQuality";
                    assert(it.offset_in_bytes == 120, "MotionProperties.mMotionQuality has unexpected offset % instead of 120", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "MotionProperties.mMotionQuality has unexpected size % instead of 1", it.type.runtime_size);
                case "mAllowSleeping";
                    assert(it.offset_in_bytes == 121, "MotionProperties.mAllowSleeping has unexpected offset % instead of 121", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "MotionProperties.mAllowSleeping has unexpected size % instead of 1", it.type.runtime_size);
                case "mAllowedDOFs";
                    assert(it.offset_in_bytes == 122, "MotionProperties.mAllowedDOFs has unexpected offset % instead of 122", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "MotionProperties.mAllowedDOFs has unexpected size % instead of 1", it.type.runtime_size);
                case "mNumVelocityStepsOverride";
                    assert(it.offset_in_bytes == 123, "MotionProperties.mNumVelocityStepsOverride has unexpected offset % instead of 123", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "MotionProperties.mNumVelocityStepsOverride has unexpected size % instead of 1", it.type.runtime_size);
                case "mNumPositionStepsOverride";
                    assert(it.offset_in_bytes == 124, "MotionProperties.mNumPositionStepsOverride has unexpected offset % instead of 124", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "MotionProperties.mNumPositionStepsOverride has unexpected size % instead of 1", it.type.runtime_size);
                case "mSleepTestSpheres";
                    assert(it.offset_in_bytes == 128, "MotionProperties.mSleepTestSpheres has unexpected offset % instead of 128", it.offset_in_bytes);
                    assert(it.type.runtime_size == 48, "MotionProperties.mSleepTestSpheres has unexpected size % instead of 48", it.type.runtime_size);
                case "mSleepTestTimer";
                    assert(it.offset_in_bytes == 176, "MotionProperties.mSleepTestTimer has unexpected offset % instead of 176", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "MotionProperties.mSleepTestTimer has unexpected size % instead of 4", it.type.runtime_size);
                case "mCachedBodyType";
                    assert(it.offset_in_bytes == 180, "MotionProperties.mCachedBodyType has unexpected offset % instead of 180", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "MotionProperties.mCachedBodyType has unexpected size % instead of 1", it.type.runtime_size);
                case "mCachedMotionType";
                    assert(it.offset_in_bytes == 181, "MotionProperties.mCachedMotionType has unexpected offset % instead of 181", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "MotionProperties.mCachedMotionType has unexpected size % instead of 1", it.type.runtime_size);
            }
        }
        assert(size_of(MotionProperties) == 192, "MotionProperties has size % instead of 192", size_of(MotionProperties));
    }

    {
        info := type_info(Body);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "Body.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "Body.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mPosition";
                    assert(it.offset_in_bytes == 0, "Body.mPosition has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "Body.mPosition has unexpected size % instead of 16", it.type.runtime_size);
                case "mRotation";
                    assert(it.offset_in_bytes == 16, "Body.mRotation has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "Body.mRotation has unexpected size % instead of 16", it.type.runtime_size);
                case "mBounds";
                    assert(it.offset_in_bytes == 32, "Body.mBounds has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "Body.mBounds has unexpected size % instead of 32", it.type.runtime_size);
                case "mShape";
                    assert(it.offset_in_bytes == 64, "Body.mShape has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "Body.mShape has unexpected size % instead of 8", it.type.runtime_size);
                case "mMotionProperties";
                    assert(it.offset_in_bytes == 72, "Body.mMotionProperties has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "Body.mMotionProperties has unexpected size % instead of 8", it.type.runtime_size);
                case "mUserData";
                    assert(it.offset_in_bytes == 80, "Body.mUserData has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "Body.mUserData has unexpected size % instead of 8", it.type.runtime_size);
                case "mCollisionGroup";
                    assert(it.offset_in_bytes == 88, "Body.mCollisionGroup has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "Body.mCollisionGroup has unexpected size % instead of 16", it.type.runtime_size);
                case "mFriction";
                    assert(it.offset_in_bytes == 104, "Body.mFriction has unexpected offset % instead of 104", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Body.mFriction has unexpected size % instead of 4", it.type.runtime_size);
                case "mRestitution";
                    assert(it.offset_in_bytes == 108, "Body.mRestitution has unexpected offset % instead of 108", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Body.mRestitution has unexpected size % instead of 4", it.type.runtime_size);
                case "mID";
                    assert(it.offset_in_bytes == 112, "Body.mID has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Body.mID has unexpected size % instead of 4", it.type.runtime_size);
                case "mObjectLayer";
                    assert(it.offset_in_bytes == 116, "Body.mObjectLayer has unexpected offset % instead of 116", it.offset_in_bytes);
                    assert(it.type.runtime_size == 2, "Body.mObjectLayer has unexpected size % instead of 2", it.type.runtime_size);
                case "mBodyType";
                    assert(it.offset_in_bytes == 118, "Body.mBodyType has unexpected offset % instead of 118", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "Body.mBodyType has unexpected size % instead of 1", it.type.runtime_size);
                case "mBroadPhaseLayer";
                    assert(it.offset_in_bytes == 119, "Body.mBroadPhaseLayer has unexpected offset % instead of 119", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "Body.mBroadPhaseLayer has unexpected size % instead of 1", it.type.runtime_size);
                case "mMotionType";
                    assert(it.offset_in_bytes == 120, "Body.mMotionType has unexpected offset % instead of 120", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "Body.mMotionType has unexpected size % instead of 1", it.type.runtime_size);
                case "mFlags";
                    assert(it.offset_in_bytes == 121, "Body.mFlags has unexpected offset % instead of 121", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "Body.mFlags has unexpected size % instead of 1", it.type.runtime_size);
            }
        }
        assert(size_of(Body) == 128, "Body has size % instead of 128", size_of(Body));
    }

    {
        info := type_info(Mutex);
        for info.members {
            if it.name == {
                case "mutexbase";
                    assert(it.offset_in_bytes == 0, "Mutex.mutexbase has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 80, "Mutex.mutexbase has unexpected size % instead of 80", it.type.runtime_size);
                case "mLockedThreadID";
                    assert(it.offset_in_bytes == 80, "Mutex.mLockedThreadID has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Mutex.mLockedThreadID has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(Mutex) == 88, "Mutex has size % instead of 88", size_of(Mutex));
    }

    {
        info := type_info(SharedMutex);
        for info.members {
            if it.name == {
                case "sharedmutexbase";
                    assert(it.offset_in_bytes == 0, "SharedMutex.sharedmutexbase has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "SharedMutex.sharedmutexbase has unexpected size % instead of 8", it.type.runtime_size);
                case "mLockedThreadID";
                    assert(it.offset_in_bytes == 8, "SharedMutex.mLockedThreadID has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "SharedMutex.mLockedThreadID has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(SharedMutex) == 16, "SharedMutex has size % instead of 16", size_of(SharedMutex));
    }

    {
        info := type_info(BodyManager.BodyStats);
        for info.members {
            if it.name == {
                case "mNumBodies";
                    assert(it.offset_in_bytes == 0, "BodyManager.BodyStats.mNumBodies has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyManager.BodyStats.mNumBodies has unexpected size % instead of 4", it.type.runtime_size);
                case "mMaxBodies";
                    assert(it.offset_in_bytes == 4, "BodyManager.BodyStats.mMaxBodies has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyManager.BodyStats.mMaxBodies has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumBodiesStatic";
                    assert(it.offset_in_bytes == 8, "BodyManager.BodyStats.mNumBodiesStatic has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyManager.BodyStats.mNumBodiesStatic has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumBodiesDynamic";
                    assert(it.offset_in_bytes == 12, "BodyManager.BodyStats.mNumBodiesDynamic has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyManager.BodyStats.mNumBodiesDynamic has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumActiveBodiesDynamic";
                    assert(it.offset_in_bytes == 16, "BodyManager.BodyStats.mNumActiveBodiesDynamic has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyManager.BodyStats.mNumActiveBodiesDynamic has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumBodiesKinematic";
                    assert(it.offset_in_bytes == 20, "BodyManager.BodyStats.mNumBodiesKinematic has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyManager.BodyStats.mNumBodiesKinematic has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumActiveBodiesKinematic";
                    assert(it.offset_in_bytes == 24, "BodyManager.BodyStats.mNumActiveBodiesKinematic has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyManager.BodyStats.mNumActiveBodiesKinematic has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumSoftBodies";
                    assert(it.offset_in_bytes == 28, "BodyManager.BodyStats.mNumSoftBodies has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyManager.BodyStats.mNumSoftBodies has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumActiveSoftBodies";
                    assert(it.offset_in_bytes == 32, "BodyManager.BodyStats.mNumActiveSoftBodies has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyManager.BodyStats.mNumActiveSoftBodies has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(BodyManager.BodyStats) == 36, "BodyManager.BodyStats has size % instead of 36", size_of(BodyManager.BodyStats));
    }

    assert(size_of(BodyManager.GrantActiveBodiesAccess) == 1, "BodyManager.GrantActiveBodiesAccess has size % instead of 1", size_of(BodyManager.GrantActiveBodiesAccess));

    {
        info := type_info(BodyManager);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "BodyManager.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "BodyManager.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mBodies";
                    assert(it.offset_in_bytes == 0, "BodyManager.mBodies has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "BodyManager.mBodies has unexpected size % instead of 24", it.type.runtime_size);
                case "mNumBodies";
                    assert(it.offset_in_bytes == 24, "BodyManager.mNumBodies has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyManager.mNumBodies has unexpected size % instead of 4", it.type.runtime_size);
                case "mBodyIDFreeListStart";
                    assert(it.offset_in_bytes == 32, "BodyManager.mBodyIDFreeListStart has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "BodyManager.mBodyIDFreeListStart has unexpected size % instead of 8", it.type.runtime_size);
                case "mBodiesMutex";
                    assert(it.offset_in_bytes == 40, "BodyManager.mBodiesMutex has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 88, "BodyManager.mBodiesMutex has unexpected size % instead of 88", it.type.runtime_size);
                case "mBodyMutexes";
                    assert(it.offset_in_bytes == 128, "BodyManager.mBodyMutexes has unexpected offset % instead of 128", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "BodyManager.mBodyMutexes has unexpected size % instead of 16", it.type.runtime_size);
                case "mBodySequenceNumbers";
                    assert(it.offset_in_bytes == 144, "BodyManager.mBodySequenceNumbers has unexpected offset % instead of 144", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "BodyManager.mBodySequenceNumbers has unexpected size % instead of 24", it.type.runtime_size);
                case "mActiveBodiesMutex";
                    assert(it.offset_in_bytes == 168, "BodyManager.mActiveBodiesMutex has unexpected offset % instead of 168", it.offset_in_bytes);
                    assert(it.type.runtime_size == 88, "BodyManager.mActiveBodiesMutex has unexpected size % instead of 88", it.type.runtime_size);
                case "mActiveBodies";
                    assert(it.offset_in_bytes == 256, "BodyManager.mActiveBodies has unexpected offset % instead of 256", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "BodyManager.mActiveBodies has unexpected size % instead of 16", it.type.runtime_size);
                case "mNumActiveBodies";
                    assert(it.offset_in_bytes == 272, "BodyManager.mNumActiveBodies has unexpected offset % instead of 272", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "BodyManager.mNumActiveBodies has unexpected size % instead of 8", it.type.runtime_size);
                case "mNumActiveCCDBodies";
                    assert(it.offset_in_bytes == 280, "BodyManager.mNumActiveCCDBodies has unexpected offset % instead of 280", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyManager.mNumActiveCCDBodies has unexpected size % instead of 4", it.type.runtime_size);
                case "mBodiesCacheInvalidMutex";
                    assert(it.offset_in_bytes == 288, "BodyManager.mBodiesCacheInvalidMutex has unexpected offset % instead of 288", it.offset_in_bytes);
                    assert(it.type.runtime_size == 88, "BodyManager.mBodiesCacheInvalidMutex has unexpected size % instead of 88", it.type.runtime_size);
                case "mBodiesCacheInvalid";
                    assert(it.offset_in_bytes == 376, "BodyManager.mBodiesCacheInvalid has unexpected offset % instead of 376", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "BodyManager.mBodiesCacheInvalid has unexpected size % instead of 24", it.type.runtime_size);
                case "mActivationListener";
                    assert(it.offset_in_bytes == 400, "BodyManager.mActivationListener has unexpected offset % instead of 400", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "BodyManager.mActivationListener has unexpected size % instead of 8", it.type.runtime_size);
                case "mBroadPhaseLayerInterface";
                    assert(it.offset_in_bytes == 408, "BodyManager.mBroadPhaseLayerInterface has unexpected offset % instead of 408", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "BodyManager.mBroadPhaseLayerInterface has unexpected size % instead of 8", it.type.runtime_size);
                case "mActiveBodiesLocked";
                    assert(it.offset_in_bytes == 416, "BodyManager.mActiveBodiesLocked has unexpected offset % instead of 416", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "BodyManager.mActiveBodiesLocked has unexpected size % instead of 1", it.type.runtime_size);
            }
        }
        assert(size_of(BodyManager) == 424, "BodyManager has size % instead of 424", size_of(BodyManager));
    }

    {
        info := type_info(PhysicsLock.LockData);
        for info.members {
            if it.name == {
                case "mLockedMutexes";
                    assert(it.offset_in_bytes == 0, "PhysicsLock.LockData.mLockedMutexes has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsLock.LockData.mLockedMutexes has unexpected size % instead of 4", it.type.runtime_size);
                case "mContext";
                    assert(it.offset_in_bytes == 8, "PhysicsLock.LockData.mContext has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsLock.LockData.mContext has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(PhysicsLock.LockData) == 16, "PhysicsLock.LockData has size % instead of 16", size_of(PhysicsLock.LockData));
    }

    assert(size_of(PhysicsLock) == 1, "PhysicsLock has size % instead of 1", size_of(PhysicsLock));

    {
        info := type_info(BodyLockInterface);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "BodyLockInterface.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "BodyLockInterface.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mBodyManager";
                    assert(it.offset_in_bytes == 8, "BodyLockInterface.mBodyManager has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "BodyLockInterface.mBodyManager has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(BodyLockInterface) == 16, "BodyLockInterface has size % instead of 16", size_of(BodyLockInterface));
    }

    {
        info := type_info(BodyLockInterfaceNoLock);
        for info.members {
            if it.name == {
                case "bodylockinterface";
                    assert(it.offset_in_bytes == 0, "BodyLockInterfaceNoLock.bodylockinterface has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "BodyLockInterfaceNoLock.bodylockinterface has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(BodyLockInterfaceNoLock) == 16, "BodyLockInterfaceNoLock has size % instead of 16", size_of(BodyLockInterfaceNoLock));
    }

    {
        info := type_info(BodyLockInterfaceLocking);
        for info.members {
            if it.name == {
                case "bodylockinterface";
                    assert(it.offset_in_bytes == 0, "BodyLockInterfaceLocking.bodylockinterface has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "BodyLockInterfaceLocking.bodylockinterface has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(BodyLockInterfaceLocking) == 16, "BodyLockInterfaceLocking has size % instead of 16", size_of(BodyLockInterfaceLocking));
    }

    {
        info := type_info(BodyLockRead);
        for info.members {
            if it.name == {
                case "bodylockbase";
                    assert(it.offset_in_bytes == 0, "BodyLockRead.bodylockbase has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "BodyLockRead.bodylockbase has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(BodyLockRead) == 24, "BodyLockRead has size % instead of 24", size_of(BodyLockRead));
    }

    {
        info := type_info(BodyLockWrite);
        for info.members {
            if it.name == {
                case "bodylockbase";
                    assert(it.offset_in_bytes == 0, "BodyLockWrite.bodylockbase has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "BodyLockWrite.bodylockbase has unexpected size % instead of 24", it.type.runtime_size);
            }
        }
        assert(size_of(BodyLockWrite) == 24, "BodyLockWrite has size % instead of 24", size_of(BodyLockWrite));
    }

    {
        info := type_info(BroadPhaseQuery);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "BroadPhaseQuery.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "BroadPhaseQuery.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(BroadPhaseQuery) == 8, "BroadPhaseQuery has size % instead of 8", size_of(BroadPhaseQuery));
    }

    {
        info := type_info(NarrowPhaseQuery);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "NarrowPhaseQuery.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "NarrowPhaseQuery.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mBodyLockInterface";
                    assert(it.offset_in_bytes == 0, "NarrowPhaseQuery.mBodyLockInterface has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "NarrowPhaseQuery.mBodyLockInterface has unexpected size % instead of 8", it.type.runtime_size);
                case "mBroadPhaseQuery";
                    assert(it.offset_in_bytes == 8, "NarrowPhaseQuery.mBroadPhaseQuery has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "NarrowPhaseQuery.mBroadPhaseQuery has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(NarrowPhaseQuery) == 16, "NarrowPhaseQuery has size % instead of 16", size_of(NarrowPhaseQuery));
    }

    {
        info := type_info(SubShapeIDPair);
        for info.members {
            if it.name == {
                case "mBody1ID";
                    assert(it.offset_in_bytes == 0, "SubShapeIDPair.mBody1ID has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "SubShapeIDPair.mBody1ID has unexpected size % instead of 4", it.type.runtime_size);
                case "mSubShapeID1";
                    assert(it.offset_in_bytes == 4, "SubShapeIDPair.mSubShapeID1 has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "SubShapeIDPair.mSubShapeID1 has unexpected size % instead of 4", it.type.runtime_size);
                case "mBody2ID";
                    assert(it.offset_in_bytes == 8, "SubShapeIDPair.mBody2ID has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "SubShapeIDPair.mBody2ID has unexpected size % instead of 4", it.type.runtime_size);
                case "mSubShapeID2";
                    assert(it.offset_in_bytes == 12, "SubShapeIDPair.mSubShapeID2 has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "SubShapeIDPair.mSubShapeID2 has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(SubShapeIDPair) == 16, "SubShapeIDPair has size % instead of 16", size_of(SubShapeIDPair));
    }

    {
        info := type_info(ContactManifold);
        for info.members {
            if it.name == {
                case "mBaseOffset";
                    assert(it.offset_in_bytes == 0, "ContactManifold.mBaseOffset has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "ContactManifold.mBaseOffset has unexpected size % instead of 16", it.type.runtime_size);
                case "mWorldSpaceNormal";
                    assert(it.offset_in_bytes == 16, "ContactManifold.mWorldSpaceNormal has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "ContactManifold.mWorldSpaceNormal has unexpected size % instead of 16", it.type.runtime_size);
                case "mPenetrationDepth";
                    assert(it.offset_in_bytes == 32, "ContactManifold.mPenetrationDepth has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactManifold.mPenetrationDepth has unexpected size % instead of 4", it.type.runtime_size);
                case "mSubShapeID1";
                    assert(it.offset_in_bytes == 36, "ContactManifold.mSubShapeID1 has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactManifold.mSubShapeID1 has unexpected size % instead of 4", it.type.runtime_size);
                case "mSubShapeID2";
                    assert(it.offset_in_bytes == 40, "ContactManifold.mSubShapeID2 has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactManifold.mSubShapeID2 has unexpected size % instead of 4", it.type.runtime_size);
                case "mRelativeContactPointsOn1";
                    assert(it.offset_in_bytes == 48, "ContactManifold.mRelativeContactPointsOn1 has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1040, "ContactManifold.mRelativeContactPointsOn1 has unexpected size % instead of 1040", it.type.runtime_size);
                case "mRelativeContactPointsOn2";
                    assert(it.offset_in_bytes == 1088, "ContactManifold.mRelativeContactPointsOn2 has unexpected offset % instead of 1088", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1040, "ContactManifold.mRelativeContactPointsOn2 has unexpected size % instead of 1040", it.type.runtime_size);
            }
        }
        assert(size_of(ContactManifold) == 2128, "ContactManifold has size % instead of 2128", size_of(ContactManifold));
    }

    {
        info := type_info(ContactSettings);
        for info.members {
            if it.name == {
                case "mCombinedFriction";
                    assert(it.offset_in_bytes == 0, "ContactSettings.mCombinedFriction has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactSettings.mCombinedFriction has unexpected size % instead of 4", it.type.runtime_size);
                case "mCombinedRestitution";
                    assert(it.offset_in_bytes == 4, "ContactSettings.mCombinedRestitution has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactSettings.mCombinedRestitution has unexpected size % instead of 4", it.type.runtime_size);
                case "mInvMassScale1";
                    assert(it.offset_in_bytes == 8, "ContactSettings.mInvMassScale1 has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactSettings.mInvMassScale1 has unexpected size % instead of 4", it.type.runtime_size);
                case "mInvInertiaScale1";
                    assert(it.offset_in_bytes == 12, "ContactSettings.mInvInertiaScale1 has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactSettings.mInvInertiaScale1 has unexpected size % instead of 4", it.type.runtime_size);
                case "mInvMassScale2";
                    assert(it.offset_in_bytes == 16, "ContactSettings.mInvMassScale2 has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactSettings.mInvMassScale2 has unexpected size % instead of 4", it.type.runtime_size);
                case "mInvInertiaScale2";
                    assert(it.offset_in_bytes == 20, "ContactSettings.mInvInertiaScale2 has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactSettings.mInvInertiaScale2 has unexpected size % instead of 4", it.type.runtime_size);
                case "mIsSensor";
                    assert(it.offset_in_bytes == 24, "ContactSettings.mIsSensor has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "ContactSettings.mIsSensor has unexpected size % instead of 1", it.type.runtime_size);
                case "mRelativeLinearSurfaceVelocity";
                    assert(it.offset_in_bytes == 32, "ContactSettings.mRelativeLinearSurfaceVelocity has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "ContactSettings.mRelativeLinearSurfaceVelocity has unexpected size % instead of 16", it.type.runtime_size);
                case "mRelativeAngularSurfaceVelocity";
                    assert(it.offset_in_bytes == 48, "ContactSettings.mRelativeAngularSurfaceVelocity has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "ContactSettings.mRelativeAngularSurfaceVelocity has unexpected size % instead of 16", it.type.runtime_size);
            }
        }
        assert(size_of(ContactSettings) == 64, "ContactSettings has size % instead of 64", size_of(ContactSettings));
    }

    assert(size_of(ContactListener) == 8, "ContactListener has size % instead of 8", size_of(ContactListener));

    {
        info := type_info(LFHMAllocator);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "LFHMAllocator.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "LFHMAllocator.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mObjectStore";
                    assert(it.offset_in_bytes == 0, "LFHMAllocator.mObjectStore has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "LFHMAllocator.mObjectStore has unexpected size % instead of 8", it.type.runtime_size);
                case "mObjectStoreSizeBytes";
                    assert(it.offset_in_bytes == 8, "LFHMAllocator.mObjectStoreSizeBytes has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LFHMAllocator.mObjectStoreSizeBytes has unexpected size % instead of 4", it.type.runtime_size);
                case "mWriteOffset";
                    assert(it.offset_in_bytes == 12, "LFHMAllocator.mWriteOffset has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LFHMAllocator.mWriteOffset has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(LFHMAllocator) == 16, "LFHMAllocator has size % instead of 16", size_of(LFHMAllocator));
    }

    {
        info := type_info(LFHMAllocatorContext);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "LFHMAllocatorContext.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "LFHMAllocatorContext.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mAllocator";
                    assert(it.offset_in_bytes == 0, "LFHMAllocatorContext.mAllocator has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "LFHMAllocatorContext.mAllocator has unexpected size % instead of 8", it.type.runtime_size);
                case "mBlockSize";
                    assert(it.offset_in_bytes == 8, "LFHMAllocatorContext.mBlockSize has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LFHMAllocatorContext.mBlockSize has unexpected size % instead of 4", it.type.runtime_size);
                case "mBegin";
                    assert(it.offset_in_bytes == 12, "LFHMAllocatorContext.mBegin has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LFHMAllocatorContext.mBegin has unexpected size % instead of 4", it.type.runtime_size);
                case "mEnd";
                    assert(it.offset_in_bytes == 16, "LFHMAllocatorContext.mEnd has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LFHMAllocatorContext.mEnd has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(LFHMAllocatorContext) == 24, "LFHMAllocatorContext has size % instead of 24", size_of(LFHMAllocatorContext));
    }

    {
        info := type_info(BodyPair);
        for info.members {
            if it.name == {
                case "mBodyA";
                    assert(it.offset_in_bytes == 0, "BodyPair.mBodyA has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyPair.mBodyA has unexpected size % instead of 4", it.type.runtime_size);
                case "mBodyB";
                    assert(it.offset_in_bytes == 4, "BodyPair.mBodyB has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "BodyPair.mBodyB has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(BodyPair) == 8, "BodyPair has size % instead of 8", size_of(BodyPair));
    }

    {
        info := type_info(PhysicsMaterial);
        for info.members {
            if it.name == {
                case "serializableobject";
                    assert(it.offset_in_bytes == 0, "PhysicsMaterial.serializableobject has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsMaterial.serializableobject has unexpected size % instead of 8", it.type.runtime_size);
                case "reftarget";
                    assert(it.offset_in_bytes == 8, "PhysicsMaterial.reftarget has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsMaterial.reftarget has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(PhysicsMaterial) == 16, "PhysicsMaterial has size % instead of 16", size_of(PhysicsMaterial));
    }

    {
        info := type_info(ConvexShapeSettings);
        for info.members {
            if it.name == {
                case "shapesettings";
                    assert(it.offset_in_bytes == 0, "ConvexShapeSettings.shapesettings has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "ConvexShapeSettings.shapesettings has unexpected size % instead of 64", it.type.runtime_size);
                case "mMaterial";
                    assert(it.offset_in_bytes == 64, "ConvexShapeSettings.mMaterial has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ConvexShapeSettings.mMaterial has unexpected size % instead of 8", it.type.runtime_size);
                case "mDensity";
                    assert(it.offset_in_bytes == 72, "ConvexShapeSettings.mDensity has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ConvexShapeSettings.mDensity has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(ConvexShapeSettings) == 80, "ConvexShapeSettings has size % instead of 80", size_of(ConvexShapeSettings));
    }

    assert(size_of(ConvexShape.Support) == 8, "ConvexShape.Support has size % instead of 8", size_of(ConvexShape.Support));

    {
        info := type_info(ConvexShape.SupportBuffer);
        for info.members {
            if it.name == {
                case "mData";
                    assert(it.offset_in_bytes == 0, "ConvexShape.SupportBuffer.mData has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4160, "ConvexShape.SupportBuffer.mData has unexpected size % instead of 4160", it.type.runtime_size);
            }
        }
        assert(size_of(ConvexShape.SupportBuffer) == 4160, "ConvexShape.SupportBuffer has size % instead of 4160", size_of(ConvexShape.SupportBuffer));
    }

    {
        info := type_info(ConvexShape);
        for info.members {
            if it.name == {
                case "shape";
                    assert(it.offset_in_bytes == 0, "ConvexShape.shape has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "ConvexShape.shape has unexpected size % instead of 32", it.type.runtime_size);
                case "mMaterial";
                    assert(it.offset_in_bytes == 32, "ConvexShape.mMaterial has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ConvexShape.mMaterial has unexpected size % instead of 8", it.type.runtime_size);
                case "mDensity";
                    assert(it.offset_in_bytes == 40, "ConvexShape.mDensity has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ConvexShape.mDensity has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(ConvexShape) == 48, "ConvexShape has size % instead of 48", size_of(ConvexShape));
    }

    {
        info := type_info(SpringPart);
        for info.members {
            if it.name == {
                case "mBias";
                    assert(it.offset_in_bytes == 0, "SpringPart.mBias has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "SpringPart.mBias has unexpected size % instead of 4", it.type.runtime_size);
                case "mSoftness";
                    assert(it.offset_in_bytes == 4, "SpringPart.mSoftness has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "SpringPart.mSoftness has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(SpringPart) == 8, "SpringPart has size % instead of 8", size_of(SpringPart));
    }

    {
        info := type_info(SpringSettings);
        for info.members {
            if it.name == {
                case "mMode";
                    assert(it.offset_in_bytes == 0, "SpringSettings.mMode has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "SpringSettings.mMode has unexpected size % instead of 1", it.type.runtime_size);
                case "mDamping";
                    assert(it.offset_in_bytes == 8, "SpringSettings.mDamping has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "SpringSettings.mDamping has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(SpringSettings) == 12, "SpringSettings has size % instead of 12", size_of(SpringSettings));
    }

    assert(size_of(StateRecorderFilter) == 8, "StateRecorderFilter has size % instead of 8", size_of(StateRecorderFilter));

    {
        info := type_info(StateRecorder);
        for info.members {
            if it.name == {
                case "streamin";
                    assert(it.offset_in_bytes == 0, "StateRecorder.streamin has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "StateRecorder.streamin has unexpected size % instead of 8", it.type.runtime_size);
                case "streamout";
                    assert(it.offset_in_bytes == 8, "StateRecorder.streamout has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "StateRecorder.streamout has unexpected size % instead of 8", it.type.runtime_size);
                case "mIsValidating";
                    assert(it.offset_in_bytes == 24, "StateRecorder.mIsValidating has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "StateRecorder.mIsValidating has unexpected size % instead of 1", it.type.runtime_size);
                case "mIsLastPart";
                    assert(it.offset_in_bytes == 25, "StateRecorder.mIsLastPart has unexpected offset % instead of 25", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "StateRecorder.mIsLastPart has unexpected size % instead of 1", it.type.runtime_size);
            }
        }
        assert(size_of(StateRecorder) == 32, "StateRecorder has size % instead of 32", size_of(StateRecorder));
    }

    {
        info := type_info(AxisConstraintPart);
        for info.members {
            if it.name == {
                case "mR1PlusUxAxis";
                    assert(it.offset_in_bytes == 0, "AxisConstraintPart.mR1PlusUxAxis has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "AxisConstraintPart.mR1PlusUxAxis has unexpected size % instead of 12", it.type.runtime_size);
                case "mR2xAxis";
                    assert(it.offset_in_bytes == 12, "AxisConstraintPart.mR2xAxis has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "AxisConstraintPart.mR2xAxis has unexpected size % instead of 12", it.type.runtime_size);
                case "mInvI1_R1PlusUxAxis";
                    assert(it.offset_in_bytes == 24, "AxisConstraintPart.mInvI1_R1PlusUxAxis has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "AxisConstraintPart.mInvI1_R1PlusUxAxis has unexpected size % instead of 12", it.type.runtime_size);
                case "mInvI2_R2xAxis";
                    assert(it.offset_in_bytes == 36, "AxisConstraintPart.mInvI2_R2xAxis has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "AxisConstraintPart.mInvI2_R2xAxis has unexpected size % instead of 12", it.type.runtime_size);
                case "mEffectiveMass";
                    assert(it.offset_in_bytes == 48, "AxisConstraintPart.mEffectiveMass has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "AxisConstraintPart.mEffectiveMass has unexpected size % instead of 4", it.type.runtime_size);
                case "mSpringPart";
                    assert(it.offset_in_bytes == 52, "AxisConstraintPart.mSpringPart has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "AxisConstraintPart.mSpringPart has unexpected size % instead of 8", it.type.runtime_size);
                case "mTotalLambda";
                    assert(it.offset_in_bytes == 60, "AxisConstraintPart.mTotalLambda has unexpected offset % instead of 60", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "AxisConstraintPart.mTotalLambda has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(AxisConstraintPart) == 64, "AxisConstraintPart has size % instead of 64", size_of(AxisConstraintPart));
    }

    {
        info := type_info(DualAxisConstraintPart);
        for info.members {
            if it.name == {
                case "mR1PlusUxN1";
                    assert(it.offset_in_bytes == 0, "DualAxisConstraintPart.mR1PlusUxN1 has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "DualAxisConstraintPart.mR1PlusUxN1 has unexpected size % instead of 16", it.type.runtime_size);
                case "mR1PlusUxN2";
                    assert(it.offset_in_bytes == 16, "DualAxisConstraintPart.mR1PlusUxN2 has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "DualAxisConstraintPart.mR1PlusUxN2 has unexpected size % instead of 16", it.type.runtime_size);
                case "mR2xN1";
                    assert(it.offset_in_bytes == 32, "DualAxisConstraintPart.mR2xN1 has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "DualAxisConstraintPart.mR2xN1 has unexpected size % instead of 16", it.type.runtime_size);
                case "mR2xN2";
                    assert(it.offset_in_bytes == 48, "DualAxisConstraintPart.mR2xN2 has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "DualAxisConstraintPart.mR2xN2 has unexpected size % instead of 16", it.type.runtime_size);
                case "mInvI1_R1PlusUxN1";
                    assert(it.offset_in_bytes == 64, "DualAxisConstraintPart.mInvI1_R1PlusUxN1 has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "DualAxisConstraintPart.mInvI1_R1PlusUxN1 has unexpected size % instead of 16", it.type.runtime_size);
                case "mInvI1_R1PlusUxN2";
                    assert(it.offset_in_bytes == 80, "DualAxisConstraintPart.mInvI1_R1PlusUxN2 has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "DualAxisConstraintPart.mInvI1_R1PlusUxN2 has unexpected size % instead of 16", it.type.runtime_size);
                case "mInvI2_R2xN1";
                    assert(it.offset_in_bytes == 96, "DualAxisConstraintPart.mInvI2_R2xN1 has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "DualAxisConstraintPart.mInvI2_R2xN1 has unexpected size % instead of 16", it.type.runtime_size);
                case "mInvI2_R2xN2";
                    assert(it.offset_in_bytes == 112, "DualAxisConstraintPart.mInvI2_R2xN2 has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "DualAxisConstraintPart.mInvI2_R2xN2 has unexpected size % instead of 16", it.type.runtime_size);
                case "mEffectiveMass";
                    assert(it.offset_in_bytes == 128, "DualAxisConstraintPart.mEffectiveMass has unexpected offset % instead of 128", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "DualAxisConstraintPart.mEffectiveMass has unexpected size % instead of 16", it.type.runtime_size);
                case "mTotalLambda";
                    assert(it.offset_in_bytes == 144, "DualAxisConstraintPart.mTotalLambda has unexpected offset % instead of 144", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "DualAxisConstraintPart.mTotalLambda has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(DualAxisConstraintPart) == 160, "DualAxisConstraintPart has size % instead of 160", size_of(DualAxisConstraintPart));
    }

    {
        info := type_info(ContactConstraintManager.ContactAllocator);
        for info.members {
            if it.name == {
                case "lfhmallocatorcontext";
                    assert(it.offset_in_bytes == 0, "ContactConstraintManager.ContactAllocator.lfhmallocatorcontext has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "ContactConstraintManager.ContactAllocator.lfhmallocatorcontext has unexpected size % instead of 24", it.type.runtime_size);
                case "mNumBodyPairs";
                    assert(it.offset_in_bytes == 24, "ContactConstraintManager.ContactAllocator.mNumBodyPairs has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.ContactAllocator.mNumBodyPairs has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumManifolds";
                    assert(it.offset_in_bytes == 28, "ContactConstraintManager.ContactAllocator.mNumManifolds has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.ContactAllocator.mNumManifolds has unexpected size % instead of 4", it.type.runtime_size);
                case "mErrors";
                    assert(it.offset_in_bytes == 32, "ContactConstraintManager.ContactAllocator.mErrors has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.ContactAllocator.mErrors has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(ContactConstraintManager.ContactAllocator) == 40, "ContactConstraintManager.ContactAllocator has size % instead of 40", size_of(ContactConstraintManager.ContactAllocator));
    }

    {
        info := type_info(ContactConstraintManager.CachedContactPoint);
        for info.members {
            if it.name == {
                case "mPosition1";
                    assert(it.offset_in_bytes == 0, "ContactConstraintManager.CachedContactPoint.mPosition1 has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "ContactConstraintManager.CachedContactPoint.mPosition1 has unexpected size % instead of 12", it.type.runtime_size);
                case "mPosition2";
                    assert(it.offset_in_bytes == 12, "ContactConstraintManager.CachedContactPoint.mPosition2 has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "ContactConstraintManager.CachedContactPoint.mPosition2 has unexpected size % instead of 12", it.type.runtime_size);
                case "mNonPenetrationLambda";
                    assert(it.offset_in_bytes == 24, "ContactConstraintManager.CachedContactPoint.mNonPenetrationLambda has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.CachedContactPoint.mNonPenetrationLambda has unexpected size % instead of 4", it.type.runtime_size);
                case "mFrictionLambda";
                    assert(it.offset_in_bytes == 28, "ContactConstraintManager.CachedContactPoint.mFrictionLambda has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ContactConstraintManager.CachedContactPoint.mFrictionLambda has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(ContactConstraintManager.CachedContactPoint) == 36, "ContactConstraintManager.CachedContactPoint has size % instead of 36", size_of(ContactConstraintManager.CachedContactPoint));
    }

    {
        info := type_info(ContactConstraintManager.CachedManifold);
        for info.members {
            if it.name == {
                case "mNextWithSameBodyPair";
                    assert(it.offset_in_bytes == 0, "ContactConstraintManager.CachedManifold.mNextWithSameBodyPair has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.CachedManifold.mNextWithSameBodyPair has unexpected size % instead of 4", it.type.runtime_size);
                case "mContactNormal";
                    assert(it.offset_in_bytes == 4, "ContactConstraintManager.CachedManifold.mContactNormal has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "ContactConstraintManager.CachedManifold.mContactNormal has unexpected size % instead of 12", it.type.runtime_size);
                case "mFlags";
                    assert(it.offset_in_bytes == 16, "ContactConstraintManager.CachedManifold.mFlags has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 2, "ContactConstraintManager.CachedManifold.mFlags has unexpected size % instead of 2", it.type.runtime_size);
                case "mNumContactPoints";
                    assert(it.offset_in_bytes == 18, "ContactConstraintManager.CachedManifold.mNumContactPoints has unexpected offset % instead of 18", it.offset_in_bytes);
                    assert(it.type.runtime_size == 2, "ContactConstraintManager.CachedManifold.mNumContactPoints has unexpected size % instead of 2", it.type.runtime_size);
                case "mContactPoints";
                    assert(it.offset_in_bytes == 20, "ContactConstraintManager.CachedManifold.mContactPoints has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 36, "ContactConstraintManager.CachedManifold.mContactPoints has unexpected size % instead of 36", it.type.runtime_size);
            }
        }
        assert(size_of(ContactConstraintManager.CachedManifold) == 56, "ContactConstraintManager.CachedManifold has size % instead of 56", size_of(ContactConstraintManager.CachedManifold));
    }

    {
        info := type_info(ContactConstraintManager.CachedBodyPair);
        for info.members {
            if it.name == {
                case "mDeltaPosition";
                    assert(it.offset_in_bytes == 0, "ContactConstraintManager.CachedBodyPair.mDeltaPosition has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "ContactConstraintManager.CachedBodyPair.mDeltaPosition has unexpected size % instead of 12", it.type.runtime_size);
                case "mDeltaRotation";
                    assert(it.offset_in_bytes == 12, "ContactConstraintManager.CachedBodyPair.mDeltaRotation has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "ContactConstraintManager.CachedBodyPair.mDeltaRotation has unexpected size % instead of 12", it.type.runtime_size);
                case "mFirstCachedManifold";
                    assert(it.offset_in_bytes == 24, "ContactConstraintManager.CachedBodyPair.mFirstCachedManifold has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.CachedBodyPair.mFirstCachedManifold has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(ContactConstraintManager.CachedBodyPair) == 28, "ContactConstraintManager.CachedBodyPair has size % instead of 28", size_of(ContactConstraintManager.CachedBodyPair));
    }

    {
        info := type_info(ContactConstraintManager.ManifoldCache);
        for info.members {
            if it.name == {
                case "mAllocator";
                    assert(it.offset_in_bytes == 0, "ContactConstraintManager.ManifoldCache.mAllocator has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "ContactConstraintManager.ManifoldCache.mAllocator has unexpected size % instead of 16", it.type.runtime_size);
                case "mCachedManifolds";
                    assert(it.offset_in_bytes == 16, "ContactConstraintManager.ManifoldCache.mCachedManifolds has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "ContactConstraintManager.ManifoldCache.mCachedManifolds has unexpected size % instead of 32", it.type.runtime_size);
                case "mCachedBodyPairs";
                    assert(it.offset_in_bytes == 48, "ContactConstraintManager.ManifoldCache.mCachedBodyPairs has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "ContactConstraintManager.ManifoldCache.mCachedBodyPairs has unexpected size % instead of 32", it.type.runtime_size);
                case "mIsFinalized";
                    assert(it.offset_in_bytes == 80, "ContactConstraintManager.ManifoldCache.mIsFinalized has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "ContactConstraintManager.ManifoldCache.mIsFinalized has unexpected size % instead of 1", it.type.runtime_size);
            }
        }
        assert(size_of(ContactConstraintManager.ManifoldCache) == 88, "ContactConstraintManager.ManifoldCache has size % instead of 88", size_of(ContactConstraintManager.ManifoldCache));
    }

    {
        info := type_info(ContactConstraintManager.WorldContactPoint);
        for info.members {
            if it.name == {
                case "mNonPenetrationConstraint";
                    assert(it.offset_in_bytes == 0, "ContactConstraintManager.WorldContactPoint.mNonPenetrationConstraint has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "ContactConstraintManager.WorldContactPoint.mNonPenetrationConstraint has unexpected size % instead of 64", it.type.runtime_size);
                case "mFrictionConstraint1";
                    assert(it.offset_in_bytes == 64, "ContactConstraintManager.WorldContactPoint.mFrictionConstraint1 has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "ContactConstraintManager.WorldContactPoint.mFrictionConstraint1 has unexpected size % instead of 64", it.type.runtime_size);
                case "mFrictionConstraint2";
                    assert(it.offset_in_bytes == 128, "ContactConstraintManager.WorldContactPoint.mFrictionConstraint2 has unexpected offset % instead of 128", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "ContactConstraintManager.WorldContactPoint.mFrictionConstraint2 has unexpected size % instead of 64", it.type.runtime_size);
                case "mContactPoint";
                    assert(it.offset_in_bytes == 192, "ContactConstraintManager.WorldContactPoint.mContactPoint has unexpected offset % instead of 192", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ContactConstraintManager.WorldContactPoint.mContactPoint has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(ContactConstraintManager.WorldContactPoint) == 200, "ContactConstraintManager.WorldContactPoint has size % instead of 200", size_of(ContactConstraintManager.WorldContactPoint));
    }

    {
        info := type_info(ContactConstraintManager.ContactConstraint);
        for info.members {
            if it.name == {
                case "mBody1";
                    assert(it.offset_in_bytes == 0, "ContactConstraintManager.ContactConstraint.mBody1 has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ContactConstraintManager.ContactConstraint.mBody1 has unexpected size % instead of 8", it.type.runtime_size);
                case "mBody2";
                    assert(it.offset_in_bytes == 8, "ContactConstraintManager.ContactConstraint.mBody2 has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ContactConstraintManager.ContactConstraint.mBody2 has unexpected size % instead of 8", it.type.runtime_size);
                case "mSortKey";
                    assert(it.offset_in_bytes == 16, "ContactConstraintManager.ContactConstraint.mSortKey has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ContactConstraintManager.ContactConstraint.mSortKey has unexpected size % instead of 8", it.type.runtime_size);
                case "mWorldSpaceNormal";
                    assert(it.offset_in_bytes == 24, "ContactConstraintManager.ContactConstraint.mWorldSpaceNormal has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 12, "ContactConstraintManager.ContactConstraint.mWorldSpaceNormal has unexpected size % instead of 12", it.type.runtime_size);
                case "mCombinedFriction";
                    assert(it.offset_in_bytes == 36, "ContactConstraintManager.ContactConstraint.mCombinedFriction has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.ContactConstraint.mCombinedFriction has unexpected size % instead of 4", it.type.runtime_size);
                case "mInvMass1";
                    assert(it.offset_in_bytes == 40, "ContactConstraintManager.ContactConstraint.mInvMass1 has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.ContactConstraint.mInvMass1 has unexpected size % instead of 4", it.type.runtime_size);
                case "mInvInertiaScale1";
                    assert(it.offset_in_bytes == 44, "ContactConstraintManager.ContactConstraint.mInvInertiaScale1 has unexpected offset % instead of 44", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.ContactConstraint.mInvInertiaScale1 has unexpected size % instead of 4", it.type.runtime_size);
                case "mInvMass2";
                    assert(it.offset_in_bytes == 48, "ContactConstraintManager.ContactConstraint.mInvMass2 has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.ContactConstraint.mInvMass2 has unexpected size % instead of 4", it.type.runtime_size);
                case "mInvInertiaScale2";
                    assert(it.offset_in_bytes == 52, "ContactConstraintManager.ContactConstraint.mInvInertiaScale2 has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.ContactConstraint.mInvInertiaScale2 has unexpected size % instead of 4", it.type.runtime_size);
                case "mContactPoints";
                    assert(it.offset_in_bytes == 56, "ContactConstraintManager.ContactConstraint.mContactPoints has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 808, "ContactConstraintManager.ContactConstraint.mContactPoints has unexpected size % instead of 808", it.type.runtime_size);
            }
        }
        assert(size_of(ContactConstraintManager.ContactConstraint) == 864, "ContactConstraintManager.ContactConstraint has size % instead of 864", size_of(ContactConstraintManager.ContactConstraint));
    }

    {
        info := type_info(ContactConstraintManager);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "ContactConstraintManager.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "ContactConstraintManager.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mCache";
                    assert(it.offset_in_bytes == 0, "ContactConstraintManager.mCache has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 176, "ContactConstraintManager.mCache has unexpected size % instead of 176", it.type.runtime_size);
                case "mCacheWriteIdx";
                    assert(it.offset_in_bytes == 176, "ContactConstraintManager.mCacheWriteIdx has unexpected offset % instead of 176", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.mCacheWriteIdx has unexpected size % instead of 4", it.type.runtime_size);
                case "mPhysicsSettings";
                    assert(it.offset_in_bytes == 184, "ContactConstraintManager.mPhysicsSettings has unexpected offset % instead of 184", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ContactConstraintManager.mPhysicsSettings has unexpected size % instead of 8", it.type.runtime_size);
                case "mContactListener";
                    assert(it.offset_in_bytes == 192, "ContactConstraintManager.mContactListener has unexpected offset % instead of 192", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ContactConstraintManager.mContactListener has unexpected size % instead of 8", it.type.runtime_size);
                case "mCombineFriction";
                    assert(it.offset_in_bytes == 200, "ContactConstraintManager.mCombineFriction has unexpected offset % instead of 200", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ContactConstraintManager.mCombineFriction has unexpected size % instead of 8", it.type.runtime_size);
                case "mCombineRestitution";
                    assert(it.offset_in_bytes == 208, "ContactConstraintManager.mCombineRestitution has unexpected offset % instead of 208", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ContactConstraintManager.mCombineRestitution has unexpected size % instead of 8", it.type.runtime_size);
                case "mConstraints";
                    assert(it.offset_in_bytes == 216, "ContactConstraintManager.mConstraints has unexpected offset % instead of 216", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ContactConstraintManager.mConstraints has unexpected size % instead of 8", it.type.runtime_size);
                case "mMaxConstraints";
                    assert(it.offset_in_bytes == 224, "ContactConstraintManager.mMaxConstraints has unexpected offset % instead of 224", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.mMaxConstraints has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumConstraints";
                    assert(it.offset_in_bytes == 228, "ContactConstraintManager.mNumConstraints has unexpected offset % instead of 228", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ContactConstraintManager.mNumConstraints has unexpected size % instead of 4", it.type.runtime_size);
                case "mUpdateContext";
                    assert(it.offset_in_bytes == 232, "ContactConstraintManager.mUpdateContext has unexpected offset % instead of 232", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ContactConstraintManager.mUpdateContext has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(ContactConstraintManager) == 240, "ContactConstraintManager has size % instead of 240", size_of(ContactConstraintManager));
    }

    {
        info := type_info(ConstraintSettings);
        for info.members {
            if it.name == {
                case "serializableobject";
                    assert(it.offset_in_bytes == 0, "ConstraintSettings.serializableobject has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ConstraintSettings.serializableobject has unexpected size % instead of 8", it.type.runtime_size);
                case "reftarget";
                    assert(it.offset_in_bytes == 8, "ConstraintSettings.reftarget has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ConstraintSettings.reftarget has unexpected size % instead of 4", it.type.runtime_size);
                case "mEnabled";
                    assert(it.offset_in_bytes == 12, "ConstraintSettings.mEnabled has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "ConstraintSettings.mEnabled has unexpected size % instead of 1", it.type.runtime_size);
                case "mConstraintPriority";
                    assert(it.offset_in_bytes == 16, "ConstraintSettings.mConstraintPriority has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ConstraintSettings.mConstraintPriority has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumVelocityStepsOverride";
                    assert(it.offset_in_bytes == 20, "ConstraintSettings.mNumVelocityStepsOverride has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ConstraintSettings.mNumVelocityStepsOverride has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumPositionStepsOverride";
                    assert(it.offset_in_bytes == 24, "ConstraintSettings.mNumPositionStepsOverride has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ConstraintSettings.mNumPositionStepsOverride has unexpected size % instead of 4", it.type.runtime_size);
                case "mDrawConstraintSize";
                    assert(it.offset_in_bytes == 28, "ConstraintSettings.mDrawConstraintSize has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "ConstraintSettings.mDrawConstraintSize has unexpected size % instead of 4", it.type.runtime_size);
                case "mUserData";
                    assert(it.offset_in_bytes == 32, "ConstraintSettings.mUserData has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ConstraintSettings.mUserData has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(ConstraintSettings) == 40, "ConstraintSettings has size % instead of 40", size_of(ConstraintSettings));
    }

    {
        info := type_info(Constraint);
        for info.members {
            if it.name == {
                case "reftarget";
                    assert(it.offset_in_bytes == 8, "Constraint.reftarget has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Constraint.reftarget has unexpected size % instead of 4", it.type.runtime_size);
                case "noncopyable";
                    assert(it.offset_in_bytes == 12, "Constraint.noncopyable has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "Constraint.noncopyable has unexpected size % instead of 1", it.type.runtime_size);
                case "mConstraintIndex";
                    assert(it.offset_in_bytes == 12, "Constraint.mConstraintIndex has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Constraint.mConstraintIndex has unexpected size % instead of 4", it.type.runtime_size);
                case "mConstraintPriority";
                    assert(it.offset_in_bytes == 16, "Constraint.mConstraintPriority has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "Constraint.mConstraintPriority has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumVelocityStepsOverride";
                    assert(it.offset_in_bytes == 20, "Constraint.mNumVelocityStepsOverride has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "Constraint.mNumVelocityStepsOverride has unexpected size % instead of 1", it.type.runtime_size);
                case "mNumPositionStepsOverride";
                    assert(it.offset_in_bytes == 21, "Constraint.mNumPositionStepsOverride has unexpected offset % instead of 21", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "Constraint.mNumPositionStepsOverride has unexpected size % instead of 1", it.type.runtime_size);
                case "mEnabled";
                    assert(it.offset_in_bytes == 22, "Constraint.mEnabled has unexpected offset % instead of 22", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "Constraint.mEnabled has unexpected size % instead of 1", it.type.runtime_size);
                case "mUserData";
                    assert(it.offset_in_bytes == 24, "Constraint.mUserData has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "Constraint.mUserData has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(Constraint) == 32, "Constraint has size % instead of 32", size_of(Constraint));
    }

    {
        info := type_info(ConstraintManager);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "ConstraintManager.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "ConstraintManager.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mLockContext";
                    assert(it.offset_in_bytes == 0, "ConstraintManager.mLockContext has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "ConstraintManager.mLockContext has unexpected size % instead of 8", it.type.runtime_size);
                case "mConstraints";
                    assert(it.offset_in_bytes == 8, "ConstraintManager.mConstraints has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "ConstraintManager.mConstraints has unexpected size % instead of 24", it.type.runtime_size);
                case "mConstraintsMutex";
                    assert(it.offset_in_bytes == 32, "ConstraintManager.mConstraintsMutex has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 88, "ConstraintManager.mConstraintsMutex has unexpected size % instead of 88", it.type.runtime_size);
            }
        }
        assert(size_of(ConstraintManager) == 120, "ConstraintManager has size % instead of 120", size_of(ConstraintManager));
    }

    {
        info := type_info(IslandBuilder.BodyLink);
        for info.members {
            if it.name == {
                case "mLinkedTo";
                    assert(it.offset_in_bytes == 0, "IslandBuilder.BodyLink.mLinkedTo has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IslandBuilder.BodyLink.mLinkedTo has unexpected size % instead of 4", it.type.runtime_size);
                case "mIslandIndex";
                    assert(it.offset_in_bytes == 4, "IslandBuilder.BodyLink.mIslandIndex has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IslandBuilder.BodyLink.mIslandIndex has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(IslandBuilder.BodyLink) == 8, "IslandBuilder.BodyLink has size % instead of 8", size_of(IslandBuilder.BodyLink));
    }

    {
        info := type_info(IslandBuilder);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "IslandBuilder.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "IslandBuilder.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mBodyLinks";
                    assert(it.offset_in_bytes == 0, "IslandBuilder.mBodyLinks has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IslandBuilder.mBodyLinks has unexpected size % instead of 8", it.type.runtime_size);
                case "mConstraintLinks";
                    assert(it.offset_in_bytes == 8, "IslandBuilder.mConstraintLinks has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IslandBuilder.mConstraintLinks has unexpected size % instead of 8", it.type.runtime_size);
                case "mContactLinks";
                    assert(it.offset_in_bytes == 16, "IslandBuilder.mContactLinks has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IslandBuilder.mContactLinks has unexpected size % instead of 8", it.type.runtime_size);
                case "mBodyIslands";
                    assert(it.offset_in_bytes == 24, "IslandBuilder.mBodyIslands has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IslandBuilder.mBodyIslands has unexpected size % instead of 8", it.type.runtime_size);
                case "mBodyIslandEnds";
                    assert(it.offset_in_bytes == 32, "IslandBuilder.mBodyIslandEnds has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IslandBuilder.mBodyIslandEnds has unexpected size % instead of 8", it.type.runtime_size);
                case "mConstraintIslands";
                    assert(it.offset_in_bytes == 40, "IslandBuilder.mConstraintIslands has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IslandBuilder.mConstraintIslands has unexpected size % instead of 8", it.type.runtime_size);
                case "mConstraintIslandEnds";
                    assert(it.offset_in_bytes == 48, "IslandBuilder.mConstraintIslandEnds has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IslandBuilder.mConstraintIslandEnds has unexpected size % instead of 8", it.type.runtime_size);
                case "mContactIslands";
                    assert(it.offset_in_bytes == 56, "IslandBuilder.mContactIslands has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IslandBuilder.mContactIslands has unexpected size % instead of 8", it.type.runtime_size);
                case "mContactIslandEnds";
                    assert(it.offset_in_bytes == 64, "IslandBuilder.mContactIslandEnds has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IslandBuilder.mContactIslandEnds has unexpected size % instead of 8", it.type.runtime_size);
                case "mIslandsSorted";
                    assert(it.offset_in_bytes == 72, "IslandBuilder.mIslandsSorted has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IslandBuilder.mIslandsSorted has unexpected size % instead of 8", it.type.runtime_size);
                case "mNumPositionSteps";
                    assert(it.offset_in_bytes == 80, "IslandBuilder.mNumPositionSteps has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "IslandBuilder.mNumPositionSteps has unexpected size % instead of 8", it.type.runtime_size);
                case "mMaxActiveBodies";
                    assert(it.offset_in_bytes == 88, "IslandBuilder.mMaxActiveBodies has unexpected offset % instead of 88", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IslandBuilder.mMaxActiveBodies has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumActiveBodies";
                    assert(it.offset_in_bytes == 92, "IslandBuilder.mNumActiveBodies has unexpected offset % instead of 92", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IslandBuilder.mNumActiveBodies has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumConstraints";
                    assert(it.offset_in_bytes == 96, "IslandBuilder.mNumConstraints has unexpected offset % instead of 96", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IslandBuilder.mNumConstraints has unexpected size % instead of 4", it.type.runtime_size);
                case "mMaxContacts";
                    assert(it.offset_in_bytes == 100, "IslandBuilder.mMaxContacts has unexpected offset % instead of 100", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IslandBuilder.mMaxContacts has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumContacts";
                    assert(it.offset_in_bytes == 104, "IslandBuilder.mNumContacts has unexpected offset % instead of 104", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IslandBuilder.mNumContacts has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumIslands";
                    assert(it.offset_in_bytes == 108, "IslandBuilder.mNumIslands has unexpected offset % instead of 108", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "IslandBuilder.mNumIslands has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(IslandBuilder) == 112, "IslandBuilder has size % instead of 112", size_of(IslandBuilder));
    }

    {
        info := type_info(LargeIslandSplitter.Split);
        for info.members {
            if it.name == {
                case "mContactBufferBegin";
                    assert(it.offset_in_bytes == 0, "LargeIslandSplitter.Split.mContactBufferBegin has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.Split.mContactBufferBegin has unexpected size % instead of 4", it.type.runtime_size);
                case "mContactBufferEnd";
                    assert(it.offset_in_bytes == 4, "LargeIslandSplitter.Split.mContactBufferEnd has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.Split.mContactBufferEnd has unexpected size % instead of 4", it.type.runtime_size);
                case "mConstraintBufferBegin";
                    assert(it.offset_in_bytes == 8, "LargeIslandSplitter.Split.mConstraintBufferBegin has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.Split.mConstraintBufferBegin has unexpected size % instead of 4", it.type.runtime_size);
                case "mConstraintBufferEnd";
                    assert(it.offset_in_bytes == 12, "LargeIslandSplitter.Split.mConstraintBufferEnd has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.Split.mConstraintBufferEnd has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(LargeIslandSplitter.Split) == 16, "LargeIslandSplitter.Split has size % instead of 16", size_of(LargeIslandSplitter.Split));
    }

    {
        info := type_info(LargeIslandSplitter.Splits);
        for info.members {
            if it.name == {
                case "mSplits";
                    assert(it.offset_in_bytes == 0, "LargeIslandSplitter.Splits.mSplits has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 512, "LargeIslandSplitter.Splits.mSplits has unexpected size % instead of 512", it.type.runtime_size);
                case "mIslandIndex";
                    assert(it.offset_in_bytes == 512, "LargeIslandSplitter.Splits.mIslandIndex has unexpected offset % instead of 512", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.Splits.mIslandIndex has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumSplits";
                    assert(it.offset_in_bytes == 516, "LargeIslandSplitter.Splits.mNumSplits has unexpected offset % instead of 516", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.Splits.mNumSplits has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumIterations";
                    assert(it.offset_in_bytes == 520, "LargeIslandSplitter.Splits.mNumIterations has unexpected offset % instead of 520", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.Splits.mNumIterations has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumVelocitySteps";
                    assert(it.offset_in_bytes == 524, "LargeIslandSplitter.Splits.mNumVelocitySteps has unexpected offset % instead of 524", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.Splits.mNumVelocitySteps has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumPositionSteps";
                    assert(it.offset_in_bytes == 528, "LargeIslandSplitter.Splits.mNumPositionSteps has unexpected offset % instead of 528", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.Splits.mNumPositionSteps has unexpected size % instead of 4", it.type.runtime_size);
                case "mStatus";
                    assert(it.offset_in_bytes == 536, "LargeIslandSplitter.Splits.mStatus has unexpected offset % instead of 536", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "LargeIslandSplitter.Splits.mStatus has unexpected size % instead of 8", it.type.runtime_size);
                case "mItemsProcessed";
                    assert(it.offset_in_bytes == 544, "LargeIslandSplitter.Splits.mItemsProcessed has unexpected offset % instead of 544", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.Splits.mItemsProcessed has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(LargeIslandSplitter.Splits) == 552, "LargeIslandSplitter.Splits has size % instead of 552", size_of(LargeIslandSplitter.Splits));
    }

    {
        info := type_info(LargeIslandSplitter);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "LargeIslandSplitter.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "LargeIslandSplitter.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mNumActiveBodies";
                    assert(it.offset_in_bytes == 0, "LargeIslandSplitter.mNumActiveBodies has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.mNumActiveBodies has unexpected size % instead of 4", it.type.runtime_size);
                case "mSplitMasks";
                    assert(it.offset_in_bytes == 8, "LargeIslandSplitter.mSplitMasks has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "LargeIslandSplitter.mSplitMasks has unexpected size % instead of 8", it.type.runtime_size);
                case "mContactAndConstraintsSplitIdx";
                    assert(it.offset_in_bytes == 16, "LargeIslandSplitter.mContactAndConstraintsSplitIdx has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "LargeIslandSplitter.mContactAndConstraintsSplitIdx has unexpected size % instead of 8", it.type.runtime_size);
                case "mContactAndConstraintIndices";
                    assert(it.offset_in_bytes == 24, "LargeIslandSplitter.mContactAndConstraintIndices has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "LargeIslandSplitter.mContactAndConstraintIndices has unexpected size % instead of 8", it.type.runtime_size);
                case "mContactAndConstraintsSize";
                    assert(it.offset_in_bytes == 32, "LargeIslandSplitter.mContactAndConstraintsSize has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.mContactAndConstraintsSize has unexpected size % instead of 4", it.type.runtime_size);
                case "mContactAndConstraintsNextFree";
                    assert(it.offset_in_bytes == 36, "LargeIslandSplitter.mContactAndConstraintsNextFree has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.mContactAndConstraintsNextFree has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumSplitIslands";
                    assert(it.offset_in_bytes == 40, "LargeIslandSplitter.mNumSplitIslands has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.mNumSplitIslands has unexpected size % instead of 4", it.type.runtime_size);
                case "mSplitIslands";
                    assert(it.offset_in_bytes == 48, "LargeIslandSplitter.mSplitIslands has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "LargeIslandSplitter.mSplitIslands has unexpected size % instead of 8", it.type.runtime_size);
                case "mNextSplitIsland";
                    assert(it.offset_in_bytes == 56, "LargeIslandSplitter.mNextSplitIsland has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "LargeIslandSplitter.mNextSplitIsland has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(LargeIslandSplitter) == 64, "LargeIslandSplitter has size % instead of 64", size_of(LargeIslandSplitter));
    }

    {
        info := type_info(BroadPhase.UpdateState);
        for info.members {
            if it.name == {
                case "mData";
                    assert(it.offset_in_bytes == 0, "BroadPhase.UpdateState.mData has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "BroadPhase.UpdateState.mData has unexpected size % instead of 32", it.type.runtime_size);
            }
        }
        assert(size_of(BroadPhase.UpdateState) == 32, "BroadPhase.UpdateState has size % instead of 32", size_of(BroadPhase.UpdateState));
    }

    {
        info := type_info(BroadPhase);
        for info.members {
            if it.name == {
                case "broadphasequery";
                    assert(it.offset_in_bytes == 0, "BroadPhase.broadphasequery has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "BroadPhase.broadphasequery has unexpected size % instead of 8", it.type.runtime_size);
                case "mBodyManager";
                    assert(it.offset_in_bytes == 8, "BroadPhase.mBodyManager has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "BroadPhase.mBodyManager has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(BroadPhase) == 16, "BroadPhase has size % instead of 16", size_of(BroadPhase));
    }

    {
        info := type_info(JobSystem.JobHandle);
        for info.members {
            if it.name == {
                case "ref";
                    assert(it.offset_in_bytes == 0, "JobSystem.JobHandle.ref has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "JobSystem.JobHandle.ref has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(JobSystem.JobHandle) == 8, "JobSystem.JobHandle has size % instead of 8", size_of(JobSystem.JobHandle));
    }

    {
        info := type_info(JobSystem.Barrier);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "JobSystem.Barrier.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "JobSystem.Barrier.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(JobSystem.Barrier) == 8, "JobSystem.Barrier has size % instead of 8", size_of(JobSystem.Barrier));
    }

    {
        info := type_info(JobSystem.Job);
        for info.members {
            if it.name == {
                case "mJobSystem";
                    assert(it.offset_in_bytes == 0, "JobSystem.Job.mJobSystem has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "JobSystem.Job.mJobSystem has unexpected size % instead of 8", it.type.runtime_size);
                case "mBarrier";
                    assert(it.offset_in_bytes == 8, "JobSystem.Job.mBarrier has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "JobSystem.Job.mBarrier has unexpected size % instead of 8", it.type.runtime_size);
                case "mJobFunction";
                    assert(it.offset_in_bytes == 16, "JobSystem.Job.mJobFunction has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "JobSystem.Job.mJobFunction has unexpected size % instead of 64", it.type.runtime_size);
                case "mReferenceCount";
                    assert(it.offset_in_bytes == 80, "JobSystem.Job.mReferenceCount has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "JobSystem.Job.mReferenceCount has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumDependencies";
                    assert(it.offset_in_bytes == 84, "JobSystem.Job.mNumDependencies has unexpected offset % instead of 84", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "JobSystem.Job.mNumDependencies has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(JobSystem.Job) == 88, "JobSystem.Job has size % instead of 88", size_of(JobSystem.Job));
    }

    {
        info := type_info(JobSystem);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "JobSystem.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "JobSystem.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(JobSystem) == 8, "JobSystem has size % instead of 8", size_of(JobSystem));
    }

    {
        info := type_info(TempAllocator);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 8, "TempAllocator.noncopyable__raw has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "TempAllocator.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
            }
        }
        assert(size_of(TempAllocator) == 8, "TempAllocator has size % instead of 8", size_of(TempAllocator));
    }

    {
        info := type_info(TempAllocatorImpl);
        for info.members {
            if it.name == {
                case "tempallocator";
                    assert(it.offset_in_bytes == 0, "TempAllocatorImpl.tempallocator has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "TempAllocatorImpl.tempallocator has unexpected size % instead of 8", it.type.runtime_size);
                case "mBase";
                    assert(it.offset_in_bytes == 8, "TempAllocatorImpl.mBase has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "TempAllocatorImpl.mBase has unexpected size % instead of 8", it.type.runtime_size);
                case "mSize";
                    assert(it.offset_in_bytes == 16, "TempAllocatorImpl.mSize has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "TempAllocatorImpl.mSize has unexpected size % instead of 8", it.type.runtime_size);
                case "mTop";
                    assert(it.offset_in_bytes == 24, "TempAllocatorImpl.mTop has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "TempAllocatorImpl.mTop has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(TempAllocatorImpl) == 32, "TempAllocatorImpl has size % instead of 32", size_of(TempAllocatorImpl));
    }

    {
        info := type_info(TempAllocatorMalloc);
        for info.members {
            if it.name == {
                case "tempallocator";
                    assert(it.offset_in_bytes == 0, "TempAllocatorMalloc.tempallocator has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "TempAllocatorMalloc.tempallocator has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(TempAllocatorMalloc) == 8, "TempAllocatorMalloc has size % instead of 8", size_of(TempAllocatorMalloc));
    }

    {
        info := type_info(TempAllocatorImplWithMallocFallback);
        for info.members {
            if it.name == {
                case "tempallocator";
                    assert(it.offset_in_bytes == 0, "TempAllocatorImplWithMallocFallback.tempallocator has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "TempAllocatorImplWithMallocFallback.tempallocator has unexpected size % instead of 8", it.type.runtime_size);
                case "mAllocator";
                    assert(it.offset_in_bytes == 8, "TempAllocatorImplWithMallocFallback.mAllocator has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "TempAllocatorImplWithMallocFallback.mAllocator has unexpected size % instead of 32", it.type.runtime_size);
                case "mFallbackAllocator";
                    assert(it.offset_in_bytes == 40, "TempAllocatorImplWithMallocFallback.mFallbackAllocator has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "TempAllocatorImplWithMallocFallback.mFallbackAllocator has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(TempAllocatorImplWithMallocFallback) == 48, "TempAllocatorImplWithMallocFallback has size % instead of 48", size_of(TempAllocatorImplWithMallocFallback));
    }

    {
        info := type_info(PhysicsUpdateContext.BodyPairQueue);
        for info.members {
            if it.name == {
                case "mWriteIdx";
                    assert(it.offset_in_bytes == 0, "PhysicsUpdateContext.BodyPairQueue.mWriteIdx has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.BodyPairQueue.mWriteIdx has unexpected size % instead of 4", it.type.runtime_size);
                case "mPadding1";
                    assert(it.offset_in_bytes == 4, "PhysicsUpdateContext.BodyPairQueue.mPadding1 has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 60, "PhysicsUpdateContext.BodyPairQueue.mPadding1 has unexpected size % instead of 60", it.type.runtime_size);
                case "mReadIdx";
                    assert(it.offset_in_bytes == 64, "PhysicsUpdateContext.BodyPairQueue.mReadIdx has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.BodyPairQueue.mReadIdx has unexpected size % instead of 4", it.type.runtime_size);
                case "mPadding2";
                    assert(it.offset_in_bytes == 68, "PhysicsUpdateContext.BodyPairQueue.mPadding2 has unexpected offset % instead of 68", it.offset_in_bytes);
                    assert(it.type.runtime_size == 60, "PhysicsUpdateContext.BodyPairQueue.mPadding2 has unexpected size % instead of 60", it.type.runtime_size);
            }
        }
        assert(size_of(PhysicsUpdateContext.BodyPairQueue) == 128, "PhysicsUpdateContext.BodyPairQueue has size % instead of 128", size_of(PhysicsUpdateContext.BodyPairQueue));
    }

    {
        info := type_info(PhysicsUpdateContext.Step.CCDBody);
        for info.members {
            if it.name == {
                case "mDeltaPosition";
                    assert(it.offset_in_bytes == 0, "PhysicsUpdateContext.Step.CCDBody.mDeltaPosition has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "PhysicsUpdateContext.Step.CCDBody.mDeltaPosition has unexpected size % instead of 16", it.type.runtime_size);
                case "mContactNormal";
                    assert(it.offset_in_bytes == 16, "PhysicsUpdateContext.Step.CCDBody.mContactNormal has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "PhysicsUpdateContext.Step.CCDBody.mContactNormal has unexpected size % instead of 16", it.type.runtime_size);
                case "mContactPointOn2";
                    assert(it.offset_in_bytes == 32, "PhysicsUpdateContext.Step.CCDBody.mContactPointOn2 has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "PhysicsUpdateContext.Step.CCDBody.mContactPointOn2 has unexpected size % instead of 16", it.type.runtime_size);
                case "mBodyID1";
                    assert(it.offset_in_bytes == 48, "PhysicsUpdateContext.Step.CCDBody.mBodyID1 has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.CCDBody.mBodyID1 has unexpected size % instead of 4", it.type.runtime_size);
                case "mBodyID2";
                    assert(it.offset_in_bytes == 52, "PhysicsUpdateContext.Step.CCDBody.mBodyID2 has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.CCDBody.mBodyID2 has unexpected size % instead of 4", it.type.runtime_size);
                case "mSubShapeID2";
                    assert(it.offset_in_bytes == 56, "PhysicsUpdateContext.Step.CCDBody.mSubShapeID2 has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.CCDBody.mSubShapeID2 has unexpected size % instead of 4", it.type.runtime_size);
                case "mFraction";
                    assert(it.offset_in_bytes == 60, "PhysicsUpdateContext.Step.CCDBody.mFraction has unexpected offset % instead of 60", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.CCDBody.mFraction has unexpected size % instead of 4", it.type.runtime_size);
                case "mFractionPlusSlop";
                    assert(it.offset_in_bytes == 64, "PhysicsUpdateContext.Step.CCDBody.mFractionPlusSlop has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.CCDBody.mFractionPlusSlop has unexpected size % instead of 4", it.type.runtime_size);
                case "mLinearCastThresholdSq";
                    assert(it.offset_in_bytes == 68, "PhysicsUpdateContext.Step.CCDBody.mLinearCastThresholdSq has unexpected offset % instead of 68", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.CCDBody.mLinearCastThresholdSq has unexpected size % instead of 4", it.type.runtime_size);
                case "mMaxPenetration";
                    assert(it.offset_in_bytes == 72, "PhysicsUpdateContext.Step.CCDBody.mMaxPenetration has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.CCDBody.mMaxPenetration has unexpected size % instead of 4", it.type.runtime_size);
                case "mContactSettings";
                    assert(it.offset_in_bytes == 80, "PhysicsUpdateContext.Step.CCDBody.mContactSettings has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "PhysicsUpdateContext.Step.CCDBody.mContactSettings has unexpected size % instead of 64", it.type.runtime_size);
            }
        }
        assert(size_of(PhysicsUpdateContext.Step.CCDBody) == 144, "PhysicsUpdateContext.Step.CCDBody has size % instead of 144", size_of(PhysicsUpdateContext.Step.CCDBody));
    }

    {
        info := type_info(PhysicsUpdateContext.Step);
        for info.members {
            if it.name == {
                case "mContext";
                    assert(it.offset_in_bytes == 0, "PhysicsUpdateContext.Step.mContext has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mContext has unexpected size % instead of 8", it.type.runtime_size);
                case "mIsFirst";
                    assert(it.offset_in_bytes == 8, "PhysicsUpdateContext.Step.mIsFirst has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "PhysicsUpdateContext.Step.mIsFirst has unexpected size % instead of 1", it.type.runtime_size);
                case "mIsLast";
                    assert(it.offset_in_bytes == 9, "PhysicsUpdateContext.Step.mIsLast has unexpected offset % instead of 9", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "PhysicsUpdateContext.Step.mIsLast has unexpected size % instead of 1", it.type.runtime_size);
                case "mBroadPhaseUpdateState";
                    assert(it.offset_in_bytes == 16, "PhysicsUpdateContext.Step.mBroadPhaseUpdateState has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "PhysicsUpdateContext.Step.mBroadPhaseUpdateState has unexpected size % instead of 32", it.type.runtime_size);
                case "mNumActiveBodiesAtStepStart";
                    assert(it.offset_in_bytes == 48, "PhysicsUpdateContext.Step.mNumActiveBodiesAtStepStart has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mNumActiveBodiesAtStepStart has unexpected size % instead of 4", it.type.runtime_size);
                case "mDetermineActiveConstraintReadIdx";
                    assert(it.offset_in_bytes == 52, "PhysicsUpdateContext.Step.mDetermineActiveConstraintReadIdx has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mDetermineActiveConstraintReadIdx has unexpected size % instead of 4", it.type.runtime_size);
                case "mPadding1";
                    assert(it.offset_in_bytes == 56, "PhysicsUpdateContext.Step.mPadding1 has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 60, "PhysicsUpdateContext.Step.mPadding1 has unexpected size % instead of 60", it.type.runtime_size);
                case "mNumActiveConstraints";
                    assert(it.offset_in_bytes == 116, "PhysicsUpdateContext.Step.mNumActiveConstraints has unexpected offset % instead of 116", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mNumActiveConstraints has unexpected size % instead of 4", it.type.runtime_size);
                case "mPadding2";
                    assert(it.offset_in_bytes == 120, "PhysicsUpdateContext.Step.mPadding2 has unexpected offset % instead of 120", it.offset_in_bytes);
                    assert(it.type.runtime_size == 60, "PhysicsUpdateContext.Step.mPadding2 has unexpected size % instead of 60", it.type.runtime_size);
                case "mSetupVelocityConstraintsReadIdx";
                    assert(it.offset_in_bytes == 180, "PhysicsUpdateContext.Step.mSetupVelocityConstraintsReadIdx has unexpected offset % instead of 180", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mSetupVelocityConstraintsReadIdx has unexpected size % instead of 4", it.type.runtime_size);
                case "mPadding3";
                    assert(it.offset_in_bytes == 184, "PhysicsUpdateContext.Step.mPadding3 has unexpected offset % instead of 184", it.offset_in_bytes);
                    assert(it.type.runtime_size == 60, "PhysicsUpdateContext.Step.mPadding3 has unexpected size % instead of 60", it.type.runtime_size);
                case "mStepListenerReadIdx";
                    assert(it.offset_in_bytes == 244, "PhysicsUpdateContext.Step.mStepListenerReadIdx has unexpected offset % instead of 244", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mStepListenerReadIdx has unexpected size % instead of 4", it.type.runtime_size);
                case "mPadding4";
                    assert(it.offset_in_bytes == 248, "PhysicsUpdateContext.Step.mPadding4 has unexpected offset % instead of 248", it.offset_in_bytes);
                    assert(it.type.runtime_size == 60, "PhysicsUpdateContext.Step.mPadding4 has unexpected size % instead of 60", it.type.runtime_size);
                case "mApplyGravityReadIdx";
                    assert(it.offset_in_bytes == 308, "PhysicsUpdateContext.Step.mApplyGravityReadIdx has unexpected offset % instead of 308", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mApplyGravityReadIdx has unexpected size % instead of 4", it.type.runtime_size);
                case "mPadding5";
                    assert(it.offset_in_bytes == 312, "PhysicsUpdateContext.Step.mPadding5 has unexpected offset % instead of 312", it.offset_in_bytes);
                    assert(it.type.runtime_size == 60, "PhysicsUpdateContext.Step.mPadding5 has unexpected size % instead of 60", it.type.runtime_size);
                case "mActiveBodyReadIdx";
                    assert(it.offset_in_bytes == 372, "PhysicsUpdateContext.Step.mActiveBodyReadIdx has unexpected offset % instead of 372", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mActiveBodyReadIdx has unexpected size % instead of 4", it.type.runtime_size);
                case "mPadding6";
                    assert(it.offset_in_bytes == 376, "PhysicsUpdateContext.Step.mPadding6 has unexpected offset % instead of 376", it.offset_in_bytes);
                    assert(it.type.runtime_size == 60, "PhysicsUpdateContext.Step.mPadding6 has unexpected size % instead of 60", it.type.runtime_size);
                case "mBodyPairQueues";
                    assert(it.offset_in_bytes == 436, "PhysicsUpdateContext.Step.mBodyPairQueues has unexpected offset % instead of 436", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4100, "PhysicsUpdateContext.Step.mBodyPairQueues has unexpected size % instead of 4100", it.type.runtime_size);
                case "mMaxBodyPairsPerQueue";
                    assert(it.offset_in_bytes == 4536, "PhysicsUpdateContext.Step.mMaxBodyPairsPerQueue has unexpected offset % instead of 4536", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mMaxBodyPairsPerQueue has unexpected size % instead of 4", it.type.runtime_size);
                case "mActiveFindCollisionJobs";
                    assert(it.offset_in_bytes == 4540, "PhysicsUpdateContext.Step.mActiveFindCollisionJobs has unexpected offset % instead of 4540", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mActiveFindCollisionJobs has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumBodyPairs";
                    assert(it.offset_in_bytes == 4544, "PhysicsUpdateContext.Step.mNumBodyPairs has unexpected offset % instead of 4544", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mNumBodyPairs has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumManifolds";
                    assert(it.offset_in_bytes == 4548, "PhysicsUpdateContext.Step.mNumManifolds has unexpected offset % instead of 4548", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mNumManifolds has unexpected size % instead of 4", it.type.runtime_size);
                case "mSolveVelocityConstraintsNextIsland";
                    assert(it.offset_in_bytes == 4552, "PhysicsUpdateContext.Step.mSolveVelocityConstraintsNextIsland has unexpected offset % instead of 4552", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mSolveVelocityConstraintsNextIsland has unexpected size % instead of 4", it.type.runtime_size);
                case "mSolvePositionConstraintsNextIsland";
                    assert(it.offset_in_bytes == 4556, "PhysicsUpdateContext.Step.mSolvePositionConstraintsNextIsland has unexpected offset % instead of 4556", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mSolvePositionConstraintsNextIsland has unexpected size % instead of 4", it.type.runtime_size);
                case "mIntegrateVelocityReadIdx";
                    assert(it.offset_in_bytes == 4560, "PhysicsUpdateContext.Step.mIntegrateVelocityReadIdx has unexpected offset % instead of 4560", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mIntegrateVelocityReadIdx has unexpected size % instead of 4", it.type.runtime_size);
                case "mCCDBodies";
                    assert(it.offset_in_bytes == 4568, "PhysicsUpdateContext.Step.mCCDBodies has unexpected offset % instead of 4568", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mCCDBodies has unexpected size % instead of 8", it.type.runtime_size);
                case "mCCDBodiesCapacity";
                    assert(it.offset_in_bytes == 4576, "PhysicsUpdateContext.Step.mCCDBodiesCapacity has unexpected offset % instead of 4576", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mCCDBodiesCapacity has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumCCDBodies";
                    assert(it.offset_in_bytes == 4580, "PhysicsUpdateContext.Step.mNumCCDBodies has unexpected offset % instead of 4580", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mNumCCDBodies has unexpected size % instead of 4", it.type.runtime_size);
                case "mNextCCDBody";
                    assert(it.offset_in_bytes == 4584, "PhysicsUpdateContext.Step.mNextCCDBody has unexpected offset % instead of 4584", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mNextCCDBody has unexpected size % instead of 4", it.type.runtime_size);
                case "mActiveBodyToCCDBody";
                    assert(it.offset_in_bytes == 4592, "PhysicsUpdateContext.Step.mActiveBodyToCCDBody has unexpected offset % instead of 4592", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mActiveBodyToCCDBody has unexpected size % instead of 8", it.type.runtime_size);
                case "mNumActiveBodyToCCDBody";
                    assert(it.offset_in_bytes == 4600, "PhysicsUpdateContext.Step.mNumActiveBodyToCCDBody has unexpected offset % instead of 4600", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.Step.mNumActiveBodyToCCDBody has unexpected size % instead of 4", it.type.runtime_size);
                case "mBroadPhasePrepare";
                    assert(it.offset_in_bytes == 4608, "PhysicsUpdateContext.Step.mBroadPhasePrepare has unexpected offset % instead of 4608", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mBroadPhasePrepare has unexpected size % instead of 8", it.type.runtime_size);
                case "mStepListeners";
                    assert(it.offset_in_bytes == 4616, "PhysicsUpdateContext.Step.mStepListeners has unexpected offset % instead of 4616", it.offset_in_bytes);
                    assert(it.type.runtime_size == 264, "PhysicsUpdateContext.Step.mStepListeners has unexpected size % instead of 264", it.type.runtime_size);
                case "mDetermineActiveConstraints";
                    assert(it.offset_in_bytes == 4880, "PhysicsUpdateContext.Step.mDetermineActiveConstraints has unexpected offset % instead of 4880", it.offset_in_bytes);
                    assert(it.type.runtime_size == 264, "PhysicsUpdateContext.Step.mDetermineActiveConstraints has unexpected size % instead of 264", it.type.runtime_size);
                case "mApplyGravity";
                    assert(it.offset_in_bytes == 5144, "PhysicsUpdateContext.Step.mApplyGravity has unexpected offset % instead of 5144", it.offset_in_bytes);
                    assert(it.type.runtime_size == 264, "PhysicsUpdateContext.Step.mApplyGravity has unexpected size % instead of 264", it.type.runtime_size);
                case "mFindCollisions";
                    assert(it.offset_in_bytes == 5408, "PhysicsUpdateContext.Step.mFindCollisions has unexpected offset % instead of 5408", it.offset_in_bytes);
                    assert(it.type.runtime_size == 264, "PhysicsUpdateContext.Step.mFindCollisions has unexpected size % instead of 264", it.type.runtime_size);
                case "mUpdateBroadphaseFinalize";
                    assert(it.offset_in_bytes == 5672, "PhysicsUpdateContext.Step.mUpdateBroadphaseFinalize has unexpected offset % instead of 5672", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mUpdateBroadphaseFinalize has unexpected size % instead of 8", it.type.runtime_size);
                case "mSetupVelocityConstraints";
                    assert(it.offset_in_bytes == 5680, "PhysicsUpdateContext.Step.mSetupVelocityConstraints has unexpected offset % instead of 5680", it.offset_in_bytes);
                    assert(it.type.runtime_size == 264, "PhysicsUpdateContext.Step.mSetupVelocityConstraints has unexpected size % instead of 264", it.type.runtime_size);
                case "mBuildIslandsFromConstraints";
                    assert(it.offset_in_bytes == 5944, "PhysicsUpdateContext.Step.mBuildIslandsFromConstraints has unexpected offset % instead of 5944", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mBuildIslandsFromConstraints has unexpected size % instead of 8", it.type.runtime_size);
                case "mFinalizeIslands";
                    assert(it.offset_in_bytes == 5952, "PhysicsUpdateContext.Step.mFinalizeIslands has unexpected offset % instead of 5952", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mFinalizeIslands has unexpected size % instead of 8", it.type.runtime_size);
                case "mBodySetIslandIndex";
                    assert(it.offset_in_bytes == 5960, "PhysicsUpdateContext.Step.mBodySetIslandIndex has unexpected offset % instead of 5960", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mBodySetIslandIndex has unexpected size % instead of 8", it.type.runtime_size);
                case "mSolveVelocityConstraints";
                    assert(it.offset_in_bytes == 5968, "PhysicsUpdateContext.Step.mSolveVelocityConstraints has unexpected offset % instead of 5968", it.offset_in_bytes);
                    assert(it.type.runtime_size == 264, "PhysicsUpdateContext.Step.mSolveVelocityConstraints has unexpected size % instead of 264", it.type.runtime_size);
                case "mPreIntegrateVelocity";
                    assert(it.offset_in_bytes == 6232, "PhysicsUpdateContext.Step.mPreIntegrateVelocity has unexpected offset % instead of 6232", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mPreIntegrateVelocity has unexpected size % instead of 8", it.type.runtime_size);
                case "mIntegrateVelocity";
                    assert(it.offset_in_bytes == 6240, "PhysicsUpdateContext.Step.mIntegrateVelocity has unexpected offset % instead of 6240", it.offset_in_bytes);
                    assert(it.type.runtime_size == 264, "PhysicsUpdateContext.Step.mIntegrateVelocity has unexpected size % instead of 264", it.type.runtime_size);
                case "mPostIntegrateVelocity";
                    assert(it.offset_in_bytes == 6504, "PhysicsUpdateContext.Step.mPostIntegrateVelocity has unexpected offset % instead of 6504", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mPostIntegrateVelocity has unexpected size % instead of 8", it.type.runtime_size);
                case "mResolveCCDContacts";
                    assert(it.offset_in_bytes == 6512, "PhysicsUpdateContext.Step.mResolveCCDContacts has unexpected offset % instead of 6512", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mResolveCCDContacts has unexpected size % instead of 8", it.type.runtime_size);
                case "mSolvePositionConstraints";
                    assert(it.offset_in_bytes == 6520, "PhysicsUpdateContext.Step.mSolvePositionConstraints has unexpected offset % instead of 6520", it.offset_in_bytes);
                    assert(it.type.runtime_size == 264, "PhysicsUpdateContext.Step.mSolvePositionConstraints has unexpected size % instead of 264", it.type.runtime_size);
                case "mContactRemovedCallbacks";
                    assert(it.offset_in_bytes == 6784, "PhysicsUpdateContext.Step.mContactRemovedCallbacks has unexpected offset % instead of 6784", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mContactRemovedCallbacks has unexpected size % instead of 8", it.type.runtime_size);
                case "mSoftBodyPrepare";
                    assert(it.offset_in_bytes == 6792, "PhysicsUpdateContext.Step.mSoftBodyPrepare has unexpected offset % instead of 6792", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mSoftBodyPrepare has unexpected size % instead of 8", it.type.runtime_size);
                case "mSoftBodyCollide";
                    assert(it.offset_in_bytes == 6800, "PhysicsUpdateContext.Step.mSoftBodyCollide has unexpected offset % instead of 6800", it.offset_in_bytes);
                    assert(it.type.runtime_size == 264, "PhysicsUpdateContext.Step.mSoftBodyCollide has unexpected size % instead of 264", it.type.runtime_size);
                case "mSoftBodySimulate";
                    assert(it.offset_in_bytes == 7064, "PhysicsUpdateContext.Step.mSoftBodySimulate has unexpected offset % instead of 7064", it.offset_in_bytes);
                    assert(it.type.runtime_size == 264, "PhysicsUpdateContext.Step.mSoftBodySimulate has unexpected size % instead of 264", it.type.runtime_size);
                case "mSoftBodyFinalize";
                    assert(it.offset_in_bytes == 7328, "PhysicsUpdateContext.Step.mSoftBodyFinalize has unexpected offset % instead of 7328", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mSoftBodyFinalize has unexpected size % instead of 8", it.type.runtime_size);
                case "mStartNextStep";
                    assert(it.offset_in_bytes == 7336, "PhysicsUpdateContext.Step.mStartNextStep has unexpected offset % instead of 7336", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.Step.mStartNextStep has unexpected size % instead of 8", it.type.runtime_size);
            }
        }
        assert(size_of(PhysicsUpdateContext.Step) == 7344, "PhysicsUpdateContext.Step has size % instead of 7344", size_of(PhysicsUpdateContext.Step));
    }

    {
        info := type_info(PhysicsUpdateContext);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "PhysicsUpdateContext.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "PhysicsUpdateContext.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mPhysicsSystem";
                    assert(it.offset_in_bytes == 0, "PhysicsUpdateContext.mPhysicsSystem has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.mPhysicsSystem has unexpected size % instead of 8", it.type.runtime_size);
                case "mTempAllocator";
                    assert(it.offset_in_bytes == 8, "PhysicsUpdateContext.mTempAllocator has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.mTempAllocator has unexpected size % instead of 8", it.type.runtime_size);
                case "mJobSystem";
                    assert(it.offset_in_bytes == 16, "PhysicsUpdateContext.mJobSystem has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.mJobSystem has unexpected size % instead of 8", it.type.runtime_size);
                case "mBarrier";
                    assert(it.offset_in_bytes == 24, "PhysicsUpdateContext.mBarrier has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.mBarrier has unexpected size % instead of 8", it.type.runtime_size);
                case "mStepDeltaTime";
                    assert(it.offset_in_bytes == 32, "PhysicsUpdateContext.mStepDeltaTime has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.mStepDeltaTime has unexpected size % instead of 4", it.type.runtime_size);
                case "mWarmStartImpulseRatio";
                    assert(it.offset_in_bytes == 36, "PhysicsUpdateContext.mWarmStartImpulseRatio has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.mWarmStartImpulseRatio has unexpected size % instead of 4", it.type.runtime_size);
                case "mErrors";
                    assert(it.offset_in_bytes == 40, "PhysicsUpdateContext.mErrors has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.mErrors has unexpected size % instead of 4", it.type.runtime_size);
                case "mActiveConstraints";
                    assert(it.offset_in_bytes == 48, "PhysicsUpdateContext.mActiveConstraints has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.mActiveConstraints has unexpected size % instead of 8", it.type.runtime_size);
                case "mBodyPairs";
                    assert(it.offset_in_bytes == 56, "PhysicsUpdateContext.mBodyPairs has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.mBodyPairs has unexpected size % instead of 8", it.type.runtime_size);
                case "mIslandBuilder";
                    assert(it.offset_in_bytes == 64, "PhysicsUpdateContext.mIslandBuilder has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.mIslandBuilder has unexpected size % instead of 8", it.type.runtime_size);
                case "mSteps";
                    assert(it.offset_in_bytes == 72, "PhysicsUpdateContext.mSteps has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 32, "PhysicsUpdateContext.mSteps has unexpected size % instead of 32", it.type.runtime_size);
                case "mNumSoftBodies";
                    assert(it.offset_in_bytes == 104, "PhysicsUpdateContext.mNumSoftBodies has unexpected offset % instead of 104", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.mNumSoftBodies has unexpected size % instead of 4", it.type.runtime_size);
                case "mSoftBodyUpdateContexts";
                    assert(it.offset_in_bytes == 112, "PhysicsUpdateContext.mSoftBodyUpdateContexts has unexpected offset % instead of 112", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsUpdateContext.mSoftBodyUpdateContexts has unexpected size % instead of 8", it.type.runtime_size);
                case "mSoftBodyToCollide";
                    assert(it.offset_in_bytes == 120, "PhysicsUpdateContext.mSoftBodyToCollide has unexpected offset % instead of 120", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsUpdateContext.mSoftBodyToCollide has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(PhysicsUpdateContext) == 128, "PhysicsUpdateContext has size % instead of 128", size_of(PhysicsUpdateContext));
    }

    {
        info := type_info(PhysicsSettings);
        for info.members {
            if it.name == {
                case "mMaxInFlightBodyPairs";
                    assert(it.offset_in_bytes == 0, "PhysicsSettings.mMaxInFlightBodyPairs has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mMaxInFlightBodyPairs has unexpected size % instead of 4", it.type.runtime_size);
                case "mStepListenersBatchSize";
                    assert(it.offset_in_bytes == 4, "PhysicsSettings.mStepListenersBatchSize has unexpected offset % instead of 4", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mStepListenersBatchSize has unexpected size % instead of 4", it.type.runtime_size);
                case "mStepListenerBatchesPerJob";
                    assert(it.offset_in_bytes == 8, "PhysicsSettings.mStepListenerBatchesPerJob has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mStepListenerBatchesPerJob has unexpected size % instead of 4", it.type.runtime_size);
                case "mBaumgarte";
                    assert(it.offset_in_bytes == 12, "PhysicsSettings.mBaumgarte has unexpected offset % instead of 12", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mBaumgarte has unexpected size % instead of 4", it.type.runtime_size);
                case "mSpeculativeContactDistance";
                    assert(it.offset_in_bytes == 16, "PhysicsSettings.mSpeculativeContactDistance has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mSpeculativeContactDistance has unexpected size % instead of 4", it.type.runtime_size);
                case "mPenetrationSlop";
                    assert(it.offset_in_bytes == 20, "PhysicsSettings.mPenetrationSlop has unexpected offset % instead of 20", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mPenetrationSlop has unexpected size % instead of 4", it.type.runtime_size);
                case "mLinearCastThreshold";
                    assert(it.offset_in_bytes == 24, "PhysicsSettings.mLinearCastThreshold has unexpected offset % instead of 24", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mLinearCastThreshold has unexpected size % instead of 4", it.type.runtime_size);
                case "mLinearCastMaxPenetration";
                    assert(it.offset_in_bytes == 28, "PhysicsSettings.mLinearCastMaxPenetration has unexpected offset % instead of 28", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mLinearCastMaxPenetration has unexpected size % instead of 4", it.type.runtime_size);
                case "mManifoldTolerance";
                    assert(it.offset_in_bytes == 32, "PhysicsSettings.mManifoldTolerance has unexpected offset % instead of 32", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mManifoldTolerance has unexpected size % instead of 4", it.type.runtime_size);
                case "mMaxPenetrationDistance";
                    assert(it.offset_in_bytes == 36, "PhysicsSettings.mMaxPenetrationDistance has unexpected offset % instead of 36", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mMaxPenetrationDistance has unexpected size % instead of 4", it.type.runtime_size);
                case "mBodyPairCacheMaxDeltaPositionSq";
                    assert(it.offset_in_bytes == 40, "PhysicsSettings.mBodyPairCacheMaxDeltaPositionSq has unexpected offset % instead of 40", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mBodyPairCacheMaxDeltaPositionSq has unexpected size % instead of 4", it.type.runtime_size);
                case "mBodyPairCacheCosMaxDeltaRotationDiv2";
                    assert(it.offset_in_bytes == 44, "PhysicsSettings.mBodyPairCacheCosMaxDeltaRotationDiv2 has unexpected offset % instead of 44", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mBodyPairCacheCosMaxDeltaRotationDiv2 has unexpected size % instead of 4", it.type.runtime_size);
                case "mContactNormalCosMaxDeltaRotation";
                    assert(it.offset_in_bytes == 48, "PhysicsSettings.mContactNormalCosMaxDeltaRotation has unexpected offset % instead of 48", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mContactNormalCosMaxDeltaRotation has unexpected size % instead of 4", it.type.runtime_size);
                case "mContactPointPreserveLambdaMaxDistSq";
                    assert(it.offset_in_bytes == 52, "PhysicsSettings.mContactPointPreserveLambdaMaxDistSq has unexpected offset % instead of 52", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mContactPointPreserveLambdaMaxDistSq has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumVelocitySteps";
                    assert(it.offset_in_bytes == 56, "PhysicsSettings.mNumVelocitySteps has unexpected offset % instead of 56", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mNumVelocitySteps has unexpected size % instead of 4", it.type.runtime_size);
                case "mNumPositionSteps";
                    assert(it.offset_in_bytes == 60, "PhysicsSettings.mNumPositionSteps has unexpected offset % instead of 60", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mNumPositionSteps has unexpected size % instead of 4", it.type.runtime_size);
                case "mMinVelocityForRestitution";
                    assert(it.offset_in_bytes == 64, "PhysicsSettings.mMinVelocityForRestitution has unexpected offset % instead of 64", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mMinVelocityForRestitution has unexpected size % instead of 4", it.type.runtime_size);
                case "mTimeBeforeSleep";
                    assert(it.offset_in_bytes == 68, "PhysicsSettings.mTimeBeforeSleep has unexpected offset % instead of 68", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mTimeBeforeSleep has unexpected size % instead of 4", it.type.runtime_size);
                case "mPointVelocitySleepThreshold";
                    assert(it.offset_in_bytes == 72, "PhysicsSettings.mPointVelocitySleepThreshold has unexpected offset % instead of 72", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSettings.mPointVelocitySleepThreshold has unexpected size % instead of 4", it.type.runtime_size);
                case "mDeterministicSimulation";
                    assert(it.offset_in_bytes == 76, "PhysicsSettings.mDeterministicSimulation has unexpected offset % instead of 76", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "PhysicsSettings.mDeterministicSimulation has unexpected size % instead of 1", it.type.runtime_size);
                case "mConstraintWarmStart";
                    assert(it.offset_in_bytes == 77, "PhysicsSettings.mConstraintWarmStart has unexpected offset % instead of 77", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "PhysicsSettings.mConstraintWarmStart has unexpected size % instead of 1", it.type.runtime_size);
                case "mUseBodyPairContactCache";
                    assert(it.offset_in_bytes == 78, "PhysicsSettings.mUseBodyPairContactCache has unexpected offset % instead of 78", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "PhysicsSettings.mUseBodyPairContactCache has unexpected size % instead of 1", it.type.runtime_size);
                case "mUseManifoldReduction";
                    assert(it.offset_in_bytes == 79, "PhysicsSettings.mUseManifoldReduction has unexpected offset % instead of 79", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "PhysicsSettings.mUseManifoldReduction has unexpected size % instead of 1", it.type.runtime_size);
                case "mUseLargeIslandSplitter";
                    assert(it.offset_in_bytes == 80, "PhysicsSettings.mUseLargeIslandSplitter has unexpected offset % instead of 80", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "PhysicsSettings.mUseLargeIslandSplitter has unexpected size % instead of 1", it.type.runtime_size);
                case "mAllowSleeping";
                    assert(it.offset_in_bytes == 81, "PhysicsSettings.mAllowSleeping has unexpected offset % instead of 81", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "PhysicsSettings.mAllowSleeping has unexpected size % instead of 1", it.type.runtime_size);
                case "mCheckActiveEdges";
                    assert(it.offset_in_bytes == 82, "PhysicsSettings.mCheckActiveEdges has unexpected offset % instead of 82", it.offset_in_bytes);
                    assert(it.type.runtime_size == 1, "PhysicsSettings.mCheckActiveEdges has unexpected size % instead of 1", it.type.runtime_size);
            }
        }
        assert(size_of(PhysicsSettings) == 84, "PhysicsSettings has size % instead of 84", size_of(PhysicsSettings));
    }

    {
        info := type_info(PhysicsSystem);
        for info.members {
            if it.name == {
                case "noncopyable__raw";
                    assert(it.offset_in_bytes == 0, "PhysicsSystem.noncopyable__raw has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 0, "PhysicsSystem.noncopyable__raw has unexpected size % instead of 0", it.type.runtime_size);
                case "mObjectVsBroadPhaseLayerFilter";
                    assert(it.offset_in_bytes == 0, "PhysicsSystem.mObjectVsBroadPhaseLayerFilter has unexpected offset % instead of 0", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsSystem.mObjectVsBroadPhaseLayerFilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mObjectLayerPairFilter";
                    assert(it.offset_in_bytes == 8, "PhysicsSystem.mObjectLayerPairFilter has unexpected offset % instead of 8", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsSystem.mObjectLayerPairFilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mBodyManager";
                    assert(it.offset_in_bytes == 16, "PhysicsSystem.mBodyManager has unexpected offset % instead of 16", it.offset_in_bytes);
                    assert(it.type.runtime_size == 424, "PhysicsSystem.mBodyManager has unexpected size % instead of 424", it.type.runtime_size);
                case "mBodyLockInterfaceNoLock";
                    assert(it.offset_in_bytes == 440, "PhysicsSystem.mBodyLockInterfaceNoLock has unexpected offset % instead of 440", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "PhysicsSystem.mBodyLockInterfaceNoLock has unexpected size % instead of 16", it.type.runtime_size);
                case "mBodyLockInterfaceLocking";
                    assert(it.offset_in_bytes == 456, "PhysicsSystem.mBodyLockInterfaceLocking has unexpected offset % instead of 456", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "PhysicsSystem.mBodyLockInterfaceLocking has unexpected size % instead of 16", it.type.runtime_size);
                case "mBodyInterfaceNoLock";
                    assert(it.offset_in_bytes == 472, "PhysicsSystem.mBodyInterfaceNoLock has unexpected offset % instead of 472", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "PhysicsSystem.mBodyInterfaceNoLock has unexpected size % instead of 24", it.type.runtime_size);
                case "mBodyInterfaceLocking";
                    assert(it.offset_in_bytes == 496, "PhysicsSystem.mBodyInterfaceLocking has unexpected offset % instead of 496", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "PhysicsSystem.mBodyInterfaceLocking has unexpected size % instead of 24", it.type.runtime_size);
                case "mNarrowPhaseQueryNoLock";
                    assert(it.offset_in_bytes == 520, "PhysicsSystem.mNarrowPhaseQueryNoLock has unexpected offset % instead of 520", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "PhysicsSystem.mNarrowPhaseQueryNoLock has unexpected size % instead of 16", it.type.runtime_size);
                case "mNarrowPhaseQueryLocking";
                    assert(it.offset_in_bytes == 536, "PhysicsSystem.mNarrowPhaseQueryLocking has unexpected offset % instead of 536", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "PhysicsSystem.mNarrowPhaseQueryLocking has unexpected size % instead of 16", it.type.runtime_size);
                case "mBroadPhase";
                    assert(it.offset_in_bytes == 552, "PhysicsSystem.mBroadPhase has unexpected offset % instead of 552", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsSystem.mBroadPhase has unexpected size % instead of 8", it.type.runtime_size);
                case "mSoftBodyContactListener";
                    assert(it.offset_in_bytes == 560, "PhysicsSystem.mSoftBodyContactListener has unexpected offset % instead of 560", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsSystem.mSoftBodyContactListener has unexpected size % instead of 8", it.type.runtime_size);
                case "mSimShapeFilter";
                    assert(it.offset_in_bytes == 568, "PhysicsSystem.mSimShapeFilter has unexpected offset % instead of 568", it.offset_in_bytes);
                    assert(it.type.runtime_size == 8, "PhysicsSystem.mSimShapeFilter has unexpected size % instead of 8", it.type.runtime_size);
                case "mSimCollideBodyVsBody";
                    assert(it.offset_in_bytes == 576, "PhysicsSystem.mSimCollideBodyVsBody has unexpected offset % instead of 576", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "PhysicsSystem.mSimCollideBodyVsBody has unexpected size % instead of 64", it.type.runtime_size);
                case "mPhysicsSettings";
                    assert(it.offset_in_bytes == 640, "PhysicsSystem.mPhysicsSettings has unexpected offset % instead of 640", it.offset_in_bytes);
                    assert(it.type.runtime_size == 84, "PhysicsSystem.mPhysicsSettings has unexpected size % instead of 84", it.type.runtime_size);
                case "mContactManager";
                    assert(it.offset_in_bytes == 728, "PhysicsSystem.mContactManager has unexpected offset % instead of 728", it.offset_in_bytes);
                    assert(it.type.runtime_size == 240, "PhysicsSystem.mContactManager has unexpected size % instead of 240", it.type.runtime_size);
                case "mConstraintManager";
                    assert(it.offset_in_bytes == 968, "PhysicsSystem.mConstraintManager has unexpected offset % instead of 968", it.offset_in_bytes);
                    assert(it.type.runtime_size == 120, "PhysicsSystem.mConstraintManager has unexpected size % instead of 120", it.type.runtime_size);
                case "mIslandBuilder";
                    assert(it.offset_in_bytes == 1088, "PhysicsSystem.mIslandBuilder has unexpected offset % instead of 1088", it.offset_in_bytes);
                    assert(it.type.runtime_size == 112, "PhysicsSystem.mIslandBuilder has unexpected size % instead of 112", it.type.runtime_size);
                case "mLargeIslandSplitter";
                    assert(it.offset_in_bytes == 1200, "PhysicsSystem.mLargeIslandSplitter has unexpected offset % instead of 1200", it.offset_in_bytes);
                    assert(it.type.runtime_size == 64, "PhysicsSystem.mLargeIslandSplitter has unexpected size % instead of 64", it.type.runtime_size);
                case "mStepListenersMutex";
                    assert(it.offset_in_bytes == 1264, "PhysicsSystem.mStepListenersMutex has unexpected offset % instead of 1264", it.offset_in_bytes);
                    assert(it.type.runtime_size == 88, "PhysicsSystem.mStepListenersMutex has unexpected size % instead of 88", it.type.runtime_size);
                case "mStepListeners";
                    assert(it.offset_in_bytes == 1352, "PhysicsSystem.mStepListeners has unexpected offset % instead of 1352", it.offset_in_bytes);
                    assert(it.type.runtime_size == 24, "PhysicsSystem.mStepListeners has unexpected size % instead of 24", it.type.runtime_size);
                case "mGravity";
                    assert(it.offset_in_bytes == 1376, "PhysicsSystem.mGravity has unexpected offset % instead of 1376", it.offset_in_bytes);
                    assert(it.type.runtime_size == 16, "PhysicsSystem.mGravity has unexpected size % instead of 16", it.type.runtime_size);
                case "mPreviousStepDeltaTime";
                    assert(it.offset_in_bytes == 1392, "PhysicsSystem.mPreviousStepDeltaTime has unexpected offset % instead of 1392", it.offset_in_bytes);
                    assert(it.type.runtime_size == 4, "PhysicsSystem.mPreviousStepDeltaTime has unexpected size % instead of 4", it.type.runtime_size);
            }
        }
        assert(size_of(PhysicsSystem) == 1408, "PhysicsSystem has size % instead of 1408", size_of(PhysicsSystem));
    }
}

