# Coeus

Coeus is a 3D game engine in pure LuaJIT with a focus on fast development and high quality games. Currently confirmed to run on both Windows and Linux. Check out some of the demos in our [Coeus Demos Repository](https://github.com/titan-studio/coeus-demos)

Official IRC is at #titan-interactive on irc.freenode.net.

Binaries for Windows (32-bit) are published in the GitHub releases section. They were built with Visual Studio 2013. You'll still need a LuaJIT install with LuaFileSystem, however, and it might need to be built with Visual Studio as well. This might change in the future.

## Features
Coeus aims to be a full featured suite for developing games and virtual reality simulations. As such, there will soon be many layers of tools for every step of the process of creating a game catering to every position in a typical game studio.

The following is a high level list of Coeus's features so far:
- Engine code written entirely in LuaJIT
- High performance graphics core based on OpenGL 3.2
- Windows and Linux support
- OpenAL-based sound engine
- Support for PNG image files
- Support for IQE and OBJ 3D model files
- Support for Ogg Vorbis sound files
- Streamlined asset loading system
- Threading through TinyCThread
- Deferred shading with point and directional lights
- Mersenne Twister pseudorandom number generator
- Powerful OOP semantics with multiple inheritance and mixins
- Solid, unit-tested math library (Vector2, Vector3, Quaternion, and Matrix4)

# Main Setup

## Windows (Automatic)
Run `install.bat` and select a location to install to, like `C:\coeus`. Copy your binaries to the `bin` folder inside of it, like `C:\coeus\bin`. The environment variables `COEUS_SRC_PATH` and `COEUS_BIN_PATH` will be set automatically.

## Windows (Manual)
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
At the present, all of the following should be compiled to dynamic libraries:
- LuaJIT 2.0.3
- LuaFileSystem
- OpenGL 3.3
- OpenAL-soft 1.1 (named openal.dll on Windows)
- GLFW 3.0.4 (named glfw3.dll on Windows)
- libvorbis 1.3.4
- libogg 1.3.2
- zlib 1.2.8 (named zlib1 on Windows)
- coeus_aux, which includes:
	- lodepng 20140624
	- stb_freetype v0.8b
	- TinyCThread 1.1

# Project Setup
Coeus projects should contain a file called `main.lua` with your application's entry point, and one or more configuration files named `config-*.lua` for different configurations. A typical `main.lua` might look like this:

```lua
--main.lua
local config = require("config-debug")
local C = require("Coeus")
C:Initialize(config)

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
