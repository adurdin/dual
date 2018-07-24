local Transloc = {
    // FIXME: consider using ref_frame arg and reference objects for the worlds.
    // Would allow better determination of where we are without hardcoding numbers.
    // World reference objects could be linked to the TranslocationMagic object.

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
    frob_start_time = 0;
    frob_max_duration = 1.0;
    frobwhile_period = 0.1;
    frobwhile_timer = 0;

    function OnFrobInvBegin() {
        frob_start_time = GetTime();

        // Start a timer for mid-frob updates and maximum frob time
        if (frobwhile_timer != 0) {
            KillTimer(frobwhile_timer);
            frobwhile_timer = 0;
        }
        frobwhile_timer = SetOneShotTimer(self, "FrobWhile", frobwhile_period);
    }

    function OnTimer() {
        if (message().name == "FrobWhile") {
            frobwhile_timer = 0;
            // Check if we've frobbed long enough
            local frob_duration = (GetTime() - frob_start_time);
            if (frob_duration >= frob_max_duration) {
                // Force frobbing to stop
                Debug.Command("use_item", 1);
            } else {
                // Keep the timer ticking
                frobwhile_timer = SetOneShotTimer(self, "FrobWhile", frobwhile_period);
            }
        }
    }

    function OnFrobInvEnd() {
        local frob_duration = message().Sec;
        DarkUI.TextMessage("Frob duration: " + frob_duration);
        if (frob_duration < frob_max_duration) {
            // FIXME: should preview translocation
        } else {
            // Translocate if we frobbed for a while.
            local player = Object.Named("Player");
            SendMessage(player, "Translocate");

            // FIXME: this doesn't work here! Dunno why, but maybe
            // a PostMessage will work?
            // But anyway, don't think I need to clear the item if
            // I'm using translocate-on-long-frob anyway.
            /*
            // Deselect the translocator.
            Debug.Command("clear_item");
            */
        }
    }

    // FIXME: this translocate-on-drop behaviour is quite unintuitive, and probably
    // should be removed in favour of translocate-on-long-frob.
    function OnContained() {
        local player = Object.Named("Player");
        if ((message().container == player)
            && (message().event == eContainsEvent.kContainRemove)) {
            // Prevent the player actually dropping the translocator, but perform
            // a translocation instead.

            // BUG: this plays loot sounds. It shouldn't!
            Container.Add(self, player);

            // Deselect the translocator.
            Debug.Command("clear_item");

            SendMessage(player, "Translocate");
        }
    }
}

// All these are right out of PHYSAPI.H
const PLAYER_HEAD = 0;
const PLAYER_FOOT = 1;
const PLAYER_BODY = 2;
const PLAYER_KNEE = 3;
const PLAYER_SHIN = 4;
const PLAYER_RADIUS = 1.2;
const PLAYER_HEIGHT = 6.0;
// local PLAYER_HEAD_POS = ((PLAYER_HEIGHT / 2) - PLAYER_RADIUS);
// local PLAYER_FOOT_POS = (-(PLAYER_HEIGHT / 2));
// local PLAYER_BODY_POS = ((PLAYER_HEIGHT / 2) - (PLAYER_RADIUS * 3));
// local PLAYER_KNEE_POS = (-(PLAYER_HEIGHT * (13.0 / 30.0)));
// local PLAYER_SHIN_POS = (-(PLAYER_HEIGHT * (11.0 / 30.0)));

class TransGarrett extends SqRootScript
{
    head_marker = 0;
    foot_marker = 0;
    body_marker = 0;
    head_probe = 0;
    body_probe = 0;
    foot_probe = 0;
    autoprobe_name = "AutoProbe";
    autoprobe_period = 0.1;
    autoprobe_timer = 0;

    function OnDarkGameModeChange() {
        // BUG: For whatever reason the Player doesn't get Sim messages! And BeginScript is too early
        // for creating the probe.
        //
        // WORKAROUND: Use DarkGameModeChange and keep track of if we've already created the probe.
        // Note that this will also fire when ending the level and just before a reload, but those
        // cases will just find the existing probe, so probably nothing to worry about.
        // FIX: put the script on another "manager" type object, whose OnSim should have access to the player.

        // Attach marker objects to submodels of the Player whose position we want to know.
        local player = self;
        head_marker = GetSubmodelMarker("PlayerHeadMarker", player, PLAYER_HEAD);
        body_marker = GetSubmodelMarker("PlayerBodyMarker", player, PLAYER_BODY);
        foot_marker = GetSubmodelMarker("PlayerFootMarker", player, PLAYER_FOOT);

        // Create probe objects for collision tests prior to teleporting the player.
        head_probe = GetSphereProbe("PlayerHeadProbe", PLAYER_RADIUS);
        body_probe = GetSphereProbe("PlayerBodyProbe", PLAYER_RADIUS);
        foot_probe = GetSphereProbe("PlayerFootProbe", 0.0);


        /*
        // FIXME: this timer probably won't work w.r.t savegames because of the above. No matter.
        // FIXME: also the interval means we run the script much too often; we really don't need to.
        //
        // FIX: Put a Tweq/Flicker on the Translocator (enabled when contained by a Player), have it
        // send a message to the TranslocationMagic object, and use the return value to update the
        // Translocator's appearance.
        if (autoprobe_timer == 0) {
            autoprobe_timer = SetOneShotTimer(autoprobe_name, autoprobe_period);
        }
        */
    }

    function OnTranslocate() {
        local player = self;
        local pos = Object.Position(player);
        local facing = Object.Facing(player);
        local new_pos = Transloc.AlternateWorldPosition(pos);
        local valid = Probe(new_pos);

        // ISSUE: player can translocate as fast as they can mash the button.
        // FIX: add some kind of delay in here.

        // ISSUE: player can end up inside an object after translocating, and we
        // cannot detect this with ValidPos() which only cares about terrain; nor
        // with Phys() messages, because they only occur on edges, not steady states.
        //
        // POSSIBLE WOKAROUND: when sim starts, scrape a list of all large-ish
        // immovable objects, get their positions, facings, and bounds, and store that.
        // Then query against that before teleporting to see if it should be allowed.

        if (valid) {
            Object.Teleport(player, new_pos, facing);
            Sound.PlayVoiceOver(player, "blue_light_on");

            // BUG: If player is abutting a wall to their East, then after teleporting,
            // they can't walk East again. Seems that teleporting the player doesn't
            // necessarily break physics contacts! (May also happen for other walls,
            // but is reliably reproducible with Eastern walls / objects.)
            //
            // SOLUTION: Setting the player's velocity seems to force contacts to be
            // re-evaluated, breaking the problematic contact. So we set it to what
            // it already is so that we don't interrupt their running/falling/whatever.
            local vel = vector();
            Physics.GetVelocity(player, vel);
            Physics.SetVelocity(player, vel);

            // BUG: If player translocates while in mid-mantle, they can still sometimes
            // get stuck midair, and teleport back if they abort the mantle! I can replicate
            // this most often with a wall to the player's South. This is an issue if I
            // try to store which world the player is in with a variable, instead of by
            // comparing player position to the reference points. Also an issue
            // for player equipment, if I'm taking that away when translocating.

        } else /* ! valid */ {
            // Translocating now would put us inside a wall or something. That's not great.
            Sound.PlayVoiceOver(player, "blue_light_off");
        }
    }

    function Probe(pos) {
        local player = self;
        local player_pos = Object.Position(player);
        local valid = true;
        if (valid) { valid = valid && EvaluateSingleProbe(head_probe, pos, head_marker, player_pos); }
        if (valid) { valid = valid && EvaluateSingleProbe(body_probe, pos, body_marker, player_pos); }
        if (valid) { valid = valid && EvaluateSingleProbe(foot_probe, pos, foot_marker, player_pos); }
        return valid;
    }

    function EvaluateSingleProbe(probe, probe_origin, marker, marker_origin) {
        local probe_pos = probe_origin + (Object.Position(marker) - marker_origin);
        Object.Teleport(probe, probe_pos, vector(0, 0, 0), 0);
        local valid = Physics.ValidPos(probe);
        return valid;
    }

    function OnTimer()
    {
        // if (message().name == autoprobe_name) {
        //     autoprobe_timer = SetOneShotTimer(autoprobe_name, autoprobe_period)
        // }
    }

    function GetSphereProbe(name, radius)
    {
        local obj = Object.Named(name);
        if (obj != 0) { return obj; }

        obj = Object.BeginCreate(Object.Named("Object"));
        Object.SetName(obj, name);

        // Probes all have a single sphere
        Property.Set(obj, "PhysType", "Type", 1);
        Property.Set(obj, "PhysType", "# Submodels", 1);
        Property.Set(obj, "PhysDims", "Radius 1", radius);
        Property.Set(obj, "PhysDims", "Offset 1", vector(0.0, 0.0, 0.0));

        // The probe must collide with anything but terrain.
        Property.Set(obj, "CollisionType", "", 0);
        Property.Set(obj, "PhysAIColl", "", false);
    
        // The probe starts at the origin.
        Object.Teleport(obj, vector(0,0,0), vector(0,0,0), 0);
        Physics.ControlCurrentLocation(obj);
        Physics.ControlCurrentRotation(obj);
    
        // Probe should not be rendered
        Property.Set(obj, "RenderType", "", 1);
    
        // Done.
        Object.EndCreate(obj);
        return obj;
    }

    function GetSubmodelMarker(name, target, submodel)
    {
        local obj = Object.Named(name);
        if (obj != 0) { return obj; }

        obj = Object.Create(Object.Named("Marker"));
        Object.SetName(obj, name);

        // Attach it to the appropriate submodel of the target
        local link = Link.Create("DetailAttachement", obj, target);
        LinkTools.LinkSetData(link, "Type", 3);
        LinkTools.LinkSetData(link, "vhot/sub #", submodel);
        LinkTools.LinkSetData(link, "rel pos", vector(0.0, 0.0, 0.0));
        LinkTools.LinkSetData(link, "rel rot", vector(0.0, 0.0, 0.0));
    
        return obj;
    }
}
