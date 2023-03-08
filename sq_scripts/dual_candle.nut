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

    function OnWaterStimStimulus() {
        ChangeMode(false);
    }

    function OnKOGasStimulus() {
        ChangeMode(false);
    }

    function OnFireStimStimulus() {
        ChangeMode(true);
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

class FrobTransmute extends SqRootScript {
    // If we (or our archetypes) have a Transmute link to another
    // object or archetype, move or clone it into our position;
    // then slay ourself.
    //
    // Prime use case is lootable candles with AnimLights; because
    // you cannot safely Destroy an AnimLight, we transmute a frobbable
    // but not lootable candle into a lootable one.
    //
    function OnFrobWorldEnd() {
        local links = Link.GetAllInheritedSingle("Transmute", self);
        if (links.AnyLinksLeft()) {
            local link = links.Link();
            local obj = LinkDest(link);
            if (obj<0) {
                obj = Object.Create(obj);
            }
            Object.Teleport(obj, vector(), vector(), self);
            SendMessage(self, "Transmuted", obj);
            Damage.Slay(self, 0);
        }
    }
}

class FrobTransmuteAndLoot extends FrobTransmute {
    function OnTransmuted() {
        local obj = message().data;
        Container.Add(obj, "Player");
    }
}
