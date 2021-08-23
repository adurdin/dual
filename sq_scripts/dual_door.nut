/* Put this on a door to make its joint tweqs run as the door is opening
   and closing.
   (The stock SubDoorJoints script runs tweqs on opening and *closed*.
   also it runs the joints in reverse when opening, which is weird!)
*/
class SyncDoorJoints extends SqRootScript
{
    function TweqJoints(flags) {
        for(local joint=1; joint<=6; ++joint) {
            local animS = "Joint" + joint + "AnimS";
            Property.Set(self, "StTweqJoints", animS, flags);
        }
        Property.Set(self, "StTweqJoints", "AnimS", flags);
    }

    function OnDoorOpening() {
        TweqJoints(TWEQ_AS_ONOFF);
    }

    function OnDoorClosing() {
        TweqJoints(TWEQ_AS_ONOFF|TWEQ_AS_REVERSE);
    }
}
