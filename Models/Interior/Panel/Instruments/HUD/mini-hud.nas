print("*** LOADING mini-hud.nas ... ***");
################################################################################
#
#                          m2005-5's HUD SETTINGS
#
################################################################################

# this function will display hud #1 (standard) or hud #4 (minihud).
var minihud = func()
{
    var hud_number     = getprop("/sim/hud/current-path");
    var is_internal    = getprop("/sim/current-view/internal");
    var heading_offset = getprop("/sim/current-view/heading-offset-deg");
    var pitch_offset   = getprop("/sim/current-view/pitch-offset-deg");
    
    var x = math.sin(heading_offset * math.pi / 180);
    var y = math.sin(pitch_offset * math.pi / 180);
    var distance_from_center = (x * x) + (y * y);
    
    # we check if internal or not :
    if(is_internal == 1)
    {
        if(distance_from_center > 0.6)
        {
            if(hud_number != 4)
            {
                # head turned, mini hud is displayed
                setprop("/sim/hud/current-path",        4);
                setprop("/sim/hud/clipping/left",   -2000);
                setprop("/sim/hud/clipping/right",   2000);
                setprop("/sim/hud/clipping/top",     2000);
                setprop("/sim/hud/clipping/bottom", -2000);
            }
        }
        else
        {
            # if too much G, the bottom of the hud is hidden
            var pilot_gdamped = getprop("/accelerations/pilot-g");
            var dynamic_clipping_bottom = -(95 - (pilot_gdamped * 7));
            
            if(hud_number != 1)
            {
                # head centered, normal hud is displayed
                setprop("/sim/hud/current-path",                          1);
                setprop("/sim/hud/clipping/left",                       -65);
                setprop("/sim/hud/clipping/right",                       65);
                setprop("/sim/hud/clipping/top",                         60);
            }
            setprop("/sim/hud/clipping/bottom", dynamic_clipping_bottom);
        }
    }
    else
    {
        if(hud_number != 4)
        {
            setprop("/sim/hud/current-path",        4);
            setprop("/sim/hud/clipping/left",   -2000);
            setprop("/sim/hud/clipping/right",   2000);
            setprop("/sim/hud/clipping/top",     2000);
            setprop("/sim/hud/clipping/bottom", -2000);
        }
    }
    settimer(minihud, 0.5);
}
