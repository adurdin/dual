class SimpleWobbleDummy extends SqRootScript
{
    function OnDamage() {
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
    function SparAttack(target) {
        if (! Link.AnyExist("AITarget", self)) {
            // An AITarget link can even force an AI to attack a friendly,
            // as long as they're in combat mode. Thanks Firemage!
            SetProperty("AI_Mode", eAIMode.kAIM_Combat);
            Link.Create("AITarget", self, target);
            print(Object_Description(self)+" attacking "+Object_Description(target));
        } else {
            print(Object_Description(self)+" AITarget link exists; not attacking.");
        }
    }

    function OnSim() {
        if (message().starting) {
            SetOneShotTimer("SparAttack", 1.0);
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
                // re-add it.
                SetOneShotTimer("SparAttack", 1.0);
            }
        }
    }
}
