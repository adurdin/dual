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
        // Would allow better determination of where we are without hardcoding numbers.

        Object.Teleport(player, new_pos, facing);
        // Undo the teleport if we end up inside terrain.
        // FIXME: consider using a probe object first so we don't have to move the player
        if (! Physics.ValidPos(player)) {
            print("Would-be player position invalid at " + new_pos);
            Object.Teleport(player, pos, facing);
            Sound.PlayVoiceOver(player, "gardrop");
        }

        // BUG: If player is abutting a wall to their East, then after teleporting,
        // they can't walk East again. Seems that teleporting the player doesn't
        // necessarily break physics contacts! (May also happen for other walls,
        // but is reliably reproducible with Eastern walls / objects.)
        //
        // SOLUTION: Setting the player's velocity seems to force contacts to be
        // re-evaluated, breaking the problematic contact. So we set it to what
        // it already is so that we don't interrupt their running/falling/whatever.
        //
        // FIXME: only do this if we actually did teleport
        local vel = vector();
        Physics.GetVelocity(player, vel);
        Physics.SetVelocity(player, vel);

        // ISSUE: player can end up inside an object after translocating, and we
        // cannot detect this with ValidPos() which only cares about terrain; nor
        // with Phys() messages, because they only occur on edges, not steady states.
        //
        // POSSIBLE WOKAROUND: when sim starts, scrape a list of all large-ish
        // immovable objects, get their positions, facings, and bounds, and store that.
        // Then query against that before teleporting to see if it should be allowed.

        // TODO: need to explore translocation while crouched, leaning, etc.
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

class TransGarrett extends SqRootScript
{
    probe = 0;
    probe_test_timer = 0;

    function OnDarkGameModeChange() {
        // BUG: For whatever reason the Player doesn't get Sim messages! And BeginScript is too early
        // for creating the probe.
        //
        // WORKAROUND: Use DarkGameModeChange and keep track of if we've already created the probe.
        // Note that this will also fire when ending the level and just before a reload, but those
        // cases will just find the existing probe, so probably nothing to worry about.
        //
        // TODO: The probe should probably be owned by the translocator itself tbh.
        local p = Object.Named("PlayerTransProbe");
        if (p != 0) {
            // Probe already exists (usually because loading a saved game)
            probe = p;
        } else {
            probe = CreateProbe();
        }

        // FIXME: this timer probably won't work w.r.t savegames because of the above. No matter.
        if (probe_test_timer == 0) {
            probe_test_timer = SetOneShotTimer("TestProbe", 0.015);
        }
    }

    function OnTimer()
    {
        if (message().name == "TestProbe") {
            TestProbe();
            probe_test_timer = SetOneShotTimer("TestProbe", 0.015)
        }
    }

    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kContactMsg);
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kEnterExitMsg);
    }

    function OnPhysCollision() {
        local m = message();

        // Find out what we're colliding with
        local type;
        local objectName;
        if (m.collType == ePhysCollisionType.kCollNone) {
            type = "None";
            objectName = "";
        } else if (m.collType == ePhysCollisionType.kCollTerrain) {
            type = "Terrain";
            objectName = "" + m.collObj;
        } else if (m.collType == ePhysCollisionType.kCollObject) {
            type = "Object";
            objectName = "'" + Object.GetName(m.collObj) + "' (" + m.collObj + ")";
        }
        print("Collision in submodel " + m.Submod + " with " + type + " " + objectName);

        // Find out the parameters of the collision
        print("  at: " + m.collPt + ", normal: " + m.collNormal + ", momentum: " + m.collMomentum);
    }

    function OnPhysContactCreate() {
        local m = message();

        // Find out what we're contacting
        local type;
        local objectName = "'" + Object.GetName(m.contactObj) + "' (" + m.contactObj + ")";

        if (m.contactType == ePhysContactType.kContactNone) {
            type = "None";
        } else if (m.contactType == ePhysContactType.kContactFace) {
            type = "Face";
        } else if (m.contactType == ePhysContactType.kContactEdge) {
            type = "Edge";
        } else if (m.contactType == ePhysContactType.kContactVertex) {
            type = "Vertex";
        } else if (m.contactType == ePhysContactType.kContactSphere) {
            type = "Sphere";
        } else if (m.contactType == ePhysContactType.kContactSphereHat) {
            type = "SphereHat";
        } else if (m.contactType == ePhysContactType.kContactOBB) {
            type = "OBB";
        }

        print("Create contact with " + objectName + " " + type + " submodel " + m.contactSubmod);
    }

    function OnPhysContactDestroy() {
        local m = message();

        // Find out what we're contacting
        local type;
        local objectName = "'" + Object.GetName(m.contactObj) + "' (" + m.contactObj + ")";

        if (m.contactType == ePhysContactType.kContactNone) {
            type = "None";
        } else if (m.contactType == ePhysContactType.kContactFace) {
            type = "Face";
        } else if (m.contactType == ePhysContactType.kContactEdge) {
            type = "Edge";
        } else if (m.contactType == ePhysContactType.kContactVertex) {
            type = "Vertex";
        } else if (m.contactType == ePhysContactType.kContactSphere) {
            type = "Sphere";
        } else if (m.contactType == ePhysContactType.kContactSphereHat) {
            type = "SphereHat";
        } else if (m.contactType == ePhysContactType.kContactOBB) {
            type = "OBB";
        }

        print("Destroy contact with " + objectName + " " + type + " submodel " + m.contactSubmod);
    }

    function OnPhysEnter() {
        local m = message();

        // Find out what we're entering
        local objectName = "'" + Object.GetName(m.transObj) + "' (" + m.transObj + ")";

        print("Enter " + objectName + " submodel " + m.transSubmod);
    }

    function OnPhysExit() {
        local m = message();

        // Find out what we're exiting
        local objectName = "'" + Object.GetName(m.transObj) + "' (" + m.transObj + ")";

        print("Exit " + objectName + " submodel " + m.transSubmod);
    }
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
enum ePhysMessageResult
{
    kPM_StatusQuo
    kPM_Nothing
    kPM_Bounce
    kPM_Slay
    kPM_NonPhys
}

enum ePhysCollisionType
{
    kCollNone
    kCollTerrain
    kCollObject
}

enum ePhysContactType
{
    kContactNone
    kContactFace
    kContactEdge
    kContactVertex
    kContactSphere
    kContactSphereHat
    kContactOBB
}

*/

    function CreateProbe()
    {
        local obj = Object.BeginCreate(Object.Named("Object"));
        Object.SetName(obj, "PlayerTransProbe");

        // The probe must have the same physics models as the player.
        local player = Object.Named("Player");
        Property.CopyFrom(obj, "PhysType", player);
        Property.CopyFrom(obj, "PhysDims", player);

        // The probe should not collide with anything though.
        Property.Set(obj, "CollisionType", "", 0);
        Property.Set(obj, "PhysAIColl", "", false);
    
        // The probe starts at the origin.
        Object.Teleport(obj, vector(0,0,0), vector(0,0,0), 0);
        Physics.ControlCurrentPosition(obj);
    
        // For the sake of visibility while developing, give it a player box model.
        Property.Set(obj, "ModelName", "", "playbox");
        const kRenderTypeNormal = 0;
        Property.Set(obj, "RenderType", "", kRenderTypeNormal);
    
        // Done.
        Object.EndCreate(obj);
        return obj;
    }

    function TestProbe() {
        local player = Object.Named("Player");

        // BUG: Updating the PhysDims property like this doesn't seem to work.
        // Is that because player motions don't update the player's phys properties?
        //
        // BUG: Also the dimensions of at least one of the submodels is clearly wrong!
        // Might have to copy some of the actual player physics from PhysCreateDefaultPlayer() in PHYSAPI.CPP
        Property.CopyFrom(probe, "PhysDims", player);

        //local pos = Object.Position(player) + vector(0.0, -8.0, 0.0);
        //local facing = Object.Facing(player);
        Object.Teleport(probe, vector(8.0, 0.0, 0.0), vector(0.0, 0.0, 0.0), player);
        local valid = Physics.ValidPos(probe);
        if (valid) {
            Property.Set(probe, "ModelName", "", "garstd"); // garcrh?
        } else {
            Property.Set(probe, "ModelName", "", "playbox");
        }
    }

/*
    function Probe(pos, facing) {
        // Update physics submodels
        Property.CopyFrom(self, "PhysDims", player);
        Object.Teleport(self, pos, facing, 0);
        local valid = Physics.ValidPos(self);
        Object.Teleport(self, vector(0, 0, 0), vector(0, 0, 0));
        
    }
*/

}
