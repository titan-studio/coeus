local PATH = (...)
local lfs = require("lfs")
local Coeus

local function name_to_file(name)
	return name:gsub("%.", "/") .. ".lua"
end

local function file_to_name(name)
	return name:gsub("%.[^%.]*$", ""):gsub("/", "%.")
end

local function name_to_directory(name)
	return name:gsub("%.", "/")
end

local function name_to_id(name)
	return name:lower()
end

local Coeus = {
	Root = PATH .. ".",
	Version = {0, 0, 0},

	vfs = {},
	loaded = {},
	meta = {}
}

function Coeus:Load(name, safe)
	local abs_name = self.Root .. name
	local id = name_to_id(name)

	if (self.loaded[id]) then
		return self.loaded[id]
	elseif (self.vfs[id]) then
		return self:LoadVFSEntry(name, safe)
	end

	local file = name_to_file(abs_name)
	local dir = name_to_directory(abs_name)

	local file_mode = lfs.attributes(file, "mode")
	local dir_mode = lfs.attributes(dir, "mode")

	if (file_mode == "file") then
		return self:LoadFile(name, file, safe)
	elseif (dir_mode == "directory") then
		return self:LoadDirectory(name, dir)
	elseif (not file_mode and not dir_mode) then
		error("Unable to load module '" .. (name or "nil") .. "': file does not exist.")
	else
		error("Unknown error in loading module '" .. (name or "nil") .. "'")
	end
end

function Coeus:LoadChunk(chunk, meta)
	meta = meta or {}
	local success, object = pcall(chunk, self, meta)

	if (not success) then
		error(object)
		return nil, object
	end

	if (meta.id) then
		self.meta[meta.id] = meta

		if (object) then
			self.loaded[meta.id] = object

			return object
		end
	end
end

function Coeus:LoadFile(name, path, safe)
	local id = name_to_id(name)
	local abs_name = self.Root .. name

	if (self.loaded[id]) then
		return self.loaded[id]
	end

	path = path or name_to_file(abs_name)

	local chunk, err = loadfile(path, "b")

	if (not chunk) then
		if (safe) then
			return nil, err
		else
			error(err)
		end
	end

	return self:LoadChunk(chunk, {
		id = id,
		name = name,
		path = path
	})
end

function Coeus:LoadDirectory(name, path)
	local id = name_to_id(name)
	local abs_name = self.Root .. name

	if (self.loaded[id]) then
		return self.loaded[id]
	end

	path = path or name_to_directory(abs_name)

	local container = setmetatable({}, {
		__index = function(container, key)
			local piece = self:Load(name .. "." .. key)
			container[key] = piece

			return piece
		end
	})

	self.loaded[id] = container

	return container
end

function Coeus:FullyLoadDirectory(name, path)
	local abs_name = self.Root .. name
	local id = name_to_id(name)
	path = path or name_to_directory(abs_name)

	local directory = self:LoadDirectory(name, path)

	--This is not quite ideal
	if (self.vfs[id]) then
		for name in pairs(self.vfs) do
			local shortname = name:match("^" .. id .. "%.(.+)$")
			if (shortname) then
				directory[shortname] = self:LoadVFSEntry(name)
			end
		end
	end

	for filepath in lfs.dir(path) do
		if (filepath ~= "." and filepath ~= "..") then
			local filename = file_to_name(filepath)
			directory[filename] = self:Load(name .. "." .. filename)
		end
	end

	return directory
end

function Coeus:GetLoadedModules()
	local buffer = {}
	for key, value in pairs(self.loaded) do
		table.insert(buffer, key)
	end

	table.sort(buffer)

	return buffer
end

function Coeus:LoadVFSEntry(name, safe)
	local id = name_to_id(name)
	local entry = self.vfs[id]

	if (entry.file) then
		local chunk, err = loadstring(entry.body)

		if (not chunk) then
			if (safe) then
				return nil, err
			else
				error(err)
			end
		end

		return self:LoadChunk(chunk, {
			name = name,
			id = id
		})
	elseif (entry.directory) then
		local container = setmetatable({}, {
			__index = function(container, key)
				local piece = self:Load(name .. "." .. key)
				container[key] = piece

				return piece
			end
		})

		self.loaded[id] = container

		return container
	else
		if (safe) then
			return nil, "Could not load VFS entry"
		else
			error("Could not load VFS entry")
		end
	end
end

function Coeus:AddVFSDirectory(name)
	self.vfs[name_to_id(name)] = {directory = true}
end

function Coeus:AddVFSFile(name, body)
	self.vfs[name_to_id(name)] = {file = true, body = body}
end

--Automagically load directories if a key doesn't exist
setmetatable(Coeus, {
	__index = function(self, key)
		self[key] = self:Load(key)

		return self[key]
	end
})

--Load built-in modules
Coeus:AddVFSDirectory('Asset')
Coeus:AddVFSDirectory('Asset.Image')
Coeus:AddVFSDirectory('Asset.Image.Formats')
Coeus:AddVFSDirectory('Bindings')
Coeus:AddVFSDirectory('Entity')
Coeus:AddVFSDirectory('Graphics')
Coeus:AddVFSDirectory('Graphics.Debug')
Coeus:AddVFSDirectory('Graphics.Lighting')
Coeus:AddVFSDirectory('Graphics.Text')
Coeus:AddVFSDirectory('Input')
Coeus:AddVFSDirectory('Math')
Coeus:AddVFSDirectory('Threading')
Coeus:AddVFSDirectory('Utility')
Coeus:AddVFSFile('Application', [==[LJ �local Coeus = (...)
local OOP = Coeus.Utility.OOP
local Timer = Coeus.Utility.Timer

local GLFW = Coeus.Bindings.GLFW
local GL = Coeus.Bindings.OpenGL

local glfw = GLFW.glfw
GLFW = GLFW.GLFW

local gl = GL.gl
GL = GL.GL

local Application = OOP:Class() {
	Window = false,
	Timer = false,

	TargetFPS = 60
}

function Application:_new(window)
	self.Window = window
	self.Timer = Timer:New()
end

function Application:Initialize()
end

function Application:Update(dt)
end

function Application:Render()
end

function Application:Destroy()
end

function Application:Main()
	self:Initialize()
	self.Timer:Step()

	while not self.Window:IsClosing() do
		self.Timer:Step()
		self.Window:Update(self.Timer:GetDelta())
		local start = self.Timer:GetTime()

		self.Window:PreRender()
		self:Render()
	
		local err = gl.GetError()
		if err ~= GL.NO_ERROR then
			error("GL error: " .. err)
		end

		self.Window:PostRender()

		local diff = self.Timer:GetTime() - start
		self.Timer:Sleep(math.max(0, (1 / self.TargetFPS) - diff))
	end
end

return ApplicationW  :  +   7>: G  �New
TimerWindowTimer self  window       	G  self       G  self  dt       	 G  self       	#G  self   � 	Gj&  7  >7  7>7  7>  T9�Q8�7  7>7  77  7> =7  7>7  7>  7	 >+  7
>+ 7 T�4 %  $>7  7>7  7>7  74 7'  7  > =T�G  ��TargetFPSmax	math
SleepPostRenderGL error: 
errorNO_ERRORGetErrorRenderPreRenderGetTimeGetDeltaUpdateIsClosingWindow	Step
TimerInitialize				


gl GL self  Hstart 'err 
diff  � 	   ] >C  7  77  77 77 77777 7	>3
 >1 :1 :1 :1 :1 :1 :0  �H  	Main Destroy Render Update Initialize 	_new 
TimerTargetFPS<Window
ClassGLgl	glfwOpenGL	GLFWBindings
TimerOOPUtility	! $#<&>>Coeus OOP Timer GLFW GL glfw gl Application   ]==])
Coeus:AddVFSFile('Asset.Data', [==[LJ ]local Coeus = ...
local OOP = Coeus.Utility.OOP

local Data = OOP:Class()()

return DataZ    C  7  7 7>>H 
ClassOOPUtilityCoeus OOP Data   ]==])
Coeus:AddVFSFile('Asset.Format', [==[LJ �local Coeus = ...
local OOP = Coeus.Utility.OOP

local Format = OOP:Static()()

function Format:Match(filename)
	return false
end

function Format:Load(filename)
	return {}
end

return Format'    ) H self  filename   '    
2  H self  filename   �   % C  7  7 7>>1 :1 :0  �H  	Load 
MatchStaticOOPUtility
Coeus OOP 
Format   ]==])
Coeus:AddVFSFile('Asset.Image.Formats.PNG', [==[LJ �local Coeus = (...)
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local ImageData = Coeus.Asset.Image.ImageData
local lodepng = Coeus.Bindings.lodepng

local PNG = OOP:Static(Coeus.Asset.Format)()

function PNG:Load(filename)
	local err_code = ffi.new("unsigned int")
	local image_data = ffi.new("unsigned char*[1]")
	local width = ffi.new("unsigned int[1]")
	local height = ffi.new("unsigned int[1]")
	local file_data = ffi.new("unsigned char*[1]")
	local img_size = ffi.new("size_t[1]")

	lodepng.lodepng_load_file(file_data, img_size, filename)
	err_code = lodepng.lodepng_decode32(image_data, width, height, file_data[0], img_size[0])

	if (err_code ~= 0) then
		return nil, {
			code = err_code,
			message = lodepng.lodepng_error_text(err_code)
		}
	end

	local out = ImageData:New()
	out.Width = tonumber(width[0]) or 0
	out.Height = tonumber(height[0]) or 0
	out.image = image_data[0]
	out.size = img_size

	return out
end

function PNG:Match(filename)
	return not not filename:match("%.png$")
end

return PNG� H�
+  7 % >+  7 % >+  7 % >+  7 % >+  7 % >+  7 % >+ 7	 
  >+ 7	 
  8 8 >   T	�)  3	 :	+
 7
	
 >
:

	F + 	 7>4	 8
 >	 	 T
�'	  :	4	 8
 >	 	 T
�'	  :	8	 :	:H ���	size
imageHeighttonumber
WidthNewmessagelodepng_error_text	code  lodepng_decode32lodepng_load_filesize_t[1]unsigned int[1]unsigned char*[1]unsigned intnew 									ffi lodepng ImageData self  Ifilename  Ierr_code Dimage_data @width <height 8file_data 4img_size 0out  M   % 7 % >  H %.png$
matchself  filename   �   H )C  4  % >7 77 777 7 7	7 7
>>1 :1 :0  �H  
Match 	LoadFormatStaticlodepngBindingsImageData
Image
AssetOOPUtilityffirequire#
'%))Coeus ffi OOP ImageData lodepng PNG   ]==])
Coeus:AddVFSFile('Asset.Image.ImageData', [==[LJ �local Coeus = ...
local OOP = Coeus.Utility.OOP

local ImageData = OOP:Class(Coeus.Asset.Format) {
	Width = 0,
	Height = 0,

	image = nil,
	size = nil,
	format = 0,
}

ImageData.Format = {
	RGBA 			= 0,
	Depth			= 1,
	DepthStencil 	= 2
}

return ImageData�   ( C  7  7 77 7>3 >3 :H  DepthStencil
Depth	RGBA  Height 
Width format Format
Asset
ClassOOPUtilityCoeus OOP 
ImageData   ]==])
Coeus:AddVFSFile('Asset.Image.ImageLoader', [==[LJ �local Coeus = ...
local OOP = Coeus.Utility.OOP

local ImageLoader = OOP:Static() {
	Formats = Coeus:FullyLoadDirectory("Asset.Image.Formats")
}

function ImageLoader:Load(path)
	local loader

	for name, member in pairs(self.Formats) do
		if (member:Match(path)) then
			loader = member
			break
		end
	end

	if (not loader) then
		print("Could not find loader for file at " .. (path or "nil"))
		return
	end

	return loader:Load(path)
end

return ImageLoader�   N)  4  7 >D�	 7
 >  T	� T�BN�  T�4 %  T�% $>G   7 @ 	Loadnil'Could not find loader for file at 
print
MatchFormats
pairs

self  path  loader   name member   �  	 . C  7  7 7>3   7 % >:>1 :0  �H  	LoadFormats  Asset.Image.FormatsFullyLoadDirectoryStaticOOPUtilityCoeus OOP ImageLoader 
  ]==])
Coeus:AddVFSFile('Asset.Loader', [==[LJ blocal Coeus = ...
local OOP = Coeus.Utility.OOP

local Loader = OOP:Static()()

return Loader]     C  7  7 7>>H StaticOOPUtilityCoeus OOP Loader   ]==])
Coeus:AddVFSFile('Asset.Stream', [==[LJ alocal Coeus = ...
local OOP = Coeus.Utility.OOP

local Stream = OOP:Class()()

return Stream\     C  7  7 7>>H 
ClassOOPUtilityCoeus OOP Stream   ]==])
Coeus:AddVFSFile('Bindings.coeus_aux', [==[LJ �--Serves only to load the combined coeus_aux DLL
local Coeus = ...
local ffi = require("ffi")
local coeus_aux = (ffi.os == "Windows") and ffi.load("lib/win32/coeus_aux.dll") or ffi.C

return coeus_aux�   ) C  4  % >7 T�7% >  T�7H Clib/win32/coeus_aux.dll	loadWindowsosffirequireCoeus ffi 
coeus_aux 	  ]==])
Coeus:AddVFSFile('Bindings.GLFW', [==[LJ �rlocal Coeus = ...

local ffi = require("ffi")
local glfw
local glfw_lib

if (ffi.os == "Windows") then
	glfw_lib = ffi.load("lib/win32/glfw3.dll")
else
	glfw_lib = ffi.load("libglfw.so.3")
end

glfw = {
	lib = glfw_lib,
	glfw = {},
	GLFW = {},

	import = function(self)
		rawset(_G, "glfw", self.glfw)
		rawset(_G, "GLFW", self.GLFW)

		return self
	end
}

setmetatable(glfw.glfw, {
	__index = function(self, index)
		self[index] = glfw_lib["glfw" .. index]
		return self[index]
	end
})

setmetatable(glfw.GLFW, {
	__index = function(self, index)
		self[index] = glfw_lib["GLFW_" .. index]
		return self[index]
	end
})

glfw.glfw.PollEvents = function()
	return glfw_lib.glfwPollEvents()
end
jit.off(glfw.glfw.PollEvents)

ffi.cdef[[
enum {
	GLFW_VERSION_MAJOR          =3,
	GLFW_VERSION_MINOR          =0,
	GLFW_VERSION_REVISION       =4,

	GLFW_RELEASE                =0,
	GLFW_PRESS                  =1,
	GLFW_REPEAT                 =2,
	GLFW_KEY_UNKNOWN            =-1,

	GLFW_KEY_SPACE              =32,
	GLFW_KEY_APOSTROPHE         =39  /* ' */,
	GLFW_KEY_COMMA              =44  /* , */,
	GLFW_KEY_MINUS              =45  /* - */,
	GLFW_KEY_PERIOD             =46  /* . */,
	GLFW_KEY_SLASH              =47  /* / */,
	GLFW_KEY_0                  =48,
	GLFW_KEY_1                  =49,
	GLFW_KEY_2                  =50,
	GLFW_KEY_3                  =51,
	GLFW_KEY_4                  =52,
	GLFW_KEY_5                  =53,
	GLFW_KEY_6                  =54,
	GLFW_KEY_7                  =55,
	GLFW_KEY_8                  =56,
	GLFW_KEY_9                  =57,
	GLFW_KEY_SEMICOLON          =59  /* ; */,
	GLFW_KEY_EQUAL              =61  /* = */,
	GLFW_KEY_A                  =65,
	GLFW_KEY_B                  =66,
	GLFW_KEY_C                  =67,
	GLFW_KEY_D                  =68,
	GLFW_KEY_E                  =69,
	GLFW_KEY_F                  =70,
	GLFW_KEY_G                  =71,
	GLFW_KEY_H                  =72,
	GLFW_KEY_I                  =73,
	GLFW_KEY_J                  =74,
	GLFW_KEY_K                  =75,
	GLFW_KEY_L                  =76,
	GLFW_KEY_M                  =77,
	GLFW_KEY_N                  =78,
	GLFW_KEY_O                  =79,
	GLFW_KEY_P                  =80,
	GLFW_KEY_Q                  =81,
	GLFW_KEY_R                  =82,
	GLFW_KEY_S                  =83,
	GLFW_KEY_T                  =84,
	GLFW_KEY_U                  =85,
	GLFW_KEY_V                  =86,
	GLFW_KEY_W                  =87,
	GLFW_KEY_X                  =88,
	GLFW_KEY_Y                  =89,
	GLFW_KEY_Z                  =90,
	GLFW_KEY_LEFT_BRACKET       =91  /* [ */,
	GLFW_KEY_BACKSLASH          =92  /* \ */,
	GLFW_KEY_RIGHT_BRACKET      =93  /* ] */,
	GLFW_KEY_GRAVE_ACCENT       =96  /* ` */,
	GLFW_KEY_WORLD_1            =161 /* non-US #1 */,
	GLFW_KEY_WORLD_2            =162 /* non-US #2 */,

	GLFW_KEY_ESCAPE             =256,
	GLFW_KEY_ENTER              =257,
	GLFW_KEY_TAB                =258,
	GLFW_KEY_BACKSPACE          =259,
	GLFW_KEY_INSERT             =260,
	GLFW_KEY_DELETE             =261,
	GLFW_KEY_RIGHT              =262,
	GLFW_KEY_LEFT               =263,
	GLFW_KEY_DOWN               =264,
	GLFW_KEY_UP                 =265,
	GLFW_KEY_PAGE_UP            =266,
	GLFW_KEY_PAGE_DOWN          =267,
	GLFW_KEY_HOME               =268,
	GLFW_KEY_END                =269,
	GLFW_KEY_CAPS_LOCK          =280,
	GLFW_KEY_SCROLL_LOCK        =281,
	GLFW_KEY_NUM_LOCK           =282,
	GLFW_KEY_PRINT_SCREEN       =283,
	GLFW_KEY_PAUSE              =284,
	GLFW_KEY_F1                 =290,
	GLFW_KEY_F2                 =291,
	GLFW_KEY_F3                 =292,
	GLFW_KEY_F4                 =293,
	GLFW_KEY_F5                 =294,
	GLFW_KEY_F6                 =295,
	GLFW_KEY_F7                 =296,
	GLFW_KEY_F8                 =297,
	GLFW_KEY_F9                 =298,
	GLFW_KEY_F10                =299,
	GLFW_KEY_F11                =300,
	GLFW_KEY_F12                =301,
	GLFW_KEY_F13                =302,
	GLFW_KEY_F14                =303,
	GLFW_KEY_F15                =304,
	GLFW_KEY_F16                =305,
	GLFW_KEY_F17                =306,
	GLFW_KEY_F18                =307,
	GLFW_KEY_F19                =308,
	GLFW_KEY_F20                =309,
	GLFW_KEY_F21                =310,
	GLFW_KEY_F22                =311,
	GLFW_KEY_F23                =312,
	GLFW_KEY_F24                =313,
	GLFW_KEY_F25                =314,
	GLFW_KEY_KP_0               =320,
	GLFW_KEY_KP_1               =321,
	GLFW_KEY_KP_2               =322,
	GLFW_KEY_KP_3               =323,
	GLFW_KEY_KP_4               =324,
	GLFW_KEY_KP_5               =325,
	GLFW_KEY_KP_6               =326,
	GLFW_KEY_KP_7               =327,
	GLFW_KEY_KP_8               =328,
	GLFW_KEY_KP_9               =329,
	GLFW_KEY_KP_DECIMAL         =330,
	GLFW_KEY_KP_DIVIDE          =331,
	GLFW_KEY_KP_MULTIPLY        =332,
	GLFW_KEY_KP_SUBTRACT        =333,
	GLFW_KEY_KP_ADD             =334,
	GLFW_KEY_KP_ENTER           =335,
	GLFW_KEY_KP_EQUAL           =336,
	GLFW_KEY_LEFT_SHIFT         =340,
	GLFW_KEY_LEFT_CONTROL       =341,
	GLFW_KEY_LEFT_ALT           =342,
	GLFW_KEY_LEFT_SUPER         =343,
	GLFW_KEY_RIGHT_SHIFT        =344,
	GLFW_KEY_RIGHT_CONTROL      =345,
	GLFW_KEY_RIGHT_ALT          =346,
	GLFW_KEY_RIGHT_SUPER        =347,
	GLFW_KEY_MENU               =348,
	GLFW_KEY_LAST               =GLFW_KEY_MENU,

	GLFW_MOD_SHIFT           =0x0001,
	GLFW_MOD_CONTROL         =0x0002,
	GLFW_MOD_ALT             =0x0004,
	GLFW_MOD_SUPER           =0x0008,

	GLFW_MOUSE_BUTTON_1         =0,
	GLFW_MOUSE_BUTTON_2         =1,
	GLFW_MOUSE_BUTTON_3         =2,
	GLFW_MOUSE_BUTTON_4         =3,
	GLFW_MOUSE_BUTTON_5         =4,
	GLFW_MOUSE_BUTTON_6         =5,
	GLFW_MOUSE_BUTTON_7         =6,
	GLFW_MOUSE_BUTTON_8         =7,
	GLFW_MOUSE_BUTTON_LAST      =GLFW_MOUSE_BUTTON_8,
	GLFW_MOUSE_BUTTON_LEFT      =GLFW_MOUSE_BUTTON_1,
	GLFW_MOUSE_BUTTON_RIGHT     =GLFW_MOUSE_BUTTON_2,
	GLFW_MOUSE_BUTTON_MIDDLE    =GLFW_MOUSE_BUTTON_3,

	GLFW_JOYSTICK_1             =0,
	GLFW_JOYSTICK_2             =1,
	GLFW_JOYSTICK_3             =2,
	GLFW_JOYSTICK_4             =3,
	GLFW_JOYSTICK_5             =4,
	GLFW_JOYSTICK_6             =5,
	GLFW_JOYSTICK_7             =6,
	GLFW_JOYSTICK_8             =7,
	GLFW_JOYSTICK_9             =8,
	GLFW_JOYSTICK_10            =9,
	GLFW_JOYSTICK_11            =10,
	GLFW_JOYSTICK_12            =11,
	GLFW_JOYSTICK_13            =12,
	GLFW_JOYSTICK_14            =13,
	GLFW_JOYSTICK_15            =14,
	GLFW_JOYSTICK_16            =15,
	GLFW_JOYSTICK_LAST          =GLFW_JOYSTICK_16,

	GLFW_NOT_INITIALIZED        =0x00010001,
	GLFW_NO_CURRENT_CONTEXT     =0x00010002,
	GLFW_INVALID_ENUM           =0x00010003,
	GLFW_INVALID_VALUE          =0x00010004,
	GLFW_OUT_OF_MEMORY          =0x00010005,
	GLFW_API_UNAVAILABLE        =0x00010006,
	GLFW_VERSION_UNAVAILABLE    =0x00010007,
	GLFW_PLATFORM_ERROR         =0x00010008,
	GLFW_FORMAT_UNAVAILABLE     =0x00010009,

	GLFW_FOCUSED                =0x00020001,
	GLFW_ICONIFIED              =0x00020002,
	GLFW_RESIZABLE              =0x00020003,
	GLFW_VISIBLE                =0x00020004,
	GLFW_DECORATED              =0x00020005,

	GLFW_RED_BITS               =0x00021001,
	GLFW_GREEN_BITS             =0x00021002,
	GLFW_BLUE_BITS              =0x00021003,
	GLFW_ALPHA_BITS             =0x00021004,
	GLFW_DEPTH_BITS             =0x00021005,
	GLFW_STENCIL_BITS           =0x00021006,
	GLFW_ACCUM_RED_BITS         =0x00021007,
	GLFW_ACCUM_GREEN_BITS       =0x00021008,
	GLFW_ACCUM_BLUE_BITS        =0x00021009,
	GLFW_ACCUM_ALPHA_BITS       =0x0002100A,
	GLFW_AUX_BUFFERS            =0x0002100B,
	GLFW_STEREO                 =0x0002100C,
	GLFW_SAMPLES                =0x0002100D,
	GLFW_SRGB_CAPABLE           =0x0002100E,
	GLFW_REFRESH_RATE           =0x0002100F,

	GLFW_CLIENT_API             =0x00022001,
	GLFW_CONTEXT_VERSION_MAJOR  =0x00022002,
	GLFW_CONTEXT_VERSION_MINOR  =0x00022003,
	GLFW_CONTEXT_REVISION       =0x00022004,
	GLFW_CONTEXT_ROBUSTNESS     =0x00022005,
	GLFW_OPENGL_FORWARD_COMPAT  =0x00022006,
	GLFW_OPENGL_DEBUG_CONTEXT   =0x00022007,
	GLFW_OPENGL_PROFILE         =0x00022008,

	GLFW_OPENGL_API             =0x00030001,
	GLFW_OPENGL_ES_API          =0x00030002,

	GLFW_NO_ROBUSTNESS                   =0,
	GLFW_NO_RESET_NOTIFICATION  =0x00031001,
	GLFW_LOSE_CONTEXT_ON_RESET  =0x00031002,

	GLFW_OPENGL_ANY_PROFILE              =0,
	GLFW_OPENGL_CORE_PROFILE    =0x00032001,
	GLFW_OPENGL_COMPAT_PROFILE  =0x00032002,

	GLFW_CURSOR                 =0x00033001,
	GLFW_STICKY_KEYS            =0x00033002,
	GLFW_STICKY_MOUSE_BUTTONS   =0x00033003,

	GLFW_CURSOR_NORMAL          =0x00034001,
	GLFW_CURSOR_HIDDEN          =0x00034002,
	GLFW_CURSOR_DISABLED        =0x00034003,

	GLFW_CONNECTED              =0x00040001,
	GLFW_DISCONNECTED           =0x00040002,
};

typedef struct GLFWWindow* GLFWWindow;
typedef void (*GLFWglproc)();
typedef struct GLFWmonitor GLFWmonitor;
typedef struct GLFWwindow GLFWwindow;
typedef void (* GLFWerrorfun)(int,const char*);
typedef void (* GLFWwindowposfun)(GLFWwindow*,int,int);
typedef void (* GLFWwindowsizefun)(GLFWwindow*,int,int);
typedef void (* GLFWwindowclosefun)(GLFWwindow*);
typedef void (* GLFWwindowrefreshfun)(GLFWwindow*);
typedef void (* GLFWwindowfocusfun)(GLFWwindow*,int);
typedef void (* GLFWwindowiconifyfun)(GLFWwindow*,int);
typedef void (* GLFWframebuffersizefun)(GLFWwindow*,int,int);
typedef void (* GLFWmousebuttonfun)(GLFWwindow*,int,int,int);
typedef void (* GLFWcursorposfun)(GLFWwindow*,double,double);
typedef void (* GLFWcursorenterfun)(GLFWwindow*,int);
typedef void (* GLFWscrollfun)(GLFWwindow*,double,double);
typedef void (* GLFWkeyfun)(GLFWwindow*,int,int,int,int);
typedef void (* GLFWcharfun)(GLFWwindow*,unsigned int);
typedef void (* GLFWmonitorfun)(GLFWmonitor*,int);

typedef struct GLFWvidmode
{
	int width;
	int height;
	int redBits;
	int greenBits;
	int blueBits;
	int refreshRate;
} GLFWvidmode;

typedef struct GLFWgammaramp
{
	unsigned short* red;
	unsigned short* green;
	unsigned short* blue;
	unsigned int size;
} GLFWgammaramp;

int glfwInit(void);
void glfwTerminate(void);
void glfwGetVersion(int* major, int* minor, int* rev);
const char* glfwGetVersionString(void);
GLFWerrorfun glfwSetErrorCallback(GLFWerrorfun cbfun);
GLFWmonitor** glfwGetMonitors(int* count);
GLFWmonitor* glfwGetPrimaryMonitor(void);
void glfwGetMonitorPos(GLFWmonitor* monitor, int* xpos, int* ypos);
void glfwGetMonitorPhysicalSize(GLFWmonitor* monitor, int* width, int* height);
const char* glfwGetMonitorName(GLFWmonitor* monitor);
GLFWmonitorfun glfwSetMonitorCallback(GLFWmonitorfun cbfun);
const GLFWvidmode* glfwGetVideoModes(GLFWmonitor* monitor, int* count);
const GLFWvidmode* glfwGetVideoMode(GLFWmonitor* monitor);
void glfwSetGamma(GLFWmonitor* monitor, float gamma);
const GLFWgammaramp* glfwGetGammaRamp(GLFWmonitor* monitor);
void glfwSetGammaRamp(GLFWmonitor* monitor, const GLFWgammaramp* ramp);
void glfwDefaultWindowHints(void);
void glfwWindowHint(int target, int hint);
GLFWwindow* glfwCreateWindow(int width, int height, const char* title, GLFWmonitor* monitor, GLFWwindow* share);
void glfwDestroyWindow(GLFWwindow* window);
int glfwWindowShouldClose(GLFWwindow* window);
void glfwSetWindowShouldClose(GLFWwindow* window, int value);
void glfwSetWindowTitle(GLFWwindow* window, const char* title);
void glfwGetWindowPos(GLFWwindow* window, int* xpos, int* ypos);
void glfwSetWindowPos(GLFWwindow* window, int xpos, int ypos);
void glfwGetWindowSize(GLFWwindow* window, int* width, int* height);
void glfwSetWindowSize(GLFWwindow* window, int width, int height);
void glfwGetFramebufferSize(GLFWwindow* window, int* width, int* height);
void glfwIconifyWindow(GLFWwindow* window);
void glfwRestoreWindow(GLFWwindow* window);
void glfwShowWindow(GLFWwindow* window);
void glfwHideWindow(GLFWwindow* window);
GLFWmonitor* glfwGetWindowMonitor(GLFWwindow* window);
int glfwGetWindowAttrib(GLFWwindow* window, int attrib);
void glfwSetWindowUserPointer(GLFWwindow* window, void* pointer);
void* glfwGetWindowUserPointer(GLFWwindow* window);
GLFWwindowposfun glfwSetWindowPosCallback(GLFWwindow* window, GLFWwindowposfun cbfun);
GLFWwindowsizefun glfwSetWindowSizeCallback(GLFWwindow* window, GLFWwindowsizefun cbfun);
GLFWwindowclosefun glfwSetWindowCloseCallback(GLFWwindow* window, GLFWwindowclosefun cbfun);
GLFWwindowrefreshfun glfwSetWindowRefreshCallback(GLFWwindow* window, GLFWwindowrefreshfun cbfun);
GLFWwindowfocusfun glfwSetWindowFocusCallback(GLFWwindow* window, GLFWwindowfocusfun cbfun);
GLFWwindowiconifyfun glfwSetWindowIconifyCallback(GLFWwindow* window, GLFWwindowiconifyfun cbfun);
GLFWframebuffersizefun glfwSetFramebufferSizeCallback(GLFWwindow* window, GLFWframebuffersizefun cbfun);
void glfwPollEvents(void);
void glfwWaitEvents(void);
int glfwGetInputMode(GLFWwindow* window, int mode);
void glfwSetInputMode(GLFWwindow* window, int mode, int value);
int glfwGetKey(GLFWwindow* window, int key);
int glfwGetMouseButton(GLFWwindow* window, int button);
void glfwGetCursorPos(GLFWwindow* window, double* xpos, double* ypos);
void glfwSetCursorPos(GLFWwindow* window, double xpos, double ypos);
GLFWkeyfun glfwSetKeyCallback(GLFWwindow* window, GLFWkeyfun cbfun);
GLFWcharfun glfwSetCharCallback(GLFWwindow* window, GLFWcharfun cbfun);
GLFWmousebuttonfun glfwSetMouseButtonCallback(GLFWwindow* window, GLFWmousebuttonfun cbfun);
GLFWcursorposfun glfwSetCursorPosCallback(GLFWwindow* window, GLFWcursorposfun cbfun);
GLFWcursorenterfun glfwSetCursorEnterCallback(GLFWwindow* window, GLFWcursorenterfun cbfun);
GLFWscrollfun glfwSetScrollCallback(GLFWwindow* window, GLFWscrollfun cbfun);
int glfwJoystickPresent(int joy);
const float* glfwGetJoystickAxes(int joy, int* count);
const unsigned char* glfwGetJoystickButtons(int joy, int* count);
const char* glfwGetJoystickName(int joy);
void glfwSetClipboardString(GLFWwindow* window, const char* string);
const char* glfwGetClipboardString(GLFWwindow* window);
double glfwGetTime(void);
void glfwSetTime(double time);
void glfwMakeContextCurrent(GLFWwindow* window);
GLFWwindow* glfwGetCurrentContext(void);
void glfwSwapBuffers(GLFWwindow* window);
void glfwSwapInterval(int interval);
int glfwExtensionSupported(const char* extension);
GLFWglproc glfwGetProcAddress(const char* procname);
]]

glfw.glfw.Init()

return glfw]   4  4 % 7 >4  4 % 7 >H  	GLFW	glfw_Grawsetself   R  !+  %   $69 6 H �	glfwglfw_lib self  	index  	 S  !"+  %   $69 6 H �
GLFW_glfw_lib self  	index  	 4   (+   7   @  �glfwPollEventsglfw_lib  �m   6� �C  4  % >* 7 T�7% > T�7% > 3 :2  :	2  :
1 : 4 7	3 1 :>4 7
3 1 :>7	1 :4 77	7>7% >7	7>0  �H 	Init�ienum {
	GLFW_VERSION_MAJOR          =3,
	GLFW_VERSION_MINOR          =0,
	GLFW_VERSION_REVISION       =4,

	GLFW_RELEASE                =0,
	GLFW_PRESS                  =1,
	GLFW_REPEAT                 =2,
	GLFW_KEY_UNKNOWN            =-1,

	GLFW_KEY_SPACE              =32,
	GLFW_KEY_APOSTROPHE         =39  /* ' */,
	GLFW_KEY_COMMA              =44  /* , */,
	GLFW_KEY_MINUS              =45  /* - */,
	GLFW_KEY_PERIOD             =46  /* . */,
	GLFW_KEY_SLASH              =47  /* / */,
	GLFW_KEY_0                  =48,
	GLFW_KEY_1                  =49,
	GLFW_KEY_2                  =50,
	GLFW_KEY_3                  =51,
	GLFW_KEY_4                  =52,
	GLFW_KEY_5                  =53,
	GLFW_KEY_6                  =54,
	GLFW_KEY_7                  =55,
	GLFW_KEY_8                  =56,
	GLFW_KEY_9                  =57,
	GLFW_KEY_SEMICOLON          =59  /* ; */,
	GLFW_KEY_EQUAL              =61  /* = */,
	GLFW_KEY_A                  =65,
	GLFW_KEY_B                  =66,
	GLFW_KEY_C                  =67,
	GLFW_KEY_D                  =68,
	GLFW_KEY_E                  =69,
	GLFW_KEY_F                  =70,
	GLFW_KEY_G                  =71,
	GLFW_KEY_H                  =72,
	GLFW_KEY_I                  =73,
	GLFW_KEY_J                  =74,
	GLFW_KEY_K                  =75,
	GLFW_KEY_L                  =76,
	GLFW_KEY_M                  =77,
	GLFW_KEY_N                  =78,
	GLFW_KEY_O                  =79,
	GLFW_KEY_P                  =80,
	GLFW_KEY_Q                  =81,
	GLFW_KEY_R                  =82,
	GLFW_KEY_S                  =83,
	GLFW_KEY_T                  =84,
	GLFW_KEY_U                  =85,
	GLFW_KEY_V                  =86,
	GLFW_KEY_W                  =87,
	GLFW_KEY_X                  =88,
	GLFW_KEY_Y                  =89,
	GLFW_KEY_Z                  =90,
	GLFW_KEY_LEFT_BRACKET       =91  /* [ */,
	GLFW_KEY_BACKSLASH          =92  /* \ */,
	GLFW_KEY_RIGHT_BRACKET      =93  /* ] */,
	GLFW_KEY_GRAVE_ACCENT       =96  /* ` */,
	GLFW_KEY_WORLD_1            =161 /* non-US #1 */,
	GLFW_KEY_WORLD_2            =162 /* non-US #2 */,

	GLFW_KEY_ESCAPE             =256,
	GLFW_KEY_ENTER              =257,
	GLFW_KEY_TAB                =258,
	GLFW_KEY_BACKSPACE          =259,
	GLFW_KEY_INSERT             =260,
	GLFW_KEY_DELETE             =261,
	GLFW_KEY_RIGHT              =262,
	GLFW_KEY_LEFT               =263,
	GLFW_KEY_DOWN               =264,
	GLFW_KEY_UP                 =265,
	GLFW_KEY_PAGE_UP            =266,
	GLFW_KEY_PAGE_DOWN          =267,
	GLFW_KEY_HOME               =268,
	GLFW_KEY_END                =269,
	GLFW_KEY_CAPS_LOCK          =280,
	GLFW_KEY_SCROLL_LOCK        =281,
	GLFW_KEY_NUM_LOCK           =282,
	GLFW_KEY_PRINT_SCREEN       =283,
	GLFW_KEY_PAUSE              =284,
	GLFW_KEY_F1                 =290,
	GLFW_KEY_F2                 =291,
	GLFW_KEY_F3                 =292,
	GLFW_KEY_F4                 =293,
	GLFW_KEY_F5                 =294,
	GLFW_KEY_F6                 =295,
	GLFW_KEY_F7                 =296,
	GLFW_KEY_F8                 =297,
	GLFW_KEY_F9                 =298,
	GLFW_KEY_F10                =299,
	GLFW_KEY_F11                =300,
	GLFW_KEY_F12                =301,
	GLFW_KEY_F13                =302,
	GLFW_KEY_F14                =303,
	GLFW_KEY_F15                =304,
	GLFW_KEY_F16                =305,
	GLFW_KEY_F17                =306,
	GLFW_KEY_F18                =307,
	GLFW_KEY_F19                =308,
	GLFW_KEY_F20                =309,
	GLFW_KEY_F21                =310,
	GLFW_KEY_F22                =311,
	GLFW_KEY_F23                =312,
	GLFW_KEY_F24                =313,
	GLFW_KEY_F25                =314,
	GLFW_KEY_KP_0               =320,
	GLFW_KEY_KP_1               =321,
	GLFW_KEY_KP_2               =322,
	GLFW_KEY_KP_3               =323,
	GLFW_KEY_KP_4               =324,
	GLFW_KEY_KP_5               =325,
	GLFW_KEY_KP_6               =326,
	GLFW_KEY_KP_7               =327,
	GLFW_KEY_KP_8               =328,
	GLFW_KEY_KP_9               =329,
	GLFW_KEY_KP_DECIMAL         =330,
	GLFW_KEY_KP_DIVIDE          =331,
	GLFW_KEY_KP_MULTIPLY        =332,
	GLFW_KEY_KP_SUBTRACT        =333,
	GLFW_KEY_KP_ADD             =334,
	GLFW_KEY_KP_ENTER           =335,
	GLFW_KEY_KP_EQUAL           =336,
	GLFW_KEY_LEFT_SHIFT         =340,
	GLFW_KEY_LEFT_CONTROL       =341,
	GLFW_KEY_LEFT_ALT           =342,
	GLFW_KEY_LEFT_SUPER         =343,
	GLFW_KEY_RIGHT_SHIFT        =344,
	GLFW_KEY_RIGHT_CONTROL      =345,
	GLFW_KEY_RIGHT_ALT          =346,
	GLFW_KEY_RIGHT_SUPER        =347,
	GLFW_KEY_MENU               =348,
	GLFW_KEY_LAST               =GLFW_KEY_MENU,

	GLFW_MOD_SHIFT           =0x0001,
	GLFW_MOD_CONTROL         =0x0002,
	GLFW_MOD_ALT             =0x0004,
	GLFW_MOD_SUPER           =0x0008,

	GLFW_MOUSE_BUTTON_1         =0,
	GLFW_MOUSE_BUTTON_2         =1,
	GLFW_MOUSE_BUTTON_3         =2,
	GLFW_MOUSE_BUTTON_4         =3,
	GLFW_MOUSE_BUTTON_5         =4,
	GLFW_MOUSE_BUTTON_6         =5,
	GLFW_MOUSE_BUTTON_7         =6,
	GLFW_MOUSE_BUTTON_8         =7,
	GLFW_MOUSE_BUTTON_LAST      =GLFW_MOUSE_BUTTON_8,
	GLFW_MOUSE_BUTTON_LEFT      =GLFW_MOUSE_BUTTON_1,
	GLFW_MOUSE_BUTTON_RIGHT     =GLFW_MOUSE_BUTTON_2,
	GLFW_MOUSE_BUTTON_MIDDLE    =GLFW_MOUSE_BUTTON_3,

	GLFW_JOYSTICK_1             =0,
	GLFW_JOYSTICK_2             =1,
	GLFW_JOYSTICK_3             =2,
	GLFW_JOYSTICK_4             =3,
	GLFW_JOYSTICK_5             =4,
	GLFW_JOYSTICK_6             =5,
	GLFW_JOYSTICK_7             =6,
	GLFW_JOYSTICK_8             =7,
	GLFW_JOYSTICK_9             =8,
	GLFW_JOYSTICK_10            =9,
	GLFW_JOYSTICK_11            =10,
	GLFW_JOYSTICK_12            =11,
	GLFW_JOYSTICK_13            =12,
	GLFW_JOYSTICK_14            =13,
	GLFW_JOYSTICK_15            =14,
	GLFW_JOYSTICK_16            =15,
	GLFW_JOYSTICK_LAST          =GLFW_JOYSTICK_16,

	GLFW_NOT_INITIALIZED        =0x00010001,
	GLFW_NO_CURRENT_CONTEXT     =0x00010002,
	GLFW_INVALID_ENUM           =0x00010003,
	GLFW_INVALID_VALUE          =0x00010004,
	GLFW_OUT_OF_MEMORY          =0x00010005,
	GLFW_API_UNAVAILABLE        =0x00010006,
	GLFW_VERSION_UNAVAILABLE    =0x00010007,
	GLFW_PLATFORM_ERROR         =0x00010008,
	GLFW_FORMAT_UNAVAILABLE     =0x00010009,

	GLFW_FOCUSED                =0x00020001,
	GLFW_ICONIFIED              =0x00020002,
	GLFW_RESIZABLE              =0x00020003,
	GLFW_VISIBLE                =0x00020004,
	GLFW_DECORATED              =0x00020005,

	GLFW_RED_BITS               =0x00021001,
	GLFW_GREEN_BITS             =0x00021002,
	GLFW_BLUE_BITS              =0x00021003,
	GLFW_ALPHA_BITS             =0x00021004,
	GLFW_DEPTH_BITS             =0x00021005,
	GLFW_STENCIL_BITS           =0x00021006,
	GLFW_ACCUM_RED_BITS         =0x00021007,
	GLFW_ACCUM_GREEN_BITS       =0x00021008,
	GLFW_ACCUM_BLUE_BITS        =0x00021009,
	GLFW_ACCUM_ALPHA_BITS       =0x0002100A,
	GLFW_AUX_BUFFERS            =0x0002100B,
	GLFW_STEREO                 =0x0002100C,
	GLFW_SAMPLES                =0x0002100D,
	GLFW_SRGB_CAPABLE           =0x0002100E,
	GLFW_REFRESH_RATE           =0x0002100F,

	GLFW_CLIENT_API             =0x00022001,
	GLFW_CONTEXT_VERSION_MAJOR  =0x00022002,
	GLFW_CONTEXT_VERSION_MINOR  =0x00022003,
	GLFW_CONTEXT_REVISION       =0x00022004,
	GLFW_CONTEXT_ROBUSTNESS     =0x00022005,
	GLFW_OPENGL_FORWARD_COMPAT  =0x00022006,
	GLFW_OPENGL_DEBUG_CONTEXT   =0x00022007,
	GLFW_OPENGL_PROFILE         =0x00022008,

	GLFW_OPENGL_API             =0x00030001,
	GLFW_OPENGL_ES_API          =0x00030002,

	GLFW_NO_ROBUSTNESS                   =0,
	GLFW_NO_RESET_NOTIFICATION  =0x00031001,
	GLFW_LOSE_CONTEXT_ON_RESET  =0x00031002,

	GLFW_OPENGL_ANY_PROFILE              =0,
	GLFW_OPENGL_CORE_PROFILE    =0x00032001,
	GLFW_OPENGL_COMPAT_PROFILE  =0x00032002,

	GLFW_CURSOR                 =0x00033001,
	GLFW_STICKY_KEYS            =0x00033002,
	GLFW_STICKY_MOUSE_BUTTONS   =0x00033003,

	GLFW_CURSOR_NORMAL          =0x00034001,
	GLFW_CURSOR_HIDDEN          =0x00034002,
	GLFW_CURSOR_DISABLED        =0x00034003,

	GLFW_CONNECTED              =0x00040001,
	GLFW_DISCONNECTED           =0x00040002,
};

typedef struct GLFWWindow* GLFWWindow;
typedef void (*GLFWglproc)();
typedef struct GLFWmonitor GLFWmonitor;
typedef struct GLFWwindow GLFWwindow;
typedef void (* GLFWerrorfun)(int,const char*);
typedef void (* GLFWwindowposfun)(GLFWwindow*,int,int);
typedef void (* GLFWwindowsizefun)(GLFWwindow*,int,int);
typedef void (* GLFWwindowclosefun)(GLFWwindow*);
typedef void (* GLFWwindowrefreshfun)(GLFWwindow*);
typedef void (* GLFWwindowfocusfun)(GLFWwindow*,int);
typedef void (* GLFWwindowiconifyfun)(GLFWwindow*,int);
typedef void (* GLFWframebuffersizefun)(GLFWwindow*,int,int);
typedef void (* GLFWmousebuttonfun)(GLFWwindow*,int,int,int);
typedef void (* GLFWcursorposfun)(GLFWwindow*,double,double);
typedef void (* GLFWcursorenterfun)(GLFWwindow*,int);
typedef void (* GLFWscrollfun)(GLFWwindow*,double,double);
typedef void (* GLFWkeyfun)(GLFWwindow*,int,int,int,int);
typedef void (* GLFWcharfun)(GLFWwindow*,unsigned int);
typedef void (* GLFWmonitorfun)(GLFWmonitor*,int);

typedef struct GLFWvidmode
{
	int width;
	int height;
	int redBits;
	int greenBits;
	int blueBits;
	int refreshRate;
} GLFWvidmode;

typedef struct GLFWgammaramp
{
	unsigned short* red;
	unsigned short* green;
	unsigned short* blue;
	unsigned int size;
} GLFWgammaramp;

int glfwInit(void);
void glfwTerminate(void);
void glfwGetVersion(int* major, int* minor, int* rev);
const char* glfwGetVersionString(void);
GLFWerrorfun glfwSetErrorCallback(GLFWerrorfun cbfun);
GLFWmonitor** glfwGetMonitors(int* count);
GLFWmonitor* glfwGetPrimaryMonitor(void);
void glfwGetMonitorPos(GLFWmonitor* monitor, int* xpos, int* ypos);
void glfwGetMonitorPhysicalSize(GLFWmonitor* monitor, int* width, int* height);
const char* glfwGetMonitorName(GLFWmonitor* monitor);
GLFWmonitorfun glfwSetMonitorCallback(GLFWmonitorfun cbfun);
const GLFWvidmode* glfwGetVideoModes(GLFWmonitor* monitor, int* count);
const GLFWvidmode* glfwGetVideoMode(GLFWmonitor* monitor);
void glfwSetGamma(GLFWmonitor* monitor, float gamma);
const GLFWgammaramp* glfwGetGammaRamp(GLFWmonitor* monitor);
void glfwSetGammaRamp(GLFWmonitor* monitor, const GLFWgammaramp* ramp);
void glfwDefaultWindowHints(void);
void glfwWindowHint(int target, int hint);
GLFWwindow* glfwCreateWindow(int width, int height, const char* title, GLFWmonitor* monitor, GLFWwindow* share);
void glfwDestroyWindow(GLFWwindow* window);
int glfwWindowShouldClose(GLFWwindow* window);
void glfwSetWindowShouldClose(GLFWwindow* window, int value);
void glfwSetWindowTitle(GLFWwindow* window, const char* title);
void glfwGetWindowPos(GLFWwindow* window, int* xpos, int* ypos);
void glfwSetWindowPos(GLFWwindow* window, int xpos, int ypos);
void glfwGetWindowSize(GLFWwindow* window, int* width, int* height);
void glfwSetWindowSize(GLFWwindow* window, int width, int height);
void glfwGetFramebufferSize(GLFWwindow* window, int* width, int* height);
void glfwIconifyWindow(GLFWwindow* window);
void glfwRestoreWindow(GLFWwindow* window);
void glfwShowWindow(GLFWwindow* window);
void glfwHideWindow(GLFWwindow* window);
GLFWmonitor* glfwGetWindowMonitor(GLFWwindow* window);
int glfwGetWindowAttrib(GLFWwindow* window, int attrib);
void glfwSetWindowUserPointer(GLFWwindow* window, void* pointer);
void* glfwGetWindowUserPointer(GLFWwindow* window);
GLFWwindowposfun glfwSetWindowPosCallback(GLFWwindow* window, GLFWwindowposfun cbfun);
GLFWwindowsizefun glfwSetWindowSizeCallback(GLFWwindow* window, GLFWwindowsizefun cbfun);
GLFWwindowclosefun glfwSetWindowCloseCallback(GLFWwindow* window, GLFWwindowclosefun cbfun);
GLFWwindowrefreshfun glfwSetWindowRefreshCallback(GLFWwindow* window, GLFWwindowrefreshfun cbfun);
GLFWwindowfocusfun glfwSetWindowFocusCallback(GLFWwindow* window, GLFWwindowfocusfun cbfun);
GLFWwindowiconifyfun glfwSetWindowIconifyCallback(GLFWwindow* window, GLFWwindowiconifyfun cbfun);
GLFWframebuffersizefun glfwSetFramebufferSizeCallback(GLFWwindow* window, GLFWframebuffersizefun cbfun);
void glfwPollEvents(void);
void glfwWaitEvents(void);
int glfwGetInputMode(GLFWwindow* window, int mode);
void glfwSetInputMode(GLFWwindow* window, int mode, int value);
int glfwGetKey(GLFWwindow* window, int key);
int glfwGetMouseButton(GLFWwindow* window, int button);
void glfwGetCursorPos(GLFWwindow* window, double* xpos, double* ypos);
void glfwSetCursorPos(GLFWwindow* window, double xpos, double ypos);
GLFWkeyfun glfwSetKeyCallback(GLFWwindow* window, GLFWkeyfun cbfun);
GLFWcharfun glfwSetCharCallback(GLFWwindow* window, GLFWcharfun cbfun);
GLFWmousebuttonfun glfwSetMouseButtonCallback(GLFWwindow* window, GLFWmousebuttonfun cbfun);
GLFWcursorposfun glfwSetCursorPosCallback(GLFWwindow* window, GLFWcursorposfun cbfun);
GLFWcursorenterfun glfwSetCursorEnterCallback(GLFWwindow* window, GLFWcursorenterfun cbfun);
GLFWscrollfun glfwSetScrollCallback(GLFWwindow* window, GLFWscrollfun cbfun);
int glfwJoystickPresent(int joy);
const float* glfwGetJoystickAxes(int joy, int* count);
const unsigned char* glfwGetJoystickButtons(int joy, int* count);
const char* glfwGetJoystickName(int joy);
void glfwSetClipboardString(GLFWwindow* window, const char* string);
const char* glfwGetClipboardString(GLFWwindow* window);
double glfwGetTime(void);
void glfwSetTime(double time);
void glfwMakeContextCurrent(GLFWwindow* window);
GLFWwindow* glfwGetCurrentContext(void);
void glfwSwapBuffers(GLFWwindow* window);
void glfwSwapInterval(int interval);
int glfwExtensionSupported(const char* extension);
GLFWglproc glfwGetProcAddress(const char* procname);
	cdefoffjit PollEvents   __index   setmetatableimport 	GLFW	glfwlib  libglfw.so.3lib/win32/glfw3.dll	loadWindowsosffirequire             
 
 
 
                ! ! ! % % ! ( * * + + + + + - �������Coeus 5ffi 2glfw 1glfw_lib  1  ]==])
Coeus:AddVFSFile('Bindings.iqm', [==[LJ �*
ffi.cdef([[
// IQM: Inter-Quake Model format
// version 1: April 20, 2010
// version 2: May 31, 2011
//    * explicitly store quaternion w to minimize animation jitter
//      modified joint and pose struct to explicitly store quaternion w in new channel 6 (with 10 total channels)

// all data is little endian

struct iqmheader
{
    char magic[16]; // the string "INTERQUAKEMODEL\0", 0 terminated
    uint version; // must be version 2
    uint filesize;
    uint flags;
    uint num_text, ofs_text;
    uint num_meshes, ofs_meshes;
    uint num_vertexarrays, num_vertexes, ofs_vertexarrays;
    uint num_triangles, ofs_triangles, ofs_adjacency;
    uint num_joints, ofs_joints;
    uint num_poses, ofs_poses;
    uint num_anims, ofs_anims;
    uint num_frames, num_framechannels, ofs_frames, ofs_bounds;
    uint num_comment, ofs_comment;
    uint num_extensions, ofs_extensions; // these are stored as a linked list, not as a contiguous array
};
// ofs_* fields are relative to the beginning of the iqmheader struct
// ofs_* fields must be set to 0 when the particular data is empty
// ofs_* fields must be aligned to at least 4 byte boundaries

struct iqmmesh
{
    uint name;     // unique name for the mesh, if desired
    uint material; // set to a name of a non-unique material or texture
    uint first_vertex, num_vertexes;
    uint first_triangle, num_triangles;
};

// all vertex array entries must ordered as defined below, if present
// i.e. position comes before normal comes before ... comes before custom
// where a format and size is given, this means models intended for portable use should use these
// an IQM implementation is not required to honor any other format/size than those recommended
// however, it may support other format/size combinations for these types if it desires
enum // vertex array type
{
    IQM_POSITION     = 0,  // float, 3
    IQM_TEXCOORD     = 1,  // float, 2
    IQM_NORMAL       = 2,  // float, 3
    IQM_TANGENT      = 3,  // float, 4
    IQM_BLENDINDEXES = 4,  // ubyte, 4
    IQM_BLENDWEIGHTS = 5,  // ubyte, 4
    IQM_COLOR        = 6,  // ubyte, 4

    // all values up to IQM_CUSTOM are reserved for future use
    // any value >= IQM_CUSTOM is interpreted as CUSTOM type
    // the value then defines an offset into the string table, where offset = value - IQM_CUSTOM
    // this must be a valid string naming the type
    IQM_CUSTOM       = 0x10
};

enum // vertex array format
{
    IQM_BYTE   = 0,
    IQM_UBYTE  = 1,
    IQM_SHORT  = 2,
    IQM_USHORT = 3,
    IQM_INT    = 4,
    IQM_UINT   = 5,
    IQM_HALF   = 6,
    IQM_FLOAT  = 7,
    IQM_DOUBLE = 8,
};

struct iqmvertexarray
{
    uint type;   // type or custom name
    uint flags;
    uint format; // component format
    uint size;   // number of components
    uint offset; // offset to array of tightly packed components, with num_vertexes * size total entries
                 // offset must be aligned to max(sizeof(format), 4)
};

struct iqmtriangle
{
    uint vertex[3];
};

struct iqmadjacency
{
    // each value is the index of the adjacent triangle for edge 0, 1, and 2, where ~0 (= -1) indicates no adjacent triangle
    // indexes are relative to the iqmheader.ofs_triangles array and span all meshes, where 0 is the first triangle, 1 is the second, 2 is the third, etc. 
    uint triangle[3];
};
 
struct iqmjoint
{
    uint name;
    int parent; // parent < 0 means this is a root bone
    float translate[3], rotate[4], scale[3]; 
    // translate is translation <Tx, Ty, Tz>, and rotate is quaternion rotation <Qx, Qy, Qz, Qw>
    // rotation is in relative/parent local space
    // scale is pre-scaling <Sx, Sy, Sz>
    // output = (input*scale)*rotation + translation
};

struct iqmpose
{
    int parent; // parent < 0 means this is a root bone
    uint channelmask; // mask of which 10 channels are present for this joint pose
    float channeloffset[10], channelscale[10]; 
    // channels 0..2 are translation <Tx, Ty, Tz> and channels 3..6 are quaternion rotation <Qx, Qy, Qz, Qw>
    // rotation is in relative/parent local space
    // channels 7..9 are scale <Sx, Sy, Sz>
    // output = (input*scale)*rotation + translation
};

ushort frames[]; // frames is a big unsigned short array where each group of framechannels components is one frame

struct iqmanim
{
    uint name;
    uint first_frame, num_frames; 
    float framerate;
    uint flags;
};

enum // iqmanim flags
{
    IQM_LOOP = 1<<0
};

struct iqmbounds
{
    float bbmins[3], bbmaxs[3]; // the minimum and maximum coordinates of the bounding box for this animation frame
    float xyradius, radius; // the circular radius in the X-Y plane, as well as the spherical radius
};

char text[]; // big array of all strings, each individual string being 0 terminated, with the first string always being the empty string "" (i.e. text[0] == 0)
char comment[];

struct iqmextension
{
    uint name;
    uint num_data, ofs_data;
    uint ofs_extensions; // pointer to next extension
};

// vertex data is not really interleaved, but this just gives examples of standard types of the data arrays
struct iqmvertex
{
    float position[3], texcoord[2], normal[3], tangent[4];
    uchar blendindices[4], blendweights[4], color[4];
};

]])

return ffi.C�)    �4   7  % > 4   7  H  C�(// IQM: Inter-Quake Model format
// version 1: April 20, 2010
// version 2: May 31, 2011
//    * explicitly store quaternion w to minimize animation jitter
//      modified joint and pose struct to explicitly store quaternion w in new channel 6 (with 10 total channels)

// all data is little endian

struct iqmheader
{
    char magic[16]; // the string "INTERQUAKEMODEL\0", 0 terminated
    uint version; // must be version 2
    uint filesize;
    uint flags;
    uint num_text, ofs_text;
    uint num_meshes, ofs_meshes;
    uint num_vertexarrays, num_vertexes, ofs_vertexarrays;
    uint num_triangles, ofs_triangles, ofs_adjacency;
    uint num_joints, ofs_joints;
    uint num_poses, ofs_poses;
    uint num_anims, ofs_anims;
    uint num_frames, num_framechannels, ofs_frames, ofs_bounds;
    uint num_comment, ofs_comment;
    uint num_extensions, ofs_extensions; // these are stored as a linked list, not as a contiguous array
};
// ofs_* fields are relative to the beginning of the iqmheader struct
// ofs_* fields must be set to 0 when the particular data is empty
// ofs_* fields must be aligned to at least 4 byte boundaries

struct iqmmesh
{
    uint name;     // unique name for the mesh, if desired
    uint material; // set to a name of a non-unique material or texture
    uint first_vertex, num_vertexes;
    uint first_triangle, num_triangles;
};

// all vertex array entries must ordered as defined below, if present
// i.e. position comes before normal comes before ... comes before custom
// where a format and size is given, this means models intended for portable use should use these
// an IQM implementation is not required to honor any other format/size than those recommended
// however, it may support other format/size combinations for these types if it desires
enum // vertex array type
{
    IQM_POSITION     = 0,  // float, 3
    IQM_TEXCOORD     = 1,  // float, 2
    IQM_NORMAL       = 2,  // float, 3
    IQM_TANGENT      = 3,  // float, 4
    IQM_BLENDINDEXES = 4,  // ubyte, 4
    IQM_BLENDWEIGHTS = 5,  // ubyte, 4
    IQM_COLOR        = 6,  // ubyte, 4

    // all values up to IQM_CUSTOM are reserved for future use
    // any value >= IQM_CUSTOM is interpreted as CUSTOM type
    // the value then defines an offset into the string table, where offset = value - IQM_CUSTOM
    // this must be a valid string naming the type
    IQM_CUSTOM       = 0x10
};

enum // vertex array format
{
    IQM_BYTE   = 0,
    IQM_UBYTE  = 1,
    IQM_SHORT  = 2,
    IQM_USHORT = 3,
    IQM_INT    = 4,
    IQM_UINT   = 5,
    IQM_HALF   = 6,
    IQM_FLOAT  = 7,
    IQM_DOUBLE = 8,
};

struct iqmvertexarray
{
    uint type;   // type or custom name
    uint flags;
    uint format; // component format
    uint size;   // number of components
    uint offset; // offset to array of tightly packed components, with num_vertexes * size total entries
                 // offset must be aligned to max(sizeof(format), 4)
};

struct iqmtriangle
{
    uint vertex[3];
};

struct iqmadjacency
{
    // each value is the index of the adjacent triangle for edge 0, 1, and 2, where ~0 (= -1) indicates no adjacent triangle
    // indexes are relative to the iqmheader.ofs_triangles array and span all meshes, where 0 is the first triangle, 1 is the second, 2 is the third, etc. 
    uint triangle[3];
};
 
struct iqmjoint
{
    uint name;
    int parent; // parent < 0 means this is a root bone
    float translate[3], rotate[4], scale[3]; 
    // translate is translation <Tx, Ty, Tz>, and rotate is quaternion rotation <Qx, Qy, Qz, Qw>
    // rotation is in relative/parent local space
    // scale is pre-scaling <Sx, Sy, Sz>
    // output = (input*scale)*rotation + translation
};

struct iqmpose
{
    int parent; // parent < 0 means this is a root bone
    uint channelmask; // mask of which 10 channels are present for this joint pose
    float channeloffset[10], channelscale[10]; 
    // channels 0..2 are translation <Tx, Ty, Tz> and channels 3..6 are quaternion rotation <Qx, Qy, Qz, Qw>
    // rotation is in relative/parent local space
    // channels 7..9 are scale <Sx, Sy, Sz>
    // output = (input*scale)*rotation + translation
};

ushort frames[]; // frames is a big unsigned short array where each group of framechannels components is one frame

struct iqmanim
{
    uint name;
    uint first_frame, num_frames; 
    float framerate;
    uint flags;
};

enum // iqmanim flags
{
    IQM_LOOP = 1<<0
};

struct iqmbounds
{
    float bbmins[3], bbmaxs[3]; // the minimum and maximum coordinates of the bounding box for this animation frame
    float xyradius, radius; // the circular radius in the X-Y plane, as well as the spherical radius
};

char text[]; // big array of all strings, each individual string being 0 terminated, with the first string always being the empty string "" (i.e. text[0] == 0)
char comment[];

struct iqmextension
{
    uint name;
    uint num_data, ofs_data;
    uint ofs_extensions; // pointer to next extension
};

// vertex data is not really interleaved, but this just gives examples of standard types of the data arrays
struct iqmvertex
{
    float position[3], texcoord[2], normal[3], tangent[4];
    uchar blendindices[4], blendweights[4], color[4];
};

	cdefffi����  ]==])
Coeus:AddVFSFile('Bindings.libogg', [==[LJ �-local Coeus = ...
local ffi = require("ffi")
local libogg = (ffi.os == "Windows") and ffi.load("lib/win32/libogg.dll") or ffi.C

--os_types.h
ffi.cdef([[
typedef __int64 ogg_int64_t;
typedef __int32 ogg_int32_t;
typedef unsigned __int32 ogg_uint32_t;
typedef __int16 ogg_int16_t;
typedef unsigned __int16 ogg_uint16_t;
]])

--ogg.h
ffi.cdef([[
typedef struct {
	void *iov_base;
	size_t iov_len;
} ogg_iovec_t;

typedef struct {
	long endbyte;
	int  endbit;

	unsigned char *buffer;
	unsigned char *ptr;
	long storage;
} oggpack_buffer;

typedef struct {
	unsigned char *header;
	long header_len;
	unsigned char *body;
	long body_len;
} ogg_page;

typedef struct {
	unsigned char *body_data;
	long body_storage;
	long body_fill;
	long body_returned;

	int *lacing_vals;
	ogg_int64_t *granule_vals;
                             
	long lacing_storage;
	long lacing_fill;
	long lacing_packet;
	long lacing_returned;

	unsigned char header[282];
	int header_fill;

	int e_o_s;
	int b_o_s;

	long serialno;
	long pageno;
	ogg_int64_t packetno;
	ogg_int64_t granulepos;

} ogg_stream_state;

typedef struct {
  unsigned char *packet;
  long bytes;
  long b_o_s;
  long e_o_s;

  ogg_int64_t granulepos;
  ogg_int64_t packetno;
} ogg_packet;

typedef struct {
  unsigned char *data;
  int storage;
  int fill;
  int returned;

  int unsynced;
  int headerbytes;
  int bodybytes;
} ogg_sync_state;

extern void  oggpack_writeinit(oggpack_buffer *b);
extern int   oggpack_writecheck(oggpack_buffer *b);
extern void  oggpack_writetrunc(oggpack_buffer *b,long bits);
extern void  oggpack_writealign(oggpack_buffer *b);
extern void  oggpack_writecopy(oggpack_buffer *b,void *source,long bits);
extern void  oggpack_reset(oggpack_buffer *b);
extern void  oggpack_writeclear(oggpack_buffer *b);
extern void  oggpack_readinit(oggpack_buffer *b,unsigned char *buf,int bytes);
extern void  oggpack_write(oggpack_buffer *b,unsigned long value,int bits);
extern long  oggpack_look(oggpack_buffer *b,int bits);
extern long  oggpack_look1(oggpack_buffer *b);
extern void  oggpack_adv(oggpack_buffer *b,int bits);
extern void  oggpack_adv1(oggpack_buffer *b);
extern long  oggpack_read(oggpack_buffer *b,int bits);
extern long  oggpack_read1(oggpack_buffer *b);
extern long  oggpack_bytes(oggpack_buffer *b);
extern long  oggpack_bits(oggpack_buffer *b);
extern unsigned char *oggpack_get_buffer(oggpack_buffer *b);

extern void  oggpackB_writeinit(oggpack_buffer *b);
extern int   oggpackB_writecheck(oggpack_buffer *b);
extern void  oggpackB_writetrunc(oggpack_buffer *b,long bits);
extern void  oggpackB_writealign(oggpack_buffer *b);
extern void  oggpackB_writecopy(oggpack_buffer *b,void *source,long bits);
extern void  oggpackB_reset(oggpack_buffer *b);
extern void  oggpackB_writeclear(oggpack_buffer *b);
extern void  oggpackB_readinit(oggpack_buffer *b,unsigned char *buf,int bytes);
extern void  oggpackB_write(oggpack_buffer *b,unsigned long value,int bits);
extern long  oggpackB_look(oggpack_buffer *b,int bits);
extern long  oggpackB_look1(oggpack_buffer *b);
extern void  oggpackB_adv(oggpack_buffer *b,int bits);
extern void  oggpackB_adv1(oggpack_buffer *b);
extern long  oggpackB_read(oggpack_buffer *b,int bits);
extern long  oggpackB_read1(oggpack_buffer *b);
extern long  oggpackB_bytes(oggpack_buffer *b);
extern long  oggpackB_bits(oggpack_buffer *b);
extern unsigned char *oggpackB_get_buffer(oggpack_buffer *b);

extern int      ogg_stream_packetin(ogg_stream_state *os, ogg_packet *op);
extern int      ogg_stream_iovecin(ogg_stream_state *os, ogg_iovec_t *iov,
                                   int count, long e_o_s, ogg_int64_t granulepos);
extern int      ogg_stream_pageout(ogg_stream_state *os, ogg_page *og);
extern int      ogg_stream_pageout_fill(ogg_stream_state *os, ogg_page *og, int nfill);
extern int      ogg_stream_flush(ogg_stream_state *os, ogg_page *og);
extern int      ogg_stream_flush_fill(ogg_stream_state *os, ogg_page *og, int nfill);

extern int      ogg_sync_init(ogg_sync_state *oy);
extern int      ogg_sync_clear(ogg_sync_state *oy);
extern int      ogg_sync_reset(ogg_sync_state *oy);
extern int      ogg_sync_destroy(ogg_sync_state *oy);
extern int      ogg_sync_check(ogg_sync_state *oy);

extern char    *ogg_sync_buffer(ogg_sync_state *oy, long size);
extern int      ogg_sync_wrote(ogg_sync_state *oy, long bytes);
extern long     ogg_sync_pageseek(ogg_sync_state *oy,ogg_page *og);
extern int      ogg_sync_pageout(ogg_sync_state *oy, ogg_page *og);
extern int      ogg_stream_pagein(ogg_stream_state *os, ogg_page *og);
extern int      ogg_stream_packetout(ogg_stream_state *os,ogg_packet *op);
extern int      ogg_stream_packetpeek(ogg_stream_state *os,ogg_packet *op);

extern int      ogg_stream_init(ogg_stream_state *os,int serialno);
extern int      ogg_stream_clear(ogg_stream_state *os);
extern int      ogg_stream_reset(ogg_stream_state *os);
extern int      ogg_stream_reset_serialno(ogg_stream_state *os,int serialno);
extern int      ogg_stream_destroy(ogg_stream_state *os);
extern int      ogg_stream_check(ogg_stream_state *os);
extern int      ogg_stream_eos(ogg_stream_state *os);

extern void     ogg_page_checksum_set(ogg_page *og);

extern int      ogg_page_version(const ogg_page *og);
extern int      ogg_page_continued(const ogg_page *og);
extern int      ogg_page_bos(const ogg_page *og);
extern int      ogg_page_eos(const ogg_page *og);
extern ogg_int64_t  ogg_page_granulepos(const ogg_page *og);
extern int      ogg_page_serialno(const ogg_page *og);
extern long     ogg_page_pageno(const ogg_page *og);
extern int      ogg_page_packets(const ogg_page *og);

extern void     ogg_packet_clear(ogg_packet *op);
]])

return libogg�,  
 , �C  4  % >7 T�7% >  T�77% >7%	 >H �)typedef struct {
	void *iov_base;
	size_t iov_len;
} ogg_iovec_t;

typedef struct {
	long endbyte;
	int  endbit;

	unsigned char *buffer;
	unsigned char *ptr;
	long storage;
} oggpack_buffer;

typedef struct {
	unsigned char *header;
	long header_len;
	unsigned char *body;
	long body_len;
} ogg_page;

typedef struct {
	unsigned char *body_data;
	long body_storage;
	long body_fill;
	long body_returned;

	int *lacing_vals;
	ogg_int64_t *granule_vals;
                             
	long lacing_storage;
	long lacing_fill;
	long lacing_packet;
	long lacing_returned;

	unsigned char header[282];
	int header_fill;

	int e_o_s;
	int b_o_s;

	long serialno;
	long pageno;
	ogg_int64_t packetno;
	ogg_int64_t granulepos;

} ogg_stream_state;

typedef struct {
  unsigned char *packet;
  long bytes;
  long b_o_s;
  long e_o_s;

  ogg_int64_t granulepos;
  ogg_int64_t packetno;
} ogg_packet;

typedef struct {
  unsigned char *data;
  int storage;
  int fill;
  int returned;

  int unsynced;
  int headerbytes;
  int bodybytes;
} ogg_sync_state;

extern void  oggpack_writeinit(oggpack_buffer *b);
extern int   oggpack_writecheck(oggpack_buffer *b);
extern void  oggpack_writetrunc(oggpack_buffer *b,long bits);
extern void  oggpack_writealign(oggpack_buffer *b);
extern void  oggpack_writecopy(oggpack_buffer *b,void *source,long bits);
extern void  oggpack_reset(oggpack_buffer *b);
extern void  oggpack_writeclear(oggpack_buffer *b);
extern void  oggpack_readinit(oggpack_buffer *b,unsigned char *buf,int bytes);
extern void  oggpack_write(oggpack_buffer *b,unsigned long value,int bits);
extern long  oggpack_look(oggpack_buffer *b,int bits);
extern long  oggpack_look1(oggpack_buffer *b);
extern void  oggpack_adv(oggpack_buffer *b,int bits);
extern void  oggpack_adv1(oggpack_buffer *b);
extern long  oggpack_read(oggpack_buffer *b,int bits);
extern long  oggpack_read1(oggpack_buffer *b);
extern long  oggpack_bytes(oggpack_buffer *b);
extern long  oggpack_bits(oggpack_buffer *b);
extern unsigned char *oggpack_get_buffer(oggpack_buffer *b);

extern void  oggpackB_writeinit(oggpack_buffer *b);
extern int   oggpackB_writecheck(oggpack_buffer *b);
extern void  oggpackB_writetrunc(oggpack_buffer *b,long bits);
extern void  oggpackB_writealign(oggpack_buffer *b);
extern void  oggpackB_writecopy(oggpack_buffer *b,void *source,long bits);
extern void  oggpackB_reset(oggpack_buffer *b);
extern void  oggpackB_writeclear(oggpack_buffer *b);
extern void  oggpackB_readinit(oggpack_buffer *b,unsigned char *buf,int bytes);
extern void  oggpackB_write(oggpack_buffer *b,unsigned long value,int bits);
extern long  oggpackB_look(oggpack_buffer *b,int bits);
extern long  oggpackB_look1(oggpack_buffer *b);
extern void  oggpackB_adv(oggpack_buffer *b,int bits);
extern void  oggpackB_adv1(oggpack_buffer *b);
extern long  oggpackB_read(oggpack_buffer *b,int bits);
extern long  oggpackB_read1(oggpack_buffer *b);
extern long  oggpackB_bytes(oggpack_buffer *b);
extern long  oggpackB_bits(oggpack_buffer *b);
extern unsigned char *oggpackB_get_buffer(oggpack_buffer *b);

extern int      ogg_stream_packetin(ogg_stream_state *os, ogg_packet *op);
extern int      ogg_stream_iovecin(ogg_stream_state *os, ogg_iovec_t *iov,
                                   int count, long e_o_s, ogg_int64_t granulepos);
extern int      ogg_stream_pageout(ogg_stream_state *os, ogg_page *og);
extern int      ogg_stream_pageout_fill(ogg_stream_state *os, ogg_page *og, int nfill);
extern int      ogg_stream_flush(ogg_stream_state *os, ogg_page *og);
extern int      ogg_stream_flush_fill(ogg_stream_state *os, ogg_page *og, int nfill);

extern int      ogg_sync_init(ogg_sync_state *oy);
extern int      ogg_sync_clear(ogg_sync_state *oy);
extern int      ogg_sync_reset(ogg_sync_state *oy);
extern int      ogg_sync_destroy(ogg_sync_state *oy);
extern int      ogg_sync_check(ogg_sync_state *oy);

extern char    *ogg_sync_buffer(ogg_sync_state *oy, long size);
extern int      ogg_sync_wrote(ogg_sync_state *oy, long bytes);
extern long     ogg_sync_pageseek(ogg_sync_state *oy,ogg_page *og);
extern int      ogg_sync_pageout(ogg_sync_state *oy, ogg_page *og);
extern int      ogg_stream_pagein(ogg_stream_state *os, ogg_page *og);
extern int      ogg_stream_packetout(ogg_stream_state *os,ogg_packet *op);
extern int      ogg_stream_packetpeek(ogg_stream_state *os,ogg_packet *op);

extern int      ogg_stream_init(ogg_stream_state *os,int serialno);
extern int      ogg_stream_clear(ogg_stream_state *os);
extern int      ogg_stream_reset(ogg_stream_state *os);
extern int      ogg_stream_reset_serialno(ogg_stream_state *os,int serialno);
extern int      ogg_stream_destroy(ogg_stream_state *os);
extern int      ogg_stream_check(ogg_stream_state *os);
extern int      ogg_stream_eos(ogg_stream_state *os);

extern void     ogg_page_checksum_set(ogg_page *og);

extern int      ogg_page_version(const ogg_page *og);
extern int      ogg_page_continued(const ogg_page *og);
extern int      ogg_page_bos(const ogg_page *og);
extern int      ogg_page_eos(const ogg_page *og);
extern ogg_int64_t  ogg_page_granulepos(const ogg_page *og);
extern int      ogg_page_serialno(const ogg_page *og);
extern long     ogg_page_pageno(const ogg_page *og);
extern int      ogg_page_packets(const ogg_page *og);

extern void     ogg_packet_clear(ogg_packet *op);
�typedef __int64 ogg_int64_t;
typedef __int32 ogg_int32_t;
typedef unsigned __int32 ogg_uint32_t;
typedef __int16 ogg_int16_t;
typedef unsigned __int16 ogg_uint16_t;
	cdefClib/win32/libogg.dll	loadWindowsosffirequire��Coeus ffi libogg 	  ]==])
Coeus:AddVFSFile('Bindings.libvorbis', [==[LJ �'local Coeus = ...
local ffi = require("ffi")
local libvorbis = (ffi.os == "Windows") and ffi.load("lib/win32/libvorbis.dll") or ffi.C

Coeus:Load("Bindings.libogg")

--codec.h
ffi.cdef([[
typedef struct vorbis_info {
	int version;
	int channels;
	long rate;

	long bitrate_upper;
	long bitrate_nominal;
	long bitrate_lower;
	long bitrate_window;

	void *codec_setup;
} vorbis_info;

typedef struct vorbis_dsp_state {
  int analysisp;
  vorbis_info *vi;

  float **pcm;
  float **pcmret;
  int      pcm_storage;
  int      pcm_current;
  int      pcm_returned;

  int  preextrapolate;
  int  eofflag;

  long lW;
  long W;
  long nW;
  long centerW;

  ogg_int64_t granulepos;
  ogg_int64_t sequence;

  ogg_int64_t glue_bits;
  ogg_int64_t time_bits;
  ogg_int64_t floor_bits;
  ogg_int64_t res_bits;

  void       *backend_state;
} vorbis_dsp_state;

typedef struct vorbis_block {
  float  **pcm;
  oggpack_buffer opb;

  long  lW;
  long  W;
  long  nW;
  int   pcmend;
  int   mode;

  int         eofflag;
  ogg_int64_t granulepos;
  ogg_int64_t sequence;
  vorbis_dsp_state *vd;

  void               *localstore;
  long                localtop;
  long                localalloc;
  long                totaluse;
  struct alloc_chain *reap;

  long glue_bits;
  long time_bits;
  long floor_bits;
  long res_bits;

  void *internal;

} vorbis_block;

struct alloc_chain{
  void *ptr;
  struct alloc_chain *next;
};

typedef struct vorbis_comment{
  char **user_comments;
  int   *comment_lengths;
  int    comments;
  char  *vendor;

} vorbis_comment;

extern void     vorbis_info_init(vorbis_info *vi);
extern void     vorbis_info_clear(vorbis_info *vi);
extern int      vorbis_info_blocksize(vorbis_info *vi,int zo);
extern void     vorbis_comment_init(vorbis_comment *vc);
extern void     vorbis_comment_add(vorbis_comment *vc, const char *comment);
extern void     vorbis_comment_add_tag(vorbis_comment *vc,
                                       const char *tag, const char *contents);
extern char    *vorbis_comment_query(vorbis_comment *vc, const char *tag, int count);
extern int      vorbis_comment_query_count(vorbis_comment *vc, const char *tag);
extern void     vorbis_comment_clear(vorbis_comment *vc);

extern int      vorbis_block_init(vorbis_dsp_state *v, vorbis_block *vb);
extern int      vorbis_block_clear(vorbis_block *vb);
extern void     vorbis_dsp_clear(vorbis_dsp_state *v);
extern double   vorbis_granule_time(vorbis_dsp_state *v,
                                    ogg_int64_t granulepos);

extern const char *vorbis_version_string(void);

extern int      vorbis_analysis_init(vorbis_dsp_state *v,vorbis_info *vi);
extern int      vorbis_commentheader_out(vorbis_comment *vc, ogg_packet *op);
extern int      vorbis_analysis_headerout(vorbis_dsp_state *v,
                                          vorbis_comment *vc,
                                          ogg_packet *op,
                                          ogg_packet *op_comm,
                                          ogg_packet *op_code);
extern float  **vorbis_analysis_buffer(vorbis_dsp_state *v,int vals);
extern int      vorbis_analysis_wrote(vorbis_dsp_state *v,int vals);
extern int      vorbis_analysis_blockout(vorbis_dsp_state *v,vorbis_block *vb);
extern int      vorbis_analysis(vorbis_block *vb,ogg_packet *op);

extern int      vorbis_bitrate_addblock(vorbis_block *vb);
extern int      vorbis_bitrate_flushpacket(vorbis_dsp_state *vd,
                                           ogg_packet *op);

extern int      vorbis_synthesis_idheader(ogg_packet *op);
extern int      vorbis_synthesis_headerin(vorbis_info *vi,vorbis_comment *vc,
                                          ogg_packet *op);

extern int      vorbis_synthesis_init(vorbis_dsp_state *v,vorbis_info *vi);
extern int      vorbis_synthesis_restart(vorbis_dsp_state *v);
extern int      vorbis_synthesis(vorbis_block *vb,ogg_packet *op);
extern int      vorbis_synthesis_trackonly(vorbis_block *vb,ogg_packet *op);
extern int      vorbis_synthesis_blockin(vorbis_dsp_state *v,vorbis_block *vb);
extern int      vorbis_synthesis_pcmout(vorbis_dsp_state *v,float ***pcm);
extern int      vorbis_synthesis_lapout(vorbis_dsp_state *v,float ***pcm);
extern int      vorbis_synthesis_read(vorbis_dsp_state *v,int samples);
extern long     vorbis_packet_blocksize(vorbis_info *vi,ogg_packet *op);

extern int      vorbis_synthesis_halfrate(vorbis_info *v,int flag);
extern int      vorbis_synthesis_halfrate_p(vorbis_info *v);

enum {
	OV_FALSE      = -1,
	OV_EOF        = -2,
	OV_HOLE       = -3,

	OV_EREAD      = -128,
	OV_EFAULT     = -129,
	OV_EIMPL      = -130,
	OV_EINVAL     = -131,
	OV_ENOTVORBIS = -132,
	OV_EBADHEADER = -133,
	OV_EVERSION   = -134,
	OV_ENOTAUDIO  = -135,
	OV_EBADPACKET = -136,
	OV_EBADLINK   = -137,
	OV_ENOSEEK    = -138
};
]])

return libvorbis�%   0 �C  4  % >7 T�7% >  T�7  7 % >7	%
 >H �$typedef struct vorbis_info {
	int version;
	int channels;
	long rate;

	long bitrate_upper;
	long bitrate_nominal;
	long bitrate_lower;
	long bitrate_window;

	void *codec_setup;
} vorbis_info;

typedef struct vorbis_dsp_state {
  int analysisp;
  vorbis_info *vi;

  float **pcm;
  float **pcmret;
  int      pcm_storage;
  int      pcm_current;
  int      pcm_returned;

  int  preextrapolate;
  int  eofflag;

  long lW;
  long W;
  long nW;
  long centerW;

  ogg_int64_t granulepos;
  ogg_int64_t sequence;

  ogg_int64_t glue_bits;
  ogg_int64_t time_bits;
  ogg_int64_t floor_bits;
  ogg_int64_t res_bits;

  void       *backend_state;
} vorbis_dsp_state;

typedef struct vorbis_block {
  float  **pcm;
  oggpack_buffer opb;

  long  lW;
  long  W;
  long  nW;
  int   pcmend;
  int   mode;

  int         eofflag;
  ogg_int64_t granulepos;
  ogg_int64_t sequence;
  vorbis_dsp_state *vd;

  void               *localstore;
  long                localtop;
  long                localalloc;
  long                totaluse;
  struct alloc_chain *reap;

  long glue_bits;
  long time_bits;
  long floor_bits;
  long res_bits;

  void *internal;

} vorbis_block;

struct alloc_chain{
  void *ptr;
  struct alloc_chain *next;
};

typedef struct vorbis_comment{
  char **user_comments;
  int   *comment_lengths;
  int    comments;
  char  *vendor;

} vorbis_comment;

extern void     vorbis_info_init(vorbis_info *vi);
extern void     vorbis_info_clear(vorbis_info *vi);
extern int      vorbis_info_blocksize(vorbis_info *vi,int zo);
extern void     vorbis_comment_init(vorbis_comment *vc);
extern void     vorbis_comment_add(vorbis_comment *vc, const char *comment);
extern void     vorbis_comment_add_tag(vorbis_comment *vc,
                                       const char *tag, const char *contents);
extern char    *vorbis_comment_query(vorbis_comment *vc, const char *tag, int count);
extern int      vorbis_comment_query_count(vorbis_comment *vc, const char *tag);
extern void     vorbis_comment_clear(vorbis_comment *vc);

extern int      vorbis_block_init(vorbis_dsp_state *v, vorbis_block *vb);
extern int      vorbis_block_clear(vorbis_block *vb);
extern void     vorbis_dsp_clear(vorbis_dsp_state *v);
extern double   vorbis_granule_time(vorbis_dsp_state *v,
                                    ogg_int64_t granulepos);

extern const char *vorbis_version_string(void);

extern int      vorbis_analysis_init(vorbis_dsp_state *v,vorbis_info *vi);
extern int      vorbis_commentheader_out(vorbis_comment *vc, ogg_packet *op);
extern int      vorbis_analysis_headerout(vorbis_dsp_state *v,
                                          vorbis_comment *vc,
                                          ogg_packet *op,
                                          ogg_packet *op_comm,
                                          ogg_packet *op_code);
extern float  **vorbis_analysis_buffer(vorbis_dsp_state *v,int vals);
extern int      vorbis_analysis_wrote(vorbis_dsp_state *v,int vals);
extern int      vorbis_analysis_blockout(vorbis_dsp_state *v,vorbis_block *vb);
extern int      vorbis_analysis(vorbis_block *vb,ogg_packet *op);

extern int      vorbis_bitrate_addblock(vorbis_block *vb);
extern int      vorbis_bitrate_flushpacket(vorbis_dsp_state *vd,
                                           ogg_packet *op);

extern int      vorbis_synthesis_idheader(ogg_packet *op);
extern int      vorbis_synthesis_headerin(vorbis_info *vi,vorbis_comment *vc,
                                          ogg_packet *op);

extern int      vorbis_synthesis_init(vorbis_dsp_state *v,vorbis_info *vi);
extern int      vorbis_synthesis_restart(vorbis_dsp_state *v);
extern int      vorbis_synthesis(vorbis_block *vb,ogg_packet *op);
extern int      vorbis_synthesis_trackonly(vorbis_block *vb,ogg_packet *op);
extern int      vorbis_synthesis_blockin(vorbis_dsp_state *v,vorbis_block *vb);
extern int      vorbis_synthesis_pcmout(vorbis_dsp_state *v,float ***pcm);
extern int      vorbis_synthesis_lapout(vorbis_dsp_state *v,float ***pcm);
extern int      vorbis_synthesis_read(vorbis_dsp_state *v,int samples);
extern long     vorbis_packet_blocksize(vorbis_info *vi,ogg_packet *op);

extern int      vorbis_synthesis_halfrate(vorbis_info *v,int flag);
extern int      vorbis_synthesis_halfrate_p(vorbis_info *v);

enum {
	OV_FALSE      = -1,
	OV_EOF        = -2,
	OV_HOLE       = -3,

	OV_EREAD      = -128,
	OV_EFAULT     = -129,
	OV_EIMPL      = -130,
	OV_EINVAL     = -131,
	OV_ENOTVORBIS = -132,
	OV_EBADHEADER = -133,
	OV_EVERSION   = -134,
	OV_ENOTAUDIO  = -135,
	OV_EBADPACKET = -136,
	OV_EBADLINK   = -137,
	OV_ENOSEEK    = -138
};
	cdefBindings.libogg	LoadClib/win32/libvorbis.dll	loadWindowsosffirequire��Coeus ffi libvorbis 	  ]==])
Coeus:AddVFSFile('Bindings.libvorbisfile', [==[LJ �local Coeus = ...
local ffi = require("ffi")
local libvorbisfile = (ffi.os == "Windows") and ffi.load("lib/win32/libvorbisfile.dll") or ffi.C

Coeus:Load("Bindings.libvorbis")
Coeus:Load("Bindings.stdio_")

--vorbisfile.h
ffi.cdef([[
typedef struct {
	size_t (*read_func)  (void *ptr, size_t size, size_t nmemb, void *datasource);
	int    (*seek_func)  (void *datasource, ogg_int64_t offset, int whence);
	int    (*close_func) (void *datasource);
	long   (*tell_func)  (void *datasource);
} ov_callbacks;

enum {
	NOTOPEN = 0,
	PARTOPEN = 1,
	OPENED = 2,
	STREAMSET = 3,
	INITSET = 4
};

typedef struct OggVorbis_File {
	void            *datasource;
	int              seekable;
	ogg_int64_t      offset;
	ogg_int64_t      end;
	ogg_sync_state   oy;

	int              links;
	ogg_int64_t     *offsets;
	ogg_int64_t     *dataoffsets;
	long            *serialnos;
	ogg_int64_t     *pcmlengths;

	vorbis_info     *vi;
	vorbis_comment  *vc;

	ogg_int64_t      pcm_offset;
	int              ready_state;
	long             current_serialno;
	int              current_link;

	double           bittrack;
	double           samptrack;

	ogg_stream_state os;
	vorbis_dsp_state vd;
	vorbis_block     vb;

	ov_callbacks callbacks;
} OggVorbis_File;


extern int ov_clear(OggVorbis_File *vf);
extern int ov_fopen(const char *path,OggVorbis_File *vf);
extern int ov_open(FILE *f,OggVorbis_File *vf,const char *initial,long ibytes);
extern int ov_open_callbacks(void *datasource, OggVorbis_File *vf,
                const char *initial, long ibytes, ov_callbacks callbacks);

extern int ov_test(FILE *f,OggVorbis_File *vf,const char *initial,long ibytes);
extern int ov_test_callbacks(void *datasource, OggVorbis_File *vf,
                const char *initial, long ibytes, ov_callbacks callbacks);
extern int ov_test_open(OggVorbis_File *vf);

extern long ov_bitrate(OggVorbis_File *vf,int i);
extern long ov_bitrate_instant(OggVorbis_File *vf);
extern long ov_streams(OggVorbis_File *vf);
extern long ov_seekable(OggVorbis_File *vf);
extern long ov_serialnumber(OggVorbis_File *vf,int i);

extern ogg_int64_t ov_raw_total(OggVorbis_File *vf,int i);
extern ogg_int64_t ov_pcm_total(OggVorbis_File *vf,int i);
extern double ov_time_total(OggVorbis_File *vf,int i);

extern int ov_raw_seek(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek_page(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_time_seek(OggVorbis_File *vf,double pos);
extern int ov_time_seek_page(OggVorbis_File *vf,double pos);

extern int ov_raw_seek_lap(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek_lap(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek_page_lap(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_time_seek_lap(OggVorbis_File *vf,double pos);
extern int ov_time_seek_page_lap(OggVorbis_File *vf,double pos);

extern ogg_int64_t ov_raw_tell(OggVorbis_File *vf);
extern ogg_int64_t ov_pcm_tell(OggVorbis_File *vf);
extern double ov_time_tell(OggVorbis_File *vf);

extern vorbis_info *ov_info(OggVorbis_File *vf,int link);
extern vorbis_comment *ov_comment(OggVorbis_File *vf,int link);

extern long ov_read_float(OggVorbis_File *vf,float ***pcm_channels,int samples,
                          int *bitstream);
extern long ov_read_filter(OggVorbis_File *vf,char *buffer,int length,
                          int bigendianp,int word,int sgned,int *bitstream,
                          void (*filter)(float **pcm,long channels,long samples,void *filter_param),void *filter_param);
extern long ov_read(OggVorbis_File *vf,char *buffer,int length,
                    int bigendianp,int word,int sgned,int *bitstream);
extern int ov_crosslap(OggVorbis_File *vf1,OggVorbis_File *vf2);

extern int ov_halfrate(OggVorbis_File *vf,int flag);
extern int ov_halfrate_p(OggVorbis_File *vf);
]])

return libvorbisfile�   8 nC  4  % >7 T�7% >  T�7  7 % >  7 %	 >7
% >H �typedef struct {
	size_t (*read_func)  (void *ptr, size_t size, size_t nmemb, void *datasource);
	int    (*seek_func)  (void *datasource, ogg_int64_t offset, int whence);
	int    (*close_func) (void *datasource);
	long   (*tell_func)  (void *datasource);
} ov_callbacks;

enum {
	NOTOPEN = 0,
	PARTOPEN = 1,
	OPENED = 2,
	STREAMSET = 3,
	INITSET = 4
};

typedef struct OggVorbis_File {
	void            *datasource;
	int              seekable;
	ogg_int64_t      offset;
	ogg_int64_t      end;
	ogg_sync_state   oy;

	int              links;
	ogg_int64_t     *offsets;
	ogg_int64_t     *dataoffsets;
	long            *serialnos;
	ogg_int64_t     *pcmlengths;

	vorbis_info     *vi;
	vorbis_comment  *vc;

	ogg_int64_t      pcm_offset;
	int              ready_state;
	long             current_serialno;
	int              current_link;

	double           bittrack;
	double           samptrack;

	ogg_stream_state os;
	vorbis_dsp_state vd;
	vorbis_block     vb;

	ov_callbacks callbacks;
} OggVorbis_File;


extern int ov_clear(OggVorbis_File *vf);
extern int ov_fopen(const char *path,OggVorbis_File *vf);
extern int ov_open(FILE *f,OggVorbis_File *vf,const char *initial,long ibytes);
extern int ov_open_callbacks(void *datasource, OggVorbis_File *vf,
                const char *initial, long ibytes, ov_callbacks callbacks);

extern int ov_test(FILE *f,OggVorbis_File *vf,const char *initial,long ibytes);
extern int ov_test_callbacks(void *datasource, OggVorbis_File *vf,
                const char *initial, long ibytes, ov_callbacks callbacks);
extern int ov_test_open(OggVorbis_File *vf);

extern long ov_bitrate(OggVorbis_File *vf,int i);
extern long ov_bitrate_instant(OggVorbis_File *vf);
extern long ov_streams(OggVorbis_File *vf);
extern long ov_seekable(OggVorbis_File *vf);
extern long ov_serialnumber(OggVorbis_File *vf,int i);

extern ogg_int64_t ov_raw_total(OggVorbis_File *vf,int i);
extern ogg_int64_t ov_pcm_total(OggVorbis_File *vf,int i);
extern double ov_time_total(OggVorbis_File *vf,int i);

extern int ov_raw_seek(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek_page(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_time_seek(OggVorbis_File *vf,double pos);
extern int ov_time_seek_page(OggVorbis_File *vf,double pos);

extern int ov_raw_seek_lap(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek_lap(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek_page_lap(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_time_seek_lap(OggVorbis_File *vf,double pos);
extern int ov_time_seek_page_lap(OggVorbis_File *vf,double pos);

extern ogg_int64_t ov_raw_tell(OggVorbis_File *vf);
extern ogg_int64_t ov_pcm_tell(OggVorbis_File *vf);
extern double ov_time_tell(OggVorbis_File *vf);

extern vorbis_info *ov_info(OggVorbis_File *vf,int link);
extern vorbis_comment *ov_comment(OggVorbis_File *vf,int link);

extern long ov_read_float(OggVorbis_File *vf,float ***pcm_channels,int samples,
                          int *bitstream);
extern long ov_read_filter(OggVorbis_File *vf,char *buffer,int length,
                          int bigendianp,int word,int sgned,int *bitstream,
                          void (*filter)(float **pcm,long channels,long samples,void *filter_param),void *filter_param);
extern long ov_read(OggVorbis_File *vf,char *buffer,int length,
                    int bigendianp,int word,int sgned,int *bitstream);
extern int ov_crosslap(OggVorbis_File *vf1,OggVorbis_File *vf2);

extern int ov_halfrate(OggVorbis_File *vf,int flag);
extern int ov_halfrate_p(OggVorbis_File *vf);
	cdefBindings.stdio_Bindings.libvorbis	LoadC lib/win32/libvorbisfile.dll	loadWindowsosffirequire	l	nCoeus ffi libvorbisfile 	  ]==])
Coeus:AddVFSFile('Bindings.lodepng', [==[LJ �^local Coeus = ...
local ffi = require("ffi")
local lib = Coeus.Bindings.coeus_aux

ffi.cdef([[
/*
LodePNG version 20140624

Copyright (c) 2005-2014 Lode Vandevenne

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
*/

typedef enum LodePNGColorType
{
  LCT_GREY = 0,
  LCT_RGB = 2,
  LCT_PALETTE = 3,
  LCT_GREY_ALPHA = 4,
  LCT_RGBA = 6
} LodePNGColorType;

unsigned lodepng_decode_memory(unsigned char** out, unsigned* w, unsigned* h,
                               const unsigned char* in, size_t insize,
                               LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_decode32(unsigned char** out, unsigned* w, unsigned* h,
                          const unsigned char* in, size_t insize);
unsigned lodepng_decode24(unsigned char** out, unsigned* w, unsigned* h,
                          const unsigned char* in, size_t insize);
unsigned lodepng_decode_file(unsigned char** out, unsigned* w, unsigned* h,
                             const char* filename,
                             LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_decode32_file(unsigned char** out, unsigned* w, unsigned* h,
                               const char* filename);
unsigned lodepng_decode24_file(unsigned char** out, unsigned* w, unsigned* h,
                               const char* filename);
unsigned lodepng_encode_memory(unsigned char** out, size_t* outsize,
                               const unsigned char* image, unsigned w, unsigned h,
                               LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_encode32(unsigned char** out, size_t* outsize,
                          const unsigned char* image, unsigned w, unsigned h);
unsigned lodepng_encode24(unsigned char** out, size_t* outsize,
                          const unsigned char* image, unsigned w, unsigned h);
unsigned lodepng_encode_file(const char* filename,
                             const unsigned char* image, unsigned w, unsigned h,
                             LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_encode32_file(const char* filename,
                               const unsigned char* image, unsigned w, unsigned h);
unsigned lodepng_encode24_file(const char* filename,
                               const unsigned char* image, unsigned w, unsigned h);
const char* lodepng_error_text(unsigned code);
typedef struct LodePNGDecompressSettings LodePNGDecompressSettings;

struct LodePNGDecompressSettings
{
  unsigned ignore_adler32;
  unsigned (*custom_zlib)(unsigned char**, size_t*,
                          const unsigned char*, size_t,
                          const LodePNGDecompressSettings*);
  unsigned (*custom_inflate)(unsigned char**, size_t*,
                             const unsigned char*, size_t,
                             const LodePNGDecompressSettings*);
  const void* custom_context;
};

extern const LodePNGDecompressSettings lodepng_default_decompress_settings;
void lodepng_decompress_settings_init(LodePNGDecompressSettings* settings);

typedef struct LodePNGCompressSettings LodePNGCompressSettings;
struct LodePNGCompressSettings
{
  unsigned btype;
  unsigned use_lz77;
  unsigned windowsize;
  unsigned minmatch;
  unsigned nicematch;
  unsigned lazymatching;
  unsigned (*custom_zlib)(unsigned char**, size_t*,
                          const unsigned char*, size_t,
                          const LodePNGCompressSettings*);
  unsigned (*custom_deflate)(unsigned char**, size_t*,
                             const unsigned char*, size_t,
                             const LodePNGCompressSettings*);
  const void* custom_context;
};

extern const LodePNGCompressSettings lodepng_default_compress_settings;
void lodepng_compress_settings_init(LodePNGCompressSettings* settings);

typedef struct LodePNGColorMode
{
  LodePNGColorType colortype;
  unsigned bitdepth;
  unsigned char* palette;
  size_t palettesize;
  unsigned key_defined;
  unsigned key_r;
  unsigned key_g;
  unsigned key_b;
} LodePNGColorMode;

void lodepng_color_mode_init(LodePNGColorMode* info);
void lodepng_color_mode_cleanup(LodePNGColorMode* info);
unsigned lodepng_color_mode_copy(LodePNGColorMode* dest, const LodePNGColorMode* source);
void lodepng_palette_clear(LodePNGColorMode* info);
unsigned lodepng_palette_add(LodePNGColorMode* info,
                             unsigned char r, unsigned char g, unsigned char b, unsigned char a);

unsigned lodepng_get_bpp(const LodePNGColorMode* info);
unsigned lodepng_get_channels(const LodePNGColorMode* info);
unsigned lodepng_is_greyscale_type(const LodePNGColorMode* info);
unsigned lodepng_is_alpha_type(const LodePNGColorMode* info);
unsigned lodepng_is_palette_type(const LodePNGColorMode* info);
unsigned lodepng_has_palette_alpha(const LodePNGColorMode* info);
unsigned lodepng_can_have_alpha(const LodePNGColorMode* info);
size_t lodepng_get_raw_size(unsigned w, unsigned h, const LodePNGColorMode* color);

typedef struct LodePNGTime
{
  unsigned year;
  unsigned month;
  unsigned day;
  unsigned hour;
  unsigned minute;
  unsigned second;
} LodePNGTime;

typedef struct LodePNGInfo
{
  unsigned compression_method;
  unsigned filter_method;
  unsigned interlace_method;
  LodePNGColorMode color;
  unsigned background_defined;
  unsigned background_r;
  unsigned background_g;
  unsigned background_b;
  size_t text_num;
  char** text_keys;
  char** text_strings;
  size_t itext_num;
  char** itext_keys;
  char** itext_langtags;
  char** itext_transkeys;
  char** itext_strings;
  unsigned time_defined;
  LodePNGTime time;
  unsigned phys_defined;
  unsigned phys_x;
  unsigned phys_y;
  unsigned phys_unit;
  unsigned char* unknown_chunks_data[3];
  size_t unknown_chunks_size[3];
} LodePNGInfo;

void lodepng_info_init(LodePNGInfo* info);
void lodepng_info_cleanup(LodePNGInfo* info);
unsigned lodepng_info_copy(LodePNGInfo* dest, const LodePNGInfo* source);
void lodepng_clear_text(LodePNGInfo* info);
unsigned lodepng_add_text(LodePNGInfo* info, const char* key, const char* str);
void lodepng_clear_itext(LodePNGInfo* info);
unsigned lodepng_add_itext(LodePNGInfo* info, const char* key, const char* langtag,
                           const char* transkey, const char* str);
unsigned lodepng_convert(unsigned char* out, const unsigned char* in,
                         LodePNGColorMode* mode_out, const LodePNGColorMode* mode_in,
                         unsigned w, unsigned h, unsigned fix_png);

typedef struct LodePNGDecoderSettings
{
  LodePNGDecompressSettings zlibsettings;
  unsigned ignore_crc;
  unsigned fix_png;
  unsigned color_convert;
  unsigned read_text_chunks;
  unsigned remember_unknown_chunks;
} LodePNGDecoderSettings;

void lodepng_decoder_settings_init(LodePNGDecoderSettings* settings);

typedef enum LodePNGFilterStrategy
{
  LFS_ZERO,
  LFS_MINSUM,
  LFS_ENTROPY,
  LFS_BRUTE_FORCE,
  LFS_PREDEFINED
} LodePNGFilterStrategy;

typedef enum LodePNGAutoConvert
{
  LAC_NO,
  LAC_ALPHA,
  LAC_AUTO,
  LAC_AUTO_NO_NIBBLES,
  LAC_AUTO_NO_PALETTE,
  LAC_AUTO_NO_NIBBLES_NO_PALETTE
} LodePNGAutoConvert;

unsigned lodepng_auto_choose_color(LodePNGColorMode* mode_out,
                                   const unsigned char* image, unsigned w, unsigned h,
                                   const LodePNGColorMode* mode_in,
                                   LodePNGAutoConvert auto_convert);

typedef struct LodePNGEncoderSettings
{
  LodePNGCompressSettings zlibsettings;
  LodePNGAutoConvert auto_convert;
  unsigned filter_palette_zero;
  LodePNGFilterStrategy filter_strategy;
  const unsigned char* predefined_filters;
  unsigned force_palette;
  unsigned add_id;
  unsigned text_compression;
} LodePNGEncoderSettings;

void lodepng_encoder_settings_init(LodePNGEncoderSettings* settings);

typedef struct LodePNGState
{
  LodePNGDecoderSettings decoder;
  LodePNGEncoderSettings encoder;
  LodePNGColorMode info_raw;
  LodePNGInfo info_png;
  unsigned error;
} LodePNGState;

void lodepng_state_init(LodePNGState* state);
void lodepng_state_cleanup(LodePNGState* state);
void lodepng_state_copy(LodePNGState* dest, const LodePNGState* source);

unsigned lodepng_decode(unsigned char** out, unsigned* w, unsigned* h,
                        LodePNGState* state,
                        const unsigned char* in, size_t insize);
unsigned lodepng_inspect(unsigned* w, unsigned* h,
                         LodePNGState* state,
                         const unsigned char* in, size_t insize);
unsigned lodepng_encode(unsigned char** out, size_t* outsize,
                        const unsigned char* image, unsigned w, unsigned h,
                        LodePNGState* state);

unsigned lodepng_chunk_length(const unsigned char* chunk);
void lodepng_chunk_type(char type[5], const unsigned char* chunk);
unsigned char lodepng_chunk_type_equals(const unsigned char* chunk, const char* type);
unsigned char lodepng_chunk_ancillary(const unsigned char* chunk);
unsigned char lodepng_chunk_private(const unsigned char* chunk);
unsigned char lodepng_chunk_safetocopy(const unsigned char* chunk);
unsigned char* lodepng_chunk_data(unsigned char* chunk);
const unsigned char* lodepng_chunk_data_const(const unsigned char* chunk);
unsigned lodepng_chunk_check_crc(const unsigned char* chunk);
void lodepng_chunk_generate_crc(unsigned char* chunk);
unsigned char* lodepng_chunk_next(unsigned char* chunk);
const unsigned char* lodepng_chunk_next_const(const unsigned char* chunk);
unsigned lodepng_chunk_append(unsigned char** out, size_t* outlength, const unsigned char* chunk);
unsigned lodepng_chunk_create(unsigned char** out, size_t* outlength, unsigned length,
                              const char* type, const unsigned char* data);

unsigned lodepng_crc32(const unsigned char* buf, size_t len);

unsigned lodepng_inflate(unsigned char** out, size_t* outsize,
                         const unsigned char* in, size_t insize,
                         const LodePNGDecompressSettings* settings);
unsigned lodepng_zlib_decompress(unsigned char** out, size_t* outsize,
                                 const unsigned char* in, size_t insize,
                                 const LodePNGDecompressSettings* settings);
unsigned lodepng_zlib_compress(unsigned char** out, size_t* outsize,
                               const unsigned char* in, size_t insize,
                               const LodePNGCompressSettings* settings);
unsigned lodepng_huffman_code_lengths(unsigned* lengths, const unsigned* frequencies,
                                      size_t numcodes, unsigned maxbitlen);
unsigned lodepng_deflate(unsigned char** out, size_t* outsize,
                         const unsigned char* in, size_t insize,
                         const LodePNGCompressSettings* settings);

unsigned lodepng_load_file(unsigned char** out, size_t* outsize, const char* filename);
unsigned lodepng_save_file(const unsigned char* buffer, size_t buffersize, const char* filename);
]])

return lib�\   
) �C  4  % >7 77% >H �[/*
LodePNG version 20140624

Copyright (c) 2005-2014 Lode Vandevenne

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
*/

typedef enum LodePNGColorType
{
  LCT_GREY = 0,
  LCT_RGB = 2,
  LCT_PALETTE = 3,
  LCT_GREY_ALPHA = 4,
  LCT_RGBA = 6
} LodePNGColorType;

unsigned lodepng_decode_memory(unsigned char** out, unsigned* w, unsigned* h,
                               const unsigned char* in, size_t insize,
                               LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_decode32(unsigned char** out, unsigned* w, unsigned* h,
                          const unsigned char* in, size_t insize);
unsigned lodepng_decode24(unsigned char** out, unsigned* w, unsigned* h,
                          const unsigned char* in, size_t insize);
unsigned lodepng_decode_file(unsigned char** out, unsigned* w, unsigned* h,
                             const char* filename,
                             LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_decode32_file(unsigned char** out, unsigned* w, unsigned* h,
                               const char* filename);
unsigned lodepng_decode24_file(unsigned char** out, unsigned* w, unsigned* h,
                               const char* filename);
unsigned lodepng_encode_memory(unsigned char** out, size_t* outsize,
                               const unsigned char* image, unsigned w, unsigned h,
                               LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_encode32(unsigned char** out, size_t* outsize,
                          const unsigned char* image, unsigned w, unsigned h);
unsigned lodepng_encode24(unsigned char** out, size_t* outsize,
                          const unsigned char* image, unsigned w, unsigned h);
unsigned lodepng_encode_file(const char* filename,
                             const unsigned char* image, unsigned w, unsigned h,
                             LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_encode32_file(const char* filename,
                               const unsigned char* image, unsigned w, unsigned h);
unsigned lodepng_encode24_file(const char* filename,
                               const unsigned char* image, unsigned w, unsigned h);
const char* lodepng_error_text(unsigned code);
typedef struct LodePNGDecompressSettings LodePNGDecompressSettings;

struct LodePNGDecompressSettings
{
  unsigned ignore_adler32;
  unsigned (*custom_zlib)(unsigned char**, size_t*,
                          const unsigned char*, size_t,
                          const LodePNGDecompressSettings*);
  unsigned (*custom_inflate)(unsigned char**, size_t*,
                             const unsigned char*, size_t,
                             const LodePNGDecompressSettings*);
  const void* custom_context;
};

extern const LodePNGDecompressSettings lodepng_default_decompress_settings;
void lodepng_decompress_settings_init(LodePNGDecompressSettings* settings);

typedef struct LodePNGCompressSettings LodePNGCompressSettings;
struct LodePNGCompressSettings
{
  unsigned btype;
  unsigned use_lz77;
  unsigned windowsize;
  unsigned minmatch;
  unsigned nicematch;
  unsigned lazymatching;
  unsigned (*custom_zlib)(unsigned char**, size_t*,
                          const unsigned char*, size_t,
                          const LodePNGCompressSettings*);
  unsigned (*custom_deflate)(unsigned char**, size_t*,
                             const unsigned char*, size_t,
                             const LodePNGCompressSettings*);
  const void* custom_context;
};

extern const LodePNGCompressSettings lodepng_default_compress_settings;
void lodepng_compress_settings_init(LodePNGCompressSettings* settings);

typedef struct LodePNGColorMode
{
  LodePNGColorType colortype;
  unsigned bitdepth;
  unsigned char* palette;
  size_t palettesize;
  unsigned key_defined;
  unsigned key_r;
  unsigned key_g;
  unsigned key_b;
} LodePNGColorMode;

void lodepng_color_mode_init(LodePNGColorMode* info);
void lodepng_color_mode_cleanup(LodePNGColorMode* info);
unsigned lodepng_color_mode_copy(LodePNGColorMode* dest, const LodePNGColorMode* source);
void lodepng_palette_clear(LodePNGColorMode* info);
unsigned lodepng_palette_add(LodePNGColorMode* info,
                             unsigned char r, unsigned char g, unsigned char b, unsigned char a);

unsigned lodepng_get_bpp(const LodePNGColorMode* info);
unsigned lodepng_get_channels(const LodePNGColorMode* info);
unsigned lodepng_is_greyscale_type(const LodePNGColorMode* info);
unsigned lodepng_is_alpha_type(const LodePNGColorMode* info);
unsigned lodepng_is_palette_type(const LodePNGColorMode* info);
unsigned lodepng_has_palette_alpha(const LodePNGColorMode* info);
unsigned lodepng_can_have_alpha(const LodePNGColorMode* info);
size_t lodepng_get_raw_size(unsigned w, unsigned h, const LodePNGColorMode* color);

typedef struct LodePNGTime
{
  unsigned year;
  unsigned month;
  unsigned day;
  unsigned hour;
  unsigned minute;
  unsigned second;
} LodePNGTime;

typedef struct LodePNGInfo
{
  unsigned compression_method;
  unsigned filter_method;
  unsigned interlace_method;
  LodePNGColorMode color;
  unsigned background_defined;
  unsigned background_r;
  unsigned background_g;
  unsigned background_b;
  size_t text_num;
  char** text_keys;
  char** text_strings;
  size_t itext_num;
  char** itext_keys;
  char** itext_langtags;
  char** itext_transkeys;
  char** itext_strings;
  unsigned time_defined;
  LodePNGTime time;
  unsigned phys_defined;
  unsigned phys_x;
  unsigned phys_y;
  unsigned phys_unit;
  unsigned char* unknown_chunks_data[3];
  size_t unknown_chunks_size[3];
} LodePNGInfo;

void lodepng_info_init(LodePNGInfo* info);
void lodepng_info_cleanup(LodePNGInfo* info);
unsigned lodepng_info_copy(LodePNGInfo* dest, const LodePNGInfo* source);
void lodepng_clear_text(LodePNGInfo* info);
unsigned lodepng_add_text(LodePNGInfo* info, const char* key, const char* str);
void lodepng_clear_itext(LodePNGInfo* info);
unsigned lodepng_add_itext(LodePNGInfo* info, const char* key, const char* langtag,
                           const char* transkey, const char* str);
unsigned lodepng_convert(unsigned char* out, const unsigned char* in,
                         LodePNGColorMode* mode_out, const LodePNGColorMode* mode_in,
                         unsigned w, unsigned h, unsigned fix_png);

typedef struct LodePNGDecoderSettings
{
  LodePNGDecompressSettings zlibsettings;
  unsigned ignore_crc;
  unsigned fix_png;
  unsigned color_convert;
  unsigned read_text_chunks;
  unsigned remember_unknown_chunks;
} LodePNGDecoderSettings;

void lodepng_decoder_settings_init(LodePNGDecoderSettings* settings);

typedef enum LodePNGFilterStrategy
{
  LFS_ZERO,
  LFS_MINSUM,
  LFS_ENTROPY,
  LFS_BRUTE_FORCE,
  LFS_PREDEFINED
} LodePNGFilterStrategy;

typedef enum LodePNGAutoConvert
{
  LAC_NO,
  LAC_ALPHA,
  LAC_AUTO,
  LAC_AUTO_NO_NIBBLES,
  LAC_AUTO_NO_PALETTE,
  LAC_AUTO_NO_NIBBLES_NO_PALETTE
} LodePNGAutoConvert;

unsigned lodepng_auto_choose_color(LodePNGColorMode* mode_out,
                                   const unsigned char* image, unsigned w, unsigned h,
                                   const LodePNGColorMode* mode_in,
                                   LodePNGAutoConvert auto_convert);

typedef struct LodePNGEncoderSettings
{
  LodePNGCompressSettings zlibsettings;
  LodePNGAutoConvert auto_convert;
  unsigned filter_palette_zero;
  LodePNGFilterStrategy filter_strategy;
  const unsigned char* predefined_filters;
  unsigned force_palette;
  unsigned add_id;
  unsigned text_compression;
} LodePNGEncoderSettings;

void lodepng_encoder_settings_init(LodePNGEncoderSettings* settings);

typedef struct LodePNGState
{
  LodePNGDecoderSettings decoder;
  LodePNGEncoderSettings encoder;
  LodePNGColorMode info_raw;
  LodePNGInfo info_png;
  unsigned error;
} LodePNGState;

void lodepng_state_init(LodePNGState* state);
void lodepng_state_cleanup(LodePNGState* state);
void lodepng_state_copy(LodePNGState* dest, const LodePNGState* source);

unsigned lodepng_decode(unsigned char** out, unsigned* w, unsigned* h,
                        LodePNGState* state,
                        const unsigned char* in, size_t insize);
unsigned lodepng_inspect(unsigned* w, unsigned* h,
                         LodePNGState* state,
                         const unsigned char* in, size_t insize);
unsigned lodepng_encode(unsigned char** out, size_t* outsize,
                        const unsigned char* image, unsigned w, unsigned h,
                        LodePNGState* state);

unsigned lodepng_chunk_length(const unsigned char* chunk);
void lodepng_chunk_type(char type[5], const unsigned char* chunk);
unsigned char lodepng_chunk_type_equals(const unsigned char* chunk, const char* type);
unsigned char lodepng_chunk_ancillary(const unsigned char* chunk);
unsigned char lodepng_chunk_private(const unsigned char* chunk);
unsigned char lodepng_chunk_safetocopy(const unsigned char* chunk);
unsigned char* lodepng_chunk_data(unsigned char* chunk);
const unsigned char* lodepng_chunk_data_const(const unsigned char* chunk);
unsigned lodepng_chunk_check_crc(const unsigned char* chunk);
void lodepng_chunk_generate_crc(unsigned char* chunk);
unsigned char* lodepng_chunk_next(unsigned char* chunk);
const unsigned char* lodepng_chunk_next_const(const unsigned char* chunk);
unsigned lodepng_chunk_append(unsigned char** out, size_t* outlength, const unsigned char* chunk);
unsigned lodepng_chunk_create(unsigned char** out, size_t* outlength, unsigned length,
                              const char* type, const unsigned char* data);

unsigned lodepng_crc32(const unsigned char* buf, size_t len);

unsigned lodepng_inflate(unsigned char** out, size_t* outsize,
                         const unsigned char* in, size_t insize,
                         const LodePNGDecompressSettings* settings);
unsigned lodepng_zlib_decompress(unsigned char** out, size_t* outsize,
                                 const unsigned char* in, size_t insize,
                                 const LodePNGDecompressSettings* settings);
unsigned lodepng_zlib_compress(unsigned char** out, size_t* outsize,
                               const unsigned char* in, size_t insize,
                               const LodePNGCompressSettings* settings);
unsigned lodepng_huffman_code_lengths(unsigned* lengths, const unsigned* frequencies,
                                      size_t numcodes, unsigned maxbitlen);
unsigned lodepng_deflate(unsigned char** out, size_t* outsize,
                         const unsigned char* in, size_t insize,
                         const LodePNGCompressSettings* settings);

unsigned lodepng_load_file(unsigned char** out, size_t* outsize, const char* filename);
unsigned lodepng_save_file(const unsigned char* buffer, size_t buffersize, const char* filename);
	cdefcoeus_auxBindingsffirequire       % 'Coeus 	ffi lib   ]==])
Coeus:AddVFSFile('Bindings.LuaJIT', [==[LJ �Nlocal Coeus = ...
local ffi = require("ffi")
local lib = ffi.C

--lua.h
ffi.cdef([[
enum {
	LUA_REGISTRYINDEX = (-10000),
	LUA_ENVIRONINDEX = (-10001),
	LUA_GLOBALSINDEX = (-10002),

	LUA_YIELD = 1,
	LUA_ERRRUN = 2,
	LUA_ERRSYNTAX = 3,
	LUA_ERRMEM = 4,
	LUA_ERRERR = 5,

	LUA_TNONE = (-1),

	LUA_TNIL = 0,
	LUA_TBOOLEAN = 1,
	LUA_TLIGHTUSERDATA = 2,
	LUA_TNUMBER = 3,
	LUA_TSTRING = 4,
	LUA_TTABLE = 5,
	LUA_TFUNCTION = 6,
	LUA_TUSERDATA = 7,
	LUA_TTHREAD = 8,

	LUA_HOOKCALL = 0,
	LUA_HOOKRET = 1,
	LUA_HOOKLINE = 2,
	LUA_HOOKCOUNT = 3,
	LUA_HOOKTAILRET = 4,

	LUA_GCSTOP = 0,
	LUA_GCRESTART = 1,
	LUA_GCCOLLECT = 2,
	LUA_GCCOUNT = 3,
	LUA_GCCOUNTB = 4,
	LUA_GCSTEP = 5,
	LUA_GCSETPAUSE = 6,
	LUA_GCSETSTEPMUL = 7,

	LUA_MINSTACK = 20,

	LUA_MULTRET = (-1)
};

typedef struct lua_State lua_State;
typedef int (*lua_CFunction) (lua_State *L);

typedef const char * (*lua_Reader) (lua_State *L, void *ud, size_t *sz);
typedef int (*lua_Writer) (lua_State *L, const void* p, size_t sz, void* ud);

typedef void * (*lua_Alloc) (void *ud, void *ptr, size_t osize, size_t nsize);

typedef double lua_Number;

typedef ptrdiff_t lua_Integer;

lua_State *(lua_newstate) (lua_Alloc f, void *ud);
void       (lua_close) (lua_State *L);
lua_State *(lua_newthread) (lua_State *L);

lua_CFunction (lua_atpanic) (lua_State *L, lua_CFunction panicf);

int   (lua_gettop) (lua_State *L);
void  (lua_settop) (lua_State *L, int idx);
void  (lua_pushvalue) (lua_State *L, int idx);
void  (lua_remove) (lua_State *L, int idx);
void  (lua_insert) (lua_State *L, int idx);
void  (lua_replace) (lua_State *L, int idx);
int   (lua_checkstack) (lua_State *L, int sz);

void  (lua_xmove) (lua_State *from, lua_State *to, int n);

int             (lua_isnumber) (lua_State *L, int idx);
int             (lua_isstring) (lua_State *L, int idx);
int             (lua_iscfunction) (lua_State *L, int idx);
int             (lua_isuserdata) (lua_State *L, int idx);
int             (lua_type) (lua_State *L, int idx);
const char     *(lua_typename) (lua_State *L, int tp);

int            (lua_equal) (lua_State *L, int idx1, int idx2);
int            (lua_rawequal) (lua_State *L, int idx1, int idx2);
int            (lua_lessthan) (lua_State *L, int idx1, int idx2);

lua_Number      (lua_tonumber) (lua_State *L, int idx);
lua_Integer     (lua_tointeger) (lua_State *L, int idx);
int             (lua_toboolean) (lua_State *L, int idx);
const char     *(lua_tolstring) (lua_State *L, int idx, size_t *len);
size_t          (lua_objlen) (lua_State *L, int idx);
lua_CFunction   (lua_tocfunction) (lua_State *L, int idx);
void	       *(lua_touserdata) (lua_State *L, int idx);
lua_State      *(lua_tothread) (lua_State *L, int idx);
const void     *(lua_topointer) (lua_State *L, int idx);

void  (lua_pushnil) (lua_State *L);
void  (lua_pushnumber) (lua_State *L, lua_Number n);
void  (lua_pushinteger) (lua_State *L, lua_Integer n);
void  (lua_pushlstring) (lua_State *L, const char *s, size_t l);
void  (lua_pushstring) (lua_State *L, const char *s);
const char *(lua_pushvfstring) (lua_State *L, const char *fmt,
                                                      va_list argp);
const char *(lua_pushfstring) (lua_State *L, const char *fmt, ...);
void  (lua_pushcclosure) (lua_State *L, lua_CFunction fn, int n);
void  (lua_pushboolean) (lua_State *L, int b);
void  (lua_pushlightuserdata) (lua_State *L, void *p);
int   (lua_pushthread) (lua_State *L);

void  (lua_gettable) (lua_State *L, int idx);
void  (lua_getfield) (lua_State *L, int idx, const char *k);
void  (lua_rawget) (lua_State *L, int idx);
void  (lua_rawgeti) (lua_State *L, int idx, int n);
void  (lua_createtable) (lua_State *L, int narr, int nrec);
void *(lua_newuserdata) (lua_State *L, size_t sz);
int   (lua_getmetatable) (lua_State *L, int objindex);
void  (lua_getfenv) (lua_State *L, int idx);

void  (lua_settable) (lua_State *L, int idx);
void  (lua_setfield) (lua_State *L, int idx, const char *k);
void  (lua_rawset) (lua_State *L, int idx);
void  (lua_rawseti) (lua_State *L, int idx, int n);
int   (lua_setmetatable) (lua_State *L, int objindex);
int   (lua_setfenv) (lua_State *L, int idx);

void  (lua_call) (lua_State *L, int nargs, int nresults);
int   (lua_pcall) (lua_State *L, int nargs, int nresults, int errfunc);
int   (lua_cpcall) (lua_State *L, lua_CFunction func, void *ud);
int   (lua_load) (lua_State *L, lua_Reader reader, void *dt,
                                        const char *chunkname);

int (lua_dump) (lua_State *L, lua_Writer writer, void *data);

int  (lua_yield) (lua_State *L, int nresults);
int  (lua_resume) (lua_State *L, int narg);
int  (lua_status) (lua_State *L);

int (lua_gc) (lua_State *L, int what, int data);

int   (lua_error) (lua_State *L);
int   (lua_next) (lua_State *L, int idx);
void  (lua_concat) (lua_State *L, int n);
lua_Alloc (lua_getallocf) (lua_State *L, void **ud);
void lua_setallocf (lua_State *L, lua_Alloc f, void *ud);

void lua_setlevel	(lua_State *from, lua_State *to);

typedef struct lua_Debug lua_Debug;  /* activation record */

/* Functions to be called by the debuger in specific events */
typedef void (*lua_Hook) (lua_State *L, lua_Debug *ar);


int lua_getstack (lua_State *L, int level, lua_Debug *ar);
int lua_getinfo (lua_State *L, const char *what, lua_Debug *ar);
const char *lua_getlocal (lua_State *L, const lua_Debug *ar, int n);
const char *lua_setlocal (lua_State *L, const lua_Debug *ar, int n);
const char *lua_getupvalue (lua_State *L, int funcindex, int n);
const char *lua_setupvalue (lua_State *L, int funcindex, int n);
int lua_sethook (lua_State *L, lua_Hook func, int mask, int count);
lua_Hook lua_gethook (lua_State *L);
int lua_gethookmask (lua_State *L);
int lua_gethookcount (lua_State *L);

void *lua_upvalueid (lua_State *L, int idx, int n);
void lua_upvaluejoin (lua_State *L, int idx1, int n1, int idx2, int n2);
int lua_loadx (lua_State *L, lua_Reader reader, void *dt,
		       const char *chunkname, const char *mode);


struct lua_Debug {
  int event;
  const char *name;
  const char *namewhat;
  const char *what;
  const char *source;
  int currentline;
  int nups;
  int linedefined;
  int lastlinedefined;
  char short_src[60];

  int i_ci;
};
]])

--lauxlib.h
ffi.cdef([[
typedef struct luaL_Reg {
  const char *name;
  lua_CFunction func;
} luaL_Reg;

void (luaL_openlib) (lua_State *L, const char *libname,
                                const luaL_Reg *l, int nup);
void (luaL_register) (lua_State *L, const char *libname,
                                const luaL_Reg *l);
int (luaL_getmetafield) (lua_State *L, int obj, const char *e);
int (luaL_callmeta) (lua_State *L, int obj, const char *e);
int (luaL_typerror) (lua_State *L, int narg, const char *tname);
int (luaL_argerror) (lua_State *L, int numarg, const char *extramsg);
const char *(luaL_checklstring) (lua_State *L, int numArg,
                                                          size_t *l);
const char *(luaL_optlstring) (lua_State *L, int numArg,
                                          const char *def, size_t *l);
lua_Number (luaL_checknumber) (lua_State *L, int numArg);
lua_Number (luaL_optnumber) (lua_State *L, int nArg, lua_Number def);

lua_Integer (luaL_checkinteger) (lua_State *L, int numArg);
lua_Integer (luaL_optinteger) (lua_State *L, int nArg,
                                          lua_Integer def);

void (luaL_checkstack) (lua_State *L, int sz, const char *msg);
void (luaL_checktype) (lua_State *L, int narg, int t);
void (luaL_checkany) (lua_State *L, int narg);

int   (luaL_newmetatable) (lua_State *L, const char *tname);
void *(luaL_checkudata) (lua_State *L, int ud, const char *tname);

void (luaL_where) (lua_State *L, int lvl);
int (luaL_error) (lua_State *L, const char *fmt, ...);

int (luaL_checkoption) (lua_State *L, int narg, const char *def,
                                   const char *const lst[]);

int (luaL_ref) (lua_State *L, int t);
void (luaL_unref) (lua_State *L, int t, int ref);

int (luaL_loadfile) (lua_State *L, const char *filename);
int (luaL_loadbuffer) (lua_State *L, const char *buff, size_t sz,
                                  const char *name);
int (luaL_loadstring) (lua_State *L, const char *s);

lua_State *(luaL_newstate) (void);


const char *(luaL_gsub) (lua_State *L, const char *s, const char *p,
                                                  const char *r);

const char *(luaL_findtable) (lua_State *L, int idx,
                                         const char *fname, int szhint);

int luaL_fileresult(lua_State *L, int stat, const char *fname);
int luaL_execresult(lua_State *L, int stat);
int (luaL_loadfilex) (lua_State *L, const char *filename,
				 const char *mode);
int (luaL_loadbufferx) (lua_State *L, const char *buff, size_t sz,
				   const char *name, const char *mode);
void luaL_traceback (lua_State *L, lua_State *L1, const char *msg,
				int level);

typedef struct luaL_Buffer {
  char *p;			/* current position in buffer */
  int lvl;  /* number of strings in the stack (level) */
  lua_State *L;
  char buffer[8192]; //LUAL_BUFFERSIZE
} luaL_Buffer;

void (luaL_buffinit) (lua_State *L, luaL_Buffer *B);
char *(luaL_prepbuffer) (luaL_Buffer *B);
void (luaL_addlstring) (luaL_Buffer *B, const char *s, size_t l);
void (luaL_addstring) (luaL_Buffer *B, const char *s);
void (luaL_addvalue) (luaL_Buffer *B);
void (luaL_pushresult) (luaL_Buffer *B);
]])

--lualib.h
ffi.cdef([[
int luaopen_base(lua_State *L);
int luaopen_math(lua_State *L);
int luaopen_string(lua_State *L);
int luaopen_table(lua_State *L);
int luaopen_io(lua_State *L);
int luaopen_os(lua_State *L);
int luaopen_package(lua_State *L);
int luaopen_debug(lua_State *L);
int luaopen_bit(lua_State *L);
int luaopen_jit(lua_State *L);
int luaopen_ffi(lua_State *L);

void luaL_openlibs(lua_State *L);
]])

return lib�L   3 �C  4  % >77% >7% >7% >H �int luaopen_base(lua_State *L);
int luaopen_math(lua_State *L);
int luaopen_string(lua_State *L);
int luaopen_table(lua_State *L);
int luaopen_io(lua_State *L);
int luaopen_os(lua_State *L);
int luaopen_package(lua_State *L);
int luaopen_debug(lua_State *L);
int luaopen_bit(lua_State *L);
int luaopen_jit(lua_State *L);
int luaopen_ffi(lua_State *L);

void luaL_openlibs(lua_State *L);
�typedef struct luaL_Reg {
  const char *name;
  lua_CFunction func;
} luaL_Reg;

void (luaL_openlib) (lua_State *L, const char *libname,
                                const luaL_Reg *l, int nup);
void (luaL_register) (lua_State *L, const char *libname,
                                const luaL_Reg *l);
int (luaL_getmetafield) (lua_State *L, int obj, const char *e);
int (luaL_callmeta) (lua_State *L, int obj, const char *e);
int (luaL_typerror) (lua_State *L, int narg, const char *tname);
int (luaL_argerror) (lua_State *L, int numarg, const char *extramsg);
const char *(luaL_checklstring) (lua_State *L, int numArg,
                                                          size_t *l);
const char *(luaL_optlstring) (lua_State *L, int numArg,
                                          const char *def, size_t *l);
lua_Number (luaL_checknumber) (lua_State *L, int numArg);
lua_Number (luaL_optnumber) (lua_State *L, int nArg, lua_Number def);

lua_Integer (luaL_checkinteger) (lua_State *L, int numArg);
lua_Integer (luaL_optinteger) (lua_State *L, int nArg,
                                          lua_Integer def);

void (luaL_checkstack) (lua_State *L, int sz, const char *msg);
void (luaL_checktype) (lua_State *L, int narg, int t);
void (luaL_checkany) (lua_State *L, int narg);

int   (luaL_newmetatable) (lua_State *L, const char *tname);
void *(luaL_checkudata) (lua_State *L, int ud, const char *tname);

void (luaL_where) (lua_State *L, int lvl);
int (luaL_error) (lua_State *L, const char *fmt, ...);

int (luaL_checkoption) (lua_State *L, int narg, const char *def,
                                   const char *const lst[]);

int (luaL_ref) (lua_State *L, int t);
void (luaL_unref) (lua_State *L, int t, int ref);

int (luaL_loadfile) (lua_State *L, const char *filename);
int (luaL_loadbuffer) (lua_State *L, const char *buff, size_t sz,
                                  const char *name);
int (luaL_loadstring) (lua_State *L, const char *s);

lua_State *(luaL_newstate) (void);


const char *(luaL_gsub) (lua_State *L, const char *s, const char *p,
                                                  const char *r);

const char *(luaL_findtable) (lua_State *L, int idx,
                                         const char *fname, int szhint);

int luaL_fileresult(lua_State *L, int stat, const char *fname);
int luaL_execresult(lua_State *L, int stat);
int (luaL_loadfilex) (lua_State *L, const char *filename,
				 const char *mode);
int (luaL_loadbufferx) (lua_State *L, const char *buff, size_t sz,
				   const char *name, const char *mode);
void luaL_traceback (lua_State *L, lua_State *L1, const char *msg,
				int level);

typedef struct luaL_Buffer {
  char *p;			/* current position in buffer */
  int lvl;  /* number of strings in the stack (level) */
  lua_State *L;
  char buffer[8192]; //LUAL_BUFFERSIZE
} luaL_Buffer;

void (luaL_buffinit) (lua_State *L, luaL_Buffer *B);
char *(luaL_prepbuffer) (luaL_Buffer *B);
void (luaL_addlstring) (luaL_Buffer *B, const char *s, size_t l);
void (luaL_addstring) (luaL_Buffer *B, const char *s);
void (luaL_addvalue) (luaL_Buffer *B);
void (luaL_pushresult) (luaL_Buffer *B);
�/enum {
	LUA_REGISTRYINDEX = (-10000),
	LUA_ENVIRONINDEX = (-10001),
	LUA_GLOBALSINDEX = (-10002),

	LUA_YIELD = 1,
	LUA_ERRRUN = 2,
	LUA_ERRSYNTAX = 3,
	LUA_ERRMEM = 4,
	LUA_ERRERR = 5,

	LUA_TNONE = (-1),

	LUA_TNIL = 0,
	LUA_TBOOLEAN = 1,
	LUA_TLIGHTUSERDATA = 2,
	LUA_TNUMBER = 3,
	LUA_TSTRING = 4,
	LUA_TTABLE = 5,
	LUA_TFUNCTION = 6,
	LUA_TUSERDATA = 7,
	LUA_TTHREAD = 8,

	LUA_HOOKCALL = 0,
	LUA_HOOKRET = 1,
	LUA_HOOKLINE = 2,
	LUA_HOOKCOUNT = 3,
	LUA_HOOKTAILRET = 4,

	LUA_GCSTOP = 0,
	LUA_GCRESTART = 1,
	LUA_GCCOLLECT = 2,
	LUA_GCCOUNT = 3,
	LUA_GCCOUNTB = 4,
	LUA_GCSTEP = 5,
	LUA_GCSETPAUSE = 6,
	LUA_GCSETSTEPMUL = 7,

	LUA_MINSTACK = 20,

	LUA_MULTRET = (-1)
};

typedef struct lua_State lua_State;
typedef int (*lua_CFunction) (lua_State *L);

typedef const char * (*lua_Reader) (lua_State *L, void *ud, size_t *sz);
typedef int (*lua_Writer) (lua_State *L, const void* p, size_t sz, void* ud);

typedef void * (*lua_Alloc) (void *ud, void *ptr, size_t osize, size_t nsize);

typedef double lua_Number;

typedef ptrdiff_t lua_Integer;

lua_State *(lua_newstate) (lua_Alloc f, void *ud);
void       (lua_close) (lua_State *L);
lua_State *(lua_newthread) (lua_State *L);

lua_CFunction (lua_atpanic) (lua_State *L, lua_CFunction panicf);

int   (lua_gettop) (lua_State *L);
void  (lua_settop) (lua_State *L, int idx);
void  (lua_pushvalue) (lua_State *L, int idx);
void  (lua_remove) (lua_State *L, int idx);
void  (lua_insert) (lua_State *L, int idx);
void  (lua_replace) (lua_State *L, int idx);
int   (lua_checkstack) (lua_State *L, int sz);

void  (lua_xmove) (lua_State *from, lua_State *to, int n);

int             (lua_isnumber) (lua_State *L, int idx);
int             (lua_isstring) (lua_State *L, int idx);
int             (lua_iscfunction) (lua_State *L, int idx);
int             (lua_isuserdata) (lua_State *L, int idx);
int             (lua_type) (lua_State *L, int idx);
const char     *(lua_typename) (lua_State *L, int tp);

int            (lua_equal) (lua_State *L, int idx1, int idx2);
int            (lua_rawequal) (lua_State *L, int idx1, int idx2);
int            (lua_lessthan) (lua_State *L, int idx1, int idx2);

lua_Number      (lua_tonumber) (lua_State *L, int idx);
lua_Integer     (lua_tointeger) (lua_State *L, int idx);
int             (lua_toboolean) (lua_State *L, int idx);
const char     *(lua_tolstring) (lua_State *L, int idx, size_t *len);
size_t          (lua_objlen) (lua_State *L, int idx);
lua_CFunction   (lua_tocfunction) (lua_State *L, int idx);
void	       *(lua_touserdata) (lua_State *L, int idx);
lua_State      *(lua_tothread) (lua_State *L, int idx);
const void     *(lua_topointer) (lua_State *L, int idx);

void  (lua_pushnil) (lua_State *L);
void  (lua_pushnumber) (lua_State *L, lua_Number n);
void  (lua_pushinteger) (lua_State *L, lua_Integer n);
void  (lua_pushlstring) (lua_State *L, const char *s, size_t l);
void  (lua_pushstring) (lua_State *L, const char *s);
const char *(lua_pushvfstring) (lua_State *L, const char *fmt,
                                                      va_list argp);
const char *(lua_pushfstring) (lua_State *L, const char *fmt, ...);
void  (lua_pushcclosure) (lua_State *L, lua_CFunction fn, int n);
void  (lua_pushboolean) (lua_State *L, int b);
void  (lua_pushlightuserdata) (lua_State *L, void *p);
int   (lua_pushthread) (lua_State *L);

void  (lua_gettable) (lua_State *L, int idx);
void  (lua_getfield) (lua_State *L, int idx, const char *k);
void  (lua_rawget) (lua_State *L, int idx);
void  (lua_rawgeti) (lua_State *L, int idx, int n);
void  (lua_createtable) (lua_State *L, int narr, int nrec);
void *(lua_newuserdata) (lua_State *L, size_t sz);
int   (lua_getmetatable) (lua_State *L, int objindex);
void  (lua_getfenv) (lua_State *L, int idx);

void  (lua_settable) (lua_State *L, int idx);
void  (lua_setfield) (lua_State *L, int idx, const char *k);
void  (lua_rawset) (lua_State *L, int idx);
void  (lua_rawseti) (lua_State *L, int idx, int n);
int   (lua_setmetatable) (lua_State *L, int objindex);
int   (lua_setfenv) (lua_State *L, int idx);

void  (lua_call) (lua_State *L, int nargs, int nresults);
int   (lua_pcall) (lua_State *L, int nargs, int nresults, int errfunc);
int   (lua_cpcall) (lua_State *L, lua_CFunction func, void *ud);
int   (lua_load) (lua_State *L, lua_Reader reader, void *dt,
                                        const char *chunkname);

int (lua_dump) (lua_State *L, lua_Writer writer, void *data);

int  (lua_yield) (lua_State *L, int nresults);
int  (lua_resume) (lua_State *L, int narg);
int  (lua_status) (lua_State *L);

int (lua_gc) (lua_State *L, int what, int data);

int   (lua_error) (lua_State *L);
int   (lua_next) (lua_State *L, int idx);
void  (lua_concat) (lua_State *L, int n);
lua_Alloc (lua_getallocf) (lua_State *L, void **ud);
void lua_setallocf (lua_State *L, lua_Alloc f, void *ud);

void lua_setlevel	(lua_State *from, lua_State *to);

typedef struct lua_Debug lua_Debug;  /* activation record */

/* Functions to be called by the debuger in specific events */
typedef void (*lua_Hook) (lua_State *L, lua_Debug *ar);


int lua_getstack (lua_State *L, int level, lua_Debug *ar);
int lua_getinfo (lua_State *L, const char *what, lua_Debug *ar);
const char *lua_getlocal (lua_State *L, const lua_Debug *ar, int n);
const char *lua_setlocal (lua_State *L, const lua_Debug *ar, int n);
const char *lua_getupvalue (lua_State *L, int funcindex, int n);
const char *lua_setupvalue (lua_State *L, int funcindex, int n);
int lua_sethook (lua_State *L, lua_Hook func, int mask, int count);
lua_Hook lua_gethook (lua_State *L);
int lua_gethookmask (lua_State *L);
int lua_gethookcount (lua_State *L);

void *lua_upvalueid (lua_State *L, int idx, int n);
void lua_upvaluejoin (lua_State *L, int idx1, int n1, int idx2, int n2);
int lua_loadx (lua_State *L, lua_Reader reader, void *dt,
		       const char *chunkname, const char *mode);


struct lua_Debug {
  int event;
  const char *name;
  const char *namewhat;
  const char *what;
  const char *source;
  int currentline;
  int nups;
  int linedefined;
  int lastlinedefined;
  char short_src[60];

  int i_ci;
};
	cdefCffirequire      �  � � Coeus ffi lib 
  ]==])
Coeus:AddVFSFile('Bindings.luajit_thread_aux', [==[LJ �local Coeus = ...
local ffi = require("ffi")
local lib = Coeus.Bindings.coeus_aux

ffi.cdef([[
	void ljta_run(void* L);
]])

return lib�   
 	C  4  % >7 77% >H 	void ljta_run(void* L);
	cdefcoeus_auxBindingsffirequire	Coeus 	ffi lib   ]==])
Coeus:AddVFSFile('Bindings.OpenAL', [==[LJ ��local ffi = require("ffi")
local oal = (ffi.os == "Windows") and ffi.load("lib/win32/OpenAL.dll") or ffi.C

--alc.h
ffi.cdef([[
enum {
	ALC_INVALID = 0, //Deprecated

	ALC_VERSION_0_1 = 1,

	ALC_FALSE = 0,
	ALC_TRUE = 1,
	ALC_FREQUENCY = 0x1007,
	ALC_REFRESH = 0x1008,
	ALC_SYNC = 0x1009,

	ALC_MONO_SOURCES = 0x1010,
	ALC_STEREO_SOURCES = 0x1011,

	ALC_NO_ERROR = 0,
	ALC_INVALID_DEVICE = 0xA001,
	ALC_INVALID_CONTEXT = 0xA002,
	ALC_INVALID_ENUM = 0xA003,
	ALC_INVALID_VALUE = 0xA004,
	ALC_OUT_OF_MEMORY = 0xA005,

	ALC_MAJOR_VERSION = 0x1000,
	ALC_MINOR_VERSION = 0x1001,

	ALC_ATTRIBUTES_SIZE = 0x1002,
	ALC_ALL_ATTRIBUTES = 0x1003,

	ALC_DEFAULT_DEVICE_SPECIFIER = 0x1004,
	ALC_DEVICE_SPECIFIER = 0x1005,
	ALC_EXTENSIONS = 0x1006,

	ALC_EXT_CAPTURE = 1,
	ALC_CAPTURE_DEVICE_SPECIFIER = 0x310,
	ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER = 0x311,
	ALC_CAPTURE_SAMPLES = 0x312,

	ALC_DEFAULT_ALL_DEVICES_SPECIFIER = 0x1012,
	ALC_ALL_DEVICES_SPECIFIER = 0x1013
};

typedef struct ALCdevice_struct ALCdevice;
typedef struct ALCcontext_struct ALCcontext;

typedef char ALCboolean;
typedef char ALCchar;
typedef signed char ALCbyte;
typedef unsigned char ALCubyte;
typedef short ALCshort;
typedef unsigned short ALCushort;
typedef int ALCint;
typedef unsigned int ALCuint;
typedef int ALCsizei;
typedef int ALCenum;
typedef float ALCfloat;
typedef double ALCdouble;
typedef void ALCvoid;

ALCcontext* alcCreateContext(ALCdevice *device, const ALCint* attrlist);
ALCboolean  alcMakeContextCurrent(ALCcontext *context);
void        alcProcessContext(ALCcontext *context);
void        alcSuspendContext(ALCcontext *context);
void        alcDestroyContext(ALCcontext *context);
ALCcontext* alcGetCurrentContext(void);
ALCdevice*  alcGetContextsDevice(ALCcontext *context);

ALCdevice* alcOpenDevice(const ALCchar *devicename);
ALCboolean alcCloseDevice(ALCdevice *device);

ALCenum alcGetError(ALCdevice *device);
ALCboolean alcIsExtensionPresent(ALCdevice *device, const ALCchar *extname);
void*      alcGetProcAddress(ALCdevice *device, const ALCchar *funcname);
ALCenum    alcGetEnumValue(ALCdevice *device, const ALCchar *enumname);

const ALCchar* alcGetString(ALCdevice *device, ALCenum param);
void           alcGetIntegerv(ALCdevice *device, ALCenum param, ALCsizei size, ALCint *values);

ALCdevice* alcCaptureOpenDevice(const ALCchar *devicename, ALCuint frequency, ALCenum format, ALCsizei buffersize);
ALCboolean alcCaptureCloseDevice(ALCdevice *device);
void       alcCaptureStart(ALCdevice *device);
void       alcCaptureStop(ALCdevice *device);
void       alcCaptureSamples(ALCdevice *device, ALCvoid *buffer, ALCsizei samples);

typedef ALCcontext*    (*LPALCCREATECONTEXT)(ALCdevice *device, const ALCint *attrlist);
typedef ALCboolean     (*LPALCMAKECONTEXTCURRENT)(ALCcontext *context);
typedef void           (*LPALCPROCESSCONTEXT)(ALCcontext *context);
typedef void           (*LPALCSUSPENDCONTEXT)(ALCcontext *context);
typedef void           (*LPALCDESTROYCONTEXT)(ALCcontext *context);
typedef ALCcontext*    (*LPALCGETCURRENTCONTEXT)(void);
typedef ALCdevice*     (*LPALCGETCONTEXTSDEVICE)(ALCcontext *context);
typedef ALCdevice*     (*LPALCOPENDEVICE)(const ALCchar *devicename);
typedef ALCboolean     (*LPALCCLOSEDEVICE)(ALCdevice *device);
typedef ALCenum        (*LPALCGETERROR)(ALCdevice *device);
typedef ALCboolean     (*LPALCISEXTENSIONPRESENT)(ALCdevice *device, const ALCchar *extname);
typedef void*          (*LPALCGETPROCADDRESS)(ALCdevice *device, const ALCchar *funcname);
typedef ALCenum        (*LPALCGETENUMVALUE)(ALCdevice *device, const ALCchar *enumname);
typedef const ALCchar* (*LPALCGETSTRING)(ALCdevice *device, ALCenum param);
typedef void           (*LPALCGETINTEGERV)(ALCdevice *device, ALCenum param, ALCsizei size, ALCint *values);
typedef ALCdevice*     (*LPALCCAPTUREOPENDEVICE)(const ALCchar *devicename, ALCuint frequency, ALCenum format, ALCsizei buffersize);
typedef ALCboolean     (*LPALCCAPTURECLOSEDEVICE)(ALCdevice *device);
typedef void           (*LPALCCAPTURESTART)(ALCdevice *device);
typedef void           (*LPALCCAPTURESTOP)(ALCdevice *device);
typedef void           (*LPALCCAPTURESAMPLES)(ALCdevice *device, ALCvoid *buffer, ALCsizei samples);
]])

--al.h
ffi.cdef([[
enum {
	AL_NONE = 0,
	AL_FALSE = 0,
	AL_TRUE = 1,

	AL_SOURCE_RELATIVE = 0x202,
	AL_CONE_INNER_ANGLE = 0x1001,
	AL_CONE_OUTER_ANGLE = 0x1002,
	AL_PITCH = 0x1003,
	AL_POSITION = 0x1004,
	AL_DIRECTION = 0x1005,
	AL_VELOCITY = 0x1006,
	AL_LOOPING = 0x1007,
	AL_BUFFER = 0x1009,
	AL_GAIN = 0x100A,
	AL_MIN_GAIN = 0x100D,
	AL_MAX_GAIN = 0x100E,
	AL_ORIENTATION = 0x100F,
	AL_SOURCE_STATE = 0x1010,

	AL_INITIAL = 0x1011,
	AL_PLAYING = 0x1012,
	AL_PAUSED = 0x1013,
	AL_STOPPED = 0x1014,

	AL_BUFFERS_QUEUED = 0x1015,
	AL_BUFFERS_PROCESSED = 0x1016,

	AL_REFERENCE_DISTANCE = 0x1020,
	AL_ROLLOFF_FACTOR = 0x1021,
	AL_CONE_OUTER_GAIN = 0x1022,
	AL_MAX_DISTANCE = 0x1023,

	AL_SEC_OFFSET = 0x1024,
	AL_SAMPLE_OFFSET = 0x1025,
	AL_BYTE_OFFSET = 0x1026,

	AL_SOURCE_TYPE = 0x1027,

	AL_STATIC = 0x1028,
	AL_STREAMING = 0x1029,
	AL_UNDETERMINED = 0x1030,

	AL_FORMAT_MONO8 = 0x1100,
	AL_FORMAT_MONO16 = 0x1101,
	AL_FORMAT_STEREO8 = 0x1102,
	AL_FORMAT_STEREO16 = 0x1103,

	AL_FREQUENCY = 0x2001,
	AL_BITS = 0x2002,
	AL_CHANNELS = 0x2003,
	AL_SIZE = 0x2004,

	AL_UNUSED = 0x2010,
	AL_PENDING = 0x2011,
	AL_PROCESSED = 0x2012,

	AL_NO_ERROR = 0,
	AL_INVALID_NAME = 0xA001,
	AL_INVALID_ENUM = 0xA002,
	AL_INVALID_VALUE = 0xA003,
	AL_INVALID_OPERATION = 0xA004,
	AL_OUT_OF_MEMORY = 0xA005,

	AL_VENDOR = 0xB001,
	AL_VERSION = 0xB002,
	AL_RENDERER = 0xB003,
	AL_EXTENSIONS = 0xB004,

	AL_DOPPLER_FACTOR = 0xC000,
	AL_DOPPLER_VELOCITY = 0xC001,
	AL_SPEED_OF_SOUND = 0xC003,
	AL_DISTANCE_MODEL = 0xD000,

	AL_INVERSE_DISTANCE = 0xD001,
	AL_INVERSE_DISTANCE_CLAMPED = 0xD002,
	AL_LINEAR_DISTANCE = 0xD003,
	AL_LINEAR_DISTANCE_CLAMPED = 0xD004,
	AL_EXPONENT_DISTANCE = 0xD005,
	AL_EXPONENT_DISTANCE_CLAMPED = 0xD006
};

typedef char ALboolean;
typedef char ALchar;
typedef signed char ALbyte;
typedef unsigned char ALubyte;
typedef short ALshort;
typedef unsigned short ALushort;
typedef int ALint;
typedef unsigned int ALuint;
typedef int ALsizei;
typedef int ALenum;
typedef float ALfloat;
typedef double ALdouble;
typedef void ALvoid;

void alDopplerFactor(ALfloat value);
void alDopplerVelocity(ALfloat value);
void alSpeedOfSound(ALfloat value);
void alDistanceModel(ALenum distanceModel);

void alEnable(ALenum capability);
void alDisable(ALenum capability);
ALboolean alIsEnabled(ALenum capability);

const ALchar* alGetString(ALenum param);
void alGetBooleanv(ALenum param, ALboolean *values);
void alGetIntegerv(ALenum param, ALint *values);
void alGetFloatv(ALenum param, ALfloat *values);
void alGetDoublev(ALenum param, ALdouble *values);
ALboolean alGetBoolean(ALenum param);
ALint alGetInteger(ALenum param);
ALfloat alGetFloat(ALenum param);
ALdouble alGetDouble(ALenum param);

ALenum alGetError(void);

ALboolean alIsExtensionPresent(const ALchar *extname);
void* alGetProcAddress(const ALchar *fname);
ALenum alGetEnumValue(const ALchar *ename);

void alListenerf(ALenum param, ALfloat value);
void alListener3f(ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
void alListenerfv(ALenum param, const ALfloat *values);
void alListeneri(ALenum param, ALint value);
void alListener3i(ALenum param, ALint value1, ALint value2, ALint value3);
void alListeneriv(ALenum param, const ALint *values);

void alGetListenerf(ALenum param, ALfloat *value);
void alGetListener3f(ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
void alGetListenerfv(ALenum param, ALfloat *values);
void alGetListeneri(ALenum param, ALint *value);
void alGetListener3i(ALenum param, ALint *value1, ALint *value2, ALint *value3);
void alGetListeneriv(ALenum param, ALint *values);

void alGenSources(ALsizei n, ALuint *sources);
void alDeleteSources(ALsizei n, const ALuint *sources);
ALboolean alIsSource(ALuint source);

void alSourcef(ALuint source, ALenum param, ALfloat value);
void alSource3f(ALuint source, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
void alSourcefv(ALuint source, ALenum param, const ALfloat *values);
void alSourcei(ALuint source, ALenum param, ALint value);
void alSource3i(ALuint source, ALenum param, ALint value1, ALint value2, ALint value3);
void alSourceiv(ALuint source, ALenum param, const ALint *values);

void alGetSourcef(ALuint source, ALenum param, ALfloat *value);
void alGetSource3f(ALuint source, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
void alGetSourcefv(ALuint source, ALenum param, ALfloat *values);
void alGetSourcei(ALuint source,  ALenum param, ALint *value);
void alGetSource3i(ALuint source, ALenum param, ALint *value1, ALint *value2, ALint *value3);
void alGetSourceiv(ALuint source,  ALenum param, ALint *values);

void alSourcePlayv(ALsizei n, const ALuint *sources);
void alSourceStopv(ALsizei n, const ALuint *sources);
void alSourceRewindv(ALsizei n, const ALuint *sources);
void alSourcePausev(ALsizei n, const ALuint *sources);

void alSourcePlay(ALuint source);
void alSourceStop(ALuint source);
void alSourceRewind(ALuint source);
void alSourcePause(ALuint source);

void alSourceQueueBuffers(ALuint source, ALsizei nb, const ALuint *buffers);
void alSourceUnqueueBuffers(ALuint source, ALsizei nb, ALuint *buffers);

void alGenBuffers(ALsizei n, ALuint *buffers);
void alDeleteBuffers(ALsizei n, const ALuint *buffers);
ALboolean alIsBuffer(ALuint buffer);

void alBufferData(ALuint buffer, ALenum format, const ALvoid *data, ALsizei size, ALsizei freq);

void alBufferf(ALuint buffer, ALenum param, ALfloat value);
void alBuffer3f(ALuint buffer, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
void alBufferfv(ALuint buffer, ALenum param, const ALfloat *values);
void alBufferi(ALuint buffer, ALenum param, ALint value);
void alBuffer3i(ALuint buffer, ALenum param, ALint value1, ALint value2, ALint value3);
void alBufferiv(ALuint buffer, ALenum param, const ALint *values);

void alGetBufferf(ALuint buffer, ALenum param, ALfloat *value);
void alGetBuffer3f(ALuint buffer, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
void alGetBufferfv(ALuint buffer, ALenum param, ALfloat *values);
void alGetBufferi(ALuint buffer, ALenum param, ALint *value);
void alGetBuffer3i(ALuint buffer, ALenum param, ALint *value1, ALint *value2, ALint *value3);
void alGetBufferiv(ALuint buffer, ALenum param, ALint *values);

typedef void          (*LPALENABLE)(ALenum capability);
typedef void          (*LPALDISABLE)(ALenum capability);
typedef ALboolean     (*LPALISENABLED)(ALenum capability);
typedef const ALchar* (*LPALGETSTRING)(ALenum param);
typedef void          (*LPALGETBOOLEANV)(ALenum param, ALboolean *values);
typedef void          (*LPALGETINTEGERV)(ALenum param, ALint *values);
typedef void          (*LPALGETFLOATV)(ALenum param, ALfloat *values);
typedef void          (*LPALGETDOUBLEV)(ALenum param, ALdouble *values);
typedef ALboolean     (*LPALGETBOOLEAN)(ALenum param);
typedef ALint         (*LPALGETINTEGER)(ALenum param);
typedef ALfloat       (*LPALGETFLOAT)(ALenum param);
typedef ALdouble      (*LPALGETDOUBLE)(ALenum param);
typedef ALenum        (*LPALGETERROR)(void);
typedef ALboolean     (*LPALISEXTENSIONPRESENT)(const ALchar *extname);
typedef void*         (*LPALGETPROCADDRESS)(const ALchar *fname);
typedef ALenum        (*LPALGETENUMVALUE)(const ALchar *ename);
typedef void          (*LPALLISTENERF)(ALenum param, ALfloat value);
typedef void          (*LPALLISTENER3F)(ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
typedef void          (*LPALLISTENERFV)(ALenum param, const ALfloat *values);
typedef void          (*LPALLISTENERI)(ALenum param, ALint value);
typedef void          (*LPALLISTENER3I)(ALenum param, ALint value1, ALint value2, ALint value3);
typedef void          (*LPALLISTENERIV)(ALenum param, const ALint *values);
typedef void          (*LPALGETLISTENERF)(ALenum param, ALfloat *value);
typedef void          (*LPALGETLISTENER3F)(ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
typedef void          (*LPALGETLISTENERFV)(ALenum param, ALfloat *values);
typedef void          (*LPALGETLISTENERI)(ALenum param, ALint *value);
typedef void          (*LPALGETLISTENER3I)(ALenum param, ALint *value1, ALint *value2, ALint *value3);
typedef void          (*LPALGETLISTENERIV)(ALenum param, ALint *values);
typedef void          (*LPALGENSOURCES)(ALsizei n, ALuint *sources);
typedef void          (*LPALDELETESOURCES)(ALsizei n, const ALuint *sources);
typedef ALboolean     (*LPALISSOURCE)(ALuint source);
typedef void          (*LPALSOURCEF)(ALuint source, ALenum param, ALfloat value);
typedef void          (*LPALSOURCE3F)(ALuint source, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
typedef void          (*LPALSOURCEFV)(ALuint source, ALenum param, const ALfloat *values);
typedef void          (*LPALSOURCEI)(ALuint source, ALenum param, ALint value);
typedef void          (*LPALSOURCE3I)(ALuint source, ALenum param, ALint value1, ALint value2, ALint value3);
typedef void          (*LPALSOURCEIV)(ALuint source, ALenum param, const ALint *values);
typedef void          (*LPALGETSOURCEF)(ALuint source, ALenum param, ALfloat *value);
typedef void          (*LPALGETSOURCE3F)(ALuint source, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
typedef void          (*LPALGETSOURCEFV)(ALuint source, ALenum param, ALfloat *values);
typedef void          (*LPALGETSOURCEI)(ALuint source, ALenum param, ALint *value);
typedef void          (*LPALGETSOURCE3I)(ALuint source, ALenum param, ALint *value1, ALint *value2, ALint *value3);
typedef void          (*LPALGETSOURCEIV)(ALuint source, ALenum param, ALint *values);
typedef void          (*LPALSOURCEPLAYV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCESTOPV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCEREWINDV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCEPAUSEV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCEPLAY)(ALuint source);
typedef void          (*LPALSOURCESTOP)(ALuint source);
typedef void          (*LPALSOURCEREWIND)(ALuint source);
typedef void          (*LPALSOURCEPAUSE)(ALuint source);
typedef void          (*LPALSOURCEQUEUEBUFFERS)(ALuint source, ALsizei nb, const ALuint *buffers);
typedef void          (*LPALSOURCEUNQUEUEBUFFERS)(ALuint source, ALsizei nb, ALuint *buffers);
typedef void          (*LPALGENBUFFERS)(ALsizei n, ALuint *buffers);
typedef void          (*LPALDELETEBUFFERS)(ALsizei n, const ALuint *buffers);
typedef ALboolean     (*LPALISBUFFER)(ALuint buffer);
typedef void          (*LPALBUFFERDATA)(ALuint buffer, ALenum format, const ALvoid *data, ALsizei size, ALsizei freq);
typedef void          (*LPALBUFFERF)(ALuint buffer, ALenum param, ALfloat value);
typedef void          (*LPALBUFFER3F)(ALuint buffer, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
typedef void          (*LPALBUFFERFV)(ALuint buffer, ALenum param, const ALfloat *values);
typedef void          (*LPALBUFFERI)(ALuint buffer, ALenum param, ALint value);
typedef void          (*LPALBUFFER3I)(ALuint buffer, ALenum param, ALint value1, ALint value2, ALint value3);
typedef void          (*LPALBUFFERIV)(ALuint buffer, ALenum param, const ALint *values);
typedef void          (*LPALGETBUFFERF)(ALuint buffer, ALenum param, ALfloat *value);
typedef void          (*LPALGETBUFFER3F)(ALuint buffer, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
typedef void          (*LPALGETBUFFERFV)(ALuint buffer, ALenum param, ALfloat *values);
typedef void          (*LPALGETBUFFERI)(ALuint buffer, ALenum param, ALint *value);
typedef void          (*LPALGETBUFFER3I)(ALuint buffer, ALenum param, ALint *value1, ALint *value2, ALint *value3);
typedef void          (*LPALGETBUFFERIV)(ALuint buffer, ALenum param, ALint *values);
typedef void          (*LPALDOPPLERFACTOR)(ALfloat value);
typedef void          (*LPALDOPPLERVELOCITY)(ALfloat value);
typedef void          (*LPALSPEEDOFSOUND)(ALfloat value);
typedef void          (*LPALDISTANCEMODEL)(ALenum distanceModel);
]])

return oal�  
 3 �4   % > 7  T�7 % >  T�7 7 % >7 %	 >H �]enum {
	AL_NONE = 0,
	AL_FALSE = 0,
	AL_TRUE = 1,

	AL_SOURCE_RELATIVE = 0x202,
	AL_CONE_INNER_ANGLE = 0x1001,
	AL_CONE_OUTER_ANGLE = 0x1002,
	AL_PITCH = 0x1003,
	AL_POSITION = 0x1004,
	AL_DIRECTION = 0x1005,
	AL_VELOCITY = 0x1006,
	AL_LOOPING = 0x1007,
	AL_BUFFER = 0x1009,
	AL_GAIN = 0x100A,
	AL_MIN_GAIN = 0x100D,
	AL_MAX_GAIN = 0x100E,
	AL_ORIENTATION = 0x100F,
	AL_SOURCE_STATE = 0x1010,

	AL_INITIAL = 0x1011,
	AL_PLAYING = 0x1012,
	AL_PAUSED = 0x1013,
	AL_STOPPED = 0x1014,

	AL_BUFFERS_QUEUED = 0x1015,
	AL_BUFFERS_PROCESSED = 0x1016,

	AL_REFERENCE_DISTANCE = 0x1020,
	AL_ROLLOFF_FACTOR = 0x1021,
	AL_CONE_OUTER_GAIN = 0x1022,
	AL_MAX_DISTANCE = 0x1023,

	AL_SEC_OFFSET = 0x1024,
	AL_SAMPLE_OFFSET = 0x1025,
	AL_BYTE_OFFSET = 0x1026,

	AL_SOURCE_TYPE = 0x1027,

	AL_STATIC = 0x1028,
	AL_STREAMING = 0x1029,
	AL_UNDETERMINED = 0x1030,

	AL_FORMAT_MONO8 = 0x1100,
	AL_FORMAT_MONO16 = 0x1101,
	AL_FORMAT_STEREO8 = 0x1102,
	AL_FORMAT_STEREO16 = 0x1103,

	AL_FREQUENCY = 0x2001,
	AL_BITS = 0x2002,
	AL_CHANNELS = 0x2003,
	AL_SIZE = 0x2004,

	AL_UNUSED = 0x2010,
	AL_PENDING = 0x2011,
	AL_PROCESSED = 0x2012,

	AL_NO_ERROR = 0,
	AL_INVALID_NAME = 0xA001,
	AL_INVALID_ENUM = 0xA002,
	AL_INVALID_VALUE = 0xA003,
	AL_INVALID_OPERATION = 0xA004,
	AL_OUT_OF_MEMORY = 0xA005,

	AL_VENDOR = 0xB001,
	AL_VERSION = 0xB002,
	AL_RENDERER = 0xB003,
	AL_EXTENSIONS = 0xB004,

	AL_DOPPLER_FACTOR = 0xC000,
	AL_DOPPLER_VELOCITY = 0xC001,
	AL_SPEED_OF_SOUND = 0xC003,
	AL_DISTANCE_MODEL = 0xD000,

	AL_INVERSE_DISTANCE = 0xD001,
	AL_INVERSE_DISTANCE_CLAMPED = 0xD002,
	AL_LINEAR_DISTANCE = 0xD003,
	AL_LINEAR_DISTANCE_CLAMPED = 0xD004,
	AL_EXPONENT_DISTANCE = 0xD005,
	AL_EXPONENT_DISTANCE_CLAMPED = 0xD006
};

typedef char ALboolean;
typedef char ALchar;
typedef signed char ALbyte;
typedef unsigned char ALubyte;
typedef short ALshort;
typedef unsigned short ALushort;
typedef int ALint;
typedef unsigned int ALuint;
typedef int ALsizei;
typedef int ALenum;
typedef float ALfloat;
typedef double ALdouble;
typedef void ALvoid;

void alDopplerFactor(ALfloat value);
void alDopplerVelocity(ALfloat value);
void alSpeedOfSound(ALfloat value);
void alDistanceModel(ALenum distanceModel);

void alEnable(ALenum capability);
void alDisable(ALenum capability);
ALboolean alIsEnabled(ALenum capability);

const ALchar* alGetString(ALenum param);
void alGetBooleanv(ALenum param, ALboolean *values);
void alGetIntegerv(ALenum param, ALint *values);
void alGetFloatv(ALenum param, ALfloat *values);
void alGetDoublev(ALenum param, ALdouble *values);
ALboolean alGetBoolean(ALenum param);
ALint alGetInteger(ALenum param);
ALfloat alGetFloat(ALenum param);
ALdouble alGetDouble(ALenum param);

ALenum alGetError(void);

ALboolean alIsExtensionPresent(const ALchar *extname);
void* alGetProcAddress(const ALchar *fname);
ALenum alGetEnumValue(const ALchar *ename);

void alListenerf(ALenum param, ALfloat value);
void alListener3f(ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
void alListenerfv(ALenum param, const ALfloat *values);
void alListeneri(ALenum param, ALint value);
void alListener3i(ALenum param, ALint value1, ALint value2, ALint value3);
void alListeneriv(ALenum param, const ALint *values);

void alGetListenerf(ALenum param, ALfloat *value);
void alGetListener3f(ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
void alGetListenerfv(ALenum param, ALfloat *values);
void alGetListeneri(ALenum param, ALint *value);
void alGetListener3i(ALenum param, ALint *value1, ALint *value2, ALint *value3);
void alGetListeneriv(ALenum param, ALint *values);

void alGenSources(ALsizei n, ALuint *sources);
void alDeleteSources(ALsizei n, const ALuint *sources);
ALboolean alIsSource(ALuint source);

void alSourcef(ALuint source, ALenum param, ALfloat value);
void alSource3f(ALuint source, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
void alSourcefv(ALuint source, ALenum param, const ALfloat *values);
void alSourcei(ALuint source, ALenum param, ALint value);
void alSource3i(ALuint source, ALenum param, ALint value1, ALint value2, ALint value3);
void alSourceiv(ALuint source, ALenum param, const ALint *values);

void alGetSourcef(ALuint source, ALenum param, ALfloat *value);
void alGetSource3f(ALuint source, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
void alGetSourcefv(ALuint source, ALenum param, ALfloat *values);
void alGetSourcei(ALuint source,  ALenum param, ALint *value);
void alGetSource3i(ALuint source, ALenum param, ALint *value1, ALint *value2, ALint *value3);
void alGetSourceiv(ALuint source,  ALenum param, ALint *values);

void alSourcePlayv(ALsizei n, const ALuint *sources);
void alSourceStopv(ALsizei n, const ALuint *sources);
void alSourceRewindv(ALsizei n, const ALuint *sources);
void alSourcePausev(ALsizei n, const ALuint *sources);

void alSourcePlay(ALuint source);
void alSourceStop(ALuint source);
void alSourceRewind(ALuint source);
void alSourcePause(ALuint source);

void alSourceQueueBuffers(ALuint source, ALsizei nb, const ALuint *buffers);
void alSourceUnqueueBuffers(ALuint source, ALsizei nb, ALuint *buffers);

void alGenBuffers(ALsizei n, ALuint *buffers);
void alDeleteBuffers(ALsizei n, const ALuint *buffers);
ALboolean alIsBuffer(ALuint buffer);

void alBufferData(ALuint buffer, ALenum format, const ALvoid *data, ALsizei size, ALsizei freq);

void alBufferf(ALuint buffer, ALenum param, ALfloat value);
void alBuffer3f(ALuint buffer, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
void alBufferfv(ALuint buffer, ALenum param, const ALfloat *values);
void alBufferi(ALuint buffer, ALenum param, ALint value);
void alBuffer3i(ALuint buffer, ALenum param, ALint value1, ALint value2, ALint value3);
void alBufferiv(ALuint buffer, ALenum param, const ALint *values);

void alGetBufferf(ALuint buffer, ALenum param, ALfloat *value);
void alGetBuffer3f(ALuint buffer, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
void alGetBufferfv(ALuint buffer, ALenum param, ALfloat *values);
void alGetBufferi(ALuint buffer, ALenum param, ALint *value);
void alGetBuffer3i(ALuint buffer, ALenum param, ALint *value1, ALint *value2, ALint *value3);
void alGetBufferiv(ALuint buffer, ALenum param, ALint *values);

typedef void          (*LPALENABLE)(ALenum capability);
typedef void          (*LPALDISABLE)(ALenum capability);
typedef ALboolean     (*LPALISENABLED)(ALenum capability);
typedef const ALchar* (*LPALGETSTRING)(ALenum param);
typedef void          (*LPALGETBOOLEANV)(ALenum param, ALboolean *values);
typedef void          (*LPALGETINTEGERV)(ALenum param, ALint *values);
typedef void          (*LPALGETFLOATV)(ALenum param, ALfloat *values);
typedef void          (*LPALGETDOUBLEV)(ALenum param, ALdouble *values);
typedef ALboolean     (*LPALGETBOOLEAN)(ALenum param);
typedef ALint         (*LPALGETINTEGER)(ALenum param);
typedef ALfloat       (*LPALGETFLOAT)(ALenum param);
typedef ALdouble      (*LPALGETDOUBLE)(ALenum param);
typedef ALenum        (*LPALGETERROR)(void);
typedef ALboolean     (*LPALISEXTENSIONPRESENT)(const ALchar *extname);
typedef void*         (*LPALGETPROCADDRESS)(const ALchar *fname);
typedef ALenum        (*LPALGETENUMVALUE)(const ALchar *ename);
typedef void          (*LPALLISTENERF)(ALenum param, ALfloat value);
typedef void          (*LPALLISTENER3F)(ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
typedef void          (*LPALLISTENERFV)(ALenum param, const ALfloat *values);
typedef void          (*LPALLISTENERI)(ALenum param, ALint value);
typedef void          (*LPALLISTENER3I)(ALenum param, ALint value1, ALint value2, ALint value3);
typedef void          (*LPALLISTENERIV)(ALenum param, const ALint *values);
typedef void          (*LPALGETLISTENERF)(ALenum param, ALfloat *value);
typedef void          (*LPALGETLISTENER3F)(ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
typedef void          (*LPALGETLISTENERFV)(ALenum param, ALfloat *values);
typedef void          (*LPALGETLISTENERI)(ALenum param, ALint *value);
typedef void          (*LPALGETLISTENER3I)(ALenum param, ALint *value1, ALint *value2, ALint *value3);
typedef void          (*LPALGETLISTENERIV)(ALenum param, ALint *values);
typedef void          (*LPALGENSOURCES)(ALsizei n, ALuint *sources);
typedef void          (*LPALDELETESOURCES)(ALsizei n, const ALuint *sources);
typedef ALboolean     (*LPALISSOURCE)(ALuint source);
typedef void          (*LPALSOURCEF)(ALuint source, ALenum param, ALfloat value);
typedef void          (*LPALSOURCE3F)(ALuint source, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
typedef void          (*LPALSOURCEFV)(ALuint source, ALenum param, const ALfloat *values);
typedef void          (*LPALSOURCEI)(ALuint source, ALenum param, ALint value);
typedef void          (*LPALSOURCE3I)(ALuint source, ALenum param, ALint value1, ALint value2, ALint value3);
typedef void          (*LPALSOURCEIV)(ALuint source, ALenum param, const ALint *values);
typedef void          (*LPALGETSOURCEF)(ALuint source, ALenum param, ALfloat *value);
typedef void          (*LPALGETSOURCE3F)(ALuint source, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
typedef void          (*LPALGETSOURCEFV)(ALuint source, ALenum param, ALfloat *values);
typedef void          (*LPALGETSOURCEI)(ALuint source, ALenum param, ALint *value);
typedef void          (*LPALGETSOURCE3I)(ALuint source, ALenum param, ALint *value1, ALint *value2, ALint *value3);
typedef void          (*LPALGETSOURCEIV)(ALuint source, ALenum param, ALint *values);
typedef void          (*LPALSOURCEPLAYV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCESTOPV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCEREWINDV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCEPAUSEV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCEPLAY)(ALuint source);
typedef void          (*LPALSOURCESTOP)(ALuint source);
typedef void          (*LPALSOURCEREWIND)(ALuint source);
typedef void          (*LPALSOURCEPAUSE)(ALuint source);
typedef void          (*LPALSOURCEQUEUEBUFFERS)(ALuint source, ALsizei nb, const ALuint *buffers);
typedef void          (*LPALSOURCEUNQUEUEBUFFERS)(ALuint source, ALsizei nb, ALuint *buffers);
typedef void          (*LPALGENBUFFERS)(ALsizei n, ALuint *buffers);
typedef void          (*LPALDELETEBUFFERS)(ALsizei n, const ALuint *buffers);
typedef ALboolean     (*LPALISBUFFER)(ALuint buffer);
typedef void          (*LPALBUFFERDATA)(ALuint buffer, ALenum format, const ALvoid *data, ALsizei size, ALsizei freq);
typedef void          (*LPALBUFFERF)(ALuint buffer, ALenum param, ALfloat value);
typedef void          (*LPALBUFFER3F)(ALuint buffer, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
typedef void          (*LPALBUFFERFV)(ALuint buffer, ALenum param, const ALfloat *values);
typedef void          (*LPALBUFFERI)(ALuint buffer, ALenum param, ALint value);
typedef void          (*LPALBUFFER3I)(ALuint buffer, ALenum param, ALint value1, ALint value2, ALint value3);
typedef void          (*LPALBUFFERIV)(ALuint buffer, ALenum param, const ALint *values);
typedef void          (*LPALGETBUFFERF)(ALuint buffer, ALenum param, ALfloat *value);
typedef void          (*LPALGETBUFFER3F)(ALuint buffer, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
typedef void          (*LPALGETBUFFERFV)(ALuint buffer, ALenum param, ALfloat *values);
typedef void          (*LPALGETBUFFERI)(ALuint buffer, ALenum param, ALint *value);
typedef void          (*LPALGETBUFFER3I)(ALuint buffer, ALenum param, ALint *value1, ALint *value2, ALint *value3);
typedef void          (*LPALGETBUFFERIV)(ALuint buffer, ALenum param, ALint *values);
typedef void          (*LPALDOPPLERFACTOR)(ALfloat value);
typedef void          (*LPALDOPPLERVELOCITY)(ALfloat value);
typedef void          (*LPALSPEEDOFSOUND)(ALfloat value);
typedef void          (*LPALDISTANCEMODEL)(ALenum distanceModel);
�enum {
	ALC_INVALID = 0, //Deprecated

	ALC_VERSION_0_1 = 1,

	ALC_FALSE = 0,
	ALC_TRUE = 1,
	ALC_FREQUENCY = 0x1007,
	ALC_REFRESH = 0x1008,
	ALC_SYNC = 0x1009,

	ALC_MONO_SOURCES = 0x1010,
	ALC_STEREO_SOURCES = 0x1011,

	ALC_NO_ERROR = 0,
	ALC_INVALID_DEVICE = 0xA001,
	ALC_INVALID_CONTEXT = 0xA002,
	ALC_INVALID_ENUM = 0xA003,
	ALC_INVALID_VALUE = 0xA004,
	ALC_OUT_OF_MEMORY = 0xA005,

	ALC_MAJOR_VERSION = 0x1000,
	ALC_MINOR_VERSION = 0x1001,

	ALC_ATTRIBUTES_SIZE = 0x1002,
	ALC_ALL_ATTRIBUTES = 0x1003,

	ALC_DEFAULT_DEVICE_SPECIFIER = 0x1004,
	ALC_DEVICE_SPECIFIER = 0x1005,
	ALC_EXTENSIONS = 0x1006,

	ALC_EXT_CAPTURE = 1,
	ALC_CAPTURE_DEVICE_SPECIFIER = 0x310,
	ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER = 0x311,
	ALC_CAPTURE_SAMPLES = 0x312,

	ALC_DEFAULT_ALL_DEVICES_SPECIFIER = 0x1012,
	ALC_ALL_DEVICES_SPECIFIER = 0x1013
};

typedef struct ALCdevice_struct ALCdevice;
typedef struct ALCcontext_struct ALCcontext;

typedef char ALCboolean;
typedef char ALCchar;
typedef signed char ALCbyte;
typedef unsigned char ALCubyte;
typedef short ALCshort;
typedef unsigned short ALCushort;
typedef int ALCint;
typedef unsigned int ALCuint;
typedef int ALCsizei;
typedef int ALCenum;
typedef float ALCfloat;
typedef double ALCdouble;
typedef void ALCvoid;

ALCcontext* alcCreateContext(ALCdevice *device, const ALCint* attrlist);
ALCboolean  alcMakeContextCurrent(ALCcontext *context);
void        alcProcessContext(ALCcontext *context);
void        alcSuspendContext(ALCcontext *context);
void        alcDestroyContext(ALCcontext *context);
ALCcontext* alcGetCurrentContext(void);
ALCdevice*  alcGetContextsDevice(ALCcontext *context);

ALCdevice* alcOpenDevice(const ALCchar *devicename);
ALCboolean alcCloseDevice(ALCdevice *device);

ALCenum alcGetError(ALCdevice *device);
ALCboolean alcIsExtensionPresent(ALCdevice *device, const ALCchar *extname);
void*      alcGetProcAddress(ALCdevice *device, const ALCchar *funcname);
ALCenum    alcGetEnumValue(ALCdevice *device, const ALCchar *enumname);

const ALCchar* alcGetString(ALCdevice *device, ALCenum param);
void           alcGetIntegerv(ALCdevice *device, ALCenum param, ALCsizei size, ALCint *values);

ALCdevice* alcCaptureOpenDevice(const ALCchar *devicename, ALCuint frequency, ALCenum format, ALCsizei buffersize);
ALCboolean alcCaptureCloseDevice(ALCdevice *device);
void       alcCaptureStart(ALCdevice *device);
void       alcCaptureStop(ALCdevice *device);
void       alcCaptureSamples(ALCdevice *device, ALCvoid *buffer, ALCsizei samples);

typedef ALCcontext*    (*LPALCCREATECONTEXT)(ALCdevice *device, const ALCint *attrlist);
typedef ALCboolean     (*LPALCMAKECONTEXTCURRENT)(ALCcontext *context);
typedef void           (*LPALCPROCESSCONTEXT)(ALCcontext *context);
typedef void           (*LPALCSUSPENDCONTEXT)(ALCcontext *context);
typedef void           (*LPALCDESTROYCONTEXT)(ALCcontext *context);
typedef ALCcontext*    (*LPALCGETCURRENTCONTEXT)(void);
typedef ALCdevice*     (*LPALCGETCONTEXTSDEVICE)(ALCcontext *context);
typedef ALCdevice*     (*LPALCOPENDEVICE)(const ALCchar *devicename);
typedef ALCboolean     (*LPALCCLOSEDEVICE)(ALCdevice *device);
typedef ALCenum        (*LPALCGETERROR)(ALCdevice *device);
typedef ALCboolean     (*LPALCISEXTENSIONPRESENT)(ALCdevice *device, const ALCchar *extname);
typedef void*          (*LPALCGETPROCADDRESS)(ALCdevice *device, const ALCchar *funcname);
typedef ALCenum        (*LPALCGETENUMVALUE)(ALCdevice *device, const ALCchar *enumname);
typedef const ALCchar* (*LPALCGETSTRING)(ALCdevice *device, ALCenum param);
typedef void           (*LPALCGETINTEGERV)(ALCdevice *device, ALCenum param, ALCsizei size, ALCint *values);
typedef ALCdevice*     (*LPALCCAPTUREOPENDEVICE)(const ALCchar *devicename, ALCuint frequency, ALCenum format, ALCsizei buffersize);
typedef ALCboolean     (*LPALCCAPTURECLOSEDEVICE)(ALCdevice *device);
typedef void           (*LPALCCAPTURESTART)(ALCdevice *device);
typedef void           (*LPALCCAPTURESTOP)(ALCdevice *device);
typedef void           (*LPALCCAPTURESAMPLES)(ALCdevice *device, ALCvoid *buffer, ALCsizei samples);
	cdefClib/win32/OpenAL.dll	loadWindowsosffirequire             l  o so uffi oal 	  ]==])
Coeus:AddVFSFile('Bindings.OpenGL', [==[LJ ��local ffi = require("ffi")

-- glcorearb.h
local glheader = [[
/*
** Copyright (c) 2013-2014 The Khronos Group Inc.
**
** Permission is hereby granted, free of charge, to any person obtaining a
** copy of this software and/or associated documentation files (the
** "Materials"), to deal in the Materials without restriction, including
** without limitation the rights to use, copy, modify, merge, publish,
** distribute, sublicense, and/or sell copies of the Materials, and to
** permit persons to whom the Materials are furnished to do so, subject to
** the following conditions:
**
** The above copyright notice and this permission notice shall be included
** in all copies or substantial portions of the Materials.
**
** THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
** EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
** MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
** CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
** TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
** MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
*/
/*
** This header is generated from the Khronos OpenGL / OpenGL ES XML
** API Registry. The current version of the Registry, generator scripts
** used to make the header, and the header can be found at
**   http://www.opengl.org/registry/
**
** Khronos $Revision: 26007 $ on $Date: 2014-03-19 01:28:09 -0700 (Wed, 19 Mar 2014) $
*/

/* glcorearb.h is for use with OpenGL core profile implementations.
** It should should be placed in the same directory as gl.h and
** included as <GL/glcorearb.h>.
**
** glcorearb.h includes only APIs in the latest OpenGL core profile
** implementation together with APIs in newer ARB extensions which 
** can be supported by the core profile. It does not, and never will
** include functionality removed from the core profile, such as
** fixed-function vertex and fragment processing.
**
** Do not #include both <GL/glcorearb.h> and either of <GL/gl.h> or
** <GL/glext.h> in the same source file.
*/

/* Generated C header for:
 * API: gl
 * Profile: core
 * Versions considered: .*
 * Versions emitted: .*
 * Default extensions included: glcore
 * Additional extensions included: _nomatch_^
 * Extensions removed: _nomatch_^
 */

typedef void GLvoid;
typedef unsigned int GLenum;
typedef float GLfloat;
typedef int GLint;
typedef int GLsizei;
typedef unsigned int GLbitfield;
typedef double GLdouble;
typedef unsigned int GLuint;
typedef unsigned char GLboolean;
typedef unsigned char GLubyte;
typedef void (APIENTRYP PFNGLCULLFACEPROC) (GLenum mode);
typedef void (APIENTRYP PFNGLFRONTFACEPROC) (GLenum mode);
typedef void (APIENTRYP PFNGLHINTPROC) (GLenum target, GLenum mode);
typedef void (APIENTRYP PFNGLLINEWIDTHPROC) (GLfloat width);
typedef void (APIENTRYP PFNGLPOINTSIZEPROC) (GLfloat size);
typedef void (APIENTRYP PFNGLPOLYGONMODEPROC) (GLenum face, GLenum mode);
typedef void (APIENTRYP PFNGLSCISSORPROC) (GLint x, GLint y, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLTEXPARAMETERFPROC) (GLenum target, GLenum pname, GLfloat param);
typedef void (APIENTRYP PFNGLTEXPARAMETERFVPROC) (GLenum target, GLenum pname, const GLfloat *params);
typedef void (APIENTRYP PFNGLTEXPARAMETERIPROC) (GLenum target, GLenum pname, GLint param);
typedef void (APIENTRYP PFNGLTEXPARAMETERIVPROC) (GLenum target, GLenum pname, const GLint *params);
typedef void (APIENTRYP PFNGLTEXIMAGE1DPROC) (GLenum target, GLint level, GLint internalformat, GLsizei width, GLint border, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLTEXIMAGE2DPROC) (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLDRAWBUFFERPROC) (GLenum mode);
typedef void (APIENTRYP PFNGLCLEARPROC) (GLbitfield mask);
typedef void (APIENTRYP PFNGLCLEARCOLORPROC) (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
typedef void (APIENTRYP PFNGLCLEARSTENCILPROC) (GLint s);
typedef void (APIENTRYP PFNGLCLEARDEPTHPROC) (GLdouble depth);
typedef void (APIENTRYP PFNGLSTENCILMASKPROC) (GLuint mask);
typedef void (APIENTRYP PFNGLCOLORMASKPROC) (GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);
typedef void (APIENTRYP PFNGLDEPTHMASKPROC) (GLboolean flag);
typedef void (APIENTRYP PFNGLDISABLEPROC) (GLenum cap);
typedef void (APIENTRYP PFNGLENABLEPROC) (GLenum cap);
typedef void (APIENTRYP PFNGLFINISHPROC) (void);
typedef void (APIENTRYP PFNGLFLUSHPROC) (void);
typedef void (APIENTRYP PFNGLBLENDFUNCPROC) (GLenum sfactor, GLenum dfactor);
typedef void (APIENTRYP PFNGLLOGICOPPROC) (GLenum opcode);
typedef void (APIENTRYP PFNGLSTENCILFUNCPROC) (GLenum func, GLint ref, GLuint mask);
typedef void (APIENTRYP PFNGLSTENCILOPPROC) (GLenum fail, GLenum zfail, GLenum zpass);
typedef void (APIENTRYP PFNGLDEPTHFUNCPROC) (GLenum func);
typedef void (APIENTRYP PFNGLPIXELSTOREFPROC) (GLenum pname, GLfloat param);
typedef void (APIENTRYP PFNGLPIXELSTOREIPROC) (GLenum pname, GLint param);
typedef void (APIENTRYP PFNGLREADBUFFERPROC) (GLenum mode);
typedef void (APIENTRYP PFNGLREADPIXELSPROC) (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, void *pixels);
typedef void (APIENTRYP PFNGLGETBOOLEANVPROC) (GLenum pname, GLboolean *data);
typedef void (APIENTRYP PFNGLGETDOUBLEVPROC) (GLenum pname, GLdouble *data);
typedef GLenum (APIENTRYP PFNGLGETERRORPROC) (void);
typedef void (APIENTRYP PFNGLGETFLOATVPROC) (GLenum pname, GLfloat *data);
typedef void (APIENTRYP PFNGLGETINTEGERVPROC) (GLenum pname, GLint *data);
typedef const GLubyte *(APIENTRYP PFNGLGETSTRINGPROC) (GLenum name);
typedef void (APIENTRYP PFNGLGETTEXIMAGEPROC) (GLenum target, GLint level, GLenum format, GLenum type, void *pixels);
typedef void (APIENTRYP PFNGLGETTEXPARAMETERFVPROC) (GLenum target, GLenum pname, GLfloat *params);
typedef void (APIENTRYP PFNGLGETTEXPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETTEXLEVELPARAMETERFVPROC) (GLenum target, GLint level, GLenum pname, GLfloat *params);
typedef void (APIENTRYP PFNGLGETTEXLEVELPARAMETERIVPROC) (GLenum target, GLint level, GLenum pname, GLint *params);
typedef GLboolean (APIENTRYP PFNGLISENABLEDPROC) (GLenum cap);
typedef void (APIENTRYP PFNGLDEPTHRANGEPROC) (GLdouble near, GLdouble far);
typedef void (APIENTRYP PFNGLVIEWPORTPROC) (GLint x, GLint y, GLsizei width, GLsizei height);

typedef float GLclampf;
typedef double GLclampd;
#define GL_DEPTH_BUFFER_BIT               0x00000100
#define GL_STENCIL_BUFFER_BIT             0x00000400
#define GL_COLOR_BUFFER_BIT               0x00004000
#define GL_FALSE                          0
#define GL_TRUE                           1
#define GL_POINTS                         0x0000
#define GL_LINES                          0x0001
#define GL_LINE_LOOP                      0x0002
#define GL_LINE_STRIP                     0x0003
#define GL_TRIANGLES                      0x0004
#define GL_TRIANGLE_STRIP                 0x0005
#define GL_TRIANGLE_FAN                   0x0006
#define GL_QUADS                          0x0007
#define GL_NEVER                          0x0200
#define GL_LESS                           0x0201
#define GL_EQUAL                          0x0202
#define GL_LEQUAL                         0x0203
#define GL_GREATER                        0x0204
#define GL_NOTEQUAL                       0x0205
#define GL_GEQUAL                         0x0206
#define GL_ALWAYS                         0x0207
#define GL_ZERO                           0
#define GL_ONE                            1
#define GL_SRC_COLOR                      0x0300
#define GL_ONE_MINUS_SRC_COLOR            0x0301
#define GL_SRC_ALPHA                      0x0302
#define GL_ONE_MINUS_SRC_ALPHA            0x0303
#define GL_DST_ALPHA                      0x0304
#define GL_ONE_MINUS_DST_ALPHA            0x0305
#define GL_DST_COLOR                      0x0306
#define GL_ONE_MINUS_DST_COLOR            0x0307
#define GL_SRC_ALPHA_SATURATE             0x0308
#define GL_NONE                           0
#define GL_FRONT_LEFT                     0x0400
#define GL_FRONT_RIGHT                    0x0401
#define GL_BACK_LEFT                      0x0402
#define GL_BACK_RIGHT                     0x0403
#define GL_FRONT                          0x0404
#define GL_BACK                           0x0405
#define GL_LEFT                           0x0406
#define GL_RIGHT                          0x0407
#define GL_FRONT_AND_BACK                 0x0408
#define GL_NO_ERROR                       0
#define GL_INVALID_ENUM                   0x0500
#define GL_INVALID_VALUE                  0x0501
#define GL_INVALID_OPERATION              0x0502
#define GL_OUT_OF_MEMORY                  0x0505
#define GL_CW                             0x0900
#define GL_CCW                            0x0901
#define GL_POINT_SIZE                     0x0B11
#define GL_POINT_SIZE_RANGE               0x0B12
#define GL_POINT_SIZE_GRANULARITY         0x0B13
#define GL_LINE_SMOOTH                    0x0B20
#define GL_LINE_WIDTH                     0x0B21
#define GL_LINE_WIDTH_RANGE               0x0B22
#define GL_LINE_WIDTH_GRANULARITY         0x0B23
#define GL_POLYGON_MODE                   0x0B40
#define GL_POLYGON_SMOOTH                 0x0B41
#define GL_CULL_FACE                      0x0B44
#define GL_CULL_FACE_MODE                 0x0B45
#define GL_FRONT_FACE                     0x0B46
#define GL_DEPTH_RANGE                    0x0B70
#define GL_DEPTH_TEST                     0x0B71
#define GL_DEPTH_WRITEMASK                0x0B72
#define GL_DEPTH_CLEAR_VALUE              0x0B73
#define GL_DEPTH_FUNC                     0x0B74
#define GL_STENCIL_TEST                   0x0B90
#define GL_STENCIL_CLEAR_VALUE            0x0B91
#define GL_STENCIL_FUNC                   0x0B92
#define GL_STENCIL_VALUE_MASK             0x0B93
#define GL_STENCIL_FAIL                   0x0B94
#define GL_STENCIL_PASS_DEPTH_FAIL        0x0B95
#define GL_STENCIL_PASS_DEPTH_PASS        0x0B96
#define GL_STENCIL_REF                    0x0B97
#define GL_STENCIL_WRITEMASK              0x0B98
#define GL_VIEWPORT                       0x0BA2
#define GL_DITHER                         0x0BD0
#define GL_BLEND_DST                      0x0BE0
#define GL_BLEND_SRC                      0x0BE1
#define GL_BLEND                          0x0BE2
#define GL_LOGIC_OP_MODE                  0x0BF0
#define GL_COLOR_LOGIC_OP                 0x0BF2
#define GL_DRAW_BUFFER                    0x0C01
#define GL_READ_BUFFER                    0x0C02
#define GL_SCISSOR_BOX                    0x0C10
#define GL_SCISSOR_TEST                   0x0C11
#define GL_COLOR_CLEAR_VALUE              0x0C22
#define GL_COLOR_WRITEMASK                0x0C23
#define GL_DOUBLEBUFFER                   0x0C32
#define GL_STEREO                         0x0C33
#define GL_LINE_SMOOTH_HINT               0x0C52
#define GL_POLYGON_SMOOTH_HINT            0x0C53
#define GL_UNPACK_SWAP_BYTES              0x0CF0
#define GL_UNPACK_LSB_FIRST               0x0CF1
#define GL_UNPACK_ROW_LENGTH              0x0CF2
#define GL_UNPACK_SKIP_ROWS               0x0CF3
#define GL_UNPACK_SKIP_PIXELS             0x0CF4
#define GL_UNPACK_ALIGNMENT               0x0CF5
#define GL_PACK_SWAP_BYTES                0x0D00
#define GL_PACK_LSB_FIRST                 0x0D01
#define GL_PACK_ROW_LENGTH                0x0D02
#define GL_PACK_SKIP_ROWS                 0x0D03
#define GL_PACK_SKIP_PIXELS               0x0D04
#define GL_PACK_ALIGNMENT                 0x0D05
#define GL_MAX_TEXTURE_SIZE               0x0D33
#define GL_MAX_VIEWPORT_DIMS              0x0D3A
#define GL_SUBPIXEL_BITS                  0x0D50
#define GL_TEXTURE_1D                     0x0DE0
#define GL_TEXTURE_2D                     0x0DE1
#define GL_POLYGON_OFFSET_UNITS           0x2A00
#define GL_POLYGON_OFFSET_POINT           0x2A01
#define GL_POLYGON_OFFSET_LINE            0x2A02
#define GL_POLYGON_OFFSET_FILL            0x8037
#define GL_POLYGON_OFFSET_FACTOR          0x8038
#define GL_TEXTURE_BINDING_1D             0x8068
#define GL_TEXTURE_BINDING_2D             0x8069
#define GL_TEXTURE_WIDTH                  0x1000
#define GL_TEXTURE_HEIGHT                 0x1001
#define GL_TEXTURE_INTERNAL_FORMAT        0x1003
#define GL_TEXTURE_BORDER_COLOR           0x1004
#define GL_TEXTURE_RED_SIZE               0x805C
#define GL_TEXTURE_GREEN_SIZE             0x805D
#define GL_TEXTURE_BLUE_SIZE              0x805E
#define GL_TEXTURE_ALPHA_SIZE             0x805F
#define GL_DONT_CARE                      0x1100
#define GL_FASTEST                        0x1101
#define GL_NICEST                         0x1102
#define GL_BYTE                           0x1400
#define GL_UNSIGNED_BYTE                  0x1401
#define GL_SHORT                          0x1402
#define GL_UNSIGNED_SHORT                 0x1403
#define GL_INT                            0x1404
#define GL_UNSIGNED_INT                   0x1405
#define GL_FLOAT                          0x1406
#define GL_DOUBLE                         0x140A
#define GL_STACK_OVERFLOW                 0x0503
#define GL_STACK_UNDERFLOW                0x0504
#define GL_CLEAR                          0x1500
#define GL_AND                            0x1501
#define GL_AND_REVERSE                    0x1502
#define GL_COPY                           0x1503
#define GL_AND_INVERTED                   0x1504
#define GL_NOOP                           0x1505
#define GL_XOR                            0x1506
#define GL_OR                             0x1507
#define GL_NOR                            0x1508
#define GL_EQUIV                          0x1509
#define GL_INVERT                         0x150A
#define GL_OR_REVERSE                     0x150B
#define GL_COPY_INVERTED                  0x150C
#define GL_OR_INVERTED                    0x150D
#define GL_NAND                           0x150E
#define GL_SET                            0x150F
#define GL_TEXTURE                        0x1702
#define GL_COLOR                          0x1800
#define GL_DEPTH                          0x1801
#define GL_STENCIL                        0x1802
#define GL_STENCIL_INDEX                  0x1901
#define GL_DEPTH_COMPONENT                0x1902
#define GL_RED                            0x1903
#define GL_GREEN                          0x1904
#define GL_BLUE                           0x1905
#define GL_ALPHA                          0x1906
#define GL_RGB                            0x1907
#define GL_RGBA                           0x1908
#define GL_POINT                          0x1B00
#define GL_LINE                           0x1B01
#define GL_FILL                           0x1B02
#define GL_KEEP                           0x1E00
#define GL_REPLACE                        0x1E01
#define GL_INCR                           0x1E02
#define GL_DECR                           0x1E03
#define GL_VENDOR                         0x1F00
#define GL_RENDERER                       0x1F01
#define GL_VERSION                        0x1F02
#define GL_EXTENSIONS                     0x1F03
#define GL_NEAREST                        0x2600
#define GL_LINEAR                         0x2601
#define GL_NEAREST_MIPMAP_NEAREST         0x2700
#define GL_LINEAR_MIPMAP_NEAREST          0x2701
#define GL_NEAREST_MIPMAP_LINEAR          0x2702
#define GL_LINEAR_MIPMAP_LINEAR           0x2703
#define GL_TEXTURE_MAG_FILTER             0x2800
#define GL_TEXTURE_MIN_FILTER             0x2801
#define GL_TEXTURE_WRAP_S                 0x2802
#define GL_TEXTURE_WRAP_T                 0x2803
#define GL_PROXY_TEXTURE_1D               0x8063
#define GL_PROXY_TEXTURE_2D               0x8064
#define GL_REPEAT                         0x2901
#define GL_R3_G3_B2                       0x2A10
#define GL_RGB4                           0x804F
#define GL_RGB5                           0x8050
#define GL_RGB8                           0x8051
#define GL_RGB10                          0x8052
#define GL_RGB12                          0x8053
#define GL_RGB16                          0x8054
#define GL_RGBA2                          0x8055
#define GL_RGBA4                          0x8056
#define GL_RGB5_A1                        0x8057
#define GL_RGBA8                          0x8058
#define GL_RGB10_A2                       0x8059
#define GL_RGBA12                         0x805A
#define GL_RGBA16                         0x805B
#define GL_VERTEX_ARRAY                   0x8074
typedef void (APIENTRYP PFNGLDRAWARRAYSPROC) (GLenum mode, GLint first, GLsizei count);
typedef void (APIENTRYP PFNGLDRAWELEMENTSPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices);
typedef void (APIENTRYP PFNGLGETPOINTERVPROC) (GLenum pname, void **params);
typedef void (APIENTRYP PFNGLPOLYGONOFFSETPROC) (GLfloat factor, GLfloat units);
typedef void (APIENTRYP PFNGLCOPYTEXIMAGE1DPROC) (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLint border);
typedef void (APIENTRYP PFNGLCOPYTEXIMAGE2DPROC) (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
typedef void (APIENTRYP PFNGLCOPYTEXSUBIMAGE1DPROC) (GLenum target, GLint level, GLint xoffset, GLint x, GLint y, GLsizei width);
typedef void (APIENTRYP PFNGLCOPYTEXSUBIMAGE2DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLTEXSUBIMAGE1DPROC) (GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLTEXSUBIMAGE2DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLBINDTEXTUREPROC) (GLenum target, GLuint texture);
typedef void (APIENTRYP PFNGLDELETETEXTURESPROC) (GLsizei n, const GLuint *textures);
typedef void (APIENTRYP PFNGLGENTEXTURESPROC) (GLsizei n, GLuint *textures);
typedef GLboolean (APIENTRYP PFNGLISTEXTUREPROC) (GLuint texture);

#define GL_UNSIGNED_BYTE_3_3_2            0x8032
#define GL_UNSIGNED_SHORT_4_4_4_4         0x8033
#define GL_UNSIGNED_SHORT_5_5_5_1         0x8034
#define GL_UNSIGNED_INT_8_8_8_8           0x8035
#define GL_UNSIGNED_INT_10_10_10_2        0x8036
#define GL_TEXTURE_BINDING_3D             0x806A
#define GL_PACK_SKIP_IMAGES               0x806B
#define GL_PACK_IMAGE_HEIGHT              0x806C
#define GL_UNPACK_SKIP_IMAGES             0x806D
#define GL_UNPACK_IMAGE_HEIGHT            0x806E
#define GL_TEXTURE_3D                     0x806F
#define GL_PROXY_TEXTURE_3D               0x8070
#define GL_TEXTURE_DEPTH                  0x8071
#define GL_TEXTURE_WRAP_R                 0x8072
#define GL_MAX_3D_TEXTURE_SIZE            0x8073
#define GL_UNSIGNED_BYTE_2_3_3_REV        0x8362
#define GL_UNSIGNED_SHORT_5_6_5           0x8363
#define GL_UNSIGNED_SHORT_5_6_5_REV       0x8364
#define GL_UNSIGNED_SHORT_4_4_4_4_REV     0x8365
#define GL_UNSIGNED_SHORT_1_5_5_5_REV     0x8366
#define GL_UNSIGNED_INT_8_8_8_8_REV       0x8367
#define GL_UNSIGNED_INT_2_10_10_10_REV    0x8368
#define GL_BGR                            0x80E0
#define GL_BGRA                           0x80E1
#define GL_MAX_ELEMENTS_VERTICES          0x80E8
#define GL_MAX_ELEMENTS_INDICES           0x80E9
#define GL_CLAMP_TO_EDGE                  0x812F
#define GL_TEXTURE_MIN_LOD                0x813A
#define GL_TEXTURE_MAX_LOD                0x813B
#define GL_TEXTURE_BASE_LEVEL             0x813C
#define GL_TEXTURE_MAX_LEVEL              0x813D
#define GL_SMOOTH_POINT_SIZE_RANGE        0x0B12
#define GL_SMOOTH_POINT_SIZE_GRANULARITY  0x0B13
#define GL_SMOOTH_LINE_WIDTH_RANGE        0x0B22
#define GL_SMOOTH_LINE_WIDTH_GRANULARITY  0x0B23
#define GL_ALIASED_LINE_WIDTH_RANGE       0x846E
typedef void (APIENTRYP PFNGLDRAWRANGEELEMENTSPROC) (GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const void *indices);
typedef void (APIENTRYP PFNGLTEXIMAGE3DPROC) (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLTEXSUBIMAGE3DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLCOPYTEXSUBIMAGE3DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);

#define GL_TEXTURE0                       0x84C0
#define GL_TEXTURE1                       0x84C1
#define GL_TEXTURE2                       0x84C2
#define GL_TEXTURE3                       0x84C3
#define GL_TEXTURE4                       0x84C4
#define GL_TEXTURE5                       0x84C5
#define GL_TEXTURE6                       0x84C6
#define GL_TEXTURE7                       0x84C7
#define GL_TEXTURE8                       0x84C8
#define GL_TEXTURE9                       0x84C9
#define GL_TEXTURE10                      0x84CA
#define GL_TEXTURE11                      0x84CB
#define GL_TEXTURE12                      0x84CC
#define GL_TEXTURE13                      0x84CD
#define GL_TEXTURE14                      0x84CE
#define GL_TEXTURE15                      0x84CF
#define GL_TEXTURE16                      0x84D0
#define GL_TEXTURE17                      0x84D1
#define GL_TEXTURE18                      0x84D2
#define GL_TEXTURE19                      0x84D3
#define GL_TEXTURE20                      0x84D4
#define GL_TEXTURE21                      0x84D5
#define GL_TEXTURE22                      0x84D6
#define GL_TEXTURE23                      0x84D7
#define GL_TEXTURE24                      0x84D8
#define GL_TEXTURE25                      0x84D9
#define GL_TEXTURE26                      0x84DA
#define GL_TEXTURE27                      0x84DB
#define GL_TEXTURE28                      0x84DC
#define GL_TEXTURE29                      0x84DD
#define GL_TEXTURE30                      0x84DE
#define GL_TEXTURE31                      0x84DF
#define GL_ACTIVE_TEXTURE                 0x84E0
#define GL_MULTISAMPLE                    0x809D
#define GL_SAMPLE_ALPHA_TO_COVERAGE       0x809E
#define GL_SAMPLE_ALPHA_TO_ONE            0x809F
#define GL_SAMPLE_COVERAGE                0x80A0
#define GL_SAMPLE_BUFFERS                 0x80A8
#define GL_SAMPLES                        0x80A9
#define GL_SAMPLE_COVERAGE_VALUE          0x80AA
#define GL_SAMPLE_COVERAGE_INVERT         0x80AB
#define GL_TEXTURE_CUBE_MAP               0x8513
#define GL_TEXTURE_BINDING_CUBE_MAP       0x8514
#define GL_TEXTURE_CUBE_MAP_POSITIVE_X    0x8515
#define GL_TEXTURE_CUBE_MAP_NEGATIVE_X    0x8516
#define GL_TEXTURE_CUBE_MAP_POSITIVE_Y    0x8517
#define GL_TEXTURE_CUBE_MAP_NEGATIVE_Y    0x8518
#define GL_TEXTURE_CUBE_MAP_POSITIVE_Z    0x8519
#define GL_TEXTURE_CUBE_MAP_NEGATIVE_Z    0x851A
#define GL_PROXY_TEXTURE_CUBE_MAP         0x851B
#define GL_MAX_CUBE_MAP_TEXTURE_SIZE      0x851C
#define GL_COMPRESSED_RGB                 0x84ED
#define GL_COMPRESSED_RGBA                0x84EE
#define GL_TEXTURE_COMPRESSION_HINT       0x84EF
#define GL_TEXTURE_COMPRESSED_IMAGE_SIZE  0x86A0
#define GL_TEXTURE_COMPRESSED             0x86A1
#define GL_NUM_COMPRESSED_TEXTURE_FORMATS 0x86A2
#define GL_COMPRESSED_TEXTURE_FORMATS     0x86A3
#define GL_CLAMP_TO_BORDER                0x812D
typedef void (APIENTRYP PFNGLACTIVETEXTUREPROC) (GLenum texture);
typedef void (APIENTRYP PFNGLSAMPLECOVERAGEPROC) (GLfloat value, GLboolean invert);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXIMAGE3DPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXIMAGE2DPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXIMAGE1DPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXSUBIMAGE3DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXSUBIMAGE2DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXSUBIMAGE1DPROC) (GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLGETCOMPRESSEDTEXIMAGEPROC) (GLenum target, GLint level, void *img);

#define GL_BLEND_DST_RGB                  0x80C8
#define GL_BLEND_SRC_RGB                  0x80C9
#define GL_BLEND_DST_ALPHA                0x80CA
#define GL_BLEND_SRC_ALPHA                0x80CB
#define GL_POINT_FADE_THRESHOLD_SIZE      0x8128
#define GL_DEPTH_COMPONENT16              0x81A5
#define GL_DEPTH_COMPONENT24              0x81A6
#define GL_DEPTH_COMPONENT32              0x81A7
#define GL_MIRRORED_REPEAT                0x8370
#define GL_MAX_TEXTURE_LOD_BIAS           0x84FD
#define GL_TEXTURE_LOD_BIAS               0x8501
#define GL_INCR_WRAP                      0x8507
#define GL_DECR_WRAP                      0x8508
#define GL_TEXTURE_DEPTH_SIZE             0x884A
#define GL_TEXTURE_COMPARE_MODE           0x884C
#define GL_TEXTURE_COMPARE_FUNC           0x884D
#define GL_FUNC_ADD                       0x8006
#define GL_FUNC_SUBTRACT                  0x800A
#define GL_FUNC_REVERSE_SUBTRACT          0x800B
#define GL_MIN                            0x8007
#define GL_MAX                            0x8008
#define GL_CONSTANT_COLOR                 0x8001
#define GL_ONE_MINUS_CONSTANT_COLOR       0x8002
#define GL_CONSTANT_ALPHA                 0x8003
#define GL_ONE_MINUS_CONSTANT_ALPHA       0x8004
typedef void (APIENTRYP PFNGLBLENDFUNCSEPARATEPROC) (GLenum sfactorRGB, GLenum dfactorRGB, GLenum sfactorAlpha, GLenum dfactorAlpha);
typedef void (APIENTRYP PFNGLMULTIDRAWARRAYSPROC) (GLenum mode, const GLint *first, const GLsizei *count, GLsizei drawcount);
typedef void (APIENTRYP PFNGLMULTIDRAWELEMENTSPROC) (GLenum mode, const GLsizei *count, GLenum type, const void *const*indices, GLsizei drawcount);
typedef void (APIENTRYP PFNGLPOINTPARAMETERFPROC) (GLenum pname, GLfloat param);
typedef void (APIENTRYP PFNGLPOINTPARAMETERFVPROC) (GLenum pname, const GLfloat *params);
typedef void (APIENTRYP PFNGLPOINTPARAMETERIPROC) (GLenum pname, GLint param);
typedef void (APIENTRYP PFNGLPOINTPARAMETERIVPROC) (GLenum pname, const GLint *params);
typedef void (APIENTRYP PFNGLBLENDCOLORPROC) (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
typedef void (APIENTRYP PFNGLBLENDEQUATIONPROC) (GLenum mode);

typedef ptrdiff_t GLsizeiptr;
typedef ptrdiff_t GLintptr;
#define GL_BUFFER_SIZE                    0x8764
#define GL_BUFFER_USAGE                   0x8765
#define GL_QUERY_COUNTER_BITS             0x8864
#define GL_CURRENT_QUERY                  0x8865
#define GL_QUERY_RESULT                   0x8866
#define GL_QUERY_RESULT_AVAILABLE         0x8867
#define GL_ARRAY_BUFFER                   0x8892
#define GL_ELEMENT_ARRAY_BUFFER           0x8893
#define GL_ARRAY_BUFFER_BINDING           0x8894
#define GL_ELEMENT_ARRAY_BUFFER_BINDING   0x8895
#define GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING 0x889F
#define GL_READ_ONLY                      0x88B8
#define GL_WRITE_ONLY                     0x88B9
#define GL_READ_WRITE                     0x88BA
#define GL_BUFFER_ACCESS                  0x88BB
#define GL_BUFFER_MAPPED                  0x88BC
#define GL_BUFFER_MAP_POINTER             0x88BD
#define GL_STREAM_DRAW                    0x88E0
#define GL_STREAM_READ                    0x88E1
#define GL_STREAM_COPY                    0x88E2
#define GL_STATIC_DRAW                    0x88E4
#define GL_STATIC_READ                    0x88E5
#define GL_STATIC_COPY                    0x88E6
#define GL_DYNAMIC_DRAW                   0x88E8
#define GL_DYNAMIC_READ                   0x88E9
#define GL_DYNAMIC_COPY                   0x88EA
#define GL_SAMPLES_PASSED                 0x8914
#define GL_SRC1_ALPHA                     0x8589
typedef void (APIENTRYP PFNGLGENQUERIESPROC) (GLsizei n, GLuint *ids);
typedef void (APIENTRYP PFNGLDELETEQUERIESPROC) (GLsizei n, const GLuint *ids);
typedef GLboolean (APIENTRYP PFNGLISQUERYPROC) (GLuint id);
typedef void (APIENTRYP PFNGLBEGINQUERYPROC) (GLenum target, GLuint id);
typedef void (APIENTRYP PFNGLENDQUERYPROC) (GLenum target);
typedef void (APIENTRYP PFNGLGETQUERYIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETQUERYOBJECTIVPROC) (GLuint id, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETQUERYOBJECTUIVPROC) (GLuint id, GLenum pname, GLuint *params);
typedef void (APIENTRYP PFNGLBINDBUFFERPROC) (GLenum target, GLuint buffer);
typedef void (APIENTRYP PFNGLDELETEBUFFERSPROC) (GLsizei n, const GLuint *buffers);
typedef void (APIENTRYP PFNGLGENBUFFERSPROC) (GLsizei n, GLuint *buffers);
typedef GLboolean (APIENTRYP PFNGLISBUFFERPROC) (GLuint buffer);
typedef void (APIENTRYP PFNGLBUFFERDATAPROC) (GLenum target, GLsizeiptr size, const void *data, GLenum usage);
typedef void (APIENTRYP PFNGLBUFFERSUBDATAPROC) (GLenum target, GLintptr offset, GLsizeiptr size, const void *data);
typedef void (APIENTRYP PFNGLGETBUFFERSUBDATAPROC) (GLenum target, GLintptr offset, GLsizeiptr size, void *data);
typedef void *(APIENTRYP PFNGLMAPBUFFERPROC) (GLenum target, GLenum access);
typedef GLboolean (APIENTRYP PFNGLUNMAPBUFFERPROC) (GLenum target);
typedef void (APIENTRYP PFNGLGETBUFFERPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETBUFFERPOINTERVPROC) (GLenum target, GLenum pname, void **params);

typedef char GLchar;
typedef short GLshort;
typedef signed char GLbyte;
typedef unsigned short GLushort;
#define GL_BLEND_EQUATION_RGB             0x8009
#define GL_VERTEX_ATTRIB_ARRAY_ENABLED    0x8622
#define GL_VERTEX_ATTRIB_ARRAY_SIZE       0x8623
#define GL_VERTEX_ATTRIB_ARRAY_STRIDE     0x8624
#define GL_VERTEX_ATTRIB_ARRAY_TYPE       0x8625
#define GL_CURRENT_VERTEX_ATTRIB          0x8626
#define GL_VERTEX_PROGRAM_POINT_SIZE      0x8642
#define GL_VERTEX_ATTRIB_ARRAY_POINTER    0x8645
#define GL_STENCIL_BACK_FUNC              0x8800
#define GL_STENCIL_BACK_FAIL              0x8801
#define GL_STENCIL_BACK_PASS_DEPTH_FAIL   0x8802
#define GL_STENCIL_BACK_PASS_DEPTH_PASS   0x8803
#define GL_MAX_DRAW_BUFFERS               0x8824
#define GL_DRAW_BUFFER0                   0x8825
#define GL_DRAW_BUFFER1                   0x8826
#define GL_DRAW_BUFFER2                   0x8827
#define GL_DRAW_BUFFER3                   0x8828
#define GL_DRAW_BUFFER4                   0x8829
#define GL_DRAW_BUFFER5                   0x882A
#define GL_DRAW_BUFFER6                   0x882B
#define GL_DRAW_BUFFER7                   0x882C
#define GL_DRAW_BUFFER8                   0x882D
#define GL_DRAW_BUFFER9                   0x882E
#define GL_DRAW_BUFFER10                  0x882F
#define GL_DRAW_BUFFER11                  0x8830
#define GL_DRAW_BUFFER12                  0x8831
#define GL_DRAW_BUFFER13                  0x8832
#define GL_DRAW_BUFFER14                  0x8833
#define GL_DRAW_BUFFER15                  0x8834
#define GL_BLEND_EQUATION_ALPHA           0x883D
#define GL_MAX_VERTEX_ATTRIBS             0x8869
#define GL_VERTEX_ATTRIB_ARRAY_NORMALIZED 0x886A
#define GL_MAX_TEXTURE_IMAGE_UNITS        0x8872
#define GL_FRAGMENT_SHADER                0x8B30
#define GL_VERTEX_SHADER                  0x8B31
#define GL_MAX_FRAGMENT_UNIFORM_COMPONENTS 0x8B49
#define GL_MAX_VERTEX_UNIFORM_COMPONENTS  0x8B4A
#define GL_MAX_VARYING_FLOATS             0x8B4B
#define GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS 0x8B4C
#define GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS 0x8B4D
#define GL_SHADER_TYPE                    0x8B4F
#define GL_FLOAT_VEC2                     0x8B50
#define GL_FLOAT_VEC3                     0x8B51
#define GL_FLOAT_VEC4                     0x8B52
#define GL_INT_VEC2                       0x8B53
#define GL_INT_VEC3                       0x8B54
#define GL_INT_VEC4                       0x8B55
#define GL_BOOL                           0x8B56
#define GL_BOOL_VEC2                      0x8B57
#define GL_BOOL_VEC3                      0x8B58
#define GL_BOOL_VEC4                      0x8B59
#define GL_FLOAT_MAT2                     0x8B5A
#define GL_FLOAT_MAT3                     0x8B5B
#define GL_FLOAT_MAT4                     0x8B5C
#define GL_SAMPLER_1D                     0x8B5D
#define GL_SAMPLER_2D                     0x8B5E
#define GL_SAMPLER_3D                     0x8B5F
#define GL_SAMPLER_CUBE                   0x8B60
#define GL_SAMPLER_1D_SHADOW              0x8B61
#define GL_SAMPLER_2D_SHADOW              0x8B62
#define GL_DELETE_STATUS                  0x8B80
#define GL_COMPILE_STATUS                 0x8B81
#define GL_LINK_STATUS                    0x8B82
#define GL_VALIDATE_STATUS                0x8B83
#define GL_INFO_LOG_LENGTH                0x8B84
#define GL_ATTACHED_SHADERS               0x8B85
#define GL_ACTIVE_UNIFORMS                0x8B86
#define GL_ACTIVE_UNIFORM_MAX_LENGTH      0x8B87
#define GL_SHADER_SOURCE_LENGTH           0x8B88
#define GL_ACTIVE_ATTRIBUTES              0x8B89
#define GL_ACTIVE_ATTRIBUTE_MAX_LENGTH    0x8B8A
#define GL_FRAGMENT_SHADER_DERIVATIVE_HINT 0x8B8B
#define GL_SHADING_LANGUAGE_VERSION       0x8B8C
#define GL_CURRENT_PROGRAM                0x8B8D
#define GL_POINT_SPRITE_COORD_ORIGIN      0x8CA0
#define GL_LOWER_LEFT                     0x8CA1
#define GL_UPPER_LEFT                     0x8CA2
#define GL_STENCIL_BACK_REF               0x8CA3
#define GL_STENCIL_BACK_VALUE_MASK        0x8CA4
#define GL_STENCIL_BACK_WRITEMASK         0x8CA5
typedef void (APIENTRYP PFNGLBLENDEQUATIONSEPARATEPROC) (GLenum modeRGB, GLenum modeAlpha);
typedef void (APIENTRYP PFNGLDRAWBUFFERSPROC) (GLsizei n, const GLenum *bufs);
typedef void (APIENTRYP PFNGLSTENCILOPSEPARATEPROC) (GLenum face, GLenum sfail, GLenum dpfail, GLenum dppass);
typedef void (APIENTRYP PFNGLSTENCILFUNCSEPARATEPROC) (GLenum face, GLenum func, GLint ref, GLuint mask);
typedef void (APIENTRYP PFNGLSTENCILMASKSEPARATEPROC) (GLenum face, GLuint mask);
typedef void (APIENTRYP PFNGLATTACHSHADERPROC) (GLuint program, GLuint shader);
typedef void (APIENTRYP PFNGLBINDATTRIBLOCATIONPROC) (GLuint program, GLuint index, const GLchar *name);
typedef void (APIENTRYP PFNGLCOMPILESHADERPROC) (GLuint shader);
typedef GLuint (APIENTRYP PFNGLCREATEPROGRAMPROC) (void);
typedef GLuint (APIENTRYP PFNGLCREATESHADERPROC) (GLenum type);
typedef void (APIENTRYP PFNGLDELETEPROGRAMPROC) (GLuint program);
typedef void (APIENTRYP PFNGLDELETESHADERPROC) (GLuint shader);
typedef void (APIENTRYP PFNGLDETACHSHADERPROC) (GLuint program, GLuint shader);
typedef void (APIENTRYP PFNGLDISABLEVERTEXATTRIBARRAYPROC) (GLuint index);
typedef void (APIENTRYP PFNGLENABLEVERTEXATTRIBARRAYPROC) (GLuint index);
typedef void (APIENTRYP PFNGLGETACTIVEATTRIBPROC) (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
typedef void (APIENTRYP PFNGLGETACTIVEUNIFORMPROC) (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
typedef void (APIENTRYP PFNGLGETATTACHEDSHADERSPROC) (GLuint program, GLsizei maxCount, GLsizei *count, GLuint *shaders);
typedef GLint (APIENTRYP PFNGLGETATTRIBLOCATIONPROC) (GLuint program, const GLchar *name);
typedef void (APIENTRYP PFNGLGETPROGRAMIVPROC) (GLuint program, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETPROGRAMINFOLOGPROC) (GLuint program, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
typedef void (APIENTRYP PFNGLGETSHADERIVPROC) (GLuint shader, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETSHADERINFOLOGPROC) (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
typedef void (APIENTRYP PFNGLGETSHADERSOURCEPROC) (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *source);
typedef GLint (APIENTRYP PFNGLGETUNIFORMLOCATIONPROC) (GLuint program, const GLchar *name);
typedef void (APIENTRYP PFNGLGETUNIFORMFVPROC) (GLuint program, GLint location, GLfloat *params);
typedef void (APIENTRYP PFNGLGETUNIFORMIVPROC) (GLuint program, GLint location, GLint *params);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBDVPROC) (GLuint index, GLenum pname, GLdouble *params);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBFVPROC) (GLuint index, GLenum pname, GLfloat *params);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBIVPROC) (GLuint index, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBPOINTERVPROC) (GLuint index, GLenum pname, void **pointer);
typedef GLboolean (APIENTRYP PFNGLISPROGRAMPROC) (GLuint program);
typedef GLboolean (APIENTRYP PFNGLISSHADERPROC) (GLuint shader);
typedef void (APIENTRYP PFNGLLINKPROGRAMPROC) (GLuint program);
typedef void (APIENTRYP PFNGLSHADERSOURCEPROC) (GLuint shader, GLsizei count, const GLchar *const*string, const GLint *length);
typedef void (APIENTRYP PFNGLUSEPROGRAMPROC) (GLuint program);
typedef void (APIENTRYP PFNGLUNIFORM1FPROC) (GLint location, GLfloat v0);
typedef void (APIENTRYP PFNGLUNIFORM2FPROC) (GLint location, GLfloat v0, GLfloat v1);
typedef void (APIENTRYP PFNGLUNIFORM3FPROC) (GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
typedef void (APIENTRYP PFNGLUNIFORM4FPROC) (GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
typedef void (APIENTRYP PFNGLUNIFORM1IPROC) (GLint location, GLint v0);
typedef void (APIENTRYP PFNGLUNIFORM2IPROC) (GLint location, GLint v0, GLint v1);
typedef void (APIENTRYP PFNGLUNIFORM3IPROC) (GLint location, GLint v0, GLint v1, GLint v2);
typedef void (APIENTRYP PFNGLUNIFORM4IPROC) (GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
typedef void (APIENTRYP PFNGLUNIFORM1FVPROC) (GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORM2FVPROC) (GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORM3FVPROC) (GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORM4FVPROC) (GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORM1IVPROC) (GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLUNIFORM2IVPROC) (GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLUNIFORM3IVPROC) (GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLUNIFORM4IVPROC) (GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLVALIDATEPROGRAMPROC) (GLuint program);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1DPROC) (GLuint index, GLdouble x);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1FPROC) (GLuint index, GLfloat x);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1FVPROC) (GLuint index, const GLfloat *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1SPROC) (GLuint index, GLshort x);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1SVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2DPROC) (GLuint index, GLdouble x, GLdouble y);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2FPROC) (GLuint index, GLfloat x, GLfloat y);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2FVPROC) (GLuint index, const GLfloat *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2SPROC) (GLuint index, GLshort x, GLshort y);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2SVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3FPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat z);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3FVPROC) (GLuint index, const GLfloat *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3SPROC) (GLuint index, GLshort x, GLshort y, GLshort z);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3SVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NBVPROC) (GLuint index, const GLbyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NIVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NSVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NUBPROC) (GLuint index, GLubyte x, GLubyte y, GLubyte z, GLubyte w);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NUBVPROC) (GLuint index, const GLubyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NUIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NUSVPROC) (GLuint index, const GLushort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4BVPROC) (GLuint index, const GLbyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4FPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4FVPROC) (GLuint index, const GLfloat *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4IVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4SPROC) (GLuint index, GLshort x, GLshort y, GLshort z, GLshort w);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4SVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4UBVPROC) (GLuint index, const GLubyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4UIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4USVPROC) (GLuint index, const GLushort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBPOINTERPROC) (GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const void *pointer);

#define GL_PIXEL_PACK_BUFFER              0x88EB
#define GL_PIXEL_UNPACK_BUFFER            0x88EC
#define GL_PIXEL_PACK_BUFFER_BINDING      0x88ED
#define GL_PIXEL_UNPACK_BUFFER_BINDING    0x88EF
#define GL_FLOAT_MAT2x3                   0x8B65
#define GL_FLOAT_MAT2x4                   0x8B66
#define GL_FLOAT_MAT3x2                   0x8B67
#define GL_FLOAT_MAT3x4                   0x8B68
#define GL_FLOAT_MAT4x2                   0x8B69
#define GL_FLOAT_MAT4x3                   0x8B6A
#define GL_SRGB                           0x8C40
#define GL_SRGB8                          0x8C41
#define GL_SRGB_ALPHA                     0x8C42
#define GL_SRGB8_ALPHA8                   0x8C43
#define GL_COMPRESSED_SRGB                0x8C48
#define GL_COMPRESSED_SRGB_ALPHA          0x8C49
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2X3FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3X2FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2X4FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4X2FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3X4FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4X3FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

typedef unsigned short GLhalf;
#define GL_COMPARE_REF_TO_TEXTURE         0x884E
#define GL_CLIP_DISTANCE0                 0x3000
#define GL_CLIP_DISTANCE1                 0x3001
#define GL_CLIP_DISTANCE2                 0x3002
#define GL_CLIP_DISTANCE3                 0x3003
#define GL_CLIP_DISTANCE4                 0x3004
#define GL_CLIP_DISTANCE5                 0x3005
#define GL_CLIP_DISTANCE6                 0x3006
#define GL_CLIP_DISTANCE7                 0x3007
#define GL_MAX_CLIP_DISTANCES             0x0D32
#define GL_MAJOR_VERSION                  0x821B
#define GL_MINOR_VERSION                  0x821C
#define GL_NUM_EXTENSIONS                 0x821D
#define GL_CONTEXT_FLAGS                  0x821E
#define GL_COMPRESSED_RED                 0x8225
#define GL_COMPRESSED_RG                  0x8226
#define GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT 0x00000001
#define GL_RGBA32F                        0x8814
#define GL_RGB32F                         0x8815
#define GL_RGBA16F                        0x881A
#define GL_RGB16F                         0x881B
#define GL_VERTEX_ATTRIB_ARRAY_INTEGER    0x88FD
#define GL_MAX_ARRAY_TEXTURE_LAYERS       0x88FF
#define GL_MIN_PROGRAM_TEXEL_OFFSET       0x8904
#define GL_MAX_PROGRAM_TEXEL_OFFSET       0x8905
#define GL_CLAMP_READ_COLOR               0x891C
#define GL_FIXED_ONLY                     0x891D
#define GL_MAX_VARYING_COMPONENTS         0x8B4B
#define GL_TEXTURE_1D_ARRAY               0x8C18
#define GL_PROXY_TEXTURE_1D_ARRAY         0x8C19
#define GL_TEXTURE_2D_ARRAY               0x8C1A
#define GL_PROXY_TEXTURE_2D_ARRAY         0x8C1B
#define GL_TEXTURE_BINDING_1D_ARRAY       0x8C1C
#define GL_TEXTURE_BINDING_2D_ARRAY       0x8C1D
#define GL_R11F_G11F_B10F                 0x8C3A
#define GL_UNSIGNED_INT_10F_11F_11F_REV   0x8C3B
#define GL_RGB9_E5                        0x8C3D
#define GL_UNSIGNED_INT_5_9_9_9_REV       0x8C3E
#define GL_TEXTURE_SHARED_SIZE            0x8C3F
#define GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH 0x8C76
#define GL_TRANSFORM_FEEDBACK_BUFFER_MODE 0x8C7F
#define GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS 0x8C80
#define GL_TRANSFORM_FEEDBACK_VARYINGS    0x8C83
#define GL_TRANSFORM_FEEDBACK_BUFFER_START 0x8C84
#define GL_TRANSFORM_FEEDBACK_BUFFER_SIZE 0x8C85
#define GL_PRIMITIVES_GENERATED           0x8C87
#define GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN 0x8C88
#define GL_RASTERIZER_DISCARD             0x8C89
#define GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS 0x8C8A
#define GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS 0x8C8B
#define GL_INTERLEAVED_ATTRIBS            0x8C8C
#define GL_SEPARATE_ATTRIBS               0x8C8D
#define GL_TRANSFORM_FEEDBACK_BUFFER      0x8C8E
#define GL_TRANSFORM_FEEDBACK_BUFFER_BINDING 0x8C8F
#define GL_RGBA32UI                       0x8D70
#define GL_RGB32UI                        0x8D71
#define GL_RGBA16UI                       0x8D76
#define GL_RGB16UI                        0x8D77
#define GL_RGBA8UI                        0x8D7C
#define GL_RGB8UI                         0x8D7D
#define GL_RGBA32I                        0x8D82
#define GL_RGB32I                         0x8D83
#define GL_RGBA16I                        0x8D88
#define GL_RGB16I                         0x8D89
#define GL_RGBA8I                         0x8D8E
#define GL_RGB8I                          0x8D8F
#define GL_RED_INTEGER                    0x8D94
#define GL_GREEN_INTEGER                  0x8D95
#define GL_BLUE_INTEGER                   0x8D96
#define GL_RGB_INTEGER                    0x8D98
#define GL_RGBA_INTEGER                   0x8D99
#define GL_BGR_INTEGER                    0x8D9A
#define GL_BGRA_INTEGER                   0x8D9B
#define GL_SAMPLER_1D_ARRAY               0x8DC0
#define GL_SAMPLER_2D_ARRAY               0x8DC1
#define GL_SAMPLER_1D_ARRAY_SHADOW        0x8DC3
#define GL_SAMPLER_2D_ARRAY_SHADOW        0x8DC4
#define GL_SAMPLER_CUBE_SHADOW            0x8DC5
#define GL_UNSIGNED_INT_VEC2              0x8DC6
#define GL_UNSIGNED_INT_VEC3              0x8DC7
#define GL_UNSIGNED_INT_VEC4              0x8DC8
#define GL_INT_SAMPLER_1D                 0x8DC9
#define GL_INT_SAMPLER_2D                 0x8DCA
#define GL_INT_SAMPLER_3D                 0x8DCB
#define GL_INT_SAMPLER_CUBE               0x8DCC
#define GL_INT_SAMPLER_1D_ARRAY           0x8DCE
#define GL_INT_SAMPLER_2D_ARRAY           0x8DCF
#define GL_UNSIGNED_INT_SAMPLER_1D        0x8DD1
#define GL_UNSIGNED_INT_SAMPLER_2D        0x8DD2
#define GL_UNSIGNED_INT_SAMPLER_3D        0x8DD3
#define GL_UNSIGNED_INT_SAMPLER_CUBE      0x8DD4
#define GL_UNSIGNED_INT_SAMPLER_1D_ARRAY  0x8DD6
#define GL_UNSIGNED_INT_SAMPLER_2D_ARRAY  0x8DD7
#define GL_QUERY_WAIT                     0x8E13
#define GL_QUERY_NO_WAIT                  0x8E14
#define GL_QUERY_BY_REGION_WAIT           0x8E15
#define GL_QUERY_BY_REGION_NO_WAIT        0x8E16
#define GL_BUFFER_ACCESS_FLAGS            0x911F
#define GL_BUFFER_MAP_LENGTH              0x9120
#define GL_BUFFER_MAP_OFFSET              0x9121
#define GL_DEPTH_COMPONENT32F             0x8CAC
#define GL_DEPTH32F_STENCIL8              0x8CAD
#define GL_FLOAT_32_UNSIGNED_INT_24_8_REV 0x8DAD
#define GL_INVALID_FRAMEBUFFER_OPERATION  0x0506
#define GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING 0x8210
#define GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE 0x8211
#define GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE 0x8212
#define GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE 0x8213
#define GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE 0x8214
#define GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE 0x8215
#define GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE 0x8216
#define GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE 0x8217
#define GL_FRAMEBUFFER_DEFAULT            0x8218
#define GL_FRAMEBUFFER_UNDEFINED          0x8219
#define GL_DEPTH_STENCIL_ATTACHMENT       0x821A
#define GL_MAX_RENDERBUFFER_SIZE          0x84E8
#define GL_DEPTH_STENCIL                  0x84F9
#define GL_UNSIGNED_INT_24_8              0x84FA
#define GL_DEPTH24_STENCIL8               0x88F0
#define GL_TEXTURE_STENCIL_SIZE           0x88F1
#define GL_TEXTURE_RED_TYPE               0x8C10
#define GL_TEXTURE_GREEN_TYPE             0x8C11
#define GL_TEXTURE_BLUE_TYPE              0x8C12
#define GL_TEXTURE_ALPHA_TYPE             0x8C13
#define GL_TEXTURE_DEPTH_TYPE             0x8C16
#define GL_UNSIGNED_NORMALIZED            0x8C17
#define GL_FRAMEBUFFER_BINDING            0x8CA6
#define GL_DRAW_FRAMEBUFFER_BINDING       0x8CA6
#define GL_RENDERBUFFER_BINDING           0x8CA7
#define GL_READ_FRAMEBUFFER               0x8CA8
#define GL_DRAW_FRAMEBUFFER               0x8CA9
#define GL_READ_FRAMEBUFFER_BINDING       0x8CAA
#define GL_RENDERBUFFER_SAMPLES           0x8CAB
#define GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE 0x8CD0
#define GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME 0x8CD1
#define GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL 0x8CD2
#define GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE 0x8CD3
#define GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER 0x8CD4
#define GL_FRAMEBUFFER_COMPLETE           0x8CD5
#define GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT 0x8CD6
#define GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT 0x8CD7
#define GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER 0x8CDB
#define GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER 0x8CDC
#define GL_FRAMEBUFFER_UNSUPPORTED        0x8CDD
#define GL_MAX_COLOR_ATTACHMENTS          0x8CDF
#define GL_COLOR_ATTACHMENT0              0x8CE0
#define GL_COLOR_ATTACHMENT1              0x8CE1
#define GL_COLOR_ATTACHMENT2              0x8CE2
#define GL_COLOR_ATTACHMENT3              0x8CE3
#define GL_COLOR_ATTACHMENT4              0x8CE4
#define GL_COLOR_ATTACHMENT5              0x8CE5
#define GL_COLOR_ATTACHMENT6              0x8CE6
#define GL_COLOR_ATTACHMENT7              0x8CE7
#define GL_COLOR_ATTACHMENT8              0x8CE8
#define GL_COLOR_ATTACHMENT9              0x8CE9
#define GL_COLOR_ATTACHMENT10             0x8CEA
#define GL_COLOR_ATTACHMENT11             0x8CEB
#define GL_COLOR_ATTACHMENT12             0x8CEC
#define GL_COLOR_ATTACHMENT13             0x8CED
#define GL_COLOR_ATTACHMENT14             0x8CEE
#define GL_COLOR_ATTACHMENT15             0x8CEF
#define GL_DEPTH_ATTACHMENT               0x8D00
#define GL_STENCIL_ATTACHMENT             0x8D20
#define GL_FRAMEBUFFER                    0x8D40
#define GL_RENDERBUFFER                   0x8D41
#define GL_RENDERBUFFER_WIDTH             0x8D42
#define GL_RENDERBUFFER_HEIGHT            0x8D43
#define GL_RENDERBUFFER_INTERNAL_FORMAT   0x8D44
#define GL_STENCIL_INDEX1                 0x8D46
#define GL_STENCIL_INDEX4                 0x8D47
#define GL_STENCIL_INDEX8                 0x8D48
#define GL_STENCIL_INDEX16                0x8D49
#define GL_RENDERBUFFER_RED_SIZE          0x8D50
#define GL_RENDERBUFFER_GREEN_SIZE        0x8D51
#define GL_RENDERBUFFER_BLUE_SIZE         0x8D52
#define GL_RENDERBUFFER_ALPHA_SIZE        0x8D53
#define GL_RENDERBUFFER_DEPTH_SIZE        0x8D54
#define GL_RENDERBUFFER_STENCIL_SIZE      0x8D55
#define GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE 0x8D56
#define GL_MAX_SAMPLES                    0x8D57
#define GL_FRAMEBUFFER_SRGB               0x8DB9
#define GL_HALF_FLOAT                     0x140B
#define GL_MAP_READ_BIT                   0x0001
#define GL_MAP_WRITE_BIT                  0x0002
#define GL_MAP_INVALIDATE_RANGE_BIT       0x0004
#define GL_MAP_INVALIDATE_BUFFER_BIT      0x0008
#define GL_MAP_FLUSH_EXPLICIT_BIT         0x0010
#define GL_MAP_UNSYNCHRONIZED_BIT         0x0020
#define GL_COMPRESSED_RED_RGTC1           0x8DBB
#define GL_COMPRESSED_SIGNED_RED_RGTC1    0x8DBC
#define GL_COMPRESSED_RG_RGTC2            0x8DBD
#define GL_COMPRESSED_SIGNED_RG_RGTC2     0x8DBE
#define GL_RG                             0x8227
#define GL_RG_INTEGER                     0x8228
#define GL_R8                             0x8229
#define GL_R16                            0x822A
#define GL_RG8                            0x822B
#define GL_RG16                           0x822C
#define GL_R16F                           0x822D
#define GL_R32F                           0x822E
#define GL_RG16F                          0x822F
#define GL_RG32F                          0x8230
#define GL_R8I                            0x8231
#define GL_R8UI                           0x8232
#define GL_R16I                           0x8233
#define GL_R16UI                          0x8234
#define GL_R32I                           0x8235
#define GL_R32UI                          0x8236
#define GL_RG8I                           0x8237
#define GL_RG8UI                          0x8238
#define GL_RG16I                          0x8239
#define GL_RG16UI                         0x823A
#define GL_RG32I                          0x823B
#define GL_RG32UI                         0x823C
#define GL_VERTEX_ARRAY_BINDING           0x85B5
typedef void (APIENTRYP PFNGLCOLORMASKIPROC) (GLuint index, GLboolean r, GLboolean g, GLboolean b, GLboolean a);
typedef void (APIENTRYP PFNGLGETBOOLEANI_VPROC) (GLenum target, GLuint index, GLboolean *data);
typedef void (APIENTRYP PFNGLGETINTEGERI_VPROC) (GLenum target, GLuint index, GLint *data);
typedef void (APIENTRYP PFNGLENABLEIPROC) (GLenum target, GLuint index);
typedef void (APIENTRYP PFNGLDISABLEIPROC) (GLenum target, GLuint index);
typedef GLboolean (APIENTRYP PFNGLISENABLEDIPROC) (GLenum target, GLuint index);
typedef void (APIENTRYP PFNGLBEGINTRANSFORMFEEDBACKPROC) (GLenum primitiveMode);
typedef void (APIENTRYP PFNGLENDTRANSFORMFEEDBACKPROC) (void);
typedef void (APIENTRYP PFNGLBINDBUFFERRANGEPROC) (GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);
typedef void (APIENTRYP PFNGLBINDBUFFERBASEPROC) (GLenum target, GLuint index, GLuint buffer);
typedef void (APIENTRYP PFNGLTRANSFORMFEEDBACKVARYINGSPROC) (GLuint program, GLsizei count, const GLchar *const*varyings, GLenum bufferMode);
typedef void (APIENTRYP PFNGLGETTRANSFORMFEEDBACKVARYINGPROC) (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLsizei *size, GLenum *type, GLchar *name);
typedef void (APIENTRYP PFNGLCLAMPCOLORPROC) (GLenum target, GLenum clamp);
typedef void (APIENTRYP PFNGLBEGINCONDITIONALRENDERPROC) (GLuint id, GLenum mode);
typedef void (APIENTRYP PFNGLENDCONDITIONALRENDERPROC) (void);
typedef void (APIENTRYP PFNGLVERTEXATTRIBIPOINTERPROC) (GLuint index, GLint size, GLenum type, GLsizei stride, const void *pointer);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBIIVPROC) (GLuint index, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBIUIVPROC) (GLuint index, GLenum pname, GLuint *params);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI1IPROC) (GLuint index, GLint x);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI2IPROC) (GLuint index, GLint x, GLint y);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI3IPROC) (GLuint index, GLint x, GLint y, GLint z);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4IPROC) (GLuint index, GLint x, GLint y, GLint z, GLint w);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI1UIPROC) (GLuint index, GLuint x);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI2UIPROC) (GLuint index, GLuint x, GLuint y);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI3UIPROC) (GLuint index, GLuint x, GLuint y, GLuint z);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4UIPROC) (GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI1IVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI2IVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI3IVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4IVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI1UIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI2UIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI3UIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4UIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4BVPROC) (GLuint index, const GLbyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4SVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4UBVPROC) (GLuint index, const GLubyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4USVPROC) (GLuint index, const GLushort *v);
typedef void (APIENTRYP PFNGLGETUNIFORMUIVPROC) (GLuint program, GLint location, GLuint *params);
typedef void (APIENTRYP PFNGLBINDFRAGDATALOCATIONPROC) (GLuint program, GLuint color, const GLchar *name);
typedef GLint (APIENTRYP PFNGLGETFRAGDATALOCATIONPROC) (GLuint program, const GLchar *name);
typedef void (APIENTRYP PFNGLUNIFORM1UIPROC) (GLint location, GLuint v0);
typedef void (APIENTRYP PFNGLUNIFORM2UIPROC) (GLint location, GLuint v0, GLuint v1);
typedef void (APIENTRYP PFNGLUNIFORM3UIPROC) (GLint location, GLuint v0, GLuint v1, GLuint v2);
typedef void (APIENTRYP PFNGLUNIFORM4UIPROC) (GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
typedef void (APIENTRYP PFNGLUNIFORM1UIVPROC) (GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLUNIFORM2UIVPROC) (GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLUNIFORM3UIVPROC) (GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLUNIFORM4UIVPROC) (GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLTEXPARAMETERIIVPROC) (GLenum target, GLenum pname, const GLint *params);
typedef void (APIENTRYP PFNGLTEXPARAMETERIUIVPROC) (GLenum target, GLenum pname, const GLuint *params);
typedef void (APIENTRYP PFNGLGETTEXPARAMETERIIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETTEXPARAMETERIUIVPROC) (GLenum target, GLenum pname, GLuint *params);
typedef void (APIENTRYP PFNGLCLEARBUFFERIVPROC) (GLenum buffer, GLint drawbuffer, const GLint *value);
typedef void (APIENTRYP PFNGLCLEARBUFFERUIVPROC) (GLenum buffer, GLint drawbuffer, const GLuint *value);
typedef void (APIENTRYP PFNGLCLEARBUFFERFVPROC) (GLenum buffer, GLint drawbuffer, const GLfloat *value);
typedef void (APIENTRYP PFNGLCLEARBUFFERFIPROC) (GLenum buffer, GLint drawbuffer, GLfloat depth, GLint stencil);
typedef const GLubyte *(APIENTRYP PFNGLGETSTRINGIPROC) (GLenum name, GLuint index);
typedef GLboolean (APIENTRYP PFNGLISRENDERBUFFERPROC) (GLuint renderbuffer);
typedef void (APIENTRYP PFNGLBINDRENDERBUFFERPROC) (GLenum target, GLuint renderbuffer);
typedef void (APIENTRYP PFNGLDELETERENDERBUFFERSPROC) (GLsizei n, const GLuint *renderbuffers);
typedef void (APIENTRYP PFNGLGENRENDERBUFFERSPROC) (GLsizei n, GLuint *renderbuffers);
typedef void (APIENTRYP PFNGLRENDERBUFFERSTORAGEPROC) (GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLGETRENDERBUFFERPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef GLboolean (APIENTRYP PFNGLISFRAMEBUFFERPROC) (GLuint framebuffer);
typedef void (APIENTRYP PFNGLBINDFRAMEBUFFERPROC) (GLenum target, GLuint framebuffer);
typedef void (APIENTRYP PFNGLDELETEFRAMEBUFFERSPROC) (GLsizei n, const GLuint *framebuffers);
typedef void (APIENTRYP PFNGLGENFRAMEBUFFERSPROC) (GLsizei n, GLuint *framebuffers);
typedef GLenum (APIENTRYP PFNGLCHECKFRAMEBUFFERSTATUSPROC) (GLenum target);
typedef void (APIENTRYP PFNGLFRAMEBUFFERTEXTURE1DPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
typedef void (APIENTRYP PFNGLFRAMEBUFFERTEXTURE2DPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
typedef void (APIENTRYP PFNGLFRAMEBUFFERTEXTURE3DPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level, GLint zoffset);
typedef void (APIENTRYP PFNGLFRAMEBUFFERRENDERBUFFERPROC) (GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);
typedef void (APIENTRYP PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVPROC) (GLenum target, GLenum attachment, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGENERATEMIPMAPPROC) (GLenum target);
typedef void (APIENTRYP PFNGLBLITFRAMEBUFFERPROC) (GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
typedef void (APIENTRYP PFNGLRENDERBUFFERSTORAGEMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLFRAMEBUFFERTEXTURELAYERPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer);
typedef void *(APIENTRYP PFNGLMAPBUFFERRANGEPROC) (GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access);
typedef void (APIENTRYP PFNGLFLUSHMAPPEDBUFFERRANGEPROC) (GLenum target, GLintptr offset, GLsizeiptr length);
typedef void (APIENTRYP PFNGLBINDVERTEXARRAYPROC) (GLuint array);
typedef void (APIENTRYP PFNGLDELETEVERTEXARRAYSPROC) (GLsizei n, const GLuint *arrays);
typedef void (APIENTRYP PFNGLGENVERTEXARRAYSPROC) (GLsizei n, GLuint *arrays);
typedef GLboolean (APIENTRYP PFNGLISVERTEXARRAYPROC) (GLuint array);

#define GL_SAMPLER_2D_RECT                0x8B63
#define GL_SAMPLER_2D_RECT_SHADOW         0x8B64
#define GL_SAMPLER_BUFFER                 0x8DC2
#define GL_INT_SAMPLER_2D_RECT            0x8DCD
#define GL_INT_SAMPLER_BUFFER             0x8DD0
#define GL_UNSIGNED_INT_SAMPLER_2D_RECT   0x8DD5
#define GL_UNSIGNED_INT_SAMPLER_BUFFER    0x8DD8
#define GL_TEXTURE_BUFFER                 0x8C2A
#define GL_MAX_TEXTURE_BUFFER_SIZE        0x8C2B
#define GL_TEXTURE_BINDING_BUFFER         0x8C2C
#define GL_TEXTURE_BUFFER_DATA_STORE_BINDING 0x8C2D
#define GL_TEXTURE_RECTANGLE              0x84F5
#define GL_TEXTURE_BINDING_RECTANGLE      0x84F6
#define GL_PROXY_TEXTURE_RECTANGLE        0x84F7
#define GL_MAX_RECTANGLE_TEXTURE_SIZE     0x84F8
#define GL_R8_SNORM                       0x8F94
#define GL_RG8_SNORM                      0x8F95
#define GL_RGB8_SNORM                     0x8F96
#define GL_RGBA8_SNORM                    0x8F97
#define GL_R16_SNORM                      0x8F98
#define GL_RG16_SNORM                     0x8F99
#define GL_RGB16_SNORM                    0x8F9A
#define GL_RGBA16_SNORM                   0x8F9B
#define GL_SIGNED_NORMALIZED              0x8F9C
#define GL_PRIMITIVE_RESTART              0x8F9D
#define GL_PRIMITIVE_RESTART_INDEX        0x8F9E
#define GL_COPY_READ_BUFFER               0x8F36
#define GL_COPY_WRITE_BUFFER              0x8F37
#define GL_UNIFORM_BUFFER                 0x8A11
#define GL_UNIFORM_BUFFER_BINDING         0x8A28
#define GL_UNIFORM_BUFFER_START           0x8A29
#define GL_UNIFORM_BUFFER_SIZE            0x8A2A
#define GL_MAX_VERTEX_UNIFORM_BLOCKS      0x8A2B
#define GL_MAX_FRAGMENT_UNIFORM_BLOCKS    0x8A2D
#define GL_MAX_COMBINED_UNIFORM_BLOCKS    0x8A2E
#define GL_MAX_UNIFORM_BUFFER_BINDINGS    0x8A2F
#define GL_MAX_UNIFORM_BLOCK_SIZE         0x8A30
#define GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS 0x8A31
#define GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS 0x8A33
#define GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT 0x8A34
#define GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH 0x8A35
#define GL_ACTIVE_UNIFORM_BLOCKS          0x8A36
#define GL_UNIFORM_TYPE                   0x8A37
#define GL_UNIFORM_SIZE                   0x8A38
#define GL_UNIFORM_NAME_LENGTH            0x8A39
#define GL_UNIFORM_BLOCK_INDEX            0x8A3A
#define GL_UNIFORM_OFFSET                 0x8A3B
#define GL_UNIFORM_ARRAY_STRIDE           0x8A3C
#define GL_UNIFORM_MATRIX_STRIDE          0x8A3D
#define GL_UNIFORM_IS_ROW_MAJOR           0x8A3E
#define GL_UNIFORM_BLOCK_BINDING          0x8A3F
#define GL_UNIFORM_BLOCK_DATA_SIZE        0x8A40
#define GL_UNIFORM_BLOCK_NAME_LENGTH      0x8A41
#define GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS  0x8A42
#define GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES 0x8A43
#define GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER 0x8A44
#define GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER 0x8A46
#define GL_INVALID_INDEX                  0xFFFFFFFFu
typedef void (APIENTRYP PFNGLDRAWARRAYSINSTANCEDPROC) (GLenum mode, GLint first, GLsizei count, GLsizei instancecount);
typedef void (APIENTRYP PFNGLDRAWELEMENTSINSTANCEDPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount);
typedef void (APIENTRYP PFNGLTEXBUFFERPROC) (GLenum target, GLenum internalformat, GLuint buffer);
typedef void (APIENTRYP PFNGLPRIMITIVERESTARTINDEXPROC) (GLuint index);
typedef void (APIENTRYP PFNGLCOPYBUFFERSUBDATAPROC) (GLenum readTarget, GLenum writeTarget, GLintptr readOffset, GLintptr writeOffset, GLsizeiptr size);
typedef void (APIENTRYP PFNGLGETUNIFORMINDICESPROC) (GLuint program, GLsizei uniformCount, const GLchar *const*uniformNames, GLuint *uniformIndices);
typedef void (APIENTRYP PFNGLGETACTIVEUNIFORMSIVPROC) (GLuint program, GLsizei uniformCount, const GLuint *uniformIndices, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETACTIVEUNIFORMNAMEPROC) (GLuint program, GLuint uniformIndex, GLsizei bufSize, GLsizei *length, GLchar *uniformName);
typedef GLuint (APIENTRYP PFNGLGETUNIFORMBLOCKINDEXPROC) (GLuint program, const GLchar *uniformBlockName);
typedef void (APIENTRYP PFNGLGETACTIVEUNIFORMBLOCKIVPROC) (GLuint program, GLuint uniformBlockIndex, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETACTIVEUNIFORMBLOCKNAMEPROC) (GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, GLsizei *length, GLchar *uniformBlockName);
typedef void (APIENTRYP PFNGLUNIFORMBLOCKBINDINGPROC) (GLuint program, GLuint uniformBlockIndex, GLuint uniformBlockBinding);

typedef struct __GLsync *GLsync;
typedef uint64_t GLuint64;
typedef int64_t GLint64;
#define GL_CONTEXT_CORE_PROFILE_BIT       0x00000001
#define GL_CONTEXT_COMPATIBILITY_PROFILE_BIT 0x00000002
#define GL_LINES_ADJACENCY                0x000A
#define GL_LINE_STRIP_ADJACENCY           0x000B
#define GL_TRIANGLES_ADJACENCY            0x000C
#define GL_TRIANGLE_STRIP_ADJACENCY       0x000D
#define GL_PROGRAM_POINT_SIZE             0x8642
#define GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS 0x8C29
#define GL_FRAMEBUFFER_ATTACHMENT_LAYERED 0x8DA7
#define GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS 0x8DA8
#define GL_GEOMETRY_SHADER                0x8DD9
#define GL_GEOMETRY_VERTICES_OUT          0x8916
#define GL_GEOMETRY_INPUT_TYPE            0x8917
#define GL_GEOMETRY_OUTPUT_TYPE           0x8918
#define GL_MAX_GEOMETRY_UNIFORM_COMPONENTS 0x8DDF
#define GL_MAX_GEOMETRY_OUTPUT_VERTICES   0x8DE0
#define GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS 0x8DE1
#define GL_MAX_VERTEX_OUTPUT_COMPONENTS   0x9122
#define GL_MAX_GEOMETRY_INPUT_COMPONENTS  0x9123
#define GL_MAX_GEOMETRY_OUTPUT_COMPONENTS 0x9124
#define GL_MAX_FRAGMENT_INPUT_COMPONENTS  0x9125
#define GL_CONTEXT_PROFILE_MASK           0x9126
#define GL_DEPTH_CLAMP                    0x864F
#define GL_QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION 0x8E4C
#define GL_FIRST_VERTEX_CONVENTION        0x8E4D
#define GL_LAST_VERTEX_CONVENTION         0x8E4E
#define GL_PROVOKING_VERTEX               0x8E4F
#define GL_TEXTURE_CUBE_MAP_SEAMLESS      0x884F
#define GL_MAX_SERVER_WAIT_TIMEOUT        0x9111
#define GL_OBJECT_TYPE                    0x9112
#define GL_SYNC_CONDITION                 0x9113
#define GL_SYNC_STATUS                    0x9114
#define GL_SYNC_FLAGS                     0x9115
#define GL_SYNC_FENCE                     0x9116
#define GL_SYNC_GPU_COMMANDS_COMPLETE     0x9117
#define GL_UNSIGNALED                     0x9118
#define GL_SIGNALED                       0x9119
#define GL_ALREADY_SIGNALED               0x911A
#define GL_TIMEOUT_EXPIRED                0x911B
#define GL_CONDITION_SATISFIED            0x911C
#define GL_WAIT_FAILED                    0x911D
#define GL_TIMEOUT_IGNORED                0xFFFFFFFFFFFFFFFFull
#define GL_SYNC_FLUSH_COMMANDS_BIT        0x00000001
#define GL_SAMPLE_POSITION                0x8E50
#define GL_SAMPLE_MASK                    0x8E51
#define GL_SAMPLE_MASK_VALUE              0x8E52
#define GL_MAX_SAMPLE_MASK_WORDS          0x8E59
#define GL_TEXTURE_2D_MULTISAMPLE         0x9100
#define GL_PROXY_TEXTURE_2D_MULTISAMPLE   0x9101
#define GL_TEXTURE_2D_MULTISAMPLE_ARRAY   0x9102
#define GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY 0x9103
#define GL_TEXTURE_BINDING_2D_MULTISAMPLE 0x9104
#define GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY 0x9105
#define GL_TEXTURE_SAMPLES                0x9106
#define GL_TEXTURE_FIXED_SAMPLE_LOCATIONS 0x9107
#define GL_SAMPLER_2D_MULTISAMPLE         0x9108
#define GL_INT_SAMPLER_2D_MULTISAMPLE     0x9109
#define GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE 0x910A
#define GL_SAMPLER_2D_MULTISAMPLE_ARRAY   0x910B
#define GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY 0x910C
#define GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY 0x910D
#define GL_MAX_COLOR_TEXTURE_SAMPLES      0x910E
#define GL_MAX_DEPTH_TEXTURE_SAMPLES      0x910F
#define GL_MAX_INTEGER_SAMPLES            0x9110
typedef void (APIENTRYP PFNGLDRAWELEMENTSBASEVERTEXPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLint basevertex);
typedef void (APIENTRYP PFNGLDRAWRANGEELEMENTSBASEVERTEXPROC) (GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const void *indices, GLint basevertex);
typedef void (APIENTRYP PFNGLDRAWELEMENTSINSTANCEDBASEVERTEXPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount, GLint basevertex);
typedef void (APIENTRYP PFNGLMULTIDRAWELEMENTSBASEVERTEXPROC) (GLenum mode, const GLsizei *count, GLenum type, const void *const*indices, GLsizei drawcount, const GLint *basevertex);
typedef void (APIENTRYP PFNGLPROVOKINGVERTEXPROC) (GLenum mode);
typedef GLsync (APIENTRYP PFNGLFENCESYNCPROC) (GLenum condition, GLbitfield flags);
typedef GLboolean (APIENTRYP PFNGLISSYNCPROC) (GLsync sync);
typedef void (APIENTRYP PFNGLDELETESYNCPROC) (GLsync sync);
typedef GLenum (APIENTRYP PFNGLCLIENTWAITSYNCPROC) (GLsync sync, GLbitfield flags, GLuint64 timeout);
typedef void (APIENTRYP PFNGLWAITSYNCPROC) (GLsync sync, GLbitfield flags, GLuint64 timeout);
typedef void (APIENTRYP PFNGLGETINTEGER64VPROC) (GLenum pname, GLint64 *data);
typedef void (APIENTRYP PFNGLGETSYNCIVPROC) (GLsync sync, GLenum pname, GLsizei bufSize, GLsizei *length, GLint *values);
typedef void (APIENTRYP PFNGLGETINTEGER64I_VPROC) (GLenum target, GLuint index, GLint64 *data);
typedef void (APIENTRYP PFNGLGETBUFFERPARAMETERI64VPROC) (GLenum target, GLenum pname, GLint64 *params);
typedef void (APIENTRYP PFNGLFRAMEBUFFERTEXTUREPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level);
typedef void (APIENTRYP PFNGLTEXIMAGE2DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLboolean fixedsamplelocations);
typedef void (APIENTRYP PFNGLTEXIMAGE3DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedsamplelocations);
typedef void (APIENTRYP PFNGLGETMULTISAMPLEFVPROC) (GLenum pname, GLuint index, GLfloat *val);
typedef void (APIENTRYP PFNGLSAMPLEMASKIPROC) (GLuint maskNumber, GLbitfield mask);

#define GL_VERTEX_ATTRIB_ARRAY_DIVISOR    0x88FE
#define GL_SRC1_COLOR                     0x88F9
#define GL_ONE_MINUS_SRC1_COLOR           0x88FA
#define GL_ONE_MINUS_SRC1_ALPHA           0x88FB
#define GL_MAX_DUAL_SOURCE_DRAW_BUFFERS   0x88FC
#define GL_ANY_SAMPLES_PASSED             0x8C2F
#define GL_SAMPLER_BINDING                0x8919
#define GL_RGB10_A2UI                     0x906F
#define GL_TEXTURE_SWIZZLE_R              0x8E42
#define GL_TEXTURE_SWIZZLE_G              0x8E43
#define GL_TEXTURE_SWIZZLE_B              0x8E44
#define GL_TEXTURE_SWIZZLE_A              0x8E45
#define GL_TEXTURE_SWIZZLE_RGBA           0x8E46
#define GL_TIME_ELAPSED                   0x88BF
#define GL_TIMESTAMP                      0x8E28
#define GL_INT_2_10_10_10_REV             0x8D9F
typedef void (APIENTRYP PFNGLBINDFRAGDATALOCATIONINDEXEDPROC) (GLuint program, GLuint colorNumber, GLuint index, const GLchar *name);
typedef GLint (APIENTRYP PFNGLGETFRAGDATAINDEXPROC) (GLuint program, const GLchar *name);
typedef void (APIENTRYP PFNGLGENSAMPLERSPROC) (GLsizei count, GLuint *samplers);
typedef void (APIENTRYP PFNGLDELETESAMPLERSPROC) (GLsizei count, const GLuint *samplers);
typedef GLboolean (APIENTRYP PFNGLISSAMPLERPROC) (GLuint sampler);
typedef void (APIENTRYP PFNGLBINDSAMPLERPROC) (GLuint unit, GLuint sampler);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERIPROC) (GLuint sampler, GLenum pname, GLint param);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERIVPROC) (GLuint sampler, GLenum pname, const GLint *param);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERFPROC) (GLuint sampler, GLenum pname, GLfloat param);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERFVPROC) (GLuint sampler, GLenum pname, const GLfloat *param);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERIIVPROC) (GLuint sampler, GLenum pname, const GLint *param);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERIUIVPROC) (GLuint sampler, GLenum pname, const GLuint *param);
typedef void (APIENTRYP PFNGLGETSAMPLERPARAMETERIVPROC) (GLuint sampler, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETSAMPLERPARAMETERIIVPROC) (GLuint sampler, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETSAMPLERPARAMETERFVPROC) (GLuint sampler, GLenum pname, GLfloat *params);
typedef void (APIENTRYP PFNGLGETSAMPLERPARAMETERIUIVPROC) (GLuint sampler, GLenum pname, GLuint *params);
typedef void (APIENTRYP PFNGLQUERYCOUNTERPROC) (GLuint id, GLenum target);
typedef void (APIENTRYP PFNGLGETQUERYOBJECTI64VPROC) (GLuint id, GLenum pname, GLint64 *params);
typedef void (APIENTRYP PFNGLGETQUERYOBJECTUI64VPROC) (GLuint id, GLenum pname, GLuint64 *params);
typedef void (APIENTRYP PFNGLVERTEXATTRIBDIVISORPROC) (GLuint index, GLuint divisor);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP1UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP1UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP2UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP2UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP3UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP3UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP4UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP4UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);

#define GL_SAMPLE_SHADING                 0x8C36
#define GL_MIN_SAMPLE_SHADING_VALUE       0x8C37
#define GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET 0x8E5E
#define GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET 0x8E5F
#define GL_TEXTURE_CUBE_MAP_ARRAY         0x9009
#define GL_TEXTURE_BINDING_CUBE_MAP_ARRAY 0x900A
#define GL_PROXY_TEXTURE_CUBE_MAP_ARRAY   0x900B
#define GL_SAMPLER_CUBE_MAP_ARRAY         0x900C
#define GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW  0x900D
#define GL_INT_SAMPLER_CUBE_MAP_ARRAY     0x900E
#define GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY 0x900F
#define GL_DRAW_INDIRECT_BUFFER           0x8F3F
#define GL_DRAW_INDIRECT_BUFFER_BINDING   0x8F43
#define GL_GEOMETRY_SHADER_INVOCATIONS    0x887F
#define GL_MAX_GEOMETRY_SHADER_INVOCATIONS 0x8E5A
#define GL_MIN_FRAGMENT_INTERPOLATION_OFFSET 0x8E5B
#define GL_MAX_FRAGMENT_INTERPOLATION_OFFSET 0x8E5C
#define GL_FRAGMENT_INTERPOLATION_OFFSET_BITS 0x8E5D
#define GL_MAX_VERTEX_STREAMS             0x8E71
#define GL_DOUBLE_VEC2                    0x8FFC
#define GL_DOUBLE_VEC3                    0x8FFD
#define GL_DOUBLE_VEC4                    0x8FFE
#define GL_DOUBLE_MAT2                    0x8F46
#define GL_DOUBLE_MAT3                    0x8F47
#define GL_DOUBLE_MAT4                    0x8F48
#define GL_DOUBLE_MAT2x3                  0x8F49
#define GL_DOUBLE_MAT2x4                  0x8F4A
#define GL_DOUBLE_MAT3x2                  0x8F4B
#define GL_DOUBLE_MAT3x4                  0x8F4C
#define GL_DOUBLE_MAT4x2                  0x8F4D
#define GL_DOUBLE_MAT4x3                  0x8F4E
#define GL_ACTIVE_SUBROUTINES             0x8DE5
#define GL_ACTIVE_SUBROUTINE_UNIFORMS     0x8DE6
#define GL_ACTIVE_SUBROUTINE_UNIFORM_LOCATIONS 0x8E47
#define GL_ACTIVE_SUBROUTINE_MAX_LENGTH   0x8E48
#define GL_ACTIVE_SUBROUTINE_UNIFORM_MAX_LENGTH 0x8E49
#define GL_MAX_SUBROUTINES                0x8DE7
#define GL_MAX_SUBROUTINE_UNIFORM_LOCATIONS 0x8DE8
#define GL_NUM_COMPATIBLE_SUBROUTINES     0x8E4A
#define GL_COMPATIBLE_SUBROUTINES         0x8E4B
#define GL_PATCHES                        0x000E
#define GL_PATCH_VERTICES                 0x8E72
#define GL_PATCH_DEFAULT_INNER_LEVEL      0x8E73
#define GL_PATCH_DEFAULT_OUTER_LEVEL      0x8E74
#define GL_TESS_CONTROL_OUTPUT_VERTICES   0x8E75
#define GL_TESS_GEN_MODE                  0x8E76
#define GL_TESS_GEN_SPACING               0x8E77
#define GL_TESS_GEN_VERTEX_ORDER          0x8E78
#define GL_TESS_GEN_POINT_MODE            0x8E79
#define GL_ISOLINES                       0x8E7A
#define GL_FRACTIONAL_ODD                 0x8E7B
#define GL_FRACTIONAL_EVEN                0x8E7C
#define GL_MAX_PATCH_VERTICES             0x8E7D
#define GL_MAX_TESS_GEN_LEVEL             0x8E7E
#define GL_MAX_TESS_CONTROL_UNIFORM_COMPONENTS 0x8E7F
#define GL_MAX_TESS_EVALUATION_UNIFORM_COMPONENTS 0x8E80
#define GL_MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS 0x8E81
#define GL_MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS 0x8E82
#define GL_MAX_TESS_CONTROL_OUTPUT_COMPONENTS 0x8E83
#define GL_MAX_TESS_PATCH_COMPONENTS      0x8E84
#define GL_MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS 0x8E85
#define GL_MAX_TESS_EVALUATION_OUTPUT_COMPONENTS 0x8E86
#define GL_MAX_TESS_CONTROL_UNIFORM_BLOCKS 0x8E89
#define GL_MAX_TESS_EVALUATION_UNIFORM_BLOCKS 0x8E8A
#define GL_MAX_TESS_CONTROL_INPUT_COMPONENTS 0x886C
#define GL_MAX_TESS_EVALUATION_INPUT_COMPONENTS 0x886D
#define GL_MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS 0x8E1E
#define GL_MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS 0x8E1F
#define GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_CONTROL_SHADER 0x84F0
#define GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_EVALUATION_SHADER 0x84F1
#define GL_TESS_EVALUATION_SHADER         0x8E87
#define GL_TESS_CONTROL_SHADER            0x8E88
#define GL_TRANSFORM_FEEDBACK             0x8E22
#define GL_TRANSFORM_FEEDBACK_BUFFER_PAUSED 0x8E23
#define GL_TRANSFORM_FEEDBACK_BUFFER_ACTIVE 0x8E24
#define GL_TRANSFORM_FEEDBACK_BINDING     0x8E25
#define GL_MAX_TRANSFORM_FEEDBACK_BUFFERS 0x8E70
typedef void (APIENTRYP PFNGLMINSAMPLESHADINGPROC) (GLfloat value);
typedef void (APIENTRYP PFNGLBLENDEQUATIONIPROC) (GLuint buf, GLenum mode);
typedef void (APIENTRYP PFNGLBLENDEQUATIONSEPARATEIPROC) (GLuint buf, GLenum modeRGB, GLenum modeAlpha);
typedef void (APIENTRYP PFNGLBLENDFUNCIPROC) (GLuint buf, GLenum src, GLenum dst);
typedef void (APIENTRYP PFNGLBLENDFUNCSEPARATEIPROC) (GLuint buf, GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);
typedef void (APIENTRYP PFNGLDRAWARRAYSINDIRECTPROC) (GLenum mode, const void *indirect);
typedef void (APIENTRYP PFNGLDRAWELEMENTSINDIRECTPROC) (GLenum mode, GLenum type, const void *indirect);
typedef void (APIENTRYP PFNGLUNIFORM1DPROC) (GLint location, GLdouble x);
typedef void (APIENTRYP PFNGLUNIFORM2DPROC) (GLint location, GLdouble x, GLdouble y);
typedef void (APIENTRYP PFNGLUNIFORM3DPROC) (GLint location, GLdouble x, GLdouble y, GLdouble z);
typedef void (APIENTRYP PFNGLUNIFORM4DPROC) (GLint location, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
typedef void (APIENTRYP PFNGLUNIFORM1DVPROC) (GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORM2DVPROC) (GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORM3DVPROC) (GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORM4DVPROC) (GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2X3DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2X4DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3X2DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3X4DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4X2DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4X3DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLGETUNIFORMDVPROC) (GLuint program, GLint location, GLdouble *params);
typedef GLint (APIENTRYP PFNGLGETSUBROUTINEUNIFORMLOCATIONPROC) (GLuint program, GLenum shadertype, const GLchar *name);
typedef GLuint (APIENTRYP PFNGLGETSUBROUTINEINDEXPROC) (GLuint program, GLenum shadertype, const GLchar *name);
typedef void (APIENTRYP PFNGLGETACTIVESUBROUTINEUNIFORMIVPROC) (GLuint program, GLenum shadertype, GLuint index, GLenum pname, GLint *values);
typedef void (APIENTRYP PFNGLGETACTIVESUBROUTINEUNIFORMNAMEPROC) (GLuint program, GLenum shadertype, GLuint index, GLsizei bufsize, GLsizei *length, GLchar *name);
typedef void (APIENTRYP PFNGLGETACTIVESUBROUTINENAMEPROC) (GLuint program, GLenum shadertype, GLuint index, GLsizei bufsize, GLsizei *length, GLchar *name);
typedef void (APIENTRYP PFNGLUNIFORMSUBROUTINESUIVPROC) (GLenum shadertype, GLsizei count, const GLuint *indices);
typedef void (APIENTRYP PFNGLGETUNIFORMSUBROUTINEUIVPROC) (GLenum shadertype, GLint location, GLuint *params);
typedef void (APIENTRYP PFNGLGETPROGRAMSTAGEIVPROC) (GLuint program, GLenum shadertype, GLenum pname, GLint *values);
typedef void (APIENTRYP PFNGLPATCHPARAMETERIPROC) (GLenum pname, GLint value);
typedef void (APIENTRYP PFNGLPATCHPARAMETERFVPROC) (GLenum pname, const GLfloat *values);
typedef void (APIENTRYP PFNGLBINDTRANSFORMFEEDBACKPROC) (GLenum target, GLuint id);
typedef void (APIENTRYP PFNGLDELETETRANSFORMFEEDBACKSPROC) (GLsizei n, const GLuint *ids);
typedef void (APIENTRYP PFNGLGENTRANSFORMFEEDBACKSPROC) (GLsizei n, GLuint *ids);
typedef GLboolean (APIENTRYP PFNGLISTRANSFORMFEEDBACKPROC) (GLuint id);
typedef void (APIENTRYP PFNGLPAUSETRANSFORMFEEDBACKPROC) (void);
typedef void (APIENTRYP PFNGLRESUMETRANSFORMFEEDBACKPROC) (void);
typedef void (APIENTRYP PFNGLDRAWTRANSFORMFEEDBACKPROC) (GLenum mode, GLuint id);
typedef void (APIENTRYP PFNGLDRAWTRANSFORMFEEDBACKSTREAMPROC) (GLenum mode, GLuint id, GLuint stream);
typedef void (APIENTRYP PFNGLBEGINQUERYINDEXEDPROC) (GLenum target, GLuint index, GLuint id);
typedef void (APIENTRYP PFNGLENDQUERYINDEXEDPROC) (GLenum target, GLuint index);
typedef void (APIENTRYP PFNGLGETQUERYINDEXEDIVPROC) (GLenum target, GLuint index, GLenum pname, GLint *params);

#define GL_FIXED                          0x140C
#define GL_IMPLEMENTATION_COLOR_READ_TYPE 0x8B9A
#define GL_IMPLEMENTATION_COLOR_READ_FORMAT 0x8B9B
#define GL_LOW_FLOAT                      0x8DF0
#define GL_MEDIUM_FLOAT                   0x8DF1
#define GL_HIGH_FLOAT                     0x8DF2
#define GL_LOW_INT                        0x8DF3
#define GL_MEDIUM_INT                     0x8DF4
#define GL_HIGH_INT                       0x8DF5
#define GL_SHADER_COMPILER                0x8DFA
#define GL_SHADER_BINARY_FORMATS          0x8DF8
#define GL_NUM_SHADER_BINARY_FORMATS      0x8DF9
#define GL_MAX_VERTEX_UNIFORM_VECTORS     0x8DFB
#define GL_MAX_VARYING_VECTORS            0x8DFC
#define GL_MAX_FRAGMENT_UNIFORM_VECTORS   0x8DFD
#define GL_RGB565                         0x8D62
#define GL_PROGRAM_BINARY_RETRIEVABLE_HINT 0x8257
#define GL_PROGRAM_BINARY_LENGTH          0x8741
#define GL_NUM_PROGRAM_BINARY_FORMATS     0x87FE
#define GL_PROGRAM_BINARY_FORMATS         0x87FF
#define GL_VERTEX_SHADER_BIT              0x00000001
#define GL_FRAGMENT_SHADER_BIT            0x00000002
#define GL_GEOMETRY_SHADER_BIT            0x00000004
#define GL_TESS_CONTROL_SHADER_BIT        0x00000008
#define GL_TESS_EVALUATION_SHADER_BIT     0x00000010
#define GL_ALL_SHADER_BITS                0xFFFFFFFF
#define GL_PROGRAM_SEPARABLE              0x8258
#define GL_ACTIVE_PROGRAM                 0x8259
#define GL_PROGRAM_PIPELINE_BINDING       0x825A
#define GL_MAX_VIEWPORTS                  0x825B
#define GL_VIEWPORT_SUBPIXEL_BITS         0x825C
#define GL_VIEWPORT_BOUNDS_RANGE          0x825D
#define GL_LAYER_PROVOKING_VERTEX         0x825E
#define GL_VIEWPORT_INDEX_PROVOKING_VERTEX 0x825F
#define GL_UNDEFINED_VERTEX               0x8260
typedef void (APIENTRYP PFNGLRELEASESHADERCOMPILERPROC) (void);
typedef void (APIENTRYP PFNGLSHADERBINARYPROC) (GLsizei count, const GLuint *shaders, GLenum binaryformat, const void *binary, GLsizei length);
typedef void (APIENTRYP PFNGLGETSHADERPRECISIONFORMATPROC) (GLenum shadertype, GLenum precisiontype, GLint *range, GLint *precision);
typedef void (APIENTRYP PFNGLDEPTHRANGEFPROC) (GLfloat n, GLfloat f);
typedef void (APIENTRYP PFNGLCLEARDEPTHFPROC) (GLfloat d);
typedef void (APIENTRYP PFNGLGETPROGRAMBINARYPROC) (GLuint program, GLsizei bufSize, GLsizei *length, GLenum *binaryFormat, void *binary);
typedef void (APIENTRYP PFNGLPROGRAMBINARYPROC) (GLuint program, GLenum binaryFormat, const void *binary, GLsizei length);
typedef void (APIENTRYP PFNGLPROGRAMPARAMETERIPROC) (GLuint program, GLenum pname, GLint value);
typedef void (APIENTRYP PFNGLUSEPROGRAMSTAGESPROC) (GLuint pipeline, GLbitfield stages, GLuint program);
typedef void (APIENTRYP PFNGLACTIVESHADERPROGRAMPROC) (GLuint pipeline, GLuint program);
typedef GLuint (APIENTRYP PFNGLCREATESHADERPROGRAMVPROC) (GLenum type, GLsizei count, const GLchar *const*strings);
typedef void (APIENTRYP PFNGLBINDPROGRAMPIPELINEPROC) (GLuint pipeline);
typedef void (APIENTRYP PFNGLDELETEPROGRAMPIPELINESPROC) (GLsizei n, const GLuint *pipelines);
typedef void (APIENTRYP PFNGLGENPROGRAMPIPELINESPROC) (GLsizei n, GLuint *pipelines);
typedef GLboolean (APIENTRYP PFNGLISPROGRAMPIPELINEPROC) (GLuint pipeline);
typedef void (APIENTRYP PFNGLGETPROGRAMPIPELINEIVPROC) (GLuint pipeline, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1IPROC) (GLuint program, GLint location, GLint v0);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1FPROC) (GLuint program, GLint location, GLfloat v0);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1DPROC) (GLuint program, GLint location, GLdouble v0);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1UIPROC) (GLuint program, GLint location, GLuint v0);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2IPROC) (GLuint program, GLint location, GLint v0, GLint v1);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2FPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2DPROC) (GLuint program, GLint location, GLdouble v0, GLdouble v1);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2UIPROC) (GLuint program, GLint location, GLuint v0, GLuint v1);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3IPROC) (GLuint program, GLint location, GLint v0, GLint v1, GLint v2);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3FPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3DPROC) (GLuint program, GLint location, GLdouble v0, GLdouble v1, GLdouble v2);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3UIPROC) (GLuint program, GLint location, GLuint v0, GLuint v1, GLuint v2);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4IPROC) (GLuint program, GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4FPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4DPROC) (GLuint program, GLint location, GLdouble v0, GLdouble v1, GLdouble v2, GLdouble v3);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4UIPROC) (GLuint program, GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2X3FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3X2FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2X4FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4X2FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3X4FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4X3FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2X3DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3X2DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2X4DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4X2DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3X4DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4X3DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLVALIDATEPROGRAMPIPELINEPROC) (GLuint pipeline);
typedef void (APIENTRYP PFNGLGETPROGRAMPIPELINEINFOLOGPROC) (GLuint pipeline, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL1DPROC) (GLuint index, GLdouble x);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL2DPROC) (GLuint index, GLdouble x, GLdouble y);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL3DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL4DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL1DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL2DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL3DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL4DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBLPOINTERPROC) (GLuint index, GLint size, GLenum type, GLsizei stride, const void *pointer);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBLDVPROC) (GLuint index, GLenum pname, GLdouble *params);
typedef void (APIENTRYP PFNGLVIEWPORTARRAYVPROC) (GLuint first, GLsizei count, const GLfloat *v);
typedef void (APIENTRYP PFNGLVIEWPORTINDEXEDFPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat w, GLfloat h);
typedef void (APIENTRYP PFNGLVIEWPORTINDEXEDFVPROC) (GLuint index, const GLfloat *v);
typedef void (APIENTRYP PFNGLSCISSORARRAYVPROC) (GLuint first, GLsizei count, const GLint *v);
typedef void (APIENTRYP PFNGLSCISSORINDEXEDPROC) (GLuint index, GLint left, GLint bottom, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLSCISSORINDEXEDVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLDEPTHRANGEARRAYVPROC) (GLuint first, GLsizei count, const GLdouble *v);
typedef void (APIENTRYP PFNGLDEPTHRANGEINDEXEDPROC) (GLuint index, GLdouble n, GLdouble f);
typedef void (APIENTRYP PFNGLGETFLOATI_VPROC) (GLenum target, GLuint index, GLfloat *data);
typedef void (APIENTRYP PFNGLGETDOUBLEI_VPROC) (GLenum target, GLuint index, GLdouble *data);

#define GL_UNPACK_COMPRESSED_BLOCK_WIDTH  0x9127
#define GL_UNPACK_COMPRESSED_BLOCK_HEIGHT 0x9128
#define GL_UNPACK_COMPRESSED_BLOCK_DEPTH  0x9129
#define GL_UNPACK_COMPRESSED_BLOCK_SIZE   0x912A
#define GL_PACK_COMPRESSED_BLOCK_WIDTH    0x912B
#define GL_PACK_COMPRESSED_BLOCK_HEIGHT   0x912C
#define GL_PACK_COMPRESSED_BLOCK_DEPTH    0x912D
#define GL_PACK_COMPRESSED_BLOCK_SIZE     0x912E
#define GL_NUM_SAMPLE_COUNTS              0x9380
#define GL_MIN_MAP_BUFFER_ALIGNMENT       0x90BC
#define GL_ATOMIC_COUNTER_BUFFER          0x92C0
#define GL_ATOMIC_COUNTER_BUFFER_BINDING  0x92C1
#define GL_ATOMIC_COUNTER_BUFFER_START    0x92C2
#define GL_ATOMIC_COUNTER_BUFFER_SIZE     0x92C3
#define GL_ATOMIC_COUNTER_BUFFER_DATA_SIZE 0x92C4
#define GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTERS 0x92C5
#define GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTER_INDICES 0x92C6
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_VERTEX_SHADER 0x92C7
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_CONTROL_SHADER 0x92C8
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_EVALUATION_SHADER 0x92C9
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_GEOMETRY_SHADER 0x92CA
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_FRAGMENT_SHADER 0x92CB
#define GL_MAX_VERTEX_ATOMIC_COUNTER_BUFFERS 0x92CC
#define GL_MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS 0x92CD
#define GL_MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS 0x92CE
#define GL_MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS 0x92CF
#define GL_MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS 0x92D0
#define GL_MAX_COMBINED_ATOMIC_COUNTER_BUFFERS 0x92D1
#define GL_MAX_VERTEX_ATOMIC_COUNTERS     0x92D2
#define GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS 0x92D3
#define GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS 0x92D4
#define GL_MAX_GEOMETRY_ATOMIC_COUNTERS   0x92D5
#define GL_MAX_FRAGMENT_ATOMIC_COUNTERS   0x92D6
#define GL_MAX_COMBINED_ATOMIC_COUNTERS   0x92D7
#define GL_MAX_ATOMIC_COUNTER_BUFFER_SIZE 0x92D8
#define GL_MAX_ATOMIC_COUNTER_BUFFER_BINDINGS 0x92DC
#define GL_ACTIVE_ATOMIC_COUNTER_BUFFERS  0x92D9
#define GL_UNIFORM_ATOMIC_COUNTER_BUFFER_INDEX 0x92DA
#define GL_UNSIGNED_INT_ATOMIC_COUNTER    0x92DB
#define GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT 0x00000001
#define GL_ELEMENT_ARRAY_BARRIER_BIT      0x00000002
#define GL_UNIFORM_BARRIER_BIT            0x00000004
#define GL_TEXTURE_FETCH_BARRIER_BIT      0x00000008
#define GL_SHADER_IMAGE_ACCESS_BARRIER_BIT 0x00000020
#define GL_COMMAND_BARRIER_BIT            0x00000040
#define GL_PIXEL_BUFFER_BARRIER_BIT       0x00000080
#define GL_TEXTURE_UPDATE_BARRIER_BIT     0x00000100
#define GL_BUFFER_UPDATE_BARRIER_BIT      0x00000200
#define GL_FRAMEBUFFER_BARRIER_BIT        0x00000400
#define GL_TRANSFORM_FEEDBACK_BARRIER_BIT 0x00000800
#define GL_ATOMIC_COUNTER_BARRIER_BIT     0x00001000
#define GL_ALL_BARRIER_BITS               0xFFFFFFFF
#define GL_MAX_IMAGE_UNITS                0x8F38
#define GL_MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS 0x8F39
#define GL_IMAGE_BINDING_NAME             0x8F3A
#define GL_IMAGE_BINDING_LEVEL            0x8F3B
#define GL_IMAGE_BINDING_LAYERED          0x8F3C
#define GL_IMAGE_BINDING_LAYER            0x8F3D
#define GL_IMAGE_BINDING_ACCESS           0x8F3E
#define GL_IMAGE_1D                       0x904C
#define GL_IMAGE_2D                       0x904D
#define GL_IMAGE_3D                       0x904E
#define GL_IMAGE_2D_RECT                  0x904F
#define GL_IMAGE_CUBE                     0x9050
#define GL_IMAGE_BUFFER                   0x9051
#define GL_IMAGE_1D_ARRAY                 0x9052
#define GL_IMAGE_2D_ARRAY                 0x9053
#define GL_IMAGE_CUBE_MAP_ARRAY           0x9054
#define GL_IMAGE_2D_MULTISAMPLE           0x9055
#define GL_IMAGE_2D_MULTISAMPLE_ARRAY     0x9056
#define GL_INT_IMAGE_1D                   0x9057
#define GL_INT_IMAGE_2D                   0x9058
#define GL_INT_IMAGE_3D                   0x9059
#define GL_INT_IMAGE_2D_RECT              0x905A
#define GL_INT_IMAGE_CUBE                 0x905B
#define GL_INT_IMAGE_BUFFER               0x905C
#define GL_INT_IMAGE_1D_ARRAY             0x905D
#define GL_INT_IMAGE_2D_ARRAY             0x905E
#define GL_INT_IMAGE_CUBE_MAP_ARRAY       0x905F
#define GL_INT_IMAGE_2D_MULTISAMPLE       0x9060
#define GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY 0x9061
#define GL_UNSIGNED_INT_IMAGE_1D          0x9062
#define GL_UNSIGNED_INT_IMAGE_2D          0x9063
#define GL_UNSIGNED_INT_IMAGE_3D          0x9064
#define GL_UNSIGNED_INT_IMAGE_2D_RECT     0x9065
#define GL_UNSIGNED_INT_IMAGE_CUBE        0x9066
#define GL_UNSIGNED_INT_IMAGE_BUFFER      0x9067
#define GL_UNSIGNED_INT_IMAGE_1D_ARRAY    0x9068
#define GL_UNSIGNED_INT_IMAGE_2D_ARRAY    0x9069
#define GL_UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY 0x906A
#define GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE 0x906B
#define GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY 0x906C
#define GL_MAX_IMAGE_SAMPLES              0x906D
#define GL_IMAGE_BINDING_FORMAT           0x906E
#define GL_IMAGE_FORMAT_COMPATIBILITY_TYPE 0x90C7
#define GL_IMAGE_FORMAT_COMPATIBILITY_BY_SIZE 0x90C8
#define GL_IMAGE_FORMAT_COMPATIBILITY_BY_CLASS 0x90C9
#define GL_MAX_VERTEX_IMAGE_UNIFORMS      0x90CA
#define GL_MAX_TESS_CONTROL_IMAGE_UNIFORMS 0x90CB
#define GL_MAX_TESS_EVALUATION_IMAGE_UNIFORMS 0x90CC
#define GL_MAX_GEOMETRY_IMAGE_UNIFORMS    0x90CD
#define GL_MAX_FRAGMENT_IMAGE_UNIFORMS    0x90CE
#define GL_MAX_COMBINED_IMAGE_UNIFORMS    0x90CF
#define GL_COMPRESSED_RGBA_BPTC_UNORM     0x8E8C
#define GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM 0x8E8D
#define GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT 0x8E8E
#define GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT 0x8E8F
#define GL_TEXTURE_IMMUTABLE_FORMAT       0x912F
typedef void (APIENTRYP PFNGLDRAWARRAYSINSTANCEDBASEINSTANCEPROC) (GLenum mode, GLint first, GLsizei count, GLsizei instancecount, GLuint baseinstance);
typedef void (APIENTRYP PFNGLDRAWELEMENTSINSTANCEDBASEINSTANCEPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount, GLuint baseinstance);
typedef void (APIENTRYP PFNGLDRAWELEMENTSINSTANCEDBASEVERTEXBASEINSTANCEPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount, GLint basevertex, GLuint baseinstance);
typedef void (APIENTRYP PFNGLGETINTERNALFORMATIVPROC) (GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint *params);
typedef void (APIENTRYP PFNGLGETACTIVEATOMICCOUNTERBUFFERIVPROC) (GLuint program, GLuint bufferIndex, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLBINDIMAGETEXTUREPROC) (GLuint unit, GLuint texture, GLint level, GLboolean layered, GLint layer, GLenum access, GLenum format);
typedef void (APIENTRYP PFNGLMEMORYBARRIERPROC) (GLbitfield barriers);
typedef void (APIENTRYP PFNGLTEXSTORAGE1DPROC) (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width);
typedef void (APIENTRYP PFNGLTEXSTORAGE2DPROC) (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLTEXSTORAGE3DPROC) (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);
typedef void (APIENTRYP PFNGLDRAWTRANSFORMFEEDBACKINSTANCEDPROC) (GLenum mode, GLuint id, GLsizei instancecount);
typedef void (APIENTRYP PFNGLDRAWTRANSFORMFEEDBACKSTREAMINSTANCEDPROC) (GLenum mode, GLuint id, GLuint stream, GLsizei instancecount);

typedef void (APIENTRY  *GLDEBUGPROC)(GLenum source,GLenum type,GLuint id,GLenum severity,GLsizei length,const GLchar *message,const void *userParam);
#define GL_NUM_SHADING_LANGUAGE_VERSIONS  0x82E9
#define GL_VERTEX_ATTRIB_ARRAY_LONG       0x874E
#define GL_COMPRESSED_RGB8_ETC2           0x9274
#define GL_COMPRESSED_SRGB8_ETC2          0x9275
#define GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 0x9276
#define GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 0x9277
#define GL_COMPRESSED_RGBA8_ETC2_EAC      0x9278
#define GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC 0x9279
#define GL_COMPRESSED_R11_EAC             0x9270
#define GL_COMPRESSED_SIGNED_R11_EAC      0x9271
#define GL_COMPRESSED_RG11_EAC            0x9272
#define GL_COMPRESSED_SIGNED_RG11_EAC     0x9273
#define GL_PRIMITIVE_RESTART_FIXED_INDEX  0x8D69
#define GL_ANY_SAMPLES_PASSED_CONSERVATIVE 0x8D6A
#define GL_MAX_ELEMENT_INDEX              0x8D6B
#define GL_COMPUTE_SHADER                 0x91B9
#define GL_MAX_COMPUTE_UNIFORM_BLOCKS     0x91BB
#define GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS 0x91BC
#define GL_MAX_COMPUTE_IMAGE_UNIFORMS     0x91BD
#define GL_MAX_COMPUTE_SHARED_MEMORY_SIZE 0x8262
#define GL_MAX_COMPUTE_UNIFORM_COMPONENTS 0x8263
#define GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS 0x8264
#define GL_MAX_COMPUTE_ATOMIC_COUNTERS    0x8265
#define GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS 0x8266
#define GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS 0x90EB
#define GL_MAX_COMPUTE_WORK_GROUP_COUNT   0x91BE
#define GL_MAX_COMPUTE_WORK_GROUP_SIZE    0x91BF
#define GL_COMPUTE_WORK_GROUP_SIZE        0x8267
#define GL_UNIFORM_BLOCK_REFERENCED_BY_COMPUTE_SHADER 0x90EC
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_COMPUTE_SHADER 0x90ED
#define GL_DISPATCH_INDIRECT_BUFFER       0x90EE
#define GL_DISPATCH_INDIRECT_BUFFER_BINDING 0x90EF
#define GL_DEBUG_OUTPUT_SYNCHRONOUS       0x8242
#define GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH 0x8243
#define GL_DEBUG_CALLBACK_FUNCTION        0x8244
#define GL_DEBUG_CALLBACK_USER_PARAM      0x8245
#define GL_DEBUG_SOURCE_API               0x8246
#define GL_DEBUG_SOURCE_WINDOW_SYSTEM     0x8247
#define GL_DEBUG_SOURCE_SHADER_COMPILER   0x8248
#define GL_DEBUG_SOURCE_THIRD_PARTY       0x8249
#define GL_DEBUG_SOURCE_APPLICATION       0x824A
#define GL_DEBUG_SOURCE_OTHER             0x824B
#define GL_DEBUG_TYPE_ERROR               0x824C
#define GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR 0x824D
#define GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR  0x824E
#define GL_DEBUG_TYPE_PORTABILITY         0x824F
#define GL_DEBUG_TYPE_PERFORMANCE         0x8250
#define GL_DEBUG_TYPE_OTHER               0x8251
#define GL_MAX_DEBUG_MESSAGE_LENGTH       0x9143
#define GL_MAX_DEBUG_LOGGED_MESSAGES      0x9144
#define GL_DEBUG_LOGGED_MESSAGES          0x9145
#define GL_DEBUG_SEVERITY_HIGH            0x9146
#define GL_DEBUG_SEVERITY_MEDIUM          0x9147
#define GL_DEBUG_SEVERITY_LOW             0x9148
#define GL_DEBUG_TYPE_MARKER              0x8268
#define GL_DEBUG_TYPE_PUSH_GROUP          0x8269
#define GL_DEBUG_TYPE_POP_GROUP           0x826A
#define GL_DEBUG_SEVERITY_NOTIFICATION    0x826B
#define GL_MAX_DEBUG_GROUP_STACK_DEPTH    0x826C
#define GL_DEBUG_GROUP_STACK_DEPTH        0x826D
#define GL_BUFFER                         0x82E0
#define GL_SHADER                         0x82E1
#define GL_PROGRAM                        0x82E2
#define GL_QUERY                          0x82E3
#define GL_PROGRAM_PIPELINE               0x82E4
#define GL_SAMPLER                        0x82E6
#define GL_MAX_LABEL_LENGTH               0x82E8
#define GL_DEBUG_OUTPUT                   0x92E0
#define GL_CONTEXT_FLAG_DEBUG_BIT         0x00000002
#define GL_MAX_UNIFORM_LOCATIONS          0x826E
#define GL_FRAMEBUFFER_DEFAULT_WIDTH      0x9310
#define GL_FRAMEBUFFER_DEFAULT_HEIGHT     0x9311
#define GL_FRAMEBUFFER_DEFAULT_LAYERS     0x9312
#define GL_FRAMEBUFFER_DEFAULT_SAMPLES    0x9313
#define GL_FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS 0x9314
#define GL_MAX_FRAMEBUFFER_WIDTH          0x9315
#define GL_MAX_FRAMEBUFFER_HEIGHT         0x9316
#define GL_MAX_FRAMEBUFFER_LAYERS         0x9317
#define GL_MAX_FRAMEBUFFER_SAMPLES        0x9318
#define GL_INTERNALFORMAT_SUPPORTED       0x826F
#define GL_INTERNALFORMAT_PREFERRED       0x8270
#define GL_INTERNALFORMAT_RED_SIZE        0x8271
#define GL_INTERNALFORMAT_GREEN_SIZE      0x8272
#define GL_INTERNALFORMAT_BLUE_SIZE       0x8273
#define GL_INTERNALFORMAT_ALPHA_SIZE      0x8274
#define GL_INTERNALFORMAT_DEPTH_SIZE      0x8275
#define GL_INTERNALFORMAT_STENCIL_SIZE    0x8276
#define GL_INTERNALFORMAT_SHARED_SIZE     0x8277
#define GL_INTERNALFORMAT_RED_TYPE        0x8278
#define GL_INTERNALFORMAT_GREEN_TYPE      0x8279
#define GL_INTERNALFORMAT_BLUE_TYPE       0x827A
#define GL_INTERNALFORMAT_ALPHA_TYPE      0x827B
#define GL_INTERNALFORMAT_DEPTH_TYPE      0x827C
#define GL_INTERNALFORMAT_STENCIL_TYPE    0x827D
#define GL_MAX_WIDTH                      0x827E
#define GL_MAX_HEIGHT                     0x827F
#define GL_MAX_DEPTH                      0x8280
#define GL_MAX_LAYERS                     0x8281
#define GL_MAX_COMBINED_DIMENSIONS        0x8282
#define GL_COLOR_COMPONENTS               0x8283
#define GL_DEPTH_COMPONENTS               0x8284
#define GL_STENCIL_COMPONENTS             0x8285
#define GL_COLOR_RENDERABLE               0x8286
#define GL_DEPTH_RENDERABLE               0x8287
#define GL_STENCIL_RENDERABLE             0x8288
#define GL_FRAMEBUFFER_RENDERABLE         0x8289
#define GL_FRAMEBUFFER_RENDERABLE_LAYERED 0x828A
#define GL_FRAMEBUFFER_BLEND              0x828B
#define GL_READ_PIXELS                    0x828C
#define GL_READ_PIXELS_FORMAT             0x828D
#define GL_READ_PIXELS_TYPE               0x828E
#define GL_TEXTURE_IMAGE_FORMAT           0x828F
#define GL_TEXTURE_IMAGE_TYPE             0x8290
#define GL_GET_TEXTURE_IMAGE_FORMAT       0x8291
#define GL_GET_TEXTURE_IMAGE_TYPE         0x8292
#define GL_MIPMAP                         0x8293
#define GL_MANUAL_GENERATE_MIPMAP         0x8294
#define GL_AUTO_GENERATE_MIPMAP           0x8295
#define GL_COLOR_ENCODING                 0x8296
#define GL_SRGB_READ                      0x8297
#define GL_SRGB_WRITE                     0x8298
#define GL_FILTER                         0x829A
#define GL_VERTEX_TEXTURE                 0x829B
#define GL_TESS_CONTROL_TEXTURE           0x829C
#define GL_TESS_EVALUATION_TEXTURE        0x829D
#define GL_GEOMETRY_TEXTURE               0x829E
#define GL_FRAGMENT_TEXTURE               0x829F
#define GL_COMPUTE_TEXTURE                0x82A0
#define GL_TEXTURE_SHADOW                 0x82A1
#define GL_TEXTURE_GATHER                 0x82A2
#define GL_TEXTURE_GATHER_SHADOW          0x82A3
#define GL_SHADER_IMAGE_LOAD              0x82A4
#define GL_SHADER_IMAGE_STORE             0x82A5
#define GL_SHADER_IMAGE_ATOMIC            0x82A6
#define GL_IMAGE_TEXEL_SIZE               0x82A7
#define GL_IMAGE_COMPATIBILITY_CLASS      0x82A8
#define GL_IMAGE_PIXEL_FORMAT             0x82A9
#define GL_IMAGE_PIXEL_TYPE               0x82AA
#define GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_TEST 0x82AC
#define GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_TEST 0x82AD
#define GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_WRITE 0x82AE
#define GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_WRITE 0x82AF
#define GL_TEXTURE_COMPRESSED_BLOCK_WIDTH 0x82B1
#define GL_TEXTURE_COMPRESSED_BLOCK_HEIGHT 0x82B2
#define GL_TEXTURE_COMPRESSED_BLOCK_SIZE  0x82B3
#define GL_CLEAR_BUFFER                   0x82B4
#define GL_TEXTURE_VIEW                   0x82B5
#define GL_VIEW_COMPATIBILITY_CLASS       0x82B6
#define GL_FULL_SUPPORT                   0x82B7
#define GL_CAVEAT_SUPPORT                 0x82B8
#define GL_IMAGE_CLASS_4_X_32             0x82B9
#define GL_IMAGE_CLASS_2_X_32             0x82BA
#define GL_IMAGE_CLASS_1_X_32             0x82BB
#define GL_IMAGE_CLASS_4_X_16             0x82BC
#define GL_IMAGE_CLASS_2_X_16             0x82BD
#define GL_IMAGE_CLASS_1_X_16             0x82BE
#define GL_IMAGE_CLASS_4_X_8              0x82BF
#define GL_IMAGE_CLASS_2_X_8              0x82C0
#define GL_IMAGE_CLASS_1_X_8              0x82C1
#define GL_IMAGE_CLASS_11_11_10           0x82C2
#define GL_IMAGE_CLASS_10_10_10_2         0x82C3
#define GL_VIEW_CLASS_128_BITS            0x82C4
#define GL_VIEW_CLASS_96_BITS             0x82C5
#define GL_VIEW_CLASS_64_BITS             0x82C6
#define GL_VIEW_CLASS_48_BITS             0x82C7
#define GL_VIEW_CLASS_32_BITS             0x82C8
#define GL_VIEW_CLASS_24_BITS             0x82C9
#define GL_VIEW_CLASS_16_BITS             0x82CA
#define GL_VIEW_CLASS_8_BITS              0x82CB
#define GL_VIEW_CLASS_S3TC_DXT1_RGB       0x82CC
#define GL_VIEW_CLASS_S3TC_DXT1_RGBA      0x82CD
#define GL_VIEW_CLASS_S3TC_DXT3_RGBA      0x82CE
#define GL_VIEW_CLASS_S3TC_DXT5_RGBA      0x82CF
#define GL_VIEW_CLASS_RGTC1_RED           0x82D0
#define GL_VIEW_CLASS_RGTC2_RG            0x82D1
#define GL_VIEW_CLASS_BPTC_UNORM          0x82D2
#define GL_VIEW_CLASS_BPTC_FLOAT          0x82D3
#define GL_UNIFORM                        0x92E1
#define GL_UNIFORM_BLOCK                  0x92E2
#define GL_PROGRAM_INPUT                  0x92E3
#define GL_PROGRAM_OUTPUT                 0x92E4
#define GL_BUFFER_VARIABLE                0x92E5
#define GL_SHADER_STORAGE_BLOCK           0x92E6
#define GL_VERTEX_SUBROUTINE              0x92E8
#define GL_TESS_CONTROL_SUBROUTINE        0x92E9
#define GL_TESS_EVALUATION_SUBROUTINE     0x92EA
#define GL_GEOMETRY_SUBROUTINE            0x92EB
#define GL_FRAGMENT_SUBROUTINE            0x92EC
#define GL_COMPUTE_SUBROUTINE             0x92ED
#define GL_VERTEX_SUBROUTINE_UNIFORM      0x92EE
#define GL_TESS_CONTROL_SUBROUTINE_UNIFORM 0x92EF
#define GL_TESS_EVALUATION_SUBROUTINE_UNIFORM 0x92F0
#define GL_GEOMETRY_SUBROUTINE_UNIFORM    0x92F1
#define GL_FRAGMENT_SUBROUTINE_UNIFORM    0x92F2
#define GL_COMPUTE_SUBROUTINE_UNIFORM     0x92F3
#define GL_TRANSFORM_FEEDBACK_VARYING     0x92F4
#define GL_ACTIVE_RESOURCES               0x92F5
#define GL_MAX_NAME_LENGTH                0x92F6
#define GL_MAX_NUM_ACTIVE_VARIABLES       0x92F7
#define GL_MAX_NUM_COMPATIBLE_SUBROUTINES 0x92F8
#define GL_NAME_LENGTH                    0x92F9
#define GL_TYPE                           0x92FA
#define GL_ARRAY_SIZE                     0x92FB
#define GL_OFFSET                         0x92FC
#define GL_BLOCK_INDEX                    0x92FD
#define GL_ARRAY_STRIDE                   0x92FE
#define GL_MATRIX_STRIDE                  0x92FF
#define GL_IS_ROW_MAJOR                   0x9300
#define GL_ATOMIC_COUNTER_BUFFER_INDEX    0x9301
#define GL_BUFFER_BINDING                 0x9302
#define GL_BUFFER_DATA_SIZE               0x9303
#define GL_NUM_ACTIVE_VARIABLES           0x9304
#define GL_ACTIVE_VARIABLES               0x9305
#define GL_REFERENCED_BY_VERTEX_SHADER    0x9306
#define GL_REFERENCED_BY_TESS_CONTROL_SHADER 0x9307
#define GL_REFERENCED_BY_TESS_EVALUATION_SHADER 0x9308
#define GL_REFERENCED_BY_GEOMETRY_SHADER  0x9309
#define GL_REFERENCED_BY_FRAGMENT_SHADER  0x930A
#define GL_REFERENCED_BY_COMPUTE_SHADER   0x930B
#define GL_TOP_LEVEL_ARRAY_SIZE           0x930C
#define GL_TOP_LEVEL_ARRAY_STRIDE         0x930D
#define GL_LOCATION                       0x930E
#define GL_LOCATION_INDEX                 0x930F
#define GL_IS_PER_PATCH                   0x92E7
#define GL_SHADER_STORAGE_BUFFER          0x90D2
#define GL_SHADER_STORAGE_BUFFER_BINDING  0x90D3
#define GL_SHADER_STORAGE_BUFFER_START    0x90D4
#define GL_SHADER_STORAGE_BUFFER_SIZE     0x90D5
#define GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS 0x90D6
#define GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS 0x90D7
#define GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS 0x90D8
#define GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS 0x90D9
#define GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS 0x90DA
#define GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS 0x90DB
#define GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS 0x90DC
#define GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS 0x90DD
#define GL_MAX_SHADER_STORAGE_BLOCK_SIZE  0x90DE
#define GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT 0x90DF
#define GL_SHADER_STORAGE_BARRIER_BIT     0x00002000
#define GL_MAX_COMBINED_SHADER_OUTPUT_RESOURCES 0x8F39
#define GL_DEPTH_STENCIL_TEXTURE_MODE     0x90EA
#define GL_TEXTURE_BUFFER_OFFSET          0x919D
#define GL_TEXTURE_BUFFER_SIZE            0x919E
#define GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT 0x919F
#define GL_TEXTURE_VIEW_MIN_LEVEL         0x82DB
#define GL_TEXTURE_VIEW_NUM_LEVELS        0x82DC
#define GL_TEXTURE_VIEW_MIN_LAYER         0x82DD
#define GL_TEXTURE_VIEW_NUM_LAYERS        0x82DE
#define GL_TEXTURE_IMMUTABLE_LEVELS       0x82DF
#define GL_VERTEX_ATTRIB_BINDING          0x82D4
#define GL_VERTEX_ATTRIB_RELATIVE_OFFSET  0x82D5
#define GL_VERTEX_BINDING_DIVISOR         0x82D6
#define GL_VERTEX_BINDING_OFFSET          0x82D7
#define GL_VERTEX_BINDING_STRIDE          0x82D8
#define GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET 0x82D9
#define GL_MAX_VERTEX_ATTRIB_BINDINGS     0x82DA
#define GL_VERTEX_BINDING_BUFFER          0x8F4F
typedef void (APIENTRYP PFNGLCLEARBUFFERDATAPROC) (GLenum target, GLenum internalformat, GLenum format, GLenum type, const void *data);
typedef void (APIENTRYP PFNGLCLEARBUFFERSUBDATAPROC) (GLenum target, GLenum internalformat, GLintptr offset, GLsizeiptr size, GLenum format, GLenum type, const void *data);
typedef void (APIENTRYP PFNGLDISPATCHCOMPUTEPROC) (GLuint num_groups_x, GLuint num_groups_y, GLuint num_groups_z);
typedef void (APIENTRYP PFNGLDISPATCHCOMPUTEINDIRECTPROC) (GLintptr indirect);
typedef void (APIENTRYP PFNGLCOPYIMAGESUBDATAPROC) (GLuint srcName, GLenum srcTarget, GLint srcLevel, GLint srcX, GLint srcY, GLint srcZ, GLuint dstName, GLenum dstTarget, GLint dstLevel, GLint dstX, GLint dstY, GLint dstZ, GLsizei srcWidth, GLsizei srcHeight, GLsizei srcDepth);
typedef void (APIENTRYP PFNGLFRAMEBUFFERPARAMETERIPROC) (GLenum target, GLenum pname, GLint param);
typedef void (APIENTRYP PFNGLGETFRAMEBUFFERPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETINTERNALFORMATI64VPROC) (GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint64 *params);
typedef void (APIENTRYP PFNGLINVALIDATETEXSUBIMAGEPROC) (GLuint texture, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth);
typedef void (APIENTRYP PFNGLINVALIDATETEXIMAGEPROC) (GLuint texture, GLint level);
typedef void (APIENTRYP PFNGLINVALIDATEBUFFERSUBDATAPROC) (GLuint buffer, GLintptr offset, GLsizeiptr length);
typedef void (APIENTRYP PFNGLINVALIDATEBUFFERDATAPROC) (GLuint buffer);
typedef void (APIENTRYP PFNGLINVALIDATEFRAMEBUFFERPROC) (GLenum target, GLsizei numAttachments, const GLenum *attachments);
typedef void (APIENTRYP PFNGLINVALIDATESUBFRAMEBUFFERPROC) (GLenum target, GLsizei numAttachments, const GLenum *attachments, GLint x, GLint y, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLMULTIDRAWARRAYSINDIRECTPROC) (GLenum mode, const void *indirect, GLsizei drawcount, GLsizei stride);
typedef void (APIENTRYP PFNGLMULTIDRAWELEMENTSINDIRECTPROC) (GLenum mode, GLenum type, const void *indirect, GLsizei drawcount, GLsizei stride);
typedef void (APIENTRYP PFNGLGETPROGRAMINTERFACEIVPROC) (GLuint program, GLenum programInterface, GLenum pname, GLint *params);
typedef GLuint (APIENTRYP PFNGLGETPROGRAMRESOURCEINDEXPROC) (GLuint program, GLenum programInterface, const GLchar *name);
typedef void (APIENTRYP PFNGLGETPROGRAMRESOURCENAMEPROC) (GLuint program, GLenum programInterface, GLuint index, GLsizei bufSize, GLsizei *length, GLchar *name);
typedef void (APIENTRYP PFNGLGETPROGRAMRESOURCEIVPROC) (GLuint program, GLenum programInterface, GLuint index, GLsizei propCount, const GLenum *props, GLsizei bufSize, GLsizei *length, GLint *params);
typedef GLint (APIENTRYP PFNGLGETPROGRAMRESOURCELOCATIONPROC) (GLuint program, GLenum programInterface, const GLchar *name);
typedef GLint (APIENTRYP PFNGLGETPROGRAMRESOURCELOCATIONINDEXPROC) (GLuint program, GLenum programInterface, const GLchar *name);
typedef void (APIENTRYP PFNGLSHADERSTORAGEBLOCKBINDINGPROC) (GLuint program, GLuint storageBlockIndex, GLuint storageBlockBinding);
typedef void (APIENTRYP PFNGLTEXBUFFERRANGEPROC) (GLenum target, GLenum internalformat, GLuint buffer, GLintptr offset, GLsizeiptr size);
typedef void (APIENTRYP PFNGLTEXSTORAGE2DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLboolean fixedsamplelocations);
typedef void (APIENTRYP PFNGLTEXSTORAGE3DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedsamplelocations);
typedef void (APIENTRYP PFNGLTEXTUREVIEWPROC) (GLuint texture, GLenum target, GLuint origtexture, GLenum internalformat, GLuint minlevel, GLuint numlevels, GLuint minlayer, GLuint numlayers);
typedef void (APIENTRYP PFNGLBINDVERTEXBUFFERPROC) (GLuint bindingindex, GLuint buffer, GLintptr offset, GLsizei stride);
typedef void (APIENTRYP PFNGLVERTEXATTRIBFORMATPROC) (GLuint attribindex, GLint size, GLenum type, GLboolean normalized, GLuint relativeoffset);
typedef void (APIENTRYP PFNGLVERTEXATTRIBIFORMATPROC) (GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
typedef void (APIENTRYP PFNGLVERTEXATTRIBLFORMATPROC) (GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
typedef void (APIENTRYP PFNGLVERTEXATTRIBBINDINGPROC) (GLuint attribindex, GLuint bindingindex);
typedef void (APIENTRYP PFNGLVERTEXBINDINGDIVISORPROC) (GLuint bindingindex, GLuint divisor);
typedef void (APIENTRYP PFNGLDEBUGMESSAGECONTROLPROC) (GLenum source, GLenum type, GLenum severity, GLsizei count, const GLuint *ids, GLboolean enabled);
typedef void (APIENTRYP PFNGLDEBUGMESSAGEINSERTPROC) (GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *buf);
typedef void (APIENTRYP PFNGLDEBUGMESSAGECALLBACKPROC) (GLDEBUGPROC callback, const void *userParam);
typedef GLuint (APIENTRYP PFNGLGETDEBUGMESSAGELOGPROC) (GLuint count, GLsizei bufSize, GLenum *sources, GLenum *types, GLuint *ids, GLenum *severities, GLsizei *lengths, GLchar *messageLog);
typedef void (APIENTRYP PFNGLPUSHDEBUGGROUPPROC) (GLenum source, GLuint id, GLsizei length, const GLchar *message);
typedef void (APIENTRYP PFNGLPOPDEBUGGROUPPROC) (void);
typedef void (APIENTRYP PFNGLOBJECTLABELPROC) (GLenum identifier, GLuint name, GLsizei length, const GLchar *label);
typedef void (APIENTRYP PFNGLGETOBJECTLABELPROC) (GLenum identifier, GLuint name, GLsizei bufSize, GLsizei *length, GLchar *label);
typedef void (APIENTRYP PFNGLOBJECTPTRLABELPROC) (const void *ptr, GLsizei length, const GLchar *label);
typedef void (APIENTRYP PFNGLGETOBJECTPTRLABELPROC) (const void *ptr, GLsizei bufSize, GLsizei *length, GLchar *label);

#define GL_MAX_VERTEX_ATTRIB_STRIDE       0x82E5
#define GL_PRIMITIVE_RESTART_FOR_PATCHES_SUPPORTED 0x8221
#define GL_TEXTURE_BUFFER_BINDING         0x8C2A
#define GL_MAP_PERSISTENT_BIT             0x0040
#define GL_MAP_COHERENT_BIT               0x0080
#define GL_DYNAMIC_STORAGE_BIT            0x0100
#define GL_CLIENT_STORAGE_BIT             0x0200
#define GL_CLIENT_MAPPED_BUFFER_BARRIER_BIT 0x00004000
#define GL_BUFFER_IMMUTABLE_STORAGE       0x821F
#define GL_BUFFER_STORAGE_FLAGS           0x8220
#define GL_CLEAR_TEXTURE                  0x9365
#define GL_LOCATION_COMPONENT             0x934A
#define GL_TRANSFORM_FEEDBACK_BUFFER_INDEX 0x934B
#define GL_TRANSFORM_FEEDBACK_BUFFER_STRIDE 0x934C
#define GL_QUERY_BUFFER                   0x9192
#define GL_QUERY_BUFFER_BARRIER_BIT       0x00008000
#define GL_QUERY_BUFFER_BINDING           0x9193
#define GL_QUERY_RESULT_NO_WAIT           0x9194
#define GL_MIRROR_CLAMP_TO_EDGE           0x8743
typedef void (APIENTRYP PFNGLBUFFERSTORAGEPROC) (GLenum target, GLsizeiptr size, const void *data, GLbitfield flags);
typedef void (APIENTRYP PFNGLCLEARTEXIMAGEPROC) (GLuint texture, GLint level, GLenum format, GLenum type, const void *data);
typedef void (APIENTRYP PFNGLCLEARTEXSUBIMAGEPROC) (GLuint texture, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const void *data);
typedef void (APIENTRYP PFNGLBINDBUFFERSBASEPROC) (GLenum target, GLuint first, GLsizei count, const GLuint *buffers);
typedef void (APIENTRYP PFNGLBINDBUFFERSRANGEPROC) (GLenum target, GLuint first, GLsizei count, const GLuint *buffers, const GLintptr *offsets, const GLsizeiptr *sizes);
typedef void (APIENTRYP PFNGLBINDTEXTURESPROC) (GLuint first, GLsizei count, const GLuint *textures);
typedef void (APIENTRYP PFNGLBINDSAMPLERSPROC) (GLuint first, GLsizei count, const GLuint *samplers);
typedef void (APIENTRYP PFNGLBINDIMAGETEXTURESPROC) (GLuint first, GLsizei count, const GLuint *textures);
typedef void (APIENTRYP PFNGLBINDVERTEXBUFFERSPROC) (GLuint first, GLsizei count, const GLuint *buffers, const GLintptr *offsets, const GLsizei *strides);

typedef uint64_t GLuint64EXT;
#define GL_UNSIGNED_INT64_ARB             0x140F
typedef GLuint64 (APIENTRYP PFNGLGETTEXTUREHANDLEARBPROC) (GLuint texture);
typedef GLuint64 (APIENTRYP PFNGLGETTEXTURESAMPLERHANDLEARBPROC) (GLuint texture, GLuint sampler);
typedef void (APIENTRYP PFNGLMAKETEXTUREHANDLERESIDENTARBPROC) (GLuint64 handle);
typedef void (APIENTRYP PFNGLMAKETEXTUREHANDLENONRESIDENTARBPROC) (GLuint64 handle);
typedef GLuint64 (APIENTRYP PFNGLGETIMAGEHANDLEARBPROC) (GLuint texture, GLint level, GLboolean layered, GLint layer, GLenum format);
typedef void (APIENTRYP PFNGLMAKEIMAGEHANDLERESIDENTARBPROC) (GLuint64 handle, GLenum access);
typedef void (APIENTRYP PFNGLMAKEIMAGEHANDLENONRESIDENTARBPROC) (GLuint64 handle);
typedef void (APIENTRYP PFNGLUNIFORMHANDLEUI64ARBPROC) (GLint location, GLuint64 value);
typedef void (APIENTRYP PFNGLUNIFORMHANDLEUI64VARBPROC) (GLint location, GLsizei count, const GLuint64 *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMHANDLEUI64ARBPROC) (GLuint program, GLint location, GLuint64 value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMHANDLEUI64VARBPROC) (GLuint program, GLint location, GLsizei count, const GLuint64 *values);
typedef GLboolean (APIENTRYP PFNGLISTEXTUREHANDLERESIDENTARBPROC) (GLuint64 handle);
typedef GLboolean (APIENTRYP PFNGLISIMAGEHANDLERESIDENTARBPROC) (GLuint64 handle);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL1UI64ARBPROC) (GLuint index, GLuint64EXT x);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL1UI64VARBPROC) (GLuint index, const GLuint64EXT *v);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBLUI64VARBPROC) (GLuint index, GLenum pname, GLuint64EXT *params);

struct _cl_context;
struct _cl_event;
#define GL_SYNC_CL_EVENT_ARB              0x8240
#define GL_SYNC_CL_EVENT_COMPLETE_ARB     0x8241
typedef GLsync (APIENTRYP PFNGLCREATESYNCFROMCLEVENTARBPROC) (struct _cl_context *context, struct _cl_event *event, GLbitfield flags);

#define GL_COMPUTE_SHADER_BIT             0x00000020

#define GL_MAX_COMPUTE_VARIABLE_GROUP_INVOCATIONS_ARB 0x9344
#define GL_MAX_COMPUTE_FIXED_GROUP_INVOCATIONS_ARB 0x90EB
#define GL_MAX_COMPUTE_VARIABLE_GROUP_SIZE_ARB 0x9345
#define GL_MAX_COMPUTE_FIXED_GROUP_SIZE_ARB 0x91BF
typedef void (APIENTRYP PFNGLDISPATCHCOMPUTEGROUPSIZEARBPROC) (GLuint num_groups_x, GLuint num_groups_y, GLuint num_groups_z, GLuint group_size_x, GLuint group_size_y, GLuint group_size_z);

#define GL_COPY_READ_BUFFER_BINDING       0x8F36
#define GL_COPY_WRITE_BUFFER_BINDING      0x8F37

typedef void (APIENTRY  *GLDEBUGPROCARB)(GLenum source,GLenum type,GLuint id,GLenum severity,GLsizei length,const GLchar *message,const void *userParam);
#define GL_DEBUG_OUTPUT_SYNCHRONOUS_ARB   0x8242
#define GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH_ARB 0x8243
#define GL_DEBUG_CALLBACK_FUNCTION_ARB    0x8244
#define GL_DEBUG_CALLBACK_USER_PARAM_ARB  0x8245
#define GL_DEBUG_SOURCE_API_ARB           0x8246
#define GL_DEBUG_SOURCE_WINDOW_SYSTEM_ARB 0x8247
#define GL_DEBUG_SOURCE_SHADER_COMPILER_ARB 0x8248
#define GL_DEBUG_SOURCE_THIRD_PARTY_ARB   0x8249
#define GL_DEBUG_SOURCE_APPLICATION_ARB   0x824A
#define GL_DEBUG_SOURCE_OTHER_ARB         0x824B
#define GL_DEBUG_TYPE_ERROR_ARB           0x824C
#define GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB 0x824D
#define GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB 0x824E
#define GL_DEBUG_TYPE_PORTABILITY_ARB     0x824F
#define GL_DEBUG_TYPE_PERFORMANCE_ARB     0x8250
#define GL_DEBUG_TYPE_OTHER_ARB           0x8251
#define GL_MAX_DEBUG_MESSAGE_LENGTH_ARB   0x9143
#define GL_MAX_DEBUG_LOGGED_MESSAGES_ARB  0x9144
#define GL_DEBUG_LOGGED_MESSAGES_ARB      0x9145
#define GL_DEBUG_SEVERITY_HIGH_ARB        0x9146
#define GL_DEBUG_SEVERITY_MEDIUM_ARB      0x9147
#define GL_DEBUG_SEVERITY_LOW_ARB         0x9148
typedef void (APIENTRYP PFNGLDEBUGMESSAGECONTROLARBPROC) (GLenum source, GLenum type, GLenum severity, GLsizei count, const GLuint *ids, GLboolean enabled);
typedef void (APIENTRYP PFNGLDEBUGMESSAGEINSERTARBPROC) (GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *buf);
typedef void (APIENTRYP PFNGLDEBUGMESSAGECALLBACKARBPROC) (GLDEBUGPROCARB callback, const void *userParam);
typedef GLuint (APIENTRYP PFNGLGETDEBUGMESSAGELOGARBPROC) (GLuint count, GLsizei bufSize, GLenum *sources, GLenum *types, GLuint *ids, GLenum *severities, GLsizei *lengths, GLchar *messageLog);

typedef void (APIENTRYP PFNGLBLENDEQUATIONIARBPROC) (GLuint buf, GLenum mode);
typedef void (APIENTRYP PFNGLBLENDEQUATIONSEPARATEIARBPROC) (GLuint buf, GLenum modeRGB, GLenum modeAlpha);
typedef void (APIENTRYP PFNGLBLENDFUNCIARBPROC) (GLuint buf, GLenum src, GLenum dst);
typedef void (APIENTRYP PFNGLBLENDFUNCSEPARATEIARBPROC) (GLuint buf, GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);

#define GL_BLEND_COLOR                    0x8005
#define GL_BLEND_EQUATION                 0x8009

#define GL_PARAMETER_BUFFER_ARB           0x80EE
#define GL_PARAMETER_BUFFER_BINDING_ARB   0x80EF
typedef void (APIENTRYP PFNGLMULTIDRAWARRAYSINDIRECTCOUNTARBPROC) (GLenum mode, GLintptr indirect, GLintptr drawcount, GLsizei maxdrawcount, GLsizei stride);
typedef void (APIENTRYP PFNGLMULTIDRAWELEMENTSINDIRECTCOUNTARBPROC) (GLenum mode, GLenum type, GLintptr indirect, GLintptr drawcount, GLsizei maxdrawcount, GLsizei stride);

#define GL_SRGB_DECODE_ARB                0x8299

#define GL_CONTEXT_FLAG_ROBUST_ACCESS_BIT_ARB 0x00000004
#define GL_LOSE_CONTEXT_ON_RESET_ARB      0x8252
#define GL_GUILTY_CONTEXT_RESET_ARB       0x8253
#define GL_INNOCENT_CONTEXT_RESET_ARB     0x8254
#define GL_UNKNOWN_CONTEXT_RESET_ARB      0x8255
#define GL_RESET_NOTIFICATION_STRATEGY_ARB 0x8256
#define GL_NO_RESET_NOTIFICATION_ARB      0x8261
typedef GLenum (APIENTRYP PFNGLGETGRAPHICSRESETSTATUSARBPROC) (void);
typedef void (APIENTRYP PFNGLGETNTEXIMAGEARBPROC) (GLenum target, GLint level, GLenum format, GLenum type, GLsizei bufSize, void *img);
typedef void (APIENTRYP PFNGLREADNPIXELSARBPROC) (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLsizei bufSize, void *data);
typedef void (APIENTRYP PFNGLGETNCOMPRESSEDTEXIMAGEARBPROC) (GLenum target, GLint lod, GLsizei bufSize, void *img);
typedef void (APIENTRYP PFNGLGETNUNIFORMFVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLfloat *params);
typedef void (APIENTRYP PFNGLGETNUNIFORMIVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLint *params);
typedef void (APIENTRYP PFNGLGETNUNIFORMUIVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLuint *params);
typedef void (APIENTRYP PFNGLGETNUNIFORMDVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLdouble *params);

#define GL_SAMPLE_SHADING_ARB             0x8C36
#define GL_MIN_SAMPLE_SHADING_VALUE_ARB   0x8C37
typedef void (APIENTRYP PFNGLMINSAMPLESHADINGARBPROC) (GLfloat value);

#define GL_SHADER_INCLUDE_ARB             0x8DAE
#define GL_NAMED_STRING_LENGTH_ARB        0x8DE9
#define GL_NAMED_STRING_TYPE_ARB          0x8DEA
typedef void (APIENTRYP PFNGLNAMEDSTRINGARBPROC) (GLenum type, GLint namelen, const GLchar *name, GLint stringlen, const GLchar *string);
typedef void (APIENTRYP PFNGLDELETENAMEDSTRINGARBPROC) (GLint namelen, const GLchar *name);
typedef void (APIENTRYP PFNGLCOMPILESHADERINCLUDEARBPROC) (GLuint shader, GLsizei count, const GLchar *const*path, const GLint *length);
typedef GLboolean (APIENTRYP PFNGLISNAMEDSTRINGARBPROC) (GLint namelen, const GLchar *name);
typedef void (APIENTRYP PFNGLGETNAMEDSTRINGARBPROC) (GLint namelen, const GLchar *name, GLsizei bufSize, GLint *stringlen, GLchar *string);
typedef void (APIENTRYP PFNGLGETNAMEDSTRINGIVARBPROC) (GLint namelen, const GLchar *name, GLenum pname, GLint *params);

#define GL_TEXTURE_SPARSE_ARB             0x91A6
#define GL_VIRTUAL_PAGE_SIZE_INDEX_ARB    0x91A7
#define GL_MIN_SPARSE_LEVEL_ARB           0x919B
#define GL_NUM_VIRTUAL_PAGE_SIZES_ARB     0x91A8
#define GL_VIRTUAL_PAGE_SIZE_X_ARB        0x9195
#define GL_VIRTUAL_PAGE_SIZE_Y_ARB        0x9196
#define GL_VIRTUAL_PAGE_SIZE_Z_ARB        0x9197
#define GL_MAX_SPARSE_TEXTURE_SIZE_ARB    0x9198
#define GL_MAX_SPARSE_3D_TEXTURE_SIZE_ARB 0x9199
#define GL_MAX_SPARSE_ARRAY_TEXTURE_LAYERS_ARB 0x919A
#define GL_SPARSE_TEXTURE_FULL_ARRAY_CUBE_MIPMAPS_ARB 0x91A9
typedef void (APIENTRYP PFNGLTEXPAGECOMMITMENTARBPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLboolean resident);

#define GL_COMPRESSED_RGBA_BPTC_UNORM_ARB 0x8E8C
#define GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM_ARB 0x8E8D
#define GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT_ARB 0x8E8E
#define GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_ARB 0x8E8F

#define GL_TEXTURE_CUBE_MAP_ARRAY_ARB     0x9009
#define GL_TEXTURE_BINDING_CUBE_MAP_ARRAY_ARB 0x900A
#define GL_PROXY_TEXTURE_CUBE_MAP_ARRAY_ARB 0x900B
#define GL_SAMPLER_CUBE_MAP_ARRAY_ARB     0x900C
#define GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW_ARB 0x900D
#define GL_INT_SAMPLER_CUBE_MAP_ARRAY_ARB 0x900E
#define GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY_ARB 0x900F

#define GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET_ARB 0x8E5E
#define GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET_ARB 0x8E5F
#define GL_MAX_PROGRAM_TEXTURE_GATHER_COMPONENTS_ARB 0x8F9F

#define GL_TRANSFORM_FEEDBACK_PAUSED      0x8E23
#define GL_TRANSFORM_FEEDBACK_ACTIVE      0x8E24

#define GL_MAX_GEOMETRY_UNIFORM_BLOCKS    0x8A2C
#define GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS 0x8A32
#define GL_UNIFORM_BLOCK_REFERENCED_BY_GEOMETRY_SHADER 0x8A45

#define GL_COMPRESSED_RGBA_ASTC_4x4_KHR   0x93B0
#define GL_COMPRESSED_RGBA_ASTC_5x4_KHR   0x93B1
#define GL_COMPRESSED_RGBA_ASTC_5x5_KHR   0x93B2
#define GL_COMPRESSED_RGBA_ASTC_6x5_KHR   0x93B3
#define GL_COMPRESSED_RGBA_ASTC_6x6_KHR   0x93B4
#define GL_COMPRESSED_RGBA_ASTC_8x5_KHR   0x93B5
#define GL_COMPRESSED_RGBA_ASTC_8x6_KHR   0x93B6
#define GL_COMPRESSED_RGBA_ASTC_8x8_KHR   0x93B7
#define GL_COMPRESSED_RGBA_ASTC_10x5_KHR  0x93B8
#define GL_COMPRESSED_RGBA_ASTC_10x6_KHR  0x93B9
#define GL_COMPRESSED_RGBA_ASTC_10x8_KHR  0x93BA
#define GL_COMPRESSED_RGBA_ASTC_10x10_KHR 0x93BB
#define GL_COMPRESSED_RGBA_ASTC_12x10_KHR 0x93BC
#define GL_COMPRESSED_RGBA_ASTC_12x12_KHR 0x93BD
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR 0x93D0
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR 0x93D1
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR 0x93D2
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR 0x93D3
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR 0x93D4
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR 0x93D5
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR 0x93D6
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR 0x93D7
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR 0x93D8
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR 0x93D9
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR 0x93DA
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR 0x93DB
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR 0x93DC
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR 0x93DD

#define GL_TEXTURE_MAX_ANISOTROPY_EXT 0x84FE
#define GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT 0x84FF
]]

local openGL = {
	GL = {},
	gl = {},
	loader = nil,

	import = function(self)
		rawset(_G, "GL", self.GL)
		rawset(_G, "gl", self.gl)
	end
}

if ffi.os == "Windows" then
	glheader = glheader:gsub("APIENTRYP", "__stdcall *")
	glheader = glheader:gsub("APIENTRY", "__stdcall")
else
	glheader = glheader:gsub("APIENTRYP", "*")
	glheader = glheader:gsub("APIENTRY", "")
end

local type_glenum = ffi.typeof("unsigned int")
local type_uint64 = ffi.typeof("uint64_t")

local function constant_replace(name, value)
	local ctype = type_glenum
	local GL = openGL.GL

	local num = tonumber(value)
	if (not num) then
		if (value:match("ull$")) then
			--Potentially reevaluate this for LuaJIT 2.1
			GL[name] = loadstring("return " .. value)()
		elseif (value:match("u$")) then
			value = value:gsub("u$", "")
			num = tonumber(value)
		end
	end
	
	GL[name] = GL[name] or ctype(num)
	
	return ""
end

glheader = glheader:gsub("#define GL_(%S+)%s+(%S+)\n", constant_replace)

ffi.cdef(glheader)

local gl_mt = {
	__index = function(self, name)
		local glname = "gl" .. name
		local procname = "PFNGL" .. name:upper() .. "PROC"
		local func = ffi.cast(procname, openGL.loader(glname))
		if func == nil then
			error("GL function \"" .. glname .. "\" doesn't exist or the GL context isn't active yet.")
		end
		rawset(self, name, func)
		return func
	end
}

setmetatable(openGL.gl, gl_mt)

return openGLZ   �4  4 % 7 >4  4 % 7 >G  glGL_Grawsetself   � 		 /e�+  + 7 4  >  T� 7% >  T�4 %  $>>9 T� 7% >  T
� 7% % > 4  > 6   T�  >9 % H ��	gsubu$return loadstring	ull$
matchtonumberGL						





type_glenum openGL name  0value  0ctype .GL ,num ) � 	
 T�	%   $%  7>% $+  7 + 7 > =  T�4 %  % $>4	     >H  ��rawset8" doesn't exist or the GL context isn't active yet.GL function "
errorloader	cast	PROC
upper
PFNGLglffi openGL self   name   glname procname func  �� 
  @� �4   % > % 3 2  :2  :1 :7 	 T� 7
% % >  7
% % > T� 7
% % >  7
% % > 7 % >7 % >1  7
% 	 > 7  >3 1 :4 7	 >0  �H setmetatable__index   	cdef#define GL_(%S+)%s+(%S+)
 uint64_tunsigned inttypeof*__stdcallAPIENTRY__stdcall *APIENTRYP	gsubWindowsosimport glGL  ��/*
** Copyright (c) 2013-2014 The Khronos Group Inc.
**
** Permission is hereby granted, free of charge, to any person obtaining a
** copy of this software and/or associated documentation files (the
** "Materials"), to deal in the Materials without restriction, including
** without limitation the rights to use, copy, modify, merge, publish,
** distribute, sublicense, and/or sell copies of the Materials, and to
** permit persons to whom the Materials are furnished to do so, subject to
** the following conditions:
**
** The above copyright notice and this permission notice shall be included
** in all copies or substantial portions of the Materials.
**
** THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
** EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
** MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
** CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
** TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
** MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
*/
/*
** This header is generated from the Khronos OpenGL / OpenGL ES XML
** API Registry. The current version of the Registry, generator scripts
** used to make the header, and the header can be found at
**   http://www.opengl.org/registry/
**
** Khronos $Revision: 26007 $ on $Date: 2014-03-19 01:28:09 -0700 (Wed, 19 Mar 2014) $
*/

/* glcorearb.h is for use with OpenGL core profile implementations.
** It should should be placed in the same directory as gl.h and
** included as <GL/glcorearb.h>.
**
** glcorearb.h includes only APIs in the latest OpenGL core profile
** implementation together with APIs in newer ARB extensions which 
** can be supported by the core profile. It does not, and never will
** include functionality removed from the core profile, such as
** fixed-function vertex and fragment processing.
**
** Do not #include both <GL/glcorearb.h> and either of <GL/gl.h> or
** <GL/glext.h> in the same source file.
*/

/* Generated C header for:
 * API: gl
 * Profile: core
 * Versions considered: .*
 * Versions emitted: .*
 * Default extensions included: glcore
 * Additional extensions included: _nomatch_^
 * Extensions removed: _nomatch_^
 */

typedef void GLvoid;
typedef unsigned int GLenum;
typedef float GLfloat;
typedef int GLint;
typedef int GLsizei;
typedef unsigned int GLbitfield;
typedef double GLdouble;
typedef unsigned int GLuint;
typedef unsigned char GLboolean;
typedef unsigned char GLubyte;
typedef void (APIENTRYP PFNGLCULLFACEPROC) (GLenum mode);
typedef void (APIENTRYP PFNGLFRONTFACEPROC) (GLenum mode);
typedef void (APIENTRYP PFNGLHINTPROC) (GLenum target, GLenum mode);
typedef void (APIENTRYP PFNGLLINEWIDTHPROC) (GLfloat width);
typedef void (APIENTRYP PFNGLPOINTSIZEPROC) (GLfloat size);
typedef void (APIENTRYP PFNGLPOLYGONMODEPROC) (GLenum face, GLenum mode);
typedef void (APIENTRYP PFNGLSCISSORPROC) (GLint x, GLint y, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLTEXPARAMETERFPROC) (GLenum target, GLenum pname, GLfloat param);
typedef void (APIENTRYP PFNGLTEXPARAMETERFVPROC) (GLenum target, GLenum pname, const GLfloat *params);
typedef void (APIENTRYP PFNGLTEXPARAMETERIPROC) (GLenum target, GLenum pname, GLint param);
typedef void (APIENTRYP PFNGLTEXPARAMETERIVPROC) (GLenum target, GLenum pname, const GLint *params);
typedef void (APIENTRYP PFNGLTEXIMAGE1DPROC) (GLenum target, GLint level, GLint internalformat, GLsizei width, GLint border, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLTEXIMAGE2DPROC) (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLDRAWBUFFERPROC) (GLenum mode);
typedef void (APIENTRYP PFNGLCLEARPROC) (GLbitfield mask);
typedef void (APIENTRYP PFNGLCLEARCOLORPROC) (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
typedef void (APIENTRYP PFNGLCLEARSTENCILPROC) (GLint s);
typedef void (APIENTRYP PFNGLCLEARDEPTHPROC) (GLdouble depth);
typedef void (APIENTRYP PFNGLSTENCILMASKPROC) (GLuint mask);
typedef void (APIENTRYP PFNGLCOLORMASKPROC) (GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);
typedef void (APIENTRYP PFNGLDEPTHMASKPROC) (GLboolean flag);
typedef void (APIENTRYP PFNGLDISABLEPROC) (GLenum cap);
typedef void (APIENTRYP PFNGLENABLEPROC) (GLenum cap);
typedef void (APIENTRYP PFNGLFINISHPROC) (void);
typedef void (APIENTRYP PFNGLFLUSHPROC) (void);
typedef void (APIENTRYP PFNGLBLENDFUNCPROC) (GLenum sfactor, GLenum dfactor);
typedef void (APIENTRYP PFNGLLOGICOPPROC) (GLenum opcode);
typedef void (APIENTRYP PFNGLSTENCILFUNCPROC) (GLenum func, GLint ref, GLuint mask);
typedef void (APIENTRYP PFNGLSTENCILOPPROC) (GLenum fail, GLenum zfail, GLenum zpass);
typedef void (APIENTRYP PFNGLDEPTHFUNCPROC) (GLenum func);
typedef void (APIENTRYP PFNGLPIXELSTOREFPROC) (GLenum pname, GLfloat param);
typedef void (APIENTRYP PFNGLPIXELSTOREIPROC) (GLenum pname, GLint param);
typedef void (APIENTRYP PFNGLREADBUFFERPROC) (GLenum mode);
typedef void (APIENTRYP PFNGLREADPIXELSPROC) (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, void *pixels);
typedef void (APIENTRYP PFNGLGETBOOLEANVPROC) (GLenum pname, GLboolean *data);
typedef void (APIENTRYP PFNGLGETDOUBLEVPROC) (GLenum pname, GLdouble *data);
typedef GLenum (APIENTRYP PFNGLGETERRORPROC) (void);
typedef void (APIENTRYP PFNGLGETFLOATVPROC) (GLenum pname, GLfloat *data);
typedef void (APIENTRYP PFNGLGETINTEGERVPROC) (GLenum pname, GLint *data);
typedef const GLubyte *(APIENTRYP PFNGLGETSTRINGPROC) (GLenum name);
typedef void (APIENTRYP PFNGLGETTEXIMAGEPROC) (GLenum target, GLint level, GLenum format, GLenum type, void *pixels);
typedef void (APIENTRYP PFNGLGETTEXPARAMETERFVPROC) (GLenum target, GLenum pname, GLfloat *params);
typedef void (APIENTRYP PFNGLGETTEXPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETTEXLEVELPARAMETERFVPROC) (GLenum target, GLint level, GLenum pname, GLfloat *params);
typedef void (APIENTRYP PFNGLGETTEXLEVELPARAMETERIVPROC) (GLenum target, GLint level, GLenum pname, GLint *params);
typedef GLboolean (APIENTRYP PFNGLISENABLEDPROC) (GLenum cap);
typedef void (APIENTRYP PFNGLDEPTHRANGEPROC) (GLdouble near, GLdouble far);
typedef void (APIENTRYP PFNGLVIEWPORTPROC) (GLint x, GLint y, GLsizei width, GLsizei height);

typedef float GLclampf;
typedef double GLclampd;
#define GL_DEPTH_BUFFER_BIT               0x00000100
#define GL_STENCIL_BUFFER_BIT             0x00000400
#define GL_COLOR_BUFFER_BIT               0x00004000
#define GL_FALSE                          0
#define GL_TRUE                           1
#define GL_POINTS                         0x0000
#define GL_LINES                          0x0001
#define GL_LINE_LOOP                      0x0002
#define GL_LINE_STRIP                     0x0003
#define GL_TRIANGLES                      0x0004
#define GL_TRIANGLE_STRIP                 0x0005
#define GL_TRIANGLE_FAN                   0x0006
#define GL_QUADS                          0x0007
#define GL_NEVER                          0x0200
#define GL_LESS                           0x0201
#define GL_EQUAL                          0x0202
#define GL_LEQUAL                         0x0203
#define GL_GREATER                        0x0204
#define GL_NOTEQUAL                       0x0205
#define GL_GEQUAL                         0x0206
#define GL_ALWAYS                         0x0207
#define GL_ZERO                           0
#define GL_ONE                            1
#define GL_SRC_COLOR                      0x0300
#define GL_ONE_MINUS_SRC_COLOR            0x0301
#define GL_SRC_ALPHA                      0x0302
#define GL_ONE_MINUS_SRC_ALPHA            0x0303
#define GL_DST_ALPHA                      0x0304
#define GL_ONE_MINUS_DST_ALPHA            0x0305
#define GL_DST_COLOR                      0x0306
#define GL_ONE_MINUS_DST_COLOR            0x0307
#define GL_SRC_ALPHA_SATURATE             0x0308
#define GL_NONE                           0
#define GL_FRONT_LEFT                     0x0400
#define GL_FRONT_RIGHT                    0x0401
#define GL_BACK_LEFT                      0x0402
#define GL_BACK_RIGHT                     0x0403
#define GL_FRONT                          0x0404
#define GL_BACK                           0x0405
#define GL_LEFT                           0x0406
#define GL_RIGHT                          0x0407
#define GL_FRONT_AND_BACK                 0x0408
#define GL_NO_ERROR                       0
#define GL_INVALID_ENUM                   0x0500
#define GL_INVALID_VALUE                  0x0501
#define GL_INVALID_OPERATION              0x0502
#define GL_OUT_OF_MEMORY                  0x0505
#define GL_CW                             0x0900
#define GL_CCW                            0x0901
#define GL_POINT_SIZE                     0x0B11
#define GL_POINT_SIZE_RANGE               0x0B12
#define GL_POINT_SIZE_GRANULARITY         0x0B13
#define GL_LINE_SMOOTH                    0x0B20
#define GL_LINE_WIDTH                     0x0B21
#define GL_LINE_WIDTH_RANGE               0x0B22
#define GL_LINE_WIDTH_GRANULARITY         0x0B23
#define GL_POLYGON_MODE                   0x0B40
#define GL_POLYGON_SMOOTH                 0x0B41
#define GL_CULL_FACE                      0x0B44
#define GL_CULL_FACE_MODE                 0x0B45
#define GL_FRONT_FACE                     0x0B46
#define GL_DEPTH_RANGE                    0x0B70
#define GL_DEPTH_TEST                     0x0B71
#define GL_DEPTH_WRITEMASK                0x0B72
#define GL_DEPTH_CLEAR_VALUE              0x0B73
#define GL_DEPTH_FUNC                     0x0B74
#define GL_STENCIL_TEST                   0x0B90
#define GL_STENCIL_CLEAR_VALUE            0x0B91
#define GL_STENCIL_FUNC                   0x0B92
#define GL_STENCIL_VALUE_MASK             0x0B93
#define GL_STENCIL_FAIL                   0x0B94
#define GL_STENCIL_PASS_DEPTH_FAIL        0x0B95
#define GL_STENCIL_PASS_DEPTH_PASS        0x0B96
#define GL_STENCIL_REF                    0x0B97
#define GL_STENCIL_WRITEMASK              0x0B98
#define GL_VIEWPORT                       0x0BA2
#define GL_DITHER                         0x0BD0
#define GL_BLEND_DST                      0x0BE0
#define GL_BLEND_SRC                      0x0BE1
#define GL_BLEND                          0x0BE2
#define GL_LOGIC_OP_MODE                  0x0BF0
#define GL_COLOR_LOGIC_OP                 0x0BF2
#define GL_DRAW_BUFFER                    0x0C01
#define GL_READ_BUFFER                    0x0C02
#define GL_SCISSOR_BOX                    0x0C10
#define GL_SCISSOR_TEST                   0x0C11
#define GL_COLOR_CLEAR_VALUE              0x0C22
#define GL_COLOR_WRITEMASK                0x0C23
#define GL_DOUBLEBUFFER                   0x0C32
#define GL_STEREO                         0x0C33
#define GL_LINE_SMOOTH_HINT               0x0C52
#define GL_POLYGON_SMOOTH_HINT            0x0C53
#define GL_UNPACK_SWAP_BYTES              0x0CF0
#define GL_UNPACK_LSB_FIRST               0x0CF1
#define GL_UNPACK_ROW_LENGTH              0x0CF2
#define GL_UNPACK_SKIP_ROWS               0x0CF3
#define GL_UNPACK_SKIP_PIXELS             0x0CF4
#define GL_UNPACK_ALIGNMENT               0x0CF5
#define GL_PACK_SWAP_BYTES                0x0D00
#define GL_PACK_LSB_FIRST                 0x0D01
#define GL_PACK_ROW_LENGTH                0x0D02
#define GL_PACK_SKIP_ROWS                 0x0D03
#define GL_PACK_SKIP_PIXELS               0x0D04
#define GL_PACK_ALIGNMENT                 0x0D05
#define GL_MAX_TEXTURE_SIZE               0x0D33
#define GL_MAX_VIEWPORT_DIMS              0x0D3A
#define GL_SUBPIXEL_BITS                  0x0D50
#define GL_TEXTURE_1D                     0x0DE0
#define GL_TEXTURE_2D                     0x0DE1
#define GL_POLYGON_OFFSET_UNITS           0x2A00
#define GL_POLYGON_OFFSET_POINT           0x2A01
#define GL_POLYGON_OFFSET_LINE            0x2A02
#define GL_POLYGON_OFFSET_FILL            0x8037
#define GL_POLYGON_OFFSET_FACTOR          0x8038
#define GL_TEXTURE_BINDING_1D             0x8068
#define GL_TEXTURE_BINDING_2D             0x8069
#define GL_TEXTURE_WIDTH                  0x1000
#define GL_TEXTURE_HEIGHT                 0x1001
#define GL_TEXTURE_INTERNAL_FORMAT        0x1003
#define GL_TEXTURE_BORDER_COLOR           0x1004
#define GL_TEXTURE_RED_SIZE               0x805C
#define GL_TEXTURE_GREEN_SIZE             0x805D
#define GL_TEXTURE_BLUE_SIZE              0x805E
#define GL_TEXTURE_ALPHA_SIZE             0x805F
#define GL_DONT_CARE                      0x1100
#define GL_FASTEST                        0x1101
#define GL_NICEST                         0x1102
#define GL_BYTE                           0x1400
#define GL_UNSIGNED_BYTE                  0x1401
#define GL_SHORT                          0x1402
#define GL_UNSIGNED_SHORT                 0x1403
#define GL_INT                            0x1404
#define GL_UNSIGNED_INT                   0x1405
#define GL_FLOAT                          0x1406
#define GL_DOUBLE                         0x140A
#define GL_STACK_OVERFLOW                 0x0503
#define GL_STACK_UNDERFLOW                0x0504
#define GL_CLEAR                          0x1500
#define GL_AND                            0x1501
#define GL_AND_REVERSE                    0x1502
#define GL_COPY                           0x1503
#define GL_AND_INVERTED                   0x1504
#define GL_NOOP                           0x1505
#define GL_XOR                            0x1506
#define GL_OR                             0x1507
#define GL_NOR                            0x1508
#define GL_EQUIV                          0x1509
#define GL_INVERT                         0x150A
#define GL_OR_REVERSE                     0x150B
#define GL_COPY_INVERTED                  0x150C
#define GL_OR_INVERTED                    0x150D
#define GL_NAND                           0x150E
#define GL_SET                            0x150F
#define GL_TEXTURE                        0x1702
#define GL_COLOR                          0x1800
#define GL_DEPTH                          0x1801
#define GL_STENCIL                        0x1802
#define GL_STENCIL_INDEX                  0x1901
#define GL_DEPTH_COMPONENT                0x1902
#define GL_RED                            0x1903
#define GL_GREEN                          0x1904
#define GL_BLUE                           0x1905
#define GL_ALPHA                          0x1906
#define GL_RGB                            0x1907
#define GL_RGBA                           0x1908
#define GL_POINT                          0x1B00
#define GL_LINE                           0x1B01
#define GL_FILL                           0x1B02
#define GL_KEEP                           0x1E00
#define GL_REPLACE                        0x1E01
#define GL_INCR                           0x1E02
#define GL_DECR                           0x1E03
#define GL_VENDOR                         0x1F00
#define GL_RENDERER                       0x1F01
#define GL_VERSION                        0x1F02
#define GL_EXTENSIONS                     0x1F03
#define GL_NEAREST                        0x2600
#define GL_LINEAR                         0x2601
#define GL_NEAREST_MIPMAP_NEAREST         0x2700
#define GL_LINEAR_MIPMAP_NEAREST          0x2701
#define GL_NEAREST_MIPMAP_LINEAR          0x2702
#define GL_LINEAR_MIPMAP_LINEAR           0x2703
#define GL_TEXTURE_MAG_FILTER             0x2800
#define GL_TEXTURE_MIN_FILTER             0x2801
#define GL_TEXTURE_WRAP_S                 0x2802
#define GL_TEXTURE_WRAP_T                 0x2803
#define GL_PROXY_TEXTURE_1D               0x8063
#define GL_PROXY_TEXTURE_2D               0x8064
#define GL_REPEAT                         0x2901
#define GL_R3_G3_B2                       0x2A10
#define GL_RGB4                           0x804F
#define GL_RGB5                           0x8050
#define GL_RGB8                           0x8051
#define GL_RGB10                          0x8052
#define GL_RGB12                          0x8053
#define GL_RGB16                          0x8054
#define GL_RGBA2                          0x8055
#define GL_RGBA4                          0x8056
#define GL_RGB5_A1                        0x8057
#define GL_RGBA8                          0x8058
#define GL_RGB10_A2                       0x8059
#define GL_RGBA12                         0x805A
#define GL_RGBA16                         0x805B
#define GL_VERTEX_ARRAY                   0x8074
typedef void (APIENTRYP PFNGLDRAWARRAYSPROC) (GLenum mode, GLint first, GLsizei count);
typedef void (APIENTRYP PFNGLDRAWELEMENTSPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices);
typedef void (APIENTRYP PFNGLGETPOINTERVPROC) (GLenum pname, void **params);
typedef void (APIENTRYP PFNGLPOLYGONOFFSETPROC) (GLfloat factor, GLfloat units);
typedef void (APIENTRYP PFNGLCOPYTEXIMAGE1DPROC) (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLint border);
typedef void (APIENTRYP PFNGLCOPYTEXIMAGE2DPROC) (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
typedef void (APIENTRYP PFNGLCOPYTEXSUBIMAGE1DPROC) (GLenum target, GLint level, GLint xoffset, GLint x, GLint y, GLsizei width);
typedef void (APIENTRYP PFNGLCOPYTEXSUBIMAGE2DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLTEXSUBIMAGE1DPROC) (GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLTEXSUBIMAGE2DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLBINDTEXTUREPROC) (GLenum target, GLuint texture);
typedef void (APIENTRYP PFNGLDELETETEXTURESPROC) (GLsizei n, const GLuint *textures);
typedef void (APIENTRYP PFNGLGENTEXTURESPROC) (GLsizei n, GLuint *textures);
typedef GLboolean (APIENTRYP PFNGLISTEXTUREPROC) (GLuint texture);

#define GL_UNSIGNED_BYTE_3_3_2            0x8032
#define GL_UNSIGNED_SHORT_4_4_4_4         0x8033
#define GL_UNSIGNED_SHORT_5_5_5_1         0x8034
#define GL_UNSIGNED_INT_8_8_8_8           0x8035
#define GL_UNSIGNED_INT_10_10_10_2        0x8036
#define GL_TEXTURE_BINDING_3D             0x806A
#define GL_PACK_SKIP_IMAGES               0x806B
#define GL_PACK_IMAGE_HEIGHT              0x806C
#define GL_UNPACK_SKIP_IMAGES             0x806D
#define GL_UNPACK_IMAGE_HEIGHT            0x806E
#define GL_TEXTURE_3D                     0x806F
#define GL_PROXY_TEXTURE_3D               0x8070
#define GL_TEXTURE_DEPTH                  0x8071
#define GL_TEXTURE_WRAP_R                 0x8072
#define GL_MAX_3D_TEXTURE_SIZE            0x8073
#define GL_UNSIGNED_BYTE_2_3_3_REV        0x8362
#define GL_UNSIGNED_SHORT_5_6_5           0x8363
#define GL_UNSIGNED_SHORT_5_6_5_REV       0x8364
#define GL_UNSIGNED_SHORT_4_4_4_4_REV     0x8365
#define GL_UNSIGNED_SHORT_1_5_5_5_REV     0x8366
#define GL_UNSIGNED_INT_8_8_8_8_REV       0x8367
#define GL_UNSIGNED_INT_2_10_10_10_REV    0x8368
#define GL_BGR                            0x80E0
#define GL_BGRA                           0x80E1
#define GL_MAX_ELEMENTS_VERTICES          0x80E8
#define GL_MAX_ELEMENTS_INDICES           0x80E9
#define GL_CLAMP_TO_EDGE                  0x812F
#define GL_TEXTURE_MIN_LOD                0x813A
#define GL_TEXTURE_MAX_LOD                0x813B
#define GL_TEXTURE_BASE_LEVEL             0x813C
#define GL_TEXTURE_MAX_LEVEL              0x813D
#define GL_SMOOTH_POINT_SIZE_RANGE        0x0B12
#define GL_SMOOTH_POINT_SIZE_GRANULARITY  0x0B13
#define GL_SMOOTH_LINE_WIDTH_RANGE        0x0B22
#define GL_SMOOTH_LINE_WIDTH_GRANULARITY  0x0B23
#define GL_ALIASED_LINE_WIDTH_RANGE       0x846E
typedef void (APIENTRYP PFNGLDRAWRANGEELEMENTSPROC) (GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const void *indices);
typedef void (APIENTRYP PFNGLTEXIMAGE3DPROC) (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLTEXSUBIMAGE3DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const void *pixels);
typedef void (APIENTRYP PFNGLCOPYTEXSUBIMAGE3DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);

#define GL_TEXTURE0                       0x84C0
#define GL_TEXTURE1                       0x84C1
#define GL_TEXTURE2                       0x84C2
#define GL_TEXTURE3                       0x84C3
#define GL_TEXTURE4                       0x84C4
#define GL_TEXTURE5                       0x84C5
#define GL_TEXTURE6                       0x84C6
#define GL_TEXTURE7                       0x84C7
#define GL_TEXTURE8                       0x84C8
#define GL_TEXTURE9                       0x84C9
#define GL_TEXTURE10                      0x84CA
#define GL_TEXTURE11                      0x84CB
#define GL_TEXTURE12                      0x84CC
#define GL_TEXTURE13                      0x84CD
#define GL_TEXTURE14                      0x84CE
#define GL_TEXTURE15                      0x84CF
#define GL_TEXTURE16                      0x84D0
#define GL_TEXTURE17                      0x84D1
#define GL_TEXTURE18                      0x84D2
#define GL_TEXTURE19                      0x84D3
#define GL_TEXTURE20                      0x84D4
#define GL_TEXTURE21                      0x84D5
#define GL_TEXTURE22                      0x84D6
#define GL_TEXTURE23                      0x84D7
#define GL_TEXTURE24                      0x84D8
#define GL_TEXTURE25                      0x84D9
#define GL_TEXTURE26                      0x84DA
#define GL_TEXTURE27                      0x84DB
#define GL_TEXTURE28                      0x84DC
#define GL_TEXTURE29                      0x84DD
#define GL_TEXTURE30                      0x84DE
#define GL_TEXTURE31                      0x84DF
#define GL_ACTIVE_TEXTURE                 0x84E0
#define GL_MULTISAMPLE                    0x809D
#define GL_SAMPLE_ALPHA_TO_COVERAGE       0x809E
#define GL_SAMPLE_ALPHA_TO_ONE            0x809F
#define GL_SAMPLE_COVERAGE                0x80A0
#define GL_SAMPLE_BUFFERS                 0x80A8
#define GL_SAMPLES                        0x80A9
#define GL_SAMPLE_COVERAGE_VALUE          0x80AA
#define GL_SAMPLE_COVERAGE_INVERT         0x80AB
#define GL_TEXTURE_CUBE_MAP               0x8513
#define GL_TEXTURE_BINDING_CUBE_MAP       0x8514
#define GL_TEXTURE_CUBE_MAP_POSITIVE_X    0x8515
#define GL_TEXTURE_CUBE_MAP_NEGATIVE_X    0x8516
#define GL_TEXTURE_CUBE_MAP_POSITIVE_Y    0x8517
#define GL_TEXTURE_CUBE_MAP_NEGATIVE_Y    0x8518
#define GL_TEXTURE_CUBE_MAP_POSITIVE_Z    0x8519
#define GL_TEXTURE_CUBE_MAP_NEGATIVE_Z    0x851A
#define GL_PROXY_TEXTURE_CUBE_MAP         0x851B
#define GL_MAX_CUBE_MAP_TEXTURE_SIZE      0x851C
#define GL_COMPRESSED_RGB                 0x84ED
#define GL_COMPRESSED_RGBA                0x84EE
#define GL_TEXTURE_COMPRESSION_HINT       0x84EF
#define GL_TEXTURE_COMPRESSED_IMAGE_SIZE  0x86A0
#define GL_TEXTURE_COMPRESSED             0x86A1
#define GL_NUM_COMPRESSED_TEXTURE_FORMATS 0x86A2
#define GL_COMPRESSED_TEXTURE_FORMATS     0x86A3
#define GL_CLAMP_TO_BORDER                0x812D
typedef void (APIENTRYP PFNGLACTIVETEXTUREPROC) (GLenum texture);
typedef void (APIENTRYP PFNGLSAMPLECOVERAGEPROC) (GLfloat value, GLboolean invert);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXIMAGE3DPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXIMAGE2DPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXIMAGE1DPROC) (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXSUBIMAGE3DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXSUBIMAGE2DPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLCOMPRESSEDTEXSUBIMAGE1DPROC) (GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLsizei imageSize, const void *data);
typedef void (APIENTRYP PFNGLGETCOMPRESSEDTEXIMAGEPROC) (GLenum target, GLint level, void *img);

#define GL_BLEND_DST_RGB                  0x80C8
#define GL_BLEND_SRC_RGB                  0x80C9
#define GL_BLEND_DST_ALPHA                0x80CA
#define GL_BLEND_SRC_ALPHA                0x80CB
#define GL_POINT_FADE_THRESHOLD_SIZE      0x8128
#define GL_DEPTH_COMPONENT16              0x81A5
#define GL_DEPTH_COMPONENT24              0x81A6
#define GL_DEPTH_COMPONENT32              0x81A7
#define GL_MIRRORED_REPEAT                0x8370
#define GL_MAX_TEXTURE_LOD_BIAS           0x84FD
#define GL_TEXTURE_LOD_BIAS               0x8501
#define GL_INCR_WRAP                      0x8507
#define GL_DECR_WRAP                      0x8508
#define GL_TEXTURE_DEPTH_SIZE             0x884A
#define GL_TEXTURE_COMPARE_MODE           0x884C
#define GL_TEXTURE_COMPARE_FUNC           0x884D
#define GL_FUNC_ADD                       0x8006
#define GL_FUNC_SUBTRACT                  0x800A
#define GL_FUNC_REVERSE_SUBTRACT          0x800B
#define GL_MIN                            0x8007
#define GL_MAX                            0x8008
#define GL_CONSTANT_COLOR                 0x8001
#define GL_ONE_MINUS_CONSTANT_COLOR       0x8002
#define GL_CONSTANT_ALPHA                 0x8003
#define GL_ONE_MINUS_CONSTANT_ALPHA       0x8004
typedef void (APIENTRYP PFNGLBLENDFUNCSEPARATEPROC) (GLenum sfactorRGB, GLenum dfactorRGB, GLenum sfactorAlpha, GLenum dfactorAlpha);
typedef void (APIENTRYP PFNGLMULTIDRAWARRAYSPROC) (GLenum mode, const GLint *first, const GLsizei *count, GLsizei drawcount);
typedef void (APIENTRYP PFNGLMULTIDRAWELEMENTSPROC) (GLenum mode, const GLsizei *count, GLenum type, const void *const*indices, GLsizei drawcount);
typedef void (APIENTRYP PFNGLPOINTPARAMETERFPROC) (GLenum pname, GLfloat param);
typedef void (APIENTRYP PFNGLPOINTPARAMETERFVPROC) (GLenum pname, const GLfloat *params);
typedef void (APIENTRYP PFNGLPOINTPARAMETERIPROC) (GLenum pname, GLint param);
typedef void (APIENTRYP PFNGLPOINTPARAMETERIVPROC) (GLenum pname, const GLint *params);
typedef void (APIENTRYP PFNGLBLENDCOLORPROC) (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
typedef void (APIENTRYP PFNGLBLENDEQUATIONPROC) (GLenum mode);

typedef ptrdiff_t GLsizeiptr;
typedef ptrdiff_t GLintptr;
#define GL_BUFFER_SIZE                    0x8764
#define GL_BUFFER_USAGE                   0x8765
#define GL_QUERY_COUNTER_BITS             0x8864
#define GL_CURRENT_QUERY                  0x8865
#define GL_QUERY_RESULT                   0x8866
#define GL_QUERY_RESULT_AVAILABLE         0x8867
#define GL_ARRAY_BUFFER                   0x8892
#define GL_ELEMENT_ARRAY_BUFFER           0x8893
#define GL_ARRAY_BUFFER_BINDING           0x8894
#define GL_ELEMENT_ARRAY_BUFFER_BINDING   0x8895
#define GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING 0x889F
#define GL_READ_ONLY                      0x88B8
#define GL_WRITE_ONLY                     0x88B9
#define GL_READ_WRITE                     0x88BA
#define GL_BUFFER_ACCESS                  0x88BB
#define GL_BUFFER_MAPPED                  0x88BC
#define GL_BUFFER_MAP_POINTER             0x88BD
#define GL_STREAM_DRAW                    0x88E0
#define GL_STREAM_READ                    0x88E1
#define GL_STREAM_COPY                    0x88E2
#define GL_STATIC_DRAW                    0x88E4
#define GL_STATIC_READ                    0x88E5
#define GL_STATIC_COPY                    0x88E6
#define GL_DYNAMIC_DRAW                   0x88E8
#define GL_DYNAMIC_READ                   0x88E9
#define GL_DYNAMIC_COPY                   0x88EA
#define GL_SAMPLES_PASSED                 0x8914
#define GL_SRC1_ALPHA                     0x8589
typedef void (APIENTRYP PFNGLGENQUERIESPROC) (GLsizei n, GLuint *ids);
typedef void (APIENTRYP PFNGLDELETEQUERIESPROC) (GLsizei n, const GLuint *ids);
typedef GLboolean (APIENTRYP PFNGLISQUERYPROC) (GLuint id);
typedef void (APIENTRYP PFNGLBEGINQUERYPROC) (GLenum target, GLuint id);
typedef void (APIENTRYP PFNGLENDQUERYPROC) (GLenum target);
typedef void (APIENTRYP PFNGLGETQUERYIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETQUERYOBJECTIVPROC) (GLuint id, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETQUERYOBJECTUIVPROC) (GLuint id, GLenum pname, GLuint *params);
typedef void (APIENTRYP PFNGLBINDBUFFERPROC) (GLenum target, GLuint buffer);
typedef void (APIENTRYP PFNGLDELETEBUFFERSPROC) (GLsizei n, const GLuint *buffers);
typedef void (APIENTRYP PFNGLGENBUFFERSPROC) (GLsizei n, GLuint *buffers);
typedef GLboolean (APIENTRYP PFNGLISBUFFERPROC) (GLuint buffer);
typedef void (APIENTRYP PFNGLBUFFERDATAPROC) (GLenum target, GLsizeiptr size, const void *data, GLenum usage);
typedef void (APIENTRYP PFNGLBUFFERSUBDATAPROC) (GLenum target, GLintptr offset, GLsizeiptr size, const void *data);
typedef void (APIENTRYP PFNGLGETBUFFERSUBDATAPROC) (GLenum target, GLintptr offset, GLsizeiptr size, void *data);
typedef void *(APIENTRYP PFNGLMAPBUFFERPROC) (GLenum target, GLenum access);
typedef GLboolean (APIENTRYP PFNGLUNMAPBUFFERPROC) (GLenum target);
typedef void (APIENTRYP PFNGLGETBUFFERPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETBUFFERPOINTERVPROC) (GLenum target, GLenum pname, void **params);

typedef char GLchar;
typedef short GLshort;
typedef signed char GLbyte;
typedef unsigned short GLushort;
#define GL_BLEND_EQUATION_RGB             0x8009
#define GL_VERTEX_ATTRIB_ARRAY_ENABLED    0x8622
#define GL_VERTEX_ATTRIB_ARRAY_SIZE       0x8623
#define GL_VERTEX_ATTRIB_ARRAY_STRIDE     0x8624
#define GL_VERTEX_ATTRIB_ARRAY_TYPE       0x8625
#define GL_CURRENT_VERTEX_ATTRIB          0x8626
#define GL_VERTEX_PROGRAM_POINT_SIZE      0x8642
#define GL_VERTEX_ATTRIB_ARRAY_POINTER    0x8645
#define GL_STENCIL_BACK_FUNC              0x8800
#define GL_STENCIL_BACK_FAIL              0x8801
#define GL_STENCIL_BACK_PASS_DEPTH_FAIL   0x8802
#define GL_STENCIL_BACK_PASS_DEPTH_PASS   0x8803
#define GL_MAX_DRAW_BUFFERS               0x8824
#define GL_DRAW_BUFFER0                   0x8825
#define GL_DRAW_BUFFER1                   0x8826
#define GL_DRAW_BUFFER2                   0x8827
#define GL_DRAW_BUFFER3                   0x8828
#define GL_DRAW_BUFFER4                   0x8829
#define GL_DRAW_BUFFER5                   0x882A
#define GL_DRAW_BUFFER6                   0x882B
#define GL_DRAW_BUFFER7                   0x882C
#define GL_DRAW_BUFFER8                   0x882D
#define GL_DRAW_BUFFER9                   0x882E
#define GL_DRAW_BUFFER10                  0x882F
#define GL_DRAW_BUFFER11                  0x8830
#define GL_DRAW_BUFFER12                  0x8831
#define GL_DRAW_BUFFER13                  0x8832
#define GL_DRAW_BUFFER14                  0x8833
#define GL_DRAW_BUFFER15                  0x8834
#define GL_BLEND_EQUATION_ALPHA           0x883D
#define GL_MAX_VERTEX_ATTRIBS             0x8869
#define GL_VERTEX_ATTRIB_ARRAY_NORMALIZED 0x886A
#define GL_MAX_TEXTURE_IMAGE_UNITS        0x8872
#define GL_FRAGMENT_SHADER                0x8B30
#define GL_VERTEX_SHADER                  0x8B31
#define GL_MAX_FRAGMENT_UNIFORM_COMPONENTS 0x8B49
#define GL_MAX_VERTEX_UNIFORM_COMPONENTS  0x8B4A
#define GL_MAX_VARYING_FLOATS             0x8B4B
#define GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS 0x8B4C
#define GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS 0x8B4D
#define GL_SHADER_TYPE                    0x8B4F
#define GL_FLOAT_VEC2                     0x8B50
#define GL_FLOAT_VEC3                     0x8B51
#define GL_FLOAT_VEC4                     0x8B52
#define GL_INT_VEC2                       0x8B53
#define GL_INT_VEC3                       0x8B54
#define GL_INT_VEC4                       0x8B55
#define GL_BOOL                           0x8B56
#define GL_BOOL_VEC2                      0x8B57
#define GL_BOOL_VEC3                      0x8B58
#define GL_BOOL_VEC4                      0x8B59
#define GL_FLOAT_MAT2                     0x8B5A
#define GL_FLOAT_MAT3                     0x8B5B
#define GL_FLOAT_MAT4                     0x8B5C
#define GL_SAMPLER_1D                     0x8B5D
#define GL_SAMPLER_2D                     0x8B5E
#define GL_SAMPLER_3D                     0x8B5F
#define GL_SAMPLER_CUBE                   0x8B60
#define GL_SAMPLER_1D_SHADOW              0x8B61
#define GL_SAMPLER_2D_SHADOW              0x8B62
#define GL_DELETE_STATUS                  0x8B80
#define GL_COMPILE_STATUS                 0x8B81
#define GL_LINK_STATUS                    0x8B82
#define GL_VALIDATE_STATUS                0x8B83
#define GL_INFO_LOG_LENGTH                0x8B84
#define GL_ATTACHED_SHADERS               0x8B85
#define GL_ACTIVE_UNIFORMS                0x8B86
#define GL_ACTIVE_UNIFORM_MAX_LENGTH      0x8B87
#define GL_SHADER_SOURCE_LENGTH           0x8B88
#define GL_ACTIVE_ATTRIBUTES              0x8B89
#define GL_ACTIVE_ATTRIBUTE_MAX_LENGTH    0x8B8A
#define GL_FRAGMENT_SHADER_DERIVATIVE_HINT 0x8B8B
#define GL_SHADING_LANGUAGE_VERSION       0x8B8C
#define GL_CURRENT_PROGRAM                0x8B8D
#define GL_POINT_SPRITE_COORD_ORIGIN      0x8CA0
#define GL_LOWER_LEFT                     0x8CA1
#define GL_UPPER_LEFT                     0x8CA2
#define GL_STENCIL_BACK_REF               0x8CA3
#define GL_STENCIL_BACK_VALUE_MASK        0x8CA4
#define GL_STENCIL_BACK_WRITEMASK         0x8CA5
typedef void (APIENTRYP PFNGLBLENDEQUATIONSEPARATEPROC) (GLenum modeRGB, GLenum modeAlpha);
typedef void (APIENTRYP PFNGLDRAWBUFFERSPROC) (GLsizei n, const GLenum *bufs);
typedef void (APIENTRYP PFNGLSTENCILOPSEPARATEPROC) (GLenum face, GLenum sfail, GLenum dpfail, GLenum dppass);
typedef void (APIENTRYP PFNGLSTENCILFUNCSEPARATEPROC) (GLenum face, GLenum func, GLint ref, GLuint mask);
typedef void (APIENTRYP PFNGLSTENCILMASKSEPARATEPROC) (GLenum face, GLuint mask);
typedef void (APIENTRYP PFNGLATTACHSHADERPROC) (GLuint program, GLuint shader);
typedef void (APIENTRYP PFNGLBINDATTRIBLOCATIONPROC) (GLuint program, GLuint index, const GLchar *name);
typedef void (APIENTRYP PFNGLCOMPILESHADERPROC) (GLuint shader);
typedef GLuint (APIENTRYP PFNGLCREATEPROGRAMPROC) (void);
typedef GLuint (APIENTRYP PFNGLCREATESHADERPROC) (GLenum type);
typedef void (APIENTRYP PFNGLDELETEPROGRAMPROC) (GLuint program);
typedef void (APIENTRYP PFNGLDELETESHADERPROC) (GLuint shader);
typedef void (APIENTRYP PFNGLDETACHSHADERPROC) (GLuint program, GLuint shader);
typedef void (APIENTRYP PFNGLDISABLEVERTEXATTRIBARRAYPROC) (GLuint index);
typedef void (APIENTRYP PFNGLENABLEVERTEXATTRIBARRAYPROC) (GLuint index);
typedef void (APIENTRYP PFNGLGETACTIVEATTRIBPROC) (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
typedef void (APIENTRYP PFNGLGETACTIVEUNIFORMPROC) (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
typedef void (APIENTRYP PFNGLGETATTACHEDSHADERSPROC) (GLuint program, GLsizei maxCount, GLsizei *count, GLuint *shaders);
typedef GLint (APIENTRYP PFNGLGETATTRIBLOCATIONPROC) (GLuint program, const GLchar *name);
typedef void (APIENTRYP PFNGLGETPROGRAMIVPROC) (GLuint program, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETPROGRAMINFOLOGPROC) (GLuint program, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
typedef void (APIENTRYP PFNGLGETSHADERIVPROC) (GLuint shader, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETSHADERINFOLOGPROC) (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
typedef void (APIENTRYP PFNGLGETSHADERSOURCEPROC) (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *source);
typedef GLint (APIENTRYP PFNGLGETUNIFORMLOCATIONPROC) (GLuint program, const GLchar *name);
typedef void (APIENTRYP PFNGLGETUNIFORMFVPROC) (GLuint program, GLint location, GLfloat *params);
typedef void (APIENTRYP PFNGLGETUNIFORMIVPROC) (GLuint program, GLint location, GLint *params);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBDVPROC) (GLuint index, GLenum pname, GLdouble *params);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBFVPROC) (GLuint index, GLenum pname, GLfloat *params);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBIVPROC) (GLuint index, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBPOINTERVPROC) (GLuint index, GLenum pname, void **pointer);
typedef GLboolean (APIENTRYP PFNGLISPROGRAMPROC) (GLuint program);
typedef GLboolean (APIENTRYP PFNGLISSHADERPROC) (GLuint shader);
typedef void (APIENTRYP PFNGLLINKPROGRAMPROC) (GLuint program);
typedef void (APIENTRYP PFNGLSHADERSOURCEPROC) (GLuint shader, GLsizei count, const GLchar *const*string, const GLint *length);
typedef void (APIENTRYP PFNGLUSEPROGRAMPROC) (GLuint program);
typedef void (APIENTRYP PFNGLUNIFORM1FPROC) (GLint location, GLfloat v0);
typedef void (APIENTRYP PFNGLUNIFORM2FPROC) (GLint location, GLfloat v0, GLfloat v1);
typedef void (APIENTRYP PFNGLUNIFORM3FPROC) (GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
typedef void (APIENTRYP PFNGLUNIFORM4FPROC) (GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
typedef void (APIENTRYP PFNGLUNIFORM1IPROC) (GLint location, GLint v0);
typedef void (APIENTRYP PFNGLUNIFORM2IPROC) (GLint location, GLint v0, GLint v1);
typedef void (APIENTRYP PFNGLUNIFORM3IPROC) (GLint location, GLint v0, GLint v1, GLint v2);
typedef void (APIENTRYP PFNGLUNIFORM4IPROC) (GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
typedef void (APIENTRYP PFNGLUNIFORM1FVPROC) (GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORM2FVPROC) (GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORM3FVPROC) (GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORM4FVPROC) (GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORM1IVPROC) (GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLUNIFORM2IVPROC) (GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLUNIFORM3IVPROC) (GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLUNIFORM4IVPROC) (GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLVALIDATEPROGRAMPROC) (GLuint program);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1DPROC) (GLuint index, GLdouble x);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1FPROC) (GLuint index, GLfloat x);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1FVPROC) (GLuint index, const GLfloat *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1SPROC) (GLuint index, GLshort x);
typedef void (APIENTRYP PFNGLVERTEXATTRIB1SVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2DPROC) (GLuint index, GLdouble x, GLdouble y);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2FPROC) (GLuint index, GLfloat x, GLfloat y);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2FVPROC) (GLuint index, const GLfloat *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2SPROC) (GLuint index, GLshort x, GLshort y);
typedef void (APIENTRYP PFNGLVERTEXATTRIB2SVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3FPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat z);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3FVPROC) (GLuint index, const GLfloat *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3SPROC) (GLuint index, GLshort x, GLshort y, GLshort z);
typedef void (APIENTRYP PFNGLVERTEXATTRIB3SVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NBVPROC) (GLuint index, const GLbyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NIVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NSVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NUBPROC) (GLuint index, GLubyte x, GLubyte y, GLubyte z, GLubyte w);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NUBVPROC) (GLuint index, const GLubyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NUIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4NUSVPROC) (GLuint index, const GLushort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4BVPROC) (GLuint index, const GLbyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4FPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4FVPROC) (GLuint index, const GLfloat *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4IVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4SPROC) (GLuint index, GLshort x, GLshort y, GLshort z, GLshort w);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4SVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4UBVPROC) (GLuint index, const GLubyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4UIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIB4USVPROC) (GLuint index, const GLushort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBPOINTERPROC) (GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const void *pointer);

#define GL_PIXEL_PACK_BUFFER              0x88EB
#define GL_PIXEL_UNPACK_BUFFER            0x88EC
#define GL_PIXEL_PACK_BUFFER_BINDING      0x88ED
#define GL_PIXEL_UNPACK_BUFFER_BINDING    0x88EF
#define GL_FLOAT_MAT2x3                   0x8B65
#define GL_FLOAT_MAT2x4                   0x8B66
#define GL_FLOAT_MAT3x2                   0x8B67
#define GL_FLOAT_MAT3x4                   0x8B68
#define GL_FLOAT_MAT4x2                   0x8B69
#define GL_FLOAT_MAT4x3                   0x8B6A
#define GL_SRGB                           0x8C40
#define GL_SRGB8                          0x8C41
#define GL_SRGB_ALPHA                     0x8C42
#define GL_SRGB8_ALPHA8                   0x8C43
#define GL_COMPRESSED_SRGB                0x8C48
#define GL_COMPRESSED_SRGB_ALPHA          0x8C49
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2X3FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3X2FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2X4FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4X2FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3X4FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4X3FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

typedef unsigned short GLhalf;
#define GL_COMPARE_REF_TO_TEXTURE         0x884E
#define GL_CLIP_DISTANCE0                 0x3000
#define GL_CLIP_DISTANCE1                 0x3001
#define GL_CLIP_DISTANCE2                 0x3002
#define GL_CLIP_DISTANCE3                 0x3003
#define GL_CLIP_DISTANCE4                 0x3004
#define GL_CLIP_DISTANCE5                 0x3005
#define GL_CLIP_DISTANCE6                 0x3006
#define GL_CLIP_DISTANCE7                 0x3007
#define GL_MAX_CLIP_DISTANCES             0x0D32
#define GL_MAJOR_VERSION                  0x821B
#define GL_MINOR_VERSION                  0x821C
#define GL_NUM_EXTENSIONS                 0x821D
#define GL_CONTEXT_FLAGS                  0x821E
#define GL_COMPRESSED_RED                 0x8225
#define GL_COMPRESSED_RG                  0x8226
#define GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT 0x00000001
#define GL_RGBA32F                        0x8814
#define GL_RGB32F                         0x8815
#define GL_RGBA16F                        0x881A
#define GL_RGB16F                         0x881B
#define GL_VERTEX_ATTRIB_ARRAY_INTEGER    0x88FD
#define GL_MAX_ARRAY_TEXTURE_LAYERS       0x88FF
#define GL_MIN_PROGRAM_TEXEL_OFFSET       0x8904
#define GL_MAX_PROGRAM_TEXEL_OFFSET       0x8905
#define GL_CLAMP_READ_COLOR               0x891C
#define GL_FIXED_ONLY                     0x891D
#define GL_MAX_VARYING_COMPONENTS         0x8B4B
#define GL_TEXTURE_1D_ARRAY               0x8C18
#define GL_PROXY_TEXTURE_1D_ARRAY         0x8C19
#define GL_TEXTURE_2D_ARRAY               0x8C1A
#define GL_PROXY_TEXTURE_2D_ARRAY         0x8C1B
#define GL_TEXTURE_BINDING_1D_ARRAY       0x8C1C
#define GL_TEXTURE_BINDING_2D_ARRAY       0x8C1D
#define GL_R11F_G11F_B10F                 0x8C3A
#define GL_UNSIGNED_INT_10F_11F_11F_REV   0x8C3B
#define GL_RGB9_E5                        0x8C3D
#define GL_UNSIGNED_INT_5_9_9_9_REV       0x8C3E
#define GL_TEXTURE_SHARED_SIZE            0x8C3F
#define GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH 0x8C76
#define GL_TRANSFORM_FEEDBACK_BUFFER_MODE 0x8C7F
#define GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS 0x8C80
#define GL_TRANSFORM_FEEDBACK_VARYINGS    0x8C83
#define GL_TRANSFORM_FEEDBACK_BUFFER_START 0x8C84
#define GL_TRANSFORM_FEEDBACK_BUFFER_SIZE 0x8C85
#define GL_PRIMITIVES_GENERATED           0x8C87
#define GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN 0x8C88
#define GL_RASTERIZER_DISCARD             0x8C89
#define GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS 0x8C8A
#define GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS 0x8C8B
#define GL_INTERLEAVED_ATTRIBS            0x8C8C
#define GL_SEPARATE_ATTRIBS               0x8C8D
#define GL_TRANSFORM_FEEDBACK_BUFFER      0x8C8E
#define GL_TRANSFORM_FEEDBACK_BUFFER_BINDING 0x8C8F
#define GL_RGBA32UI                       0x8D70
#define GL_RGB32UI                        0x8D71
#define GL_RGBA16UI                       0x8D76
#define GL_RGB16UI                        0x8D77
#define GL_RGBA8UI                        0x8D7C
#define GL_RGB8UI                         0x8D7D
#define GL_RGBA32I                        0x8D82
#define GL_RGB32I                         0x8D83
#define GL_RGBA16I                        0x8D88
#define GL_RGB16I                         0x8D89
#define GL_RGBA8I                         0x8D8E
#define GL_RGB8I                          0x8D8F
#define GL_RED_INTEGER                    0x8D94
#define GL_GREEN_INTEGER                  0x8D95
#define GL_BLUE_INTEGER                   0x8D96
#define GL_RGB_INTEGER                    0x8D98
#define GL_RGBA_INTEGER                   0x8D99
#define GL_BGR_INTEGER                    0x8D9A
#define GL_BGRA_INTEGER                   0x8D9B
#define GL_SAMPLER_1D_ARRAY               0x8DC0
#define GL_SAMPLER_2D_ARRAY               0x8DC1
#define GL_SAMPLER_1D_ARRAY_SHADOW        0x8DC3
#define GL_SAMPLER_2D_ARRAY_SHADOW        0x8DC4
#define GL_SAMPLER_CUBE_SHADOW            0x8DC5
#define GL_UNSIGNED_INT_VEC2              0x8DC6
#define GL_UNSIGNED_INT_VEC3              0x8DC7
#define GL_UNSIGNED_INT_VEC4              0x8DC8
#define GL_INT_SAMPLER_1D                 0x8DC9
#define GL_INT_SAMPLER_2D                 0x8DCA
#define GL_INT_SAMPLER_3D                 0x8DCB
#define GL_INT_SAMPLER_CUBE               0x8DCC
#define GL_INT_SAMPLER_1D_ARRAY           0x8DCE
#define GL_INT_SAMPLER_2D_ARRAY           0x8DCF
#define GL_UNSIGNED_INT_SAMPLER_1D        0x8DD1
#define GL_UNSIGNED_INT_SAMPLER_2D        0x8DD2
#define GL_UNSIGNED_INT_SAMPLER_3D        0x8DD3
#define GL_UNSIGNED_INT_SAMPLER_CUBE      0x8DD4
#define GL_UNSIGNED_INT_SAMPLER_1D_ARRAY  0x8DD6
#define GL_UNSIGNED_INT_SAMPLER_2D_ARRAY  0x8DD7
#define GL_QUERY_WAIT                     0x8E13
#define GL_QUERY_NO_WAIT                  0x8E14
#define GL_QUERY_BY_REGION_WAIT           0x8E15
#define GL_QUERY_BY_REGION_NO_WAIT        0x8E16
#define GL_BUFFER_ACCESS_FLAGS            0x911F
#define GL_BUFFER_MAP_LENGTH              0x9120
#define GL_BUFFER_MAP_OFFSET              0x9121
#define GL_DEPTH_COMPONENT32F             0x8CAC
#define GL_DEPTH32F_STENCIL8              0x8CAD
#define GL_FLOAT_32_UNSIGNED_INT_24_8_REV 0x8DAD
#define GL_INVALID_FRAMEBUFFER_OPERATION  0x0506
#define GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING 0x8210
#define GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE 0x8211
#define GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE 0x8212
#define GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE 0x8213
#define GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE 0x8214
#define GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE 0x8215
#define GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE 0x8216
#define GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE 0x8217
#define GL_FRAMEBUFFER_DEFAULT            0x8218
#define GL_FRAMEBUFFER_UNDEFINED          0x8219
#define GL_DEPTH_STENCIL_ATTACHMENT       0x821A
#define GL_MAX_RENDERBUFFER_SIZE          0x84E8
#define GL_DEPTH_STENCIL                  0x84F9
#define GL_UNSIGNED_INT_24_8              0x84FA
#define GL_DEPTH24_STENCIL8               0x88F0
#define GL_TEXTURE_STENCIL_SIZE           0x88F1
#define GL_TEXTURE_RED_TYPE               0x8C10
#define GL_TEXTURE_GREEN_TYPE             0x8C11
#define GL_TEXTURE_BLUE_TYPE              0x8C12
#define GL_TEXTURE_ALPHA_TYPE             0x8C13
#define GL_TEXTURE_DEPTH_TYPE             0x8C16
#define GL_UNSIGNED_NORMALIZED            0x8C17
#define GL_FRAMEBUFFER_BINDING            0x8CA6
#define GL_DRAW_FRAMEBUFFER_BINDING       0x8CA6
#define GL_RENDERBUFFER_BINDING           0x8CA7
#define GL_READ_FRAMEBUFFER               0x8CA8
#define GL_DRAW_FRAMEBUFFER               0x8CA9
#define GL_READ_FRAMEBUFFER_BINDING       0x8CAA
#define GL_RENDERBUFFER_SAMPLES           0x8CAB
#define GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE 0x8CD0
#define GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME 0x8CD1
#define GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL 0x8CD2
#define GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE 0x8CD3
#define GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER 0x8CD4
#define GL_FRAMEBUFFER_COMPLETE           0x8CD5
#define GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT 0x8CD6
#define GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT 0x8CD7
#define GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER 0x8CDB
#define GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER 0x8CDC
#define GL_FRAMEBUFFER_UNSUPPORTED        0x8CDD
#define GL_MAX_COLOR_ATTACHMENTS          0x8CDF
#define GL_COLOR_ATTACHMENT0              0x8CE0
#define GL_COLOR_ATTACHMENT1              0x8CE1
#define GL_COLOR_ATTACHMENT2              0x8CE2
#define GL_COLOR_ATTACHMENT3              0x8CE3
#define GL_COLOR_ATTACHMENT4              0x8CE4
#define GL_COLOR_ATTACHMENT5              0x8CE5
#define GL_COLOR_ATTACHMENT6              0x8CE6
#define GL_COLOR_ATTACHMENT7              0x8CE7
#define GL_COLOR_ATTACHMENT8              0x8CE8
#define GL_COLOR_ATTACHMENT9              0x8CE9
#define GL_COLOR_ATTACHMENT10             0x8CEA
#define GL_COLOR_ATTACHMENT11             0x8CEB
#define GL_COLOR_ATTACHMENT12             0x8CEC
#define GL_COLOR_ATTACHMENT13             0x8CED
#define GL_COLOR_ATTACHMENT14             0x8CEE
#define GL_COLOR_ATTACHMENT15             0x8CEF
#define GL_DEPTH_ATTACHMENT               0x8D00
#define GL_STENCIL_ATTACHMENT             0x8D20
#define GL_FRAMEBUFFER                    0x8D40
#define GL_RENDERBUFFER                   0x8D41
#define GL_RENDERBUFFER_WIDTH             0x8D42
#define GL_RENDERBUFFER_HEIGHT            0x8D43
#define GL_RENDERBUFFER_INTERNAL_FORMAT   0x8D44
#define GL_STENCIL_INDEX1                 0x8D46
#define GL_STENCIL_INDEX4                 0x8D47
#define GL_STENCIL_INDEX8                 0x8D48
#define GL_STENCIL_INDEX16                0x8D49
#define GL_RENDERBUFFER_RED_SIZE          0x8D50
#define GL_RENDERBUFFER_GREEN_SIZE        0x8D51
#define GL_RENDERBUFFER_BLUE_SIZE         0x8D52
#define GL_RENDERBUFFER_ALPHA_SIZE        0x8D53
#define GL_RENDERBUFFER_DEPTH_SIZE        0x8D54
#define GL_RENDERBUFFER_STENCIL_SIZE      0x8D55
#define GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE 0x8D56
#define GL_MAX_SAMPLES                    0x8D57
#define GL_FRAMEBUFFER_SRGB               0x8DB9
#define GL_HALF_FLOAT                     0x140B
#define GL_MAP_READ_BIT                   0x0001
#define GL_MAP_WRITE_BIT                  0x0002
#define GL_MAP_INVALIDATE_RANGE_BIT       0x0004
#define GL_MAP_INVALIDATE_BUFFER_BIT      0x0008
#define GL_MAP_FLUSH_EXPLICIT_BIT         0x0010
#define GL_MAP_UNSYNCHRONIZED_BIT         0x0020
#define GL_COMPRESSED_RED_RGTC1           0x8DBB
#define GL_COMPRESSED_SIGNED_RED_RGTC1    0x8DBC
#define GL_COMPRESSED_RG_RGTC2            0x8DBD
#define GL_COMPRESSED_SIGNED_RG_RGTC2     0x8DBE
#define GL_RG                             0x8227
#define GL_RG_INTEGER                     0x8228
#define GL_R8                             0x8229
#define GL_R16                            0x822A
#define GL_RG8                            0x822B
#define GL_RG16                           0x822C
#define GL_R16F                           0x822D
#define GL_R32F                           0x822E
#define GL_RG16F                          0x822F
#define GL_RG32F                          0x8230
#define GL_R8I                            0x8231
#define GL_R8UI                           0x8232
#define GL_R16I                           0x8233
#define GL_R16UI                          0x8234
#define GL_R32I                           0x8235
#define GL_R32UI                          0x8236
#define GL_RG8I                           0x8237
#define GL_RG8UI                          0x8238
#define GL_RG16I                          0x8239
#define GL_RG16UI                         0x823A
#define GL_RG32I                          0x823B
#define GL_RG32UI                         0x823C
#define GL_VERTEX_ARRAY_BINDING           0x85B5
typedef void (APIENTRYP PFNGLCOLORMASKIPROC) (GLuint index, GLboolean r, GLboolean g, GLboolean b, GLboolean a);
typedef void (APIENTRYP PFNGLGETBOOLEANI_VPROC) (GLenum target, GLuint index, GLboolean *data);
typedef void (APIENTRYP PFNGLGETINTEGERI_VPROC) (GLenum target, GLuint index, GLint *data);
typedef void (APIENTRYP PFNGLENABLEIPROC) (GLenum target, GLuint index);
typedef void (APIENTRYP PFNGLDISABLEIPROC) (GLenum target, GLuint index);
typedef GLboolean (APIENTRYP PFNGLISENABLEDIPROC) (GLenum target, GLuint index);
typedef void (APIENTRYP PFNGLBEGINTRANSFORMFEEDBACKPROC) (GLenum primitiveMode);
typedef void (APIENTRYP PFNGLENDTRANSFORMFEEDBACKPROC) (void);
typedef void (APIENTRYP PFNGLBINDBUFFERRANGEPROC) (GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);
typedef void (APIENTRYP PFNGLBINDBUFFERBASEPROC) (GLenum target, GLuint index, GLuint buffer);
typedef void (APIENTRYP PFNGLTRANSFORMFEEDBACKVARYINGSPROC) (GLuint program, GLsizei count, const GLchar *const*varyings, GLenum bufferMode);
typedef void (APIENTRYP PFNGLGETTRANSFORMFEEDBACKVARYINGPROC) (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLsizei *size, GLenum *type, GLchar *name);
typedef void (APIENTRYP PFNGLCLAMPCOLORPROC) (GLenum target, GLenum clamp);
typedef void (APIENTRYP PFNGLBEGINCONDITIONALRENDERPROC) (GLuint id, GLenum mode);
typedef void (APIENTRYP PFNGLENDCONDITIONALRENDERPROC) (void);
typedef void (APIENTRYP PFNGLVERTEXATTRIBIPOINTERPROC) (GLuint index, GLint size, GLenum type, GLsizei stride, const void *pointer);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBIIVPROC) (GLuint index, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBIUIVPROC) (GLuint index, GLenum pname, GLuint *params);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI1IPROC) (GLuint index, GLint x);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI2IPROC) (GLuint index, GLint x, GLint y);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI3IPROC) (GLuint index, GLint x, GLint y, GLint z);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4IPROC) (GLuint index, GLint x, GLint y, GLint z, GLint w);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI1UIPROC) (GLuint index, GLuint x);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI2UIPROC) (GLuint index, GLuint x, GLuint y);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI3UIPROC) (GLuint index, GLuint x, GLuint y, GLuint z);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4UIPROC) (GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI1IVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI2IVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI3IVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4IVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI1UIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI2UIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI3UIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4UIVPROC) (GLuint index, const GLuint *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4BVPROC) (GLuint index, const GLbyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4SVPROC) (GLuint index, const GLshort *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4UBVPROC) (GLuint index, const GLubyte *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBI4USVPROC) (GLuint index, const GLushort *v);
typedef void (APIENTRYP PFNGLGETUNIFORMUIVPROC) (GLuint program, GLint location, GLuint *params);
typedef void (APIENTRYP PFNGLBINDFRAGDATALOCATIONPROC) (GLuint program, GLuint color, const GLchar *name);
typedef GLint (APIENTRYP PFNGLGETFRAGDATALOCATIONPROC) (GLuint program, const GLchar *name);
typedef void (APIENTRYP PFNGLUNIFORM1UIPROC) (GLint location, GLuint v0);
typedef void (APIENTRYP PFNGLUNIFORM2UIPROC) (GLint location, GLuint v0, GLuint v1);
typedef void (APIENTRYP PFNGLUNIFORM3UIPROC) (GLint location, GLuint v0, GLuint v1, GLuint v2);
typedef void (APIENTRYP PFNGLUNIFORM4UIPROC) (GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
typedef void (APIENTRYP PFNGLUNIFORM1UIVPROC) (GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLUNIFORM2UIVPROC) (GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLUNIFORM3UIVPROC) (GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLUNIFORM4UIVPROC) (GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLTEXPARAMETERIIVPROC) (GLenum target, GLenum pname, const GLint *params);
typedef void (APIENTRYP PFNGLTEXPARAMETERIUIVPROC) (GLenum target, GLenum pname, const GLuint *params);
typedef void (APIENTRYP PFNGLGETTEXPARAMETERIIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETTEXPARAMETERIUIVPROC) (GLenum target, GLenum pname, GLuint *params);
typedef void (APIENTRYP PFNGLCLEARBUFFERIVPROC) (GLenum buffer, GLint drawbuffer, const GLint *value);
typedef void (APIENTRYP PFNGLCLEARBUFFERUIVPROC) (GLenum buffer, GLint drawbuffer, const GLuint *value);
typedef void (APIENTRYP PFNGLCLEARBUFFERFVPROC) (GLenum buffer, GLint drawbuffer, const GLfloat *value);
typedef void (APIENTRYP PFNGLCLEARBUFFERFIPROC) (GLenum buffer, GLint drawbuffer, GLfloat depth, GLint stencil);
typedef const GLubyte *(APIENTRYP PFNGLGETSTRINGIPROC) (GLenum name, GLuint index);
typedef GLboolean (APIENTRYP PFNGLISRENDERBUFFERPROC) (GLuint renderbuffer);
typedef void (APIENTRYP PFNGLBINDRENDERBUFFERPROC) (GLenum target, GLuint renderbuffer);
typedef void (APIENTRYP PFNGLDELETERENDERBUFFERSPROC) (GLsizei n, const GLuint *renderbuffers);
typedef void (APIENTRYP PFNGLGENRENDERBUFFERSPROC) (GLsizei n, GLuint *renderbuffers);
typedef void (APIENTRYP PFNGLRENDERBUFFERSTORAGEPROC) (GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLGETRENDERBUFFERPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef GLboolean (APIENTRYP PFNGLISFRAMEBUFFERPROC) (GLuint framebuffer);
typedef void (APIENTRYP PFNGLBINDFRAMEBUFFERPROC) (GLenum target, GLuint framebuffer);
typedef void (APIENTRYP PFNGLDELETEFRAMEBUFFERSPROC) (GLsizei n, const GLuint *framebuffers);
typedef void (APIENTRYP PFNGLGENFRAMEBUFFERSPROC) (GLsizei n, GLuint *framebuffers);
typedef GLenum (APIENTRYP PFNGLCHECKFRAMEBUFFERSTATUSPROC) (GLenum target);
typedef void (APIENTRYP PFNGLFRAMEBUFFERTEXTURE1DPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
typedef void (APIENTRYP PFNGLFRAMEBUFFERTEXTURE2DPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
typedef void (APIENTRYP PFNGLFRAMEBUFFERTEXTURE3DPROC) (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level, GLint zoffset);
typedef void (APIENTRYP PFNGLFRAMEBUFFERRENDERBUFFERPROC) (GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);
typedef void (APIENTRYP PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVPROC) (GLenum target, GLenum attachment, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGENERATEMIPMAPPROC) (GLenum target);
typedef void (APIENTRYP PFNGLBLITFRAMEBUFFERPROC) (GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
typedef void (APIENTRYP PFNGLRENDERBUFFERSTORAGEMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLFRAMEBUFFERTEXTURELAYERPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer);
typedef void *(APIENTRYP PFNGLMAPBUFFERRANGEPROC) (GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access);
typedef void (APIENTRYP PFNGLFLUSHMAPPEDBUFFERRANGEPROC) (GLenum target, GLintptr offset, GLsizeiptr length);
typedef void (APIENTRYP PFNGLBINDVERTEXARRAYPROC) (GLuint array);
typedef void (APIENTRYP PFNGLDELETEVERTEXARRAYSPROC) (GLsizei n, const GLuint *arrays);
typedef void (APIENTRYP PFNGLGENVERTEXARRAYSPROC) (GLsizei n, GLuint *arrays);
typedef GLboolean (APIENTRYP PFNGLISVERTEXARRAYPROC) (GLuint array);

#define GL_SAMPLER_2D_RECT                0x8B63
#define GL_SAMPLER_2D_RECT_SHADOW         0x8B64
#define GL_SAMPLER_BUFFER                 0x8DC2
#define GL_INT_SAMPLER_2D_RECT            0x8DCD
#define GL_INT_SAMPLER_BUFFER             0x8DD0
#define GL_UNSIGNED_INT_SAMPLER_2D_RECT   0x8DD5
#define GL_UNSIGNED_INT_SAMPLER_BUFFER    0x8DD8
#define GL_TEXTURE_BUFFER                 0x8C2A
#define GL_MAX_TEXTURE_BUFFER_SIZE        0x8C2B
#define GL_TEXTURE_BINDING_BUFFER         0x8C2C
#define GL_TEXTURE_BUFFER_DATA_STORE_BINDING 0x8C2D
#define GL_TEXTURE_RECTANGLE              0x84F5
#define GL_TEXTURE_BINDING_RECTANGLE      0x84F6
#define GL_PROXY_TEXTURE_RECTANGLE        0x84F7
#define GL_MAX_RECTANGLE_TEXTURE_SIZE     0x84F8
#define GL_R8_SNORM                       0x8F94
#define GL_RG8_SNORM                      0x8F95
#define GL_RGB8_SNORM                     0x8F96
#define GL_RGBA8_SNORM                    0x8F97
#define GL_R16_SNORM                      0x8F98
#define GL_RG16_SNORM                     0x8F99
#define GL_RGB16_SNORM                    0x8F9A
#define GL_RGBA16_SNORM                   0x8F9B
#define GL_SIGNED_NORMALIZED              0x8F9C
#define GL_PRIMITIVE_RESTART              0x8F9D
#define GL_PRIMITIVE_RESTART_INDEX        0x8F9E
#define GL_COPY_READ_BUFFER               0x8F36
#define GL_COPY_WRITE_BUFFER              0x8F37
#define GL_UNIFORM_BUFFER                 0x8A11
#define GL_UNIFORM_BUFFER_BINDING         0x8A28
#define GL_UNIFORM_BUFFER_START           0x8A29
#define GL_UNIFORM_BUFFER_SIZE            0x8A2A
#define GL_MAX_VERTEX_UNIFORM_BLOCKS      0x8A2B
#define GL_MAX_FRAGMENT_UNIFORM_BLOCKS    0x8A2D
#define GL_MAX_COMBINED_UNIFORM_BLOCKS    0x8A2E
#define GL_MAX_UNIFORM_BUFFER_BINDINGS    0x8A2F
#define GL_MAX_UNIFORM_BLOCK_SIZE         0x8A30
#define GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS 0x8A31
#define GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS 0x8A33
#define GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT 0x8A34
#define GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH 0x8A35
#define GL_ACTIVE_UNIFORM_BLOCKS          0x8A36
#define GL_UNIFORM_TYPE                   0x8A37
#define GL_UNIFORM_SIZE                   0x8A38
#define GL_UNIFORM_NAME_LENGTH            0x8A39
#define GL_UNIFORM_BLOCK_INDEX            0x8A3A
#define GL_UNIFORM_OFFSET                 0x8A3B
#define GL_UNIFORM_ARRAY_STRIDE           0x8A3C
#define GL_UNIFORM_MATRIX_STRIDE          0x8A3D
#define GL_UNIFORM_IS_ROW_MAJOR           0x8A3E
#define GL_UNIFORM_BLOCK_BINDING          0x8A3F
#define GL_UNIFORM_BLOCK_DATA_SIZE        0x8A40
#define GL_UNIFORM_BLOCK_NAME_LENGTH      0x8A41
#define GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS  0x8A42
#define GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES 0x8A43
#define GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER 0x8A44
#define GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER 0x8A46
#define GL_INVALID_INDEX                  0xFFFFFFFFu
typedef void (APIENTRYP PFNGLDRAWARRAYSINSTANCEDPROC) (GLenum mode, GLint first, GLsizei count, GLsizei instancecount);
typedef void (APIENTRYP PFNGLDRAWELEMENTSINSTANCEDPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount);
typedef void (APIENTRYP PFNGLTEXBUFFERPROC) (GLenum target, GLenum internalformat, GLuint buffer);
typedef void (APIENTRYP PFNGLPRIMITIVERESTARTINDEXPROC) (GLuint index);
typedef void (APIENTRYP PFNGLCOPYBUFFERSUBDATAPROC) (GLenum readTarget, GLenum writeTarget, GLintptr readOffset, GLintptr writeOffset, GLsizeiptr size);
typedef void (APIENTRYP PFNGLGETUNIFORMINDICESPROC) (GLuint program, GLsizei uniformCount, const GLchar *const*uniformNames, GLuint *uniformIndices);
typedef void (APIENTRYP PFNGLGETACTIVEUNIFORMSIVPROC) (GLuint program, GLsizei uniformCount, const GLuint *uniformIndices, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETACTIVEUNIFORMNAMEPROC) (GLuint program, GLuint uniformIndex, GLsizei bufSize, GLsizei *length, GLchar *uniformName);
typedef GLuint (APIENTRYP PFNGLGETUNIFORMBLOCKINDEXPROC) (GLuint program, const GLchar *uniformBlockName);
typedef void (APIENTRYP PFNGLGETACTIVEUNIFORMBLOCKIVPROC) (GLuint program, GLuint uniformBlockIndex, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETACTIVEUNIFORMBLOCKNAMEPROC) (GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, GLsizei *length, GLchar *uniformBlockName);
typedef void (APIENTRYP PFNGLUNIFORMBLOCKBINDINGPROC) (GLuint program, GLuint uniformBlockIndex, GLuint uniformBlockBinding);

typedef struct __GLsync *GLsync;
typedef uint64_t GLuint64;
typedef int64_t GLint64;
#define GL_CONTEXT_CORE_PROFILE_BIT       0x00000001
#define GL_CONTEXT_COMPATIBILITY_PROFILE_BIT 0x00000002
#define GL_LINES_ADJACENCY                0x000A
#define GL_LINE_STRIP_ADJACENCY           0x000B
#define GL_TRIANGLES_ADJACENCY            0x000C
#define GL_TRIANGLE_STRIP_ADJACENCY       0x000D
#define GL_PROGRAM_POINT_SIZE             0x8642
#define GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS 0x8C29
#define GL_FRAMEBUFFER_ATTACHMENT_LAYERED 0x8DA7
#define GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS 0x8DA8
#define GL_GEOMETRY_SHADER                0x8DD9
#define GL_GEOMETRY_VERTICES_OUT          0x8916
#define GL_GEOMETRY_INPUT_TYPE            0x8917
#define GL_GEOMETRY_OUTPUT_TYPE           0x8918
#define GL_MAX_GEOMETRY_UNIFORM_COMPONENTS 0x8DDF
#define GL_MAX_GEOMETRY_OUTPUT_VERTICES   0x8DE0
#define GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS 0x8DE1
#define GL_MAX_VERTEX_OUTPUT_COMPONENTS   0x9122
#define GL_MAX_GEOMETRY_INPUT_COMPONENTS  0x9123
#define GL_MAX_GEOMETRY_OUTPUT_COMPONENTS 0x9124
#define GL_MAX_FRAGMENT_INPUT_COMPONENTS  0x9125
#define GL_CONTEXT_PROFILE_MASK           0x9126
#define GL_DEPTH_CLAMP                    0x864F
#define GL_QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION 0x8E4C
#define GL_FIRST_VERTEX_CONVENTION        0x8E4D
#define GL_LAST_VERTEX_CONVENTION         0x8E4E
#define GL_PROVOKING_VERTEX               0x8E4F
#define GL_TEXTURE_CUBE_MAP_SEAMLESS      0x884F
#define GL_MAX_SERVER_WAIT_TIMEOUT        0x9111
#define GL_OBJECT_TYPE                    0x9112
#define GL_SYNC_CONDITION                 0x9113
#define GL_SYNC_STATUS                    0x9114
#define GL_SYNC_FLAGS                     0x9115
#define GL_SYNC_FENCE                     0x9116
#define GL_SYNC_GPU_COMMANDS_COMPLETE     0x9117
#define GL_UNSIGNALED                     0x9118
#define GL_SIGNALED                       0x9119
#define GL_ALREADY_SIGNALED               0x911A
#define GL_TIMEOUT_EXPIRED                0x911B
#define GL_CONDITION_SATISFIED            0x911C
#define GL_WAIT_FAILED                    0x911D
#define GL_TIMEOUT_IGNORED                0xFFFFFFFFFFFFFFFFull
#define GL_SYNC_FLUSH_COMMANDS_BIT        0x00000001
#define GL_SAMPLE_POSITION                0x8E50
#define GL_SAMPLE_MASK                    0x8E51
#define GL_SAMPLE_MASK_VALUE              0x8E52
#define GL_MAX_SAMPLE_MASK_WORDS          0x8E59
#define GL_TEXTURE_2D_MULTISAMPLE         0x9100
#define GL_PROXY_TEXTURE_2D_MULTISAMPLE   0x9101
#define GL_TEXTURE_2D_MULTISAMPLE_ARRAY   0x9102
#define GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY 0x9103
#define GL_TEXTURE_BINDING_2D_MULTISAMPLE 0x9104
#define GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY 0x9105
#define GL_TEXTURE_SAMPLES                0x9106
#define GL_TEXTURE_FIXED_SAMPLE_LOCATIONS 0x9107
#define GL_SAMPLER_2D_MULTISAMPLE         0x9108
#define GL_INT_SAMPLER_2D_MULTISAMPLE     0x9109
#define GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE 0x910A
#define GL_SAMPLER_2D_MULTISAMPLE_ARRAY   0x910B
#define GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY 0x910C
#define GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY 0x910D
#define GL_MAX_COLOR_TEXTURE_SAMPLES      0x910E
#define GL_MAX_DEPTH_TEXTURE_SAMPLES      0x910F
#define GL_MAX_INTEGER_SAMPLES            0x9110
typedef void (APIENTRYP PFNGLDRAWELEMENTSBASEVERTEXPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLint basevertex);
typedef void (APIENTRYP PFNGLDRAWRANGEELEMENTSBASEVERTEXPROC) (GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const void *indices, GLint basevertex);
typedef void (APIENTRYP PFNGLDRAWELEMENTSINSTANCEDBASEVERTEXPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount, GLint basevertex);
typedef void (APIENTRYP PFNGLMULTIDRAWELEMENTSBASEVERTEXPROC) (GLenum mode, const GLsizei *count, GLenum type, const void *const*indices, GLsizei drawcount, const GLint *basevertex);
typedef void (APIENTRYP PFNGLPROVOKINGVERTEXPROC) (GLenum mode);
typedef GLsync (APIENTRYP PFNGLFENCESYNCPROC) (GLenum condition, GLbitfield flags);
typedef GLboolean (APIENTRYP PFNGLISSYNCPROC) (GLsync sync);
typedef void (APIENTRYP PFNGLDELETESYNCPROC) (GLsync sync);
typedef GLenum (APIENTRYP PFNGLCLIENTWAITSYNCPROC) (GLsync sync, GLbitfield flags, GLuint64 timeout);
typedef void (APIENTRYP PFNGLWAITSYNCPROC) (GLsync sync, GLbitfield flags, GLuint64 timeout);
typedef void (APIENTRYP PFNGLGETINTEGER64VPROC) (GLenum pname, GLint64 *data);
typedef void (APIENTRYP PFNGLGETSYNCIVPROC) (GLsync sync, GLenum pname, GLsizei bufSize, GLsizei *length, GLint *values);
typedef void (APIENTRYP PFNGLGETINTEGER64I_VPROC) (GLenum target, GLuint index, GLint64 *data);
typedef void (APIENTRYP PFNGLGETBUFFERPARAMETERI64VPROC) (GLenum target, GLenum pname, GLint64 *params);
typedef void (APIENTRYP PFNGLFRAMEBUFFERTEXTUREPROC) (GLenum target, GLenum attachment, GLuint texture, GLint level);
typedef void (APIENTRYP PFNGLTEXIMAGE2DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLboolean fixedsamplelocations);
typedef void (APIENTRYP PFNGLTEXIMAGE3DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedsamplelocations);
typedef void (APIENTRYP PFNGLGETMULTISAMPLEFVPROC) (GLenum pname, GLuint index, GLfloat *val);
typedef void (APIENTRYP PFNGLSAMPLEMASKIPROC) (GLuint maskNumber, GLbitfield mask);

#define GL_VERTEX_ATTRIB_ARRAY_DIVISOR    0x88FE
#define GL_SRC1_COLOR                     0x88F9
#define GL_ONE_MINUS_SRC1_COLOR           0x88FA
#define GL_ONE_MINUS_SRC1_ALPHA           0x88FB
#define GL_MAX_DUAL_SOURCE_DRAW_BUFFERS   0x88FC
#define GL_ANY_SAMPLES_PASSED             0x8C2F
#define GL_SAMPLER_BINDING                0x8919
#define GL_RGB10_A2UI                     0x906F
#define GL_TEXTURE_SWIZZLE_R              0x8E42
#define GL_TEXTURE_SWIZZLE_G              0x8E43
#define GL_TEXTURE_SWIZZLE_B              0x8E44
#define GL_TEXTURE_SWIZZLE_A              0x8E45
#define GL_TEXTURE_SWIZZLE_RGBA           0x8E46
#define GL_TIME_ELAPSED                   0x88BF
#define GL_TIMESTAMP                      0x8E28
#define GL_INT_2_10_10_10_REV             0x8D9F
typedef void (APIENTRYP PFNGLBINDFRAGDATALOCATIONINDEXEDPROC) (GLuint program, GLuint colorNumber, GLuint index, const GLchar *name);
typedef GLint (APIENTRYP PFNGLGETFRAGDATAINDEXPROC) (GLuint program, const GLchar *name);
typedef void (APIENTRYP PFNGLGENSAMPLERSPROC) (GLsizei count, GLuint *samplers);
typedef void (APIENTRYP PFNGLDELETESAMPLERSPROC) (GLsizei count, const GLuint *samplers);
typedef GLboolean (APIENTRYP PFNGLISSAMPLERPROC) (GLuint sampler);
typedef void (APIENTRYP PFNGLBINDSAMPLERPROC) (GLuint unit, GLuint sampler);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERIPROC) (GLuint sampler, GLenum pname, GLint param);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERIVPROC) (GLuint sampler, GLenum pname, const GLint *param);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERFPROC) (GLuint sampler, GLenum pname, GLfloat param);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERFVPROC) (GLuint sampler, GLenum pname, const GLfloat *param);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERIIVPROC) (GLuint sampler, GLenum pname, const GLint *param);
typedef void (APIENTRYP PFNGLSAMPLERPARAMETERIUIVPROC) (GLuint sampler, GLenum pname, const GLuint *param);
typedef void (APIENTRYP PFNGLGETSAMPLERPARAMETERIVPROC) (GLuint sampler, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETSAMPLERPARAMETERIIVPROC) (GLuint sampler, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETSAMPLERPARAMETERFVPROC) (GLuint sampler, GLenum pname, GLfloat *params);
typedef void (APIENTRYP PFNGLGETSAMPLERPARAMETERIUIVPROC) (GLuint sampler, GLenum pname, GLuint *params);
typedef void (APIENTRYP PFNGLQUERYCOUNTERPROC) (GLuint id, GLenum target);
typedef void (APIENTRYP PFNGLGETQUERYOBJECTI64VPROC) (GLuint id, GLenum pname, GLint64 *params);
typedef void (APIENTRYP PFNGLGETQUERYOBJECTUI64VPROC) (GLuint id, GLenum pname, GLuint64 *params);
typedef void (APIENTRYP PFNGLVERTEXATTRIBDIVISORPROC) (GLuint index, GLuint divisor);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP1UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP1UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP2UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP2UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP3UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP3UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP4UIPROC) (GLuint index, GLenum type, GLboolean normalized, GLuint value);
typedef void (APIENTRYP PFNGLVERTEXATTRIBP4UIVPROC) (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);

#define GL_SAMPLE_SHADING                 0x8C36
#define GL_MIN_SAMPLE_SHADING_VALUE       0x8C37
#define GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET 0x8E5E
#define GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET 0x8E5F
#define GL_TEXTURE_CUBE_MAP_ARRAY         0x9009
#define GL_TEXTURE_BINDING_CUBE_MAP_ARRAY 0x900A
#define GL_PROXY_TEXTURE_CUBE_MAP_ARRAY   0x900B
#define GL_SAMPLER_CUBE_MAP_ARRAY         0x900C
#define GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW  0x900D
#define GL_INT_SAMPLER_CUBE_MAP_ARRAY     0x900E
#define GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY 0x900F
#define GL_DRAW_INDIRECT_BUFFER           0x8F3F
#define GL_DRAW_INDIRECT_BUFFER_BINDING   0x8F43
#define GL_GEOMETRY_SHADER_INVOCATIONS    0x887F
#define GL_MAX_GEOMETRY_SHADER_INVOCATIONS 0x8E5A
#define GL_MIN_FRAGMENT_INTERPOLATION_OFFSET 0x8E5B
#define GL_MAX_FRAGMENT_INTERPOLATION_OFFSET 0x8E5C
#define GL_FRAGMENT_INTERPOLATION_OFFSET_BITS 0x8E5D
#define GL_MAX_VERTEX_STREAMS             0x8E71
#define GL_DOUBLE_VEC2                    0x8FFC
#define GL_DOUBLE_VEC3                    0x8FFD
#define GL_DOUBLE_VEC4                    0x8FFE
#define GL_DOUBLE_MAT2                    0x8F46
#define GL_DOUBLE_MAT3                    0x8F47
#define GL_DOUBLE_MAT4                    0x8F48
#define GL_DOUBLE_MAT2x3                  0x8F49
#define GL_DOUBLE_MAT2x4                  0x8F4A
#define GL_DOUBLE_MAT3x2                  0x8F4B
#define GL_DOUBLE_MAT3x4                  0x8F4C
#define GL_DOUBLE_MAT4x2                  0x8F4D
#define GL_DOUBLE_MAT4x3                  0x8F4E
#define GL_ACTIVE_SUBROUTINES             0x8DE5
#define GL_ACTIVE_SUBROUTINE_UNIFORMS     0x8DE6
#define GL_ACTIVE_SUBROUTINE_UNIFORM_LOCATIONS 0x8E47
#define GL_ACTIVE_SUBROUTINE_MAX_LENGTH   0x8E48
#define GL_ACTIVE_SUBROUTINE_UNIFORM_MAX_LENGTH 0x8E49
#define GL_MAX_SUBROUTINES                0x8DE7
#define GL_MAX_SUBROUTINE_UNIFORM_LOCATIONS 0x8DE8
#define GL_NUM_COMPATIBLE_SUBROUTINES     0x8E4A
#define GL_COMPATIBLE_SUBROUTINES         0x8E4B
#define GL_PATCHES                        0x000E
#define GL_PATCH_VERTICES                 0x8E72
#define GL_PATCH_DEFAULT_INNER_LEVEL      0x8E73
#define GL_PATCH_DEFAULT_OUTER_LEVEL      0x8E74
#define GL_TESS_CONTROL_OUTPUT_VERTICES   0x8E75
#define GL_TESS_GEN_MODE                  0x8E76
#define GL_TESS_GEN_SPACING               0x8E77
#define GL_TESS_GEN_VERTEX_ORDER          0x8E78
#define GL_TESS_GEN_POINT_MODE            0x8E79
#define GL_ISOLINES                       0x8E7A
#define GL_FRACTIONAL_ODD                 0x8E7B
#define GL_FRACTIONAL_EVEN                0x8E7C
#define GL_MAX_PATCH_VERTICES             0x8E7D
#define GL_MAX_TESS_GEN_LEVEL             0x8E7E
#define GL_MAX_TESS_CONTROL_UNIFORM_COMPONENTS 0x8E7F
#define GL_MAX_TESS_EVALUATION_UNIFORM_COMPONENTS 0x8E80
#define GL_MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS 0x8E81
#define GL_MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS 0x8E82
#define GL_MAX_TESS_CONTROL_OUTPUT_COMPONENTS 0x8E83
#define GL_MAX_TESS_PATCH_COMPONENTS      0x8E84
#define GL_MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS 0x8E85
#define GL_MAX_TESS_EVALUATION_OUTPUT_COMPONENTS 0x8E86
#define GL_MAX_TESS_CONTROL_UNIFORM_BLOCKS 0x8E89
#define GL_MAX_TESS_EVALUATION_UNIFORM_BLOCKS 0x8E8A
#define GL_MAX_TESS_CONTROL_INPUT_COMPONENTS 0x886C
#define GL_MAX_TESS_EVALUATION_INPUT_COMPONENTS 0x886D
#define GL_MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS 0x8E1E
#define GL_MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS 0x8E1F
#define GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_CONTROL_SHADER 0x84F0
#define GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_EVALUATION_SHADER 0x84F1
#define GL_TESS_EVALUATION_SHADER         0x8E87
#define GL_TESS_CONTROL_SHADER            0x8E88
#define GL_TRANSFORM_FEEDBACK             0x8E22
#define GL_TRANSFORM_FEEDBACK_BUFFER_PAUSED 0x8E23
#define GL_TRANSFORM_FEEDBACK_BUFFER_ACTIVE 0x8E24
#define GL_TRANSFORM_FEEDBACK_BINDING     0x8E25
#define GL_MAX_TRANSFORM_FEEDBACK_BUFFERS 0x8E70
typedef void (APIENTRYP PFNGLMINSAMPLESHADINGPROC) (GLfloat value);
typedef void (APIENTRYP PFNGLBLENDEQUATIONIPROC) (GLuint buf, GLenum mode);
typedef void (APIENTRYP PFNGLBLENDEQUATIONSEPARATEIPROC) (GLuint buf, GLenum modeRGB, GLenum modeAlpha);
typedef void (APIENTRYP PFNGLBLENDFUNCIPROC) (GLuint buf, GLenum src, GLenum dst);
typedef void (APIENTRYP PFNGLBLENDFUNCSEPARATEIPROC) (GLuint buf, GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);
typedef void (APIENTRYP PFNGLDRAWARRAYSINDIRECTPROC) (GLenum mode, const void *indirect);
typedef void (APIENTRYP PFNGLDRAWELEMENTSINDIRECTPROC) (GLenum mode, GLenum type, const void *indirect);
typedef void (APIENTRYP PFNGLUNIFORM1DPROC) (GLint location, GLdouble x);
typedef void (APIENTRYP PFNGLUNIFORM2DPROC) (GLint location, GLdouble x, GLdouble y);
typedef void (APIENTRYP PFNGLUNIFORM3DPROC) (GLint location, GLdouble x, GLdouble y, GLdouble z);
typedef void (APIENTRYP PFNGLUNIFORM4DPROC) (GLint location, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
typedef void (APIENTRYP PFNGLUNIFORM1DVPROC) (GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORM2DVPROC) (GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORM3DVPROC) (GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORM4DVPROC) (GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2X3DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX2X4DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3X2DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX3X4DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4X2DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLUNIFORMMATRIX4X3DVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLGETUNIFORMDVPROC) (GLuint program, GLint location, GLdouble *params);
typedef GLint (APIENTRYP PFNGLGETSUBROUTINEUNIFORMLOCATIONPROC) (GLuint program, GLenum shadertype, const GLchar *name);
typedef GLuint (APIENTRYP PFNGLGETSUBROUTINEINDEXPROC) (GLuint program, GLenum shadertype, const GLchar *name);
typedef void (APIENTRYP PFNGLGETACTIVESUBROUTINEUNIFORMIVPROC) (GLuint program, GLenum shadertype, GLuint index, GLenum pname, GLint *values);
typedef void (APIENTRYP PFNGLGETACTIVESUBROUTINEUNIFORMNAMEPROC) (GLuint program, GLenum shadertype, GLuint index, GLsizei bufsize, GLsizei *length, GLchar *name);
typedef void (APIENTRYP PFNGLGETACTIVESUBROUTINENAMEPROC) (GLuint program, GLenum shadertype, GLuint index, GLsizei bufsize, GLsizei *length, GLchar *name);
typedef void (APIENTRYP PFNGLUNIFORMSUBROUTINESUIVPROC) (GLenum shadertype, GLsizei count, const GLuint *indices);
typedef void (APIENTRYP PFNGLGETUNIFORMSUBROUTINEUIVPROC) (GLenum shadertype, GLint location, GLuint *params);
typedef void (APIENTRYP PFNGLGETPROGRAMSTAGEIVPROC) (GLuint program, GLenum shadertype, GLenum pname, GLint *values);
typedef void (APIENTRYP PFNGLPATCHPARAMETERIPROC) (GLenum pname, GLint value);
typedef void (APIENTRYP PFNGLPATCHPARAMETERFVPROC) (GLenum pname, const GLfloat *values);
typedef void (APIENTRYP PFNGLBINDTRANSFORMFEEDBACKPROC) (GLenum target, GLuint id);
typedef void (APIENTRYP PFNGLDELETETRANSFORMFEEDBACKSPROC) (GLsizei n, const GLuint *ids);
typedef void (APIENTRYP PFNGLGENTRANSFORMFEEDBACKSPROC) (GLsizei n, GLuint *ids);
typedef GLboolean (APIENTRYP PFNGLISTRANSFORMFEEDBACKPROC) (GLuint id);
typedef void (APIENTRYP PFNGLPAUSETRANSFORMFEEDBACKPROC) (void);
typedef void (APIENTRYP PFNGLRESUMETRANSFORMFEEDBACKPROC) (void);
typedef void (APIENTRYP PFNGLDRAWTRANSFORMFEEDBACKPROC) (GLenum mode, GLuint id);
typedef void (APIENTRYP PFNGLDRAWTRANSFORMFEEDBACKSTREAMPROC) (GLenum mode, GLuint id, GLuint stream);
typedef void (APIENTRYP PFNGLBEGINQUERYINDEXEDPROC) (GLenum target, GLuint index, GLuint id);
typedef void (APIENTRYP PFNGLENDQUERYINDEXEDPROC) (GLenum target, GLuint index);
typedef void (APIENTRYP PFNGLGETQUERYINDEXEDIVPROC) (GLenum target, GLuint index, GLenum pname, GLint *params);

#define GL_FIXED                          0x140C
#define GL_IMPLEMENTATION_COLOR_READ_TYPE 0x8B9A
#define GL_IMPLEMENTATION_COLOR_READ_FORMAT 0x8B9B
#define GL_LOW_FLOAT                      0x8DF0
#define GL_MEDIUM_FLOAT                   0x8DF1
#define GL_HIGH_FLOAT                     0x8DF2
#define GL_LOW_INT                        0x8DF3
#define GL_MEDIUM_INT                     0x8DF4
#define GL_HIGH_INT                       0x8DF5
#define GL_SHADER_COMPILER                0x8DFA
#define GL_SHADER_BINARY_FORMATS          0x8DF8
#define GL_NUM_SHADER_BINARY_FORMATS      0x8DF9
#define GL_MAX_VERTEX_UNIFORM_VECTORS     0x8DFB
#define GL_MAX_VARYING_VECTORS            0x8DFC
#define GL_MAX_FRAGMENT_UNIFORM_VECTORS   0x8DFD
#define GL_RGB565                         0x8D62
#define GL_PROGRAM_BINARY_RETRIEVABLE_HINT 0x8257
#define GL_PROGRAM_BINARY_LENGTH          0x8741
#define GL_NUM_PROGRAM_BINARY_FORMATS     0x87FE
#define GL_PROGRAM_BINARY_FORMATS         0x87FF
#define GL_VERTEX_SHADER_BIT              0x00000001
#define GL_FRAGMENT_SHADER_BIT            0x00000002
#define GL_GEOMETRY_SHADER_BIT            0x00000004
#define GL_TESS_CONTROL_SHADER_BIT        0x00000008
#define GL_TESS_EVALUATION_SHADER_BIT     0x00000010
#define GL_ALL_SHADER_BITS                0xFFFFFFFF
#define GL_PROGRAM_SEPARABLE              0x8258
#define GL_ACTIVE_PROGRAM                 0x8259
#define GL_PROGRAM_PIPELINE_BINDING       0x825A
#define GL_MAX_VIEWPORTS                  0x825B
#define GL_VIEWPORT_SUBPIXEL_BITS         0x825C
#define GL_VIEWPORT_BOUNDS_RANGE          0x825D
#define GL_LAYER_PROVOKING_VERTEX         0x825E
#define GL_VIEWPORT_INDEX_PROVOKING_VERTEX 0x825F
#define GL_UNDEFINED_VERTEX               0x8260
typedef void (APIENTRYP PFNGLRELEASESHADERCOMPILERPROC) (void);
typedef void (APIENTRYP PFNGLSHADERBINARYPROC) (GLsizei count, const GLuint *shaders, GLenum binaryformat, const void *binary, GLsizei length);
typedef void (APIENTRYP PFNGLGETSHADERPRECISIONFORMATPROC) (GLenum shadertype, GLenum precisiontype, GLint *range, GLint *precision);
typedef void (APIENTRYP PFNGLDEPTHRANGEFPROC) (GLfloat n, GLfloat f);
typedef void (APIENTRYP PFNGLCLEARDEPTHFPROC) (GLfloat d);
typedef void (APIENTRYP PFNGLGETPROGRAMBINARYPROC) (GLuint program, GLsizei bufSize, GLsizei *length, GLenum *binaryFormat, void *binary);
typedef void (APIENTRYP PFNGLPROGRAMBINARYPROC) (GLuint program, GLenum binaryFormat, const void *binary, GLsizei length);
typedef void (APIENTRYP PFNGLPROGRAMPARAMETERIPROC) (GLuint program, GLenum pname, GLint value);
typedef void (APIENTRYP PFNGLUSEPROGRAMSTAGESPROC) (GLuint pipeline, GLbitfield stages, GLuint program);
typedef void (APIENTRYP PFNGLACTIVESHADERPROGRAMPROC) (GLuint pipeline, GLuint program);
typedef GLuint (APIENTRYP PFNGLCREATESHADERPROGRAMVPROC) (GLenum type, GLsizei count, const GLchar *const*strings);
typedef void (APIENTRYP PFNGLBINDPROGRAMPIPELINEPROC) (GLuint pipeline);
typedef void (APIENTRYP PFNGLDELETEPROGRAMPIPELINESPROC) (GLsizei n, const GLuint *pipelines);
typedef void (APIENTRYP PFNGLGENPROGRAMPIPELINESPROC) (GLsizei n, GLuint *pipelines);
typedef GLboolean (APIENTRYP PFNGLISPROGRAMPIPELINEPROC) (GLuint pipeline);
typedef void (APIENTRYP PFNGLGETPROGRAMPIPELINEIVPROC) (GLuint pipeline, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1IPROC) (GLuint program, GLint location, GLint v0);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1FPROC) (GLuint program, GLint location, GLfloat v0);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1DPROC) (GLuint program, GLint location, GLdouble v0);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1UIPROC) (GLuint program, GLint location, GLuint v0);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM1UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2IPROC) (GLuint program, GLint location, GLint v0, GLint v1);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2FPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2DPROC) (GLuint program, GLint location, GLdouble v0, GLdouble v1);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2UIPROC) (GLuint program, GLint location, GLuint v0, GLuint v1);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM2UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3IPROC) (GLuint program, GLint location, GLint v0, GLint v1, GLint v2);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3FPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3DPROC) (GLuint program, GLint location, GLdouble v0, GLdouble v1, GLdouble v2);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3UIPROC) (GLuint program, GLint location, GLuint v0, GLuint v1, GLuint v2);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM3UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4IPROC) (GLuint program, GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4IVPROC) (GLuint program, GLint location, GLsizei count, const GLint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4FPROC) (GLuint program, GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4FVPROC) (GLuint program, GLint location, GLsizei count, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4DPROC) (GLuint program, GLint location, GLdouble v0, GLdouble v1, GLdouble v2, GLdouble v3);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4DVPROC) (GLuint program, GLint location, GLsizei count, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4UIPROC) (GLuint program, GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORM4UIVPROC) (GLuint program, GLint location, GLsizei count, const GLuint *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2X3FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3X2FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2X4FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4X2FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3X4FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4X3FVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2X3DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3X2DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX2X4DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4X2DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX3X4DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMMATRIX4X3DVPROC) (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
typedef void (APIENTRYP PFNGLVALIDATEPROGRAMPIPELINEPROC) (GLuint pipeline);
typedef void (APIENTRYP PFNGLGETPROGRAMPIPELINEINFOLOGPROC) (GLuint pipeline, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL1DPROC) (GLuint index, GLdouble x);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL2DPROC) (GLuint index, GLdouble x, GLdouble y);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL3DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL4DPROC) (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL1DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL2DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL3DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL4DVPROC) (GLuint index, const GLdouble *v);
typedef void (APIENTRYP PFNGLVERTEXATTRIBLPOINTERPROC) (GLuint index, GLint size, GLenum type, GLsizei stride, const void *pointer);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBLDVPROC) (GLuint index, GLenum pname, GLdouble *params);
typedef void (APIENTRYP PFNGLVIEWPORTARRAYVPROC) (GLuint first, GLsizei count, const GLfloat *v);
typedef void (APIENTRYP PFNGLVIEWPORTINDEXEDFPROC) (GLuint index, GLfloat x, GLfloat y, GLfloat w, GLfloat h);
typedef void (APIENTRYP PFNGLVIEWPORTINDEXEDFVPROC) (GLuint index, const GLfloat *v);
typedef void (APIENTRYP PFNGLSCISSORARRAYVPROC) (GLuint first, GLsizei count, const GLint *v);
typedef void (APIENTRYP PFNGLSCISSORINDEXEDPROC) (GLuint index, GLint left, GLint bottom, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLSCISSORINDEXEDVPROC) (GLuint index, const GLint *v);
typedef void (APIENTRYP PFNGLDEPTHRANGEARRAYVPROC) (GLuint first, GLsizei count, const GLdouble *v);
typedef void (APIENTRYP PFNGLDEPTHRANGEINDEXEDPROC) (GLuint index, GLdouble n, GLdouble f);
typedef void (APIENTRYP PFNGLGETFLOATI_VPROC) (GLenum target, GLuint index, GLfloat *data);
typedef void (APIENTRYP PFNGLGETDOUBLEI_VPROC) (GLenum target, GLuint index, GLdouble *data);

#define GL_UNPACK_COMPRESSED_BLOCK_WIDTH  0x9127
#define GL_UNPACK_COMPRESSED_BLOCK_HEIGHT 0x9128
#define GL_UNPACK_COMPRESSED_BLOCK_DEPTH  0x9129
#define GL_UNPACK_COMPRESSED_BLOCK_SIZE   0x912A
#define GL_PACK_COMPRESSED_BLOCK_WIDTH    0x912B
#define GL_PACK_COMPRESSED_BLOCK_HEIGHT   0x912C
#define GL_PACK_COMPRESSED_BLOCK_DEPTH    0x912D
#define GL_PACK_COMPRESSED_BLOCK_SIZE     0x912E
#define GL_NUM_SAMPLE_COUNTS              0x9380
#define GL_MIN_MAP_BUFFER_ALIGNMENT       0x90BC
#define GL_ATOMIC_COUNTER_BUFFER          0x92C0
#define GL_ATOMIC_COUNTER_BUFFER_BINDING  0x92C1
#define GL_ATOMIC_COUNTER_BUFFER_START    0x92C2
#define GL_ATOMIC_COUNTER_BUFFER_SIZE     0x92C3
#define GL_ATOMIC_COUNTER_BUFFER_DATA_SIZE 0x92C4
#define GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTERS 0x92C5
#define GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTER_INDICES 0x92C6
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_VERTEX_SHADER 0x92C7
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_CONTROL_SHADER 0x92C8
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_EVALUATION_SHADER 0x92C9
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_GEOMETRY_SHADER 0x92CA
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_FRAGMENT_SHADER 0x92CB
#define GL_MAX_VERTEX_ATOMIC_COUNTER_BUFFERS 0x92CC
#define GL_MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS 0x92CD
#define GL_MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS 0x92CE
#define GL_MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS 0x92CF
#define GL_MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS 0x92D0
#define GL_MAX_COMBINED_ATOMIC_COUNTER_BUFFERS 0x92D1
#define GL_MAX_VERTEX_ATOMIC_COUNTERS     0x92D2
#define GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS 0x92D3
#define GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS 0x92D4
#define GL_MAX_GEOMETRY_ATOMIC_COUNTERS   0x92D5
#define GL_MAX_FRAGMENT_ATOMIC_COUNTERS   0x92D6
#define GL_MAX_COMBINED_ATOMIC_COUNTERS   0x92D7
#define GL_MAX_ATOMIC_COUNTER_BUFFER_SIZE 0x92D8
#define GL_MAX_ATOMIC_COUNTER_BUFFER_BINDINGS 0x92DC
#define GL_ACTIVE_ATOMIC_COUNTER_BUFFERS  0x92D9
#define GL_UNIFORM_ATOMIC_COUNTER_BUFFER_INDEX 0x92DA
#define GL_UNSIGNED_INT_ATOMIC_COUNTER    0x92DB
#define GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT 0x00000001
#define GL_ELEMENT_ARRAY_BARRIER_BIT      0x00000002
#define GL_UNIFORM_BARRIER_BIT            0x00000004
#define GL_TEXTURE_FETCH_BARRIER_BIT      0x00000008
#define GL_SHADER_IMAGE_ACCESS_BARRIER_BIT 0x00000020
#define GL_COMMAND_BARRIER_BIT            0x00000040
#define GL_PIXEL_BUFFER_BARRIER_BIT       0x00000080
#define GL_TEXTURE_UPDATE_BARRIER_BIT     0x00000100
#define GL_BUFFER_UPDATE_BARRIER_BIT      0x00000200
#define GL_FRAMEBUFFER_BARRIER_BIT        0x00000400
#define GL_TRANSFORM_FEEDBACK_BARRIER_BIT 0x00000800
#define GL_ATOMIC_COUNTER_BARRIER_BIT     0x00001000
#define GL_ALL_BARRIER_BITS               0xFFFFFFFF
#define GL_MAX_IMAGE_UNITS                0x8F38
#define GL_MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS 0x8F39
#define GL_IMAGE_BINDING_NAME             0x8F3A
#define GL_IMAGE_BINDING_LEVEL            0x8F3B
#define GL_IMAGE_BINDING_LAYERED          0x8F3C
#define GL_IMAGE_BINDING_LAYER            0x8F3D
#define GL_IMAGE_BINDING_ACCESS           0x8F3E
#define GL_IMAGE_1D                       0x904C
#define GL_IMAGE_2D                       0x904D
#define GL_IMAGE_3D                       0x904E
#define GL_IMAGE_2D_RECT                  0x904F
#define GL_IMAGE_CUBE                     0x9050
#define GL_IMAGE_BUFFER                   0x9051
#define GL_IMAGE_1D_ARRAY                 0x9052
#define GL_IMAGE_2D_ARRAY                 0x9053
#define GL_IMAGE_CUBE_MAP_ARRAY           0x9054
#define GL_IMAGE_2D_MULTISAMPLE           0x9055
#define GL_IMAGE_2D_MULTISAMPLE_ARRAY     0x9056
#define GL_INT_IMAGE_1D                   0x9057
#define GL_INT_IMAGE_2D                   0x9058
#define GL_INT_IMAGE_3D                   0x9059
#define GL_INT_IMAGE_2D_RECT              0x905A
#define GL_INT_IMAGE_CUBE                 0x905B
#define GL_INT_IMAGE_BUFFER               0x905C
#define GL_INT_IMAGE_1D_ARRAY             0x905D
#define GL_INT_IMAGE_2D_ARRAY             0x905E
#define GL_INT_IMAGE_CUBE_MAP_ARRAY       0x905F
#define GL_INT_IMAGE_2D_MULTISAMPLE       0x9060
#define GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY 0x9061
#define GL_UNSIGNED_INT_IMAGE_1D          0x9062
#define GL_UNSIGNED_INT_IMAGE_2D          0x9063
#define GL_UNSIGNED_INT_IMAGE_3D          0x9064
#define GL_UNSIGNED_INT_IMAGE_2D_RECT     0x9065
#define GL_UNSIGNED_INT_IMAGE_CUBE        0x9066
#define GL_UNSIGNED_INT_IMAGE_BUFFER      0x9067
#define GL_UNSIGNED_INT_IMAGE_1D_ARRAY    0x9068
#define GL_UNSIGNED_INT_IMAGE_2D_ARRAY    0x9069
#define GL_UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY 0x906A
#define GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE 0x906B
#define GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY 0x906C
#define GL_MAX_IMAGE_SAMPLES              0x906D
#define GL_IMAGE_BINDING_FORMAT           0x906E
#define GL_IMAGE_FORMAT_COMPATIBILITY_TYPE 0x90C7
#define GL_IMAGE_FORMAT_COMPATIBILITY_BY_SIZE 0x90C8
#define GL_IMAGE_FORMAT_COMPATIBILITY_BY_CLASS 0x90C9
#define GL_MAX_VERTEX_IMAGE_UNIFORMS      0x90CA
#define GL_MAX_TESS_CONTROL_IMAGE_UNIFORMS 0x90CB
#define GL_MAX_TESS_EVALUATION_IMAGE_UNIFORMS 0x90CC
#define GL_MAX_GEOMETRY_IMAGE_UNIFORMS    0x90CD
#define GL_MAX_FRAGMENT_IMAGE_UNIFORMS    0x90CE
#define GL_MAX_COMBINED_IMAGE_UNIFORMS    0x90CF
#define GL_COMPRESSED_RGBA_BPTC_UNORM     0x8E8C
#define GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM 0x8E8D
#define GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT 0x8E8E
#define GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT 0x8E8F
#define GL_TEXTURE_IMMUTABLE_FORMAT       0x912F
typedef void (APIENTRYP PFNGLDRAWARRAYSINSTANCEDBASEINSTANCEPROC) (GLenum mode, GLint first, GLsizei count, GLsizei instancecount, GLuint baseinstance);
typedef void (APIENTRYP PFNGLDRAWELEMENTSINSTANCEDBASEINSTANCEPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount, GLuint baseinstance);
typedef void (APIENTRYP PFNGLDRAWELEMENTSINSTANCEDBASEVERTEXBASEINSTANCEPROC) (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount, GLint basevertex, GLuint baseinstance);
typedef void (APIENTRYP PFNGLGETINTERNALFORMATIVPROC) (GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint *params);
typedef void (APIENTRYP PFNGLGETACTIVEATOMICCOUNTERBUFFERIVPROC) (GLuint program, GLuint bufferIndex, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLBINDIMAGETEXTUREPROC) (GLuint unit, GLuint texture, GLint level, GLboolean layered, GLint layer, GLenum access, GLenum format);
typedef void (APIENTRYP PFNGLMEMORYBARRIERPROC) (GLbitfield barriers);
typedef void (APIENTRYP PFNGLTEXSTORAGE1DPROC) (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width);
typedef void (APIENTRYP PFNGLTEXSTORAGE2DPROC) (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLTEXSTORAGE3DPROC) (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);
typedef void (APIENTRYP PFNGLDRAWTRANSFORMFEEDBACKINSTANCEDPROC) (GLenum mode, GLuint id, GLsizei instancecount);
typedef void (APIENTRYP PFNGLDRAWTRANSFORMFEEDBACKSTREAMINSTANCEDPROC) (GLenum mode, GLuint id, GLuint stream, GLsizei instancecount);

typedef void (APIENTRY  *GLDEBUGPROC)(GLenum source,GLenum type,GLuint id,GLenum severity,GLsizei length,const GLchar *message,const void *userParam);
#define GL_NUM_SHADING_LANGUAGE_VERSIONS  0x82E9
#define GL_VERTEX_ATTRIB_ARRAY_LONG       0x874E
#define GL_COMPRESSED_RGB8_ETC2           0x9274
#define GL_COMPRESSED_SRGB8_ETC2          0x9275
#define GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 0x9276
#define GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 0x9277
#define GL_COMPRESSED_RGBA8_ETC2_EAC      0x9278
#define GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC 0x9279
#define GL_COMPRESSED_R11_EAC             0x9270
#define GL_COMPRESSED_SIGNED_R11_EAC      0x9271
#define GL_COMPRESSED_RG11_EAC            0x9272
#define GL_COMPRESSED_SIGNED_RG11_EAC     0x9273
#define GL_PRIMITIVE_RESTART_FIXED_INDEX  0x8D69
#define GL_ANY_SAMPLES_PASSED_CONSERVATIVE 0x8D6A
#define GL_MAX_ELEMENT_INDEX              0x8D6B
#define GL_COMPUTE_SHADER                 0x91B9
#define GL_MAX_COMPUTE_UNIFORM_BLOCKS     0x91BB
#define GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS 0x91BC
#define GL_MAX_COMPUTE_IMAGE_UNIFORMS     0x91BD
#define GL_MAX_COMPUTE_SHARED_MEMORY_SIZE 0x8262
#define GL_MAX_COMPUTE_UNIFORM_COMPONENTS 0x8263
#define GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS 0x8264
#define GL_MAX_COMPUTE_ATOMIC_COUNTERS    0x8265
#define GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS 0x8266
#define GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS 0x90EB
#define GL_MAX_COMPUTE_WORK_GROUP_COUNT   0x91BE
#define GL_MAX_COMPUTE_WORK_GROUP_SIZE    0x91BF
#define GL_COMPUTE_WORK_GROUP_SIZE        0x8267
#define GL_UNIFORM_BLOCK_REFERENCED_BY_COMPUTE_SHADER 0x90EC
#define GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_COMPUTE_SHADER 0x90ED
#define GL_DISPATCH_INDIRECT_BUFFER       0x90EE
#define GL_DISPATCH_INDIRECT_BUFFER_BINDING 0x90EF
#define GL_DEBUG_OUTPUT_SYNCHRONOUS       0x8242
#define GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH 0x8243
#define GL_DEBUG_CALLBACK_FUNCTION        0x8244
#define GL_DEBUG_CALLBACK_USER_PARAM      0x8245
#define GL_DEBUG_SOURCE_API               0x8246
#define GL_DEBUG_SOURCE_WINDOW_SYSTEM     0x8247
#define GL_DEBUG_SOURCE_SHADER_COMPILER   0x8248
#define GL_DEBUG_SOURCE_THIRD_PARTY       0x8249
#define GL_DEBUG_SOURCE_APPLICATION       0x824A
#define GL_DEBUG_SOURCE_OTHER             0x824B
#define GL_DEBUG_TYPE_ERROR               0x824C
#define GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR 0x824D
#define GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR  0x824E
#define GL_DEBUG_TYPE_PORTABILITY         0x824F
#define GL_DEBUG_TYPE_PERFORMANCE         0x8250
#define GL_DEBUG_TYPE_OTHER               0x8251
#define GL_MAX_DEBUG_MESSAGE_LENGTH       0x9143
#define GL_MAX_DEBUG_LOGGED_MESSAGES      0x9144
#define GL_DEBUG_LOGGED_MESSAGES          0x9145
#define GL_DEBUG_SEVERITY_HIGH            0x9146
#define GL_DEBUG_SEVERITY_MEDIUM          0x9147
#define GL_DEBUG_SEVERITY_LOW             0x9148
#define GL_DEBUG_TYPE_MARKER              0x8268
#define GL_DEBUG_TYPE_PUSH_GROUP          0x8269
#define GL_DEBUG_TYPE_POP_GROUP           0x826A
#define GL_DEBUG_SEVERITY_NOTIFICATION    0x826B
#define GL_MAX_DEBUG_GROUP_STACK_DEPTH    0x826C
#define GL_DEBUG_GROUP_STACK_DEPTH        0x826D
#define GL_BUFFER                         0x82E0
#define GL_SHADER                         0x82E1
#define GL_PROGRAM                        0x82E2
#define GL_QUERY                          0x82E3
#define GL_PROGRAM_PIPELINE               0x82E4
#define GL_SAMPLER                        0x82E6
#define GL_MAX_LABEL_LENGTH               0x82E8
#define GL_DEBUG_OUTPUT                   0x92E0
#define GL_CONTEXT_FLAG_DEBUG_BIT         0x00000002
#define GL_MAX_UNIFORM_LOCATIONS          0x826E
#define GL_FRAMEBUFFER_DEFAULT_WIDTH      0x9310
#define GL_FRAMEBUFFER_DEFAULT_HEIGHT     0x9311
#define GL_FRAMEBUFFER_DEFAULT_LAYERS     0x9312
#define GL_FRAMEBUFFER_DEFAULT_SAMPLES    0x9313
#define GL_FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS 0x9314
#define GL_MAX_FRAMEBUFFER_WIDTH          0x9315
#define GL_MAX_FRAMEBUFFER_HEIGHT         0x9316
#define GL_MAX_FRAMEBUFFER_LAYERS         0x9317
#define GL_MAX_FRAMEBUFFER_SAMPLES        0x9318
#define GL_INTERNALFORMAT_SUPPORTED       0x826F
#define GL_INTERNALFORMAT_PREFERRED       0x8270
#define GL_INTERNALFORMAT_RED_SIZE        0x8271
#define GL_INTERNALFORMAT_GREEN_SIZE      0x8272
#define GL_INTERNALFORMAT_BLUE_SIZE       0x8273
#define GL_INTERNALFORMAT_ALPHA_SIZE      0x8274
#define GL_INTERNALFORMAT_DEPTH_SIZE      0x8275
#define GL_INTERNALFORMAT_STENCIL_SIZE    0x8276
#define GL_INTERNALFORMAT_SHARED_SIZE     0x8277
#define GL_INTERNALFORMAT_RED_TYPE        0x8278
#define GL_INTERNALFORMAT_GREEN_TYPE      0x8279
#define GL_INTERNALFORMAT_BLUE_TYPE       0x827A
#define GL_INTERNALFORMAT_ALPHA_TYPE      0x827B
#define GL_INTERNALFORMAT_DEPTH_TYPE      0x827C
#define GL_INTERNALFORMAT_STENCIL_TYPE    0x827D
#define GL_MAX_WIDTH                      0x827E
#define GL_MAX_HEIGHT                     0x827F
#define GL_MAX_DEPTH                      0x8280
#define GL_MAX_LAYERS                     0x8281
#define GL_MAX_COMBINED_DIMENSIONS        0x8282
#define GL_COLOR_COMPONENTS               0x8283
#define GL_DEPTH_COMPONENTS               0x8284
#define GL_STENCIL_COMPONENTS             0x8285
#define GL_COLOR_RENDERABLE               0x8286
#define GL_DEPTH_RENDERABLE               0x8287
#define GL_STENCIL_RENDERABLE             0x8288
#define GL_FRAMEBUFFER_RENDERABLE         0x8289
#define GL_FRAMEBUFFER_RENDERABLE_LAYERED 0x828A
#define GL_FRAMEBUFFER_BLEND              0x828B
#define GL_READ_PIXELS                    0x828C
#define GL_READ_PIXELS_FORMAT             0x828D
#define GL_READ_PIXELS_TYPE               0x828E
#define GL_TEXTURE_IMAGE_FORMAT           0x828F
#define GL_TEXTURE_IMAGE_TYPE             0x8290
#define GL_GET_TEXTURE_IMAGE_FORMAT       0x8291
#define GL_GET_TEXTURE_IMAGE_TYPE         0x8292
#define GL_MIPMAP                         0x8293
#define GL_MANUAL_GENERATE_MIPMAP         0x8294
#define GL_AUTO_GENERATE_MIPMAP           0x8295
#define GL_COLOR_ENCODING                 0x8296
#define GL_SRGB_READ                      0x8297
#define GL_SRGB_WRITE                     0x8298
#define GL_FILTER                         0x829A
#define GL_VERTEX_TEXTURE                 0x829B
#define GL_TESS_CONTROL_TEXTURE           0x829C
#define GL_TESS_EVALUATION_TEXTURE        0x829D
#define GL_GEOMETRY_TEXTURE               0x829E
#define GL_FRAGMENT_TEXTURE               0x829F
#define GL_COMPUTE_TEXTURE                0x82A0
#define GL_TEXTURE_SHADOW                 0x82A1
#define GL_TEXTURE_GATHER                 0x82A2
#define GL_TEXTURE_GATHER_SHADOW          0x82A3
#define GL_SHADER_IMAGE_LOAD              0x82A4
#define GL_SHADER_IMAGE_STORE             0x82A5
#define GL_SHADER_IMAGE_ATOMIC            0x82A6
#define GL_IMAGE_TEXEL_SIZE               0x82A7
#define GL_IMAGE_COMPATIBILITY_CLASS      0x82A8
#define GL_IMAGE_PIXEL_FORMAT             0x82A9
#define GL_IMAGE_PIXEL_TYPE               0x82AA
#define GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_TEST 0x82AC
#define GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_TEST 0x82AD
#define GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_WRITE 0x82AE
#define GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_WRITE 0x82AF
#define GL_TEXTURE_COMPRESSED_BLOCK_WIDTH 0x82B1
#define GL_TEXTURE_COMPRESSED_BLOCK_HEIGHT 0x82B2
#define GL_TEXTURE_COMPRESSED_BLOCK_SIZE  0x82B3
#define GL_CLEAR_BUFFER                   0x82B4
#define GL_TEXTURE_VIEW                   0x82B5
#define GL_VIEW_COMPATIBILITY_CLASS       0x82B6
#define GL_FULL_SUPPORT                   0x82B7
#define GL_CAVEAT_SUPPORT                 0x82B8
#define GL_IMAGE_CLASS_4_X_32             0x82B9
#define GL_IMAGE_CLASS_2_X_32             0x82BA
#define GL_IMAGE_CLASS_1_X_32             0x82BB
#define GL_IMAGE_CLASS_4_X_16             0x82BC
#define GL_IMAGE_CLASS_2_X_16             0x82BD
#define GL_IMAGE_CLASS_1_X_16             0x82BE
#define GL_IMAGE_CLASS_4_X_8              0x82BF
#define GL_IMAGE_CLASS_2_X_8              0x82C0
#define GL_IMAGE_CLASS_1_X_8              0x82C1
#define GL_IMAGE_CLASS_11_11_10           0x82C2
#define GL_IMAGE_CLASS_10_10_10_2         0x82C3
#define GL_VIEW_CLASS_128_BITS            0x82C4
#define GL_VIEW_CLASS_96_BITS             0x82C5
#define GL_VIEW_CLASS_64_BITS             0x82C6
#define GL_VIEW_CLASS_48_BITS             0x82C7
#define GL_VIEW_CLASS_32_BITS             0x82C8
#define GL_VIEW_CLASS_24_BITS             0x82C9
#define GL_VIEW_CLASS_16_BITS             0x82CA
#define GL_VIEW_CLASS_8_BITS              0x82CB
#define GL_VIEW_CLASS_S3TC_DXT1_RGB       0x82CC
#define GL_VIEW_CLASS_S3TC_DXT1_RGBA      0x82CD
#define GL_VIEW_CLASS_S3TC_DXT3_RGBA      0x82CE
#define GL_VIEW_CLASS_S3TC_DXT5_RGBA      0x82CF
#define GL_VIEW_CLASS_RGTC1_RED           0x82D0
#define GL_VIEW_CLASS_RGTC2_RG            0x82D1
#define GL_VIEW_CLASS_BPTC_UNORM          0x82D2
#define GL_VIEW_CLASS_BPTC_FLOAT          0x82D3
#define GL_UNIFORM                        0x92E1
#define GL_UNIFORM_BLOCK                  0x92E2
#define GL_PROGRAM_INPUT                  0x92E3
#define GL_PROGRAM_OUTPUT                 0x92E4
#define GL_BUFFER_VARIABLE                0x92E5
#define GL_SHADER_STORAGE_BLOCK           0x92E6
#define GL_VERTEX_SUBROUTINE              0x92E8
#define GL_TESS_CONTROL_SUBROUTINE        0x92E9
#define GL_TESS_EVALUATION_SUBROUTINE     0x92EA
#define GL_GEOMETRY_SUBROUTINE            0x92EB
#define GL_FRAGMENT_SUBROUTINE            0x92EC
#define GL_COMPUTE_SUBROUTINE             0x92ED
#define GL_VERTEX_SUBROUTINE_UNIFORM      0x92EE
#define GL_TESS_CONTROL_SUBROUTINE_UNIFORM 0x92EF
#define GL_TESS_EVALUATION_SUBROUTINE_UNIFORM 0x92F0
#define GL_GEOMETRY_SUBROUTINE_UNIFORM    0x92F1
#define GL_FRAGMENT_SUBROUTINE_UNIFORM    0x92F2
#define GL_COMPUTE_SUBROUTINE_UNIFORM     0x92F3
#define GL_TRANSFORM_FEEDBACK_VARYING     0x92F4
#define GL_ACTIVE_RESOURCES               0x92F5
#define GL_MAX_NAME_LENGTH                0x92F6
#define GL_MAX_NUM_ACTIVE_VARIABLES       0x92F7
#define GL_MAX_NUM_COMPATIBLE_SUBROUTINES 0x92F8
#define GL_NAME_LENGTH                    0x92F9
#define GL_TYPE                           0x92FA
#define GL_ARRAY_SIZE                     0x92FB
#define GL_OFFSET                         0x92FC
#define GL_BLOCK_INDEX                    0x92FD
#define GL_ARRAY_STRIDE                   0x92FE
#define GL_MATRIX_STRIDE                  0x92FF
#define GL_IS_ROW_MAJOR                   0x9300
#define GL_ATOMIC_COUNTER_BUFFER_INDEX    0x9301
#define GL_BUFFER_BINDING                 0x9302
#define GL_BUFFER_DATA_SIZE               0x9303
#define GL_NUM_ACTIVE_VARIABLES           0x9304
#define GL_ACTIVE_VARIABLES               0x9305
#define GL_REFERENCED_BY_VERTEX_SHADER    0x9306
#define GL_REFERENCED_BY_TESS_CONTROL_SHADER 0x9307
#define GL_REFERENCED_BY_TESS_EVALUATION_SHADER 0x9308
#define GL_REFERENCED_BY_GEOMETRY_SHADER  0x9309
#define GL_REFERENCED_BY_FRAGMENT_SHADER  0x930A
#define GL_REFERENCED_BY_COMPUTE_SHADER   0x930B
#define GL_TOP_LEVEL_ARRAY_SIZE           0x930C
#define GL_TOP_LEVEL_ARRAY_STRIDE         0x930D
#define GL_LOCATION                       0x930E
#define GL_LOCATION_INDEX                 0x930F
#define GL_IS_PER_PATCH                   0x92E7
#define GL_SHADER_STORAGE_BUFFER          0x90D2
#define GL_SHADER_STORAGE_BUFFER_BINDING  0x90D3
#define GL_SHADER_STORAGE_BUFFER_START    0x90D4
#define GL_SHADER_STORAGE_BUFFER_SIZE     0x90D5
#define GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS 0x90D6
#define GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS 0x90D7
#define GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS 0x90D8
#define GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS 0x90D9
#define GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS 0x90DA
#define GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS 0x90DB
#define GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS 0x90DC
#define GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS 0x90DD
#define GL_MAX_SHADER_STORAGE_BLOCK_SIZE  0x90DE
#define GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT 0x90DF
#define GL_SHADER_STORAGE_BARRIER_BIT     0x00002000
#define GL_MAX_COMBINED_SHADER_OUTPUT_RESOURCES 0x8F39
#define GL_DEPTH_STENCIL_TEXTURE_MODE     0x90EA
#define GL_TEXTURE_BUFFER_OFFSET          0x919D
#define GL_TEXTURE_BUFFER_SIZE            0x919E
#define GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT 0x919F
#define GL_TEXTURE_VIEW_MIN_LEVEL         0x82DB
#define GL_TEXTURE_VIEW_NUM_LEVELS        0x82DC
#define GL_TEXTURE_VIEW_MIN_LAYER         0x82DD
#define GL_TEXTURE_VIEW_NUM_LAYERS        0x82DE
#define GL_TEXTURE_IMMUTABLE_LEVELS       0x82DF
#define GL_VERTEX_ATTRIB_BINDING          0x82D4
#define GL_VERTEX_ATTRIB_RELATIVE_OFFSET  0x82D5
#define GL_VERTEX_BINDING_DIVISOR         0x82D6
#define GL_VERTEX_BINDING_OFFSET          0x82D7
#define GL_VERTEX_BINDING_STRIDE          0x82D8
#define GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET 0x82D9
#define GL_MAX_VERTEX_ATTRIB_BINDINGS     0x82DA
#define GL_VERTEX_BINDING_BUFFER          0x8F4F
typedef void (APIENTRYP PFNGLCLEARBUFFERDATAPROC) (GLenum target, GLenum internalformat, GLenum format, GLenum type, const void *data);
typedef void (APIENTRYP PFNGLCLEARBUFFERSUBDATAPROC) (GLenum target, GLenum internalformat, GLintptr offset, GLsizeiptr size, GLenum format, GLenum type, const void *data);
typedef void (APIENTRYP PFNGLDISPATCHCOMPUTEPROC) (GLuint num_groups_x, GLuint num_groups_y, GLuint num_groups_z);
typedef void (APIENTRYP PFNGLDISPATCHCOMPUTEINDIRECTPROC) (GLintptr indirect);
typedef void (APIENTRYP PFNGLCOPYIMAGESUBDATAPROC) (GLuint srcName, GLenum srcTarget, GLint srcLevel, GLint srcX, GLint srcY, GLint srcZ, GLuint dstName, GLenum dstTarget, GLint dstLevel, GLint dstX, GLint dstY, GLint dstZ, GLsizei srcWidth, GLsizei srcHeight, GLsizei srcDepth);
typedef void (APIENTRYP PFNGLFRAMEBUFFERPARAMETERIPROC) (GLenum target, GLenum pname, GLint param);
typedef void (APIENTRYP PFNGLGETFRAMEBUFFERPARAMETERIVPROC) (GLenum target, GLenum pname, GLint *params);
typedef void (APIENTRYP PFNGLGETINTERNALFORMATI64VPROC) (GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint64 *params);
typedef void (APIENTRYP PFNGLINVALIDATETEXSUBIMAGEPROC) (GLuint texture, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth);
typedef void (APIENTRYP PFNGLINVALIDATETEXIMAGEPROC) (GLuint texture, GLint level);
typedef void (APIENTRYP PFNGLINVALIDATEBUFFERSUBDATAPROC) (GLuint buffer, GLintptr offset, GLsizeiptr length);
typedef void (APIENTRYP PFNGLINVALIDATEBUFFERDATAPROC) (GLuint buffer);
typedef void (APIENTRYP PFNGLINVALIDATEFRAMEBUFFERPROC) (GLenum target, GLsizei numAttachments, const GLenum *attachments);
typedef void (APIENTRYP PFNGLINVALIDATESUBFRAMEBUFFERPROC) (GLenum target, GLsizei numAttachments, const GLenum *attachments, GLint x, GLint y, GLsizei width, GLsizei height);
typedef void (APIENTRYP PFNGLMULTIDRAWARRAYSINDIRECTPROC) (GLenum mode, const void *indirect, GLsizei drawcount, GLsizei stride);
typedef void (APIENTRYP PFNGLMULTIDRAWELEMENTSINDIRECTPROC) (GLenum mode, GLenum type, const void *indirect, GLsizei drawcount, GLsizei stride);
typedef void (APIENTRYP PFNGLGETPROGRAMINTERFACEIVPROC) (GLuint program, GLenum programInterface, GLenum pname, GLint *params);
typedef GLuint (APIENTRYP PFNGLGETPROGRAMRESOURCEINDEXPROC) (GLuint program, GLenum programInterface, const GLchar *name);
typedef void (APIENTRYP PFNGLGETPROGRAMRESOURCENAMEPROC) (GLuint program, GLenum programInterface, GLuint index, GLsizei bufSize, GLsizei *length, GLchar *name);
typedef void (APIENTRYP PFNGLGETPROGRAMRESOURCEIVPROC) (GLuint program, GLenum programInterface, GLuint index, GLsizei propCount, const GLenum *props, GLsizei bufSize, GLsizei *length, GLint *params);
typedef GLint (APIENTRYP PFNGLGETPROGRAMRESOURCELOCATIONPROC) (GLuint program, GLenum programInterface, const GLchar *name);
typedef GLint (APIENTRYP PFNGLGETPROGRAMRESOURCELOCATIONINDEXPROC) (GLuint program, GLenum programInterface, const GLchar *name);
typedef void (APIENTRYP PFNGLSHADERSTORAGEBLOCKBINDINGPROC) (GLuint program, GLuint storageBlockIndex, GLuint storageBlockBinding);
typedef void (APIENTRYP PFNGLTEXBUFFERRANGEPROC) (GLenum target, GLenum internalformat, GLuint buffer, GLintptr offset, GLsizeiptr size);
typedef void (APIENTRYP PFNGLTEXSTORAGE2DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLboolean fixedsamplelocations);
typedef void (APIENTRYP PFNGLTEXSTORAGE3DMULTISAMPLEPROC) (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedsamplelocations);
typedef void (APIENTRYP PFNGLTEXTUREVIEWPROC) (GLuint texture, GLenum target, GLuint origtexture, GLenum internalformat, GLuint minlevel, GLuint numlevels, GLuint minlayer, GLuint numlayers);
typedef void (APIENTRYP PFNGLBINDVERTEXBUFFERPROC) (GLuint bindingindex, GLuint buffer, GLintptr offset, GLsizei stride);
typedef void (APIENTRYP PFNGLVERTEXATTRIBFORMATPROC) (GLuint attribindex, GLint size, GLenum type, GLboolean normalized, GLuint relativeoffset);
typedef void (APIENTRYP PFNGLVERTEXATTRIBIFORMATPROC) (GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
typedef void (APIENTRYP PFNGLVERTEXATTRIBLFORMATPROC) (GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
typedef void (APIENTRYP PFNGLVERTEXATTRIBBINDINGPROC) (GLuint attribindex, GLuint bindingindex);
typedef void (APIENTRYP PFNGLVERTEXBINDINGDIVISORPROC) (GLuint bindingindex, GLuint divisor);
typedef void (APIENTRYP PFNGLDEBUGMESSAGECONTROLPROC) (GLenum source, GLenum type, GLenum severity, GLsizei count, const GLuint *ids, GLboolean enabled);
typedef void (APIENTRYP PFNGLDEBUGMESSAGEINSERTPROC) (GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *buf);
typedef void (APIENTRYP PFNGLDEBUGMESSAGECALLBACKPROC) (GLDEBUGPROC callback, const void *userParam);
typedef GLuint (APIENTRYP PFNGLGETDEBUGMESSAGELOGPROC) (GLuint count, GLsizei bufSize, GLenum *sources, GLenum *types, GLuint *ids, GLenum *severities, GLsizei *lengths, GLchar *messageLog);
typedef void (APIENTRYP PFNGLPUSHDEBUGGROUPPROC) (GLenum source, GLuint id, GLsizei length, const GLchar *message);
typedef void (APIENTRYP PFNGLPOPDEBUGGROUPPROC) (void);
typedef void (APIENTRYP PFNGLOBJECTLABELPROC) (GLenum identifier, GLuint name, GLsizei length, const GLchar *label);
typedef void (APIENTRYP PFNGLGETOBJECTLABELPROC) (GLenum identifier, GLuint name, GLsizei bufSize, GLsizei *length, GLchar *label);
typedef void (APIENTRYP PFNGLOBJECTPTRLABELPROC) (const void *ptr, GLsizei length, const GLchar *label);
typedef void (APIENTRYP PFNGLGETOBJECTPTRLABELPROC) (const void *ptr, GLsizei bufSize, GLsizei *length, GLchar *label);

#define GL_MAX_VERTEX_ATTRIB_STRIDE       0x82E5
#define GL_PRIMITIVE_RESTART_FOR_PATCHES_SUPPORTED 0x8221
#define GL_TEXTURE_BUFFER_BINDING         0x8C2A
#define GL_MAP_PERSISTENT_BIT             0x0040
#define GL_MAP_COHERENT_BIT               0x0080
#define GL_DYNAMIC_STORAGE_BIT            0x0100
#define GL_CLIENT_STORAGE_BIT             0x0200
#define GL_CLIENT_MAPPED_BUFFER_BARRIER_BIT 0x00004000
#define GL_BUFFER_IMMUTABLE_STORAGE       0x821F
#define GL_BUFFER_STORAGE_FLAGS           0x8220
#define GL_CLEAR_TEXTURE                  0x9365
#define GL_LOCATION_COMPONENT             0x934A
#define GL_TRANSFORM_FEEDBACK_BUFFER_INDEX 0x934B
#define GL_TRANSFORM_FEEDBACK_BUFFER_STRIDE 0x934C
#define GL_QUERY_BUFFER                   0x9192
#define GL_QUERY_BUFFER_BARRIER_BIT       0x00008000
#define GL_QUERY_BUFFER_BINDING           0x9193
#define GL_QUERY_RESULT_NO_WAIT           0x9194
#define GL_MIRROR_CLAMP_TO_EDGE           0x8743
typedef void (APIENTRYP PFNGLBUFFERSTORAGEPROC) (GLenum target, GLsizeiptr size, const void *data, GLbitfield flags);
typedef void (APIENTRYP PFNGLCLEARTEXIMAGEPROC) (GLuint texture, GLint level, GLenum format, GLenum type, const void *data);
typedef void (APIENTRYP PFNGLCLEARTEXSUBIMAGEPROC) (GLuint texture, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const void *data);
typedef void (APIENTRYP PFNGLBINDBUFFERSBASEPROC) (GLenum target, GLuint first, GLsizei count, const GLuint *buffers);
typedef void (APIENTRYP PFNGLBINDBUFFERSRANGEPROC) (GLenum target, GLuint first, GLsizei count, const GLuint *buffers, const GLintptr *offsets, const GLsizeiptr *sizes);
typedef void (APIENTRYP PFNGLBINDTEXTURESPROC) (GLuint first, GLsizei count, const GLuint *textures);
typedef void (APIENTRYP PFNGLBINDSAMPLERSPROC) (GLuint first, GLsizei count, const GLuint *samplers);
typedef void (APIENTRYP PFNGLBINDIMAGETEXTURESPROC) (GLuint first, GLsizei count, const GLuint *textures);
typedef void (APIENTRYP PFNGLBINDVERTEXBUFFERSPROC) (GLuint first, GLsizei count, const GLuint *buffers, const GLintptr *offsets, const GLsizei *strides);

typedef uint64_t GLuint64EXT;
#define GL_UNSIGNED_INT64_ARB             0x140F
typedef GLuint64 (APIENTRYP PFNGLGETTEXTUREHANDLEARBPROC) (GLuint texture);
typedef GLuint64 (APIENTRYP PFNGLGETTEXTURESAMPLERHANDLEARBPROC) (GLuint texture, GLuint sampler);
typedef void (APIENTRYP PFNGLMAKETEXTUREHANDLERESIDENTARBPROC) (GLuint64 handle);
typedef void (APIENTRYP PFNGLMAKETEXTUREHANDLENONRESIDENTARBPROC) (GLuint64 handle);
typedef GLuint64 (APIENTRYP PFNGLGETIMAGEHANDLEARBPROC) (GLuint texture, GLint level, GLboolean layered, GLint layer, GLenum format);
typedef void (APIENTRYP PFNGLMAKEIMAGEHANDLERESIDENTARBPROC) (GLuint64 handle, GLenum access);
typedef void (APIENTRYP PFNGLMAKEIMAGEHANDLENONRESIDENTARBPROC) (GLuint64 handle);
typedef void (APIENTRYP PFNGLUNIFORMHANDLEUI64ARBPROC) (GLint location, GLuint64 value);
typedef void (APIENTRYP PFNGLUNIFORMHANDLEUI64VARBPROC) (GLint location, GLsizei count, const GLuint64 *value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMHANDLEUI64ARBPROC) (GLuint program, GLint location, GLuint64 value);
typedef void (APIENTRYP PFNGLPROGRAMUNIFORMHANDLEUI64VARBPROC) (GLuint program, GLint location, GLsizei count, const GLuint64 *values);
typedef GLboolean (APIENTRYP PFNGLISTEXTUREHANDLERESIDENTARBPROC) (GLuint64 handle);
typedef GLboolean (APIENTRYP PFNGLISIMAGEHANDLERESIDENTARBPROC) (GLuint64 handle);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL1UI64ARBPROC) (GLuint index, GLuint64EXT x);
typedef void (APIENTRYP PFNGLVERTEXATTRIBL1UI64VARBPROC) (GLuint index, const GLuint64EXT *v);
typedef void (APIENTRYP PFNGLGETVERTEXATTRIBLUI64VARBPROC) (GLuint index, GLenum pname, GLuint64EXT *params);

struct _cl_context;
struct _cl_event;
#define GL_SYNC_CL_EVENT_ARB              0x8240
#define GL_SYNC_CL_EVENT_COMPLETE_ARB     0x8241
typedef GLsync (APIENTRYP PFNGLCREATESYNCFROMCLEVENTARBPROC) (struct _cl_context *context, struct _cl_event *event, GLbitfield flags);

#define GL_COMPUTE_SHADER_BIT             0x00000020

#define GL_MAX_COMPUTE_VARIABLE_GROUP_INVOCATIONS_ARB 0x9344
#define GL_MAX_COMPUTE_FIXED_GROUP_INVOCATIONS_ARB 0x90EB
#define GL_MAX_COMPUTE_VARIABLE_GROUP_SIZE_ARB 0x9345
#define GL_MAX_COMPUTE_FIXED_GROUP_SIZE_ARB 0x91BF
typedef void (APIENTRYP PFNGLDISPATCHCOMPUTEGROUPSIZEARBPROC) (GLuint num_groups_x, GLuint num_groups_y, GLuint num_groups_z, GLuint group_size_x, GLuint group_size_y, GLuint group_size_z);

#define GL_COPY_READ_BUFFER_BINDING       0x8F36
#define GL_COPY_WRITE_BUFFER_BINDING      0x8F37

typedef void (APIENTRY  *GLDEBUGPROCARB)(GLenum source,GLenum type,GLuint id,GLenum severity,GLsizei length,const GLchar *message,const void *userParam);
#define GL_DEBUG_OUTPUT_SYNCHRONOUS_ARB   0x8242
#define GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH_ARB 0x8243
#define GL_DEBUG_CALLBACK_FUNCTION_ARB    0x8244
#define GL_DEBUG_CALLBACK_USER_PARAM_ARB  0x8245
#define GL_DEBUG_SOURCE_API_ARB           0x8246
#define GL_DEBUG_SOURCE_WINDOW_SYSTEM_ARB 0x8247
#define GL_DEBUG_SOURCE_SHADER_COMPILER_ARB 0x8248
#define GL_DEBUG_SOURCE_THIRD_PARTY_ARB   0x8249
#define GL_DEBUG_SOURCE_APPLICATION_ARB   0x824A
#define GL_DEBUG_SOURCE_OTHER_ARB         0x824B
#define GL_DEBUG_TYPE_ERROR_ARB           0x824C
#define GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB 0x824D
#define GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB 0x824E
#define GL_DEBUG_TYPE_PORTABILITY_ARB     0x824F
#define GL_DEBUG_TYPE_PERFORMANCE_ARB     0x8250
#define GL_DEBUG_TYPE_OTHER_ARB           0x8251
#define GL_MAX_DEBUG_MESSAGE_LENGTH_ARB   0x9143
#define GL_MAX_DEBUG_LOGGED_MESSAGES_ARB  0x9144
#define GL_DEBUG_LOGGED_MESSAGES_ARB      0x9145
#define GL_DEBUG_SEVERITY_HIGH_ARB        0x9146
#define GL_DEBUG_SEVERITY_MEDIUM_ARB      0x9147
#define GL_DEBUG_SEVERITY_LOW_ARB         0x9148
typedef void (APIENTRYP PFNGLDEBUGMESSAGECONTROLARBPROC) (GLenum source, GLenum type, GLenum severity, GLsizei count, const GLuint *ids, GLboolean enabled);
typedef void (APIENTRYP PFNGLDEBUGMESSAGEINSERTARBPROC) (GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *buf);
typedef void (APIENTRYP PFNGLDEBUGMESSAGECALLBACKARBPROC) (GLDEBUGPROCARB callback, const void *userParam);
typedef GLuint (APIENTRYP PFNGLGETDEBUGMESSAGELOGARBPROC) (GLuint count, GLsizei bufSize, GLenum *sources, GLenum *types, GLuint *ids, GLenum *severities, GLsizei *lengths, GLchar *messageLog);

typedef void (APIENTRYP PFNGLBLENDEQUATIONIARBPROC) (GLuint buf, GLenum mode);
typedef void (APIENTRYP PFNGLBLENDEQUATIONSEPARATEIARBPROC) (GLuint buf, GLenum modeRGB, GLenum modeAlpha);
typedef void (APIENTRYP PFNGLBLENDFUNCIARBPROC) (GLuint buf, GLenum src, GLenum dst);
typedef void (APIENTRYP PFNGLBLENDFUNCSEPARATEIARBPROC) (GLuint buf, GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);

#define GL_BLEND_COLOR                    0x8005
#define GL_BLEND_EQUATION                 0x8009

#define GL_PARAMETER_BUFFER_ARB           0x80EE
#define GL_PARAMETER_BUFFER_BINDING_ARB   0x80EF
typedef void (APIENTRYP PFNGLMULTIDRAWARRAYSINDIRECTCOUNTARBPROC) (GLenum mode, GLintptr indirect, GLintptr drawcount, GLsizei maxdrawcount, GLsizei stride);
typedef void (APIENTRYP PFNGLMULTIDRAWELEMENTSINDIRECTCOUNTARBPROC) (GLenum mode, GLenum type, GLintptr indirect, GLintptr drawcount, GLsizei maxdrawcount, GLsizei stride);

#define GL_SRGB_DECODE_ARB                0x8299

#define GL_CONTEXT_FLAG_ROBUST_ACCESS_BIT_ARB 0x00000004
#define GL_LOSE_CONTEXT_ON_RESET_ARB      0x8252
#define GL_GUILTY_CONTEXT_RESET_ARB       0x8253
#define GL_INNOCENT_CONTEXT_RESET_ARB     0x8254
#define GL_UNKNOWN_CONTEXT_RESET_ARB      0x8255
#define GL_RESET_NOTIFICATION_STRATEGY_ARB 0x8256
#define GL_NO_RESET_NOTIFICATION_ARB      0x8261
typedef GLenum (APIENTRYP PFNGLGETGRAPHICSRESETSTATUSARBPROC) (void);
typedef void (APIENTRYP PFNGLGETNTEXIMAGEARBPROC) (GLenum target, GLint level, GLenum format, GLenum type, GLsizei bufSize, void *img);
typedef void (APIENTRYP PFNGLREADNPIXELSARBPROC) (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLsizei bufSize, void *data);
typedef void (APIENTRYP PFNGLGETNCOMPRESSEDTEXIMAGEARBPROC) (GLenum target, GLint lod, GLsizei bufSize, void *img);
typedef void (APIENTRYP PFNGLGETNUNIFORMFVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLfloat *params);
typedef void (APIENTRYP PFNGLGETNUNIFORMIVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLint *params);
typedef void (APIENTRYP PFNGLGETNUNIFORMUIVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLuint *params);
typedef void (APIENTRYP PFNGLGETNUNIFORMDVARBPROC) (GLuint program, GLint location, GLsizei bufSize, GLdouble *params);

#define GL_SAMPLE_SHADING_ARB             0x8C36
#define GL_MIN_SAMPLE_SHADING_VALUE_ARB   0x8C37
typedef void (APIENTRYP PFNGLMINSAMPLESHADINGARBPROC) (GLfloat value);

#define GL_SHADER_INCLUDE_ARB             0x8DAE
#define GL_NAMED_STRING_LENGTH_ARB        0x8DE9
#define GL_NAMED_STRING_TYPE_ARB          0x8DEA
typedef void (APIENTRYP PFNGLNAMEDSTRINGARBPROC) (GLenum type, GLint namelen, const GLchar *name, GLint stringlen, const GLchar *string);
typedef void (APIENTRYP PFNGLDELETENAMEDSTRINGARBPROC) (GLint namelen, const GLchar *name);
typedef void (APIENTRYP PFNGLCOMPILESHADERINCLUDEARBPROC) (GLuint shader, GLsizei count, const GLchar *const*path, const GLint *length);
typedef GLboolean (APIENTRYP PFNGLISNAMEDSTRINGARBPROC) (GLint namelen, const GLchar *name);
typedef void (APIENTRYP PFNGLGETNAMEDSTRINGARBPROC) (GLint namelen, const GLchar *name, GLsizei bufSize, GLint *stringlen, GLchar *string);
typedef void (APIENTRYP PFNGLGETNAMEDSTRINGIVARBPROC) (GLint namelen, const GLchar *name, GLenum pname, GLint *params);

#define GL_TEXTURE_SPARSE_ARB             0x91A6
#define GL_VIRTUAL_PAGE_SIZE_INDEX_ARB    0x91A7
#define GL_MIN_SPARSE_LEVEL_ARB           0x919B
#define GL_NUM_VIRTUAL_PAGE_SIZES_ARB     0x91A8
#define GL_VIRTUAL_PAGE_SIZE_X_ARB        0x9195
#define GL_VIRTUAL_PAGE_SIZE_Y_ARB        0x9196
#define GL_VIRTUAL_PAGE_SIZE_Z_ARB        0x9197
#define GL_MAX_SPARSE_TEXTURE_SIZE_ARB    0x9198
#define GL_MAX_SPARSE_3D_TEXTURE_SIZE_ARB 0x9199
#define GL_MAX_SPARSE_ARRAY_TEXTURE_LAYERS_ARB 0x919A
#define GL_SPARSE_TEXTURE_FULL_ARRAY_CUBE_MIPMAPS_ARB 0x91A9
typedef void (APIENTRYP PFNGLTEXPAGECOMMITMENTARBPROC) (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLboolean resident);

#define GL_COMPRESSED_RGBA_BPTC_UNORM_ARB 0x8E8C
#define GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM_ARB 0x8E8D
#define GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT_ARB 0x8E8E
#define GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_ARB 0x8E8F

#define GL_TEXTURE_CUBE_MAP_ARRAY_ARB     0x9009
#define GL_TEXTURE_BINDING_CUBE_MAP_ARRAY_ARB 0x900A
#define GL_PROXY_TEXTURE_CUBE_MAP_ARRAY_ARB 0x900B
#define GL_SAMPLER_CUBE_MAP_ARRAY_ARB     0x900C
#define GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW_ARB 0x900D
#define GL_INT_SAMPLER_CUBE_MAP_ARRAY_ARB 0x900E
#define GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY_ARB 0x900F

#define GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET_ARB 0x8E5E
#define GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET_ARB 0x8E5F
#define GL_MAX_PROGRAM_TEXTURE_GATHER_COMPONENTS_ARB 0x8F9F

#define GL_TRANSFORM_FEEDBACK_PAUSED      0x8E23
#define GL_TRANSFORM_FEEDBACK_ACTIVE      0x8E24

#define GL_MAX_GEOMETRY_UNIFORM_BLOCKS    0x8A2C
#define GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS 0x8A32
#define GL_UNIFORM_BLOCK_REFERENCED_BY_GEOMETRY_SHADER 0x8A45

#define GL_COMPRESSED_RGBA_ASTC_4x4_KHR   0x93B0
#define GL_COMPRESSED_RGBA_ASTC_5x4_KHR   0x93B1
#define GL_COMPRESSED_RGBA_ASTC_5x5_KHR   0x93B2
#define GL_COMPRESSED_RGBA_ASTC_6x5_KHR   0x93B3
#define GL_COMPRESSED_RGBA_ASTC_6x6_KHR   0x93B4
#define GL_COMPRESSED_RGBA_ASTC_8x5_KHR   0x93B5
#define GL_COMPRESSED_RGBA_ASTC_8x6_KHR   0x93B6
#define GL_COMPRESSED_RGBA_ASTC_8x8_KHR   0x93B7
#define GL_COMPRESSED_RGBA_ASTC_10x5_KHR  0x93B8
#define GL_COMPRESSED_RGBA_ASTC_10x6_KHR  0x93B9
#define GL_COMPRESSED_RGBA_ASTC_10x8_KHR  0x93BA
#define GL_COMPRESSED_RGBA_ASTC_10x10_KHR 0x93BB
#define GL_COMPRESSED_RGBA_ASTC_12x10_KHR 0x93BC
#define GL_COMPRESSED_RGBA_ASTC_12x12_KHR 0x93BD
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR 0x93D0
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR 0x93D1
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR 0x93D2
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR 0x93D3
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR 0x93D4
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR 0x93D5
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR 0x93D6
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR 0x93D7
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR 0x93D8
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR 0x93D9
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR 0x93DA
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR 0x93DB
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR 0x93DC
#define GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR 0x93DD

#define GL_TEXTURE_MAX_ANISOTROPY_EXT 0x84FE
#define GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT 0x84FF
ffirequire   EGHHIIOORRRSSSSSSTTTTTTTVVVVVVWWWWWWZZZ[[[oqqqqqqsssu������ffi =glheader <openGL 5type_glenum type_uint64 constant_replace gl_mt   ]==])
Coeus:AddVFSFile('Bindings.stb_truetype', [==[LJ �Elocal Coeus = ...
local ffi = require("ffi")
local stb_truetype = Coeus.Bindings.coeus_aux

ffi.cdef([[
// stb_truetype.h - v0.8b - public domain
// authored from 2009-2013 by Sean Barrett / RAD Game Tools
// Sean Barrett is a god, BOW DOWN TO HIM

typedef unsigned char   stbtt_uint8;
typedef signed   char   stbtt_int8;
typedef unsigned short  stbtt_uint16;
typedef signed   short  stbtt_int16;
typedef unsigned int    stbtt_uint32;
typedef signed   int    stbtt_int32;

typedef char stbtt__check_size32[sizeof(stbtt_int32)==4 ? 1 : -1];
typedef char stbtt__check_size16[sizeof(stbtt_int16)==2 ? 1 : -1];

typedef struct
{
   unsigned short x0,y0,x1,y1;
   float xoff,yoff,xadvance;   
} stbtt_bakedchar;

extern int stbtt_BakeFontBitmap(const unsigned char *data, int offset,
                                float pixel_height,
                                unsigned char *pixels, int pw, int ph,
                                int first_char, int num_chars,
                                stbtt_bakedchar *chardata);

typedef struct
{
   float x0,y0,s0,t0;
   float x1,y1,s1,t1;
} stbtt_aligned_quad;

extern void stbtt_GetBakedQuad(stbtt_bakedchar *chardata, int pw, int ph,
                               int char_index,
                               float *xpos, float *ypos,
                               stbtt_aligned_quad *q,
                               int opengl_fillrule);

extern int stbtt_GetFontOffsetForIndex(const unsigned char *data, int index);

typedef struct stbtt_fontinfo
{
   void           * userdata;
   unsigned char  * data;            
   int              fontstart;       

   int numGlyphs;

   int loca,head,glyf,hhea,hmtx,kern;
   int index_map;
   int indexToLocFormat;
} stbtt_fontinfo;

extern int stbtt_InitFont(stbtt_fontinfo *info, const unsigned char *data, int offset);
int stbtt_FindGlyphIndex(const stbtt_fontinfo *info, int unicode_codepoint);
extern float stbtt_ScaleForPixelHeight(const stbtt_fontinfo *info, float pixels);
extern float stbtt_ScaleForMappingEmToPixels(const stbtt_fontinfo *info, float pixels);
extern void stbtt_GetFontVMetrics(const stbtt_fontinfo *info, int *ascent, int *descent, int *lineGap);
extern void stbtt_GetFontBoundingBox(const stbtt_fontinfo *info, int *x0, int *y0, int *x1, int *y1);
extern void stbtt_GetCodepointHMetrics(const stbtt_fontinfo *info, int codepoint, int *advanceWidth, int *leftSideBearing);
extern int  stbtt_GetCodepointKernAdvance(const stbtt_fontinfo *info, int ch1, int ch2);
extern int stbtt_GetCodepointBox(const stbtt_fontinfo *info, int codepoint, int *x0, int *y0, int *x1, int *y1);
extern void stbtt_GetGlyphHMetrics(const stbtt_fontinfo *info, int glyph_index, int *advanceWidth, int *leftSideBearing);
extern int  stbtt_GetGlyphKernAdvance(const stbtt_fontinfo *info, int glyph1, int glyph2);
extern int  stbtt_GetGlyphBox(const stbtt_fontinfo *info, int glyph_index, int *x0, int *y0, int *x1, int *y1);

enum {
  STBTT_vmove=1,
  STBTT_vline,
  STBTT_vcurve
};

typedef struct
{
  short x,y,cx,cy;
  unsigned char type,padding;
} stbtt_vertex;

extern int stbtt_IsGlyphEmpty(const stbtt_fontinfo *info, int glyph_index);
extern int stbtt_GetCodepointShape(const stbtt_fontinfo *info, int unicode_codepoint, stbtt_vertex **vertices);
extern int stbtt_GetGlyphShape(const stbtt_fontinfo *info, int glyph_index, stbtt_vertex **vertices);
extern void stbtt_FreeShape(const stbtt_fontinfo *info, stbtt_vertex *vertices);

extern void stbtt_FreeBitmap(unsigned char *bitmap, void *userdata);

extern unsigned char *stbtt_GetCodepointBitmap(const stbtt_fontinfo *info, float scale_x, float scale_y, int codepoint, int *width, int *height, int *xoff, int *yoff);
extern unsigned char *stbtt_GetCodepointBitmapSubpixel(const stbtt_fontinfo *info, float scale_x, float scale_y, float shift_x, float shift_y, int codepoint, int *width, int *height, int *xoff, int *yoff);
extern void stbtt_MakeCodepointBitmap(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, int codepoint);
extern void stbtt_MakeCodepointBitmapSubpixel(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, int codepoint);
extern void stbtt_GetCodepointBitmapBox(const stbtt_fontinfo *font, int codepoint, float scale_x, float scale_y, int *ix0, int *iy0, int *ix1, int *iy1);
extern void stbtt_GetCodepointBitmapBoxSubpixel(const stbtt_fontinfo *font, int codepoint, float scale_x, float scale_y, float shift_x, float shift_y, int *ix0, int *iy0, int *ix1, int *iy1);

extern unsigned char *stbtt_GetGlyphBitmap(const stbtt_fontinfo *info, float scale_x, float scale_y, int glyph, int *width, int *height, int *xoff, int *yoff);
extern unsigned char *stbtt_GetGlyphBitmapSubpixel(const stbtt_fontinfo *info, float scale_x, float scale_y, float shift_x, float shift_y, int glyph, int *width, int *height, int *xoff, int *yoff);
extern void stbtt_MakeGlyphBitmap(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, int glyph);
extern void stbtt_MakeGlyphBitmapSubpixel(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, int glyph);
extern void stbtt_GetGlyphBitmapBox(const stbtt_fontinfo *font, int glyph, float scale_x, float scale_y, int *ix0, int *iy0, int *ix1, int *iy1);
extern void stbtt_GetGlyphBitmapBoxSubpixel(const stbtt_fontinfo *font, int glyph, float scale_x, float scale_y,float shift_x, float shift_y, int *ix0, int *iy0, int *ix1, int *iy1);

typedef struct
{
   int w,h,stride;
   unsigned char *pixels;
} stbtt__bitmap;

extern void stbtt_Rasterize(stbtt__bitmap *result, float flatness_in_pixels, stbtt_vertex *vertices, int num_verts, float scale_x, float scale_y, float shift_x, float shift_y, int x_off, int y_off, int invert, void *userdata);

extern int stbtt_FindMatchingFont(const unsigned char *fontdata, const char *name, int flags);

enum {
	STBTT_MACSTYLE_DONTCARE     = 0,
	STBTT_MACSTYLE_BOLD         = 1,
	STBTT_MACSTYLE_ITALIC       = 2,
	STBTT_MACSTYLE_UNDERSCORE   = 4,
	STBTT_MACSTYLE_NONE         = 8   // <= not same as 0, this makes us check the bitfield is 0
};

extern int stbtt_CompareUTF8toUTF16_bigendian(const char *s1, int len1, const char *s2, int len2);
extern const char *stbtt_GetFontNameString(const stbtt_fontinfo *font, int *length, int platformID, int encodingID, int languageID, int nameID);

enum { // platformID
   STBTT_PLATFORM_ID_UNICODE   =0,
   STBTT_PLATFORM_ID_MAC       =1,
   STBTT_PLATFORM_ID_ISO       =2,
   STBTT_PLATFORM_ID_MICROSOFT =3
};

enum { // encodingID for STBTT_PLATFORM_ID_UNICODE
   STBTT_UNICODE_EID_UNICODE_1_0    =0,
   STBTT_UNICODE_EID_UNICODE_1_1    =1,
   STBTT_UNICODE_EID_ISO_10646      =2,
   STBTT_UNICODE_EID_UNICODE_2_0_BMP=3,
   STBTT_UNICODE_EID_UNICODE_2_0_FULL=4
};

enum { // encodingID for STBTT_PLATFORM_ID_MICROSOFT
   STBTT_MS_EID_SYMBOL        =0,
   STBTT_MS_EID_UNICODE_BMP   =1,
   STBTT_MS_EID_SHIFTJIS      =2,
   STBTT_MS_EID_UNICODE_FULL  =10
};

enum { // encodingID for STBTT_PLATFORM_ID_MAC; same as Script Manager codes
   STBTT_MAC_EID_ROMAN        =0,   STBTT_MAC_EID_ARABIC       =4,
   STBTT_MAC_EID_JAPANESE     =1,   STBTT_MAC_EID_HEBREW       =5,
   STBTT_MAC_EID_CHINESE_TRAD =2,   STBTT_MAC_EID_GREEK        =6,
   STBTT_MAC_EID_KOREAN       =3,   STBTT_MAC_EID_RUSSIAN      =7
};

enum { // languageID for STBTT_PLATFORM_ID_MICROSOFT; same as LCID...
       // problematic because there are e.g. 16 english LCIDs and 16 arabic LCIDs
   STBTT_MS_LANG_ENGLISH     =0x0409,   STBTT_MS_LANG_ITALIAN     =0x0410,
   STBTT_MS_LANG_CHINESE     =0x0804,   STBTT_MS_LANG_JAPANESE    =0x0411,
   STBTT_MS_LANG_DUTCH       =0x0413,   STBTT_MS_LANG_KOREAN      =0x0412,
   STBTT_MS_LANG_FRENCH      =0x040c,   STBTT_MS_LANG_RUSSIAN     =0x0419,
   STBTT_MS_LANG_GERMAN      =0x0407,   STBTT_MS_LANG_SPANISH     =0x0409,
   STBTT_MS_LANG_HEBREW      =0x040d,   STBTT_MS_LANG_SWEDISH     =0x041D
};

enum { // languageID for STBTT_PLATFORM_ID_MAC
   STBTT_MAC_LANG_ENGLISH      =0 ,   STBTT_MAC_LANG_JAPANESE     =11,
   STBTT_MAC_LANG_ARABIC       =12,   STBTT_MAC_LANG_KOREAN       =23,
   STBTT_MAC_LANG_DUTCH        =4 ,   STBTT_MAC_LANG_RUSSIAN      =32,
   STBTT_MAC_LANG_FRENCH       =1 ,   STBTT_MAC_LANG_SPANISH      =6 ,
   STBTT_MAC_LANG_GERMAN       =2 ,   STBTT_MAC_LANG_SWEDISH      =5 ,
   STBTT_MAC_LANG_HEBREW       =10,   STBTT_MAC_LANG_CHINESE_SIMPLIFIED =33,
   STBTT_MAC_LANG_ITALIAN      =3 ,   STBTT_MAC_LANG_CHINESE_TRAD =19
};
]])

return stb_truetype�C   
( �C  4  % >7 77% >H �C// stb_truetype.h - v0.8b - public domain
// authored from 2009-2013 by Sean Barrett / RAD Game Tools
// Sean Barrett is a god, BOW DOWN TO HIM

typedef unsigned char   stbtt_uint8;
typedef signed   char   stbtt_int8;
typedef unsigned short  stbtt_uint16;
typedef signed   short  stbtt_int16;
typedef unsigned int    stbtt_uint32;
typedef signed   int    stbtt_int32;

typedef char stbtt__check_size32[sizeof(stbtt_int32)==4 ? 1 : -1];
typedef char stbtt__check_size16[sizeof(stbtt_int16)==2 ? 1 : -1];

typedef struct
{
   unsigned short x0,y0,x1,y1;
   float xoff,yoff,xadvance;   
} stbtt_bakedchar;

extern int stbtt_BakeFontBitmap(const unsigned char *data, int offset,
                                float pixel_height,
                                unsigned char *pixels, int pw, int ph,
                                int first_char, int num_chars,
                                stbtt_bakedchar *chardata);

typedef struct
{
   float x0,y0,s0,t0;
   float x1,y1,s1,t1;
} stbtt_aligned_quad;

extern void stbtt_GetBakedQuad(stbtt_bakedchar *chardata, int pw, int ph,
                               int char_index,
                               float *xpos, float *ypos,
                               stbtt_aligned_quad *q,
                               int opengl_fillrule);

extern int stbtt_GetFontOffsetForIndex(const unsigned char *data, int index);

typedef struct stbtt_fontinfo
{
   void           * userdata;
   unsigned char  * data;            
   int              fontstart;       

   int numGlyphs;

   int loca,head,glyf,hhea,hmtx,kern;
   int index_map;
   int indexToLocFormat;
} stbtt_fontinfo;

extern int stbtt_InitFont(stbtt_fontinfo *info, const unsigned char *data, int offset);
int stbtt_FindGlyphIndex(const stbtt_fontinfo *info, int unicode_codepoint);
extern float stbtt_ScaleForPixelHeight(const stbtt_fontinfo *info, float pixels);
extern float stbtt_ScaleForMappingEmToPixels(const stbtt_fontinfo *info, float pixels);
extern void stbtt_GetFontVMetrics(const stbtt_fontinfo *info, int *ascent, int *descent, int *lineGap);
extern void stbtt_GetFontBoundingBox(const stbtt_fontinfo *info, int *x0, int *y0, int *x1, int *y1);
extern void stbtt_GetCodepointHMetrics(const stbtt_fontinfo *info, int codepoint, int *advanceWidth, int *leftSideBearing);
extern int  stbtt_GetCodepointKernAdvance(const stbtt_fontinfo *info, int ch1, int ch2);
extern int stbtt_GetCodepointBox(const stbtt_fontinfo *info, int codepoint, int *x0, int *y0, int *x1, int *y1);
extern void stbtt_GetGlyphHMetrics(const stbtt_fontinfo *info, int glyph_index, int *advanceWidth, int *leftSideBearing);
extern int  stbtt_GetGlyphKernAdvance(const stbtt_fontinfo *info, int glyph1, int glyph2);
extern int  stbtt_GetGlyphBox(const stbtt_fontinfo *info, int glyph_index, int *x0, int *y0, int *x1, int *y1);

enum {
  STBTT_vmove=1,
  STBTT_vline,
  STBTT_vcurve
};

typedef struct
{
  short x,y,cx,cy;
  unsigned char type,padding;
} stbtt_vertex;

extern int stbtt_IsGlyphEmpty(const stbtt_fontinfo *info, int glyph_index);
extern int stbtt_GetCodepointShape(const stbtt_fontinfo *info, int unicode_codepoint, stbtt_vertex **vertices);
extern int stbtt_GetGlyphShape(const stbtt_fontinfo *info, int glyph_index, stbtt_vertex **vertices);
extern void stbtt_FreeShape(const stbtt_fontinfo *info, stbtt_vertex *vertices);

extern void stbtt_FreeBitmap(unsigned char *bitmap, void *userdata);

extern unsigned char *stbtt_GetCodepointBitmap(const stbtt_fontinfo *info, float scale_x, float scale_y, int codepoint, int *width, int *height, int *xoff, int *yoff);
extern unsigned char *stbtt_GetCodepointBitmapSubpixel(const stbtt_fontinfo *info, float scale_x, float scale_y, float shift_x, float shift_y, int codepoint, int *width, int *height, int *xoff, int *yoff);
extern void stbtt_MakeCodepointBitmap(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, int codepoint);
extern void stbtt_MakeCodepointBitmapSubpixel(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, int codepoint);
extern void stbtt_GetCodepointBitmapBox(const stbtt_fontinfo *font, int codepoint, float scale_x, float scale_y, int *ix0, int *iy0, int *ix1, int *iy1);
extern void stbtt_GetCodepointBitmapBoxSubpixel(const stbtt_fontinfo *font, int codepoint, float scale_x, float scale_y, float shift_x, float shift_y, int *ix0, int *iy0, int *ix1, int *iy1);

extern unsigned char *stbtt_GetGlyphBitmap(const stbtt_fontinfo *info, float scale_x, float scale_y, int glyph, int *width, int *height, int *xoff, int *yoff);
extern unsigned char *stbtt_GetGlyphBitmapSubpixel(const stbtt_fontinfo *info, float scale_x, float scale_y, float shift_x, float shift_y, int glyph, int *width, int *height, int *xoff, int *yoff);
extern void stbtt_MakeGlyphBitmap(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, int glyph);
extern void stbtt_MakeGlyphBitmapSubpixel(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, int glyph);
extern void stbtt_GetGlyphBitmapBox(const stbtt_fontinfo *font, int glyph, float scale_x, float scale_y, int *ix0, int *iy0, int *ix1, int *iy1);
extern void stbtt_GetGlyphBitmapBoxSubpixel(const stbtt_fontinfo *font, int glyph, float scale_x, float scale_y,float shift_x, float shift_y, int *ix0, int *iy0, int *ix1, int *iy1);

typedef struct
{
   int w,h,stride;
   unsigned char *pixels;
} stbtt__bitmap;

extern void stbtt_Rasterize(stbtt__bitmap *result, float flatness_in_pixels, stbtt_vertex *vertices, int num_verts, float scale_x, float scale_y, float shift_x, float shift_y, int x_off, int y_off, int invert, void *userdata);

extern int stbtt_FindMatchingFont(const unsigned char *fontdata, const char *name, int flags);

enum {
	STBTT_MACSTYLE_DONTCARE     = 0,
	STBTT_MACSTYLE_BOLD         = 1,
	STBTT_MACSTYLE_ITALIC       = 2,
	STBTT_MACSTYLE_UNDERSCORE   = 4,
	STBTT_MACSTYLE_NONE         = 8   // <= not same as 0, this makes us check the bitfield is 0
};

extern int stbtt_CompareUTF8toUTF16_bigendian(const char *s1, int len1, const char *s2, int len2);
extern const char *stbtt_GetFontNameString(const stbtt_fontinfo *font, int *length, int platformID, int encodingID, int languageID, int nameID);

enum { // platformID
   STBTT_PLATFORM_ID_UNICODE   =0,
   STBTT_PLATFORM_ID_MAC       =1,
   STBTT_PLATFORM_ID_ISO       =2,
   STBTT_PLATFORM_ID_MICROSOFT =3
};

enum { // encodingID for STBTT_PLATFORM_ID_UNICODE
   STBTT_UNICODE_EID_UNICODE_1_0    =0,
   STBTT_UNICODE_EID_UNICODE_1_1    =1,
   STBTT_UNICODE_EID_ISO_10646      =2,
   STBTT_UNICODE_EID_UNICODE_2_0_BMP=3,
   STBTT_UNICODE_EID_UNICODE_2_0_FULL=4
};

enum { // encodingID for STBTT_PLATFORM_ID_MICROSOFT
   STBTT_MS_EID_SYMBOL        =0,
   STBTT_MS_EID_UNICODE_BMP   =1,
   STBTT_MS_EID_SHIFTJIS      =2,
   STBTT_MS_EID_UNICODE_FULL  =10
};

enum { // encodingID for STBTT_PLATFORM_ID_MAC; same as Script Manager codes
   STBTT_MAC_EID_ROMAN        =0,   STBTT_MAC_EID_ARABIC       =4,
   STBTT_MAC_EID_JAPANESE     =1,   STBTT_MAC_EID_HEBREW       =5,
   STBTT_MAC_EID_CHINESE_TRAD =2,   STBTT_MAC_EID_GREEK        =6,
   STBTT_MAC_EID_KOREAN       =3,   STBTT_MAC_EID_RUSSIAN      =7
};

enum { // languageID for STBTT_PLATFORM_ID_MICROSOFT; same as LCID...
       // problematic because there are e.g. 16 english LCIDs and 16 arabic LCIDs
   STBTT_MS_LANG_ENGLISH     =0x0409,   STBTT_MS_LANG_ITALIAN     =0x0410,
   STBTT_MS_LANG_CHINESE     =0x0804,   STBTT_MS_LANG_JAPANESE    =0x0411,
   STBTT_MS_LANG_DUTCH       =0x0413,   STBTT_MS_LANG_KOREAN      =0x0412,
   STBTT_MS_LANG_FRENCH      =0x040c,   STBTT_MS_LANG_RUSSIAN     =0x0419,
   STBTT_MS_LANG_GERMAN      =0x0407,   STBTT_MS_LANG_SPANISH     =0x0409,
   STBTT_MS_LANG_HEBREW      =0x040d,   STBTT_MS_LANG_SWEDISH     =0x041D
};

enum { // languageID for STBTT_PLATFORM_ID_MAC
   STBTT_MAC_LANG_ENGLISH      =0 ,   STBTT_MAC_LANG_JAPANESE     =11,
   STBTT_MAC_LANG_ARABIC       =12,   STBTT_MAC_LANG_KOREAN       =23,
   STBTT_MAC_LANG_DUTCH        =4 ,   STBTT_MAC_LANG_RUSSIAN      =32,
   STBTT_MAC_LANG_FRENCH       =1 ,   STBTT_MAC_LANG_SPANISH      =6 ,
   STBTT_MAC_LANG_GERMAN       =2 ,   STBTT_MAC_LANG_SWEDISH      =5 ,
   STBTT_MAC_LANG_HEBREW       =10,   STBTT_MAC_LANG_CHINESE_SIMPLIFIED =33,
   STBTT_MAC_LANG_ITALIAN      =3 ,   STBTT_MAC_LANG_CHINESE_TRAD =19
};
	cdefcoeus_auxBindingsffirequire��Coeus 	ffi stb_truetype   ]==])
Coeus:AddVFSFile('Bindings.stdio_', [==[LJ �local Coeus = (...)
local ffi = require("ffi")
local C = ffi.C

ffi.cdef([[
struct _iobuf {
	char *_ptr;
	int   _cnt;
	char *_base;
	int   _flag;
	int   _file;
	int   _charbuf;
	int   _bufsiz;
	char *_tmpfname;
};
typedef struct _iobuf FILE;

enum {
	SEEK_CUR = 1,
	SEEK_END = 2,
	SEEK_SET = 0
};

FILE* fopen(const char* filename, const char* mode);
int fclose(FILE* stream);
size_t fread(void* ptr, size_t size, size_t count, FILE* stream);
int fseek(FILE* stream, long int offset, int origin);
long int ftell(FILE* stream);

]])

return C�   	  C  4  % >77% >H �struct _iobuf {
	char *_ptr;
	int   _cnt;
	char *_base;
	int   _flag;
	int   _file;
	int   _charbuf;
	int   _bufsiz;
	char *_tmpfname;
};
typedef struct _iobuf FILE;

enum {
	SEEK_CUR = 1,
	SEEK_END = 2,
	SEEK_SET = 0
};

FILE* fopen(const char* filename, const char* mode);
int fclose(FILE* stream);
size_t fread(void* ptr, size_t size, size_t count, FILE* stream);
int fseek(FILE* stream, long int offset, int origin);
long int ftell(FILE* stream);

	cdefCffirequire Coeus ffi C   ]==])
Coeus:AddVFSFile('Bindings.TinyCThread', [==[LJ �local Coeus = ...
local ffi = require("ffi")
local tct = Coeus.Bindings.coeus_aux

--Platform-specific typedefs
if (ffi.os == "Windows") then
	Coeus:Load("Bindings.Win32_")
	ffi.cdef([[
		typedef int time_t;
		typedef int clock_t;
		typedef int clockid_t;

		typedef struct _tthread_timespec {
			time_t tv_sec;
			long   tv_nsec;
		};

		typedef struct timespec {
			time_t tv_sec;
			long tv_nsec;
		};

		typedef int _tthread_clockid_t;
		int _tthread_clock_gettime(clockid_t clk_id, struct timespec *ts);

		typedef struct {
		  CRITICAL_SECTION mHandle;   /* Critical section handle */
		  int mAlreadyLocked;         /* TRUE if the mutex is already locked */
		  int mRecursive;             /* TRUE if the mutex is recursive */
		} mtx_t;

		typedef struct {
		  HANDLE mEvents[2];                  /* Signal and broadcast event HANDLEs. */
		  unsigned int mWaitersCount;         /* Count of the number of waiters. */
		  CRITICAL_SECTION mWaitersCountLock; /* Serialize access to mWaitersCount. */
		} cnd_t;

		typedef HANDLE thrd_t;
		typedef DWORD tss_t;
	]])
else
	ffi.cdef([[
		typedef pthread_mutex_t mtx_t;
		typedef pthread_cond_t cnd_t;
		typedef pthread_t thrd_t;
		typedef pthread_key_t tss_t;
	]])
end

ffi.cdef([[
/*
Copyright (c) 2012 Marcus Geelnard

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
*/

/** TinyCThread version (major number). */
enum {
	TINYCTHREAD_VERSION_MAJOR = 1,
	TINYCTHREAD_VERSION_MINOR = 1,
	TINYCTHREAD_VERSION = 101,

	TSS_DTRO_ITERATIONS = 0,

	thrd_error = 0,
	thrd_success = 1,
	thrd_timeout = 2,
	thrd_busy = 3,
	thrd_nomem = 4,

	mtx_plain = 1,
	mtx_timed = 2,
	mtx_try = 4,
	mtx_recursive = 8
};

int mtx_init(mtx_t *mtx, int type);
void mtx_destroy(mtx_t *mtx);
int mtx_lock(mtx_t *mtx);
// NOT IMPLEMENTED AS OF 1.1
// int mtx_timedlock(mtx_t *mtx, const struct timespec *ts);
int mtx_trylock(mtx_t *mtx);
int mtx_unlock(mtx_t *mtx);

int cnd_init(cnd_t *cond);
void cnd_destroy(cnd_t *cond);
int cnd_signal(cnd_t *cond);
int cnd_broadcast(cnd_t *cond);
int cnd_wait(cnd_t *cond, mtx_t *mtx);
int cnd_timedwait(cnd_t *cond, mtx_t *mtx, const struct timespec *ts);


typedef int (*thrd_start_t)(void *arg);


int thrd_create(thrd_t *thr, thrd_start_t func, void *arg);
thrd_t thrd_current(void);
// NOT IMPLEMENTED AS OF 1.1
//int thrd_detach(thrd_t thr);
int thrd_equal(thrd_t thr0, thrd_t thr1);
void thrd_exit(int res);
int thrd_join(thrd_t thr, int *res);
int thrd_sleep(const struct timespec *time_point, struct timespec *remaining);
void thrd_yield(void);

typedef void (*tss_dtor_t)(void *val);
int tss_create(tss_t *key, tss_dtor_t dtor);
void tss_delete(tss_t key);
void *tss_get(tss_t key);
int tss_set(tss_t key, void *val);
]])

return tct�   - �C  4  % >7 77 T�  7 % >7%	 >T�7%
 >7% >H �/*
Copyright (c) 2012 Marcus Geelnard

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
*/

/** TinyCThread version (major number). */
enum {
	TINYCTHREAD_VERSION_MAJOR = 1,
	TINYCTHREAD_VERSION_MINOR = 1,
	TINYCTHREAD_VERSION = 101,

	TSS_DTRO_ITERATIONS = 0,

	thrd_error = 0,
	thrd_success = 1,
	thrd_timeout = 2,
	thrd_busy = 3,
	thrd_nomem = 4,

	mtx_plain = 1,
	mtx_timed = 2,
	mtx_try = 4,
	mtx_recursive = 8
};

int mtx_init(mtx_t *mtx, int type);
void mtx_destroy(mtx_t *mtx);
int mtx_lock(mtx_t *mtx);
// NOT IMPLEMENTED AS OF 1.1
// int mtx_timedlock(mtx_t *mtx, const struct timespec *ts);
int mtx_trylock(mtx_t *mtx);
int mtx_unlock(mtx_t *mtx);

int cnd_init(cnd_t *cond);
void cnd_destroy(cnd_t *cond);
int cnd_signal(cnd_t *cond);
int cnd_broadcast(cnd_t *cond);
int cnd_wait(cnd_t *cond, mtx_t *mtx);
int cnd_timedwait(cnd_t *cond, mtx_t *mtx, const struct timespec *ts);


typedef int (*thrd_start_t)(void *arg);


int thrd_create(thrd_t *thr, thrd_start_t func, void *arg);
thrd_t thrd_current(void);
// NOT IMPLEMENTED AS OF 1.1
//int thrd_detach(thrd_t thr);
int thrd_equal(thrd_t thr0, thrd_t thr1);
void thrd_exit(int res);
int thrd_join(thrd_t thr, int *res);
int thrd_sleep(const struct timespec *time_point, struct timespec *remaining);
void thrd_yield(void);

typedef void (*tss_dtor_t)(void *val);
int tss_create(tss_t *key, tss_dtor_t dtor);
void tss_delete(tss_t key);
void *tss_get(tss_t key);
int tss_set(tss_t key, void *val);
�		typedef pthread_mutex_t mtx_t;
		typedef pthread_cond_t cnd_t;
		typedef pthread_t thrd_t;
		typedef pthread_key_t tss_t;
	�		typedef int time_t;
		typedef int clock_t;
		typedef int clockid_t;

		typedef struct _tthread_timespec {
			time_t tv_sec;
			long   tv_nsec;
		};

		typedef struct timespec {
			time_t tv_sec;
			long tv_nsec;
		};

		typedef int _tthread_clockid_t;
		int _tthread_clock_gettime(clockid_t clk_id, struct timespec *ts);

		typedef struct {
		  CRITICAL_SECTION mHandle;   /* Critical section handle */
		  int mAlreadyLocked;         /* TRUE if the mutex is already locked */
		  int mRecursive;             /* TRUE if the mutex is recursive */
		} mtx_t;

		typedef struct {
		  HANDLE mEvents[2];                  /* Signal and broadcast event HANDLEs. */
		  unsigned int mWaitersCount;         /* Count of the number of waiters. */
		  CRITICAL_SECTION mWaitersCountLock; /* Serialize access to mWaitersCount. */
		} cnd_t;

		typedef HANDLE thrd_t;
		typedef DWORD tss_t;
		cdefBindings.Win32_	LoadWindowsoscoeus_auxBindingsffirequire((*/*2�2�Coeus ffi tct   ]==])
Coeus:AddVFSFile('Bindings.Win32_', [==[LJ �--[[
Contains just the Win32 bindings Coeus needs
]]

local ffi = require("ffi")
if (ffi.os ~= "Windows") then
	return
end

ffi.cdef([[
	typedef uint16_t WORD;
	typedef long LONG;
	typedef unsigned long DWORD;
	typedef unsigned long ULONG_PTR;
	typedef void *HANDLE;

	typedef struct _LIST_ENTRY {
	   struct _LIST_ENTRY *Flink;
	   struct _LIST_ENTRY *Blink;
	} LIST_ENTRY, *PLIST_ENTRY;

	typedef struct _RTL_CRITICAL_SECTION {
	    struct _RTL_CRITICAL_SECTION *DebugInfo;

	    //
	    //  The following three fields control entering and exiting the critical
	    //  section for the resource
	    //

	    LONG LockCount;
	    LONG RecursionCount;
	    HANDLE OwningThread;        // from the thread's ClientId->UniqueThread
	    HANDLE LockSemaphore;
	    ULONG_PTR SpinCount;        // force size on 64-bit systems when packed
	} RTL_CRITICAL_SECTION, *PRTL_CRITICAL_SECTION;

	typedef struct _RTL_CRITICAL_SECTION_DEBUG {
	    WORD   Type;
	    WORD   CreatorBackTraceIndex;
	    struct _RTL_CRITICAL_SECTION *CriticalSection;
	    LIST_ENTRY ProcessLocksList;
	    DWORD EntryCount;
	    DWORD ContentionCount;
	    DWORD Flags;
	    WORD   CreatorBackTraceIndexHigh;
	    WORD   SpareWORD  ;
	} RTL_CRITICAL_SECTION_DEBUG, *PRTL_CRITICAL_SECTION_DEBUG, RTL_RESOURCE_DEBUG, *PRTL_RESOURCE_DEBUG;

	typedef struct _RTL_CRITICAL_SECTION CRITICAL_SECTION;
	typedef unsigned int MMRESULT;

	void Sleep(DWORD milliseconds);
	MMRESULT timeBeginPeriod(unsigned int uperiod);
]])

return ffi.C�    84   % > 7  T�G  7 % >7 H C�
	typedef uint16_t WORD;
	typedef long LONG;
	typedef unsigned long DWORD;
	typedef unsigned long ULONG_PTR;
	typedef void *HANDLE;

	typedef struct _LIST_ENTRY {
	   struct _LIST_ENTRY *Flink;
	   struct _LIST_ENTRY *Blink;
	} LIST_ENTRY, *PLIST_ENTRY;

	typedef struct _RTL_CRITICAL_SECTION {
	    struct _RTL_CRITICAL_SECTION *DebugInfo;

	    //
	    //  The following three fields control entering and exiting the critical
	    //  section for the resource
	    //

	    LONG LockCount;
	    LONG RecursionCount;
	    HANDLE OwningThread;        // from the thread's ClientId->UniqueThread
	    HANDLE LockSemaphore;
	    ULONG_PTR SpinCount;        // force size on 64-bit systems when packed
	} RTL_CRITICAL_SECTION, *PRTL_CRITICAL_SECTION;

	typedef struct _RTL_CRITICAL_SECTION_DEBUG {
	    WORD   Type;
	    WORD   CreatorBackTraceIndex;
	    struct _RTL_CRITICAL_SECTION *CriticalSection;
	    LIST_ENTRY ProcessLocksList;
	    DWORD EntryCount;
	    DWORD ContentionCount;
	    DWORD Flags;
	    WORD   CreatorBackTraceIndexHigh;
	    WORD   SpareWORD  ;
	} RTL_CRITICAL_SECTION_DEBUG, *PRTL_CRITICAL_SECTION_DEBUG, RTL_RESOURCE_DEBUG, *PRTL_RESOURCE_DEBUG;

	typedef struct _RTL_CRITICAL_SECTION CRITICAL_SECTION;
	typedef unsigned int MMRESULT;

	void Sleep(DWORD milliseconds);
	MMRESULT timeBeginPeriod(unsigned int uperiod);
	cdefWindowsosffirequire
6
88ffi 	  ]==])
Coeus:AddVFSFile('Bindings.zlib', [==[LJ �local Coeus = ...

local ffi = require("ffi")
local z_lib

if (ffi.os == "Windows") then
	z_lib = ffi.load("lib/win32/zlib1.dll")
else
	z_lib = ffi.load("z")
end

ffi.cdef([[
	unsigned long compressBound(unsigned long sourceLen);
	int compress2(uint8_t *dest, unsigned long *destLen, const uint8_t *source, unsigned long sourceLen, int level);
	int uncompress(uint8_t *dest, unsigned long *destLen, const uint8_t *source, unsigned long sourceLen);
]])

return z_lib�  	 , C  4  % >)  7 T�7% > T�7% > 7% >H �	unsigned long compressBound(unsigned long sourceLen);
	int compress2(uint8_t *dest, unsigned long *destLen, const uint8_t *source, unsigned long sourceLen, int level);
	int uncompress(uint8_t *dest, unsigned long *destLen, const uint8_t *source, unsigned long sourceLen);
	cdefzlib/win32/zlib1.dll	loadWindowsosffirequire				Coeus ffi z_lib   ]==])
Coeus:AddVFSFile('Entity.BaseComponent', [==[LJ �local Coeus 	= (...)
local OOP		= Coeus.Utility.OOP 
local Table		= Coeus.Utility.Table

local BaseComponent = OOP:Class() {
	entity = false,
}

function BaseComponent:_new()

end

function BaseComponent:SetEntity(entity)
	if self.entity then
		self.entity:RemoveComponent(self)
	end
	entity:AddComponent(self)
end
function BaseComponent:GetEntity()
	return self.entity
end

function BaseComponent:Update(dt)

end

function BaseComponent:Render()

end

return BaseComponent    		G  self   �   7    T�7   7  > 7  >G  AddComponentRemoveComponententityself  entity   #   
7  H entityself       G  self  dt       	G  self   �   = C  7  77  7 7>3 >1 :1 :1
 :	1 :1 :0  �H  Render Update GetEntity SetEntity 	_new entity
Class
TableOOPUtility	Coeus OOP Table BaseComponent   ]==])
Coeus:AddVFSFile('Entity.Entity', [==[LJ � local Coeus 		= (...)
local oop 			= Coeus.Utility.OOP 
local Table 		= Coeus.Utility.Table

local Matrix4 		= Coeus.Math.Matrix4
local Vector3 		= Coeus.Math.Vector3
local Quaternion 	= Coeus.Math.Quaternion

local Event 		= Coeus.Utility.Event

local Entity = oop:Class() {
	scene = false,

	parent 		= false,
	children 	= {},

	local_transform 	= Matrix4:New(),
	render_transform 	= Matrix4:New(),
	dirty_transform 	= false,

	scale 	 = Vector3:New(1, 1, 1),
	position = Vector3:New(),
	rotation = Quaternion:New(),

	components = {},

	name = "Entity",

}

function Entity:_new()

end

function Entity:SetName(name)
	self.name = name
end
function Entity:GetName()
	return self.name
end


function Entity:SetScene(scene)
	self.scene = scene
	for i,v in pairs(self.children) do
		v:SetScene(scene)
	end
end


function Entity:AddChild(child)
	for i,v in pairs(self.children) do
		if v == child then return end
	end
	self.children[#self.children+1] = child
	if child.parent then
		child.parent:RemoveChild(child)
	end
	child.parent = self
	child:SetScene(self.scene)
end

function Entity:RemoveChild(child)
	for i,v in pairs(self.children) do
		if v == child then
			v.parent = false
			table.remove(self.children, i)
			return
		end
	end
end

function Entity:SetParent(parent)
	parent:AddChild(self)
end

function Entity:FindFirstChild(name, recursive)
	for i,v in pairs(self.children) do
		if v.name == name then
			return v
		end
		if recursive then
			v:FindFirstChild(name, true)
		end
	end
	return nil
end

function Entity:GetChildren()
	return Table.Copy(self.children)
end


function Entity:AddComponent(component)
	if self.components[component:GetClass()] then return end
	self.components[component:GetClass()] = component
	component.entity = self
end

function Entity:RemoveComponent(component)
	local comp = self.components[component:GetClass()]
	if comp then
		comp.entity = false
		self.components[component:GetClass()] = nil
	end
end

function Entity:GetComponent(component_type)
	return self.components[component_type]
end


function Entity:SetLocalTransform(matrix)
	self.local_transform = matrix:Copy()
	self:DirtyTransform()
end
function Entity:GetLocalTransform()
	self:BuildTransform()
	return self.local_transform:Copy()
end

function Entity:GetRenderTransform()
	self:BuildTransform()
	return self.render_transform:Copy()
end


function Entity:SetScale(x, y, z)
	if type(x) ~= "number" then
		self:SetScale(x.x, x.y, x.z)
		return
	end
	self.scale.x = x
	self.scale.y = y or x
	self.scale.z = z or x
	self:DirtyTransform()
end
function Entity:GetScale()
	return self.scale:Copy()
end

function Entity:SetPosition(x, y, z)
	if type(x) ~= "number" then
		self:SetPosition(x.x, x.y, x.z)
		return
	end
	self.position.x = x
	self.position.y = y
	self.position.z = z
	self:DirtyTransform()
end
function Entity:GetPosition()
	return self.position:Copy()
end

function Entity:SetRotation(x, y, z, w)
	if type(x) ~= "number" then
		self:SetRotation(x.x, x.y, x.z, x.w)
		return
	end
	self.rotation.x = x
	self.rotation.y = y
	self.rotation.z = z
	self.rotation.w = w
	self:DirtyTransform()
end
function Entity:GetRotation()
	return self.rotation:Copy()
end


function Entity:DirtyTransform()
	self.dirty_transform = true

	for i,v in pairs(self.children) do
		v:DirtyTransform()
	end
end

function Entity:BuildTransform()
	if not self.dirty_transform then return end
	self.dirty_transform = false

	self.local_transform = Matrix4.GetScale(self.scale) * 
						   Matrix4.GetTranslation(self.position) *
						   self.rotation:ToRotationMatrix() 
						   
	self.render_transform = self.local_transform-- * self.render_transform
end


function Entity:Update(dt)
	for i,v in pairs(self.components) do
		v:Update(dt)
	end
	for i,v in pairs(self.children) do
		v:Update(dt)
	end
end

function Entity:Render()
	self:BuildTransform()
	for i,v in pairs(self.components) do
		v:Render()
	end
	for i,v in pairs(self.children) do 
		v:Render()
	end
end

return Entity    	G  self   (   #:  G  	nameself  name   !   
&7  H 	nameself   � 
  -+:  4 7 >D� 7	 >BN�G  SetScenechildren
pairs
sceneself  scene    i v   �  =3
4  7 >D� T�G  BN�7 7   97  T�7 7 >:  77 >G  
sceneSetSceneRemoveChildparentchildren
pairs				
self  child    i v   � 
  2?4  7 >D
� T�) :4 77 	 >G  BN�G  remove
tableparentchildren
pairsself  child    i 
v  
 =   I 7   >G  AddChildself  parent   �   ?M
4  7 >D�7 T�H   T�	 7
 ) >BN�)  H FindFirstChild	namechildren
pairs		self  name  recursive    i v   <  Y+  7 7 @ �children	CopyTable self   �   #^7   7>6  T�G  7   7>9: G  entityGetClasscomponentsself  component   �   +d7   7>6  T�) :7   7>)  9G  entityGetClasscomponentsself  component  comp  =   l7  6H componentsself  component_type   g   q 7>:    7 >G  DirtyTransform	Copylocal_transformself  	matrix  	 Y   u  7  >7  7@ 	Copylocal_transformBuildTransformself   Z   z  7  >7  7@ 	Copyrender_transformBuildTransformself   � 	  0�	4   > T�  7 777>G  7 :7  T� :7  T� :  7 >G  DirtyTransform
scalezyxSetScalenumber	type	self  x  y  z   2   �7   7@ 	Copy
scaleself   � 	  *�	4   > T�  7 777>G  7 :7 :7 :  7 >G  DirtyTransformpositionzyxSetPositionnumber	type	self  x  y  z   5   �7   7@ 	Copypositionself   �  	 1�
4   > T�  7 777	7
>G  7 :7 :7 :7 :  7 >G  DirtyTransformrotationwzyxSetRotationnumber	type			
self  x  y  z  w   5   �7   7@ 	Copyrotationself   �   %�) :  4 7 >D� 7>BN�G  DirtyTransformchildren
pairsdirty_transformself    i v   � 	 (�	7    T�G  ) :  +  77 >+  77 > 7  7> : 7 : G  �render_transformToRotationMatrixrotationpositionGetTranslation
scaleGetScalelocal_transformdirty_transform	Matrix4 self   � 
  D�4  7 >D� 7	 >BN�4  7 >D� 7	 >BN�G  childrenUpdatecomponents
pairsself  dt    i v  	  i v   �   @�  7  >4 7 >D� 7>BN�4 7 >D� 7>BN�G  childrenRendercomponents
pairsBuildTransformself    i v    i v   �  D a� �C  7  77  77 77 77 77  7 7>3	 2	  :	

 7	>	:	
 7	>	:	
 7	' ' ' >	:	
 7	>	:	
 7	>	:	2	  :	>1 :1 :1 :1 :1 :1 :1 :1! : 1# :"1% :$1' :&1) :(1+ :*1- :,1/ :.11 :013 :215 :417 :619 :81; ::1= :<1? :>1A :@1C :B0  �H  Render Update BuildTransform DirtyTransform GetRotation SetRotation GetPosition SetPosition GetScale SetScale GetRenderTransform GetLocalTransform SetLocalTransform GetComponent RemoveComponent AddComponent GetChildren FindFirstChild SetParent RemoveChild AddChild SetScene GetName SetName 	_newcomponentsrotationposition
scalerender_transformlocal_transformNewchildren 	nameEntity
sceneparentdirty_transform
Class
EventQuaternionVector3Matrix4	Math
TableOOPUtility		!%#(&0+=3G?KIWM[Yb^jdnltqxu}z����������������������Coeus `oop ^Table \Matrix4 ZVector3 XQuaternion VEvent TEntity  4  ]==])
Coeus:AddVFSFile('Graphics.Camera', [==[LJ �local Coeus 	= (...)
local oop 		= Coeus.Utility.OOP 

local BaseComponent = Coeus.Entity.BaseComponent
local Matrix4		= Coeus.Math.Matrix4

local Camera = oop:Class(BaseComponent) {
	fov = 90,
	near = 0.1,
	far = 10000,

	projection_type = 0,
	projection = false,
	projection_dirty = true,

	window = false
}
Camera.ProjectionType = {
	Orthographic 	= 1,
	Perspective 	= 2
}

function Camera:_new(window)
	self.window = window
	self.window.Resized:Listen(function()
		self.projection_dirty = true
	end)	

	self.projection_type = Camera.ProjectionType.Perspective
	self:BuildProjectionTransform()
end

function Camera:SetFieldOfView(degrees)
	self.fov = degrees
	self.projection_dirty = true
end	
function Camera:GetFieldOfView()
	return self.fov
end

function Camera:SetRenderDistances(near, far)
	self.near = near
	self.far = far
	self.projection_dirty = true
end
function Camera:GetRenderDistances()
	return self.near, self.far
end


function Camera:GetViewTransform()
	local entity = self.entity
	if entity then
		return entity:GetRenderTransform():GetInverse()
	end
	return Matrix4:New()
end

function Camera:BuildProjectionTransform()
	if not self.projection_dirty then return end
	self.projection_dirty = false

	if self.projection_type == Camera.ProjectionType.Perspective then
		local fov = self.fov
		local width, height = self.window:GetSize()
		local near, far = self.near, self.far
		local aspect = width / height
		self.projection = Matrix4.GetPerspective(fov, near, far, aspect)
	end
end

function Camera:GetProjectionTransform()
	self:BuildProjectionTransform()
	return self.projection
end

function Camera:GetViewProjection()
	local view = self:GetViewTransform()
	local proj = self:GetProjectionTransform()

	return proj * view
end

return Camera7   
+   ) :  G   �projection_dirtyself  � (:  7  7 71 >+  77:   7 >0  �G  �BuildProjectionTransformPerspectiveProjectionTypeprojection_type ListenResizedwindowCamera self  window   E   !:  ) : G  projection_dirtyfovself  degrees       
%7  H fovself   R   ):  : ) : G  projection_dirtyfar	nearself  near  far   *   .7  7 F far	nearself   �  &37    T� 7> 7@ +   7@ �NewGetInverseGetRenderTransformentityMatrix4 self  entity  �  a;7    T�G  ) :  7 +  77 T�7 7  7>7 7 !+ 7
 	 
  >:	 G  ��GetPerspectiveprojectionfar	nearGetSizewindowfovPerspectiveProjectionTypeprojection_typeprojection_dirty								Camera Matrix4 self  fov width height  near 	far  	aspect  O   H  7  >7 H projectionBuildProjectionTransformself   p   M  7  >  7 > H GetProjectionTransformGetViewTransformself  	view proj  �   #U TC  7  77 77 7 7 >3 >3	 :1 :
1 :1 :1 :1 :1 :1 :1 :1 :0  �H  GetViewProjection GetProjectionTransform BuildProjectionTransform GetViewTransform GetRenderDistances SetRenderDistances GetFieldOfView SetFieldOfView 	_new OrthographicPerspectiveProjectionType projection_dirtywindowprojection	near����	����far�NfovZprojection_type 
ClassMatrix4	MathBaseComponentEntityOOPUtility$!'%-)0.93F;KHRMTTCoeus "oop  BaseComponent Matrix4 Camera   ]==])
Coeus:AddVFSFile('Graphics.Debug.PlaneMesh', [==[LJ �local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local Mesh			= Coeus.Graphics.Mesh

local PlaneMesh = OOP:Class(Mesh) {
	
}

function PlaneMesh:_new(x_scale, y_scale, tex_x, tex_y)
	Mesh._new(self)

	local x = x_scale or 1
	local y = y_scale or 1
	local tx = tex_x or 1
	local ty = tex_y or 1

	local vertices = {
		-0.5 * x, 0, -0.5 * y, 		0.0 * tx, 0.0 * ty, 	0.0, 1.0, 0.0,
		 0.5 * x, 0, -0.5 * y, 		1.0 * tx, 0.0 * ty, 	0.0, 1.0, 0.0,
		-0.5 * x, 0,  0.5 * y, 		0.0 * tx, 1.0 * ty, 	0.0, 1.0, 0.0,
		 0.5 * x, 0,  0.5 * y, 		1.0 * tx, 1.0 * ty, 	0.0, 1.0, 0.0
	}		

	local indices = {
		2, 1, 0,
		3, 1, 2
	}

	self:SetData(vertices, indices, Mesh.DataFormat.PositionTexCoordNormalInterleaved)
end

return PlaneMesh� ;�
+  7   > T�'  T�'  T�'  T�' 3	 
 ;
	
 ;
	
;
	
;
	
;
		
 ;
	
;
	
;
	
 ;
	
;
	
;
	
;
	
;
	
;
	
;
	
;
	3
   7 	 
 +  77>G  �&PositionTexCoordNormalInterleavedDataFormatSetData   !                              	_new���� ����								







Mesh self  <x_scale  <y_scale  <tex_x  <tex_y  <x 4y 1tx .ty +vertices !
indices 	 �   1 !C  7  77 7 7 >2  >1 :0  �H  	_new
Class	MeshGraphicsOOPUtility
!!Coeus OOP Mesh 
PlaneMesh   ]==])
Coeus:AddVFSFile('Graphics.Framebuffer', [==[LJ �local ffi = require("ffi")
local Coeus 		= (...)
local OOP			= Coeus.Utility.OOP

local Texture 		= Coeus.Graphics.Texture
local ImageData 	= Coeus.Asset.Image.ImageData
local Mesh			= Coeus.Graphics.Mesh
local Shader		= Coeus.Graphics.Shader

local OpenGL 	= Coeus.Bindings.OpenGL
local gl 	 	= OpenGL.gl
local GL 		= OpenGL.GL

local Framebuffer = OOP:Class() {
	fbo = -1,
	textures = {},
	depth = false,

	shader = false,
	mesh = false,

	GraphicsContext = false,
	width = 0, height = 0,
}

function Framebuffer:_new(context, width, height, num_color_buffers, with_depth)
	self.width = width
	self.height = height
	self.GraphicsContext = context

	num_color_buffers = num_color_buffers or 1

	local fbo = ffi.new("int[1]")
	gl.GenFramebuffers(1, fbo)
	self.fbo = fbo[0]

	local prev_fbo = ffi.new("int[1]")
	gl.GetIntegerv(GL.DRAW_FRAMEBUFFER_BINDING, prev_fbo)
	gl.BindFramebuffer(GL.FRAMEBUFFER, self.fbo)

	self.draw_buffers_data = ffi.new("int[?]", num_color_buffers)
	for i = 0, num_color_buffers - 1 do
		local image_data = ImageData:New()
		image_data.image = nil
		image_data.Width = width
		image_data.Height = height
		image_data.format = ImageData.Format.RGBA

		local texture = Texture:New(image_data)
		gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + i, GL.TEXTURE_2D, texture.handle, 0)
		gl.DrawBuffer(GL.COLOR_ATTACHMENT0 + i)

		self.textures[#self.textures + 1] = texture
		self.draw_buffers_data[i] = GL.COLOR_ATTACHMENT0 + i
	end
	
	if with_depth then
		local image_data = ImageData:New()
		image_data.image = nil
		image_data.Width = width
		image_data.Height = height
		image_data.format = ImageData.Format.Depth

		self.depth = Texture:New(image_data)
		gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.TEXTURE_2D, self.depth.handle, 0)
	end

	gl.BindFramebuffer(GL.FRAMEBUFFER, prev_fbo[0])

	self.shader = Shader:New(self.GraphicsContext, [[
#version 330
layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord_;

out vec2 texcoord;

void main() {
	gl_Position = vec4(position, 1.0);
	texcoord = texcoord_;
}
		]],[[
#version 330

layout(location=0) out vec4 FragColor;

uniform sampler2D FBOTexture;

in vec2 texcoord;

void main() {
	FragColor = texture(FBOTexture, texcoord);
}
	]])

	self.mesh = Mesh:New()
	self.mesh:SetData({
		-1.0, -1.0, 0.0, 	0.0, 0.0,
		 1.0, -1.0, 0.0,	1.0, 0.0,
		-1.0,  1.0, 0.0, 	0.0, 1.0,
		 1.0,  1.0, 0.0,	1.0, 1.0
	}, {
		0, 1, 2,
		2, 1, 3
	}, Mesh.DataFormat.PositionTexCoordInterleaved)
end

function Framebuffer:Bind()
	gl.BindFramebuffer(GL.FRAMEBUFFER, self.fbo)
	gl.DrawBuffers(#self.textures, self.draw_buffers_data)
end

function Framebuffer:Clear()
	gl.Clear(bit.bor(tonumber(GL.COLOR_BUFFER_BIT), tonumber(GL.DEPTH_BUFFER_BIT)))
end

function Framebuffer.Unbind()
	gl.BindFramebuffer(GL.FRAMEBUFFER, 0)
end

function Framebuffer:Render(shader)
	local shader = shader or self.shader

	shader:Use()
	shader:Send("FBOTexture", self.textures[2])
	self.mesh:Render()
end

function Framebuffer:RenderTo(shader)
	shader:Use()
	self.mesh:Render()
end

function Framebuffer:Destroy()
	self.textures = {}
	local fb = ffi.new("int[1]", self.fbo)
	gl.BindFramebuffer(GL.FRAMEBUFFER, 0)
	gl.DeleteFramebuffers(1, fb)
end

return Framebuffer� &��O:  : :   T�' +  7% >+ 7' 	 >8 : +  7% >+ 7+	 7		
 >+ 7	+	 7	
	7
 >+  7%	 
 >: '  	 '
 I.�+  7>)  :::+ 77:+  7 >+ 7+ 7
+ 7+ 77'  >+ 7+ 7>7 7   97 + 79K�  T�+ 	 7>)	  :	::+	 7		7		:	+	 
	 7		 >	:	 +	 7		+
 7


+ 7+ 77 7'  >	+ 7	+	 7	
	8
 >+ 	 77
 % % >: + 	 7>:  7  	 7!3
" 3# + 7$7%>G   ��	����� PositionTexCoordInterleavedDataFormat     ��������   ����  ����   SetData	mesh�#version 330

layout(location=0) out vec4 FragColor;

uniform sampler2D FBOTexture;

in vec2 texcoord;

void main() {
	FragColor = texture(FBOTexture, texcoord);
}
	�#version 330
layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord_;

out vec2 texcoord;

void main() {
	gl_Position = vec4(position, 1.0);
	texcoord = texcoord_;
}
		shaderDEPTH_ATTACHMENT
depth
DepthtexturesDrawBufferhandleTEXTURE_2DCOLOR_ATTACHMENT0FramebufferTexture2D	RGBAFormatformatHeight
Width
imageNewint[?]draw_buffers_dataFRAMEBUFFERBindFramebufferDRAW_FRAMEBUFFER_BINDINGGetIntegervfboGenFramebuffersint[1]newGraphicsContextheight
width		    !!"#$$$$&&&&&&''''''''''''******,,,,7C,CEEEEEFFFFKNNNFOffi gl GL ImageData Texture Shader Mesh self  �context  �width  �height  �num_color_buffers  �with_depth  �fbo �prev_fbo �/ / /i -image_data )texture image_data # �  k+  7 + 77 >+  77  7 >G  �	�draw_buffers_datatexturesDrawBuffersfboFRAMEBUFFERBindFramebuffergl GL self   �  p+  7 4 74 + 7>4 + 7> = = G  �	�DEPTH_BUFFER_BITCOLOR_BUFFER_BITtonumberborbit
Cleargl GL self   T   t+   7   + 7'  > G  �	�FRAMEBUFFERBindFramebuffergl GL  �   +x T�7   7> 7% 7 8>7  7>G  Render	meshtexturesFBOTexture	SendUseshaderself  shader  shader  T   � 7 >7  7>G  Render	meshUseself  	shader  	 �  *�2  :  +  7% 7 >+ 7+ 7'  >+ 7'  >G   ��	�DeleteFramebuffersFRAMEBUFFERBindFramebufferfboint[1]newtexturesffi gl GL self  fb  �    *� �4   % > C 777777777	77
7777	 7
>
3 2  :>
1 :
1 :
1 :
1 :
1 :
1 :
1 :
0  �H
  Destroy RenderTo Render Unbind 
Clear 	Bind 	_newtextures 
depthfbo����shaderGraphicsContext
width 	meshheight 
ClassGLglOpenGLBindingsShader	MeshImageData
Image
AssetTextureGraphicsOOPUtilityffirequire

inkrpvt~x������ffi 'Coeus &OOP $Texture "ImageData Mesh Shader OpenGL gl GL Framebuffer   ]==])
Coeus:AddVFSFile('Graphics.GraphicsContext', [==[LJ �local ffi = require("ffi")
local Coeus = ...
local OOP = Coeus.Utility.OOP

local OpenGL = Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local RenderPass = Coeus.Graphics.RenderPass

local GraphicsContext = OOP:Class() {
	texture_units = {},
	MaxTextureUnits = 32,

	render_passes = {},

	ActiveCamera = false,

	all_scenes = {},
	active_scenes = {}
}

function GraphicsContext:_new()
	local texture_units = ffi.new('int[1]')
	gl.GetIntegerv(GL.MAX_TEXTURE_IMAGE_UNITS, texture_units)
	self.MaxTextureUnits = texture_units[0]

	self.render_passes[#self.render_passes+1] = RenderPass:New(self, "Default Pass", RenderPass.PassTag.Default, 1)
	self.render_passes[#self.render_passes+1] = RenderPass:New(self, "Transparent Pass", RenderPass.PassTag.Transparent, 2)
	self.render_passes[#self.render_passes+1] = RenderPass:New(self, "HUD", RenderPass.PassTag.HUD, 3)
end

function GraphicsContext:BindTexture(texture)
	local unused = 1
	for i = 1, self.MaxTextureUnits do
		if self.texture_units[i] == nil or texture == self.texture_units[i] then
			unused = i - 1
			break
		end
	end
	texture:Bind(tonumber(unused + GL.TEXTURE0))
	self.texture_units[unused + 1] = texture

	return unused
end
function GraphicsContext:UnbindTextures()
	for i, texture in ipairs(self.texture_units) do
		texture:Unbind()
	end
	self.texture_units = {}
end

function GraphicsContext:AddScene(scene)
	for i, v in pairs(self.all_scenes) do
		if v == scene then
			return
		end
	end
	self.all_scenes[#self.all_scenes + 1] = scene
end
function GraphicsContext:RemoveScene(scene)
	self:SetSceneActive(scene, false)
	for i, v in pairs(self.all_scenes) do
		if v == scene then
			table.remove(self.all_scenes, i)
		end
	end
end
function GraphicsContext:SetSceneActive(scene, active)
	local found = false
	for i, v in pairs(self.all_scenes) do
		if v == scene then
			found = true
		end
	end
	if not found then
		return false
	end
	for i, v in pairs(self.active_scenes) do
		if active then
			if v == scene then
				return false
			end
		else
			table.remove(self.active_scenes, i)
			return true
		end
	end
	self.active_scenes[#self.active_scenes + 1] = scene
	return true
end


function GraphicsContext:Render()
	for i, v in ipairs(self.render_passes) do
		v:Render()
		break
	end
end

return GraphicsContext� 
:g+  7 % >+ 7+ 7 >8 : 7 7   +  7  % + 77	'	 >97 7   +  7  %
 + 77'	 >97 7   +  7  % + 77'	 >9G   ����HUDTransparentTransparent PassDefaultPassTagDefault PassNewrender_passesMaxTextureUnitsMAX_TEXTURE_IMAGE_UNITSGetIntegervint[1]newffi gl GL RenderPass self  ;texture_units 6 � G!' ' 7  ' I�7 6
  T�7 6 T� T�K� 74 +  7> =7  9H �TEXTURE0tonumber	Bindtexture_unitsMaxTextureUnits			GL self  texture  unused   i 
 �   +.4  7 >T� 7>AN�2  : G  Unbindtexture_unitsipairsself    i texture   �  054  7 >D� T�G  BN�7 7   9G  all_scenes
pairsself  scene    i v   � 
  4=  7   ) >4 7 >D� T�4 77 	 >BN�G  remove
tableall_scenes
pairsSetSceneActiveself  scene  	
 
 
i v   �  )lE) 4  7 >D� T	�) BN�  T�) H 4  7 >D�  T	� T	
�)	 H	 T	�4	 7		7
  >	)	 H	 BN�7 7   9) H remove
tableactive_scenesall_scenes
pairs





self  *scene  *active  *found (  i v    i v   v   $^4  7 >T� 7>T�AN�G  Renderrender_passesipairsself    i v   � 
  )p e4   % > C 77777777	 7
>3 2	  :	2	  :	2	  :	2	  :	>1 :1 :1 :1 :1 :1 :1 :0  �H  Render SetSceneActive RemoveScene AddScene UnbindTextures BindTexture 	_newactive_scenesall_scenesrender_passestexture_units MaxTextureUnits ActiveCamera
ClassRenderPassGraphicsGLglOpenGLBindingsOOPUtilityffirequire		-!3.<5D=[Ec^eeffi &Coeus %OOP #OpenGL !gl  GL RenderPass GraphicsContext   ]==])
Coeus:AddVFSFile('Graphics.Lighting.DirectionalLight', [==[LJ]==])
Coeus:AddVFSFile('Graphics.Lighting.PointLight', [==[LJ]==])
Coeus:AddVFSFile('Graphics.Material', [==[LJ �local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local BaseComponent	= Coeus.Entity.BaseComponent

local Material = OOP:Class(BaseComponent) {
	GraphicsContext = false,
	Shader = false,

	Textures = {}
}

function Material:_new(ctx)
	self.GraphicsContext = ctx
end

function Material:Use()
	self.Shader:Use()
	for i, v in pairs(self.Textures) do
		if v.GetClass and v:GetClass(Texture) then
			self.Shader:Send(i, v)
		end
	end

	local camera = self.GraphicsContext.ActiveCamera
	local model = self.entity:GetRenderTransform()
	local view_projection = camera:GetViewProjection()
	local mvp = view_projection * model
	
	self.Shader:Send("ModelViewProjection", mvp)
	self.Shader:Send("Model", model)
end

return Material2   :  G  GraphicsContextself  ctx   � 
  0r7   7>4 7 >D�7  T� 74 >  T�7   7 	 >BN�7 77	  7
> 7> 7   7%  >7   7%  >G  
ModelModelViewProjectionGetViewProjectionGetRenderTransformentityActiveCameraGraphicsContext	SendTextureGetClassTextures
pairsUseShader				


self  1  i v  camera model view_projection mvp  �   = "C  7  77 7 7 >3 2  :>1 :1
 :	0  �H  Use 	_newTextures GraphicsContextShader
ClassBaseComponentEntityOOPUtility

 ""Coeus OOP BaseComponent Material   ]==])
Coeus:AddVFSFile('Graphics.Mesh', [==[LJ �local Coeus = (...)
local oop = Coeus.Utility.OOP
local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL
local ffi = require("ffi")

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local Mesh = oop:Class() {
	vbo = -1,
	ibo = -1,
	vao = -1,

	num_vertices = 0,
	num_indices = 0,

	render_groups = {}
}

Mesh.DataFormat = {
	Position 							= 0,
	PositionTexCoordInterleaved			= 1,
	PositionTexCoordNormalInterleaved 	= 2
}

function Mesh:_new()
	local vao, vbo = ffi.new('int[1]'), ffi.new('int[1]')
	gl.GenVertexArrays(1, vao); vao = vao[0]
	gl.BindVertexArray(vao)
	self.vao = vao

	gl.GenBuffers(1, vbo); vbo = vbo[0]
	gl.BindBuffer(GL.ARRAY_BUFFER, vbo)
	self.vbo = vbo
end

function Mesh:SetData(vertices, indices, format)
	self.num_vertices = #vertices

	gl.BindVertexArray(self.vao)

	if format == Mesh.DataFormat.Position then
		gl.EnableVertexAttribArray(0)
		gl.VertexAttribPointer(0, 3, GL.FLOAT, GL.FALSE, 3 * 4, ffi.cast('void *', 0))

		self.num_vertices = self.num_vertices / 3
	elseif format == Mesh.DataFormat.PositionTexCoordInterleaved then
		gl.EnableVertexAttribArray(0)
		gl.VertexAttribPointer(0, 3, GL.FLOAT, GL.FALSE, 5 * 4, ffi.cast('void *', 0))
		gl.EnableVertexAttribArray(1)
		gl.VertexAttribPointer(1, 2, GL.FLOAT, GL.FALSE, 5 * 4, ffi.cast('void *', 3 * 4))

		self.num_vertices = self.num_vertices / 5
	elseif format == Mesh.DataFormat.PositionTexCoordNormalInterleaved then
		gl.EnableVertexAttribArray(0)
		gl.VertexAttribPointer(0, 3, GL.FLOAT, GL.FALSE, 8 * 4, ffi.cast('void *', 0))
		gl.EnableVertexAttribArray(1)
		gl.VertexAttribPointer(1, 2, GL.FLOAT, GL.FALSE, 8 * 4, ffi.cast('void *', 3 * 4))
		gl.EnableVertexAttribArray(2)
		gl.VertexAttribPointer(2, 3, GL.FLOAT, GL.FALSE, 8 * 4, ffi.cast('void *', 5 * 4))

		self.num_vertices = self.num_vertices / 8
	end

	local data = ffi.new('float['..#vertices..']')
	for i=1,#vertices do
		data[i-1] = vertices[i]
	end
	gl.BufferData(GL.ARRAY_BUFFER, 4 * #vertices, data, GL.STATIC_DRAW)

	if indices then
		self.num_indices = #indices
		local ibo = ffi.new('int[1]')
		gl.GenBuffers(1, ibo); ibo = ibo[0]
		gl.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, ibo)
		self.ibo = ibo

		data = ffi.new("int[?]", #indices)
		for i=1,#indices do
			data[i-1] = indices[i]
		end
		gl.BufferData(GL.ELEMENT_ARRAY_BUFFER, 4 * #indices, data, GL.STATIC_DRAW)
	end

	local gl_error = gl.GetError()
	if gl_error ~= GL.NO_ERROR then
		print("GL error: " .. gl_error)
	end
end

function Mesh:Render()
	gl.BindVertexArray(self.vao)
	if self.ibo ~= -1 then
		gl.DrawElements(GL.TRIANGLES, self.num_indices, GL.UNSIGNED_INT, nil)
	else
		gl.DrawArrays(GL.TRIANGLES, 0, self.num_vertices)
	end
end

function Mesh:Destroy()
	local buf = ffi.new("int[1]")
	buf[0] = self.vbo
	gl.DeleteBuffers(1, buf)
	buf[0] = self.ibo
	gl.DeleteBuffers(1, buf)
	buf[0] = self.vao
	gl.DeleteVertexArrays(1, buf)
end

return Mesh� 	 !?	+  7 % >+  7 % >+ 7'  >8 + 7 >: + 7'  >8 + 7+ 7 >: G  ���vboARRAY_BUFFERBindBufferGenBuffersvaoBindVertexArrayGenVertexArraysint[1]new	ffi gl GL self  "vao 	vbo   � ��)4 :  +  77 >+ 77 T�+  7'  >+  7'  ' + 7+ 7'	 +
 7
	
%
 '  >
 =7   :  Tp�+ 77 T*�+  7'  >+  7'  ' + 7+ 7'	 +
 7
	
%
 '  >
 =+  7' >+  7' ' + 7+ 7'	 +
 7
	
%
 ' >
 =7  :  TA�+ 77 T<�+  7'  >+  7'  ' + 7+ 7'	  +
 7
	
%
 '  >
 =+  7' >+  7' ' + 7+ 7'	  +
 7
	
%
 ' >
 =+  7' >+  7' ' + 7+ 7'	  +
 7
	
%
 ' >
 =7  :  + 7%  % $>'  ' I�	6
9
	K�+  7+ 7  +	 7		>  T+� : + 7% >+  7'  >8 +  7+ 7 >: + 7%  > '  ' I�
	6	9
K�+  7+ 7 	 +
 7

>+  7>+ 7 T�4 %  $>G  �	���GL error: 
printNO_ERRORGetErrorint[?]iboELEMENT_ARRAY_BUFFERBindBufferGenBuffersint[1]num_indicesSTATIC_DRAWARRAY_BUFFERBufferData]float[new&PositionTexCoordNormalInterleaved PositionTexCoordInterleavedvoid *	cast
FALSE
FLOATVertexAttribPointerEnableVertexAttribArrayPositionDataFormatvaoBindVertexArraynum_vertices
				




          ""##$$$$%%%%%%&&&&&&'))))))****+++*----------0001111222224gl Mesh GL ffi self  �vertices  �indices  �format  �data �L  i ibo %  i gl_error 
 � 	'_+  7 7 >7   T
�+  7+ 77 + 7)  >T�+  7+ 7'  7 >G  ��num_verticesDrawArraysUNSIGNED_INTnum_indicesTRIANGLESDrawElementsibovaoBindVertexArray����gl GL self   �  /h+  7 % >7 ; + 7'  >7 ; + 7'  >7 ; + 7'  >G  ��DeleteVertexArraysvaoiboDeleteBuffersvboint[1]newffi gl self  buf  �   !e rC  7  77 77 74 % >7777	
 7	
>	3
 2  :
>	3
 :
	1
 :
	1
 :
	1
 :
	1
 :
	0  �H	  Destroy Render SetData 	_new  PositionTexCoordInterleavedPosition &PositionTexCoordNormalInterleavedDataFormatrender_groups num_vertices vbo����vao����ibo����num_indices 
ClassGLgl	glfwffirequireOpenGL	GLFWBindingsOOPUtility
'])f_phrrCoeus  oop GLFW OpenGL ffi glfw GLFW gl GL Mesh   ]==])
Coeus:AddVFSFile('Graphics.MeshRenderer', [==[LJ �local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local BaseComponent	= Coeus.Entity.BaseComponent
local Material 		= Coeus.Graphics.Material

local MeshRenderer = OOP:Class(BaseComponent) {
	GraphicsContext = false,
	Mesh = false,
}

function MeshRenderer:_new(ctx)
	self.GraphicsContext = ctx
end

function MeshRenderer:Render()
	local material = self.entity:GetComponent(Material)
	if material and self.Mesh then
		material:Use()
		
		self.Mesh:Render()
	end
end

return MeshRenderer2   :  G  GraphicsContextself  ctx   �  .7   7+  >  T
�7   T� 7>7  7>G  �RenderUse	MeshGetComponententityMaterial self  material  �   L C  7  77 77 7 7 >3 >1	 :1 :
0  �H  Render 	_new GraphicsContext	Mesh
ClassMaterialGraphicsBaseComponentEntityOOPUtilityCoeus OOP BaseComponent Material MeshRenderer   ]==])
Coeus:AddVFSFile('Graphics.RenderPass', [==[LJ �local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local next_priority = 1
local RenderPass = OOP:Class() {
	context = false,
	name = "Default Pass",
	pass_tag = false,
	priority = 1,

	entities = {}
}
RenderPass.PassTag = {
	Default 		= 1,
	Transparent 	= 2,
	HUD				= 3
}

function RenderPass:_new(context, name, tag, priority)
	self.context = context
	self.name = name
	self.pass_tag = tag or RenderPass.PassTag.Default
	self.priority = priority or next_priority
	next_priority = next_priority + 1
end

function RenderPass:AddEntity(entity)
	for i, v in pairs(self.entities) do
		if v == entity then
			return
		end
	end

	self.entities[#self.entities + 1] = entity
end
function RenderPass:RemoveEntity(entity)
	for i, v in pairs(self.entities) do
		if v == entity then
			table.remove(self.entities, i)
			return
		end
	end
end

function RenderPass:Render()
	for i,v in pairs(self.context.active_scenes) do
		v:Render()
	end
end

return RenderPass� S:  :  T�+  77:  T�+ : +  , G  ��priorityDefaultPassTagpass_tag	namecontextRenderPass next_priority self  context  name  tag  priority   �  14  7 >D� T�G  BN�7 7   9G  entities
pairsself  entity    i v   � 
  1$4  7 >D� T�4 77 	 >G  BN�G  remove
tableentities
pairsself  entity    i v   }   $-4  7 7>D� 7>BN�G  Renderactive_scenescontext
pairsself    i v   �   C 3C  7  7'  7>3 2  :>3 :1 :1
 :	1 :1 :0  �H  Render RemoveEntity AddEntity 	_new TransparentHUDDefaultPassTagentities contextpriority	nameDefault Passpass_tag
ClassOOPUtility#+$1-33Coeus OOP next_priority RenderPass   ]==])
Coeus:AddVFSFile('Graphics.Scene', [==[LJ �local Coeus 		= (...)
local OOP			= Coeus.Utility.OOP

local Scene = OOP:Class() {
	context = false,
	active = false,

	entities = {}
}

function Scene:_new(context)
	self.context = context
end

function Scene:AddEntity(entity)
	for i, v in pairs(self.entities) do
		if v == entity then
			return
		end
	end
	self.entities[#self.entities + 1] = entity
	if entity.scene then
		entity.scene:RemoveEntity(entity)
	end
	entity:SetScene(self)
end
function Scene:RemoveEntity(entity)
	for i, v in pairs(self.entities) do
		if v == entity then
			table.remove(self.entities, i)
			return
		end
	end
end

function Scene:Update(dt)
	for i, v in ipairs(self.entities) do
		v:Update(dt)
	end
end

function Scene:Render()
	for i, v in ipairs(self.entities) do
		v:Render()
	end
end

return Scene.   :  G  contextself  context   �  =4  7 >D� T�G  BN�7 7   97  T�7 7 > 7  >G  SetSceneRemoveEntity
sceneentities
pairs



self  entity    i v   � 
  14  7 >D� T�4 77 	 >G  BN�G  remove
tableentities
pairsself  entity    i v   v 
  )$4  7 >T� 7	 >AN�G  Updateentitiesipairsself  dt    i v   l   
#*4  7 >T� 7>AN�G  Renderentitiesipairsself    i v   �   - 0C  7  7 7>3 2  :>1 :1 :1
 :	1 :1 :0  �H  Render Update RemoveEntity AddEntity 	_newentities contextactive
ClassOOPUtility"($.*00Coeus OOP Scene   ]==])
Coeus:AddVFSFile('Graphics.Shader', [==[LJ �local Coeus = (...)
local oop = Coeus.Utility.OOP
local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL
local ffi = require("ffi")

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local Vector3 = Coeus.Math.Vector3
local Matrix4 = Coeus.Math.Matrix4
local Table = Coeus.Utility.Table

local Texture = Coeus.Graphics.Texture

local Shader = oop:Class() {
	context = false,
	program = false,
	uniforms = {}
}

local function check_item(shader, get, log, status_check)
	local status = ffi.new("int[1]")
	get(shader, status_check, status)
	if status[0] == GL.FALSE then
		local length = ffi.new("int[1]")
		get(shader, GL.INFO_LOG_LENGTH, length)
		local str = ffi.new("char[" .. length[0] .. "]")
		log(shader, length[0], length, str)
		print("Error in shader: " .. ffi.string(str, length[0]))
		return false
	end
	return true
end

local function create_shader(source, type)
	local shader = gl.CreateShader(type)
	local str = ffi.new("const char*[1]")
	str[0] = source
	local len = ffi.new("int[1]")
	len[0] = source:len()
	gl.ShaderSource(shader, 1, str, len)
	gl.CompileShader(shader)

	check_item(shader, gl.GetShaderiv, gl.GetShaderInfoLog, GL.COMPILE_STATUS)
	return shader
end


function Shader:_new(context, vertex_source, fragment_source, geometry_source)
	self.context = context

	local vertex_shader
	if vertex_source then
		vertex_shader = create_shader(vertex_source, GL.VERTEX_SHADER)
	end
	local fragment_shader
	if fragment_source then
		fragment_shader = create_shader(fragment_source, GL.FRAGMENT_SHADER)
	end

	local program
	if vertex_shader and fragment_shader then
		program = gl.CreateProgram()
		gl.AttachShader(program, vertex_shader)
		gl.AttachShader(program, fragment_shader)

		gl.LinkProgram(program)
		check_item(program, gl.GetProgramiv, gl.GetProgramInfoLog, GL.LINK_STATUS)
		self.program = program
	end
end

function Shader:get_uniform(name)
	local uni = self.uniforms[name]
	if not uni then
		local str = ffi.cast('char*', name)
		uni = gl.GetUniformLocation(self.program, str)
		self.uniforms[name] = uni
	end
	return uni
end

function Shader:Send(name, ...)
	local uniform = self:get_uniform(name)
	if uniform == -1 then
		--TODO: better error handling here
		error("Couldn't set shader uniform " .. name .. ": location not found (did you forget to use it?)")
	end

	local values = {...}
	local first = values[1]
	if not first then return end
	local size = 1
	if type(first) ~= 'number' then
		if first.GetClass and first:GetClass() == Vector3 then
			--convert the data now...
			local data = ffi.new('float[' .. (3 * #values) .. ']')
			local idx = 0
			for i=1,#values do
				data[idx+0] = values[i].x
				data[idx+1] = values[i].y 
				data[idx+2] = values[i].z
				idx = idx + 3
			end
			gl.Uniform3fv(uniform, #values, data)
			return
		end
		if first.GetClass and first:GetClass() == Matrix4 then
			local data = ffi.new('float[' .. (16 * #values) .. ']')
			local idx = 0
			for i=1,#values do
				for j=1, 16 do
					data[idx] = values[i].m[j]
					idx = idx + 1
				end
			end
			gl.UniformMatrix4fv(uniform, #values, GL.FALSE, data)
			return
		end
		if first.GetClass and first:GetClass() == Texture then
			local data = ffi.new('int[' .. #values .. ']')
			for i = 1, #values do
				data[i - 1] = self.context:BindTexture(values[i])
			end
			gl.Uniform1iv(uniform, #values, data)
			return
		end
		print("Unhandled type of uniform")
		return
	end

	--If a single number...
	local data = ffi.new('float[' .. #values .. ']')
	for i = 1, #values do
		data[i - 1] = values[i]
	end
	gl.Uniform1fv(uniform, #values, data)
end

function Shader:SendInt(name, ...)
	--TODO: implement this
end

function Shader:Use()
	gl.UseProgram(self.program)
end

return Shader� 	 2v+  7 % >     >8 + 7 T"�+  7 % >   + 7	 >+  7 % 8 %	 $	>   8	 
  >4 % +	  7		
 8 >	$	>) H ) H ��stringError in shader: 
print]
char[INFO_LOG_LENGTH
FALSEint[1]new		ffi GL shader  3get  3log  3status_check  3status .length str  � 

 &a'+  7  >+ 7% >;  + 7% >  7 >; +  7 '  	 >+  7 >+  +  7+  7+	 7			>H ����COMPILE_STATUSGetShaderInfoLogGetShaderivCompileShaderShaderSourcelenint[1]const char*[1]newCreateShader									
gl ffi check_item GL source  'type  'shader "str len  � 
 5�5:  )    T�+   + 7> )    T�+   +	 7		> )    T�  T�+ 7> + 7	 
 >+ 7	 
 >+ 7	 >+ 	 +
 7

+ 7+ 7>:	 G  ����programLINK_STATUSGetProgramInfoLogGetProgramivLinkProgramAttachShaderCreateProgramFRAGMENT_SHADERVERTEX_SHADERcontext						create_shader GL gl check_item self  6context  6vertex_source  6fragment_source  6geometry_source  6vertex_shader 3fragment_shader 	*program 	! �  4M7  6  T�+  7%  >+ 77  > 7  9H ��programGetUniformLocation
char*	castuniformsffi gl self  name  uni str  �
��W7  7   >	  T�4 %  % $>2 C < 8  T�G  ' 4  > T|�7  T(� 7>+   T"�+ 7%  %		 $	>'  ' 	 '
 I�67
9679679K�+ 7	 
  >G  7  T'� 7>+  T!�+ 7%  %		 $	>'  ' 	 '
 I�' ' ' I�6769K�K�+ 7	 
 + 7 >G  7  T � 7>+  T�+ 7%  %		 $	>'  '	 I�
7  76
>9K�+ 7 	 
 >G  4 % >G  + 7%  %		 $	>'  '	 I�
6
9K�+ 7 	 
 >G  	���
���Uniform1fvUnhandled type of uniform
printUniform1ivBindTexturecontext	int[
FALSEUniformMatrix4fvmUniform3fvzyx]float[newGetClassnumber	type5: location not found (did you forget to use it?)!Couldn't set shader uniform 
errorget_uniform��������  			
""""""""#%%%%%%%%%&&&&&&&''''((((((('******+---.2222222333344436666667Vector3 ffi gl Matrix4 GL Texture self  �name  �uniform �values �first �size �data idx   i data &idx   i 
  j data  	 	 	i data   i     �G  self  name   D  �+  7 7 >G  �programUseProgramgl self   �   +� �C  7  77 77 74 % >7777	7	
 7		7

 7

7  77 7 7>3 2  :>1 1 1 :1 :1 :1 :1 :0  �H  Use SendInt 	Send get_uniform 	_new  uniforms contextprogram
ClassTextureGraphics
TableMatrix4Vector3	MathGLgl	glfwffirequireOpenGL	GLFWBindingsOOPUtility
%2K5UM�W������Coeus *oop (GLFW &OpenGL $ffi !glfw  GLFW gl GL Vector3 Matrix4 Table Texture Shader check_item create_shader   ]==])
Coeus:AddVFSFile('Graphics.Text.Font', [==[LJ �Glocal ffi			= require("ffi")
local Coeus 		= (...)
local OOP			= Coeus.Utility.OOP
local tt			= Coeus.Bindings.stb_truetype
local stdio			= Coeus.Bindings.stdio_

local OpenGL		= Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local Texture 		= Coeus.Graphics.Texture
local Glyph 		= Coeus.Graphics.Text.Glyph

--[[
	Huge thanks to slime from #LOVE on irc.oftc.net
--]]

local Font = OOP:Class() {
	glyphs = {},

	texture_cache_id = 0,
	texture_size_index = 1,
	texture_width = 0,
	texture_height = 0,
	texture_x = 0,
	texture_y = 0,
	row_height = 0,

	font = false,
	scale = 1,
	height = 12,
	line_height = 1,
	baseline = 0,

	ascent = 0,
	descent = 0,


	textures = {},
}	
Font.TextureSizes = {
	{128, 128}, {256, 128},
	{256, 256}, {512, 256},
	{512, 512}, {1024, 512},
	{1024, 1024}, {2048, 1024},
	{2048, 2048}
}
Font.TexturePadding = 1

function Font:_new(filename, height)
	self.height = height or 12

	local file = stdio.fopen(filename, "rb")
	stdio.fseek(file, 0, stdio.SEEK_END)
	local file_size = stdio.ftell(file)
	stdio.fseek(file, 0, stdio.SEEK_SET)
	local buffer = ffi.new("unsigned char[" .. tonumber(file_size) .. "]")
	stdio.fread(buffer, 1, file_size, file)

	self.font = ffi.new("stbtt_fontinfo[1]")
	local ascent = ffi.new("int[1]")
	local descent = ffi.new("int[1]")
	local linegap = ffi.new("int[1]")

	tt.stbtt_InitFont(self.font, buffer, 0)
	self.scale = tt.stbtt_ScaleForPixelHeight(self.font, self.height)
	self.scale = tonumber(self.scale)
	tt.stbtt_GetFontVMetrics(self.font, ascent, descent, linegap)

	--if it bitches, check this line
	self.baseline = math.floor(tonumber(ascent[0] * self.scale))
	self.ascent = ascent[0] * self.scale
	self.descent = descent[0] * self.scale
	self.linegap = linegap[0] * self.scale
end

function Font:CreateTexture()
	local size_index = self.texture_size_index
	if size_index < #Font.TextureSizes and #self.textures > 0 then
		local top = self.textures[#self.textures]
		top:Destroy()
		table.remove(self.textures, #self.textures)

		self.texture_cache_id = self.texture_cache_id + 1
		size_index = size_index + 1
	end

	local texture = Texture:New()
	texture:Bind()

	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_BASE_LEVEL, 0)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAX_LEVEL, 0)
	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MAX_ANISOTROPY_EXT, 8)
	gl.PixelStorei(GL.UNPACK_ALIGNMENT, 1)
	gl.PixelStorei(GL.PACK_ALIGNMENT, 1)
	self.texture_width = Font.TextureSizes[size_index][1]
	self.texture_height = Font.TextureSizes[size_index][2]
	local format = GL.RED
	local internal_format = GL.R8
	local bpp = 1
	local byte_len = self.texture_width * self.texture_height * bpp
	local data = ffi.new("unsigned char[?]", byte_len, 0)
	gl.TexImage2D(GL.TEXTURE_2D, 0, internal_format,
				  self.texture_width, self.texture_height,
				  0, format, GL.UNSIGNED_BYTE,
				  data)

	
	local err = gl.GetError()
	if err ~= GL.NO_ERROR then
		texture:Destroy()
		error("Couldn't create font texture! Error: " .. err)
	end

	self.texture_size_index = size_index
	self.texture_x = Font.TexturePadding
	self.texture_y = Font.TexturePadding 
	self.row_height = Font.TexturePadding

	self.textures[#self.textures+1] = texture
end

function Font:AddGlyph(glyph)
	local x1, y1 = ffi.new("int[1]"), ffi.new("int[1]")
	local x2, y2 = ffi.new("int[1]"), ffi.new("int[1]")
	tt.stbtt_GetCodepointBitmapBox(
		self.font, glyph, self.scale, self.scale,
		x1, y1, x2, y2)
	x1 = tonumber(x1[0])
	y1 = tonumber(y1[0])
	local width = tonumber(x2[0]) - x1
	local height = tonumber(y2[0]) - y1
	local bytes = width * height
	local data
	if bytes > 0 then
		data = ffi.new("unsigned char[?]", bytes, 64)
	else
		local data = ffi.new("unsigned char[0]")
	end
	tt.stbtt_MakeCodepointBitmap(
		self.font, data, width, height, width, self.scale, self.scale,
		glyph)
	if self.texture_x + width + Font.TexturePadding > self.texture_width then
		self.texture_x = Font.TexturePadding
		self.texture_y = self.texture_y + self.row_height
		self.row_height = Font.TexturePadding
	end
	if self.texture_y + height + Font.TexturePadding > self.texture_height then
		local cache_id = self.texture_cache_id
		self:CreateTexture()

		if cache_id ~= self.texture_cache_id then
			local glyphs = Coeus.Utility.Table.Copy(self.glyphs)
			for i, v in pairs(glyphs) do
				cache_id = self.texture_cache_id
				self:AddGlyph(i)
				table.remove(self.glyphs, i)

				if cache_id ~= self.texture_cache_id then
					break
				end
			end
		end
	end

	local g = Glyph:New()
	local advance = ffi.new("int[1]")
	local lsb = ffi.new("int[1]")
	tt.stbtt_GetCodepointHMetrics(self.font, glyph, advance, lsb)

	g.Spacing = tonumber(advance[0]) * self.scale
	g.BearingX = tonumber(lsb[0]) * self.scale
	g.BearingY = tonumber(y1) + height

	local texture = self.textures[#self.textures]
	g.Texture = texture

	g.Vertices = {}
	if width > 0 and height > 0 then
		texture:Bind()
		gl.TexSubImage2D(GL.TEXTURE_2D,
			0, self.texture_x, self.texture_y, width, height,
			GL.RED, GL.UNSIGNED_BYTE, data)

		g.Vertices = {
			{
				x = 0, y = 0 + height, z = 0, 
				s = (self.texture_x) / self.texture_width, 
				t = (self.texture_y) / self.texture_height
			},
			{
				x = 0 + width, y = 0 + height, z = 0, 
				s = (self.texture_x+width) / self.texture_width, 
				t = (self.texture_y) / self.texture_height
			},
			{
				x = 0, y = 0, z = 0, 
				s = (self.texture_x) / self.texture_width, 
				t = (self.texture_y+height) / self.texture_height
			},
			{
				x = 0, y = 0 , z = 0, 
				s = (self.texture_x) / self.texture_width, 
				t = (self.texture_y +height) / self.texture_height
			},
			{
				x = 0 + width, y = 0 + height, z = 0, 
				s = (self.texture_x+width) / self.texture_width, 
				t = (self.texture_y) / self.texture_height
			},
			{
				x = 0 + width, y = 0, z = 0, 
				s = (self.texture_x+width) / self.texture_width, 
				t = (self.texture_y+height) / self.texture_height
			},
		}
		for i, v in ipairs(g.Vertices) do
			v.x = v.x + g.BearingX
			v.y = v.y - g.BearingY
		end
	end
	if width > 0 then
		self.texture_x = self.texture_x + width + Font.TexturePadding
	end
	if height > 0 then
		self.row_height = math.max(self.row_height, height + Font.TexturePadding)
	end
	g.Codepoint = glyph
	self.glyphs[glyph] = g

	return g
end
function Font:GetGlyph(glyph)
	local found = self.glyphs[glyph]
	if found then
		return found
	end
	return self:AddGlyph(glyph)
end

function Font:GenerateMesh(text, extra_spacing, offset_x, offset_y)
	local draws = {}

	local extra_spacing = extra_spacing or 0
	local offset_x = offset_x or 0
	local offset_y = offset_y or 0
	local dx = offset_x
	local dy = offset_y

	local line_height = self:GetBaseline()
	local max_width = 0

	--Do a pass to get all glyphs loaded
	for codepoint in Coeus.Utility.Unicode.UTF8Iterate(text) do
		self:GetGlyph(codepoint)
	end

	local vertex_data = {}
	local vertex_id = 0
	--Now do the actual mesh building
	for codepoint in Coeus.Utility.Unicode.UTF8Iterate(text) do
		if codepoint == string.byte('\n') then
			if dx > max_width then
				max_width = dx
			end
			dy = dy + math.floor(self:GetHeight() + self:GetLineHeight() + 0.5)
			dx = offset_x
		else
			local glyph = self:GetGlyph(codepoint)
			if glyph.Texture then
				local start_id = vertex_id
				for i, v in ipairs(glyph.Vertices) do
					vertex_id = vertex_id + 1
					vertex_data[#vertex_data + 1] = v.x + dx
					vertex_data[#vertex_data + 1] = v.y + dy + line_height
					vertex_data[#vertex_data + 1] = v.z

					vertex_data[#vertex_data + 1] = v.s
					vertex_data[#vertex_data + 1] = v.t
				end

				if #draws == 0 or draws[#draws].texture ~= glyph.Texture then

					local draw = {}
					draw.start = start_id
					draw.count = 0
					draw.texture = glyph.Texture
					draws[#draws + 1] = draw
				end

				draws[#draws].count = draws[#draws].count + #glyph.Vertices
			end

			dx = dx + glyph.Spacing

			if codepoint == string.byte(" ") and extra_spacing ~= 0 then
				dx = math.floor(dx + extra_spacing)
			end
		end
	end

	table.sort(draws, function(a, b)
		return a.texture.handle < b.texture.handle
	end)

	if dx > max_width then
		max_width = dx
	end

	local height = dy - offset_y
	if dx > 0 then
		height = height + (self:GetHeight() * self:GetLineHeight() + 0.5)
	end
	return vertex_data, draws, max_width - offset_x, height
end

function Font:GetWidth(text)

end

function Font:GetHeight()
	return self.height
end

function Font:GetLineHeight()
	return self.line_height
end

function Font:GetBaseline()
	return self.baseline
end

return Font�  i�2 T�' :  +  7 % >+  7 '  +  7>+  7 >+  7 '  +  7>+ 7% 4	  >%
 $>+  7 ' 	 
 >+ 7% >: + 7% >+ 7% >+ 7%	 >+	 7		7
  '  >	+	 7		7
 7  >	:	 4		 7
 >	:	 +	 7		7
    >	4	 7		4
	 8 7  >
 =	 :	 8	 7
  	
	:	 8	 7
  	
	:	 8	 7
  	
	:	 G  � ��linegapdescentascent
floor	mathbaselinestbtt_GetFontVMetricsstbtt_ScaleForPixelHeight
scalestbtt_InitFontint[1]stbtt_fontinfo[1]	font
fread]tonumberunsigned char[newSEEK_SET
ftellSEEK_END
fseekrb
fopenheight




stdio ffi tt self  jfilename  jheight  jfile 
`file_size Ubuffer Eascent 5descent 1linegap - � (��M07  +  7  T�7  '   T�7 7  6 7>4 77 7  >7  :  +  7> 7>+ 7	+ 7
+ 7+ 7>+ 7	+ 7
+ 7+ 7>+ 7	+ 7
+ 7+ 7>+ 7	+ 7
+ 7+ 7>+ 7	+ 7
+ 7'  >+ 7	+ 7
+ 7'  >+ 7+ 7
+ 7' >+ 7+ 7' >+ 7+ 7' >+  768: +  768: + 7+ 7' 7 7   + 7% 	 '
  >+ 7+	 7	
	'
   7 7 '   + 7 >
+ 7 >+	 7	!		 T	�
 7	>	4	" %
#  $

>	:  +	  7	%	:	$ +	  7	%	:	& +	  7	%	:	' 7	 7
 

 
 
9
	G  
���� �row_heighttexture_yTexturePaddingtexture_x*Couldn't create font texture! Error: 
errorNO_ERRORGetErrorUNSIGNED_BYTETexImage2Dunsigned char[?]newR8REDtexture_heighttexture_widthPACK_ALIGNMENTUNPACK_ALIGNMENTPixelStoreiTEXTURE_MAX_ANISOTROPY_EXTTexParameterfTEXTURE_MAX_LEVELTEXTURE_BASE_LEVELTEXTURE_MAG_FILTERNEARESTTEXTURE_MIN_FILTERTEXTURE_WRAP_TCLAMP_TO_EDGETEXTURE_WRAP_STEXTURE_2DTexParameteri	BindNewtexture_cache_idremove
tableDestroytexturesTextureSizestexture_size_index    !$$$%%%%&&&'''''*+++,,,---/////0Font Texture gl GL ffi self  �size_index �top texture �format W:internal_format 8bpp 7byte_len 3data -err  � 4��m+  7 % >+  7 % >+  7 % >+  7 % >+ 77  7	 7
     >	4 8 > 4 8 > 4 8 >4 8 > )	  '
  
 T
�+
  7
 
%  '@ >
	
 T
�+
  7
 
% >
+
 7

7 	    7 7  >
	7
	 

+ 7


7 
 T

�+
 7


:
	 7
 7 

:
 +
 7


:
 7
 

+ 7


7 
 T
!�7
   7 >7 
 T�+ 7777 >4  >D�7
   7  >4 77  >7 
 T�T�BN�+
 
 7

>
+  7 % >+  7 % >+ 77    >4 8 >7  :
4 8 >7  :
4  >:
7 7  6:
2  : 
'   Ts�'   Tp� 7!>+ 7"+ 7#'  7	 7   + 7$+ 7%	 >
2 3&  :'7	 7 !:(7 7 !:);3*  :+ :'7	 7 !:(7 7 !:);3, 7	 7 !:(7 7 !:);3- 7	 7 !:(7 7 !:);3.  :+ :'7	 7 !:(7 7 !:);3/  :+7	 7 !:(7 7 !:);: 
40 7 
>T�7+7
:+7'7
:'AN�'   T�7	 + 7
:	 '   T�41 727 + 7
>: :3
7 9
H
  ��
��	���Codepointmax	mathipairs z y  z  z y x  z y x x z tsy z x UNSIGNED_BYTEREDTEXTURE_2DTexSubImage2D	BindVerticesTexturetexturesBearingYBearingXSpacingstbtt_GetCodepointHMetricsNewremove
tableAddGlyph
pairsglyphs	Copy
TableUtilityCreateTexturetexture_cache_idtexture_heightrow_heighttexture_ytexture_widthTexturePaddingtexture_xstbtt_MakeCodepointBitmapunsigned char[0]unsigned char[?]tonumber
scale	font stbtt_GetCodepointBitmapBoxint[1]new 				
 !!!!"""""$$$%++++,,,,----.......000000111111222224444577888888999::::;;;;;<<<<<:>>@@AAAABBBBCCEEEEFFFFFGGGGHHKKKKLLLLLMMPPPPQQQQQRRTTTTUUUUUVVVVWWYYZZZZZ[[[[[\]^^^^____````^^cccddddddfffggggggggijjlffi tt Font Coeus Glyph gl GL self  �glyph  �x1 	�y1  �x2 �y2  �width �height �bytes �data �data  cache_id & glyphs   i v  g �advance �lsb �texture �n  i v   `   	!�7  6  T�H   7  @ AddGlyphglyphsself  
glyph  
found  U   
�7  77 7  T�) T�) H handletexturea  b   �
���J2   T�'   T�'   T�'  	 
   7  >'  +  777 >T�  7  >AN�2  '  +  777 >Tg�4 7% > T�	 T�	 4 7	  7
 >  7 > >

	 TP�  7  >7  T:� 4 7>T� 7	9 7
9 79 79 79AN�  T� 677 T	�2  :'  :7: 9 6 677 :7		4 7% > T� T�4 7		>	 AN�4 7 1 >	 T�	 
'  	 T	�  7
 >  7 >     0  �F � 	sort
table Spacing
count
starttexturetszyxVerticesipairsTextureGetLineHeightGetHeight
floor	math
	bytestringGetGlyphUTF8IterateUnicodeUtilityGetBaseline���� 			
 !!!!!""""""####%%%%&&&&)))))))))+,--..///222222222557777777788888===?=AABEFFFGGGGGGGGGIIIIIICoeus self  �text  �extra_spacing  �offset_x  �offset_y  �draws �extra_spacing �offset_x �offset_y �dx �dy �line_height �max_width �  codepoint vertex_data �vertex_id �j j jcodepoint gglyph Lstart_id 9  i v  draw $height +     �G  self  text   $   
�7  H heightself   )   
�7  H line_heightself   &   
�7  H baselineself   �  / F� �4   % > C 7777777777	7
77	
7		7		 7
>
3 2  :2  :>
2
 3 ;3 ;3 ;3 ;3 ;3 ;3 ;3 ;3 ;	:
' :
1 :
1  :
1" :!
1$ :#
1& :%
1( :'
1* :)
1, :+
1. :-
0  �H
  GetBaseline GetLineHeight GetHeight GetWidth GenerateMesh GetGlyph AddGlyph CreateTexture 	_newTexturePadding  ��  ��  ��  ��  ��  ��  ��  ��  ��TextureSizestexturesglyphs texture_y height
scaletexture_size_indextexture_cache_id texture_x baseline line_height	fontascent texture_width descent row_height texture_height 
Class
Glyph	TextTextureGraphicsGLglOpenGLstdio_stb_truetypeBindingsOOPUtilityffirequire             	            ' '  ) ) * * * * + + + + , , , , - - - - . / 0 0 K 2 } M �  � � ?� CAGEKIOMQQffi CCoeus BOOP @tt >stdio <OpenGL :gl 9GL 8Texture 6Glyph 3Font 	*  ]==])
Coeus:AddVFSFile('Graphics.Text.Glyph', [==[LJ �local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local Glyph = OOP:Class() {
	Texture = false,
	Vertices = false,
	Codepoint = 0,
	Spacing = 0,
	BearingX = 0
}

return Glyph�   	  C  7  7 7>3 >H  TextureBearingX Spacing VerticesCodepoint 
ClassOOPUtilityCoeus OOP Glyph   ]==])
Coeus:AddVFSFile('Graphics.Text.TextRenderer', [==[LJ �local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local OpenGL		= Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local Mesh	= Coeus.Graphics.Mesh
local Material		= Coeus.Graphics.Material

local TextRenderer = OOP:Class(Material) {
	context = false,
	text = "",
	font = false,

	width = 0,
	height = 0,

	draws = false
}

function TextRenderer:_new(context)
	self.context = context
	self.Mesh = Mesh:New()

	self.Shader = Coeus.Graphics.Shader:New(context, [[
		#version 330
		layout(location=0) in vec3 position;
		layout(location=1) in vec2 texcoord_;
		layout(location=2) in vec3 normal;

		uniform mat4 ModelViewProjection;

		out vec2 texcoord;

		void main() {
			gl_Position = ModelViewProjection * vec4(position, 1.0);
			texcoord = texcoord_;
		}
		]],[[
		#version 330
		
		layout(location=0) out vec4 FragColor;

		uniform sampler2D FontAtlas;

		in vec2 texcoord;

		void main() {
			float brightness = texture(FontAtlas, texcoord).x;
			//if (brightness == 0) discard;
			FragColor = vec4(vec3(1.0) * brightness, 1.0);
		}
	]])
end

function TextRenderer:RebuildText()
	local text = self.text
	local vertex_data, draws, width, height = self.font:GenerateMesh(text)
	self.Mesh:SetData(vertex_data, nil, Mesh.DataFormat.PositionTexCoordInterleaved)
	self.width = width
	self.height = height

	self.draws = draws
end

function TextRenderer:Use()
	Material.Use(self)
end

function TextRenderer:Render()
	if not self.draws then return end
	gl.BlendFunc(GL.ONE, GL.ONE)
	gl.BindVertexArray(self.Mesh.vao)
	local camera = self.context.ActiveCamera
	local model = self.entity:GetRenderTransform()
	local view_projection = camera:GetViewProjection()
	local mvp = view_projection * model
	
	self.Shader:Use()
	for i, v in ipairs(self.draws) do
		self.Shader:Send("FontAtlas", v.texture)
		self.Shader:Send("ModelViewProjection", mvp)
		gl.DrawArrays(GL.TRIANGLES, v.start, v.count)
	end
	gl.BlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
end

return TextRenderer�  .!:  +   7>: + 77 7 % % >: G  � ��		#version 330
		
		layout(location=0) out vec4 FragColor;

		uniform sampler2D FontAtlas;

		in vec2 texcoord;

		void main() {
			float brightness = texture(FontAtlas, texcoord).x;
			//if (brightness == 0) discard;
			FragColor = vec4(vec3(1.0) * brightness, 1.0);
		}
	�		#version 330
		layout(location=0) in vec3 position;
		layout(location=1) in vec2 texcoord_;
		layout(location=2) in vec3 normal;

		uniform mat4 ModelViewProjection;

		out vec2 texcoord;

		void main() {
			gl_Position = ModelViewProjection * vec4(position, 1.0);
			texcoord = texcoord_;
		}
		GraphicsShaderNew	Meshcontext  !Mesh Coeus self  context   � 
 N97  7  7 >7  7 )	  +
  7

7

>: : :	 G  �
drawsheight
width PositionTexCoordInterleavedDataFormatSetData	MeshGenerateMesh	font	textMesh self  text vertex_data draws  width  height   :  C+  7   >G  �UseMaterial self   �  ?�G7    T�G  +  7+ 7+ 7>+  77 7>7 77  7	> 7
> 7  7>4 7  >T�7
 
 7

% 7	>
7
 
 7

%  >
+
  7

+ 77	7	>
AN�+  7+ 7+ 7>G  ��ONE_MINUS_SRC_ALPHASRC_ALPHA
count
startTRIANGLESDrawArraysModelViewProjectiontextureFontAtlas	SendipairsUseShaderGetViewProjectionGetRenderTransformentityActiveCameracontextvao	MeshBindVertexArrayONEBlendFunc
draws				





gl GL self  @camera -model )view_projection &mvp %  i v   � 
  ^ YC  7  77 7777 77 7 7		 >3
 >1 :1 :1 :1 :0  �H  Render Use RebuildText 	_new context	font	textheight 
draws
width 
ClassMaterial	MeshGraphicsGLglOpenGLBindingsOOPUtility		7A9ECWGYYCoeus OOP OpenGL gl GL Mesh Material TextRenderer 
  ]==])
Coeus:AddVFSFile('Graphics.Texture', [==[LJ �local ffi = require("ffi")
local Coeus			= (...)
local oop			= Coeus.Utility.OOP 

local ImageData 	= Coeus.Asset.Image.ImageData

local OpenGL		= Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local Texture = oop:Class() {
	context = false,
	unit = -1,
	handle = -1,

	filter_min = 1,
	filter_mag = 1,
	mipmapping = false,

	wrap_s = 0,
	wrap_t = 0,

	gl_target = GL.TEXTURE_2D
}

Texture.Filter = {
	Nearest		= 0,
	Linear		= 1
}
Texture.Wrap = {
	Wrap 	= 0,
	Clamp	= 1
}


function Texture:_new(image_data)
	local handle = ffi.new('unsigned int[1]')
	gl.GenTextures(1, handle)
	self.handle = handle[0]

	self:Bind()
	self:UpdateTextureParameters()
	self:SetData(image_data)
end

function Texture:UpdateTextureParameters()
	local filter_lookup = {
		[true] = {
			[Texture.Filter.Nearest] = GL.NEAREST_MIPMAP_NEAREST,
			[Texture.Filter.Linear] = GL.NEAREST_MIPMAP_LINEAR
		},
		[false] = {
			[Texture.Filter.Nearest] = GL.NEAREST,
			[Texture.Filter.Linear] = GL.LINEAR
		}
	}
	local min = filter_lookup[self.mipmapping][self.filter_min] or GL.NEAREST
	local mag = filter_lookup[self.mipmapping][self.filter_max] or GL.NEAREST

	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, min)
	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, mag)

	if self.wrap_s == Texture.Wrap.Wrap then
		gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.REPEAT)
	else
		gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
	end
	if self.wrap_t == Texture.Wrap.Wrap then
		gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.REPEAT)
	else
		gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)
	end
end

function Texture:SetData(image_data)
	local width = image_data.Width
	local height = image_data.Height
	local format_lookup = {
		[ImageData.Format.RGBA] = {
			internal 	= GL.RGBA,
			format 		= GL.RGBA,
			type		= GL.UNSIGNED_BYTE
		},
		[ImageData.Format.Depth] = {
			internal	= GL.DEPTH_COMPONENT,
			format 		= GL.DEPTH_COMPONENT,
			type		= GL.UNSIGNED_BYTE
		},
		[ImageData.Format.DepthStencil] = {
			internal	= GL.DEPTH_STENCIL,
			format 		= GL.DEPTH_STENCIL,
			type		= GL.UNSIGNED_BYTE
		}
	}
	local format = format_lookup[image_data.format]
	local dat = nil

	if image_data.image then
		dat = image_data.image
	end
	print(dat, width, height)
	gl.TexImage2D(GL.TEXTURE_2D, 0, format.internal, width, height, 0, format.format, format.type, dat)
end

function Texture:Destroy()
	local handle = ffi.new('unsigned int[1]')
	handle[0] = self.handle
	gl.DeleteTextures(1, handle)
end

function Texture:Bind(unit)
	if unit then
		self.unit = unit
		gl.ActiveTexture(unit)
	end
	gl.BindTexture(self.gl_target, self.handle)
end

function Texture:Unbind()
	gl.ActiveTexture(self.unit)
	gl.BindTexture(self.gl_target, 0)
	self.unit = -1
end

return Texture�  ;$+  7 % >+ 7'  >8 :   7 >  7 >  7  >G   ��SetDataUpdateTextureParameters	BindhandleGenTexturesunsigned int[1]newffi gl self  image_data  handle  �  r�.2 2 +  7 7+ 79+  7 7+ 79) 92 +  7 7+ 79+  7 7+ 79) 97 67 6  T�+ 77 67	 6  T�+ 7+ 7
+ 7+ 7 >+ 7
+ 7+ 7 >7 +  77 T
�+ 7+ 7+ 7+ 7>T	�+ 7+ 7+ 7+ 7>7 +  77 T
�+ 7+ 7+ 7+ 7>T	�+ 7+ 7+ 7+ 7>G  ���TEXTURE_WRAP_Twrap_tCLAMP_TO_EDGEREPEATTEXTURE_WRAP_STexParameteri	Wrapwrap_sTEXTURE_MAG_FILTERTEXTURE_MIN_FILTERTEXTURE_2DTexParameterffilter_maxfilter_minmipmappingLINEARNEARESTNEAREST_MIPMAP_LINEARLinearNEAREST_MIPMAP_NEARESTNearestFilter		Texture GL gl self  sfilter_lookup  Smin Kmag C �  G�K7 72 +  773 + 7:+ 7:+ 7:9+  77	3 + 7
:+ 7
:+ 7:9+  773 + 7:+ 7:+ 7:976)  7  T�74  	 
 >+ 7+ 7'	  7
  '  77 >
G  ���TEXTURE_2DTexImage2D
print
image  DEPTH_STENCILDepthStencil  DEPTH_COMPONENT
Depth	typeUNSIGNED_BYTEformatinternal  	RGBAFormatHeight
Width				


ImageData GL gl self  Himage_data  Hwidth Fheight Eformat_lookup +format dat  �  $i+  7 % >7 ; + 7'  >G   ��DeleteTextureshandleunsigned int[1]newffi gl self  handle  �  o  T�:  +  7 >+  77 7 >G  �handlegl_targetBindTextureActiveTexture	unitgl self  unit   |  w+  7 7 >+  77 '  >'��: G  �gl_targetBindTexture	unitActiveTexturegl self   � 
  &d }4   % > C 77777777	7
 7>3 7	:	>3 :3 :1 :1 :1 :1 :1 :1 :0  �H  Unbind 	Bind Destroy SetData UpdateTextureParameters 	_new 
Clamp	Wrap 	Wrap LinearNearest Filtergl_targetTEXTURE_2D filter_minfilter_magwrap_t mipmappingcontextwrap_s handle����	unit����
ClassGLglOpenGLBindingsImageData
Image
AssetOOPUtilityffirequire	!,$I.gKmiuo{w}}ffi #Coeus "oop  ImageData OpenGL gl GL Texture   ]==])
Coeus:AddVFSFile('Graphics.Window', [==[LJ �,local Coeus = (...)
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL

local KeyboardContext = Coeus.Input.KeyboardContext
local MouseContext = Coeus.Input.MouseContext
local GraphicsContext = Coeus.Graphics.GraphicsContext

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local Event = Coeus.Utility.Event

local Window = OOP:Class() {
	title = "Coeus Window",

	x = 0,
	y = 0,

	width = 640,
	height = 480,

	fullscreen = false,
	resizable = false,
	monitor = false,
	vsync_enabled = false,

	handle = false,

	Keyboard = false,
	Mouse = false,
	Graphics = false,

	Resized 	= Event:New(),
	Moved 		= Event:New(),
	Closed 		= Event:New(),
	
	FocusGained = Event:New(),
	FocusLost 	= Event:New(),

	Minimized 	= Event:New(),
	Restored	= Event:New()
}

function Window:_new(title, width, height, mode)
	self.width = width or self.width
	self.height = height or self.height
	self.title = title or self.title

	self.fullscreen = mode and mode.fullscreen or self.fullscreen

	local monitor = mode and mode.monitor or self.mode
	local resizable = mode and mode.resizable or self.resizable
	local vsync_enabled = mode and mode.vsync or self.vsync

	local monitorobj

	if monitor then
		local count = ffi.new("int[1]")
		local monitors = glfw.GetMonitors(count)

		if (monitor <= count[0]) then
			monitorobj = monitors[monitor - 1]
		else
			print("Monitor cannot be greater than the number of connected monitors!")
			print("Reverting to primary monitor...")
			monitorobj = glfw.GetPrimaryMonitor()
		end
	else
		monitorobj = glfw.GetPrimaryMonitor()
	end

	glfw.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
	glfw.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL.TRUE)
	glfw.WindowHint(GLFW.OPENGL_DEBUG_CONTEXT, GL.TRUE)

	glfw.WindowHint(GLFW.DEPTH_BITS, 24)

	glfw.WindowHint(GLFW.RESIZABLE, resizable and GL.TRUE or GL.FALSE)

	local mode = glfw.GetVideoMode(monitorobj)[0]
	width = width or mode.width
	height = height or mode.height

	local window
	if fullscreen then
		if fullscreen == "desktop" then
			glfw.WindowHint(GLFW.DECORATED, GL.FALSE)

			window = glfw.CreateWindow(width, height, title, nil, nil)
		else
			window = glfw.CreateWindow(width, height, title, monitorobj, nil)
		end
	else
		window = glfw.CreateWindow(width, height, title, nil, nil)
	end

	if window == nil then
		error("GLFW failed to create a window!")
	end

	self.handle = window
	glfw.SetWindowSizeCallback(self.handle, function(handle, width, height)
		self.Resized:Fire(width, height)
		self.width = width
		self.height = height
	end)
	glfw.SetWindowCloseCallback(self.handle, function(handle)
		self.Closed:Fire()
	end)
	glfw.SetWindowPosCallback(self.handle, function(handle, x, y)
		self.Moved:Fire(x, y)
		self.x = x
		self.y = y
	end)
	glfw.SetWindowFocusCallback(self.handle, function(handle, focus)
		if focus == GL.TRUE then
			self.FocusGained:Fire()
		else
			self.FocusLost:Fire()
		end
	end)
	glfw.SetWindowIconifyCallback(self.handle, function(handle, iconify)
		if iconify == GL.TRUE then
			self.Minimized:Fire()
		else
			self.Restored:Fire()
		end
	end)

	local xp, yp = ffi.new("int[1]"), ffi.new("int[1]")
	glfw.GetWindowPos(self.handle, xp, yp)
	self.x = xp[0]
	self.y = yp[0]
	glfw.GetWindowSize(self.handle, xp, yp)
	self.width = xp[0]
	self.height = yp[0]

	self:Use()
	gl.Enable(GL.DEPTH_TEST)
	gl.DepthFunc(GL.LEQUAL)

	gl.FrontFace(GL.CCW)
	gl.Enable(GL.CULL_FACE)
	gl.CullFace(GL.BACK)
	gl.DepthMask(GL.TRUE)
	gl.Enable(GL.BLEND)
	

	self:SetVSyncEnabled(self.vsync_enabled)

	self.Keyboard = KeyboardContext:New(self)
	self.Mouse = MouseContext:New(self)
	self.Graphics = GraphicsContext:New(self)
end

function Window:Use()
	glfw.MakeContextCurrent(self.handle)
	gl.Viewport(0, 0, self.width, self.height)
end

function Window:GetSize()
	return self.width, self.height
end
function Window:SetSize(width, height)
	glfw.SetWindowSize(self.handle, width, height)
end

function Window:GetPosition()
	return self.x, self.y
end
function Window:SetPosition(x, y)
	glfw.SetWindowPos(self.handle, x, y)
end

function Window:GetVSyncEnabled()
	return self.vsync_enabled
end
function Window:SetVSyncEnabled(value)
	local old_handle = glfw.GetCurrentContext()

	glfw.MakeContextCurrent(self.handle)
	glfw.SwapInterval(value and 1 or 0)
	glfw.MakeContextCurrent(old_handle)

	self.vsync_enabled = not not value
end

function Window:GetTitle(title)
	return self.title
end
function Window:SetTitle(title)
	self.title = title

	glfw.SetWindowTitle(self.handle, title)
end

function Window:HasFocus()
	return glfw.GetWindowAttrib(self.handle, GLFW.FOCUSED) == 1
end

function Window:IsMinimized()
	return glfw.GetWindowAttrib(self.handle, GLFW.ICONIFIED) == 1
end

function Window:IsClosing()
	return glfw.WindowShouldClose(self.handle) ~= 0
end
function Window:Close()
	glfw.SetWindowShouldClose(self.handle, 1)
end

function Window:PollEvents()
	glfw.PollEvents()
end
function Window:WaitEvents()
	glfw.WaitEvents()
end

function Window:PreRender()
	self:Use()
	gl.ClearDepth(1.0)
	gl.ClearColor(0, 0, 0, 1)
	gl.Clear(bit.bor(tonumber(GL.COLOR_BUFFER_BIT), tonumber(GL.DEPTH_BUFFER_BIT)))
end

function Window:PostRender()
	glfw.SwapBuffers(self.handle)
end

function Window:Update(dt)
	self:PollEvents()
	self.Mouse:Update(dt)
end

return Window�  ,o+  7  7  >+  :+  :G   �height
width	FireResizedself handle  width  height   E  t+  7  7>G   �	FireClosedself handle   n  #w+  7  7  >+  :+  :G   �yx	Fire
Movedself handle  x  y   �  *|+  7  T�+ 7 7>T�+ 7 7>G    �FocusLost	FireFocusGained	TRUEGL self handle  focus   �  ,�+  7  T�+ 7 7>T�+ 7 7>G    �Restored	FireMinimized	TRUEGL self handle  iconify   �A��3p T�7  :   T�7 :  T�7 :   T�7  T�7 :   T�7  T�7   T�7  T�7   T�7  T�7 )    T	�+	  7		%
	 >	+
 7


	 >
8 	 T� 6
T�4 % >4 % >+ 7> T	�+	 7		>		 +	 7		+
 7

' >	+	 7		+
 7

' >	+	 7		+
 7

+ 7>	+	 7		+
 7

+ 7>	+	 7		+
 7

+ 7>	+	 7		+
 7

' >	+	 7		+
 7

  T�+ 7  T�+ 7>	+	 7		
 >	8	 	  T
�7 	  T
�7	)
  4   T�4  T�+ 7+ 7+ 7>+ 7   * >
 T�+ 7    )  >
 T�+ 7   * >
 
  T�4 % >:
  + 7!7  1" >+ 7#7  1$ >+ 7%7  1& >+ 7'7  1( >+ 7)7  1* >+  7%	 >+  7%	 >+ 7+7    >8 :, 8 :- + 7.7    >8 :  8 :   7/ >+ 70+ 71>+ 72+ 73>+ 74+ 75>+ 70+ 76>+ 77+ 78>+ 79+ 7>+ 70+ 7:>  7; 7< >+  7>  >:= +  7>  >:? +  7>  >:@ 0  �G  ��	��
����Graphics
MouseNewKeyboardvsync_enabledSetVSyncEnabled
BLENDDepthMask	BACKCullFaceCULL_FACECCWFrontFaceLEQUALDepthFuncDEPTH_TESTEnableUseGetWindowSizeyxGetWindowPos SetWindowIconifyCallback SetWindowFocusCallback SetWindowPosCallback SetWindowCloseCallback SetWindowSizeCallbackhandle$GLFW failed to create a window!
errorCreateWindowDECORATEDdesktopGetVideoMode
FALSERESIZABLEDEPTH_BITSOPENGL_DEBUG_CONTEXT	TRUEOPENGL_FORWARD_COMPATOPENGL_CORE_PROFILEOPENGL_PROFILECONTEXT_VERSION_MINORCONTEXT_VERSION_MAJORWindowHintGetPrimaryMonitor$Reverting to primary monitor...EMonitor cannot be greater than the number of connected monitors!
printGetMonitorsint[1]new
vsyncresizable	modemonitorfullscreen
titleheight
width						       """"""$$$$$$$$$$$$$&&&&&'''(((*+++,,,-------/////////11111111124444444477888;<<<@<AAACADDDHDIIIOIPPPVPXXXXXXXXYYYYYYZZ[[\\\\\\]]^^```aaaaabbbbbdddddeeeeefffffggggghhhhhkkkkmmmmmmnnnnnnooooooppffi glfw GLFW GL gl KeyboardContext MouseContext GraphicsContext self  �title  �width  �height  �mode  �monitor �resizable �vsync_enabled �monitorobj �count monitors mode N�window �xp ORyp  R �  �+  7 7 >+ 7'  '  7 7 >G  �
�height
widthViewporthandleMakeContextCurrentglfw gl self   /   �7  7 F height
widthself   c  %�+  7 7   >G  �handleSetWindowSizeglfw self  width  height   &   �7  7 F yxself   Y  �+  7 7   >G  �handleSetWindowPosglfw self  x  y   +   
�7  H vsync_enabledself   �  9�+  7 >+  77 >+  7  T�' T�'  >+  7 >  : G  �vsync_enabledSwapIntervalhandleMakeContextCurrentGetCurrentContextglfw self  value  old_handle  +   �7  H 
titleself  title   a  �:  +  77  >G  �handleSetWindowTitle
titleglfw self  title   } �+  7 7 + 7>  T�) T�) H �	�FOCUSEDhandleGetWindowAttribglfw GLFW self    �+  7 7 + 7>  T�) T�) H �	�ICONIFIEDhandleGetWindowAttribglfw GLFW self   f 
�+  7 7 >	  T�) T�) H �handleWindowShouldClose glfw self   T  �+  7 7 ' >G  �handleSetWindowShouldCloseglfw self   9  �+  7 >G  �PollEventsglfw self   9  �+  7 >G  �WaitEventsglfw self   � 	 +�  7  >+  7' >+  7'  '  '  ' >+  74 74 + 7>4 + 7> = = G  
��DEPTH_BUFFER_BITCOLOR_BUFFER_BITtonumberborbit
ClearClearColorClearDepthUsegl GL self   F  �+  7 7 >G  �handleSwapBuffersglfw self   ]   	�  7  >7  7 >G  Update
MousePollEventsself  
dt  
 �  @ _� �C  4  % >7 77 77 77 77 7	7
 777	7
77 7 7>3  7>: 7>: 7>: 7>: 7>: 7>: 7>:>1 :1 :1 :1! : 1# :"1% :$1' :&1) :(1+ :*1- :,1/ :.11 :013 :215 :417 :619 :81; ::1= :<1? :>0  �H  Update PostRender PreRender WaitEvents PollEvents 
Close IsClosing IsMinimized HasFocus SetTitle GetTitle SetVSyncEnabled GetVSyncEnabled SetPosition GetPosition SetSize GetSize Use 	_newRestoredMinimizedFocusLostFocusGainedClosed
MovedResizedNew 
Mouseheight�Keyboard
width�
titleCoeus WindowGraphicsresizablefullscreenmonitorvsync_enabledy handlex 
Class
EventGLgl	glfwGraphicsContextGraphicsMouseContextKeyboardContext
InputOpenGL	GLFWBindingsOOPUtilityffirequire		

(((())))****,,,,----////0000�3������������û������������������������Coeus ^ffi [OOP YGLFW WOpenGL UKeyboardContext SMouseContext QGraphicsContext Oglfw NGLFW Mgl LGL KEvent IWindow !(  ]==])
Coeus:AddVFSFile('Input.KeyboardContext', [==[LJ �local Coeus = (...)
local bit = require("bit")

local OOP = Coeus.Utility.OOP
local Event = Coeus.Utility.Event

local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
GLFW = GLFW.GLFW

local KeyboardContext = OOP:Class() {
	keys = {},

	KeyDown = Event:New(),
	KeyUp = Event:New(),

	TextInput = Event:New()
}

function KeyboardContext:_new(window)
	glfw.SetKeyCallback(window.handle, function(handle, key, scancode, action, mod)
		if action == GLFW.PRESS then
			self.keys[key] = true
			self.KeyDown:Fire(key)
		elseif action == GLFW.RELEASE then
			self.keys[key] = false
			self.KeyUp:Fire(key)
		end
	end)

	glfw.SetCharCallback(window.handle, function(handle, unicode)
		self.TextInput:Fire(unicode)
	end)
end

function KeyboardContext:IsKeyDown(key)
	if type(key) == "string" then
		key = key:upper()
		key = string.byte(key)
	end
	return self.keys[key] or false
end

return KeyboardContext�  R+  7  T�+ 7) 9+ 7 7 >T�+  7 T
�+ 7) 9+ 7 7 >G    �
KeyUpRELEASE	FireKeyDown	keys
PRESSGLFW self handle  key  scancode  action  mod   W   +  7  7 >G   �	FireTextInputself handle  unicode   � '+  7 71 >+  771 >0  �G  �� SetCharCallback handleSetKeyCallback	glfw GLFW self  window   �   "$4   > T	� 7> 4 7 > 7 6  T�) H 	keys	byte
upperstring	typeself  key   � 
  %b ,C  4  % >7 77 77 777 7>3	 2  :
	 7>:	 7>:	 7>:>1 :1 :0  �H  IsKeyDown 	_newTextInput
KeyUpKeyDownNew	keys  
Class	glfw	GLFWBindings
EventOOPUtilitybitrequire	"*$,,Coeus $bit !OOP Event GLFW glfw KeyboardContext   ]==])
Coeus:AddVFSFile('Input.MouseContext', [==[LJ �local Coeus = (...)
local ffi = require('ffi')
local bit = require('bit')

local OOP = Coeus.Utility.OOP
local Event = Coeus.Utility.Event

local OpenGL = Coeus.Bindings.OpenGL
local GL = OpenGL.GL
local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
GLFW = GLFW.GLFW

local MouseContext = OOP:Class() {
	window = false,
	buttons = {},

	last_x = 0,
	last_y = 0,

	prelock_x = 0,
	prelock_y = 0,
	lock = false,
	mouse_in = false,

	delta_x = 0,
	delta_y = 0,

	ButtonDown = Event:New(),
	ButtonUp = Event:New(),
	EnterWindow = Event:New(),
	LeaveWindow = Event:New()
}

function MouseContext:_new(window)
	self.window = window

	glfw.SetCursorEnterCallback(self.window.handle, function(handle, entered)
		if entered == GL.TRUE then
			self.mouse_in = true
			self.EnterWindow:Fire()
		else
			self.mouse_in = false
			self.LeaveWindow:Fire()
		end
	end)

	glfw.SetMouseButtonCallback(self.window.handle, function(handle, button, action, mod)
		button = button + 1

		if action == GLFW.PRESS then
			self.buttons[button] = true
			self.ButtonDown:Fire(button, modifiers)
		else
			self.buttons[button] = false
			self.ButtonUp:Fire(button, modifiers)
		end
	end)
end

function MouseContext:IsButtonDown(button)
	return self.buttons[button] or false
end

function MouseContext:GetPosition()
	return math.floor(self.x), math.floor(self.y)
end

function MouseContext:SetPosition(x, y)
	glfw.SetCursorPos(self.window.handle, x, y)
	self.x = x
	self.y = y
end

function MouseContext:GetDelta()
	return self.delta_x, self.delta_y
end

function MouseContext:SetLocked(locked)
	self.lock = locked
	if locked then
		self.prelock_x = self.x
		self.prelock_y = self.y
	else
		self:SetPosition(self.prelock_x, self.prelock_y)
	end
end
function MouseContext:IsLocked()
	return self.lock
end

function MouseContext:Update()
	local xp, yp = ffi.new("double[1]"), ffi.new("double[1]")
	glfw.GetCursorPos(self.window.handle, xp, yp)
	self.x, self.y = xp[0], yp[0]

	self.delta_x = self.x - self.last_x
	self.delta_y = self.y - self.last_y
	self.last_x = self.x
	self.last_y = self.y

	if self.lock and self.window:HasFocus() then
		glfw.SetInputMode(self.window.handle, GLFW.CURSOR, GLFW.CURSOR_DISABLED)
	else
		glfw.SetInputMode(self.window.handle, GLFW.CURSOR, GLFW.CURSOR_NORMAL)
	end

	if self.lock and not self.window:HasFocus() then
		self.delta_x = 0
		self.delta_y = 0
	end
end

return MouseContext�  2&+  7  T	�+ ) :+ 7 7>T�+ ) :+ 7 7>G    �LeaveWindow	FireEnterWindowmouse_in	TRUEGL self handle  entered   � I0
 +  7  T�+ 7) 9+ 7 7 4 >T�+ 7) 9+ 7 7 4 >G    �ButtonUpmodifiers	FireButtonDownbuttons
PRESS
GLFW self handle  button  action  mod   � -#:  +  77  71 >+  77  71 >0  �G  ��� SetMouseButtonCallback handleSetCursorEnterCallbackwindowglfw GL GLFW self  window   A   =7  6  T�) H buttonsself  button   N   	A4  77 >4  77 > E yx
floor	mathself  
 r  
E+  7 7 7  >: : G  �yxhandlewindowSetCursorPosglfw self  x  y   1   K7  7 F delta_ydelta_xself   �   O:    T�7 : 7 : T�  7 7 7 >G  SetPositionyprelock_yxprelock_x	lockself  locked   !   
X7  H 	lockself   �  Ii\+  7 % >+  7 % >+ 77 7  >8 8 : : 7 7 : 7 7
 :	 7 : 7 :
 7   T�7  7>  T
�+ 77 7+ 7+ 7>T	�+ 77 7+ 7+ 7>7   T
�7  7>  T�'  : '  :	 G  ���CURSOR_NORMALCURSOR_DISABLEDCURSORSetInputModeHasFocus	locklast_ydelta_ylast_xdelta_xyxhandlewindowGetCursorPosdouble[1]new








ffi glfw GLFW self  Jxp 	Ayp  A �  # ;� rC  4  % >4  % >7 77 77 777 7	7
7	
 7	>	3
 2  :
 7>:
 7>:
 7>:
 7>:
>	1
 :
	1
 :
	1
 :
	1
 :
	1
 :
	1
 :
	1
  :
	1
" :
!	0  �H	  Update IsLocked SetLocked GetDelta SetPosition GetPosition IsButtonDown 	_newLeaveWindowEnterWindowButtonUpButtonDownNewbuttons 	delta_y window	lockdelta_x last_y prelock_y mouse_inlast_x prelock_x 
Class	glfw	GLFWGLOpenGLBindings
EventOOPUtilitybitffirequire	

    ;#?=CAIEMKWOZXp\rrCoeus :ffi 7bit 4OOP 2Event 0OpenGL .GL -GLFW +glfw *MouseContext   ]==])
Coeus:AddVFSFile('Math.Matrix4', [==[LJ �2local Coeus = (...)
local oop = Coeus.Utility.OOP
local Vector3 = Coeus.Math.Vector3

local Matrix4 = oop:Class() {
	m = {}
}

function Matrix4:_new(values)
	if values then
		for i=1, 16 do
			self.m[i] = values[i]
		end
	else
		for i=1, 16 do
			self.m[i] = 0
		end
		self.m[1] = 1
		self.m[6] = 1
		self.m[11] = 1
		self.m[16] = 1
	end
end

function Matrix4.Manual(...)
	local vals = {...}
	local m = {}
	for i=1, 16 do
		m[i] = vals[i]
	end
	return Matrix4:New(m)
end

function Matrix4:GetInverse()
	local r = {}
	local m = self.m
	r[1] = m[6]*m[11]*m[16] - m[6]*m[15]*m[12] - m[7]*m[10]*m[16] + m[7]*m[14]*m[12] + m[8]*m[10]*m[15] - m[8]*m[14]*m[11]
	r[2] = -m[2]*m[11]*m[16] + m[2]*m[15]*m[12] + m[3]*m[10]*m[16] - m[3]*m[14]*m[12] - m[4]*m[10]*m[15] + m[4]*m[14]*m[11]
	r[3] = m[2]*m[7]*m[16] - m[2]*m[15]*m[8] - m[3]*m[6]*m[16] + m[3]*m[14]*m[8] + m[4]*m[6]*m[15] - m[4]*m[14]*m[7]
	r[4] = -m[2]*m[7]*m[12] + m[2]*m[11]*m[8] + m[3]*m[6]*m[12] - m[3]*m[10]*m[8] - m[4]*m[6]*m[11] + m[4]*m[10]*m[7]

	r[5] = -m[5]*m[11]*m[16] + m[5]*m[15]*m[12] + m[7]*m[9]*m[16] - m[7]*m[13]*m[12] - m[8]*m[9]*m[15] + m[8]*m[13]*m[11]
	r[6] = m[1]*m[11]*m[16] - m[1]*m[15]*m[12] - m[3]*m[9]*m[16] + m[3]*m[13]*m[12] + m[4]*m[9]*m[15] - m[4]*m[13]*m[11]
	r[7] = -m[1]*m[7]*m[16] + m[1]*m[15]*m[8] + m[3]*m[5]*m[16] - m[3]*m[13]*m[8] - m[4]*m[5]*m[15] + m[4]*m[13]*m[7]
	r[8] = m[1]*m[7]*m[12] - m[1]*m[11]*m[8] - m[3]*m[4]*m[12] + m[3]*m[9]*m[8] + m[4]*m[5]*m[11] - m[4]*m[9]*m[7]

	r[9] = m[5]*m[10]*m[16] - m[5]*m[14]*m[12] - m[6]*m[9]*m[16] + m[6]*m[13]*m[12] + m[8]*m[9]*m[14] - m[8]*m[13]*m[10]
	r[10] = -m[1]*m[10]*m[16] + m[1]*m[14]*m[12] + m[2]*m[9]*m[16] - m[2]*m[13]*m[12] - m[4]*m[9]*m[14] + m[4]*m[13]*m[10]
	r[11] = m[1]*m[6]*m[16] - m[1]*m[14]*m[8] - m[2]*m[5]*m[16] + m[2]*m[13]*m[8] + m[4]*m[5]*m[14] - m[4]*m[13]*m[6]
	r[12] = -m[1]*m[6]*m[12] + m[1]*m[10]*m[8] + m[2]*m[5]*m[12] - m[2]*m[9]*m[8] - m[4]*m[5]*m[10] + m[4]*m[9]*m[6]

	r[13] = -m[5]*m[10]*m[15] + m[5]*m[14]*m[11] + m[6]*m[9]*m[15] - m[6]*m[13]*m[11] - m[7]*m[9]*m[14] + m[7]*m[13]*m[10]
	r[14] = m[1]*m[10]*m[15] - m[1]*m[14]*m[11] - m[2]*m[9]*m[15] + m[2]*m[13]*m[11] + m[3]*m[9]*m[14] - m[3]*m[13]*m[10]
	r[15] = -m[1]*m[6]*m[15] + m[1]*m[14]*m[7] + m[2]*m[5]*m[15] - m[2]*m[13]*m[7] - m[3]*m[5]*m[14] + m[3]*m[13]*m[6]
	r[16] = m[1]*m[6]*m[11] - m[1]*m[10]*m[7] - m[2]*m[5]*m[11] + m[2]*m[9]*m[7] + m[3]*m[5]*m[10] - m[3]*m[9]*m[6]

	local det = m[1]*r[1] + m[2]*r[5] + m[3]*r[9] + m[4]*r[13]

	for i=1, 16 do
		r[i] = r[i] / det
	end

	return Matrix4:New(r)
end

function Matrix4.Multiply(b, a)
	local a = a.m
	local b = b.m
	local r = {}
	r[1] = a[1] * b[1] + a[2] * b[5] + a[3] * b[9] + a[4] * b[13]
	r[2] = a[1] * b[2] + a[2] * b[6] + a[3] * b[10] + a[4] * b[14]
	r[3] = a[1] * b[3] + a[2] * b[7] + a[3] * b[11] + a[4] * b[15]
	r[4] = a[1] * b[4] + a[2] * b[8] + a[3] * b[12] + a[4] * b[16]

	r[5] = a[5] * b[1] + a[6] * b[5] + a[7] * b[9] + a[8] * b[13]
	r[6] = a[5] * b[2] + a[6] * b[6] + a[7] * b[10] + a[8] * b[14]
	r[7] = a[5] * b[3] + a[6] * b[7] + a[7] * b[11] + a[8] * b[15]
	r[8] = a[5] * b[4] + a[6] * b[8] + a[7] * b[12] + a[8] * b[16]

	r[9] = a[9] * b[1] + a[10] * b[5] + a[11] * b[9] + a[12] * b[13]
	r[10] = a[9] * b[2] + a[10] * b[6] + a[11] * b[10] + a[12] * b[14]
	r[11] = a[9] * b[3] + a[10] * b[7] + a[11] * b[11] + a[12] * b[15]
	r[12] = a[9] * b[4] + a[10] * b[8] + a[11] * b[12] + a[12] * b[16]

	r[13] = a[13] * b[1] + a[14] * b[5] + a[15] * b[9] + a[16] * b[13]
	r[14] = a[13] * b[2] + a[14] * b[6] + a[15] * b[10] + a[16] * b[14]
	r[15] = a[13] * b[3] + a[14] * b[7] + a[15] * b[11] + a[16] * b[15]
	r[16] = a[13] * b[4] + a[14] * b[8] + a[15] * b[12] + a[16] * b[16]

	return Matrix4:New(r)
end

function Matrix4:GetUpVector()
	return Vector3:New(self.m[5], self.m[6], self.m[7])
end

function Matrix4:GetRightVector()
	return Vector3:New(self.m[1], self.m[2], self.m[3])
end

function Matrix4:GetForwardVector()
	return Vector3:New(self.m[9], self.m[10], self.m[11])
end

function Matrix4:TransformPoint(vec)
	--This function may not be correct (or at least what is expected.)
	--Further investigation may be necessary
	local m = self.m
	local inv_w = 1 / (m[13] * vec.x + m[14] * vec.y + m[15] * vec.z + m[16])
	return Vector3:New(
		(m[1] * vec.x + m[2] * vec.y + m[3] * vec.z + m[4]) * inv_w,
		(m[5] * vec.x + m[6] * vec.y + m[7] * vec.z + m[8]) * inv_w,
		(m[9] * vec.x + m[10] * vec.y + m[11] * vec.z + m[12]) * inv_w
	)
end

function Matrix4:TransformVector3(vec)
	return Vector3:New(
		m[1] * vec.x + m[2] * vec.y + m[3] * vec.z,
		m[5] * vec.x + m[6] * vec.y + m[7] * vec.z,
		m[9] * vec.x + m[10] * vec.y + m[11] * vec.z
	)
end

function Matrix4:GetValues()
	return m
end

function Matrix4.GetTranslation(vector)
	if vector:GetClass() == Vector3 then
		local out = Matrix4:New()
		out.m[13] = vector.x
		out.m[14] = vector.y
		out.m[15] = vector.z
		return out
	else
		return Vector3:New(vector.m[13], vector.m[14], vector.m[15])
	end
end

function Matrix4.GetRotationX(angle)
	return Matrix4.Manual(
		1, 0, 0, 0,
		0, math.cos(angle), math.sin(angle), 0,
		0, -math.sin(angle), math.cos(angle), 0,
		0, 0, 0, 1
	)
end
function Matrix4.GetRotationY(angle)
	return Matrix4.Manual(
		math.cos(angle), 0, -math.sin(angle), 0,
		0, 1, 0, 0,
		math.sin(angle), 0, math.cos(angle), 0,
		0, 0, 0, 1
	)
end
function Matrix4.GetRotationZ(angle)
	return Matrix4.Manual(
		math.cos(angle), math.sin(angle), 0, 0,
		-math.sin(angle), math.cos(angle), 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	)
end

function Matrix4.GetScale(vector)
	return Matrix4.Manual(
		vector.x, 0, 0, 0,
		0, vector.y, 0, 0,
		0, 0, vector.z, 0,
		0, 0, 0, 1
	)
end

function Matrix4.GetPerspective(fov, near, far, aspect)
	local m = {}
	local y_scale = 1.0 / math.tan(math.rad(fov) / 2)
	local x_scale = y_scale / aspect
	local range =  near - far

	m[1] = x_scale
	m[2] = 0 
	m[3] = 0 
	m[4] = 0 

	m[5] = 0
	m[6] = y_scale
	m[7] = 0 
	m[8] = 0 

	m[9] = 0 
	m[10] = 0
	m[11] = (far + near) / range
	m[12] = -1 

	m[13] = 0 
	m[14] = 0
	m[15] = 2*far*near / range
	m[16] = 0

	return Matrix4:New(m)
end

Matrix4:AddMetamethods({
	__mul = function(a, b)
		if b:GetClass() == Vector3 then
			return Matrix4.TransformPoint(a, b)
		else
			return Matrix4.Multiply(a, b)
		end
	end

})

return Matrix4�    K	  T	�' ' ' I�7  69K�T�' ' ' I�7  '  9K�7  ' ;7  ' ;7  ' ;7  ' ;G  m			


self  !values  !  i   i  � 12  C  <  2  ' ' ' I�6 9K�+   7  @ �New����Matrix4 vals m   i  � 	 ��"2  7  88 8 88 8 88
 8 88 8 88
 8 88 8 ;8 8 8 88 8 88
 8 88 8 88
 8 88 8 ;88 8 88 8 88 8 88 8 88 8 88 8 ;8 8 8 88 8 88 8 88
 8 88 8 88
 8 ;8 8 8 88 8 88	 8 88 8 88	 8 88 8 ;88 8 88 8 88	 8 88 8 88	 8 88 8 ;8 8 8 88 8 88 8 88 8 88 8 88 8 ;88 8 88 8 88 8 88	 8 88 8 88	 8 ;88
 8 88 8 88	 8 88 8 88	 8 88 8
 ;	8 8
 8 88 8 88	 8 88 8 88	 8 88 8
 ;
88 8 88 8 88 8 88 8 88 8 88 8 ;8 8 8 88
 8 88 8 88	 8 88 8
 88	 8 ;8 8
 8 88 8 88	 8 88 8 88	 8 88 8
 ;88
 8 88 8 88	 8 88 8 88	 8 88 8
 ;8 8 8 88 8 88 8 88 8 88 8 88 8 ;88 8 88
 8 88 8 88	 8 88 8
 88	 8 ;88 88 88	 88 ' ' ' I�6!9K�+   7 @ �Newm																																				




































Matrix4 self  �r �m �det �  i  �
  ��B7 7  2  88 88 88	 88 ;88 88 88
 88 ;88 88 88 88 ;88 88 88 88 ;88 88 88	 88 ;88 88 88
 88 ;88 88 88 88 ;88 88 88 88 ;8	8 8
8 88	 88 ;	8	8 8
8 88
 88 ;
8	8 8
8 88 88 ;8	8 8
8 88 88 ;88 88 88	 88 ;88 88 88
 88 ;88 88 88 88 ;88 88 88 88 ;+   7 @ �Newm																















Matrix4 b  �a  �a �b �r � T  
]+   7 7 87 87 8@ �mNewVector3 self   T  
a+   7 7 87 87 8@ �mNewVector3 self   T  
e+   7 7 8	7 8
7 8@ �mNewVector3 self   � =_i
7  87 87 87 8 +   787 87 87 8 87 87	 	87	 	8 8	7	 	8	
7
 	
		8	7
 	
		8		 @ �Newzyxm	Vector3 self  >vec  >m <inv_w . � 	 .Du+   7 4 87 4 87 4 87 4 87 4 87 4 87 4 8	7 4 8
7 4 87 @ �zyxmNewVector3 self  /vec  /    
}4  H mself   �   @�
  7  >+   T�+  7>77 ;77 ;77 ;H T
�+   77 87 87 8@ G  ��zyxmNewGetClass
Vector3 Matrix4 vector  !out 
 �   1�+  7 ' '  '  '  '  4 7  >4 7	  >'	  '
  4 7  > 4 7  >'  '  '  '  ' @ �sincos	mathManualMatrix4 angle  ! �   1�+  7 4 7  >'  4 7  > '  '  ' '  '	  4
 7

  >
'  4 7  >'  '  '  '  ' @ �sincos	mathManualMatrix4 angle  ! �   1�+  7 4 7  >4 7  >'  '  4 7  > 4 7  >'  '	  '
  '  ' '  '  '  '  ' @ �sincos	mathManualMatrix4 angle  ! �  %�+  7 7 '  '  '  '  7 '  '	  '
  '  7 '  '  '  '  ' @ �zyxManualMatrix4 vector   � 2w�2  4  74  7  > >!;'  ;'  ;'  ;'  ;;'  ;'  ;'  ;	'  ;
!;'��;'  ;'  ;  !;'  ;+  	 7
 @ �Newradtan	math		Matrix4 fov  3near  3far  3aspect  3m 1y_scale 	(x_scale 'range & �  +� 7 >+   T�+ 7   @ T�+ 7   @ G  ��MultiplyTransformPointGetClassVector3 Matrix4 a  b   �  + 4W �C  7  77 7 7>3 2  :>1 :1
 :	1 :1 :1 :1 :1 :1 :1 :1 :1 :1 :1  :1" :!1$ :#1& :% 7'3) 1( :*>0  �H 
__mul   AddMetamethods GetPerspective GetScale GetRotationZ GetRotationY GetRotationX GetTranslation GetValues TransformVector3 TransformPoint GetForwardVector GetRightVector GetUpVector Multiply GetInverse Manual 	_newm  
ClassVector3	MathOOPUtility	 @"[B_]cagesi{u}����������ʯ��������Coeus 3oop 1Vector3 /Matrix4 (  ]==])
Coeus:AddVFSFile('Math.Quaternion', [==[LJ �)local Coeus = (...)
local oop = Coeus.Utility.OOP

local Matrix4 = Coeus.Math.Matrix4
local Vector3 = Coeus.Math.Vector3

--TURN BACK NOW! THIS FILE HAS BEEN KNOWN TO CAUSE IRREVERSIBLE BRAIN DAMAGE

local Quaternion = oop:Class() {
	x = 0,
	y = 0,
	z = 0,
	w = 1
}

function Quaternion:_new(x, y, z, w)
	self.x = x or self.x
	self.y = y or self.y
	self.z = z or self.z
	self.w = w or self.w
end

function Quaternion.FromMatrix4(matrix)
	local m = matrix.m
	local trace = m[1] + m[6] + m[11]
	local root

	if trace > 0 then
		root = math.sqrt(trace + 1)
		local w = root * 0.5
		root = 0.5 / root
		return Quaternion:New(
			(m[10] - m[7]) * root,
			(m[ 3] - m[9]) * root,
			(m[ 5] - m[2]) * root,
			w
		)
	else
		local i = 0
		if m[6] > m[1] then
			i = 1
		else
			i = 2
		end
		local n = {1, 2, 0}
		local j = n[i - 1]
		local k = n[j - 1]

		local ii, jj, kk, kj, jk, ji, ij, ki, ik
		if i == 0 then
			ii = m[1] -- i = 0
			jj = m[6] -- j = 1
			kk = m[11] --k = 2
			kj = m[10]; jk = m[7]
			ji = m[5]; ij = m[2]
			ki = m[9]; ik = m[3]
		elseif i == 1 then
			ii = m[6] -- i = 1
			jj = m[11] -- j = 2
			kk = m[1] -- k = 0
			kj = m[3]; jk = m[9]
			ji = m[10]; ij = m[7]
			ki = m[2]; ik = m[5]
		elseif i == 2 then
			ii = m[11] -- i = 2
			jj = m[1] -- j = 0
			kk = m[6] -- k = 1
			kj = m[2]; jk = m[5]
			ji = m[3]; ij = m[9]
			ki = m[7]; ik = m[10]
		end
		local root = math.sqrt(ii - jj - kk + 1)
		local quat = {}
		quat[i] = root * 0.5
		root = 0.5 / root

		local w = (kj - jk) * root
		quat[j] = (ji + ij) * root
		quat[k] = (ki + ik) * root
	end
end

function Quaternion:ToRotationMatrix()
	local tx = self.x + self.x
	local ty = self.y + self.y
	local tz = self.z + self.z
	
	local twx = tx * self.w
	local twy = ty * self.w
	local twz = tz * self.w

	local txx = tx * self.x
	local txy = ty * self.x
	local txz = tz * self.x

	local tyy = ty * self.y
	local tyz = tz * self.y
	local tzz = tz * self.z

	return Matrix4.Manual(
		1 - (tyy + tzz), txy - twz, txz + twy, 0,
		txy + twz, 1 - (txx + tzz), tyz - twx, 0,
		txz - twy, tyz + twx, 1 - (txx + tyy), 0,
		0, 0, 0, 1
	)
end

function Quaternion.FromAngleAxis(angle, axis)
	local half_angle = 0.5 * angle
	local sin = math.sin(half_angle)

	return Quaternion:New(sin * axis.x, sin * axis.y, sin * axis.z, math.cos(half_angle))
end

function Quaternion:ToAngleAxis()
	local len_sqr = (self.x^2) + (self.y^2) + (self.z^2)

	if len_sqr > 0 then
		local angle = 2 * math.acos(self.w)
		local inv_length = 1 / math.sqrt(len_sqr)
		return angle, Vector3:New(self.x * inv_length, self.y * inv_length, self.z * inv_length)
	else
		return 0, Vector3:new(1, 0, 0)
	end
end

function Quaternion.Slerp(a, b, alpha, shortest_path)
	local cos = a:Dot(b)
	local t = Quaternion:New()

	if cos < 0 and shortest_path == true then
		cos = -cos
		t = b * -1
	else
		t = b
	end

	if math.abs(cos) < (1 - 1e-3) then
		local sin = math.sqrt(1 - cos^2)
		local angle = math.atan2(sin, cos)
		local inv_sin = 1 / sin
		local coeff0 = math.sin((1 - alpha) * angle) * inv_sin
		local coeff1 = math.sin(alpha * angle) * inv_sin
		return a:Multiply(coeff0) + coeff1 * t
	else
		t = a:Multiply(1 - alpha) + alpha * t
		t:Normalize()
		return t
	end
end

function Quaternion.Dot(a, b)
	return a.w*b.w+a.x*b.x+a.y*b.y+a.z*b.z
end

function Quaternion:Norm()
	return (self.x^2) + (self.y^2) + (self.z^2) + (self.w^2)
end

function Quaternion:Normalize()
	local length = self:Norm()
	local factor = 1 / math.sqrt(length)
	self.x = self.x * factor
	self.y = self.y * factor
	self.z = self.z * factor
	self.w = self.w * factor
end

function Quaternion:GetInverse()
	local norm = self:GetNorm()
	if norm > 0 then
		local inv_norm = 1 / norm
		return Quaternion:New(-x * inv_norm, -y * inv_norm, -z * inv_norm, w * inv_norm)
	else
		return nil
	end
end

function Quaternion:TransformVector(vec)
	local uv, uuv
	local q_vec = Vector3:New(self.x, self.y, self.z)
	uv = q_vec:Cross(vec)
	uuv = q_vec:Cross(uv)
	uv = uv * (self.w * 2)
	uuv = uuv * 2

	return (vec + uv + uuv)
end

function Quaternion.Add(a, b)
	return Quaternion:New(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
end

function Quaternion.Subtract(a, b)
	return Quaternion:New(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)
end

function Quaternion.Multiply(a, b)
	if type(a) == 'number' then
		return Quaternion.Multiply(b, a)
	end
	if type(b) == 'number' then
		return Quaternion:New(a.x * b, a.y * b, a.z * b, a.w * b)
	end
	if b.GetClass and b:GetClass() == Vector3 then
		return a:TransformVector(b)
	end

	return Quaternion:New(
		a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
		a.w * b.y + a.y * b.w + a.z * b.x - a.x * b.z,
		a.w * b.z + a.z * b.w + a.x * b.y - a.y * b.x,
		a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
	)
end



Quaternion:AddMetamethods({
	__add = function(a, b)
		return Quaternion.Add(a, b)
	end,
	__sub = function(a, b)
		return Quaternion.Subtract(a, b)
	end,
	__mul = function(a, b)
		return Quaternion.Multiply(a, b)
	end,
	__div = function(a, b)
		return Quaternion.Divide(a, b)
	end
})

return Quaternion   ) T�7  :   T�7 :  T�7 :  T�7 : G  wzyxself  x  y  z  w   � g�:7  888)  '   T�4 7 > +   78
8 88			 8	8
	
	 		
 @ TC�'  88 T�' T�' 3  6 6* 	 T
�88	8
8
8888	8T�	  T
�88	8
88	8
888T�	 T	�88	8
8888	88
4 7	
 >2  9  9 9G  �   New	sqrt	mathm���� 			



  !!!""#$%&&''((())*+,--..//111111233466777888:Quaternion matrix  hm ftrace aroot `w 	i Bn :j 8k 6ii 5jj  5kk  5kj  5jk  5ji  5ij  5ki  5ik  5root )quat w  � 1�S7  7  7 7 7 7 7  7  7  7   7   7	   		7
  

7  7  +  7
 	'   '  	
 '  '  '  '  ' @ �Manualwzyx		

Matrix4 self  2tx .ty +tz (twx &twy $twz "txx  txy txz tyy tyz tzz  � Al  4  7 >+   77 7 7 4	  7		
 >	 ? �coszyxNewsin	math����Quaternion angle  axis  half_angle sin  � 
	/^s
7  ' #7 ' #7 ' #'   T�4 77 > 4 7 > +   77   7  7	  		> E T	�'  +   7' '  '  > E G  �newNew	sqrtw	acos	mathzyx
Vector3 self  0len_sqr $angle inv_length  � 	B�  7   >+   7>'   T� T�  T� 4 7 >(  T�4 7' #>4 7 	 >4	 7		
 

>	 		4
 7

 >
 

  7 	 > 
H T
�  7 >  7>H G  �NormalizeMultiplysin
atan2	sqrtabs	mathNewDot����ל�����Quaternion a  Cb  Calpha  Cshortest_path  Ccos >t :sin angle inv_sin coeff0 coeff1  l   �7  7  7 7 7 7 7 7 H zyxwa  b   k   �7  ' #7 ' #7 ' #7 ' #H wzyxself   �  /�  7  >4 7 > 7  : 7  : 7  : 7  : G  wzyx	sqrt	math	Normself  length factor  � 	?�  7  >'   T� +   74   4   4   4  @ T�)  H G  �wzyxNewGetNormQuaternion self  norm inv_norm  � 	B�	* +   7 7 7 7 > 7 >  7 > 7    H �w
CrosszyxNewVector3 self  vec  uv uuv  q_vec  } 	 $�+   7 7 77 77 77 7@ �wzyxNewQuaternion a  b   } 	 $�+   7 7 77 77 77 7@ �wzyxNewQuaternion a  b   � 

 h��4    > T�+  7   @ 4   > T�+   77  7  7  7  @ 7  T
� 7>+  T�  7	  @ +   77 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7	 	7 7	 	7 7	 	@ ��TransformVectorGetClasswzyxNewMultiplynumber	typeQuaternion Vector3 a  ib  i >  �+  7    @ �AddQuaternion a  b   C  �+  7    @ �SubtractQuaternion a  b   C  �+  7    @ �MultiplyQuaternion a  b   A  �+  7    @ �DivideQuaternion a  b   � 	 - 6f �C  7  77 77 7 7>3 >1 :1
 :	1 :1 :1 :1 :1 :1 :1 :1 :1 :1 :1  :1" :! 7#3% 1$ :&1' :(1) :*1+ :,>0  �H 
__div 
__mul 
__sub 
__add   AddMetamethods Multiply Subtract Add TransformVector GetInverse Normalize 	Norm Dot 
Slerp ToAngleAxis FromAngleAxis ToRotationMatrix FromMatrix4 	_new wz x y 
ClassVector3Matrix4	MathOOPUtility					QjSql}s�������������������������������Coeus 5oop 3Matrix4 1Vector3 /Quaternion *  ]==])
Coeus:AddVFSFile('Math.Vector3', [==[LJ �local Coeus = (...)
local oop = Coeus.Utility.OOP

local Vector3 = oop:Class() {
	x = 0,
	y = 0,
	z = 0
}

function Vector3:_new(x, y, z)
	self.x = x or self.x
	self.y = y or self.y
	self.z = z or self.z
end

function Vector3.Add(a, b)
	if type(a) == 'number' then
		return Vector3.Add(b, a)
	end
	if type(b) == 'number' then
		return Vector3:New(a.x + b, a.y + b, a.z + b)
	end
	return Vector3:New(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Vector3.Subtract(a, b)
	if type(b) == 'number' then
		return Vector3:New(a.x - b, a.y - b, a.z - b)
	end
	return Vector3:New(a.x - b.x, a.y - b.y, a.z - b.z)
end

function Vector3.Multiply(a, b)
	if type(a) == 'number' then
		return Vector3.Multiply(b, a)
	end
	if type(b) == 'number' then
		return Vector3:New(a.x * b, a.y * b, a.z * b)
	end
	return Vector3:New(a.x * b.x, a.y * b.y, a.z * b.z)
end

function Vector3.Divide(a, b)
	if type(b) == 'number' then
		return Vector3:New(a.x / b, a.y / b, a.z / b)
	end
	return Vector3:New(a.x / b.x, a.y / b.y, a.z / b.z)
end

function Vector3.Dot(a, b)
	return (a.x + b.x) + (a.y + b.y) + (a.z + b.z)
end
function Vector3.AngleBetween(a, b)
	return math.acos(Vector3.Dot(a, b))
end

function Vector3.Cross(a, b)
	return Vector3:New(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	)
end

function Vector3:LengthSquared()
	return (self.x^2)+(self.y^2)+(self.z^2)
end
function Vector3:Length()
	return math.sqrt(self:LengthSquared())
end

function Vector3.Unit(a)
	local length = a:Length()
	return a / length
end
function Vector3:Normalize()
	local len = self:Length()
	self.x = self.x / len
	self.y = self.y / len
	self.z = self.z / len
end

function Vector3.GetMidpoint(a, b)
	return (a + b) / 2
end

function Vector3.Lerp(a, b, alpha)
	return a + (alpha * (b - a))
end

function Vector3:GetValues()
	return {self.x, self.y, self.z}
end

Vector3:AddMetamethods({
	__add = function(a, b)
		return Vector3.Add(a, b)
	end,
	__sub = function(a, b)
		return Vector3.Subtract(a, b)
	end,
	__mul = function(a, b)
		return Vector3.Multiply(a, b)
	end,
	__div = function(a, b)
		return Vector3.Divide(a, b)
	end
})

return Vector3e   !
 T�7  :   T�7 :  T�7 : G  zyxself  x  y  z   �  &74    > T�+  7   @ 4   > T
�+   77 7 7 @ +   77 77 77 7@ �zyxNewAddnumber	typeVector3 a  'b  ' �  -4   > T
�+   77 7 7 @ +   77 77 77 7@ �zyxNewnumber	typeVector3 a  b   �  &7!4    > T�+  7   @ 4   > T
�+   77  7  7  @ +   77 7 7 7 7 7 @ �zyxNewMultiplynumber	typeVector3 a  'b  ' �  -+4   > T
�+   77 !7 !7 !@ +   77 7!7 7!7 7!@ �zyxNewnumber	typeVector3 a  b   U   27  7 7 77 7H zyxa  b   S  54  7+  7   > ?  �Dot	acos	mathVector3 a  	b  	 � 	 *9+   7 7 7 7 7 7 7 7 7 7 7 7 7 @ �xzyNewVector3 a  b   T   A7  ' #7 ' #7 ' #H zyxself   H   D4  7  7 > ?  LengthSquared	sqrt	mathself   8   H  7  >! H Lengtha  length  f   L  7  >7 !: 7 !: 7 !: G  zyxLengthself  len 
 #   S  H a  b   /    W   H a  b  alpha   @   [2 7  ;7 ;7 ;H zyxself  	 :  `+  7    @ �AddVector3 a  b   ?  c+  7    @ �SubtractVector3 a  b   ?  f+  7    @ �MultiplyVector3 a  b   =  i+  7    @ �DivideVector3 a  b   �  , 4M nC  7  7 7>3 >1 :1 :1	 :1 :
1 :1 :1 :1 :1 :1 :1 :1 :1 :1 :1! :  7"3$ 1# :%1& :'1( :)1* :+>0  �H 
__div 
__mul 
__sub 
__add   AddMetamethods GetValues 	Lerp GetMidpoint Normalize 	Unit Length LengthSquared 
Cross AngleBetween Dot Divide Multiply Subtract Add 	_new z x y 
ClassOOPUtility
)!0+4275?9CAFDKHQLUSYW][___bbeehhkk_nnCoeus 3oop 1Vector3 ,  ]==])
Coeus:AddVFSFile('Threading.Thread', [==[LJ �--from https://github.com/ColonelThirtyTwo/LuaJIT-Threads
local Coeus = ...
local ffi = require("ffi")
local OOP = Coeus.Utility.OOP
local ljta = Coeus.Bindings.luajit_thread_aux
local LuaJIT = Coeus.Bindings.LuaJIT
local TCT = Coeus.Bindings.TinyCThread

local xpcall_debug_hook_dump = string.dump(function(err)
	return debug.traceback(tostring(err) or "<nonstring error>")
end)

local moveValues_typeconverters = {
	["number"]  = function(L,v) LuaJIT.lua_pushnumber(L,v) end,
	["string"]  = function(L,v) LuaJIT.lua_pushlstring(L,v,#v) end,
	["nil"]     = function(L,v) LuaJIT.lua_pushnil(L) end,
	["boolean"] = function(L,v) LuaJIT.lua_pushboolean(L,v) end,
	["cdata"]   = function(L,v) LuaJIT.lua_pushlightuserdata(L,v) end,
}

-- Copies values into a lua state
local function moveValues(L, ...)
	local n = select("#", ...)

	if LuaJIT.lua_checkstack(L, n) == 0 then
		error("out of memory")
	end

	for i = 1, n do
		local v = select(i, ...)
		local conv = moveValues_typeconverters[type(v)]
		if not conv then
			error("Cannot pass argument "..i.." into thread: type "..type(v).." not supported")
		end
		conv(L, v)
	end
end

local Thread = OOP:Class() {
}

function Thread:_new(method, ...)
	local serialized = string.dump(method)
	local L = LuaJIT.luaL_newstate()

	self.state = L

	LuaJIT.luaL_openlibs(L)
	LuaJIT.lua_settop(L, 0)

	LuaJIT.lua_getfield(L, LuaJIT.LUA_GLOBALSINDEX, "loadstring")
	LuaJIT.lua_pushlstring(L, xpcall_debug_hook_dump, #xpcall_debug_hook_dump)
	LuaJIT.lua_call(L, 1, 1)

	LuaJIT.lua_getfield(L, LuaJIT.LUA_GLOBALSINDEX, "loadstring")
	LuaJIT.lua_pushlstring(L, serialized, #serialized)
	LuaJIT.lua_call(L, 1, 1)

	moveValues(L, ...)

	self.thread = ffi.new("thrd_t[1]")
	TCT.thrd_create(self.thread, ljta.ljta_run, ffi.cast("void*", L))
end

function Thread:Join()
	TCT.thrd_join(self.thread[0], nil)
end

function Thread:Destroy()
end

return Threadi   		4  74   >  T�% @ <nonstring error>tostringtraceback
debugerr  
 I   +  7    >G  �lua_pushnumber      LuaJIT L  v   O   +  7     >G  �lua_pushlstring       LuaJIT L  v   A   +  7   >G  �lua_pushnil     LuaJIT L  v   J   +  7    >G  �lua_pushboolean      LuaJIT L  v   P   +  7    >G  �lua_pushlightuserdata      LuaJIT L  v   �	-o4  % C =+  7   >	  T�4 % >'  ' I�4   C =+ 4 	 >6  T
�4 %	 
 % 4  >% $		> 	  
 >K�G  �� not supported into thread: type Cannot pass argument 	typeout of memory
errorlua_checkstack#select 					

LuaJIT moveValues_typeconverters L  .n )  i v conv  �
 M�*4  7 >+  7>: +  7 >+  7 '  >+  7 +  7% >+  7	 + +  >+  7
 ' ' >+  7 +  7% >+  7	   >+  7
 ' ' >+  C =+ 7% >: + 77 + 7+ 7% 	 > =G  ������
void*	castljta_runthrd_createthrd_t[1]newthreadlua_calllua_pushlstringloadstringLUA_GLOBALSINDEXlua_getfieldlua_settopluaL_openlibs
stateluaL_newstate	dumpstring							






LuaJIT xpcall_debug_hook_dump moveValues ffi TCT ljta self  Nmethod  Nserialized IL F L  A+  7 7 8 )  >G  �threadthrd_joinTCT self       	EG  self   �   )� HC  4  % >7 77 77 77 74 7	1
 >3 1 :1 :1 :1 :1 :1 
 7	>	2
  >	1
 :
	1
 :
	1
 :
	0  �H	  Destroy 	Join 	_new
Class 
cdata boolean nil  number    	dumpstringTinyCThreadLuaJITluajit_thread_auxBindingsOOPUtilityffirequire			%'''''?*CAFEHHCoeus (ffi %OOP #ljta !LuaJIT TCT xpcall_debug_hook_dump moveValues_typeconverters moveValues Thread   ]==])
Coeus:AddVFSFile('Utility.CPSleep', [==[LJ �local Coeus = ...
local ffi = require("ffi")
local CPSleep

if (ffi.os == "Windows") then
	local Win32 = Coeus.Bindings.Win32_

	--Windows 7 bugfix: WinMM not referenced by default.
	local WinMM = ffi.load("winmm.dll")
	WinMM.timeBeginPeriod(1)

	CPSleep = function(s)
		Win32.Sleep(s * 1000)
	end
else
	--untested
	ffi.cdef([[
		typedef unsigned int useconds_t;

		int usleep(useconds_t usec);
	]])

	CPSleep = function(s)
		ffi.C.usleep(s * 1000000)
	end
end

return CPSleep8 +  7   >G  �
Sleep�Win32 s   ? +  7 7  >G  �usleepC��zffi s   �   A C  4  % >)  7 T
�7 77% >7' >1	 0�7
% >1 0  �H  I		typedef unsigned int useconds_t;

		int usleep(useconds_t usec);
		cdef timeBeginPeriodwinmm.dll	loadWin32_BindingsWindowsosffirequire			


Coeus ffi CPSleep Win32 WinMM   ]==])
Coeus:AddVFSFile('Utility.Event', [==[LJ �local Coeus 	= (...)
local oop		= Coeus.Utility.OOP 

--[[
Simple use case:

Code:
	local ev = Event:New(true)

	local listener1 = ev:Listen(function(x, consume, disconnect)
		print("listener 1 checking in!",x)
		if x == "round 2" then
			disconnect()
		end
	end, false, 2)
	local listener2 = ev:Listen(function(x)
		print("listener 2 checking in!",x)
	end, true, 1)

	ev:Fire("round 1")
	ev:Fire("round 2")
	ev:Fire("round 3")

Output:
>	listener 2 checking in!	round 1
	(listener 2 comes first because it had the lower priority number
	 if you call consume() in listener 2, it won't reach listener 1)
> 	listener 1 checking in!	round 1
	(listener 2 is disposable so it drops out after round 1)
>	listener 1 checking in! round 2
 	(round 3 reaches nothing because listener 1 called disconnect() in round 2)

Any questions? Ask Kyle
]]

local Event = oop:Class() {
	listeners = {},
	use_priority = false
}

function Event:_new(use_priority)
	self.use_priority = use_priority or self.use_priority
end

function Event:Fire(...)
	local args = {...}
	local consumed = false
	local disconnected = false
	args[#args+1] = function() consumed = true end
	args[#args+1] = function() disconnected = true end

	for i=1,#self.listeners do 
		local v = self.listeners[i]
		if v == nil then break end --the disconnections might cause nil values at the end

		local callback = v.callback
		callback(unpack(args))
		if consume then
			break
		end
		if disconnected or v.disposable then
			table.remove(self.listeners, i)
		end
		disconnected = false
	end
	return consumed
end

function Event:Listen(func, disposable, priority)
	local listener = {}
	listener.callback = func
	listener.disposable = disposable or false
	listener.priority = priority or 0
	listener.Disconnect = function()
		self:Disconnect(listener)
	end
	self.listeners[#self.listeners+1] = listener
	if self.use_priority then
		self:Sort()
	end
	return listener
end

function Event:Disconnect(listener)
	for i,v in pairs(self.listeners) do
		if v == listener then
			table.remove(self.listeners, i)
			return
		end
	end
end

function Event:Sort()
	table.sort(self.listeners, function(a,b)
		return a.priority < b.priority
	end)
end

function Event:Destroy()
	--free the listeners
	self.listeners = {}
end

return EventG   ) T�7  :  G  use_priorityself  use_priority        1 /  G  �  consumed  $    2 /  G  �  disconnected  � 	/t-2 C <  ) )  1  9 1 9' 7  ' I�7 6  T	�T�7	
	 4  > =
 4
  
 T�T�  T
�7
 
 T�4
 7

7  >
) K�0  �H remove
tabledisposableconsumeunpackcallbacklisteners  ����			self  0args ,consumed +disconnected *  i v callback  F   J+     7   + > G   ��Disconnectself listener  � KE2  :  T�) : T�'  :1 :7 7   97   T�  7 >0  �H 	Sortuse_prioritylisteners Disconnectprioritydisposablecallback			


self  func  disposable  priority  listener  � 
  3T4  7 >D� T�4 77 	 >G  BN�G  remove
tablelisteners
pairsself  listener    i v   D   ^7  7   T�) T�) H prioritya  	b  	 F  ]4  77 1 >G   listeners	sort
tableself   +   c2  :  G  listenersself   �   / hC  7  7 7>3 2  :>1 :1 :1
 :	1 :1 :1 :0  �H  Destroy 	Sort Disconnect Listen 	Fire 	_newlisteners use_priority
ClassOOPUtility$$$$%%$+)C-RE[Ta]fchhCoeus oop Event   ]==])
Coeus:AddVFSFile('Utility.OBJLoader', [==[LJ �local Coeus 		= (...)
local oop			= Coeus.Utility.OOP
local Mesh			= Coeus.Graphics.Mesh

local Vector3 		= Coeus.Math.Vector3

local OBJLoader = oop:Class() {
	vertices = {},
	normals = {},
	texcoords = {},

	faces = {},

	mesh = false
}

function OBJLoader:_new(filename)
	local file, err = io.open(filename, 'r')
	if not file then
		print("Error opening OBJ file for loading: " .. err)
	end

	--Do some parsing
	local line_num = 0
	local line_str = ""
	local more
	local line = file:read("*l")
	while line do
		line_num = line_num + 1
		if more then
			line_str = line_str .. line
		else
			line_str = line
		end

		if line:find("\\$") then
			more = true
		else
			self:ParseLine(line_str)
		end
		line = file:read("*l")
	end

	--And then play the matching game
	local vertex_data = {}
	local index_data = {}
	local vertex_index = 0
	for i, face in ipairs(self.faces) do
		for j = 1, #face do
			local point = face[j]
			local vertex = self.vertices[point.v] or Vector3:New()
			local texcoord = self.texcoords[point.t] or Vector3:New()
			local normal = self.normals[point.n] or Vector3:New()

			vertex_data[#vertex_data + 1] = vertex.x
			vertex_data[#vertex_data + 1] = vertex.y
			vertex_data[#vertex_data + 1] = vertex.z
 	
 			vertex_data[#vertex_data + 1] = texcoord.x
			vertex_data[#vertex_data + 1] = texcoord.y
 
 			vertex_data[#vertex_data + 1] = normal.x
			vertex_data[#vertex_data + 1] = normal.y
			vertex_data[#vertex_data + 1] = normal.z

			index_data[#index_data + 1] = vertex_index
			vertex_index = vertex_index + 1
		end
	end

	local mesh = Mesh:New()
	mesh:SetData(vertex_data, index_data, Mesh.DataFormat.PositionTexCoordNormalInterleaved)

	self.mesh = mesh
end

function OBJLoader:ParseVector3(str)
	local x, y, z = str:match("^(%S+) +(%S+) +(%S+)")
	x = tonumber(x) or 0
	y = tonumber(y) or 0
	z = tonumber(z) or 0

	return Vector3:New(x, y, z)
end

function OBJLoader:ParseVector2(str)
	local x, y, z = str:match("^(%S+) +(%S+)")
	x = tonumber(x) or 0
	y = tonumber(y) or 0

	return {x=x,y=y}
end	

function OBJLoader:ParseLine(line)
	local cmd, arg_str = line:match("^%s*(%S+) +(.*)")
	cmd = cmd and cmd:lower()
	if not cmd or cmd == "#" then
		--comment or empty line
	elseif cmd == 'v' then
		self.vertices[#self.vertices + 1] = self:ParseVector3(arg_str)
	elseif cmd == 'vn' then
		self.normals[#self.normals + 1] = self:ParseVector3(arg_str)
	elseif cmd == 'vt' then
		self.texcoords[#self.texcoords + 1] = self:ParseVector2(arg_str)
	elseif cmd == 'f' then
		local face = {}
		for c in arg_str:gmatch("(%S+)") do
			local v, t, n = c:match("^([^/]+)/?([^/]*)/?([^/]*)")
			
			v = tonumber(v)
			t = tonumber(t)
			n = tonumber(n)

			face[#face + 1] = {
				v = v or 0,
				t = t or 0,
				n = n or 0
			}
			
		end
		
		self.faces[#self.faces + 1] = face
	end
end

function OBJLoader:GetMesh()
	return self.mesh
end

return OBJLoader� ��:4  7 % >  T�4 %  $>'  % )   7%	 >  T�Q�   T� 	 $	T� 	 7%
	 >  T	�) T�	  7
 
 >	 7%
 > T�2  2	  '
  4 7 >TE�'  ' IA�67 76  T�+   7>7 76  T�+   7>7 76  T�+   7>  79  79  79  79  79  79  79  79	  9
	
 
K�AN�+  7> 7 	 + 77>: G  ��	mesh&PositionTexCoordNormalInterleavedDataFormatSetDatazyxnnormalsttexcoordsNewvvertices
facesipairsParseLine\$	find*l	read)Error opening OBJ file for loading: 
printr	openio	



    !"""""""""#########$$$$$$$$$&&&&''''((((****++++----....////1112 6666777777779:Vector3 Mesh self  �filename  �file �err  �line_num line_str ~more }line yvertex_data [index_data Zvertex_index YH H Hi Eface  EB B Bj @point ?vertex 	6texcoord 	-normal 	$mesh +
 � 
 ?M 7 % >4  > T�'  4  > T�'  4  > T�'  +   7  	 @ �Newtonumber^(%S+) +(%S+) +(%S+)
matchVector3 self  str  x y  z   �   .V 7 % >4  > T�'  4  > T�'  3 ::H yx  tonumber^(%S+) +(%S+)
matchself  str  x y  z   �  c�^ 7 % >  T� 7>   TV� T�TS� T
�7 7     7  >9TG� T
�7 7     7  >9T;�	 T
�7
 7
     7  >9T/� T-�2   7% >T �
 7	 % >	4 	 >	 4 
 >
 4  >   3 	 T�'  :
 T�'  : T�'  :9AN�7 7   9G  
facesnt  tonumber^([^/]+)/?([^/]*)/?([^/]*)
(%S+)gmatchfParseVector2texcoordsvtnormalsvnParseVector3verticesv#
lower^%s*(%S+) +(.*)
match		









self  dline  dcmd _arg_str  _face 2,# # #c  v t  n   !   
~7  H 	meshself   �    L �C  7  77 77 7 7>3 2  :2  :	2  :
2  :>1 :1 :1 :1 :1 :0  �H  GetMesh ParseLine ParseVector2 ParseVector3 	_new
facestexcoordsnormalsvertices 	mesh
ClassVector3	Math	MeshGraphicsOOPUtility		

KTM\V|^�~��Coeus oop Mesh Vector3 OBJLoader   ]==])
Coeus:AddVFSFile('Utility.OOP', [==[LJ �local Coeus = (...)
local Table = Coeus.Utility.Table
local OOP = {}

function OOP:Class(...)
	local new = Table.DeepCopy(self.Object)
	new:Inherit(...)

	return function(target)
		if (target) then
			Table.Merge(new, target)
			return target
		else
			return new
		end
	end
end

function OOP:Static(...)
	local new = Table.DeepCopy(self.StaticObject)
	new:Inherit(...)

	return function(target)
		if (target) then
			Table.Merge(new, target)
			return target
		else
			return new
		end
	end
end

function OOP:Wrap(object, userdata)
	local interface = userdata or newproxy(true)
	local imeta = getmetatable(interface)

	object.GetInternal = function()
		return object
	end

	imeta.__index = object
	imeta.__newindex = object
	imeta.__gc = function(self)
		if (self.Destroy) then
			self:Destroy()
		end
	end

	for key, value in pairs(object.__metatable) do
		imeta[key] = value
	end

	return interface
end

OOP.Object = {
	__metatable = {}
}

--Class Methods
function OOP.Object:Inherit(...)
	for key, item in ipairs({...}) do
		Table.DeepCopyMerge(item, self)

		local imeta = item.__metatable or getmetatable(item)
		if (imeta) then
			Table.Merge(imeta, self.__metatable)
		end
	end

	return self
end

function OOP.Object:New(...)
	local internal = Table.DeepCopy(self)
	local instance = OOP:Wrap(internal)

	internal.GetClass = function()
		return self
	end

	if (instance._new) then
		instance:_new(...)
	end

	return instance
end

function OOP.Object:AddMetamethods(methods)
	for key, value in pairs(methods) do
		self.__metatable[key] = value
	end
end

--Object Methods
function OOP.Object:Copy()
	return OOP:Wrap(Table.DeepCopy(self:GetInternal()))
end

function OOP.Object:PointTo(object)
	OOP:Wrap(object, self)
end

function OOP.Object:Destroy()
end

OOP.StaticObject = {}

function OOP.StaticObject:Inherit(...)
	for key, item in ipairs({...}) do
		Table.DeepCopyMerge(item, self)
	end

	return self
end

return OOPd   	   T�+  7 +   >H  T�+ H G    �
MergeTable new target   p +  7 7 > 7C =1 0  �H � InheritObjectDeepCopyTable self  new  d      T�+  7 +   >H  T�+ H G    �
MergeTable new target   v +  7 7 > 7C =1 0  �H � InheritStaticObjectDeepCopyTable self  new      
%+   H  �object  =   +7    T�  7  >G  Destroyself   � 
 ^! T�4  ) >4  >1 :::1 :4 7	>D�9	BN�0  �H __metatable
pairs 	__gc__newindex__index GetInternalgetmetatablenewproxy	self  object  userdata  interface imeta 	  key value   �
G=4  2 C <  >T�+  7   >7  T�4  >  T�+  7 7	 >AN�H  �
Mergegetmetatable__metatableDeepCopyMergeipairs����
Table self    key item  imeta      N+   H   �self  � <J+  7   >+  7 >1 :7  T� 7C =0  �H ��	_new GetClass	WrapDeepCopy				Table OOP self  internal instance  r   	2Y4   >D�7 9BN�G  __metatable
pairsself  
methods  
  key value   l  
`+   7 + 7  7 > =  ? ��GetInternalDeepCopy	WrapOOP Table self   I  d+   7    >G  �	WrapOOP self  object       	hG  self   �	2m4  2 C <  >T�+  7   >AN�H  �DeepCopyMergeipairs����Table self    key item   �   '> uC  7  72  1 :1 :1 :3	 2  :
:71 :71 :71 :71 :71 :71 :2  :71 :0  �H  StaticObject Destroy PointTo 	Copy AddMetamethods New Inherit__metatable  Object 	Wrap Static 
Class
TableUtility6!899:=H=JWJY]Y`b`dfdhihkkmsmuuCoeus &Table $OOP #  ]==])
Coeus:AddVFSFile('Utility.PNGLoader', [==[LJ �local ffi = require("ffi")
local Coeus			= (...)
local OOP			= Coeus.Utility.OOP
local lodepng		= Coeus.Bindings.lodepng
local Texture 		= Coeus.Graphics.Texture

local OpenGL = Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local PNGLoader = OOP:Class() {
	texture = false
}

function PNGLoader:_new(filename)
	local err_code = ffi.new('unsigned int')
	local image_data = ffi.new('unsigned char*[1]')
	local width = ffi.new('unsigned int[1]')
	local height = ffi.new('unsigned int[1]')
	local file_data = ffi.new('unsigned char*[1]')
	local img_size = ffi.new('size_t[1]')

	lodepng.lodepng_load_file(file_data, img_size, filename)
	err_code = lodepng.lodepng_decode32(image_data, width, height, file_data[0], img_size[0])

	--ffi.C.free(file_data[0])
	if err_code ~= 0 then
		print("Error loading PNG file: " .. ffi.string(lodepng.lodepng_error_text(err_code)))
		--ffi.C.free(image_data[0])
		return
	end

	
	local texture = Texture:New()
	texture:Bind()

	

	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR)

	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR)
	gl.TexImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width[0], height[0], 0, GL.RGBA, GL.UNSIGNED_BYTE, image_data[0])
	local err = gl.GetError()
	if err ~= GL.NO_ERROR then
		error("GL error: " .. err)
	end
	self.texture = texture
	--ffi.C.free(image_data[0])
end

function PNGLoader:GetTexture()
	return self.texture
end

return PNGLoader� l�"+  7 % >+  7 % >+  7 % >+  7 % >+  7 % >+  7 % >+ 7	 
  >+ 7	 
  8 8 >   T�4 %	 +
  7
	
+ 7
 > =
 $	
	>G  + 	 7>
 7	>	+	 7		+
 7

+ 7+ 7>	+	 7		+
 7

+ 7+ 7>	+	 7		+
 7

'  + 78 8 '  + 7+ 78 >	
+	 7		>	+
 7

	
 T
�4
 % 	 $>
: G   �����textureGL error: 
errorNO_ERRORGetErrorUNSIGNED_BYTE	RGBATexImage2DTEXTURE_MAG_FILTERLINEARTEXTURE_MIN_FILTERTEXTURE_2DTexParameterf	BindNewlodepng_error_textstringError loading PNG file: 
printlodepng_decode32lodepng_load_filesize_t[1]unsigned int[1]unsigned char*[1]unsigned intnew 									 "ffi lodepng Texture gl GL self  mfilename  merr_code himage_data dwidth `height \file_data Ximg_size Ttexture !3err ( $   
37  H textureself   � 
  a 74   % > C 777777777	7
	 7>3	 >1	 :	1	 :	0  �H  GetTexture 	_new texture
ClassGLglOpenGLTextureGraphicslodepngBindingsOOPUtilityffirequire	15377ffi Coeus OOP lodepng Texture OpenGL gl GL PNGLoader   ]==])
Coeus:AddVFSFile('Utility.Table', [==[LJ �local Coeus = (...)
local Table = {}

function Table.IsDictionary(source)
	for key in pairs(source) do
		if (type(key) ~= "number") then
			return true
		end
	end

	return false
end

function Table.IsSequence(source)
	local last = 0

	for key in ipairs(source) do
		if (key ~= last + 1) then
			return false
		else
			last = key
		end
	end

	return (last ~= 0)
end

function Table.ArrayData(target, ...)
	for key, value in ipairs(target) do
		target[key] = nil
	end

	for key, value in ipairs({...}) do
		target[key] = value
	end

	return target
end

function Table.ArrayUpdate(target, ...)
	for key, value in ipairs({...}) do
		target[key] = value
	end

	return target
end

function Table.Equal(first, second, no_reverse)
	for key, value in pairs(first) do
		if (second[key] ~= value) then
			return false, key
		end
	end

	if (not no_reverse) then
		return Table.Equal(second, first, true)
	else
		return true
	end
end

function Table.Congruent(first, second, no_reverse)
	for key, value in pairs(first) do
		local value2 = second[key]

		if (type(value) == type(value2)) then
			if (type(value) == "table") then
				if (not Table.Congruent(value, value2)) then
					return false, key
				end
			else
				if (value ~= value2) then
					return false, key
				end
			end
		else
			return false, key
		end
	end

	if (not no_reverse) then
		return Table.Congruent(second, first, true)
	else
		return true
	end
end

function Table.Copy(source, target)
	target = target or {}

	for key, value in pairs(source) do
		target[key] = value
	end

	return target
end

function Table.DeepCopy(source, target, break_lock)
	target = target or {}

	for key, value in pairs(source) do
		local typeof = type(value)

		if (typeof == "table") then
			target[key] = Table.DeepCopy(value)
		elseif (typeof == "userdata" and value.Copy) then
			target[key] = value:Copy()
		else
			target[key] = value
		end
	end

	return target
end

function Table.Merge(source, target)
	if (not target) then
		return nil
	end

	for key, value in pairs(source) do
		if (not target[key]) then
			target[key] = value
		end
	end

	return target
end

function Table.CopyMerge(source, target, break_lock)
	if (not target) then
		return nil
	end

	for key, value in pairs(source) do
		if (not target[key]) then
			local typeof = type(value)

			if (typeof == "table") then
				target[key] = Table.Copy(value)
			elseif (typeof == "userdata" and value.Copy) then
				target[key] = value:Copy()
			else
				target[key] = value
			end
		end
	end

	return target
end

function Table.DeepCopyMerge(source, target, break_lock)
	if (not target) then
		return nil
	end

	for key, value in pairs(source) do
		if (not target[key]) then
			local typeof = type(value)

			if (typeof == "table") then
				target[key] = Table.DeepCopy(value)
			elseif (typeof == "userdata" and value.Copy) then
				target[key] = value:Copy()
			else
				target[key] = value
			end
		end
	end

	return target
end

function Table.Invert(source, target)
	target = target or {}

	for key, value in pairs(source) do
		target[value] = key
	end

	return target
end

function Table.Contains(source, value)
	for key, compare in pairs(source) do
		if (compare == value) then
			return true
		end
	end

	return false
end

return Table�   (4    >D�4  > T�) H BN�) H number	type
pairssource  
 
 
key  �  4'  4    >T�  T�) H T� AN�	 T�) T�) H ipairs source  last 
 
 
key  � J
4    >T�)  9 AN�4  2 C <  >T�9 AN�H  ipairs����	target    key value  	  key value   j 
+(4  2 C <  >T�9 AN�H  ipairs����target    key value   � 
 T04    >D�6 T�) 	 F BN�  T�+  7   ) @ T�) H G  �
Equal
pairs

Table first  second  no_reverse  	 	 	key value   �  4y>4    >D"�64	 
 >	4
  >
	
 T	�4	 
 >		 T	�+	  7		
  >	 	 T	�)	 
 F	 T		� T	�)	 
 F	 T	�)	 
 F	 BN�  T�+  7   ) @ T�) H G  �Congruent
table	type
pairs

Table first  5second  5no_reverse  5% % %key "value  "value2 ! q   5X  T�2  4    >D�9BN�H 
pairssource  target    key value   �   fb  T�2  4    >D�4 	 > T	�+	  7		
 >	9	T	� T	�7	 	 T
�
 7	>	9	T	�9BN�H �	CopyuserdataDeepCopy
table	type
pairs					Table source  !target  !break_lock  !  key value  typeof  �   9t  T�)  H 4    >D�6  T�9BN�H 
pairssource  target    key value   �  $j�  T�)  H 4    >D�6  T�4 	 > T	�+	  7		
 >	9	T	� T	�7	 	 T
�
 7	>	9	T	�9BN�H �userdata	Copy
table	type
pairs		





Table source  %target  %break_lock  %  key value  typeof  �  $j�  T�)  H 4    >D�6  T�4 	 > T	�+	  7		
 >	9	T	� T	�7	 	 T
�
 7	>	9	T	�9BN�H �	CopyuserdataDeepCopy
table	type
pairs		





Table source  %target  %break_lock  %  key value  typeof  r   5�  T�2  4    >D�9BN�H 
pairssource  target    key value   x   7�4    >D� T�) H BN�) H 
pairssource  value    key compare   �   / �C  2  1 : 1 :1 :1 :1	 :1 :
1 :1 :1 :1 :1 :1 :1 :0  �H  Contains Invert DeepCopyMerge CopyMerge 
Merge DeepCopy 	Copy Congruent 
Equal ArrayUpdate ArrayData IsSequence IsDictionary&.(<0V>`Xrb�t����������Coeus Table   ]==])
Coeus:AddVFSFile('Utility.Timer', [==[LJ �local Coeus = (...)
local ffi = require("ffi")
local OOP = Coeus.Utility.OOP

local CPSleep = Coeus.Utility.CPSleep

local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local Timer = OOP:Class() { 
	FPSUpdatePeriod = 1,

	current = 0,
	previous = 0,

	frame_count = 0,
	frame_time = 0,
	fps = 0
}

function Timer:_new()
	self.current = 0
	self.previous = 0
	self.frame_count = 0
	self.frame_time = 0
	self.fps = 0
end

function Timer:GetTime()
	return glfw.GetTime()
end

function Timer:Sleep(time)
	CPSleep(time)
end

function Timer:Step()
	self.current = self.GetTime()
	self.delta = self.current - self.previous
	self.fps = 1 / self.delta
	self.previous = self.current

	self.frame_time = self.frame_time + self.delta
	self.frame_count = self.frame_count + 1

	if self.frame_time > self.FPSUpdatePeriod then
		self.FPS = self.frame_count / self.frame_time

		self.frame_time = 0
		self.frame_count = 0
	end
end

function Timer:GetDelta()
	return self.delta
end

function Timer:GetFPS()
	return math.ceil(self.fps)
end

return Timeru   '  :  '  : '  : '  : '  : G  fpsframe_timeframe_countpreviouscurrentself   0  +  7 @ �GetTimeglfw self   7   "+   >G  �CPSleep self  time   �  	 (&7 >:  7  7 : 7  : 7  : 7 7 : 7  : 7 7  T�7 7 !: '  : '  : G  FPSFPSUpdatePeriodframe_countframe_timefpsprevious
deltaGetTimecurrent				



self  ! "   
77  H 
deltaself   4   ;4  77 @ fps	ceil	mathself   � 	  [ ?C  4  % >7 77 77 777 7>3	 >1 :
1 :1 :1 :1 :1 :0  �H  GetFPS GetDelta 	Step 
Sleep GetTime 	_new frame_time fps FPSUpdatePeriodcurrent previous frame_count 
Class	glfw	GLFWBindingsCPSleepOOPUtilityffirequire	 $"5&97=;??Coeus ffi OOP CPSleep GLFW glfw GLFW Timer   ]==])
Coeus:AddVFSFile('Utility.Unicode', [==[LJ �local Coeus = (...)
local ffi = require("ffi")
local bit = require("bit")

local Unicode = {}

local UTF8_ACCEPT = 0
local UTF8_REJECT = 12
 
local utf8d = ffi.new("const uint8_t[364]", {
  -- The first part of the table maps bytes to character classes that
  -- to reduce the size of the transition table and create bitmasks.
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
   7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
   8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  10,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3, 11,6,6,6,5,8,8,8,8,8,8,8,8,8,8,8,
 
  -- The second part is a transition table that maps a combination
  -- of a state of the automaton and a character class to a state.
   0,12,24,36,60,96,84,12,12,12,48,72, 12,12,12,12,12,12,12,12,12,12,12,12,
  12, 0,12,12,12,12,12, 0,12, 0,12,12, 12,24,12,12,12,12,12,24,12,24,12,12,
  12,12,12,12,12,12,12,24,12,12,12,12, 12,24,12,12,12,12,12,12,12,24,12,12,
  12,12,12,12,12,12,12,36,12,36,12,12, 12,36,12,12,12,12,12,36,12,36,12,12,
  12,36,12,12,12,12,12,12,12,12,12,12,
})
 
function Unicode.DecodeUTF8Byte(state, codep, byte)
	local ctype = utf8d[byte];
	if state ~= UTF8_ACCEPT then
		codep = bit.bor(bit.band(byte, 0x3f), bit.lshift(codep, 6))
	else
		codep = bit.band(bit.rshift(0xff, ctype), byte)
	end
	state = utf8d[256 + state + ctype]
	return state, codep
end

function Unicode.UTF8Iterate(utf8string, len)
	len = len or #utf8string
	local state = UTF8_ACCEPT
	local codep = 0
	local offset = 0
	local ptr = ffi.cast("uint8_t *", utf8string)
	local bufflen = len

	return function()
		while offset < bufflen do
			state, codep = Unicode.DecodeUTF8Byte(state, codep, ptr[offset])
			offset = offset + 1
			if state == UTF8_ACCEPT then
				return codep
			elseif state == UTF8_REJECT then
				return nil, state
			end
		end
		return nil, state
	end
end

function Unicode.UTF8Length(utf8string, len)
	local count = 0
	for codepoint, err in utf8_string_iterator(utf8string,len) do
		count = count + 1
	end
	return count
end

return Unicode� 	%[	+  6+   T�+ 7 + 7 '? >+ 7 ' > = T
�+ 7+ 7'�  > > +    6    F ���rshiftlshift	bandbor�utf8d UTF8_ACCEPT bit state  &codep  &byte  &ctype # �  $d2+   +   T �Q �+  7   + + + +  6> , ,  +      ,   +  +   T �+  H  T �+  +   T �)   + F  T �)   + F  ���� �   DecodeUTF8Byte


offset bufflen state codep Unicode ptr UTF8_ACCEPT UTF8_REJECT  � p*  T�  +  '  '  + 7 %   > 1 0  �H ���� uint8_t *	castUTF8_ACCEPT ffi Unicode UTF8_REJECT utf8string  len  state codep 
offset 	ptr bufflen  � 	 
A@'  4     >T� AN�H utf8_string_iteratorutf8string  len  count 	  codepoint err   � 	  Y HC  4  % >4  % >2  '  ' 7% 3 >1 :1	 :1 :
0  �H  UTF8Length UTF8Iterate DecodeUTF8Byte�                                                                                                                                  																
 $<`T0H   $$$$$$const uint8_t[364]newbitffirequire



(>*F@HHCoeus ffi bit Unicode UTF8_ACCEPT UTF8_REJECT utf8d   ]==])

local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL
OpenGL.loader = glfw.GetProcAddress

return Coeus