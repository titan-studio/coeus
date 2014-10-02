# Coeus

Coeus is a 3D game engine in pure LuaJIT with a focus on fast development and high quality games. Currently confirmed to run on both Windows and Linux. Check out some of the demos in our [Coeus Demos Repository](https://github.com/titan-studio/coeus-demos)

Official IRC is at #titan-interactive on irc.freenode.net.

Binaries for Windows (32-bit) are published in the GitHub releases section. They were built with Visual Studio 2013. You'll still need a LuaJIT install with LuaFileSystem, however, and it might need to be built with Visual Studio as well. This might change in the future.

# Main Setup

## Windows
Create a directory to install Coeus. For this example, we'll use `C:\Coeus`. Make sure this directory will not be moved.

Compile all dependencies (or use the dependencies from the 'releases' section of GitHub) and put them into `C:\Coeus\bin`.

Move the `src` directory into your new Coeus folder.

Optionally, create the environment variable `COEUS_SRC_PATH` and set it to `C:\Coeus\src` as well as `COEUS_BIN_PATH`, set to `C:\Coeus\bin`. This lets you use the sample configuration file (given below) for your projects and let LuaJIT automatically locate Coeus.

## Linux / Other Platforms
Create a directory to install Coeus, like `/usr/Coeus`.

Compile all dependencies and make sure they're in your `LD_LIBRARY_PATH` so LuaJIT can load them.

Move the `src` directory into your new Coeus folder.

Optionally, create the environment variable `COEUS_SRC_PATH` and set it to `/usr/Coeus/src`. This lets you use the sample configuration file (given below) for your projects and let LuaJIT automatically locate Coeus.

# Dependencies
- LuaJIT 2.0.3
- LuaFileSystem
- OpenGL 3.3
- OpenAL-soft 1.1
- GLFW 3.0.4
- libvorbis 1.3.4
- libogg 1.3.2
- zlib 1.2.8
- coeus_aux, which includes:
	- lodepng 20140624
	- stb_freetype v0.8b
	- TinyCThread 1.1

# Project Setup
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

	--Automatically determine where Coeus is located through environment variables
	BinDir = os.getenv("COEUS_BIN_PATH"),
	SourceDir = os.getenv("COEUS_SRC_PATH")
}

--update path to add Coeus
package.path = package.path .. ";" .. config.SourceDir .. "?/init.lua"

return config
```

Running the `main.lua` file should then run our project.