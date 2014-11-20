# Coeus Coding Conventions

## Globals
Globals should be avoided at all costs; modules should return an object instead of putting one in the global scope.

## Modules
Modules should have the following elements in order:

1. Comments describing the purpose of the module and where it's generally useful
2. Preprocessor directives (Coeus 0.3.0-alpha and above)
3. A reference to the Coeus core using `...` and the Coeus namespace if necessary
4. The body of the code, loading any dependencies and defining module(s)
5. A return statement exposing functionality of the module

This would look something like:
```lua
--[[
	Demonstration Library
	
	This library exists to show the recommending coding style for the Coeus core
	codebase.
]]
--#EnableExtension TypedLiterals

local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP

local DemoLibrary = OOP:Static() {
	PublicProperty = "Hello, world!",

	private_property = "uh oh"
}

function DemoLibrary:PublicMethod()
	print(self.PublicProperty)
end

function DemoLibrary:private_method()
	print(self.private_property)
end

return DemoLibrary
```

## Casing
Public names (classes, public methods and properties) should be in `PascalCase`. Private names (scoped variables, private methods and properties) should be in `under_score_case`.

## Spacing
Spaces should be put between operators except when helpful to clarify precedence.
```lua
5 + 5 --normal spacing
5 ^ 2 --also normal spacing
5^2 + 5^2 --spacing to emphasize operator precedence
(5 ^ 2) + (5 ^ 2) --also acceptable to emphasize precedence
```

Spacing should not be used before or after function names in both function calls and declarations. In function arguments, spaces should be placed after commas, but not before.
```lua
local function do_something()
	--function body
end

function MyClass:DoSomethingPublic(x, y, z)
	--function body
end

function MyClass:do_something_private(x, y, z)
	--function body
end
```

## Line breaks
Generally, a line break should occur after each statement. Line breaks should also occur within table definitions when defining large sets of data, most commonly dictionary-type data. If a table spans more than one line, the data should not start until after the first line break. Line breaks should also occur between large sections of code, like after a list of variable declarations or after a function declaration.
```lua
--This data is okay on one line because it's concise
local some_list = {1, 2, 3}

--This data makes more sense on multiple lines
local three_matrix = {
	1, 2, 3,
	4, 5, 6,
	7, 8, 9
}

--This dictionary makes sense on multiple lines
local data_index = {
	hello = "world",
	foo = "bar"
}
```

In multiline comments, a line break should occur when it would make sense to prevent too long of a line. A line break should also occur after the opening of a multiline comment. When writing comments, it is recommended that a ruler is enabled in your text editor.
```lua
--[[
	This is a multiline comment describing absolutely nothing, but still important for making sure that all code conforms to the standards set forth in this document.
	A line break occurs here because it looks nice, but is not strictly necessary.
]]
```

## Indentation
Indentation should be done with tabs, not spaces. It is assumed that your editor is configured to have a tab width of four spaces, but this does not necessarily have to be the case. Idents should occur after the start of a function, a multiple line table, or any statement creating a new scope.
```lua
local big_data = {
	1, 2, 3,
	4, 5, 6,
	7, 8, 9
}

local function coolio_bro()
	print("That's pretty rad.")
end

while (true) do
	print("Burn the world!")
end

repeat
	if (is_on_fire) then
		die()
	else
		print("You're not on fire, Ricky Bobby!")
	end
until (calm)
```

In multiline comments, a tab should proceed each line within the comment.
```lua
--[[
	This is a simple multiline comment.
]]
```

## Parentheses
Liberal use of parentheses for clarity and functionality is encouraged, and required in conditionals.
```lua
--This is okay for clarity purposes
local result = (5 * 6) + 7

--This is technically sound, but probably should be refactored
print((("Hello, world!"):gsub("..", "!?")))

--Wrap conditions in parentheses
if (something) then
	do_something()
elseif (something_else) then
	do_something_else()
end

--Wrap them here too
while (bar_of_soap) do
	print("foo!")
end
```

## Semicolons
Semicolons, both to terminate statements and to separate table elements, are discouraged.

## Function Declarations
When defining a method (as inside a class or object) it's best to use Lua's dedicated method syntax. This lets anyone reading the code know that the function should be called with method syntax (`:`) instead of regular function syntax (`.`). That being said, if a function should not be called as a method, defining it using regular function syntax is encouraged.
```lua
function MyClass:CoolMethod()
	print("Hello, world!")
end

function MyClass.SomeStruct.Operate(object)
	print("Hello, world, given object:", object)
end
```