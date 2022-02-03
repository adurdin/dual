class TrolBetter extends SqRootScript
{
    //TrolPause=5000;TrolChance=50
    function OnPatrolPoint() {
        local pt = message().patrolObj;
        local nextPt = Link_GetCurrentPatrol(self);
        local chance = SendMessage(pt, "TrolChance?");
        local r = (100.0*Data.RandFlt0to1());
        print("r "+r+" >= chance "+chance+"? "+(r<=chance))
        if (chance!=null && r>=chance) {
        // if (chance!=null && (100.0*Data.RandFlt0to1())>=chance) {
            local pause = SendMessage(pt, "TrolPause?");
            if (pause!=null && pause >= 100) {
                print(Object_Description(self)+" pausing for "+pause+"s");
                Object.AddMetaProperty(self, "M-DontGoHome");
                Object.RemoveMetaProperty(self, "M-DoesPatrol");
                SetOneShotTimer("ResumeTrol", (pause/1000.0), nextPt);
            }
        }
    }

    function OnTimer() {
        if (message().name=="ResumeTrol") {
            local pt = message().data;
            if (pt!=null && pt!=0) {
                print(Object_Description(self)+" resuming patrol at "+pt);
                Link_SetCurrentPatrol(self, pt);
                Object.AddMetaProperty(self, "M-DoesPatrol");
                Object.RemoveMetaProperty(self, "M-DontGoHome");
            }
        }
    }
}

class TrolBetterPt extends SqRootScript
{
    function OnTrolPause_() {
        local params = userparams();
        if ("TrolPause" in params) {
            Reply(params.TrolPause.tointeger());
        }
    }

    function OnTrolChance_() {
        local params = userparams();
        if ("TrolChance" in params) {
            Reply(params.TrolChance.tointeger());
        }
    }
}
