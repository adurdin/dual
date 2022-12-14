class AnimLightExtra extends SqRootScript {
    /* Don't use this script directly! Instead, subclass it and
    ** override ChangeMode() to add whatever behaviour your light
    ** needs when it is turned on/off.
    **
    ** NOTE: InitModes(), IsLightOn(), and OnTurnOn()/OnTurnOff()
    ** are copied from the stock AnimLight, so that we are compatible
    ** with it (i.e. consider the same AnimLight modes to be
    ** 'on' or 'off'). New behaviour specific to this script is
    ** called from ChangeMode().
    */
    function InitModes() {
        local mode, onmode, offmode;

        if(Property.Possessed(self,"AnimLight"))
            mode=Property.Get(self,"AnimLight","Mode");
        else
            return; // Bad, but nothing we can do.

        if(mode==ANIM_LIGHT_MODE_MINIMUM)
            offmode=mode;
        else if(mode==ANIM_LIGHT_MODE_SMOOTH_BRIGHTEN ||
                mode==ANIM_LIGHT_MODE_SMOOTH_DIM)
            offmode=ANIM_LIGHT_MODE_SMOOTH_DIM;
        else
            offmode=ANIM_LIGHT_MODE_EXTINGUISH;

        if(mode!=offmode)
            onmode=mode;
        else {
            if(offmode==ANIM_LIGHT_MODE_SMOOTH_DIM)
                onmode=ANIM_LIGHT_MODE_SMOOTH_BRIGHTEN;
            else
                onmode=ANIM_LIGHT_MODE_MAXIMUM;
        }

        SetData("OnLiteMode", onmode);
        SetData("OffLiteMode", offmode);
    }
         
    function IsLightOn() {
        local mode;

        if(Property.Possessed(self,"AnimLight"))
            mode=Property.Get(self,"AnimLight","Mode");
        else
            return false;

        if(!IsDataSet("OnLiteMode"))
            InitModes();

        return mode==GetData("OnLiteMode").tointeger();
    }

    function OnTurnOn() {
        if(! Property.Possessed(self,"StTweqBlink"))
            ChangeMode(true);
    }

    function OnTurnOff() {
        ChangeMode(false);
    }

    function OnToggle() {
        if (IsLightOn()) {
            ChangeMode(false);
        } else {
            ChangeMode(true);
        }
    }

    function OnBeginScript() {
        ChangeMode(IsLightOn());
    }

    function OnTweqComplete() {
        if(message.Type==eTweqType.kTweqTypeFlicker) {
            ChangeMode(true);
        }
    }
    
    function OnSlain() {
        ChangeMode(false);
    }

    function ChangeMode(on) {
        // Override this method in inherited classes.
    }
}

class CandleGlow extends AnimLightExtra {
    function ChangeMode(on) {
        base.ChangeMode(on);
        local glow = on?0.3:0.0;

        Property.Set(self, "ExtraLight", "Amount (-1..1)", glow);
        Property.Set(self, "ExtraLight", "Additive?", true);
    }
}
