print("*** LOADING MiscRwr.nas ... ***");
################################################################################
#
#                        m2005-5's RADAR SETTINGS SOON DEPRECIATED
#
################################################################################

var StandByTgtMarker  = 0;
var Target_Index      = 0;
var tableuBound       = 0;

var switch_distance = func(){
    radar.switch_distance();
}

var activate_ECM = func(){
    if(getprop("instrumentation/ecm/on-off") != "true" )
    {
        setprop("instrumentation/ecm/on-off", "true");
    }
    else
    {
        setprop("instrumentation/ecm/on-off", "false");
    }
}

var activate_Telemeter= func(){
    if(getprop("/ai/closest/range") == -2)
    {
        setprop("/ai/closest/range", -1);
    }
    else
    {
        setprop("/ai/closest/range", -2);
    }
    #choosen_Target_List();
    radar.radar_mode_toggle();
    StandByTgtMarker = 0;
}

var next_Target_Index = func(){
    radar.next_Target_Index();
}

var previous_Target_Index = func(){
    radar.previous_Target_Index();
}

var closest_target = func(){
    if(tableuBound > 0)
    {
        if(Target_Index < 0)
        {
            Target_Index = tableuBound - 1;
        }
        if(Target_Index > tableuBound - 1)
        {
            Target_Index = 0;
        }
        var MyTarget = MyTargetList[Target_Index];
        return MyTarget;
    }
}


