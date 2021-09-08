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

    function OnDoorOpen() { PrintDoorMessage(); }
    function OnDoorOpening() { PrintDoorMessage(); }
    function OnDoorClose() { PrintDoorMessage(); }
    function OnDoorClosing() { PrintDoorMessage(); }
    function OnDoorHalt() { PrintDoorMessage(); }
}

class DualPlat extends DualPuzzleDoor
{
}

class DualRotBridge extends DualPuzzleDoor
{
}

/*************************************/

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

    /* messages from levers and knobs */

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

    /* messages from platforms */

    // TODO

    /* manage all the things! */

    function Update() {
        // add and remove links. move the elevators. rotate the doors.
        // extend the platforms. just a whole ton of things to do!
        // and keep track of if we are in motion or not.

        // TODO
    }
}
