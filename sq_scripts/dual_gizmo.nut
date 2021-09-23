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

    function OnFrobWorldEnd() {
        // Toggle the hatch from open to closed. Allow it to be
        // interrupted mid-animation.
        local state = GetState();
        if (state==eWispTurbHatchState.kClosed) {
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
        // When the hatch finishes opening:
        //   - Nothing special
        // When the hatch finishes closing:
        //   - If loaded with a charged box, turn on our CD'd turbine.
        //   - If loaded with an empty box, unload and disown it.
        local state = GetState();
        if (state==eWispTurbHatchState.kClosed
        && IsLoaded()) {
            if (IsCharged()) {
                Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
            } else {
                // TODO: play a rejection sound
                SetState(eWispTurbHatchState.kOpening);
                UnloadBox();
            }
        }
    }

    function LoadBox(box) {
        Container.Remove(box);
        if (! Link.AnyExist("Owns", self, box)) {
            Link.Create("Owns", self, box);
        }
        if (! Object.HasMetaProperty(box, "FrobInert")) {
            Object.AddMetaProperty(box, "FrobInert");
        }
        Object.Teleport(box, vector(), vector(), self);
    }

    function UnloadBox() {
        local link = Link.GetOne("Owns", self);
        if (link) {
            local box = LinkDest(link);
            Object.RemoveMetaProperty(box, "FrobInert");
            // We do not destroy the 'Owns' link here; that will
            // be done by the box when it is picked up. And at that
            // point it will tell us to enable frobs again.
            if (! Object.HasMetaProperty(self, "FrobInert")) {
                Object.AddMetaProperty(self, "FrobInert");
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
            Reply(false);
            return;
        }
        local state = GetState();
        if (state==eWispTurbHatchState.kOpen) {
            if (IsLoaded()) {
                // Already have a box!
                Reply(false);
            } else {
                LoadBox(message().from);
                Reply(true);
            }
        } else if (state==eWispTurbHatchState.kClosed
                || state==eWispTurbHatchState.kClosing) {
            SetState(eWispTurbHatchState.kOpening);
            Reply(false);
        } else {
            // Already opening. Have some patience please, player!
            Reply(false);
        }
    }

    function OnUnloadWispBox() {
        Object.RemoveMetaProperty(self, "FrobInert");
    }
}

class WispBox extends SqRootScript
{
    function OnFrobToolEnd() {
        local target = message().DstObjId;
        local isHatch = Object.InheritsFrom(target, "WispTurbHatch");
        if (isHatch) {
            local wasUsed = SendMessage(target, "LoadWispBox");
            Reply(wasUsed);
        } else {
            // Not a turbine hatch. Why would you use this here??
            Reply(false);
        }
    }

    function OnFrobWorldEnd() {
        local link = Link.GetOne("~Owns", self);
        if (link) {
            SendMessage(LinkDest(link), "UnloadWispBox");
            Link.Destroy(link);
        }
    }
}
