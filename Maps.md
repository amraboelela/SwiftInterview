# Maps Rendering Engine — Swift Developer Interview

# Relevant Experience

## MapKit & CoreLocation

**GlobalLocator** — custom base-32 coordinate encoding (lat/lon ↔ short alphanumeric code). Deep use of `MKCoordinateRegion`, `MKLocalSearch`, span interpolation. Multi-platform iOS/macOS/watchOS Swift package.

**GoWalkin** — production SwiftUI `Map` with `MapCameraPosition`, `UserAnnotation`, `Annotation`. `LocationManager`: async/await + `CLLocationManager` via `CheckedContinuation`, geofence monitoring, `@MainActor` isolation.

## Unity Engine (Alter Learning)

**ALConnect** — led iOS, Android, and Oculus VR for a startup educational gaming app. Games built in Unity (C++ engine), integrated with Swift/Kotlin native layers. Closest parallel to a maps rendering engine: C++ engine core + native wrapper handling OS integration, engine owns the render loop, scene graph, and asset pipeline.

## Apple & AI / ML

Three Apple stints (IS&T 2024–2026, Backstage 2012–2014, IT 2010–2011). **Muhaffez** — PyTorch transformer → CoreML/TFLite, hybrid search pipeline. M.Sc. Image Processing (U of Western Ontario). Open-source Swift: apple/swift #4788, swift-corelibs-foundation, libdispatch.

---

# Swift ↔ C++ Interoperability & Migration

## Q: How does Swift/C++ interoperability work (Swift 5.9+)?

Swift can directly import C++ headers without an Objective-C++ bridge:

```swift
// module.modulemap
module MyCppLib { header "Engine.h"; requires cplusplus }

// Swift
import MyCppLib
let engine = CppRenderEngine()
engine.renderFrame()
```

**Works automatically:** C++ structs/classes, methods, `std::vector<T>`, namespaces (become Swift enums).

**Still needs a bridge:** templates (expose via `typedef`/`using` aliases), operator overloads, C++ exceptions (wrap in `noexcept` boundary).

## Q: What is the strangler fig migration pattern?

Build the Swift system alongside C++, migrating one subsystem at a time — never a big-bang rewrite. Phase 1: Swift wraps C++ (unchanged core). Phase 2: replace subsystems one by one. Phase 3: Swift is the core, C++ shims cover whatever remains. Both run in production simultaneously; each migrated subsystem has parity tests before the C++ version is deleted.

## Q: How do C++ concepts map to Swift?

| C++ | Swift |
|---|---|
| `class` with virtual methods | `protocol` + conformance |
| Templates | Generics with protocol constraints |
| `std::unique_ptr<T>` | Value type `struct` or `class` + ARC |
| `std::shared_ptr<T>` | `class` with ARC |
| RAII destructor | `deinit` / `defer` |
| `std::optional<T>` | `T?` |
| `std::variant<A,B>` | `enum` with associated values |
| `std::vector<T>` | `ContiguousArray<T>` |
| `const T&` param | `borrowing` (Swift 5.9+) |
| `T&&` move | `consuming` (Swift 5.9+) |
| `inline` | `@inline(__always)` |

## Q: What is `borrowing` / `consuming` and why does engine code need it?

```swift
func render(mesh: borrowing Mesh) { ... }    // no copy — like const T&
func upload(mesh: consuming Mesh) -> GPUBuffer { ... }  // takes ownership — like T&&
func transform(mesh: inout Mesh, by m: float4x4) { ... } // in-place — like T&
```

`borrowing` eliminates copies on hot paths. `consuming` makes resource transfer explicit — compiler prevents use-after-move bugs.

---

# Performance-Critical Swift

## Q: How do you write high-performance Swift for a rendering engine?

- `ContiguousArray<SIMD3<Float>>` — guaranteed contiguous storage, cache-friendly, no bridging overhead.
- SIMD math compiles to single hardware instructions: `mvp * SIMD4<Float>(pos, 1)`, `dot(normal, lightDir)`.
- `@inline(__always)` on hot-path functions eliminates call overhead.
- `borrowing` parameters avoid copies; `Unmanaged` avoids ARC retain/release in tight loops.
- Bulk GPU writes: `buffer.contents().withMemoryRebound(to: Vertex.self, capacity: n) { ptr in ... }`

## Q: How do Swift actors fit into a rendering engine?

Actors isolate mutable state across concurrent systems (tile decoder, network, GPU encoder):

```swift
actor TileCache {
    private var tiles: [TileID: GPUTile] = [:]
    func insert(_ tile: GPUTile, for id: TileID) { tiles[id] = tile }
    func tile(for id: TileID) -> GPUTile? { tiles[id] }
}
```

**Critical rule:** never `await` across actor boundaries mid-frame — that yields execution and risks missing the frame deadline. All async work happens between frames; the frame encode runs synchronously.

---

# Metal & GPU — Geometry Concepts

## Q: What is a Vertex, Mesh, Material, and Model?

A **vertex** is one point in 3D space with attributes. A **mesh** is a collection of vertices plus an index buffer describing how they connect into triangles. A **material** describes how the surface looks when light hits it. A **model** is a higher-level container bundling one or more meshes together with their materials, skeleton, animations, and transform hierarchy — what you import from a `.usdz`, `.fbx`, or `.obj` file.

```
Model (e.g. person.usdz)
 ├── Mesh: body skin    + Material: skin shader + albedo texture
 ├── Mesh: eyes         + Material: glossy eye shader
 ├── Mesh: hair         + Material: alpha-blended hair shader
 └── Mesh: clothing     + Material: fabric shader (swappable)
```

**Can a person be one mesh?** Technically yes — a simple game character can be a single mesh. But in practice people are multiple meshes because:
- Different body parts need different shaders (hair uses alpha transparency; eyes need specular highlights).
- Clothing meshes can be swapped independently.
- LOD — you can replace just the hair mesh with a lower-poly version at distance.
- Rigging — a skeleton deforms each mesh; separating them makes weight painting easier.

```swift
struct Vertex {
    var position: SIMD3<Float>  // XYZ location
    var normal:   SIMD3<Float>  // surface direction for lighting
    var uv:       SIMD2<Float>  // texture coordinate
}
// 32 bytes/vertex. 100k vertices = 3.2 MB vertex buffer.

struct Material {
    var baseColor: SIMD4<Float>       // RGBA tint
    var metallic:  Float              // 0 = plastic, 1 = metal
    var roughness: Float              // 0 = mirror, 1 = diffuse
    var albedoTexture:  MTLTexture?   // base colour map
    var normalTexture:  MTLTexture?   // fake surface detail
}
```

**Mesh analogy:** a fisherman's net — vertices are the knots, edges are the threads, faces are the cells. A real fisherman's net is actually **quads** (rectangles), not triangles. And in a net the cells are open holes — but in rendering every face is a **filled solid triangle**.

**Do faces have to be triangles?** No — 3D modeling tools work with quads and n-gons because they're easier to sculpt. But the GPU only draws triangles, so the engine **triangulates** before uploading: every quad is split into 2 triangles, every n-gon into however many needed. This happens once at asset import time.

```
Quad:          Triangulated:
A --- B        A --- B
|     |   →    |  ↗  |
D --- C        D --- C
Indices: [A,B,D,  B,C,D]
```

Why triangles? Three points always define exactly one flat plane. A quad can be warped (non-planar), making shading ambiguous. Triangle rasterisation is also simple and parallelisable — GPU hardware is optimised specifically for it.

**The material** is like the fabric or paint stretched over the net to give it colour and texture.

**Index buffer:** a cube has 8 unique vertices but 36 index entries (6 faces × 2 triangles × 3 indices). Indices reuse vertices to avoid duplicating data.

**Winding order:** counter-clockwise = front face. The GPU back-face culls clockwise triangles (facing away from camera) — halving fragment work. Wrong winding = mesh invisible from outside.

**Material vs Texture:**

A **texture** is just an image stored on the GPU — a grid of pixels (texels). It has no meaning on its own.

A **material** is the recipe that says *how to use* one or more textures together to produce a final surface appearance. The material owns the textures and tells the shader: "sample this image for colour, that image for bump detail, this greyscale image for shininess."

```
Texture = raw image data (pixels)
Material = shader + textures + scalar values (metallic, roughness…)
           → combined by the fragment shader to produce final pixel colour
```

Analogy: a texture is a tin of paint; a material is the painter's instructions — which tin, where, matte or gloss.

**Material textures:**

| Texture | Effect |
|---|---|
| Albedo / diffuse | Surface colour in white light |
| Normal map | Fake bumps without extra geometry |
| Roughness map | Per-pixel shiny vs matte |
| Emissive map | Self-illuminated areas (windows, signs) |

## Q: What is SIMD?

**SIMD** (Single Instruction, Multiple Data) — one CPU instruction operates on multiple values simultaneously instead of one at a time. A renderer transforms millions of vertices per frame; SIMD makes that practical.

```swift
// Without SIMD: 4 adds. With SIMD: 1 instruction.
let moved = position + offset          // SIMD3<Float> add
let clipPos = mvp * SIMD4<Float>(p, 1) // matrix × vector
let dir = simd_normalize(target - eye)
```

**GPU data types — Swift ↔ Metal:**

| Swift | Metal | Bytes | Used for |
|---|---|---|---|
| `Float` | `float` | 4 | Scalar: time, alpha |
| `SIMD2<Float>` | `float2` | 8 | UV, screen pos |
| `SIMD3<Float>` | `float3` | 12 | Position, normal, RGB |
| `SIMD4<Float>` | `float4` | 16 | Clip-space pos, RGBA |
| `float3x3` | `float3x3` | 36 | Normal matrix |
| `float4x4` | `float4x4` | 64 | Model / View / Projection / MVP |
| `simd_quatf` | — | 16 | Rotation (no gimbal lock) |
| `Float16` / `half` | `half` | 2 | Compressed colour, UV |
| `Vertex` (struct) | `struct Vertex` | varies | Full point attributes → vertex buffer |

Structs crossing the CPU/GPU boundary must use SIMD types — mismatched layout causes silent GPU data corruption.

## Q: What is the difference between a Buffer and a Data Type?

A **data type** (e.g. `Vertex`, `Uniforms`, `float4x4`) is the blueprint — it defines what bytes mean. A **buffer** (`MTLBuffer`) is allocated GPU memory holding instances of that type.

```swift
// Blueprint — no memory yet
struct Vertex { var position: SIMD3<Float>; var uv: SIMD2<Float> }

// Allocated GPU memory
let buffer = device.makeBuffer(
    length: 1000 * MemoryLayout<Vertex>.stride,
    options: .storageModeShared)!

// Write (CPU), bind (GPU reads via the Vertex type)
buffer.contents().bindMemory(to: Vertex.self, capacity: 1000)[0]
    = Vertex(position: [0,0,0], uv: [0,0])
encoder.setVertexBuffer(buffer, offset: 0, index: 0)
```

`MTLStorageMode.shared` — zero-copy on Apple Silicon (same DRAM). `MTLStorageMode.private` — GPU-only, fastest for static meshes, requires a blit from a staging buffer.

## Q: What are Uniforms?

A `Uniforms` struct holds per-frame constants every shader reads (MVP matrices, camera pos, time). Uploaded once per frame into a small `MTLBuffer` and bound to both vertex and fragment stages:

```swift
struct Uniforms {
    var mvp:          float4x4
    var normalMatrix: float3x3
    var cameraPos:    SIMD3<Float>
    var time:         Float
}
encoder.setVertexBuffer(uniformBuffer,   offset: 0, index: 1)
encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)
```

**`float4x4` in detail:** every vertex goes through Model × View × Projection. Normal vectors use `float3x3(model).inverse.transpose` — translation from `float4x4` would corrupt them.

## Q: What is the difference between Camera, View matrix, and Projection matrix?

**Camera** — the conceptual object: position in the world, direction it looks, field of view, near/far clip planes. It's the "eye." Not a matrix itself — just the data you use to build the matrices.

**View matrix** — transforms world space into camera space, making the camera the origin facing −Z. Built from camera position, look-at target, and up vector:

```swift
let view = float4x4(eye: cameraPos, target: lookAt, up: SIMD3(0,1,0))
```

**Projection matrix** — transforms camera space into clip space, applying perspective (far objects appear smaller). Defined by field of view, aspect ratio, and near/far planes:

```swift
let projection = float4x4(perspectiveProjectionFov: .pi/3, aspectRatio: 16/9,
                           nearZ: 0.1, farZ: 1000)
```

The full vertex transform pipeline:

```
Local space →[Model]→ World space →[View]→ Camera space →[Projection]→ Clip space → Screen
```

**Tile vs Mesh Face:**

A **mesh face** is one triangle — the smallest unit of geometry in a 3D model.

A **tile** is a geographic chunk of map data (geometry + textures + labels) for a rectangular region of the world at a specific zoom level. It is not a single triangle — it contains many meshes (road meshes, building meshes, terrain mesh) that together cover that patch of the map.

| | Mesh face | Tile |
|---|---|---|
| What it is | One triangle (3 vertices) | A geographic region's worth of scene data |
| Scale | Microscopic — part of a model | Kilometers of real-world area |
| Content | 3 vertices + indices | Many meshes, textures, labels, metadata |
| Loaded | At model import time | Streamed on demand as camera moves |
| LOD | Fewer faces at distance | Lower zoom level (coarser) tile at distance |

---

# Metal & GPU Pipeline

## Q: How does the Metal draw call pipeline work?

```
MTLDevice → MTLCommandQueue → MTLCommandBuffer
  → MTLRenderCommandEncoder
      .setRenderPipelineState(pso)
      .setVertexBuffer(vertexBuf, offset:0, index:0)
      .setFragmentTexture(albedo, index:0)
      .drawIndexedPrimitives(.triangle, indexCount:n, ...)
  .endEncoding()
commandBuffer.present(drawable)
commandBuffer.commit()
```

PSOs (Pipeline State Objects) compile vertex + fragment shaders + blend state at load time. Draw calls are near-zero cost — all state pre-validated.

## Q: What is triple buffering?

Keep 3 sets of per-frame uniform buffers. CPU writes `buffers[frame % 3]` while GPU reads from the previous frame's. A `DispatchSemaphore(value: 3)` prevents the CPU from lapping the GPU.

## Q: What is a render graph?

Declarative description of all render passes with explicit resource read/write declarations. The engine derives optimal barrier placement and aliases transient render targets (SSAO, TAA history) — reducing peak GPU memory 30–50%. Popularised by Frostbite (GDC 2017).

---

# Engine Architecture (Unity-Style in Swift)

## Q: What are the core engine subsystems?

| Subsystem | Responsibility |
|---|---|
| Scene graph / ECS | Entities, components, transforms, parent-child hierarchy |
| Render loop | Fixed-timestep update → variable-rate render |
| Asset pipeline | Load, cache, stream, hot-reload meshes/textures/shaders |
| Resource manager | Ref-counted GPU resource lifetime |
| Command buffer layer | Batch draw calls, sort by PSO/material |
| Camera system | View/projection matrix, frustum culling, LOD |
| Concurrency layer | Worker threads for physics/audio/assets; sync before GPU submit |

## Q: What is ECS and how do you implement it in Swift?

Entity-Component-System separates data (components) from logic (systems) — cache-friendly memory, parallelisable updates, no deep OOP inheritance. Each component type lives in its own `ContiguousArray` so iterating 10k entities hits L1 cache, not pointer chains across the heap:

```swift
typealias EntityID = UInt32
struct Transform: Component { var position: SIMD3<Float>; var rotation: simd_quatf; var scale: SIMD3<Float> }

final class ComponentStore<C: Component> {
    private var components: ContiguousArray<C> = []
    private var index: [EntityID: Int] = [:]
    func add(_ c: C, for e: EntityID) { index[e] = components.count; components.append(c) }
    func get(for e: EntityID) -> C? { index[e].map { components[$0] } }
}
func renderSystem(transforms: ComponentStore<Transform>, entities: [EntityID]) {
    for e in entities { if let t = transforms.get(for: e) { submitDrawCall(transform: t) } }
}
```

## Q: How do you implement camera fly-over of a metropolitan area?

A fly-over animates the camera along a **Catmull-Rom spline** through waypoints each frame, while an actor streams tiles asynchronously and LOD switches with altitude:

```swift
// Smooth spline — advance flightT each frame, sample eye position
func catmullRom(_ p0: SIMD3<Float>, _ p1: SIMD3<Float>,
                _ p2: SIMD3<Float>, _ p3: SIMD3<Float>, t: Float) -> SIMD3<Float> {
    let t2 = t*t, t3 = t2*t
    return 0.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t2+(-p0+3*p1-3*p2+p3)*t3)
}
// Per frame: update camera view from spline, tile streamer reacts to altitude
actor TileStreamer {
    func updateVisible(camera: Camera) async {
        for id in quadTree.visibleTiles(for: camera) where cache[id] == nil {
            Task { cache[id] = await fetchTile(id) }
        }
    }
}
```

Lower altitude → higher-detail tiles; higher altitude → coarser tiles to stay within GPU budget.

---

# Research-Grade Rendering (SIGGRAPH Topics)

**Key SIGGRAPH topics and brief answers:**

- **TAA** — accumulates jittered frames using a history buffer; near-free vs 4–8× MSAA; needs velocity buffer + neighbourhood clamping.
- **Mesh shaders** — replace vertex + tessellation pipeline; GPU generates vertices directly; eliminates CPU tessellation; available on Apple Silicon.
- **Neural upscaling** — render at 75% resolution, reconstruct with ML (DLSS/FSR style) via MPS/CoreML; big battery saving on mobile.
- **SDF text** — glyphs stored as signed distance fields; render at any size with one texture sample.
- **PBR** — physically based rendering; Cook-Torrance BRDF; `metallic` + `roughness` drives specular vs diffuse.
- **SSAO** — screen-space ambient occlusion; darkens crevices cheaply using depth buffer samples.
- **Gaussian splatting** — represents scenes as 3D Gaussians rather than meshes; fast novel-view synthesis.

---

# AI-Assisted Development: Top-Down Instead of Bottom-Up

## Q: How do AI tools change the engineering workflow?

Traditional development is **bottom-up** — raw primitives → utilities → subsystems → features → UX. Weeks of groundwork before anything visible works.

AI-assisted development is **top-down** — describe the intent, AI generates the scaffolding beneath it. Working prototype in hours; engineer refines from there.

Applied to a C++ → Swift engine migration: describe the subsystem, AI generates a Swift candidate, engineer reviews for correctness and edge cases, iterate on the hard parts (ownership, unsafe pointers, threading). The engineer shifts from **writing every line** to **directing intent and verifying correctness**.

**Risks:** AI code can be plausible but wrong — especially unsafe memory, threading, GPU alignment. Top-down can produce brittle foundations if the engineer doesn't understand the layers AI filled in. AI raises the floor; the ceiling — architecture, performance, concurrency correctness — is still entirely the engineer's job.

---

# Compiling, Pipelining, and Looping in a Renderer

## Q: What does "compiling" mean in a rendering engine?

Three different things get compiled, at three different times:

**1. Swift/C++ source → binary (build time)**
Normal Xcode compilation. The engine code becomes a native binary.

**2. Shaders → GPU bytecode (load time)**
Metal Shading Language (`.metal` files) are compiled into GPU machine code when the app launches. This is done via `MTLLibrary` and `MTLRenderPipelineState` (PSO). Shader compilation is slow (100ms+), so it always happens at load time — never mid-frame.

```swift
let lib  = device.makeDefaultLibrary()!
let desc = MTLRenderPipelineDescriptor()
desc.vertexFunction   = lib.makeFunction(name: "vertexShader")!
desc.fragmentFunction = lib.makeFunction(name: "fragmentShader")!
let pso = try! device.makeRenderPipelineState(descriptor: desc)
```

**3. Style / asset compilation (pipeline time)**
Map style JSON, tile data, and meshes are compiled into optimised binary formats before streaming to the device.

## Q: What is pipelining in a renderer?

A GPU **pipeline** is the fixed sequence every triangle passes through on its way to a pixel:

```
Vertex shader → Rasterisation → Fragment shader → Blending → Framebuffer
```

- **Vertex shader** — transforms each vertex from 3D world space to 2D screen space using the MVP matrix.
- **Rasterisation** — GPU determines which pixels each triangle covers.
- **Fragment shader** — runs once per covered pixel; samples textures, computes lighting, outputs colour.
- **Blending** — combines fragment colour with the framebuffer (for transparency).

**PSO (Pipeline State Object):** bundles vertex + fragment shader + blend state into one pre-compiled object. Switching PSOs is expensive — sort draw calls by PSO to minimise switches.

**CPU/GPU overlap:** while the GPU renders frame N, the CPU encodes frame N+1. Triple buffering makes this safe.

## Q: What is the render loop?

The heartbeat of the engine — runs every frame (60/120 Hz) driven by `CADisplayLink`:

```
1. Update  — physics, animation, transform propagation
2. Cull    — frustum cull entities not visible to the camera
3. Encode  — record draw calls into MTLCommandBuffer (CPU)
4. Commit  — submit command buffer to the GPU
5. Present — display framebuffer when GPU finishes
```

Must complete in **16.6 ms** (60 Hz) or **8.3 ms** (120 Hz). Work that can't finish in time moves to a background thread and double-buffers its results in for the next frame.

---

## General Interview Tips

- Ask what migration phase they're at and what C++ patterns are hardest to port.
- Show Swift/C++ interop depth — modulemap setup, what works automatically, what needs a bridge.
- Mention SIMD, `borrowing`/`consuming`, `ContiguousArray`, `@inline(__always)`, unsafe buffers — signals performance-critical Swift.
- Swift 6 strict concurrency is a common pain point — know how actors isolate state without blocking the render loop.
- Apple Silicon unified memory (`MTLStorageMode.shared`) eliminates GPU upload cost — worth mentioning.
- Open-source Swift compiler contributions (apple/swift #4788, foundation, libdispatch) show language-runtime-level experience.

---

## YouTube Resources

### Swift ↔ C++ Interoperability
- [WWDC25: Safely Mix C, C++, and Swift — Apple](https://www.youtube.com/watch?v=fFPq_4_LCqo)
- [WWDC23: Mix Swift and C++ — Apple](https://www.youtube.com/watch?v=MixEUoUQyNU)
- [try! Swift Tokyo 2024 — Porting a Game to Swift](https://www.youtube.com/watch?v=P1IwI0Wh-Rg)
- [Mixing C++ and Swift — From Obj-C Bridging to Direct Interop](https://www.youtube.com/watch?v=sNWzGyS2gG0)
- [Calling C and C++ from iOS Swift](https://www.youtube.com/watch?v=SsqsRfvbJOI)

### Swift Performance & Low-Level
- [Swift's Pointy Bits: Unsafe Swift & Pointer Types](https://www.youtube.com/watch?v=zFEpNtAZi9o)
- [4× Code Performance with SIMD](https://www.youtube.com/watch?v=Imj4ROIiMw0)
- [What Are SIMD Instructions?](https://www.youtube.com/watch?v=vIRjSdTCIEU)
### Swift Concurrency & Actors
- [WWDC21: Protect Mutable State with Swift Actors](https://www.youtube.com/watch?v=9Nqox5SeYEM)
- [WWDC21: Swift Concurrency Behind the Scenes](https://www.youtube.com/watch?v=f-re0WpYzZo)
### Engine Architecture & Unity
- [SIGGRAPH 2021 REAC: Unity Rendering Architecture](https://www.youtube.com/watch?v=6LzcXPIWUbc)
- [Introduction to the Render Graph in Unity 6](https://www.youtube.com/watch?v=U8PygjYAF7A)
- [ECS Game Development Architecture](https://www.youtube.com/watch?v=6djXCScdK54)
- [Render System — ECS Data into Visuals](https://www.youtube.com/watch?v=pzUIiwVhIco)
- [Scene Graph — 3D Game Engine Tutorial](https://www.youtube.com/watch?v=ktz9AlMSEoA)
- [SIGGRAPH 2021 Rendering Engine Architecture Course](https://www.youtube.com/playlist?list=PLAOytOz0HZbLaWhVrGEge5_6dNCAzGFYH)
### Metal Framework & Engine in Swift
- [WWDC22: Metal Mesh Shaders — Apple](https://www.youtube.com/watch?v=uVfj79_bZsU)
- [Metal Performance Best Practices — Apple 2023](https://www.youtube.com/watch?v=LXTUFmbZwec)
- [Swift Game Engine with Metal Intro](https://www.youtube.com/watch?v=PcA-VAybgIQ)
- [Custom 2D Game Engine in Swift and MetalKit](https://www.youtube.com/watch?v=PdSDsf7rqkI)
- [Programming Metal in iOS — Full Playlist](https://www.youtube.com/playlist?list=PL23Revp-82LJG3vcDPm8w7b5HTKjBOY0W)

### Research-Grade Rendering
- [TAA — Temporal Anti-Aliasing Deep Dive](https://www.youtube.com/watch?v=WG8w9Yg5B3g)
- [Mesh Shaders — How Do They Work?](https://www.youtube.com/watch?v=8NNnMwcb-hM)
- [Upscaling Explained — DLSS vs FSR](https://www.youtube.com/watch?v=Chpb3yNypxY)
- [Glyphs, Shapes, Fonts, Signed Distance Fields](https://www.youtube.com/watch?v=1b5hIMqz_wM)
- [PBR Explained in 3 Minutes](https://www.youtube.com/watch?v=_ZbkOZNgwNk)
- [Advances in Neural Rendering — SIGGRAPH 2021](https://www.youtube.com/watch?v=otly9jcZ0Jg)
