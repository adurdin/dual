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
