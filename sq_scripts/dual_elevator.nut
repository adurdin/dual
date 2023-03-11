class ElevatorPatroller extends SqRootScript {
    function StartPatrolling() {
        print("++++ StartPatrolling");
        if (! Object.HasMetaProperty(self, "M-DoesPatrol")) {
            print("     Adding metaprop");
            Object.AddMetaProperty(self, "M-DoesPatrol");
        }
    }

    function StopPatrolling() {
        if (Object.HasMetaProperty(self, "M-DoesPatrol")) {
            Object.RemoveMetaProperty(self, "M-DoesPatrol");
        }
    }
/*
    function OnResumePatrolling() {
        print(Object_Description(self)+": "+message().message);

        local trol = 0;
        foreach (link in Link.GetAll("ScriptParams", self)) {
            local data = LinkTools.LinkGetData(link, "");
            if (data=="ResumePatrol") {
                trol = LinkDest(link);
            }
        }
        Link.DestroyMany("ScriptParams", self, 0);
        
        Object.Teleport(self, vector(), vector(), self); // HACK?

        if (trol) {
            if (! Link.AnyExist("AICurrentPatrol", self)) {
                print("Creating AICurrentPatrol to "+trol);
                Link.Create("AICurrentPatrol", self, trol);
            } else {
                print("HUH??? AICurrentPatrol already exists!");
            }
            StartPatrolling();
        }
    }
*/

    function OnPatrolPoint() {
        print(Object_Description(self)+": "+message().message + " trol " + Object_Description(message().patrolObj));

        local trol = message().patrolObj;
        if (trol) {
            local result = SendMessage(trol, "ReachedPatrolPt");
            print("ReachedPatrolPt result: "+result+" ("+(typeof result)+")");

            switch (result) {
            case "WaitForElevator":
                print("Waiting...");
                StopPatrolling();
                local link = Link.GetOne("Route", trol);
                Link_SetCurrentPatrol(self, LinkDest(link));

                // Wait here until the patrol point tells us otherwise.
                // TODO: conversation, cancel mechanism, alert state handling, blah blah
                Link.Create("Population", trol, self);
                // Call the elevator.
                link = Link.GetOne("~ControlDevice", trol);
                if (link) {
                    print("** Route link is to "+Object_Description(LinkDest(link)));
                    SendMessage(LinkDest(link), "TurnOn");
                } else {
                    print("?? Missing the Route link?");
                }
                break;
            case "IdleOnElevator":
                // TODO:
                break;
            }

/*
            local terrPtLink = Link.GetOne("Route", trol);
            local nextTrolLink = Link.GetOne("AIPatrol", trol);
            if (terrPtLink && nextTrolLink) {
                local terrPt = LinkDest(terrPtLink);
                local nextTrol = LinkDest(nextTrolLink);
                // Abort current patrol
                StopPatrolling();
                local current = Link.GetOne("AICurrentPatrol", self);
                if (current) {
                    print("Current patrol is: "+LinkDest(current));
                //     print("Destroying current patrol to: "+LinkDest(current));
                //     Link.Destroy(current);
                }

                // Current patrol _will_ be destroyed before next tick, so lets
                // use a different link to track it.
                print("Creating ScriptParams link to "+nextTrol);
                local link = Link.Create("ScriptParams", self, nextTrol);
                LinkTools.LinkSetData(link, "", "ResumePatrol");

                print("Creating ScriptParams link to "+terrPt);
                local link = Link.Create("ScriptParams", self, terrPt);
                LinkTools.LinkSetData(link, "", "NotifyMe");

                // // Prepare for resuming
                // Link.Create("AICurrentPatrol", self, nextTrol);
                // Tell the elevator to move
                print("Sending TurnOn to: "+terrPt);
                SendMessage(terrPt, "TurnOn");
            } else if (terrPtLink) {
                print(trol+" has Route link to TerrPt, but is missing AIPatrol link to where to resume patrol.");
            } else if (nextTrolLink) {
                print(trol+" has AIPatrol link to resume patrol, but is missing Route link to TerrPt.");
            }
*/
        }
    }

    function OnTurnOn() {
        // TODO: this is not the best message to use, its too generic
        local trol = message().from;
        Link.DestroyMany("~ControlDevice", self, 0);
        // TODO: HERE: for some reason the guy doesnt start patrolling again?
        print("current patrol is: "+Object_Description(Link_GetCurrentPatrol(self)));
        StartPatrolling();
        print("current patrol is: "+Object_Description(Link_GetCurrentPatrol(self)));
    }


    // TODO: obsolete?
    function OnElevatorStarting() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
        SendMessage(self, "StopPatrolling");
    }

    function OnElevatorStopping() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
        SendMessage(self, "StartPatrolling");
    }

    function OnStartPatrolling() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
        if (! Object.HasMetaProperty(self, "M-DoesPatrol")) {
            Object.AddMetaProperty(self, "M-DoesPatrol");
            print("Added M-DoesPatrol");
        } else {
            print("Already got M-DoesPatrol on " + self);
        }
    }

    function OnStopPatrolling() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
        if (Object.HasMetaProperty(self, "M-DoesPatrol")) {
            Object.RemoveMetaProperty(self, "M-DoesPatrol");
            print("Removed M-DoesPatrol");
        } else {
            print("No M-DoesPatrol on " + self);
        }
    }

}

class FancyElevator extends SqRootScript {
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
    ** When we reach a TerrPt, tell it we have arrived. When
    ** we leave it, tell it that we have left.
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

    function OnSim() {
        if (message().starting) {
            local link = Link.GetOne("TPathInit", self);
            if (! link) return;
            local atPt = LinkDest(link);
            SetAtPoint(atPt);
            if (atPt) {
                SendMessage(atPt, "Arriving");
            }
        }
    }

    function OnStopping() {
        local nextPt = LinkDest(Link.GetOne("TPathNext", self));
        SetAtPoint(nextPt);
        if (nextPt) {
            SendMessage(nextPt, "Arriving");
        }
    }

    function OnCall() {
        local fromPt = message().from;
        local atPt = GetAtPoint();
        if (fromPt==atPt) return;
        ClearAtPoint();
        if (atPt) {
            SendMessage(atPt, "Departing");
        }
    }
}

class FancyTerrPt extends SqRootScript {
    function OnMessage() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
    }

    function OnArriving() {
        Link.BroadcastOnAllLinks(self, "TurnOn", "ControlDevice");
    }

    function OnDeparting() {
        Link.BroadcastOnAllLinks(self, "TurnOff", "ControlDevice");
    }
}

class ElevatorEmbarkPt extends SqRootScript {
    function OnMessage() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
    }

    function OnReachedPatrolPt() {
        print(Object_Description(self)+": "+message().message + " from " + Object_Description(message().from));
        Reply("IdleOnElevator");
    }
}

class ElevatorWaitPt extends SqRootScript {
    function IsEnabled() {
        return Link.AnyExist("AIPatrol", self);
    }

    function SetEnabled(enabled) {
        if (enabled) {
            local link = Link.GetOne("Route", self);
            if (link) {
                Link.Create("AIPatrol", self, LinkDest(link));
                Link.Destroy(link);
                // TODO: notify?
            }
        } else {
            local link = Link.GetOne("AIPatrol", self);
            if (link) {
                Link.Create("Route", self, LinkDest(link));
                Link.Destroy(link);
                // TODO: notify?
            }
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

