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

    function OnTurnOn() {
        // TurnOn means, enable loading/unloading the cavity and its
        // owned box (if any).
        if (IsLoaded()) {
            local box = GetBox();
            Object.RemoveMetaProperty(box, "FrobInert");
            print(message().message+": Loaded; allow BOX to be frobbed.");
        } else {
            Object.RemoveMetaProperty(self, "FrobInert");
            print(message().message+": Not loaded; allow self to be frobbed.");
        }
    }

    function OnTurnOff() {
        // TurnOn means, dosable loading/unloading the cavity and its
        // owned box (if any).
        if (! Object.HasMetaProperty(self, "FrobInert")) {
            Object.AddMetaProperty(self, "FrobInert");
            print(message().message+": disallow self to be frobbed.");
        }
        if (IsLoaded()) {
            local box = GetBox();
            if (! Object.HasMetaProperty(box, "FrobInert")) {
                Object.AddMetaProperty(box, "FrobInert");
                print(message().message+": disallow BOX to be frobbed.");
            }
        }
    }

    function OnLoadWispBox() {
        // We will accept a wisp box, if:
        //   - the wisp box is charged (dilemma!)
        //   - we aren't already loaded
        //   - the hatch is open
        //
        // If the hatch is closed or closing:
        //   - reject the box, but start opening the hatch.
        //
        // In any other circumstances, reject the box.
        local box = message().from;
        if (! Object.InheritsFrom(box, "WispBox")) {
            print(message().message+": not a box.");
            Reply(false);
            return;
        }
        if (IsLoaded()) {
            // Already have a box!
            print(message().message+": already loaded.");
            Reply(false);
        } else {
            print(message().message+": accept the box.");
            // When we have a loaded box, stop being frobbable.
            // If the box is charged, turn on our CD'd devices.
            Container.Remove(box);
            if (! Link.AnyExist("Owns", self, box)) {
                Link.Create("Owns", self, box);
            }
            Object.Teleport(box, vector(), vector(), self);
            if (! Object.HasMetaProperty(self, "FrobInert")) {
                Object.AddMetaProperty(self, "FrobInert");
                print(message().message+": disallow self to be frobbed.");
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
        print(message().message+": ??? allow BOX to be frobbed???");
        local link = Link.GetOne("Owns", self);
        if (link) {
            local box = LinkDest(link);
            if (IsCharged()) {
                print(message().message+": sending TurnOff.");
                Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
            }
            if (IsHatchOpen()) {
                Object.RemoveMetaProperty(self, "FrobInert");
                print(message().message+": allow self to be frobbed.");
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
            if (GetState()==eWispTurbHatchState.kOpen) {
                Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
            } else {
                Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
            }
        }
    }

    function OnOpen() {
        local state = GetState();
        if (state==eWispTurbHatchState.kClosed
        || state==eWispTurbHatchState.kClosing) {
            SetState(eWispTurbHatchState.kOpening);
        }
    }

    function OnFrobWorldEnd() {
        // Toggle the hatch from open to closed. Allow it to be
        // interrupted mid-animation.
        // When the hatch starts closing, tell our CD'd cavity to turn off.
        local state = GetState();
        if (state==eWispTurbHatchState.kOpen) {
            Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
        }
        if (state==eWispTurbHatchState.kClosed
        || state==eWispTurbHatchState.kClosing) {
            SetState(eWispTurbHatchState.kOpening);
        } else {
            SetState(eWispTurbHatchState.kClosing);
        }
    }

    function OnTweqComplete() {
        // When the hatch finishes opening, tell our CD'd cavity to turn on.
        local state = GetState();
        if (state==eWispTurbHatchState.kOpen) {
            Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
        }
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
}
