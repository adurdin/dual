// TODO: remember to put the wardrobe thingy back when deleting the orange brushes!

    /** HERE: TODO: okay, so i want as much as possible to keep the behaviour
        triggered only by reaching the relevant patrol points. that way other
        ai behaviours (fleeing, combat, etc) can override it, and when calmed
        down and going back to patrolling, we can retrigger, maybe?

            (problem: if we only trigger when patrolling to the wait point, and
            then something escalates while there, wont resuming patrol try to
            go to the embark point, and not retrigger?

            maybe while waiting we turn off patrolling, and adopt a script that,
            on alert, sets AICurrentPatrol to the wait point and reenables
            patrolling (to come back after calming down)? this could maybe be
            done via the conversation abort steps sending a "ResumePatrolling"
            message with data=WaitPointName, rather than tracking state in
            the script?

        so far it seems that pathfinding breaking down isnt breaking the
        conversation triggers though, like it did the watches.

        ...


    */


DEBUG_ELEVATOR <- false;

class ElevatorPatroller extends SqRootScript {
    function DebugLogMessage() {
        if (DEBUG_ELEVATOR) print("**** "+message().message
            +" to:"+Object_Description(self)
            +" from:"+Object_Description(message().from)
            +" data:"+message().data
            +" data2:"+message().data2
            +" data3:"+message().data3
            +" ****");
    }

    function OnMessage() {
        DebugLogMessage();
    }

    function OnSim() {
        if (message().starting) {
            SetOneShotTimer("DumpPatrolStatus", 1.0);
        }
    }

    function OnTimer() {
        if (message().name=="DumpPatrolStatus") {
            local status = GetProperty("AI_Patrol");
            local link = Link.GetOne("AICurrentPatrol", self);
            local msg;
            if (status) {
                msg = "patrolling to "+Object_Description(LinkDest(link));
            } else {
                msg = "NOT PATROLLING (to "+Object_Description(LinkDest(link))+")";
            }
            if (DEBUG_ELEVATOR) print("----------------------------- "+msg);
            SetOneShotTimer("DumpPatrolStatus", 1.0);
        }

        if (message().name=="ResetPatrol") {
            DebugLogMessage();
            local trolName = message().data;
            if (trolName==null) {
                if (DEBUG_ELEVATOR) print("NOTE: no trolName");
                return;
            }
            local trol = Object.Named(trolName);
            if (trol==0) {
                if (DEBUG_ELEVATOR) print("ERROR: cant find object named "+trolName);
                return;
            }
            Link.Create("AICurrentPatrol", self, trol);
            // // HACK! but not working?
            // AI.ClearGoals(self);
            // Object.Teleport(self, vector(), vector(), self); // HACK: force the AI to re-pathfind.
            SetProperty("AI_Patrol", true);
            // Object.Teleport(self, Object.Position(trol), Object.Facing(self)); // HACK!
            // // Property.SetSimple(self, "AI_Patrol", true);
            local link = Link.GetOne("AICurrentPatrol", self);
            if (DEBUG_ELEVATOR) print("New patrol target: "+Object_Description(LinkDest(link)));
        }
    }

    function OnPatrolPoint() {
        DebugLogMessage();
        local trol = message().patrolObj;
        // TODO - how do we _properly_ determine if we should react to this point?
        //        i dont actually know!
        // if (Property.Possessed(trol, "AI_WtchPnt")) {
        //     if (DEBUG_ELEVATOR) print("@@@@ Created Watch");
        //     Link.Create("AIWatchObj", self, trol);
        //     // AI.ClearGoals(self);
        // }
        if (Property.Possessed(trol, "AI_Converation")) {
            if (! Link.AnyExist("AIConversationActor", trol)) {
                if (DEBUG_ELEVATOR) print("@@ Creating actor link.");
                local link = Link.Create("AIConversationActor", trol, self);
                LinkTools.LinkSetData(link, "Actor ID", 1);
            }
            local result = AI.StartConversation(trol);
            if (DEBUG_ELEVATOR) print("@@@@ Started conversation on "+Object_Description(trol)+" result: "+result);
        }
    }

    function OnPatrolTo() {
        DebugLogMessage();
        local trol;
        local trolName = message().data;
        if (trolName==null) {
            if (DEBUG_ELEVATOR) print("ERROR: no trolName");
            Reply(false);
            return;
        }
        trol = Object.Named(trolName);
        if (trol==0) {
            if (DEBUG_ELEVATOR) print("ERROR: cant find object named "+trolName);
            Reply(false);
            return;
        }
        // if (DEBUG_ELEVATOR) print("Patrolling to "+Object_Description(trol));
        // // Property.SetSimple(self, "AI_Patrol", false);
        // local link = Link.GetOne("AICurrentPatrol", self);
        // if (DEBUG_ELEVATOR) print("Old patrol target: "+Object_Description(LinkDest(link)));
        // Link.DestroyMany("AICurrentPatrol", self, 0);
        // /////////////////////////
        // // SO: this doesnt work, because once at the top of the elevator, the ai
        // // thinks it is in the path cell at the bottom. this is hard to resolve!
        // // TO DEAL WITH THIS in the elevator demo, i had the ai's patrol path be
        // // continuous up and down the elevator shaft. this let it walk off when
        // // going up to the top.
        // // BUT: that didnt seem to work reliably when trying to path back onto
        // // the elevator!
        // // // HACK! but not working:
        // // AI.ClearGoals(self);
        // // HACK! but not working:
        Object.Teleport(self, vector(), vector(), self); // HACK: force the AI to re-pathfind.
        // Object.Teleport(self, Object.Position(trol), Object.Facing(self)); // HACK!
        // Link.Create("AICurrentPatrol", self, trol);
        // // Property.SetSimple(self, "AI_Patrol", true);
        // link = Link.GetOne("AICurrentPatrol", self);
        // if (DEBUG_ELEVATOR) print("New patrol target: "+Object_Description(LinkDest(link)));
    }

    function OnElevArrived() {
        DebugLogMessage();
        local terr = message().data;
        SetData("ElevatorAt", Object.GetName(terr));
/*
        if (IsOnElevator()) {
            SetOnElevator(false);
            // Just patrol off the elevator, auto-selecting the patrol.
            // point. No need to do anything else!
            if (DEBUG_ELEVATOR) print("################################################");
            local link = Link.GetOne("AICurrentPatrol", self);
            if (DEBUG_ELEVATOR) print("Current patrol: "+Object_Description(LinkDest(link)));
            SetProperty("AI_Patrol", false);
            // AI.ClearGoals(self);
            Link.DestroyMany("AICurrentPatrol", self, 0);
            SetProperty("AI_Patrol", true);
            link = Link.GetOne("AICurrentPatrol", self);
            if (DEBUG_ELEVATOR) print("New patrol: "+Object_Description(LinkDest(link)));
        } else {
            if (DEBUG_ELEVATOR) print("Not on the elevator????");
        }
        // GetProperty("AI_Patrol")
        // if (! GetProperty("AI_Patrol")) {
        // }
        // TODO: if we are waiting for the elevator, now we need to get on it!
*/
    }

    function OnElevDeparted() {
        DebugLogMessage();
        local terr = message().data;
        ClearData("ElevatorAt");
    }

    function OnWaitForElevatorArrival() {
        DebugLogMessage();
        local terrName = message().data;
        local embarkName = message().data2;
        local elevatorReady = (GetData("ElevatorAt")==terrName);
        if (elevatorReady) {
            if (DEBUG_ELEVATOR) print("#### Elevator is ready");
            // local embark = Object.Named(embarkName);
            // if (! embark) {
            //     if (DEBUG_ELEVATOR) print("ERROR: no embark point named "+embarkName);
            //     return;
            // }
            // if (Property.Possessed(embark, "AI_WtchPnt")) {
            //     Link.Create("AIWatchObj", self, embark);
            //     AI.ClearGoals(self);
            // } else {
            //     if (DEBUG_ELEVATOR) print("ERROR: embark point "+Object_Description(embark)+" has no Watch Link Defaults.");
            //     return;
            // }
            Reply(false);
        } else {
            if (DEBUG_ELEVATOR) print("#### Elevator is NOT READY");
            // We rely on the pseudoscript to keep on trying over time.
            Reply(true);
        }
    }

    function OnStopWaitingForElevator() {
        DebugLogMessage();
        if (DEBUG_ELEVATOR) print("########## stop waiting");
        local trolName = message().data;
        if (trolName==null) {
            if (DEBUG_ELEVATOR) print("NOTE: no trolName");
            Reply(false);
            return;
        }
        local trol = Object.Named(trolName);
        if (trol==0) {
            if (DEBUG_ELEVATOR) print("ERROR: cant find object named "+trolName);
            Reply(false);
            return;
        }
        if (DEBUG_ELEVATOR) print("Changing patrol to "+Object_Description(trol));
        // // Property.SetSimple(self, "AI_Patrol", false);
        local link = Link.GetOne("AICurrentPatrol", self);
        if (DEBUG_ELEVATOR) print("Old patrol target: "+Object_Description(LinkDest(link)));
        Link.DestroyMany("AICurrentPatrol", self, 0);
        SetProperty("AI_Patrol", false);
        SetOneShotTimer("ResetPatrol", 1.5, trolName);
    }
}

class ElevatorNotify extends SqRootScript {
    /* Put this on the Vator class so that it can reliably track
    ** which TerrPt it is stopped at (if any). An elevator with
    ** this script will:
    **
    **   - notify each TerrPt it stops at with an ElevArrived message.
    **   - notify each TerrPt it leaves with an ElevDeparted message.
    **   - notify all interested parties of its movements with ElevArrived
    **     and ElevDeparted messages as it moves; the data of the message
    **     is the TerrPt it arrived at/departed from. An interested party
    **     is any object linked from this elevator with a Population link.
    **   - reply to At? messages with the TerrPt it is stopped at, or
    **     with 0 if it is in motion.
    **
    ** Details: uses a singular Route link from this elevator to keep track
    ** of which TerrPt it is at. When getting a Call message, this elevator
    ** needs to use this to figure out if it is actually going to move or not.
    **
    ** All this is necessary because a StdElevator itself doesn't provide this
    ** information; and when stopped at a TerrPt and re-called to it, the
    ** Stopping self-message may not be sent, and the MovingTerrain/Active
    ** property is not reliable (it sometimes remains on).
    */

    function GetAtPoint() {
        local link = Link.GetOne("Route", self);
        if (! link) return 0;
        return LinkDest(link);
    }

    function ClearAtPoint() {
        Link.DestroyMany("Route", self, 0);
    }

    function SetAtPoint(pt) {
        Link.DestroyMany("Route", self, 0);
        if (! pt) return;
        Link.Create("Route", self, pt);
    }

    function BroadcastToListeners(message, data) {
        // NOTE: calling SendMessage() will usually disrupt a link query,
        //       so we have to first find all the listeners first, and only
        //       then send them the message. We can't use Link.Broadcast...()
        //       because it doesn't support sending any extra data.
        local listeners = [];
        foreach (link in Link.GetAll("Population", self)) {
            listeners.append(LinkDest(link));
        }
        foreach (obj in listeners) {
            SendMessage(obj, message, data);
        }
    }

    function OnSim() {
        if (message().starting) {
            local link = Link.GetOne("TPathInit", self);
            if (! link) {
                if (DEBUG_ELEVATOR) print("WARNING: elevator "+self+" does not have a TPathInit link.");
                return;
            }
            local atPt = LinkDest(link);
            SetAtPoint(atPt);
            SendMessage(atPt, "ElevArrived", atPt);
            BroadcastToListeners("ElevArrived", atPt);
        }
    }

    function OnStopping() {
        local link = Link.GetOne("TPathNext", self);
        if (! link) {
            if (DEBUG_ELEVATOR) print("WARNING: elevator "+self+" path simply ends.");
            return;
        }
        local atPt = LinkDest(link);
        SetAtPoint(atPt);
        SendMessage(atPt, "ElevArrived", atPt);
        BroadcastToListeners("ElevArrived", atPt);
    }

    function OnCall() {
        local atPt = GetAtPoint();
        // Do nothing if the elevator is between points.
        if (! atPt) return;
        // Ignore if we are called to the point we are already at. The elevator
        // script itself won't see this as important and won't send a Stopping
        // message either, so we won't have a dangling message problem.
        if (atPt==message().from) return;
        ClearAtPoint();
        SendMessage(atPt, "ElevDeparted", atPt);
        BroadcastToListeners("ElevDeparted", atPt);
    }

    function OnAt_() {
        Reply(GetAtPoint());
    }
}

class ElevPaused extends SqRootScript {
    /* Intended for use on a metaprop. Prevents the elevator from responding
    ** to calls while this script is active. Once the script is removed, it
    ** will process the last call that it received.
    */
    function GetLastCalledPt() {
        foreach (link in Link.GetAll("ScriptParams", self)) {
            if (LinkTools.LinkGetData(link, "")=="ElevPausedLink") {
                return LinkDest(link)
            }
        }
        return 0;
    }

    function SetLastCalledPt(terr) {
        local links = [];
        foreach (link in Link.GetAll("ScriptParams", self)) {
            if (LinkTools.LinkGetData(link, "")=="ElevPausedLink") {
                links.append(link);
            }
        }
        foreach (link in links) {
            Link.Destroy(link);
        }
        if (terr) {
            local link = Link.Create("ScriptParams", self, terr);
            LinkTools.LinkSetData(link, "", "ElevPausedLink");
            return link;
        }
        return 0;
    }

    function OnBeginScript() {
        SetLastCalledPt(0);
    }

    function OnEndScript() {
        local terr = GetLastCalledPt();
        SetLastCalledPt(0);
        if (terr) {
            PostMessage(terr, "TurnOn");
        }
    }

    function OnCall() {
        SetLastCalledPt(message().from);
        BlockMessage();
        Reply(false);
    }
}
