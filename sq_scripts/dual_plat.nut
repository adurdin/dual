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
    // TODO: track all the fixed parts with links
    P1Base = 0;
    P1Bridge1 = 0;
    P1Bridge2 = 0;
    P2Base = 0;
    P2Top = 0;
    P2Ladder = 0;
    P2Bridge1 = 0;
    P2Bridge2 = 0;

    function OnSim() {
        if (message().starting) {
            // parts
            P1Base = ObjID("P1Base");
            P1Bridge1 = ObjID("P1Bridge1");
            P1Bridge2 = ObjID("P1Bridge2");
            P2Base = ObjID("P2Base");
            P2Top = ObjID("P2Top");
            P2Ladder = ObjID("P2Ladder");
            P2Bridge1 = ObjID("P2Bridge1");
            P2Bridge2 = ObjID("P2Bridge2");
            // starting positions
            SetData("P1RootPos", Property.Get(P1Base, "PhysState", "Location"));
            SetData("P1RootFac", Property.Get(P1Base, "PhysState", "Facing"));
            SetData("P2RootPos", Property.Get(P2Base, "PhysState", "Location"));
            SetData("P2RootFac", Property.Get(P2Base, "PhysState", "Facing"));
            // initial configuration
            SetData("Animating", false);
            SetData("P1Rise", 0);
            SetData("P1Rot", 0);
            SetData("P1RotDir", 1);
            SetData("P1Bridge1", 0);
            SetData("P2Rise", 0);
            SetData("P2Rot", 0);
            SetData("P2RotDir", 1);
            SetData("P2Bridge1", 0);
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
        // Pillar 1 -------------------------------------------------

        local p1rootPos = GetData("P1RootPos");
        local p1rootFac = GetData("P1RootFac");
        local p1fRise = GetData("P1Rise").tofloat();
        local p1fRot = GetData("P1Rot").tofloat();
        local p1fRotDir = GetData("P1RotDir").tofloat();
        local p1fBridge1 = GetData("P1Bridge1").tofloat();

        local p1basePosAt = Object.Position(P1Base);
        local p1baseFacAt = Object.Facing(P1Base);
        // movement targets are hard-coded here:
        local p1basePosTo = p1rootPos+vector(0,0,48)*p1fRise;
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
        local n2 = vector(-n1.y,n1.x,0);
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
        local p1bridge2PosNext = p1basePosNext+n2*-17.0;
        local p1bridge2FacNext = p1baseFacNext*1.0; // ensure a copy!

        // Pillar 2 --------------------------------------------------

        local p2rootPos = GetData("P2RootPos");
        local p2rootFac = GetData("P2RootFac");
        local p2fRise = GetData("P2Rise").tofloat();
        local p2fRot = GetData("P2Rot").tofloat();
        local p2fRotDir = GetData("P2RotDir").tofloat();
        local p2fBridge1 = GetData("P2Bridge1").tofloat();

        local p2basePosAt = Object.Position(P2Base);
        local p2baseFacAt = Object.Facing(P2Base);
        // movement targets are hard-coded here:
        local p2basePosTo = p2rootPos+vector(0,0,48)*p2fRise;
        local p2baseFacTo = p2rootFac+vector(0,0,90)*p2fRot;

        // Move the base
        local p2basePosNext;
        local p2baseFacNext;
        if (GetData("Animating")) {
            p2basePosNext = p2basePosTo*1.0; // ensure a copy!
            p2basePosNext.z = LinearNext(
                p2basePosAt.z, p2basePosTo.z, 8.0, dt);

            p2baseFacNext = p2baseFacTo*1.0; // ensure a copy!
            p2baseFacNext.z = FacingNext(
                p2baseFacAt.z, p2baseFacTo.z, p2fRotDir<0, 30.0, dt);
        } else {
            p2basePosNext = p2basePosTo;
            p2baseFacNext = p2baseFacTo;
        }

        // Move the bridges
        const pi = 3.141592653589793;
        local a = p2baseFacNext.z*pi/180.0;
        local n1 = vector(cos(a),sin(a),0);
        local n2 = vector(-n1.y,n1.x,0);
        // Bridge 1 can extend and retract
        local p2bridge1OutAt = (Object.Position(P2Bridge1)-p2basePosAt).Dot(n2);
        local p2bridge1OutTo = p2fBridge1*17.0;
        local p2bridge1OutNext;
        if (GetData("Animating")) {
            p2bridge1OutNext = LinearNext(
                p2bridge1OutAt, p2bridge1OutTo, 4.0, dt);
        } else {
            p2bridge1OutNext = p2bridge1OutTo;
        }
        local p2bridge1PosNext = p2basePosNext+n2*p2bridge1OutNext;
        local p2bridge1FacNext = p2baseFacNext+vector(0,0,180);
        local p2bridge2PosNext = p2basePosNext+vector(0,0,48)+n1*-17.0;
        local p2bridge2FacNext = p2baseFacNext+vector(0,0,270);

        // Also move the top and the ladder
        local p2topPosNext = p2basePosNext+vector(0,0,48);
        local p2topFacNext = p2baseFacNext*1.0; // ensure a copy!

        // TODO: rotate the ladder (ugh)
        local ladderOffset = vector(3,-2,25);
        local p2ladderPosNext = p2basePosNext+ladderOffset;
        local p2ladderFacNext = vector();

        // Apply to the objects ----------------------------------------

        Object.Teleport(P1Base, p1basePosNext, p1baseFacNext);
        Object.Teleport(P1Bridge1, p1bridge1PosNext, p1bridge1FacNext);
        Object.Teleport(P1Bridge2, p1bridge2PosNext, p1bridge2FacNext);

        Object.Teleport(P2Base, p2basePosNext, p2baseFacNext);
        Object.Teleport(P2Top, p2topPosNext, p2topFacNext);
        Object.Teleport(P2Ladder, p2ladderPosNext, p2ladderFacNext);
        Object.Teleport(P2Bridge1, p2bridge1PosNext, p2bridge1FacNext);
        Object.Teleport(P2Bridge2, p2bridge2PosNext, p2bridge2FacNext);

        // stop animating when everything is at its end point/
        if (p1basePosNext.z==p1basePosTo.z
        && p1baseFacNext.z==p1baseFacTo.z
        && p1bridge1OutNext==p1bridge1OutTo
        && p2basePosNext.z==p2basePosTo.z
        && p2baseFacNext.z==p2baseFacTo.z
        && p2bridge1OutNext==p2bridge1OutTo) {
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
        if (message().from==ObjID("SwitchP1Bridge1Toggle")) {
            SetData("P1Bridge1", 1);
        } else if (message().from==ObjID("SwitchP1Rot90CW")) {
            local rot = GetData("P1Rot");
            rot = (rot+3)%4;
            SetData("P1Rot", rot);
            SetData("P1RotDir", -1);
        } else if (message().from==ObjID("SwitchP1RiseToggle")) {
            if (GetData("P1Rise")==0) {
                SetData("P1Rise", 1);
            } else {
                SetData("P1Rise", 0);
            }
        } else if (message().from==ObjID("SwitchP2Bridge1Toggle")) {
            SetData("P2Bridge1", 1);
        } else if (message().from==ObjID("SwitchP2Rot180AndRiseToggle")) {
            local rot = GetData("P2Rot");
            rot = (rot+2)%4;
            SetData("P2Rot", rot);
            SetData("P2RotDir", -1);
            if (GetData("P2Rise")==0) {
                SetData("P2Rise", 1);
            } else {
                SetData("P2Rise", 0);
            }
        } else if (message().from==ObjID("SwitchP1AndP2Rot90CCW")) {
            local rot = GetData("P1Rot");
            rot = (rot+1)%4;
            SetData("P1Rot", rot);
            SetData("P1RotDir", 1);
            rot = GetData("P2Rot");
            rot = (rot+1)%4;
            SetData("P2Rot", rot);
            SetData("P2RotDir", 1);
        }
        StartAnimating();
    }

    function OnTurnOff() {
        if (message().from==ObjID("SwitchP1Bridge1Toggle")) {
            SetData("P1Rise", 0);
            SetData("P1Rot", 0);
            SetData("P1RotDir", -1);
            SetData("P1Bridge1", 0);
        } else if (message().from==ObjID("SwitchP2Bridge1Toggle")) {
            SetData("P2Bridge1", 0);
        }
        StartAnimating();
    }
}
