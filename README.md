# my-minetest-game
**NOTE**: name is still TBD

This is a procedurally generated space exploration game, inspired by No Man's
Sky and other similar titles, but built around voxel mechanics. It features an
immensely large universe with a never-ending variety of planets to explore.

**NOTE**: choose *singlenode* as mapgen type.

## Status
For now, 16 different planets' surfaces are generated next to each other. Blocks
include stone, gravel, dust, sediment, liquid (water, hydrocarbon, lava), grass
soil, grass, dry grass, tall grass and snow. Planets of different colors,
rockier, more hilly or flat, richer in oceans, arid, frozen, volcanic, and with
or without living organisms are generated. World generation features oceans,
caves, deserts and craters.

The next step is adding an infinite (actually 597529) number of planets.

The game is not yet playable, as it does not include any user-interaction code.

## TODO
 * Add minerals and ores
 * Add player mechanics
 * Add basic items
 * Add basic crafting
 * Add spacecraft building
 * Add flight
 * Add interplanetary space
 * Add interstellar travel
 * Improve all of the above

## Contributing
The code is made to be as self-documenting as possible. Just go into the `mods`
directory and read the `init.lua` file within a mod. It should present the API
exported by the mod, if any, and gently guide the reader through the code
itself.
