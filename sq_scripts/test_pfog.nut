class TestFogChanger extends SqRootScript {
    function OnTurnOn() {
        local pControl = ObjID("PeriaptController");
        if (pControl) {
            SendMessage(pControl, "SetFogColor", 68, 140, 203);
        }
    }

    function OnTurnOff() {
        local pControl = ObjID("PeriaptController");
        if (pControl) {
            SendMessage(pControl, "SetFogColor", 117, 76, 36);
        }
    }
}

class TestFogDistancer extends SqRootScript {
    fogTimer = 0;
    fogStartTime = 0.0;

    function OnTurnOn() {
        if (fogTimer == 0) {
            fogStartTime = GetTime();
            fogTimer = SetOneShotTimer("Fog", 0.016);
            print("Starting fog fade...");
        }
    }

    function OnTimer() {
        const duration = 4.0;

        local t = (GetTime()-fogStartTime) / duration;
        if (t < 0.0) t = 0.0;
        if (t >= 1.0) t = 1.0;

        local f; // from 0 to 1 and back again
        if (t < 0.5) f = 2.0*t;
        else f = -2.0*t + 2.0;

        const minFog = 32.0;
        const farFog = 256.0;
        local fogDistance = minFog + f*farFog;

        print("Fog distance " + fogDistance);

        local pControl = ObjID("PeriaptController");
        if (pControl) {
            SendMessage(pControl, "SetFogDist", fogDistance);
        }

        if (t < 1.0) {
            fogTimer = SetOneShotTimer("Fog", 0.016);
        } else {
            print("Ending fog fade.");
            fogTimer = 0;
        }
    }
}
