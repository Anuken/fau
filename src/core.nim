#proxy file for multiple backends

when defined(JS):
    include web/webcore
else:
    #include sdl/sdlcore
    include glfw/glfwcore
