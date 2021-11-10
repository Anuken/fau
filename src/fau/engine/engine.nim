import ../../ecs, ../g3/[mesh3, fmath3], shading

#COMPLETELY UNFINISHED!

registerComponents(defaultComponentOptions):
  type

    Transform* = object
      pos*: Vec3
      scale*: Vec3
      rot*: Quat
    RenderMesh* = object
      mesh*: proc() #need a function pointer, because mesh types are generic
      material*: Material

sys("renderMesh", [RenderMesh]):
  all:
    discard

#[
TODO query about:
- empty systems
- big O complexity of fetching arbitrary components
  - ANSWER: O(N), where N is the number of components. Not great.
- feasibility of a tree system for scenes
  - see more thoughts below

To resolve:
- do I need deferred lighting, deferred shading, or forward rendering?
- there's even 'tiled forward rendering'... so many options
- https://docs.unity3d.com/Manual/RenderTech-DeferredShading.html implies that deferred [anything] is pretty advanced and shouldn't be used for something this simple
- do I need PBR?

Per pixel or per vertex?
- more info: https://docs.unity3d.com/Manual/RenderTech-ForwardRendering.html
- what the heck is https://en.wikipedia.org/wiki/Spherical_harmonic_lighting ?

SCENE GRAPH:
- have a system that simply iterates over Child components and updates transform based on parent transforms
  - but isn' this slow? fetching parent and then fetching parent transform is... expensive, unless it uses ComponentRefs or something. is that possible?
- could have some caching or "dirty" flag, e.g. a ChangedTransform component
- transform resolved in a TransformSystem that takes pos/rot/scale and shoves it into the transform matrix
- how do you make sure that parents update first, though?

Order of operations:
User has a bunch of entities that have transform and optionally mesh components

1. transform: resolve all parent-child transforms and write to their resulting transform - this is recursive (maybe should be implemented as a stack?)
  - see https://github.com/JoeyDeVries/Cell/blob/master/cell/scene/scene_node.cpp#L154 for Cell impl
  - only called from root scene node
  - only done for modified nodes
  - sounds kinda inefficient to me (?)
2. culling: iterate through all meshes, check for intersection with camera frustum, add to command buffer if so
  - can probably be parallelized?
  - here's what one engine does: https://github.com/htmlboss/OpenGL-Renderer/blob/c466f657582f3e76bb71ec8d5a051fcb19dac946/MP-APS/Engine.cpp#L137
3. sorting: sort all meshes in command buffer by 1) transparency, then 2) by material/shader ID
4. draw everything in the command buffer

TODO look into glUniformBlockBinding, fallbacks, and see what versions are supported
see https://www.khronos.org/opengl/wiki/Uniform_Buffer_Object
also look at that nim engine that sets light uniforms manually, maybe that's an ok option
writing two different shaders may have to be an option.
- alternatively, profile and see how bad it is - if lights don't change often, it might not be that big of a deal to change all the light uniforms.


RESEARCH:

- Scene graph:
  - do I need one? https://blog.blackshift.foon.uk/2016/05/why-i-dont-need-scene-graph.html
  - tl;dr no


]#