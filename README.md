# Sprite texture repeat shader. (or tiling)

---
Set 'sprite_repeat' material to the sprite. Directly in the editor or with code.

```lua
go.set(self.url, "material", self.repeat_material)
```


Create and go our super-puper repeating magic.

```lua
local sprite_repeat = require('sprite_repeat.sprite_repeat')

function init(self)

	local repeat_x = 4
	local repeat_y = 4

	local sr = sprite_repeat.create("#sprite_url")
	sr.animate(repeat_x, repeat_y)

end
```

See file 'sprite_repeat.script' for details.

Works with both static and animated sprites.

![Example](example.png)

Happy Defolding!

---