class SimpleWobbleDummy extends SqRootScript
{
    function Wobble() {
        if (GetProperty("StTweqRotate", "AnimS") != 0)
            return;
        SetProperty("CfgTweqRotate", "Halt", TWEQ_HALT_STOP);
        SetProperty("CfgTweqRotate", "AnimC", TWEQ_AC_SIM|TWEQ_AC_1BOUNCE);
        SetProperty("CfgTweqRotate", "MiscC", 0);
        SetProperty("CfgTweqRotate", "CurveC", TWEQ_CC_BOUNCE);
        SetProperty("CfgTweqRotate", "Primary Axis", 2);
        SetProperty("CfgTweqRotate", "x rate-low-high", vector());
        SetProperty("CfgTweqRotate", "y rate-low-high", vector(15,0,5));
        SetProperty("CfgTweqRotate", "z rate-low-high", vector());
        SetProperty("StTweqRotate", "AnimS", TWEQ_AS_ONOFF);
    }

    function OnDamage() {
        Wobble();
    }

    function OnBashStimStimulus() {
        // Should still wobble when hit with a wooden sword.
        Wobble();
    }

    function OnSlashStimStimulus() {
        // Should still wobble when hit with a wooden sword.
        Wobble();
    }
}

class WobbleDummy extends SqRootScript
{
    function GetJointMarker() {
        local m = GetData("JointMarker");
        if (!m) {
            m = Object.Create("Marker");
            SetData("JointMarker", m);
        }
        return m;
    }

    function GetAttackPoint(attacker, ref_facing=null) {
        local fromPos = Object.Position(attacker);
        local fromFacing = Object.Facing(attacker);
        local attach = Link.GetOne("~CreatureAttachment", attacker);
        if (attach) {
            // Create a marker at the Right Fingers joint, which is where
            // the tip of the weapon is. This is so we can find out the
            // joint position!
            local cret = LinkDest(attach);
            local cretType = Property.Get(cret, "Creature");
            if (cretType==0         // Humanoid
            || cretType==1      // PlayerArm
            || cretType==6      // Crayman
            || cretType==11) {  // Zombie
                local m = GetJointMarker();
                local dattach = Link.Create("DetailAttachement", m, cret);
                LinkTools.LinkSetData(dattach, "Type", 2); // Joint
                LinkTools.LinkSetData(dattach, "joint", 12); // Right Fingers
                LinkTools.LinkSetData(dattach, "rel rot", vector(0,90,0)); // make marker +X point to joint -Z
                LinkTools.LinkSetData(dattach, "Flags", 1); // "No Auto-Delete"
                Link.Destroy(dattach);
                local tipPos = Object.Position(m);
                local tipFacing = Object.Facing(m);
                dattach = Link.Create("DetailAttachement", m, cret);
                LinkTools.LinkSetData(dattach, "Type", 2); // Joint
                LinkTools.LinkSetData(dattach, "joint", 10); // Right Wrist
                LinkTools.LinkSetData(dattach, "rel rot", vector(0,90,0)); // make marker +X point to joint -Z
                LinkTools.LinkSetData(dattach, "Flags", 1); // "No Auto-Delete"
                Link.Destroy(dattach);
                local basePos = Object.Position(m);
                local baseFacing = Object.Facing(m);
                // Find the closest point on the weapon to us.
                local p = Object.Position(self);
                local a = basePos;
                local n = (tipPos-a).GetNormalized();
                local t = (p-a).Dot(n);
                if (t<0.0) t = 0.0;
                if (t<1.0) t = 1.0;
                fromPos = a+n*t;
                fromFacing = baseFacing; // Both should be the same anyhow.
            }
        }
        // Update the passed-by-reference facing vector
        if (ref_facing!=null) {
            ref_facing.x = fromFacing.x;
            ref_facing.y = fromFacing.y;
            ref_facing.z = fromFacing.z;
        }
        return fromPos;
    }

    function OnDamage() {
        local fromFacing = vector();
        local fromPos = GetAttackPoint(message().culprit, fromFacing);
        /*
            // For debugging: create a dummy object showing the pos+facing
            local t = Object.BeginCreate("Marker");
            Object.Teleport(t, fromPos, fromFacing);
            Property.Set(t, "FrobInfo", "World Action", 4); // Delete
            Property.SetSimple(t, "RenderType", 2); // Unlit
            Property.SetSimple(t, "ModelName", "firarr");
            Object.EndCreate(t);
        */
        local isOverhead = (fromFacing.x>=225 && fromFacing.x<=315);
        // An attack from the front or side or back, how cowardly!
        local direction;
        local d = Object.WorldToObject(self, fromPos);
        local a = atan2(d.y,d.x)*180.0/3.1416;
        local msg;
        if (a < -135 || a >= 135) {
            msg = "WobbleFromLeft";
        } else if (a <= -45) {
            msg = "WobbleFromBack";
        } else if (a <= 45) {
            msg = "WobbleFromRight";
        } else {
            msg = "WobbleFromFront";
        }
        // Now I command thee, wobble!
        Link.BroadcastOnAllLinks(self, msg, "ControlDevice");
    }
}

class WobbleDummyVisible extends SqRootScript
{
    function OnWobbleFromLeft() {
        if (GetProperty("StTweqRotate", "AnimS") != 0)
            return;
        SetProperty("CfgTweqRotate", "Halt", TWEQ_HALT_STOP);
        SetProperty("CfgTweqRotate", "AnimC", TWEQ_AC_SIM|TWEQ_AC_1BOUNCE);
        SetProperty("CfgTweqRotate", "MiscC", TWEQ_MC_LINKREL);
        SetProperty("CfgTweqRotate", "CurveC", TWEQ_CC_BOUNCE);
        SetProperty("CfgTweqRotate", "Primary Axis", 2);
        SetProperty("CfgTweqRotate", "x rate-low-high", vector());
        SetProperty("CfgTweqRotate", "y rate-low-high", vector(15,0,5));
        SetProperty("CfgTweqRotate", "z rate-low-high", vector());
        SetProperty("StTweqRotate", "AnimS", TWEQ_AS_ONOFF);
    }

    function OnWobbleFromRight() {
        // Because I cant get the anticlockwise tweq to work
        OnWobbleFromLeft();
    }

    function OnWobbleFromFront() {
        if (GetProperty("StTweqRotate", "AnimS") != 0)
            return;
        SetProperty("CfgTweqRotate", "Halt", TWEQ_HALT_STOP);
        SetProperty("CfgTweqRotate", "AnimC", TWEQ_AC_SIM|TWEQ_AC_1BOUNCE);
        SetProperty("CfgTweqRotate", "MiscC", TWEQ_MC_LINKREL);
        SetProperty("CfgTweqRotate", "CurveC", TWEQ_CC_BOUNCE);
        SetProperty("CfgTweqRotate", "Primary Axis", 1);
        SetProperty("CfgTweqRotate", "x rate-low-high", vector(15,0,5));
        SetProperty("CfgTweqRotate", "y rate-low-high", vector());
        SetProperty("CfgTweqRotate", "z rate-low-high", vector());
        SetProperty("StTweqRotate", "AnimS", TWEQ_AS_ONOFF);
    }

    function OnWobbleFromBack() {
        // Because I cant get the anticlockwise tweq to work
        OnWobbleFromFront();
    }
}

class Sparring extends SqRootScript
{
    /* BUGS:
        1. they keep trying to do this even if they are KOd or dead. they cant
           act then, but will stand up and try to.
        2. they should not be trying to do this when their target is KOd, or
           dead, or not nearby.
        3. if their partner is not available, but the target dummy is, then
           they should maybe wail on that instead?
        4. i currently have Broadcasts fully disabled on these guards so their
           combat shouts dont alert nearby ai to come and investigate. but
           this is bad for gameplay involving the player. also, the sound of
           their swords clashing still brings other ais sometimes (and should
           not be happening with wooden swords). solution: give these guards
           a custom voice set with combat shouts that dont carry combat value.
    */

    function SparAttack(target) {
        if (! Link.AnyExist("AITarget", self)) {
            // An AITarget link can even force an AI to attack a friendly,
            // as long as they're in combat mode. Thanks Firemage!
            SetProperty("AI_Mode", eAIMode.kAIM_Combat);
            Link.Create("AITarget", self, target);
        }
    }

    function OnSim() {
        if (message().starting) {
            SetOneShotTimer("SparAttack", 0.5+Data.RandFlt0to1());
        }
    }

    function OnTimer() {
        if (message().name=="SparAttack") {
            local target = Link_GetOneParam("SparAttack", self);
            if (target) {
                SparAttack(target);
                // Every two seconds, the AI will re-evaluate its targets. When
                // that happens, it will see that its target is on the same team,
                // and so not valid, and will remove it. So we need to repeatedly
                // re-add it. We do so with a little randomness, so that the two
                // guards won't be synchronized.
                SetOneShotTimer("SparAttack", 0.5+Data.RandFlt0to1());
            }
        }
    }
}

class HeatStimOnOff extends SqRootScript
{
    /* When receiving a Heat stim with intensity >= 50, send TurnOn via
    all ControlDevice links; if < 50, send TurnOff. Will only send the
    message when the presence of the stim changes. */
    function OnSim() {
        if (message().starting) {
            SetData("HeatStimOn", 0);
        }
    }

    function OnHeatStimStimulus() {
        local wasOn = GetData("HeatStimOn");
        local on;
        // We add a tiny bit of hysteresis in here, to prevent the case
        // where the stim value changes slightly (which happens with torches!)
        if (wasOn) {
            on = (message().intensity>=45);
        } else {
            on = (message().intensity>=55);
        }
        // And we use integers to ensure the == comparison works (because
        // bools dont survive the GetData/SetData properly)
        on = (on?1:0);
        if (on != wasOn) {
            print("HeatStimOnOff: "+on+ " (was "+wasOn+")");
            SetData("HeatStimOn", on);
            local msg = (on ? "TurnOn" : "TurnOff");
            Link.BroadcastOnAllLinks(self, msg, "ControlDevice");
        }
    }
}

class ToggleExtraLight extends SqRootScript
{
    function OnBeginScript() {
        local amount = GetProperty("ExtraLight", "Amount (-1..1)");
        local additive = GetProperty("ExtraLight", "Additive?");
        SetData("TELAmount", amount);
        SetData("TELAdditive", additive);
    }

    function OnTurnOn() {
        local amount = GetData("TELAmount");
        local additive = GetData("TELAdditive");
        SetProperty("ExtraLight", "Amount (-1..1)", amount);
        SetProperty("ExtraLight", "Additive?", additive);
    }

    function OnTurnOff() {
        SetProperty("ExtraLight", "Amount (-1..1)", 0.0);
        SetProperty("ExtraLight", "Additive?", true);
    }
}

class BlinkController extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            SetData("BlinkTime", 0.0);
            SetData("BlinkInterval", 0.0);
            SetOneShotTimer("Blink", 1.0);
        }
    }

    function OnTimer() {
        if (message().name=="Blink") {
            Blink();
            SetOneShotTimer("Blink", 1.0);
        }
    }

    DEBUG = false;
    ALWAYS_BLINK = false;

    function Blink() {
        local Log = (DEBUG?
            function(msg) { print(msg); }
            : function(msg) {} );

        // Don't blink more than once a minute or so.
        local BLINK_INTERVAL = DEBUG? 2.0 : 60.0;
        // And don't allow any painting to blink twice in five minutes.
        local PAINTING_BLINK_INTERVAL = DEBUG? 6.0 : 5*60.0;

        // Make sure we're not trying to make any blinking happen too often.
        local now = GetTime();
        local lastBlink = GetData("BlinkTime");
        local interval = GetData("BlinkInterval");
        if ((now - lastBlink) < interval) {
            Log("Too soon (global)");
            if (! ALWAYS_BLINK)
                return;
        }
        interval = BLINK_INTERVAL*(0.9+0.6*Data.RandFlt0to1());
        SetData("BlinkInterval", interval);

        local cameraPos = Camera.GetPosition();
        local links = Link.GetAll("ControlDevice", self);
        local paintings = [];
        foreach (link in links) {
            paintings.append(LinkDest(link));
        }
        foreach (o in paintings) {
            // Look for a good candidate:
            // - must be on screen
            //
            // BUG: note that the periapt osm is currently interfering with
            //      the visibility stuff, so the game thinks the painting is
            //      always rendered :(
            if (! Object.RenderedThisFrame(o)) {
                Log(Object_Description(o)+": Not rendered");
                if (! ALWAYS_BLINK)
                    continue;
            }
            // - must not be right up close (in XY)
            local pos = Object.Position(o);
            local dist = (pos - cameraPos).Length();
            if (dist <= 8.0) {
                Log(Object_Description(o)+": Too close");
                if (! ALWAYS_BLINK)
                    continue;
            }
            // - must be peripheral, not central (unless far away)
            if (dist <= 16.0) {
                local dir = Camera.WorldToCamera(Object.Position(o)).GetNormalized();
                local howCentered = dir.Dot(vector(1,0,0));
                if (howCentered >= 0.9) {
                    Log(Object_Description(o)+": Too central");
                    if (! ALWAYS_BLINK)
                        continue;
                }
            }
            // - must not have blinked very recently
            local prev = SendMessage(o, "LastBlinkTime?").tofloat();
            if ((now - prev) < PAINTING_BLINK_INTERVAL) {
                Log(Object_Description(o)+": Too soon");
                if (! ALWAYS_BLINK)
                    continue;
            }
            // - and must not have terrain in front of it
            local hitPos = vector();
            local hit = Engine.PortalRaycast(cameraPos, pos, hitPos);
            local hitDist = (hitPos - cameraPos).Length();
            if (hitDist < dist) {
                Log(Object_Description(o)+": Obscured");
                if (! ALWAYS_BLINK)
                    continue;
            }

            // Seems like an okay candidate
            Log(Object_Description(o)+": Blink!");
            SetData("BlinkTime", now);
            SendMessage(o, "Blink");
            
            if (! ALWAYS_BLINK)
                break;
        }
    }
}

class Blink extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            local tex = GetProperty("OTxtRepr0");
            SetData("BlinkOrig", tex);
            SetData("BlinkTime", 0.0);
        }
    }

    function OnLastBlinkTime_() {
        local lastTime = GetData("BlinkTime");
        Reply(lastTime);
    }

    function OnBlink() {
        local now = GetTime();
        SetData("BlinkTime", now);
        SetProperty("OTxtRepr0", userparams().Blink);
        SetOneShotTimer("BlinkOff", 0.08);
    }

    function OnTimer() {
        if (message().name=="BlinkOff") {
            SetProperty("OTxtRepr0", GetData("BlinkOrig"));
        }
    }
}

class DelayedFall extends SqRootScript
{
    function OnTurnOn() {
        if (! Locked.IsLocked(self)) {
            local delay = 1000;
            if (HasProperty("ScriptTiming")) {
                delay = GetProperty("ScriptTiming");
            }
            SetProperty("Locked", true);
            SetOneShotTimer("DelayedFall", delay/1000.0);
        }
    }

    function OnTimer() {
        if (message().name == "DelayedFall") {
            local controls = GetProperty("PhysControl", "Controls Active");
            controls = controls & (~24); // Clear location (8) and rotation (16).
            SetProperty("PhysControl", "Controls Active", controls);
        }
    }
}

class HangingHazard extends SqRootScript
{
    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnPhysCollision() {
        if (message().collType == ePhysCollisionType.kCollObject
        && message().collObj == ObjID("Player")) {
            local coll = "Event Collision";
            local mat1 = "Metal";
            local mat2 = "Wood";
            if (HasProperty("Material Tags")) {
                mat2 = GetProperty("Material Tags", "1: Tags");
                if (startswith(mat2, "Material ")) {
                    mat2 = mat2.slice(9);
                }
            }
            local tags = (coll+", Material "+mat1+", Material2 "+mat2);
            local ok = Sound.PlayEnvSchema(0, tags, self, message().collObj, eEnvSoundLoc.kEnvSoundOnObj);
            if (! ok) {
                tags = (coll+", Material "+mat2+", Material2 "+mat1);
                ok = Sound.PlayEnvSchema(0, tags, self, message().collObj, eEnvSoundLoc.kEnvSoundOnObj);
            }
            print("tags: "+tags+" ok: "+ok);
        }
    }
}

class TrampleBook extends SqRootScript {
    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeModels
        && message().Op==eTweqOperation.kTweqOpHaltTweq) {
            if (! IsDataSet("Trampled")) {
                SetData("Trampled", true);
                local qvar = "bookstrampled";
                local count = 0;
                if (Quest.Exists(qvar)) {
                    count = Quest.Get(qvar);
                }
                count += 1;
                Quest.Set(qvar, count);
            }
        }
    }
}

/*
class HurtMeBaby extends SqRootScript {
    function OnBeginScript() {
        Physics.SubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    function OnEndScript() {
        Physics.UnsubscribeMsg(self, ePhysScriptMsgType.kCollisionMsg);
    }

    // function OnPhysContactCreate() {
    //     print(self+": contact type "+message().contactType+" with "+message().contactObj+" submod "+message().contactSubmod);
    // }

    function OnPhysCollision() {
        if (message().collType==ePhysCollisionType.kCollObject) {
            local mauler = message().collObj;
            //print(self+": collision from "+mauler+" submod "+message().collSubmod);
            // TODO - maybe not just burricks?
            if (Object.InheritsFrom(mauler, "Burrick")) {
                if (! Link.AnyExist("AIAttack", mauler, self))
                    SendMessage(mauler, "HurtMeBaby");
            }
        }
        // class sPhysMsg extends sScrMsg
        // {
        //    const int Submod;
        //    const ePhysCollisionType collType;
        //    const ObjID collObj;
        //    const int collSubmod;
        //    const float collMomentum;
        //    const vector collNormal;
        //    const vector collPt;
        //    const ePhysContactType contactType;
        //    const ObjID contactObj;
        //    const int contactSubmod;
        //    const ObjID transObj;
        //    const int transSubmod;
        // }
    }
}

class MeleeObstacles extends SqRootScript {
    function OnHurtMeBaby() {
        local target = message().from;
        // local link = Link.GetOne("AIAttack", self, target);
        // if (link!=0) {
        //     print("already attacking you (shouldnt get here, but just in case).");
        //     return;
        // }
        // print("Creating Attack link!");
        // target = message().from;
        // link = Link.Create("AIAttack", self, target);
        // LinkTools.LinkSetData(link, "", 5); // Very High

        local link = Link.GetOne("AITarget", self);
        if (link!=0) {
            if (LinkDest(link)==target) {
                //print("already attacking you (shouldnt get here, but just in case).");
                return;
            }
            Link.Destroy(link);
        }
        SetProperty("AI_Mode", eAIMode.kAIM_Combat);
        Link.Create("AITarget", self, target);
        local metaprop = Object.Named("M-MeleeBurrick");
        if (metaprop) {
            if (! Object.HasMetaProperty(self, metaprop)) {
                print("Adopting melee weapons!");
                Object.AddMetaProperty(self, metaprop);
            }
            // TODO: need to remove the metaprop after destroying the object!
        }
    }

    function OnMessage() {
        print(self+": uncategorized "+message().message);
    }
}
*/