Current setup (poor):

	- GraphicsContext
		- List of RenderPass objects
			- List of Scenes

Pros:
	- Well... it filled the gap for now
Cons:
	- No clear ownership of Scene objects
	- Inconsistent overhead
	- Possibly unused objects (what if there's no HUD? no transparency?)
	- Scenes can achieve the same thing anyway
	- GraphicsContext does too much

Proposed setup:
	
	- GraphicsContext
		- Scene
			- Layer

Pros:
	- No more unclear ownership of Scenes
	- GraphicsContext is cut down

Other notes:
	GraphicsContext should not manage direct rendering of lights. That should be handled as a layer. 
Lights should've been applied as a RenderPass but since RenderPasses owned Scenes, this was impossible. 
Now, a Scene can own a Light Layer and render lights last as part of the entire rendering process 
rather than special treatment.