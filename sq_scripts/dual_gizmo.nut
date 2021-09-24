class WispTurbine extends SqRootScript
{
    function OnTurnOn() {
        local AnimS = GetProperty("StTweqJoints", "AnimS");
        local Joint1AnimS = GetProperty("StTweqJoints", "Joint1AnimS");
        AnimS = (AnimS|TWEQ_AS_ONOFF);
        Joint1AnimS = (Joint1AnimS|TWEQ_AS_ONOFF);
        SetProperty("StTweqJoints", "AnimS", AnimS);
        SetProperty("StTweqJoints", "Joint1AnimS", Joint1AnimS);
    }

    function OnTurnOff() {
        local AnimS = GetProperty("StTweqJoints", "AnimS");
        local Joint1AnimS = GetProperty("StTweqJoints", "Joint1AnimS");
        AnimS = (AnimS&~TWEQ_AS_ONOFF);
        Joint1AnimS = (Joint1AnimS&~TWEQ_AS_ONOFF);
        SetProperty("StTweqJoints", "AnimS", AnimS);
        SetProperty("StTweqJoints", "Joint1AnimS", Joint1AnimS);
    }
}

class WispTurbCavity extends SqRootScript
{
    function GetBox() {
        local link = Link.GetOne("Owns", self);
        if (link) {
            return LinkDest(link);
        }
        return 0;
    }

    function IsLoaded() {
        return Link.AnyExist("Owns", self);
    }

    function IsCharged() {
        local link = Link.GetOne("Owns", self);
        if (! link) return;
        if (Object.InheritsFrom(LinkDest(link), "ChargedWispBox")
        || Object.InheritsFrom(LinkDest(link), "InvChargedWispBox")) {
            return true;
        }
        return false;
    }

    function IsHatchOpen() {
        local link = Link.GetOne("~ControlDevice", self);
        if (link
        && Object.InheritsFrom(LinkDest(link), "WispHatch")) {
            return SendMessage(LinkDest(link), "IsOpen?");
        }
        return true;
    }

    function OnHatchOpen() {
        // HatchOpen means, enable loading/unloading the cavity and its
        // owned box (if any).
        if (IsLoaded()) {
            local box = GetBox();
            Object.RemoveMetaProperty(box, "FrobInert");
        } else {
            Object.RemoveMetaProperty(self, "FrobInert");
        }
    }

    function OnHatchClosing() {
        // HatchClosing means, dosable loading/unloading the cavity and its
        // owned box (if any).
        if (! Object.HasMetaProperty(self, "FrobInert")) {
            Object.AddMetaProperty(self, "FrobInert");
        }
        if (IsLoaded()) {
            local box = GetBox();
            if (! Object.HasMetaProperty(box, "FrobInert")) {
                Object.AddMetaProperty(box, "FrobInert");
            }
        }
    }

    function OnHatchClosed() {
        // Make sure things are frob-disabled when the hatch finishes
        // closing (or starts closed!)
        OnHatchClosing();

        local box = GetBox();
        if (box) SendMessage(box, "TurnOff")
    }

    function OnHatchOpening() {
        local box = GetBox();
        if (box) SendMessage(box, "TurnOn")
    }

    function OnLoadWispBox() {
        // When we load a box, stop being frobbable.
        // If the box is charged, turn on our CD'd devices.
        local box = message().from;
        if (! Object.InheritsFrom(box, "WispBox")
        && ! Object.InheritsFrom(box, "InvChargedWispBox")) {
            print(message().message+": not a box.");
            Reply(false);
            return;
        }
        if (IsLoaded()) {
            // Already have a box!
            Reply(false);
        } else {
            // When we have a loaded box, stop being frobbable.
            // If the box is charged, turn on our CD'd devices.
            // If it's a fake charged box, then it will be swapping itself
            // out next frame, but it will handle updating the Owns link,
            // so its all okay from where we stand here.
            Container.Remove(box);
            if (! Link.AnyExist("Owns", self, box)) {
                Link.Create("Owns", self, box);
            }
            Object.Teleport(box, vector(), vector(), self);
            Property.Set(box, "PhysControl", "Controls Active", 24);
            if (! Object.HasMetaProperty(self, "FrobInert")) {
                Object.AddMetaProperty(self, "FrobInert");
            }
            if (IsCharged()) {
                print(message().message+": sending TurnOn.");
                Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
            }
            Reply(true);
        }
    }

    function OnUnloadWispBox() {
        // When we lose our loaded box, start being frobbable, if
        // our hatch permits.
        // If the box is charged, turn off our CD'd devices.
        local link = Link.GetOne("Owns", self);
        if (link) {
            local box = LinkDest(link);
            if (IsCharged()) {
                print(message().message+": sending TurnOff.");
                Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
            }
            if (IsHatchOpen()) {
                Object.RemoveMetaProperty(self, "FrobInert");
            }
            Link.Destroy(link);
        }
    }
}

enum eWispTurbHatchState
{
    kClosed,
    kOpening,
    kOpen,
    kClosing,
}

class WispTurbHatch extends SqRootScript
{
    function GetState() {
        local AnimS = GetProperty("StTweqJoints", "AnimS");
        local Joint1AnimS = GetProperty("StTweqJoints", "Joint1AnimS");
        if ((AnimS&TWEQ_AS_ONOFF) || (Joint1AnimS&TWEQ_AS_ONOFF)) {
            if (Joint1AnimS&TWEQ_AS_REVERSE) {
                return eWispTurbHatchState.kClosing;
            } else {
                return eWispTurbHatchState.kOpening;
            }
        } else {
            if (Joint1AnimS&TWEQ_AS_REVERSE) {
                return eWispTurbHatchState.kOpen;
            } else {
                return eWispTurbHatchState.kClosed;
            }
        }
    }

    function SetState(state) {
        local AnimS = GetProperty("StTweqJoints", "AnimS");
        local Joint1AnimS = GetProperty("StTweqJoints", "Joint1AnimS");
        local Joint2AnimS = GetProperty("StTweqJoints", "Joint2AnimS");
        if (state==eWispTurbHatchState.kClosed
        || state==eWispTurbHatchState.kClosing) {
            AnimS = (AnimS|TWEQ_AS_ONOFF);
            Joint1AnimS = (Joint1AnimS|TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
            Joint2AnimS = ((Joint2AnimS|TWEQ_AS_ONOFF)&~TWEQ_AS_REVERSE);
        } else {
            AnimS = (AnimS|TWEQ_AS_ONOFF);
            Joint1AnimS = ((Joint1AnimS|TWEQ_AS_ONOFF)&~TWEQ_AS_REVERSE);
            Joint2AnimS = (Joint2AnimS|TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
        }
        SetProperty("StTweqJoints", "AnimS", AnimS);
        SetProperty("StTweqJoints", "Joint1AnimS", Joint1AnimS);
        SetProperty("StTweqJoints", "Joint2AnimS", Joint2AnimS);
    }

    function OnIsOpen_() {
        return (GetState()==eWispTurbHatchState.kOpen);
    }

    function OnSim() {
        if (message().starting) {
            BroadcastStateMessage();
        }
    }

    function OnOpen() {
        local state = GetState();
        if (state==eWispTurbHatchState.kClosed
        || state==eWispTurbHatchState.kClosing) {
            SetState(eWispTurbHatchState.kOpening);
            BroadcastStateMessage();
        }
    }

    function BroadcastStateMessage() {
        local state = GetState();
        local msg;
        if (state==eWispTurbHatchState.kClosed) {
            msg = "HatchClosed";
        } else if (state==eWispTurbHatchState.kOpening) {
            msg = "HatchOpening";
        } else if (state==eWispTurbHatchState.kOpen) {
            msg = "HatchOpen";
        } else {
            msg = "HatchClosing";
        }
        Link.BroadcastOnAllLinks(self, msg, "ControlDevice");
    }

    function OnFrobWorldEnd() {
        // Toggle the hatch from open to closed. Allow it to be
        // interrupted mid-animation.
        // When the hatch starts closing, tell our CD'd cavity to turn off.
        local state = GetState();
        if (state==eWispTurbHatchState.kClosed
        || state==eWispTurbHatchState.kClosing) {
            SetState(eWispTurbHatchState.kOpening);
        } else {
            SetState(eWispTurbHatchState.kClosing);
        }
        BroadcastStateMessage();
    }

    function OnTweqComplete() {
        // When the hatch finishes opening, tell our CD'd cavity to turn on.
        BroadcastStateMessage();
    }
}

class WispBox extends SqRootScript
{
    function OnFrobToolEnd() {
        local target = message().DstObjId;
        local isCavity = Object.InheritsFrom(target, "WispTurbCavity");
        local isHatch = Object.InheritsFrom(target, "WispTurbHatch");
        if (isCavity) {
            local wasUsed = SendMessage(target, "LoadWispBox");
            Reply(wasUsed);
        } else if (isHatch) {
            SendMessage(target, "Open");
        } else {
            // Not a turbine cavity. Why would you use this here??
            Reply(false);
        }
    }

    function OnFrobWorldEnd() {
        local link = Link.GetOne("~Owns", self);
        if (link) {
            SendMessage(LinkDest(link), "UnloadWispBox");
        }
    }

    function OnTurnOn() {
        if (HasProperty("SelfLit")) {
            local brightness = 10.0;
            if (IsDataSet("Brightness")) {
                brightness = GetData("Brightness");
            }
            SetProperty("SelfLit", brightness);
        }
    }

    function OnTurnOff() {
        if (HasProperty("SelfLit")) {
            local brightness = GetProperty("SelfLit");
            if (! IsDataSet("Brightness")) {
                SetData("Brightness", brightness);
            }
            SetProperty("SelfLit", 0.0);
        }
    }
}

class ChargedWispBox extends SqRootScript
{
    function OnContained() {
        local container = message().container;
        local isPlayer = Object.InheritsFrom(container, "Avatar");
        if (isPlayer) {
            if (message().event==eContainsEvent.kContainAdd) {
                // swap ourselves out for an inventory fake
                local invbox = Object.Create("InvChargedWispBox");
                Container.Add(invbox, container);
                DarkUI.InvSelect(invbox);
                Object.Destroy(self);
            }
        }
    }
}

class InvChargedWispBox extends SqRootScript
{
    function OnContained() {
        local container = message().container;
        local isPlayer = Object.InheritsFrom(container, "Avatar");
        if (isPlayer) {
            if (message().event==eContainsEvent.kContainRemove) {
                // If we do the swap-out right here and now, we
                // hit a crash because we still have an UpdateInv
                // message in flight! So we make sure to disable that
                // first, and let the swap happen next frame.
                PostMessage(self, "PrestoChango");
                SetData("Selected", false);
            }
        }
    }

    function OnPrestoChango() {
        // swap ourselves out for the real thing!
        local box = Object.Create("ChargedWispBox");
        Object.Teleport(box, vector(), vector(), self);
        Property.CopyFrom(box, "PhysControl", self);
        Property.CopyFrom(box, "PhysState", self);
        local link = Link.GetOne("~Owns", self);
        if (link) {
            Link.Create("Owns", LinkDest(link), box);
            Link.Destroy(link);
        }
        Object.Destroy(self);
    }

    function OnInvSelect() {
        SetData("Selected", true);
        SendMessage(self, "UpdateInv");
    }

    function OnUpdateInv() {
        local t = (GetTime()*-8.4375*10)%360.0;
        local t2 = (GetTime()*2000.0)%360.0;
        local fac = Object.Facing(self);
        local camfac = Camera.GetFacing();

        if (camfac.y>180.0) camfac.y-=360.0;
        // This is the compass2 angle calculation from drkinvui.
        local pitch_factor = 0.25*camfac.y;
        if (pitch_factor < -5.625)
           pitch_factor=((pitch_factor+5.625)*5)+(-5.625);
        else if (pitch_factor < -8.4375)
           pitch_factor=((pitch_factor+8.4375)*2)+(-19.6875);
        else if (pitch_factor > 5.625)
           pitch_factor=((pitch_factor-5.625)*2)+(5.625);
        local camy = -25.3125 - pitch_factor;

        // Joint 1: compensate for compass z rotation
        SetProperty("JointPos", "Joint 1", (fac.z+270.0)%360.0);
        // Joint 2: compensate for compass y rotation
        SetProperty("JointPos", "Joint 2", (camy+360.0+20.0)%360.0);
        // Joint 3: rotate the box like an ordinary inventory item!
        SetProperty("JointPos", "Joint 3", t%360.0);
        // Joint 4: counter-rotate the fake particles!
        SetProperty("JointPos", "Joint 4", (360.0-t)%360.0);
        // Joint 5: spin the fake particles!
        SetProperty("JointPos", "Joint 5", t2);
        if (GetData("Selected")) {
            PostMessage(self, "UpdateInv");
        }
    }

    function OnInvDeSelect() {
        SetData("Selected", false);
    }
}
