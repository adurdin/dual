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

    function OnBeginScript() {
        if (! IsDataSet("Animating")) SetData("Animating", 0);
        if (! IsDataSet("P1Rise")) SetData("P1Rise", 0);
        if (! IsDataSet("P1Rot")) SetData("P1Rot", 0);
        if (! IsDataSet("P1Bridge1")) SetData("P1Bridge1", 0);
    }

    function OnSim() {
        if (message().starting) {
            P1Base = ObjID("P1Base");
            P1Bridge1 = ObjID("P1Bridge1");
            P1Bridge2 = ObjID("P1Bridge2");
            local pos = Property.Get(P1Base, "PhysState", "Location");
            local fac = Property.Get(P1Base, "PhysState", "Facing");
            SetData("P1BasePos", pos);
            SetData("P1BaseFac", fac);
            UpdatePositions();
        }
    }

    function UpdatePositions() {
        // TODO: animating!
        local basePos = GetData("P1BasePos");
        local baseFac = GetData("P1BaseFac");
        local vRise = GetData("P1Rise").tofloat();
        local vRot = GetData("P1Rot").tofloat();
        local vBridge1 = GetData("P1Bridge1").tofloat();

        local targetPos = basePos;
        targetPos += vector(0,0,48)*vRise;
        local targetFac = baseFac;
        targetFac += vector(0,0,90)*vRot;

        const halfpi = 1.5707963267948966;
        local n1 = vector(cos(vRot*halfpi),sin(vRot*halfpi),0);
        local n2 = vector(n1.y,-n1.x,0);

        local bridge1TargetPos = targetPos;
        if (GetData("P1Bridge1"))
            bridge1TargetPos += n1*17.0;
        local bridge1TargetFac = targetFac+vector(0,0,90);
        local bridge2TargetPos = targetPos+n2*17.0;
        local bridge2TargetFac = targetFac;

        print("POSITIONS and FACINGS:");
        print("  base: "+targetPos+" - "+targetFac);
        print("  bridge1: "+bridge1TargetPos+" - "+bridge1TargetFac);
        print("  bridge2: "+bridge2TargetPos+" - "+bridge2TargetFac);

        Object.Teleport(P1Base, targetPos, targetFac);
        Object.Teleport(P1Bridge1, bridge1TargetPos, bridge1TargetFac);
        Object.Teleport(P1Bridge2, bridge2TargetPos, bridge2TargetFac);

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
        UpdatePositions();
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
        UpdatePositions();
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
