class WispTurbHatch extends SqRootScript
{
    function OnFrobWorldEnd() {
        print(message().message);
        local AnimS = GetProperty("StTweqJoints", "AnimS");
        local Joint1AnimS = GetProperty("StTweqJoints", "Joint1AnimS");
        local Joint2AnimS = GetProperty("StTweqJoints", "Joint2AnimS");
        print("BEFORE:");
        print("  AnimS: "+format("0x%08x", AnimS));
        print("  Joint1AnimS: "+format("0x%08x", Joint1AnimS));
        print("  Joint2AnimS: "+format("0x%08x", Joint2AnimS));
        local isOn = ((AnimS&TWEQ_AS_ONOFF) != 0);
        if (isOn) {
            print("  REVERSE DIRECTION");
            // Reverse direction
            Joint1AnimS = (Joint1AnimS^TWEQ_AS_REVERSE);
            Joint2AnimS = (Joint2AnimS^TWEQ_AS_REVERSE);
            SetProperty("StTweqJoints", "Joint1AnimS", Joint1AnimS);
            SetProperty("StTweqJoints", "Joint2AnimS", Joint2AnimS);
        } else {
            print("  START");
            // Start going
            AnimS = (AnimS|TWEQ_AS_ONOFF);
            Joint1AnimS = (Joint1AnimS|TWEQ_AS_ONOFF);
            Joint2AnimS = (Joint2AnimS|TWEQ_AS_ONOFF);
            SetProperty("StTweqJoints", "AnimS", AnimS);
            SetProperty("StTweqJoints", "Joint1AnimS", Joint1AnimS);
            SetProperty("StTweqJoints", "Joint2AnimS", Joint2AnimS);
        }
        print("  AnimS: "+format("0x%08x", AnimS));
        print("  Joint1AnimS: "+format("0x%08x", Joint1AnimS));
        print("  Joint2AnimS: "+format("0x%08x", Joint2AnimS));
    }

    function OnTweqComplete() {
        print(message().message);
    }
}
