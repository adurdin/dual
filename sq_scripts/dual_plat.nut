/** AscensionPuzzle controls all the state of the puzzle. Levers and
 *  knobs send their inputs here; the internal state of the puzzle is
 *  updated accordingly; then the appropriate properties are set on
 *  the moving platforms. This ensures the puzzle state remains
 *  consistent and the moving platforms are brought in line with the
 *  state; and also that inputs are managed while the platforms are
 *  in motion.
 */
class AscensionPuzzle extends SqRootScript
{
    P1Base = 0;
    P1Bridge1 = 0;
    P1Bridge2 = 0;

    function OnSim() {
        if (message().starting) {
            // parts
            P1Base = ObjID("P1Base");
            P1Bridge1 = ObjID("P1Bridge1");
            P1Bridge2 = ObjID("P1Bridge2");
            // starting positions
            local pos = Property.Get(P1Base, "PhysState", "Location");
            local fac = Property.Get(P1Base, "PhysState", "Facing");
            SetData("P1RootPos", pos);
            SetData("P1RootFac", fac);
            // initial configuration
            SetData("Animating", false);
            SetData("P1Rise", 0);
            SetData("P1Rot", 0);
            SetData("P1RotDir", 1);
            SetData("P1Bridge1", 0);
            // apply it!
            UpdatePositions(1.0);
        }
    }

    function StartAnimating() {
        if (! GetData("Animating")) {
            SetData("Animating", true);
            SetData("PrevFrameTime", GetTime());
            PostMessage(self, "AnimFrame");
        }
    }

    function OnAnimFrame() {
        local t = GetTime();
        local dt = t-GetData("PrevFrameTime");
        SetData("PrevFrameTime", t);
        UpdatePositions(dt);
        if (GetData("Animating")) PostMessage(self, "AnimFrame");
    }

    function UpdatePositions(dt) {
        local rootPos = GetData("P1RootPos");
        local rootFac = GetData("P1RootFac");
        local fRise = GetData("P1Rise").tofloat();
        local fRot = GetData("P1Rot").tofloat();
        local fRotDir = GetData("P1RotDir").tofloat();
        local fBridge1 = GetData("P1Bridge1").tofloat();

        local basePosAt = Object.Position(P1Base);
        local basePosTo = rootPos+vector(0,0,48)*fRise;
        local baseFacAt = Object.Facing(P1Base);
        local baseFacTo = rootFac+vector(0,0,90)*fRot;

        // Move the base
        local basePosNext;
        local baseFacNext;
        if (GetData("Animating")) {
            const MAX_POS_SPEED = 8.0;
            const MAX_FAC_SPEED = 30.0;
            local posSpeed = (basePosTo-basePosAt)/dt;
            if (abs(posSpeed.z)>MAX_POS_SPEED) {
                posSpeed.z = (posSpeed.z<0?-MAX_POS_SPEED:MAX_POS_SPEED);
                basePosNext = basePosAt+posSpeed*dt;
            } else {
                basePosNext = basePosTo;
            }

            if (fRotDir>0) {
                // CCW - we require To > At
                if (baseFacTo.z<baseFacAt.z)
                    baseFacTo.z += 360;
            } else {
                // CW - we require To < At
                if (baseFacTo.z>baseFacAt.z)
                    baseFacAt.z += 360;
            }
            local facSpeed = (baseFacTo-baseFacAt)/dt;
            if (abs(facSpeed.z)>MAX_FAC_SPEED) {
                facSpeed.z = (facSpeed.z<0?-MAX_FAC_SPEED:MAX_FAC_SPEED);
                baseFacNext = baseFacAt+facSpeed*dt;
            } else {
                baseFacNext = baseFacTo;
            }
            // keep Next in range
            baseFacNext.z %= 360;
        } else {
            basePosNext = basePosTo;
            baseFacNext = baseFacTo;
        }

        // Move the bridges
        const pi = 3.141592653589793;
        local a = baseFacNext.z*pi/180.0;
        local n1 = vector(cos(a),sin(a),0);
        local n2 = vector(n1.y,-n1.x,0);
        // Bridge 1 can extend and retract
        local bridge1OutAt = (Object.Position(P1Bridge1)-basePosAt).Dot(n1);
        local bridge1OutTo = fBridge1*17.0;
        local bridge1OutNext;
        if (GetData("Animating")) {
            const MAX_BRIDGE_SPEED = 4.0;
            local outSpeed = (bridge1OutTo-bridge1OutAt)/dt;
            if (abs(outSpeed)>MAX_BRIDGE_SPEED) {
                outSpeed = (outSpeed<0?-MAX_BRIDGE_SPEED:MAX_BRIDGE_SPEED);
                bridge1OutNext = bridge1OutAt+outSpeed*dt;
            } else {
                bridge1OutNext = bridge1OutTo;
            }
        } else {
            bridge1OutNext = bridge1OutTo;
        }
        local bridge1PosNext = basePosNext+n1*bridge1OutNext;
        local bridge1FacNext = baseFacNext+vector(0,0,90);
        local bridge2PosNext = basePosNext+n2*17.0;
        local bridge2FacNext = baseFacNext;

        //print("POSITIONS and FACINGS:");
        print("basePos at "+basePosAt.z+", next "+basePosNext.z+", to "+basePosTo.z);
        print("    Fac at "+baseFacAt.z+", next "+baseFacNext.z+", to "+baseFacTo.z);
        print(" B1 out at "+bridge1OutAt+", next "+bridge1OutNext+", to "+bridge1OutTo);
        //print("  bridge1 next: "+bridge1PosNext+" - "+bridge1FacNext);
        //print("  bridge2 next: "+bridge2PosNext+" - "+bridge2FacNext);

        Object.Teleport(P1Base, basePosNext, baseFacNext);
        Object.Teleport(P1Bridge1, bridge1PosNext, bridge1FacNext);
        Object.Teleport(P1Bridge2, bridge2PosNext, bridge2FacNext);

        // stop animating when everything is at its end point/
        if ((basePosNext-basePosTo).Length()==0.0
        && (baseFacNext-baseFacTo).Length()==0.0
        && bridge1OutNext==bridge1OutTo) {
            SetData("Animating", false);
        }

        //// this moves the physics box, but not the visible object!
        // Property.Set(P1Base, "PhysState", "Location", targetPos);
        // Property.Set(P1Base, "PhysState", "Facing", targetFac);
        // Property.Set(P1Bridge1, "PhysState", "Location", bridge1TargetPos);
        // Property.Set(P1Bridge1, "PhysState", "Facing", bridge1TargetFac);
        // Property.Set(P1Bridge2, "PhysState", "Location", bridge2TargetPos);
        // Property.Set(P1Bridge2, "PhysState", "Facing", bridge2TargetFac);
    }

    function OnTurnOn() {
        if (message().from==ObjID("P1Bridge1Switch")) {
            SetData("P1Bridge1", 1);
        } else if (message().from==ObjID("P1RotSwitch")) {
            local rot = GetData("P1Rot");
            rot = (rot+3)%4;
            SetData("P1Rot", rot);
            SetData("P1RotDir", -1);
        } else if (message().from==ObjID("P1RiseSwitch")) {
            if (GetData("P1Rise")==0) {
                SetData("P1Rise", 1);
            } else {
                SetData("P1Rise", 0);
            }
        }
        StartAnimating();
    }

    function OnTurnOff() {
        if (message().from==ObjID("P1Bridge1Switch")) {
            SetData("P1Rise", 0);
            SetData("P1Rot", 0);
            SetData("P1RotDir", -1);
            SetData("P1Bridge1", 0);
        }
        StartAnimating();
    }

    /* messages from levers and knobs */
/*
    function OnP1ToggleBridge1() {
        ToggleVar("P1Bridge1");
        // Reset the puzzle when the bridge is retracted!
        if (GetData("P1Bridge1")==0) Reset();
        Update();
    }

    function OnP1Rot90CW() {
        RotateVar("P1Rot", -1);
        Update();
    }

    function OnP2ToggleBridge1() {
        ToggleVar("P2Bridge1");
        Update();
    }

    function OnP1ToggleRise() {
        ToggleVar("P1Rise");
        Update();
    }

    function OnP2ToggleRot180AndRise() {
        RotateVar("P2Rot", -2);
        ToggleVar("P2Rise");
        Update();
    }

    function OnP1P2Rot90CCW() {
        RotateVar("P1Rot", 1);
        RotateVar("P2Rot", 1);
        Update();
    }
*/
}
