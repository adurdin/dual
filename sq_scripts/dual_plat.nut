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
        local fBridge1 = GetData("P1Bridge1").tofloat();

        local basePosAt = Object.Position(P1Base);
        local basePosTo = rootPos+vector(0,0,48)*fRise;
        local baseFacAt = Object.Facing(P1Base);
        local baseFacTo = rootFac+vector(0,0,90)*fRot;
        // TODO: cw or ccw needs to be a parameter!
        local basePosNext;
        local baseFacNext;

        if (GetData("Animating")) {
            const MAX_POS_SPEED = 8.0;
            const MAX_FAC_SPEED = 30.0;
            local posSpeed = (basePosTo-basePosAt)/dt;
            local facSpeed = (baseFacTo-baseFacAt)/dt;
            if (abs(posSpeed.z)>MAX_POS_SPEED) {
                posSpeed.z = (posSpeed.z<0?-MAX_POS_SPEED:MAX_POS_SPEED);
                basePosNext = basePosAt+posSpeed*dt;
            } else {
                basePosNext = basePosTo;
            }
            if (abs(facSpeed.z)>MAX_FAC_SPEED) {
                facSpeed.z = (facSpeed.z<0?-MAX_FAC_SPEED:MAX_FAC_SPEED);
                baseFacNext = baseFacAt+facSpeed*dt;
            } else {
                baseFacNext = baseFacTo;
            }
        } else {
            basePosNext = basePosTo;
            baseFacNext = baseFacTo;
        }

        print("basePos at "+basePosAt.z+", next "+basePosNext.z+", to "+basePosTo.z);
        print("    Fac at "+baseFacAt.z+", next "+baseFacNext.z+", to "+baseFacTo.z);

        // stop animating when everything is at its end point/
        if ((basePosNext-basePosTo).Length()==0.0
        && (baseFacNext-baseFacTo).Length()==0.0) {
            SetData("Animating", false);
        }

/*
        const halfpi = 1.5707963267948966;
        local n1 = vector(cos(fRot*halfpi),sin(fRot*halfpi),0);
        local n2 = vector(n1.y,-n1.x,0);

        local bridge1TargetPos = targetPos+n1*17.0*fBridge1*step;
        local bridge1TargetFac = targetFac+vector(0,0,90)*step;
        local bridge2TargetPos = targetPos+n2*17.0*step;
        local bridge2TargetFac = targetFac*step;

        print("POSITIONS and FACINGS:");
        print("  base: "+targetPos+" - "+targetFac);
        print("  bridge1: "+bridge1TargetPos+" - "+bridge1TargetFac);
        print("  bridge2: "+bridge2TargetPos+" - "+bridge2TargetFac);
*/
        Object.Teleport(P1Base, basePosNext, baseFacNext);
        //Object.Teleport(P1Bridge1, bridge1TargetPos, bridge1TargetFac);
        //Object.Teleport(P1Bridge2, bridge2TargetPos, bridge2TargetFac);

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
        } else if (message().from==ObjID("P1RiseSwitch")) {
            SetData("P1Rise", 1);
        }
        StartAnimating();
    }

    function OnTurnOff() {
        if (message().from==ObjID("P1Bridge1Switch")) {
            SetData("P1Rise", 0);
            SetData("P1Rot", 0);
            SetData("P1Bridge1", 0);
        } else if (message().from==ObjID("P1RotSwitch")) {
            local rot = GetData("P1Rot");
            rot = (rot+1)%4;
            SetData("P1Rot", rot);
        } else if (message().from==ObjID("P1RiseSwitch")) {
            SetData("P1Rise", 0);
        }
        StartAnimating();
    }
/*
    function OnPlatStarted() {
        print(message().message + " from " + Object.GetName(message().from));
        SetRisingMode(true);
        // okay, with this we _can_ rotate an object that is PhysAttached
        // to the elevator! cant stand on it though (with or without the
        // rotation, which is odd? but can live without).
        SetData("PrevTime", GetTime());
        PostMessage(self, "Foo");
    }

    function OnPlatReachedWaypoint() {
        print(message().message + " from " + Object.GetName(message().from));
        local pt = message().data;
        //if (pt==ObjID("P1TopPt")) {
        //} else if (pt==ObjID("P1BottomPt")) {
        //}
        SetRisingMode(false);
    }

    function OnFoo() {
        local dt = GetTime()-GetData("PrevTime");
        local o = ObjID("P1Bridge1Rising");
        local fac = Property.Get(o, "PhysState", "Facing");
        fac.z = fac.z + 30*dt;
        //fac.z = 3.14/2;
        Property.Set(o, "PhysState", "Facing", fac);
        print("fac: " + fac);
        if (GetData("RisingMode")) {
            SetData("PrevTime", GetTime());
            PostMessage(self, "Foo");
        }
    }

    function SetRisingMode(risingMode) {
        print("SetRisingMode: "+risingMode);
        SetData("RisingMode", risingMode);
        local P1Rise = ObjID("P1Rise");
        local P1Bridge1 = ObjID("P1Bridge1");
        local P1Bridge2 = ObjID("P1Bridge2");
        local P1Bridge1Rising = ObjID("P1Bridge1Rising");
        local P1Bridge2Rising = ObjID("P1Bridge2Rising");
        local P1Bridge1Vis = ObjID("P1Bridge1Vis");

        // Link.DestroyMany("PhysAttach", "*", P1Rise);
        // if (risingMode) {
        //     Link.Create("PhysAttach", P1Bridge1, P1Rise);
        //     Link.Create("PhysAttach", P1Bridge2, P1Rise);
        // }

        // Property.SetSimple(P1Bridge1, "CollisionType", risingMode?COLLTYPE_NONE:COLLTYPE_BOUNCE);
        // Property.SetSimple(P1Bridge2, "CollisionType", risingMode?COLLTYPE_NONE:COLLTYPE_BOUNCE);
        // Property.SetSimple(P1Bridge1Rising, "CollisionType", risingMode?COLLTYPE_BOUNCE:COLLTYPE_NONE);
        // Property.SetSimple(P1Bridge2Rising, "CollisionType", risingMode?COLLTYPE_BOUNCE:COLLTYPE_NONE);
        // local pos = Object.Position(risingMode?P1Bridge1:P1Bridge1Rising);
        // local fac = Object.Facing(risingMode?P1Bridge1:P1Bridge1Rising);
        // Object.Teleport(risingMode?P1Bridge1Rising:P1Bridge1, pos, fac);
        // Link.DestroyMany("DetailAttachement", P1Bridge1Vis, "*");
        // local link = Link.Create("DetailAttachement", P1Bridge1Vis, risingMode?P1Bridge1Rising:P1Bridge1);
    }
*/
/*
    function Reset() {
        SetData("P1Rot", 0);
        SetData("P1Rise", 0);
        SetData("P1Bridge1", 0);
        SetData("P2Rot", 0);
        SetData("P2Rise", 0);
        SetData("P2Bridge1", 0);
    }

    function Endgame() {
        // TODO
    }

    function ToggleVar(var) {
        local v = GetData(var);
        v = (v ? 0 : 1);
        SetData(var, v);
        Update();
    }

    function RotateVar(var, direction) {
        // positive direction is anticlockwise
        local v = GetData(var);
        v = v+direction.tointeger()%4;
        v = (v+4)%4;
        SetData(var, v);
    }
*/
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
    /* messages from platforms */

    // TODO

    /* manage all the things! */
/*
    function Update() {
        // add and remove links. move the elevators. rotate the doors.
        // extend the platforms. just a whole ton of things to do!
        // and keep track of if we are in motion or not.

        // TODO
    }
*/
}
