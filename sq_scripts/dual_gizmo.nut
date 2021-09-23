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
        if (link
        && Object.InheritsFrom(LinkDest(link), "ChargedWispBox")) {
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
        if (! Object.InheritsFrom(box, "WispBox")) {
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
            Container.Remove(box);
            if (! Link.AnyExist("Owns", self, box)) {
                Link.Create("Owns", self, box);
            }
            // The cavity origin is a little off-center because of its
            // front angles. So just hack that here.
            Object.Teleport(box, vector(-0.25,0,0), vector(), self);
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
