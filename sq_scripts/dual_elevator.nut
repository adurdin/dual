class ElevatorPatroller extends SqRootScript {
    function DebugLogMessage() {
        print("**** "+message().message
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
            print("----------------------------- "+msg);
            SetOneShotTimer("DumpPatrolStatus", 1.0);
        }

        if (message().name=="ResetPatrol") {
            DebugLogMessage();
            local trolName = message().data;
            if (trolName==null) {
                print("NOTE: no trolName");
                return;
            }
            local trol = Object.Named(trolName);
            if (trol==0) {
                print("ERROR: cant find object named "+trolName);
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
            print("New patrol target: "+Object_Description(LinkDest(link)));
        }
    }

    function OnPatrolPoint() {
        DebugLogMessage();
        local trol = message().patrolObj;
        // TODO - how do we _properly_ determine if we should react to this point?
        //        i dont actually know!
        // if (Property.Possessed(trol, "AI_WtchPnt")) {
        //     print("@@@@ Created Watch");
        //     Link.Create("AIWatchObj", self, trol);
        //     // AI.ClearGoals(self);
        // }
        if (Property.Possessed(trol, "AI_Converation")) {
            if (! Link.AnyExist("AIConversationActor", trol)) {
                print("@@ Creating actor link.");
                local link = Link.Create("AIConversationActor", trol, self);
                LinkTools.LinkSetData(link, "Actor ID", 1);
            }
            local result = AI.StartConversation(trol);
            print("@@@@ Started conversation on "+Object_Description(trol)+" result: "+result);
        }
    }

    function OnPatrolTo() {
        DebugLogMessage();
        local trol;
        local trolName = message().data;
        if (trolName==null) {
            print("ERROR: no trolName");
            Reply(false);
            return;
        }
        trol = Object.Named(trolName);
        if (trol==0) {
            print("ERROR: cant find object named "+trolName);
            Reply(false);
            return;
        }
        // print("Patrolling to "+Object_Description(trol));
        // // Property.SetSimple(self, "AI_Patrol", false);
        // local link = Link.GetOne("AICurrentPatrol", self);
        // print("Old patrol target: "+Object_Description(LinkDest(link)));
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
        // print("New patrol target: "+Object_Description(LinkDest(link)));
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
            print("################################################");
            local link = Link.GetOne("AICurrentPatrol", self);
            print("Current patrol: "+Object_Description(LinkDest(link)));
            SetProperty("AI_Patrol", false);
            // AI.ClearGoals(self);
            Link.DestroyMany("AICurrentPatrol", self, 0);
            SetProperty("AI_Patrol", true);
            link = Link.GetOne("AICurrentPatrol", self);
            print("New patrol: "+Object_Description(LinkDest(link)));
        } else {
            print("Not on the elevator????");
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

    /** HERE: TODO: so, the problem is that pathfinding breaks down OFTEN. and
        when that happens, the AI gets its patrol property turned off, and
        moreover it seems the Watch links we are creating fail to trigger!
        turning the patrol property back on we _can_ do, but first we have to
        resolve the Watch problem.

        The self-destructing pathable objects were an attempt to ensure there
        would always be an available path cell in the embark places to prevent
        pathfinding fails, but it didnt entirely work. when they were the same
        height as the elevator, it seemed to work for the bottom point, but the
        top point then _couldnt_ disembark! it seemed the npc patrolled "up"
        the shaft into a cell from the pathable obj from where it then couldnt
        find the cell from the elevator! or something like that.

        possibly adding a Conversation property to the patrol point, and having
        the patroller trigger that when reaching it (instead of creating the
        AIWatchObj link) might work better? at least triggering the conversation
        should be reliable (i hope!).

        further work: if the patroller gives up while waiting for the elevator
        at the top or bottom, we should try to reset them to a different trolpt
        (probably via a parameter on the StopWaitingForElevator message).
        although i have struggled with that!

        several of these problems might perhaps be solved if we require the
        "wait" trolpt to have at least one trolpt between it and the "embark"
        pt, such that the ai will *not* think it has reached that intermediate
        UNTIL the pseudoscript ends...?  <<<< THIS should be the next line
                                              of experiment!
    */

    function OnWaitForElevatorArrival() {
        DebugLogMessage();
        local terrName = message().data;
        local embarkName = message().data2;
        local elevatorReady = (GetData("ElevatorAt")==terrName);
        if (elevatorReady) {
            print("#### Elevator is ready");
            // local embark = Object.Named(embarkName);
            // if (! embark) {
            //     print("ERROR: no embark point named "+embarkName);
            //     return;
            // }
            // if (Property.Possessed(embark, "AI_WtchPnt")) {
            //     Link.Create("AIWatchObj", self, embark);
            //     AI.ClearGoals(self);
            // } else {
            //     print("ERROR: embark point "+Object_Description(embark)+" has no Watch Link Defaults.");
            //     return;
            // }
            Reply(false);
        } else {
            print("#### Elevator is NOT READY");
            // We rely on the pseudoscript to keep on trying over time.
            Reply(true);
        }
    }

    function OnStopWaitingForElevator() {
        DebugLogMessage();
        print("########## stop waiting");
        local trolName = message().data;
        if (trolName==null) {
            print("NOTE: no trolName");
            Reply(false);
            return;
        }
        local trol = Object.Named(trolName);
        if (trol==0) {
            print("ERROR: cant find object named "+trolName);
            Reply(false);
            return;
        }
        print("Changing patrol to "+Object_Description(trol));
        // // Property.SetSimple(self, "AI_Patrol", false);
        local link = Link.GetOne("AICurrentPatrol", self);
        print("Old patrol target: "+Object_Description(LinkDest(link)));
        Link.DestroyMany("AICurrentPatrol", self, 0);
        SetProperty("AI_Patrol", false);
        SetOneShotTimer("ResetPatrol", 1.5, trolName);
    }
}

class ElevatorNotify extends SqRootScript {
    /* Use a singular Route link to keep track of which TerrPt we
    ** are at, when stopped. When we get a Call message, we can
    ** use this info to figure out if we are going to actually
    ** move or not.
    **
    ** (All this is necessary because the elevator itself
    ** doesn't provide this information; and when stopped at a
    ** point and re-called to it, the MovingTerrain/Active
    ** property is not reliable.)
    **
    ** When we reach a TerrPt, send it ElevArrived. When we leave
    ** it, send it ElevDeparted. Also, broadcast these messages
    ** with the TerrPt as data along outgoing Population links
    ** to all interested parties.
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
                print("WARNING: elevator "+self+" does not have a TPathInit link.");
                return;
            }
            local atPt = LinkDest(link);
            SetAtPoint(atPt);
            SendMessage(atPt, "ElevArrived");
            BroadcastToListeners("ElevArrived", atPt);
        }
    }

    function OnStopping() {
        local link = Link.GetOne("TPathNext", self);
        if (! link) {
            print("WARNING: elevator "+self+" path simply ends.");
            return;
        }
        local nextPt = LinkDest(link);
        SetAtPoint(nextPt);
        SendMessage(nextPt, "ElevArrived");
        BroadcastToListeners("ElevArrived", nextPt);
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
        SendMessage(atPt, "ElevDeparted");
        BroadcastToListeners("ElevDeparted", atPt);
    }
}

// TODO - i think i can discard this class (but keep it for now for debugging
//        as it can turn on the light.
//        but, make sure to remove it from the TerrPts when we delete the class.
class FancyTerrPt extends SqRootScript {
    function OnMessage() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
    }
}

// TODO - i think i can discard this class
//        but, make sure to remove it from the TerrPts when we delete the class.
class ElevatorEmbarkPt extends SqRootScript {
    function OnMessage() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
    }

    function OnReachedPatrolPt() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
        Reply("EmbarkOnElevator");
    }
}

// TODO - i think i can discard this class????
//        well. maybe the Enabled() /TurnOn()/TurnOff() bits of it? maybe?
//        but! for right now it is maybe involved??
class ElevatorWaitPt extends SqRootScript {
    function IsEnabled() {
        return (GetData("Enabled")==1);
    }

    function SetEnabled(enabled) {
        if (enabled) {
            SetData("Enabled", 1);
        } else {
            SetData("Enabled", 0);
        }
    }

    function OnMessage() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
    }

    function OnReachedPatrolPt() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
        if (! IsEnabled()) {
            //Link.Create("Population", self, from?)
            Reply("WaitForElevator");
        } else {
            Reply("ElevatorIsReady");
        }
    }

    function OnTurnOn() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
        SetEnabled(true);
        Link.BroadcastOnAllLinks(self, "TurnOn", "Population");
        // EnableEmbarkLink(true);
        // NotifyPatrollers();
    }

    function OnTurnOff() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
        Link.BroadcastOnAllLinks(self, "TurnOff", "Population");
        SetEnabled(false);
    }
}

