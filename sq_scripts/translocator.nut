local Transloc = {
    // Worlds must be spread out on the Y axis, and aligned on the X and Z axis.
    _worlds = [
        {
            origin = vector(0, 0, 0),
            min_y = -256,
            max_y = 256,
        },
        {
            origin = vector(0, 512, 0),
            min_y = 256,
            max_y = 768,
        },
    ]

    WorldIndex = function(pos) {
        foreach (index, world in _worlds) {
            if (pos.y >= world.min_y && pos.y < world.max_y) {
                return index;
            }
        }
        throw ("No world found at position: " + pos);
    }
}

class Translocator extends SqRootScript
{
    function OnFrobInvEnd() {
        local player = Object.Named("Player");
        local pos = Object.Position(player);
        local world_index = Transloc.WorldIndex(pos);
        print("Translocator says hello from world: " + world_index);
    }
}
