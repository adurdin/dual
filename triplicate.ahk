WaitForDromed()
{
    Sleep 30
}

DuplicateBrushes(from_brush_id, to_brush_id, move_down, move_up, retime)
{
    iteration := 0
    iteration_stop := (to_brush_id - from_brush_id + 1)
    brush_id := from_brush_id
    time_offset := 0
    While (iteration < iteration_stop)
    {
        OutputDebug % "TRIP: " . iteration . "/" . iteration_stop
        OutputDebug % "TRIP brush_id: " . brush_id
        if (move_down)
        {
            SelectBrush(brush_id)
            DuplicateBrush()
            if (retime)
            {
                SetBrushTime(brush_id + time_offset)
                ++time_offset
            }
            Loop 4
            {
                MoveBrushDown()
            }
        }
        if (move_up)
        {
            SelectBrush(brush_id)
            DuplicateBrush()
            if (retime)
            {
                SetBrushTime(brush_id + time_offset)
                ++time_offset
            }
            Loop 4
            {
                MoveBrushUp()
            }
        }
        ; Brush IDs are at end until portalization,
        ; so we dont need to skip any brush_ids:
        ++brush_id
        ++iteration
        if (mod(iteration, 100)==0)
        {
            PlaySchema("bow_begin")
            Sleep 500
        }
    }
}

SetBrushTime(time)
{
    Send % ":brush_set_time " . time . "{Enter}"
    WaitForDromed()
}

DuplicateBrush()
{
    Send +{Ins}
    WaitForDromed()
}

MoveBrushUp()
{
    Send {NumpadSub}
    WaitForDromed()
}

MoveBrushDown()
{
    Send {NumpadAdd}
    WaitForDromed()
}

SetGrid(scale)
{
    ; scale: allowable values: 11 (0.125 unit nudge) to 21 (128 unit nudge)
    Send +/
    WaitForDromed()
    current_scale := 14
    While (current_scale > scale)
    {
        Send +,
        WaitForDromed()
        --current_scale
    }
    While (current_scale < scale)
    {
        Send +.
        WaitForDromed()
        ++current_scale
    }
}

ZoomToWorld()
{
    Send % ":fit_cameras 0{Enter}"
    WaitForDromed()
    Send % ":zoom_all 4{Enter}"
    WaitForDromed()
}

SaveMission(filename)
{
    Send % ":save_mission " . filename . "{Enter}"
    WaitForDromed()
}

SelectBrush(brush_id)
{
    Send  % ":brush_select " . brush_id . "{Enter}"
    WaitForDromed()
}

PlaySchema(schema)
{
    Send % ":play_schema " . schema . "{Enter}"
    WaitForDromed()
}

DoTriplicate()
{
    SetTitleMatchMode 1
    SendMode Input
    ; SendMode Event
    if WinExist("DromEd")
    {
        WinActivate
    }
    else
    {
        MsgBox % "Cannot find DromEd window."
        ExitApp
    }

    OutputDebug % "============ TRIP ============"
    ; LoadMission("miss20_mid.mis") ; load_file filename [then wait...?]
    SetGrid(21)
    ZoomToWorld()
    retime_brushes := true
    DuplicateBrushes(1, 454, true, true, retime_brushes)
    DuplicateBrushes(455, 3935, false, true, retime_brushes)
    SaveMission("triplicate.mis")
    PlaySchema("dinner_bell")
    Return
}

DoTriplicate()
Return
