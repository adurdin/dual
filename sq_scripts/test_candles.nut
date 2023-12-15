// We're not drawing a HUD, but we're using the HUD api to get screen positions
// and to determine if the object in question is onscreen or not!

enum eCandleState {
    kFocused = 0x01,    // candle was in view on last update.
    kChanged = 0x02,    // candle focused state changed on last update.
    kInvalid = 0x10,    // either disabled, or the object id is no longer valid.
}

// Targets: a dict of (objid -> eCandleState).
g_candles_targets <- {};

class CandlesOverlay extends IDarkOverlayHandler
{
    debug_draw_rects = false;

    // The CandlesController.
    m_controller = 0;

    // keep these intrefs around so we dont allocate them every frame.
    rx1 = int_ref();
    ry1 = int_ref();
    rx2 = int_ref();
    ry2 = int_ref();

    function Init(controller) {
        m_controller = controller;
    }

    function DrawHUD() {
        if (! m_controller) return;

        // TODO: will need this later to make the 'in view' decision resolution-independent.
        // Engine.GetCanvasSize(rx1, ry1);
        // local screenWidth = rx1.tofloat();
        // local screenHeight = ry1.tofloat();

        // Hardcode a rect that covers the bulk of the periapt in its animation.
        // TODO: This is not a good approach to "was this rendered in the periapt"?
        //       firstly because its not resolution-independent yet. secondly
        //       because its not aspect-ratio independent (where does the periapt
        //       show  up in 4:3? in 21:9? who knows?). thirdly because it is just
        //       a rect that doesnt fully align ever with the periapt. but for now
        //       it is enough to test the rest of the thing with.
        const rect_x1 = 1143;
        const rect_x2 = 1655;
        const rect_y1 = 421;
        const rect_y2 = 824;
        if (debug_draw_rects) {
            DarkOverlay.SetTextColor(64, 0, 64);
            DarkOverlay.DrawLine(rect_x1, rect_y1, rect_x2, rect_y1);
            DarkOverlay.DrawLine(rect_x2, rect_y1, rect_x2, rect_y2);
            DarkOverlay.DrawLine(rect_x1, rect_y1, rect_x1, rect_y2);
            DarkOverlay.DrawLine(rect_x1, rect_y2, rect_x2, rect_y2);

        }

        local any_changed = false;
        foreach (target, state in g_candles_targets) {
            if (state & eCandleState.kInvalid) {
                continue;
            }
            if (! Object.Exists(target)) {
                g_candles_targets[target] = eCandleState.kInvalid;
                continue;
            }
            local visible = DarkOverlay.GetObjectScreenBounds(target, rx1, ry1, rx2, ry2);
            local was_focused = (state & eCandleState.kFocused)!=0;
            local is_focused = false;
            if (visible) {
                local x1 = rx1.tointeger();
                local y1 = ry1.tointeger();
                local x2 = rx2.tointeger();
                local y2 = ry2.tointeger();
                local in_rect = (x1>=rect_x1 && x2<rect_x2 && y1>=rect_y1 && y2<rect_y2);
                if (in_rect) {
                    is_focused = true;
                }
                if (debug_draw_rects) {
                    DarkOverlay.SetTextColor(255, 0, 255);
                    DarkOverlay.DrawLine(x1, y1, x2, y1);
                    DarkOverlay.DrawLine(x2, y1, x2, y2);
                    DarkOverlay.DrawLine(x1, y1, x1, y2);
                    DarkOverlay.DrawLine(x1, y2, x2, y2);
                }
            }

            if (was_focused==is_focused) {
                // No change happened. Skip.
                continue;
            }
            if ((state & eCandleState.kChanged) && was_focused) {
                // If it was focused in at least one frame between controller updates,
                // we leave it that way so the focusing doesn't get skipped.
                continue;
            }

            any_changed = true;
            state = eCandleState.kChanged;
            if (is_focused) state = state | eCandleState.kFocused;
            g_candles_targets[target] = state;
        }

        if (any_changed) {
            // Queue an update.
            Property.Set(m_controller, "StTweqBlink", "AnimS", TWEQ_AS_ONOFF);
        }
    }

    // TODO: handle resolution changes and such.
    // handler called by the engine when dark initializes UI components,
    // this is also called when resuming game after in-game menu and other
    // UI screens and is a good place to update positioning of HUD elements
    // in case display resolution changed.
    //function OnUIEnterMode() {}
}

g_candles_overlay <- CandlesOverlay();

EnableCandle <- function(target, enable) {
    if (target in g_candles_targets) {
        local state = g_candles_targets[target];
        if (enable) {
            state = state & ~eCandleState.kInvalid;
        } else {
            state = state | eCandleState.kInvalid;
        }
        g_candles_targets[target] = state;
    } else {
        if (enable) {
            g_candles_targets[target] <- 0;
        }
    }
}

class CandlesController extends SqRootScript
{
    function UpdateCandles() {
        foreach (target, state in g_candles_targets) {
            if (state & eCandleState.kInvalid) continue;
            if (state & eCandleState.kChanged) {
                if (state & eCandleState.kFocused) {
                    SendMessage(target, "BeginVisible");
                } else {
                    SendMessage(target, "EndVisible");
                }
                state = state & ~eCandleState.kChanged;
                g_candles_targets[target] = state;
            }
        }
        Property.Set(self, "StTweqBlink", "AnimS", 0);
    }

    function destructor() {
        // to be on the safe side make really sure the handler is removed
        // when this script is destroyed (calling RemoveHandler if it's already
        // been removed is no problem)
        DarkOverlay.RemoveHandler(g_candles_overlay);
    }

    function OnBeginScript() {
        g_candles_overlay.Init(self);
        DarkOverlay.AddHandler(g_candles_overlay);
    }

    function OnEndScript() {
        DarkOverlay.RemoveHandler(g_candles_overlay);
    }

    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker) {
            UpdateCandles();
        }
    }
}

class ActiveCandle extends SqRootScript {
    kTimerIncrement = 0.033;

    function OnBeginScript() {
        if (! IsDataSet("Visible")) SetData("Visible", false);
        if (! IsDataSet("Appear")) SetData("Appear", 0.0);
        if (! IsDataSet("AppearDone")) SetData("AppearDone", false);

        if (! GetData("AppearDone")) {
            EnableCandle(self, true);
        }
    }

    function OnEndScript() {
        EnableCandle(self, false);
    }

    function GetCounterpart() {
        local link = Link.GetOne("Owns", self);
        if (link) return LinkDest(link);
        return 0;
    }

    function OnSim() {
        if (message().starting) {
            local counterpart = GetCounterpart();
            if (counterpart) {
                SendMessage(counterpart, "TurnOff");
                Property.SetSimple(counterpart, "HasRefs", false);
                Property.SetSimple(counterpart, "RenderAlpha", 0.0);
                Property.Set(counterpart, "PhysType", "Type", 3); // None
            } else {
                print("ERROR: ActiveCandle "+self+" has no counterpart.");
            }
        }
    }

    function OnBeginVisible() {
        print(self+" "+message().message);
        SetData("Visible", true);
        DarkUI.TextMessage("Visible", 0x0080FF, 10000);
        // NOTE: we always kick off the timer here, because we flag ourselves
        //       as invalid once we are done, and wont get BeginVisible messages
        //       anymore.
        SetOneShotTimer(self, "CandleAppear", kTimerIncrement);
    }

    function OnEndVisible() {
        print(self+" "+message().message);
        SetData("Visible", false);
        DarkUI.TextMessage("", 0, 1);
    }

    function OnTimer() {
        if (message().name=="CandleAppear") {
            local counterpart = GetCounterpart();
            if (! counterpart) return;
            local appear = GetData("Appear");
            local visible = GetData("Visible");
            // TODO: make framerate independent.
            // TODO: tweak timing until it feels right.
            local step = (visible? 1.0 : -1.0)*0.005;
            // TODO: audio feedback as appear starts rising/falling??
            appear += step;
            if (appear<0.0) appear = 0.0;
            if (appear>1.0) appear = 1.0;
            SetData("Appear", appear);
            DarkUI.TextMessage("appear:"+(appear*1000).tointeger(), 0xFF00FF, 100);
            Property.SetSimple(counterpart, "HasRefs", (appear>0.0));
            // TODO: better alpha curve (and maybe ExtraLight, if AnimLight doesnt interfere?)
            Property.SetSimple(counterpart, "RenderAlpha", appear);
            if (appear>=1.0) {
                // We are solid now, permanently.
                // TODO: audio feedback.
                SetData("AppearDone", true);
                Property.Set(counterpart, "PhysType", "Type", 0); // OBB
                EnableCandle(self, false);
                SendMessage(counterpart, "TurnOn");
                return;
            }
            if (appear<=0.0) {
                // We are faded out. No need for another timer tick.
                // TODO: silence rising/falling audio feedback (if any).
                return;
            }
            SetOneShotTimer(self, "CandleAppear", kTimerIncrement);
        }
    }
}
