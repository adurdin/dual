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
