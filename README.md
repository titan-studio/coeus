# Coeus

Coeus is a 3D game engine in pure LuaJIT with a focus on fast development and high quality games. Currently confirmed to run on both Windows and Linux. Check out some of the demos in our [Coeus Demos Repository](https://github.com/titan-studio/coeus-demos)

Official IRC is at #titan-interactive on irc.freenode.net.

Binaries will be released in the releases section.

## Status
Coeus is currently undergoing a large rewrite to reorganize most of the engine. Check the `legacy` branch for the old codebase for the unreleased 0.2.0 version.

## Features
Coeus aims to be a full featured suite for developing games and virtual reality simulations. As such, there will soon be many layers of tools for every step of the process of creating a game catering to every position in a typical game studio.

# Main Setup
Stay tuned for the rewrite of Coeus to see new installation instructions.

# Dependencies
At the present, all of the following should be compiled to dynamic libraries:
- LuaJIT 2.1 alpha (will be bundled)
- LuaFileSystem
- OpenGL 3.3
- OpenAL-soft 1.1 (named openal.dll on Windows)
- GLFW 3.1 (needs to be updated)
- libvorbis 1.3.4
- libogg 1.3.2
- zlib 1.2.8 (named zlib1 on Windows)
- LibCoeus, which includes:
	- lodepng 20141130 (needs to be updated)
	- stb_freetype v1.02 (needs to be updated)
	- TinyCThread 1.1