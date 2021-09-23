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

    function OnBeginScript() {
        if (! IsDataSet("IsLoaded")) SetData("IsLoaded", false);
    }

    function OnFrobWorldEnd() {
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
        local state = GetState();
        if (state==eWispTurbHatchState.kClosed
        && GetData("IsLoaded")) {
            Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
        }
    }

    function LoadBox(box) {
        Container.Remove(box);
        Object.Teleport(box, vector(), vector(), self);
        Object.AddMetaProperty(box, "FrobInert");
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
        local state = GetState();
        if (state==eWispTurbHatchState.kOpen) {
            if (GetData("IsLoaded")) {
                // We don't need your stinking box!
                Reply(false);
            } else {
                LoadBox(message().from);
                SetData("IsLoaded", true);
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
}

class WispBox extends SqRootScript
{
    function OnFrobToolEnd() {
        print(self+" - "+message().message);
        print("  Src: "+message().SrcObjId);
        print("  Dst: "+message().DstObjId);
        print("  Frobber: "+message().Frobber);
        print("  SrcLoc: "+message().SrcLoc);
        print("  DstLoc: "+message().DstLoc);

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
}
