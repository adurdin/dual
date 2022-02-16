class LibraryRoom extends SqRootScript
{
    function OnPlayerRoomEnter() {
        local puz = ObjID("LibraryPuzzle");
        local params = userparams();
        if (puz && "LibraryRoom" in params) {
            SendMessage(puz, "LibraryRoom", params.LibraryRoom);
        }
    }
}

class LibraryPuzzle extends SqRootScript
{
    /* LibraryPuzzle: Library puzzle, that requires the player to walk between
    rooms of the library in the correct order.

        1. Create a TrigTrap, name it "LibraryPuzzle", and attach the
        LibraryPuzzle script.

        2. Set the Design Note parameter "LibraryPuzzle" to the magic word.

        3. Add a ControlDevice link from the trap to whatever it should turn
           on when the puzzle is successfully completed.

        4. Create a room archetype for each letter in the magic word.

        5. With each room archetype:
            a) Set the Design Note parameter "LibraryRoom" to the letter.
            b) Attach the "LibraryRoom" script.
    */

    // -- Messages

    function OnLibraryRoom()
    {
        local letter = message().data;
        AdvancePuzzle(letter);
    }

    function OnTurnOn()
    {
        CompletePuzzle();
    }

    function OnTurnOff()
    {
        ResetPuzzle();
    }

    // -- Puzzle logic

    function AdvancePuzzle(letter)
    {
        local progress = GetProgress();
        local solution = GetSolution();

        // Ignore if we get the same letter again.
        if (endswith(progress, letter))
            return;

        // Advance the progress
        progress += letter;
        if (progress.len() > solution.len()) {
            progress = progress.slice(progress.len() - solution.len());
        }
        SetProgress(progress);

        // Check for success or failure
        if (progress == solution) {
            CompletePuzzle();
        }
    }

    function CompletePuzzle()
    {
        Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
    }

    function ResetPuzzle()
    {
        SetProgress("");
    }

    // -- Data management

    function GetSolution()
    {
        local params = userparams();
        local value = "";
        if ("LibraryPuzzle" in params) {
            value = params.LibraryPuzzle.tostring();
        }
        return value;
    }

    function GetProgress()
    {
        local progress = GetData("LibraryPuzzleProgress");
        if (progress == null) {
            progress = "";
        }
        return progress;
    }

    function SetProgress(progress)
    {
        print("LibraryPuzzle: "+progress);
        SetData("LibraryPuzzleProgress", progress);
    }
}

class GantryPuzzle extends SqRootScript
{
    function OnSim() {
        // We need to be sure to kick this off only after the existence traps
        // have done their Sim stuff. I don't know if Sim messages happen
        // in any particular order, so let's just be cautious:
        PostMessage(self, "Setup");
    }

    function OnSetup() {
        ActivateScenario(0);
    }

    function ActivateScenario(n) {
        local relayRubble = ObjID("RubbleGantryScenario");
        local relayMiddle = ObjID("MiddleGantryScenario");
        local relayWindow = ObjID("WindowGantryScenario");
        if (n==0) {
            SendMessage(relayRubble, "TurnOn");
            SendMessage(relayMiddle, "TurnOff");
            SendMessage(relayWindow, "TurnOff");
        } else if (n==1) {
            SendMessage(relayRubble, "TurnOff");
            SendMessage(relayMiddle, "TurnOn");
            SendMessage(relayWindow, "TurnOff");
        } else {
            SendMessage(relayRubble, "TurnOff");
            SendMessage(relayMiddle, "TurnOff");
            SendMessage(relayWindow, "TurnOn");
        }
    }

    function OnMovingTerrainWaypoint() {
        local pt = message().waypoint;
        if (pt==ObjID("TerrPtGantry1")) {
            ActivateScenario(0);
        } else if (pt==ObjID("TerrPtGantry2") || pt==ObjID("TerrPtGantry4")) {
            ActivateScenario(1);
        } else {
            ActivateScenario(2);
        }
    }
}
