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

/* Move the door seal out, then let it fall */
class DoorSeal extends SqRootScript
{
    function OnFrobWorldEnd() {
        Object.RemoveMetaProperty(self, "LockedDoorSeal");
        SetProperty("PhysControl", "Controls Active", 0);
        local pos = Object.Position(self);
        local vel_rel = vector(0,-10.0,10.0);
        local vel_abs = Object.ObjectToWorld(self, vel_rel) - pos;
        local rot_rel = vector(2.0,0,0);
        local rot_abs = Object.ObjectToWorld(self, rot_rel) - pos;
        Physics.SetVelocity(self, vel_abs);
        SetProperty("PhysState", "Rot Velocity", rot_abs);
    }

}
