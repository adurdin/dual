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
            SetData("P1RootPos", Property.Get(P1Base, "PhysState", "Location"));
            SetData("P1RootFac", Property.Get(P1Base, "PhysState", "Facing"));
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

    function LinearNext(at, to, max_speed, dt) {
        const MAX_POS_SPEED = 8.0;
        local speed = (to-at)/dt;
        if (abs(speed)>max_speed) {
            speed = (speed<0?-max_speed:max_speed);
            return at+speed*dt;
        } else {
            return to;
        }
    }

    function FacingNext(at, to, cw, max_speed, dt) {
        if (cw) {
            // CW - we require To < At
            if (to>at) at += 360;
        } else {
            // CCW - we require To > At
            if (to<at) to += 360;
        }
        local speed = (to-at)/dt;
        local next = 0;
        if (abs(speed)>max_speed) {
            speed = (speed<0?-max_speed:max_speed);
            next = at+speed*dt;
        } else {
            next = to*1.0; // ensure a copy!
        }
        // keep Next in range
        next %= 360;
        return next;
    }

    function UpdatePositions(dt) {
        local p1rootPos = GetData("P1RootPos");
        local p1rootFac = GetData("P1RootFac");
        local p1fRise = GetData("P1Rise").tofloat();
        local p1fRot = GetData("P1Rot").tofloat();
        local p1fRotDir = GetData("P1RotDir").tofloat();
        local p1fBridge1 = GetData("P1Bridge1").tofloat();

        local p1basePosAt = Object.Position(P1Base);
        local p1basePosTo = p1rootPos+vector(0,0,48)*p1fRise;
        local p1baseFacAt = Object.Facing(P1Base);
        local p1baseFacTo = p1rootFac+vector(0,0,90)*p1fRot;

        // Move the base
        local p1basePosNext;
        local p1baseFacNext;
        if (GetData("Animating")) {
            p1basePosNext = p1basePosTo*1.0; // ensure a copy!
            p1basePosNext.z = LinearNext(
                p1basePosAt.z, p1basePosTo.z, 8.0, dt);

            p1baseFacNext = p1baseFacTo*1.0; // ensure a copy!
            p1baseFacNext.z = FacingNext(
                p1baseFacAt.z, p1baseFacTo.z, p1fRotDir<0, 30.0, dt);
        } else {
            p1basePosNext = p1basePosTo;
            p1baseFacNext = p1baseFacTo;
        }

        // Move the bridges
        const pi = 3.141592653589793;
        local a = p1baseFacNext.z*pi/180.0;
        local n1 = vector(cos(a),sin(a),0);
        local n2 = vector(n1.y,-n1.x,0);
        // Bridge 1 can extend and retract
        local p1bridge1OutAt = (Object.Position(P1Bridge1)-p1basePosAt).Dot(n1);
        local p1bridge1OutTo = p1fBridge1*17.0;
        local p1bridge1OutNext;
        if (GetData("Animating")) {
            p1bridge1OutNext = LinearNext(
                p1bridge1OutAt, p1bridge1OutTo, 4.0, dt);
        } else {
            p1bridge1OutNext = p1bridge1OutTo;
        }
        local p1bridge1PosNext = p1basePosNext+n1*p1bridge1OutNext;
        local p1bridge1FacNext = p1baseFacNext+vector(0,0,90);
        local p1bridge2PosNext = p1basePosNext+n2*17.0;
        local p1bridge2FacNext = p1baseFacNext*1.0; // ensure a copy!

        //print("POSITIONS and FACINGS:");
        print("basePos at "+p1basePosAt.z+", next "+p1basePosNext.z+", to "+p1basePosTo.z);
        // print("    Fac at "+baseFacAt.z+", next "+baseFacNext.z+", to "+baseFacTo.z);
        // print(" B1 out at "+bridge1OutAt+", next "+bridge1OutNext+", to "+bridge1OutTo);
        //print("  bridge1 next: "+bridge1PosNext+" - "+bridge1FacNext);
        //print("  bridge2 next: "+bridge2PosNext+" - "+bridge2FacNext);

        Object.Teleport(P1Base, p1basePosNext, p1baseFacNext);
        Object.Teleport(P1Bridge1, p1bridge1PosNext, p1bridge1FacNext);
        Object.Teleport(P1Bridge2, p1bridge2PosNext, p1bridge2FacNext);

        // stop animating when everything is at its end point/
        if ((p1basePosNext-p1basePosTo).Length()==0.0
        && (p1baseFacNext-p1baseFacTo).Length()==0.0
        && p1bridge1OutNext==p1bridge1OutTo) {
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
