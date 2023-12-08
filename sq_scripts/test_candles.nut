class DebugOnscreen extends SqRootScript {
    function OnTweqComplete() {
        if (message().Type==eTweqType.kTweqTypeFlicker) {
            // We were drawn.
            DarkUI.TextMessage("OnScreen", 0x0080FF, 100);
        }
    }
}

// We're not drawing a HUD, but we're using the HUD api to get screen positions
// and to determine if the object in question is onscreen or not!
class DebugRenderInfoOverlay extends IDarkOverlayHandler
{
    m_target = 0;
    m_target_is_focused = 0;

    // keep these intrefs around so we dont create garbage every frame.
    rx1 = int_ref();
    ry1 = int_ref();
    rx2 = int_ref();
    ry2 = int_ref();

    // handle to transparent hud overlay items
    xhair_handle = 0;
    corner_handles = [];

    function constructor() {
        local bm = DarkOverlay.GetBitmap("debugxhair", "hud\\");
        xhair_handle = DarkOverlay.CreateTOverlayItemFromBitmap(0, 0, 255, bm, true);
        for (local i=0; i<4; i++) {
            bm = DarkOverlay.GetBitmap("debugframe"+i, "hud\\");
            corner_handles.append( DarkOverlay.CreateTOverlayItemFromBitmap(0, 0, 255, bm, true) );
        }

        base.constructor();
    }
   

    function Init(target) {
        m_target = target;
        m_target_is_focused = false;
    }

    // IDarkOverlayHandler interface

    function DrawHUD() {
        if (m_target==0) return;

        Engine.GetCanvasSize(rx1, ry1);
        local w = rx1.tofloat();
        local h = ry1.tofloat();
        local visible = DarkOverlay.GetObjectScreenBounds(m_target, rx1, ry1, rx2, ry2);
        // local playerPos = Object.Position(Object.Named("Player"));
        // local targetPos = Object.Position(m_target);
        // local distance = (targetPos-playerPos).Length();
        // const MAX_RANGE = 16.0;
        // const MIN_RANGE = 2.0;
        // local proximity = (MIN_RANGE+MAX_RANGE-distance)/MAX_RANGE;
        // if (proximity<0.0) proximity = 0.0;
        // if (proximity>0.999) proximity = 0.999;
        local was_focused = m_target_is_focused;
        local is_focused = false;
        if (visible) { // || proximity>0.0) {
            local x1 = rx1.tointeger();
            local y1 = ry1.tointeger();
            local x2 = rx2.tointeger();
            local y2 = ry2.tointeger();
            // Hardcode a rect that covers the bulk of the periapt in its animation.
            // TODO: This is not a good approach to "was this rendered in the periapt"?
            //       firstly because its not resolution-independent yet. secondly
            //       because its not aspect-ratio independent (where does the periapt
            //       show  up in 4:3? in 21:9? who knows?). thirdly because it is just
            //       a rect that doesnt fully align ever with the periapt. but for now
            //       it is enough to test the rest of the thing with.
            local in_rect = (x1>=1143 && x2<1655 && y1>=421 && y2<824);
            if (in_rect) {
                //DarkUI.TextMessage("In Rect", 0xFF00FF, 100);
                is_focused = true;
            }
            //print("visible at "+x1+","+y1+" - "+x2+","+y2+(in_rect?" IN RECT":""));
            DarkOverlay.UpdateTOverlayPosition(xhair_handle, x1+(x2-x1)/2-8, y1+(y2-y1)/2-8);
            DarkOverlay.UpdateTOverlayPosition(corner_handles[0], x1, y1);
            DarkOverlay.UpdateTOverlayPosition(corner_handles[1], x2-8, y1);
            DarkOverlay.UpdateTOverlayPosition(corner_handles[2], x2-8, y2-8);
            DarkOverlay.UpdateTOverlayPosition(corner_handles[3], x1, y2-8);
            // DarkOverlay.DrawTOverlayItem(xhair_handle);
            // for (local i=0; i<4; i++) {
            //     DarkOverlay.DrawTOverlayItem(corner_handles[i]);
            // }
            DarkOverlay.SetTextColor(255, 0, 255);
            DarkOverlay.DrawLine(x1, y1, x2, y1);
            DarkOverlay.DrawLine(x2, y1, x2, y2);
            DarkOverlay.DrawLine(x1, y1, x1, y2);
            DarkOverlay.DrawLine(x1, y2, x2, y2);
        } else {
            //print("not visible.");
        }

        if (is_focused!=was_focused) {
            m_target_is_focused = is_focused;
            // TODO: i dont like this. i would much rather send a message to
            //       the object. but from inside the hud, we can't, because
            //       the overlay is only a squirrel instance. We would have to
            //       have another concrete object that on flicker (or every
            //       frame timer) looks at g_overlay.m_target_is_focused and
            //       dispatches the appropriate messages... gross.
            if (is_focused) {
                Property.Set(m_target, "StTweqBlink", "AnimS", TWEQ_AS_ONOFF);
            } else {
                Property.Set(m_target, "StTweqBlink", "AnimS", 0);
            }
        }
    }

    //function DrawTOverlay() {}
    //function OnUIEnterMode() {}
}

g_overlay <- DebugRenderInfoOverlay();

class DebugRenderInfo extends SqRootScript
{
    function destructor() {
        // to be on the safe side make really sure the handler is removed when this script is destroyed
        // (calling RemoveHandler if it's already been removed is no problem)
        DarkOverlay.RemoveHandler(g_overlay);
    }

    function OnBeginScript() {
        DarkOverlay.AddHandler(g_overlay);
        g_overlay.Init(self);
    }

    function OnEndScript() {
        DarkOverlay.RemoveHandler(g_overlay);
    }
}
