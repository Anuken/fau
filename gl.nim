import gltypes
export gltypes

when defined(JS):
    import web/webgl
else:
    import sdl/sdlgl

#openGL wrapper functions