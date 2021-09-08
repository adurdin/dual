DOOR_ACTION_STRING <- {
    [eDoorAction.kOpen] = "kOpen",
    [eDoorAction.kClose] = "kClose",
    [eDoorAction.kOpening] = "kOpening",
    [eDoorAction.kClosing] = "kClosing",
    [eDoorAction.kHalt] = "kHalt",
};

DOOR_STATUS_STRING <- {
    [eDoorStatus.kDoorClosed] = "kDoorClosed",
    [eDoorStatus.kDoorOpen] = "kDoorOpen",
    [eDoorStatus.kDoorClosing] = "kDoorClosing",
    [eDoorStatus.kDoorOpening] = "kDoorOpening",
    [eDoorStatus.kDoorHalt] = "kDoorHalt",
    [eDoorStatus.kDoorNoDoor] = "kDoorNoDoor",
};

class DualPuzzleDoor extends SqRootScript
{
    function PrintDoorMessage() {
        local state = Door.GetDoorState(self);
        local actionType = message().ActionType;
        local prevActionType = message().PrevActionType;
        local isProxy = message().isProxy;
        print(Object.GetName(self) + ": "
            + message().message
            + ", " + DOOR_ACTION_STRING[actionType]
            + ", prev " + DOOR_ACTION_STRING[prevActionType]
            + ", proxy " + isProxy
            + "; state " + DOOR_STATUS_STRING[state]);
    }

    function PrintOtherMessage() {
        local state = Door.GetDoorState(self);
        print(Object.GetName(self) + ": "
            + message().message
            + "; state " + DOOR_STATUS_STRING[state]);
    }

    function OnTurnOn() {
        PrintOtherMessage();
        Door.OpenDoor(self);
    }

    function OnTurnOff() {
        PrintOtherMessage();
        Door.CloseDoor(self);
    }

    function OnDoorOpen() { PrintDoorMessage();
        SendMessage(ObjID("AscensionPuzzle"), message().message); }
    function OnDoorOpening() { PrintDoorMessage();
        SendMessage(ObjID("AscensionPuzzle"), message().message); }
    function OnDoorClose() { PrintDoorMessage();
        SendMessage(ObjID("AscensionPuzzle"), message().message); }
    function OnDoorClosing() { PrintDoorMessage();
        SendMessage(ObjID("AscensionPuzzle"), message().message); }
    function OnDoorHalt() { PrintDoorMessage();
        SendMessage(ObjID("AscensionPuzzle"), message().message); }
}

class DualPlat extends SqRootScript
{
    function OnCall() {
        SendMessage(ObjID("AscensionPuzzle"), "PlatStarted");
    }

    function OnMovingTerrainWaypoint() {
        SendMessage(ObjID("AscensionPuzzle"), "PlatReachedWaypoint", message().waypoint);
    }
}

class DualRotBridge extends DualPuzzleDoor
{
}

/*************************************/

const COLLTYPE_BOUNCE = 0x1;
const COLLTYPE_NONE = 0x0;

/** AscensionPuzzle controls all the state of the puzzle. Levers and
 *  knobs send their inputs here; the internal state of the puzzle is
 *  updated accordingly; then the appropriate messages are sent to
 *  the moving platforms. This ensures the puzzle state remains
 *  consistent and the moving platforms are brought in line with the
 *  state; and also that inputs are managed while the platforms are
 *  in motion.
 */
class AscensionPuzzle extends SqRootScript
{
    function OnSim() {
        if (message().starting) {
            local P1Rise = ObjID("P1Rise");
            local P1Bridge1 = ObjID("P1Bridge1");
            local P1Bridge2 = ObjID("P1Bridge2");
            local P1Bridge1Rising = ObjID("P1Bridge1Rising");
            local P1Bridge2Rising = ObjID("P1Bridge2Rising");
            // Property.SetSimple(P1Bridge1, "CollisionType", COLLTYPE_BOUNCE);
            // Property.SetSimple(P1Bridge2, "CollisionType", COLLTYPE_BOUNCE);
            // Property.SetSimple(P1Bridge1Rising, "CollisionType", COLLTYPE_NONE);
            // Property.SetSimple(P1Bridge2Rising, "CollisionType", COLLTYPE_NONE);
        }
    }

    function OnTurnOn() {
        local P1Rise = ObjID("P1Rise");
        local P1Bridge1 = ObjID("P1Bridge1");
        local P1Bridge2 = ObjID("P1Bridge2");
        local P1Bridge1Rising = ObjID("P1Bridge1Rising");
        local P1Bridge2Rising = ObjID("P1Bridge2Rising");
        local P1Bridge1Vis = ObjID("P1Bridge1Vis");
        local P1Bridge2Vis = ObjID("P1Bridge2Vis");
        if (message().from==ObjID("P1RotSwitch")) {
            SendMessage(P1Bridge1, "TurnOn");
            SendMessage(P1Bridge2, "TurnOn");
        } else if (message().from==ObjID("P1RiseSwitch")) {
            //SendMessage(P1Rise, "TurnOn");
            //SendMessage(P1Bridge1Rising, "TurnOn");
            SendMessage("P1TopPt", "TurnOn");
        }
    }

    function OnTurnOff() {
        local P1Rise = ObjID("P1Rise");
        local P1Bridge1 = ObjID("P1Bridge1");
        local P1Bridge2 = ObjID("P1Bridge2");
        local P1Bridge1Rising = ObjID("P1Bridge1Rising");
        local P1Bridge2Rising = ObjID("P1Bridge2Rising");
        if (message().from==ObjID("P1RotSwitch")) {
            SendMessage(P1Bridge1, "TurnOff");
            SendMessage(P1Bridge2, "TurnOff");
        } else if (message().from==ObjID("P1RiseSwitch")) {
            //SendMessage(P1Rise, "TurnOff");
            //SendMessage(P1Bridge1Rising, "TurnOff");
            SendMessage("P1BottomPt", "TurnOn");
        }
    }

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
