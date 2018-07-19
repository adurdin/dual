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

    AlternateWorldIndex = function(world_index) {
        if (world_index == 0) {
            return 1;
        } else {
            return 0;
        }
    }

    AlternateWorldPosition = function(pos) {
        local world_index_a = WorldIndex(pos);
        local world_index_b = AlternateWorldIndex(world_index_a);
        local relative = (pos - _worlds[world_index_a].origin);
        return _worlds[world_index_b].origin + relative;
    }
}

class Translocator extends SqRootScript
{

    function OnFrobInvEnd() {
        local player = Object.Named("Player");
        local pos = Object.Position(player);
        local facing = Object.Facing(player);
        local new_pos = Transloc.AlternateWorldPosition(pos);
        // FIXME: consider using ref_frame arg and reference objects for the worlds.
        Object.Teleport(player, new_pos, facing);
        // Undo the teleport if we end up in a bad spot.
        if (! Physics.ValidPos(player)) {
            print("Would-be player position invalid at " + new_pos);
            Object.Teleport(player, pos, facing);
            Sound.PlayVoiceOver(player, "gardrop");
        }
        // BUG: if player is abutting a wall to his East, then after teleporting,
        // he can't walk East again. Find some way to break contacts or whatever.
        // NOTE: the following line seems to work around the bug, but obviously
        // causes weirdness for player movement, and particularly allows falling
        // interruption exploit.
        //Physics.SetVelocity(player, vector(0.0, 0.0, 0.0));

        // ISSUE: player can end up inside an object after translocating, and we
        // cannot detect this with ValidPos() which only cares about terrain; nor
        // with Phys() messages, because they only occur on edges, not steady states.
    }
}


class DebugPhysics extends SqRootScript
{
    function OnBeginScript() {
        print("Script begin");
        local messages = 0x01F0;
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);

    }

    function OnEndScript() {
        print("Script emd");
        local messages = 0x01F0;
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
    }

    function OnPhysCollision() {
        print(Object.GetName(self) + ": " + message().message);
    }

    function OnPhysContactCreate() {
        print(Object.GetName(self) + ": " + message().message);
    }

    function OnPhysContactDestroy() {
        print(Object.GetName(self) + ": " + message().message);
    }

    function OnPhysEnter() {
        print(Object.GetName(self) + ": " + message().message);
    }

    function OnPhysExit() {
        print(Object.GetName(self) + ": " + message().message);
    }
}

class TransGarrett extends DebugPhysics
{
    // function OnBeginScript() {
    //     print("Script begin");
    //     local messages = 0x01F0;
    //     Physics.SubscribeMsg(self, messages);
    // }

    // function OnEndScript() {
    //     print("Script emd");
    //     local messages = 0x01F0;
    //     Physics.UnsubscribeMsg(self, messages);
    // }

    // function OnPhysCollision() {
    //     print(message().message);
    // }

    // function OnPhysContactCreate() {
    //     print(message().message);
    // }

    // function OnPhysContactDestroy() {
    //     print(message().message);
    // }

    // function OnPhysEnter() {
    //     print(message().message);
    // }

    // function OnPhysExit() {
    //     print(message().message);
    // }
/*
// Messages: "PhysFellAsleep", "PhysWokeUp", "PhysMadePhysical", "PhysMadeNonPhysical", "PhysCollision",
//           "PhysContactCreate", "PhysContactDestroy", "PhysEnter", "PhysExit"
class sPhysMsg extends sScrMsg
{
   const int Submod;
   const ePhysCollisionType collType;
   const ObjID collObj;
   const int collSubmod;
   const float collMomentum;
   const vector collNormal;
   const vector collPt;
   const ePhysContactType contactType;
   const ObjID contactObj;
   const int contactSubmod;
   const ObjID transObj;
   const int transSubmod;
}
*/
}
