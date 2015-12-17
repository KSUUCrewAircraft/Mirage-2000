print("*** LOADING m2000-5.nas ... ***");
################################################################################
#
#                       m2005-5's SYSTEMS SETTINGS
#
################################################################################
#
# Typhonn systems
# crazy dj nasal from many sources...
# and also, almursi work
# and 5H1N0B1

var deltaT                = 1.0;
var SAS_Loop_running      = 0;
var Elapsed_time_Seconds  = 0;
var Elapsed_time_previous = 0;
var LastTime              = 0;
# Elapsed for time > 0.25 sec
var Elapsed               = 0;

# Need some simplification in the way to manage the interval
var engine1 = engines.Jet.new(0, 0, 0.01, 20, 3, 5, 30, 15);
var myRadar3 = radar.Radar.new();

var InitListener = setlistener("/sim/signals/fdm-initialized", func
{
    settimer(main_Init_Loop, 5.0);
    removelistener(InitListener);
});

# Main init loop
# Perhaps in the future, make an object for each subsystems, in the same way
# of "engine"
var main_Init_Loop = func()
{
    # Loop Updated inside
    print("Electrical ... Check");
    settimer(electrics.Electrical_init, 1.0);
    
    # Loop Updated inside
    print("Hydraulical ... Check");
    settimer(hydraulics.Hydraulical_init, 1.0);
    
    # Loop Updated inside
    print("Fuel ... Check");
    settimer(fuel.Fuel_init, 1.0);
    
    # Loop Updated below
    print("Stability Augmentation System ... Check");
    settimer(mirage2000.init_SAS, 2.0);
    
    print("Engine ... Check");
    engine1.init();
    
    print("Intrumentation ... Check");
    settimer(instrumentation.initIns, 2.0);
    
    print("Radar ... Check");
    myRadar3.init();
    
    print("Flight Director ... Check");
    settimer(mirage2000.init_set, 4.0);
    
    print("MFD ...Check");
    settimer(mirage2000.update_main, 4.0);
    
    print("Transponder ... Check");
    settimer(init_Transpondeur, 4.0);
    
    print("system loop ... Check");
    settimer(updatefunction, 8.0);
    
    print("minihud ... Check");
    settimer(hud.minihud, 10);
}

var UpdateMain = func
{
    settimer(mirage2000.updatefunction, 0);
}

var updatefunction = func()
{
    Elapsed_time_Seconds = int(getprop("/sim/time/elapsed-sec"));
    AbsoluteTime = getprop("/sim/time/elapsed-sec");
    
    mirage2000.Update_SAS();
    mirage2000.update_main();
    MfdTime = getprop ("sim/time/elapsed-sec");
    if(AbsoluteTime - Elapsed > 0.5)
    {
        m2000_load.Encode_Load();
        Elapsed = Elapsed_time_Seconds;
    }
    
    # Flight Director (autopilot)
    if(getprop("/autopilot/locks/AP-status") == "AP1")
    {
        mirage2000.update_fd();
    }
    else
    {
        # this is a way to reduce autopilot refreshing time when not activated  <-? what
        if(Elapsed_time_Seconds != Elapsed_time_previous)
        {
            mirage2000.update_fd();
        }
    }
    if(Elapsed_time_Seconds != Elapsed_time_previous)
    {
        mirage2000.fuel_managment();
    }
    Elapsed_time_previous = Elapsed_time_Seconds;
    LastTime = AbsoluteTime;
    mirage2000.UpdateMain();
}

var init_Transpondeur = func()
{
    # Init Transponder
    var poweroften = [1, 10, 100, 1000];
    var idcode = getprop('/instrumentation/transponder/id-code');
    
    if(idcode != nil)
    {
        for(var i = 0 ; i < 4 ; i += 1)
        {
            setprop("/instrumentation/transponder/inputs/digit[" ~ i ~ "]", int(math.mod(idcode / poweroften[i], 10)));
        }
    }
}

controls.deployChute = func(v)
{
    # Deploy
    if(v > 0)
    {
        setprop("sim/model/lightning/controls/flight/chute_deployed", 1);
        setprop("sim/model/lightning/controls/flight/chute_open", 1);
        chuteAngle();
    }
    # Jettison
    if(v < 0)
    {
        var voltage = getprop("systems/electrical/outputs/chute_jett");
        if(voltage > 20)
        {
            setprop("sim/model/lightning/controls/flight/chute_jettisoned", 1);
            setprop("sim/model/lightning/controls/flight/chute_open", 0);
        }
    }
}

var chuteAngle = func
{
    var chute_open = getprop('sim/model/lightning/controls/flight/chute_open');
    
    if(chute_open != '1')
    {
        return();
    }
    var speed = getprop('/velocities/airspeed-kt');
    var aircraftpitch = getprop('/orientation/pitch-deg[0]');
    var aircraftyaw = getprop('/orientation/side-slip-deg');
    var chuteyaw = getprop("/sim/model/lightning/orientation/chute_yaw");
    var aircraftroll = getprop('/orientation/roll-deg');
    
    if(speed > 210)
    {
        setprop("sim/model/lightning/controls/flight/chute_jettisoned", 1); # Model Shear Pin
        return();
    }
    
    # Chute Pitch
    var chutepitch = aircraftpitch * -1;
    setprop("/sim/model/lightning/orientation/chute_pitch", chutepitch);
    
    # Damped yaw from Vivian's A4 work
    var n = 0.01;
    if(aircraftyaw == nil)
    {
        aircraftyaw = 0;
    }
    if(chuteyaw == nil)
    {
        chuteyaw = 0;
    }
    var chuteyaw = (aircraftyaw * n) + (chuteyaw * (1 - n));
    setprop("/sim/model/lightning/orientation/chute_yaw", chuteyaw);
    
    # Chute Roll - no twisting for now
    var chuteroll = aircraftroll;
    setprop("/sim/model/lightning/orientation/chute_roll", chuteroll * rand() * -1);
    
    return registerTimerControlsNil(chuteAngle);  # Keep watching
}

var chuteRepack = func
{
    setprop('sim/model/lightning/controls/flight/chute_open',       0);
    setprop('sim/model/lightning/controls/flight/chute_deployed',   0);
    setprop('sim/model/lightning/controls/flight/chute_jettisoned', 0);
}

var fuel_managment = func()
{
    var Externaltank = getprop("/consumables/fuel/tank[2]/empty");
    Externaltank *= getprop("/consumables/fuel/tank[3]/empty");
    Externaltank *= getprop("/consumables/fuel/tank[4]/empty");
    # If only one external Tank is still not empty, then...
    # systems/refuel/contact = false si pas refuel en cours
    if(getprop("/systems/refuel/contact"))
    {
        setprop("/consumables/fuel/tank[0]/selected", 1);
        setprop("/consumables/fuel/tank[1]/selected", 1);
        
        if(getprop("/consumables/fuel/tank[2]/capacity-m3") != 0)
        {
            setprop("/consumables/fuel/tank[2]/selected", 1);
        }
        if(getprop("/consumables/fuel/tank[3]/capacity-m3") != 0)
        {
            setprop("/consumables/fuel/tank[3]/selected", 1);
        }
        if(getprop("/consumables/fuel/tank[4]/capacity-m3") != 0)
        {
            setprop("/consumables/fuel/tank[4]/selected", 1);
        }
    }
    elsif(Externaltank)
    {
        setprop("/consumables/fuel/tank[0]/selected", 1);
        setprop("/consumables/fuel/tank[1]/selected", 1);
    }
    else
    {
        setprop("/consumables/fuel/tank[0]/selected", 0);
        setprop("/consumables/fuel/tank[1]/selected", 0);
        if(getprop("/consumables/fuel/tank[2]/level-kg") > 0)
        {
            setprop("/consumables/fuel/tank[2]/selected", 1);
        }
        if(getprop("/consumables/fuel/tank[3]/level-kg") > 0)
        {
            setprop("/consumables/fuel/tank[3]/selected", 1);
        }
        if(getprop("/consumables/fuel/tank[4]/level-kg") > 0)
        {
            setprop("/consumables/fuel/tank[4]/selected", 1);
        }
    }
}

