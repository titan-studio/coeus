# Coeus Game Engine

Coeus is a 3D game engine in pure LuaJIT with a focus on fast development and high quality games. Currently confirmed to run on both Windows and Linux.

Official IRC is at #titan-interactive on irc.freenode.net.

Binaries for Windows (32-bit) are published in the GitHub releases section. They were built with Visual Studio 2013. You'll still need a LuaJIT install with LuaFileSystem, however, and it might need to be built with Visual Studio as well. This might change in the future.

## Dependencies
- LuaJIT 2.0.3
- LuaFileSystem
- OpenGL 3.3
- OpenAL-soft 1.1
- GLFW 3.0.4
- libvorbis 1.3.4
- libogg 1.3.2
- zlib 1.2.8
- lodepng 20140624 (included inline)
- stb_freetype v0.8b (included inline)
- TinyCThread 1.1 (included inline)

## Project Setup
Coeus projects should contain a file called `main.lua` with your application's entry point, and one or more configuration files named `config-*.lua` for different configurations. A typical `main.lua` might look like this:

```lua
--main.lua
local config = require("config-debug")
local Coeus = require("Coeus")
Coeus:Initialize(config)

--Start our game
```

And the associated `config-debug.lua`:

```lua
--config-debug.lua
local config = {
	Debug = true,
	BinDir = "C:/path/to/coeus/bin/win32/", --Path to Coeus binaries
	CoeusDir = "C:/path/to/coeus/src/" --Path to Coeus sources
}

--Update Lua's path to add Coeus automatically
config.SourceDir = config.CoeusDir .. "Coeus/"
package.path = package.path .. ";" .. config.CoeusDir .. "?/init.lua"

return config
```

Running the `main.lua` file should then begin our project.