class Sitter extends SqRootScript
{
    function FindSitPoint() {
        local pt = 0;
        local ptDist = 999999;
        local myPos = Object.Position(self);
        local arch = Object.Named("SitPoint");
        // Look for links to SitPoints
        local links = Link.GetAll("AIWatchObj", self);
        foreach (link in links) {
            local o = LinkDest(link);
            if (Object.InheritsFrom(o, arch)) {
                local dist = (myPos-Object.Position(o)).Length();
                if (dist<ptDist) {
                    pt = o;
                    ptDist = dist;
                }
            }
        }
        return pt;
    }

    function SnapToAnimStartPosition(pt) {
        Object.Teleport(self, vector(1.0,0,-0.25), vector(), pt);
    }

    function SnapToAnimEndPosition(pt) {
        Object.Teleport(self, vector(), vector(), pt);
    }

    function OnSitActionStart() {
        BlockMessage();
        if (Link.AnyExist("AIAttack", self)) {
            Reply(false);
            return;
        }
        if (Link.AnyExist("AIInvest", self)) {
            Reply(false);
            return;
        }
        local pt = FindSitPoint();
        if (pt==0) {
            Reply(false);
            return;
        }
        SnapToAnimStartPosition(pt);
        Reply(true);
    }

    function OnSitActionDone() {
        BlockMessage();
        SetData("SitHappening", false);
        local pt = FindSitPoint();
        local meta = Object.Named("M-SittingDown");
        if (pt==0) {
            Reply(false);
            return;
        }
        SnapToAnimEndPosition(pt);
        if (! Object.HasMetaProperty(self, meta)) {
            Object.AddMetaProperty(self, meta);
        }
        Reply(true);
    }

    function OnSitActionAbort() {
        BlockMessage();
        SetData("SitHappening", false);
    }
}

class AlreadySitting extends SqRootScript
{
    function OnSit() {
        BlockMessage();
        Reply(false);
    }

    function OnSitActionStart() {
        BlockMessage();
        Reply(false);
    }

    function OnSitActionDone() {
        BlockMessage();
        Reply(false);
    }

    function OnSitActionAbort() {
        BlockMessage();
    }

    function OnAlertness() {
        if (message().level>message().oldLevel && message().level>=2) {
            Object.RemoveMetaProperty(self, "M-SittingDown");
        }
    }

    function OnHighAlert() {
        if (message().level>message().oldLevel && message().level>=2) {
            Object.RemoveMetaProperty(self, "M-SittingDown");
        }
    }

    function OnAIModeChange() {
        if (message().mode==eAIMode.kAIM_Combat || message().mode==eAIMode.kAIM_Dead) {
            Object.RemoveMetaProperty(self, "M-SittingDown");
        }
    }
}
