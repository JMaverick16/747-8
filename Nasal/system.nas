##############################################
##############################################
# Simple APU control class
# based on Syd�s Engine class
# ie: var EngAPU = APU.new(APU number);
var APU = {
    new : func(eng_num){
        m = { parents : [APU]};
        m.fdensity = getprop("consumables/fuel/tank[1]/density-ppg");
        if(m.fdensity ==nil)m.fdensity=6.72;
        m.eng = props.globals.getNode("engines/apu["~eng_num~"]",1);
        m.running = m.eng.getNode("running",1);
        m.running.setBoolValue(0);
        m.n1 = m.eng.getNode("n1",1);
        m.n1.setDoubleValue(0);
        m.n2 = m.eng.getNode("n2",1);
        m.n2.setDoubleValue(0);
        m.rpm = m.eng.getNode("rpm",1);
        m.rpm.setDoubleValue(0);
        m.cutoff = props.globals.getNode("controls/engines/apu["~eng_num~"]/cutoff",1);
        m.cutoff.setBoolValue(1);
        m.fuel_out = props.globals.getNode("engines/apu["~eng_num~"]/out-of-fuel",1);
        m.fuel_out.setBoolValue(0);
        m.starter = props.globals.getNode("controls/engines/apu["~eng_num~"]/starter",1);
        m.starter.setBoolValue(0);
        m.fuel_pph=m.eng.getNode("fuel-flow_pph",1);
        m.fuel_pph.setDoubleValue(0);
        m.fuel_gph=m.eng.getNode("fuel-flow-gph",1);
        m.fuel_gph.setDoubleValue(0);
        m.apu_starting = props.globals.getNode("controls/engines/apu["~eng_num~"]/starting",1);
        m.apu_starting.setBoolValue(0);
        m.apu_shutdown = props.globals.getNode("controls/engines/apu["~eng_num~"]/shutdown",1);
        m.apu_shutdown.setBoolValue(0);
        m.apu_egt = props.globals.getNode("engines/apu["~eng_num~"]/egt-degc",1);
        m.apu_egt.setDoubleValue(0);
        m.apu_egtf = props.globals.initNode("engines/apu["~eng_num~"]/egt-degf",1);
        m.apu_egtf.setDoubleValue(0);
        m.tank = props.globals.getNode("consumables/fuel/tank[1]/level-lbs",1);
	m.DC_pump = props.globals.initNode("controls/fuel/tank[1]/dc-pump-temp",15,"DOUBLE");
    return m;
    },
#### start ####
    start : func{
    	if ( !me.apu_starting.getValue() and !me.running.getValue() and !me.cutoff.getValue() ) {
        	me.apu_starting.setValue(1);
        	
	        interpolate( me.n1.getPath(), 80, 60);
	        interpolate( me.n2.getPath(), 95, 80);
	        interpolate( me.rpm.getPath(), 10320, 60);
	        
	        interpolate( me.apu_egt.getPath(), 840, 60);
	        interpolate( me.apu_egtf.getPath(), 1.8 * 840 + 32 , 60);
	        
	        interpolate( me.fuel_pph.getPath(), 5050, 60);
	        interpolate( me.fuel_gph.getPath(), 5050 * 453.59237 , 60);
	        
	        settimer( func{ 
	        	me.starter.setValue(0);
	        	me.apu_starting.setValue(0);
	        	me.running.setValue(1);
	        }
	        , 60);
		
#		settimer( func{
#			boost1 = getprop("controls/fuel/tank[1]/pump-fwd");
#			boost2 = getprop("controls/fuel/tank[1]/pump-aft");
#			if (me.running.getValue() and (!boost1) and (!boost2)) 
#				me.shutdown();
#		}
#		, 160);
        };
    },
#### shutdown ####
    shutdown : func{
    	if ( !me.apu_shutdown.getValue() and me.running.getValue() and me.cutoff.getValue() ) {
        	me.apu_shutdown.setValue(1);
        	me.running.setValue(0);
        	
	        interpolate( me.n1.getPath(), 0, 60);
	        interpolate( me.n2.getPath(), 0, 60);
	        interpolate( me.rpm.getPath(), 0, 60);
	        
	        interpolate( me.apu_egt.getPath(), 25, 60);
	        interpolate( me.apu_egtf.getPath(), 1.8 * 25 + 32 , 60);
	        
	        interpolate( me.fuel_pph.getPath(), 0, 60);
	        interpolate( me.fuel_gph.getPath(), 0 * 453.59237 , 60);

	        settimer( func{ 
	        	me.apu_shutdown.setValue(0);
	        	me.cutoff.setValue(0);
	        }
	        , 81);
        };   
    },
#### fuelcons ####
	fuelcons : func {
			if ( me.tank.getValue() > 1 ) {
				var surcharge = 1.0;
				var highflow = 0.0;
				if (getprop("systems/electrical/apu-generator[0]") == 2)
					surcharge = surcharge + 0.003;
				if (getprop("systems/electrical/apu-generator[1]") == 2)
					surcharge = surcharge + 0.003;
				if (getprop("controls/pneumatic/APU-bleed") and !getprop("systems/pneumatic/APU-bleed-valve")) {
					surcharge = surcharge + 0.02;
					if (getprop("controls/pneumatic/pack-high-flow"))
					highflow = 0.06;
#					if (getprop("controls/pneumatic/pack-control[0]"))
					if (getprop("systems/pneumatic/pack"))
					surcharge = surcharge + 0.02 + highflow;
					if (getprop("systems/pneumatic/pack[1]"))
					surcharge = surcharge + 0.02 + highflow;
					if (getprop("systems/pneumatic/pack[2]"))
					surcharge = surcharge + 0.02 + highflow;
					if (getprop("controls/engines/engine/starter"))
					surcharge = surcharge + 0.2;
					if (getprop("controls/engines/engine[1]/starter"))
					surcharge = surcharge + 0.2;
					if (getprop("controls/engines/engine[2]/starter"))
					surcharge = surcharge + 0.2;
					if (getprop("controls/engines/engine[3]/starter"))
					surcharge = surcharge + 0.2;
				}

				var fuel_cons_pph = ( me.n1.getValue() * surcharge * 12.0 ) + rand() ;
				var fuel_cons_pps = ( fuel_cons_pph / 3600 )  ;
				me.fuel_pph.setDoubleValue( fuel_cons_pph );
				me.fuel_gph.setDoubleValue( ( 453.59237 * me.fuel_pph.getValue() ) );
				me.tank.setDoubleValue( me.tank.getValue() - fuel_cons_pps );

				var boost1 = getprop("controls/fuel/tank[1]/pump-fwd");
				var boost2 = getprop("controls/fuel/tank[1]/pump-aft");
				if (me.DC_pump.getValue() < (140 / getprop("consumables/fuel/tank[1]/density-ppg")))
					me.DC_pump.setValue(140 / getprop("consumables/fuel/tank[1]/density-ppg"));
				if (boost1 or boost2)
					me.DC_pump.setValue(me.DC_pump.getValue() - 0.05);
				else
					me.DC_pump.setValue(me.DC_pump.getValue() - 0.05 + (fuel_cons_pps * 0.4));
				if (me.DC_pump.getValue() > 80)
					electrical.turn_apu_sw(-2);
			} else {
				electrical.turn_apu_sw(-2);
#				me.cutoff.setValue(1);
#				me.shutdown();
			};
#			settimer( func {
#				me.fuelcons();
#			}
#			,1);
	},
	
#### update ####
    update : func{
    	if ( me.running.getValue() ) {
    	
			if ( rand() > 0.5 ) {
				var sigflag = -0.01 ;
			} else {
				var sigflag = 0.01 ;
			};
			var n1value = me.n1.getValue() + ( sigflag * rand() ) ;
    		me.n1.setDoubleValue( n1value );
    		me.n2.setDoubleValue( ( me.n1.getValue() * 1.1875 ) + rand() );
    		me.rpm.setDoubleValue( ( me.n1.getValue() * 129.00 ) + rand() );

    		me.apu_egt.setDoubleValue( ( me.n1.getValue() * 8.40 ) + rand() );
			me.apu_egtf.setDoubleValue( ( 1.8 * me.apu_egt.getValue() + 32 ) );
			
			if ( me.cutoff.getValue() ) {
				me.shutdown();
			};
        } else {
			if ( me.starter.getValue() ) {
				me.start();
			};
        
        };
    },

};
##########################
var EngAPU = APU.new(0);

## Mouse drag&drop handler ##

var MouseHandler = {
  new : func() {
    var obj = { parents : [ MouseHandler ] };

    obj.property = nil;
    obj.factor = 1.0;

    obj.YListenerId = setlistener( "devices/status/mice/mouse/accel-y", 
      func(n) { obj.YListener(n); }, 1, 0 );

    return obj;
  },

  YListener : func(n) {
    me.property == nil and return;
    me.factor == 0 and return;
    n == nil and return;
    var v = n.getValue();
    v == nil and return;
    fgcommand("property-adjust", props.Node.new({ 
      "offset" : v,
      "factor" : me.factor,
      "property" : me.property
    }));
  },

  set : func( property = nil, factor = 1.0 ) {
    me.property = property;
    me.factor = factor;
  },

};

var mouseHandler = MouseHandler.new();

## Stall Horn ##
var stall_horn = func {
    var spd = getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
    var stall = getprop("instrumentation/fmc/vspeeds/stall-speed");
    var wow = (getprop("gear/gear[1]/wow") or getprop("gear/gear[4]/wow"));
    if (!wow and spd < 0.8 * stall) {
        setprop("sim/alarms/stall-warning",1);
    } else {
        setprop("sim/alarms/stall-warning",0);
    }
}

## Lights ##

var beacon = aircraft.light.new( "/sim/model/lights/beacon", [0.15, 1.2,], "/controls/lighting/beacon" );
var strobe = aircraft.light.new( "/sim/model/lights/strobe", [0.07, 2,], "/controls/lighting/strobe" );

var light_stat = {
    new : func {
	m = { parents : [light_stat] };
	
	m.light_controls = props.globals.getNode("controls/lighting",0);

	m.beacon_sw = m.light_controls.getNode("beacon",0);
	m.nav_sw = m.light_controls.getNode("nav-lights",0);
	m.strobe_sw = m.light_controls.getNode("strobe",0);
	m.logo_sw = m.light_controls.getNode("logo-lights",0);
	m.wing_sw = m.light_controls.getNode("wing-lights",0);
	m.taxi_sw = m.light_controls.getNode("taxi-lights",0);
	m.Lland_sw = m.light_controls.getNode("landing-lights[1]",0);
	m.Rland_sw = m.light_controls.getNode("landing-lights[2]",0);
	
	m.beacon = props.globals.initNode("systems/electrical/lighting/beacon",0,"BOOL");
	m.nav = props.globals.initNode("systems/electrical/lighting/nav-lights",0,"BOOL");
	m.strobe = props.globals.initNode("systems/electrical/lighting/strobe",0,"BOOL");
	m.logo = props.globals.initNode("systems/electrical/lighting/logo-lights",0,"BOOL");
	m.wing = props.globals.initNode("systems/electrical/lighting/wing-lights",0,"BOOL");
	m.taxi = props.globals.initNode("systems/electrical/lighting/landing-lights[0]",0,"BOOL");
	m.Lland = props.globals.initNode("systems/electrical/lighting/landing-lights[1]",0,"BOOL");
	m.Rland = props.globals.initNode("systems/electrical/lighting/landing-lights[2]",0,"BOOL");

	return m;
    },
    update : func {
	if (getprop("systems/electrical/ac-bus") and !getprop("sim/crashed")) {
	    # Beacon:
	    if (me.beacon_sw.getBoolValue() and getprop("sim/model/lights/beacon/state")) {
		me.beacon.setBoolValue(1);
	    } else {
		me.beacon.setBoolValue(0);
	    }
	    # Strobe:
	    if (me.strobe_sw.getBoolValue() and getprop("sim/model/lights/strobe/state")) {
		me.strobe.setBoolValue(1);
	    } else {
		me.strobe.setBoolValue(0);
	    }
	    # Logo lights:
	    if (me.logo_sw.getBoolValue()) {
		me.logo.setBoolValue(1);
	    } else {
		me.logo.setBoolValue(0);
	    }
	    # Wing lights:
	    if (me.wing_sw.getBoolValue()) {
		me.wing.setBoolValue(1);
	    } else {
		me.wing.setBoolValue(0);
	    }
	    # Taxi light:
	    if (me.taxi_sw.getBoolValue() and getprop("gear/gear[0]/position-norm") > 0.75) {
		me.taxi.setBoolValue(1);
	    } else {
		me.taxi.setBoolValue(0);
	    }
	    # Left landing light:
	    if (me.Lland_sw.getBoolValue()) {
		me.Lland.setBoolValue(1);
	    } else {
		me.Lland.setBoolValue(0);
	    }
	    # Right landing light:
	    if (me.Rland_sw.getBoolValue()) {
		me.Rland.setBoolValue(1);
	    } else {
		me.Rland.setBoolValue(0);
	    }
	} else {
	    me.beacon.setBoolValue(0);
	    me.strobe.setBoolValue(0);
	    me.logo.setBoolValue(0);
	    me.wing.setBoolValue(0);
	    me.taxi.setBoolValue(0);
	    me.Lland.setBoolValue(0);
	    me.Rland.setBoolValue(0);
	}
	    # Nav lights:
	    if (me.nav_sw.getBoolValue() and !getprop("sim/crashed")) {
		me.nav.setBoolValue(1);
	    } else {
		me.nav.setBoolValue(0);
	    }
    },
};
var lighting_status = light_stat.new();
	    

## Landing Gear ##

controls.gearDown = func(v) {
    if (v < 0 and getprop("systems/hydraulic/equipment/enable-flap")) {
	# flaps and gear up have the same hydraulic requirements
        if(!getprop("gear/gear[1]/wow"))setprop("/controls/gear/gear-down", 0);
    }
	elsif (v > 0 and getprop("systems/hydraulic/equipment/enable-gear")) {
      setprop("/controls/gear/gear-down", 1);
    }
}

setlistener("controls/gear/alt-gear", func (alt) {
	if (alt.getBoolValue()) {
		setprop("controls/gear/gear-down",1);
		setlistener("controls/gear/gear-down", func {
		    setprop("controls/gear/gear-down",1);
		},0,0);
	}
},0,0);

# Main gear steering
var MG_steer = {
    new : func {
	m = { parents : [MG_steer] };

	m.nose = props.globals.getNode("controls/flight/rudder",0);
	m.rear = props.globals.initNode("controls/gear/main-gear-steering-norm",0,"DOUBLE");
	m.push = props.globals.initNode("sim/model/pushback/position-norm",0,"DOUBLE");

	m.arm = 0;

	return m;
    },
    update : func {
	var speed = getprop("gear/gear[2]/rollspeed-ms") * 1.94;
	if (getprop("gear/gear/wow")) {
	    if (me.arm == 1 and speed > 20) me.arm = 0;
	    if (me.arm == 0 and speed < 15) me.arm = 1;
	} else {
	    me.arm = 0;
	}

	var enable = math.abs(me.nose.getValue()) > 0.286 and me.arm == 1 and !getprop("/systems/hydraulic/system-fault[0]");

	if (enable) {
	    if (me.nose.getValue() > 0)
		me.rear.setValue(0.349 - (1.349 * me.nose.getValue()));
	    if (me.nose.getValue() < 0)
		me.rear.setValue(-0.349 - (1.349 * me.nose.getValue()));
	} else {
	    me.rear.setValue(0);
	}

	setprop("controls/gear/steering",me.nose.getValue());
    },
};
var maingear_steer = MG_steer.new();

# Gear smoke on touchdown
aircraft.tyresmoke_system.new(0, 1, 2, 3, 4);

# Brake unblocking
setlistener("controls/gear/brake-parking", func (brk) {
	if (!brk.getBoolValue()) {
	    setprop("controls/gear/brake-left", 0);
	    setprop("controls/gear/brake-right", 0);
	}
},0,0);

## Thrust reversers ##
var thr_reverser = func {
	var threv0 = props.globals.getNode("controls/engines/engine[0]/reverser",1);
	var threv1 = props.globals.getNode("controls/engines/engine[1]/reverser",1);
	var threv2 = props.globals.getNode("controls/engines/engine[2]/reverser",1);
	var threv3 = props.globals.getNode("controls/engines/engine[3]/reverser",1);

	if (getprop("systems/hydraulic/equipment/enable-threv")) {
	    if (threv0.getBoolValue() and threv1.getBoolValue() and threv2.getBoolValue() and threv3.getBoolValue()) {
		threv0.setBoolValue(0);
		threv1.setBoolValue(0);
		threv2.setBoolValue(0);
		threv3.setBoolValue(0);
	    } else {
		threv0.setBoolValue(1);
		threv1.setBoolValue(1);
		threv2.setBoolValue(1);
		threv3.setBoolValue(1);
#		if (getprop("systems/hydraulic/equipment/enable-spoil"))
#		    setprop("controls/flight/speedbrake",1);
	    }
	}
}

## Flaps ##
controls.flapsDown = func(step) {
    if (getprop("systems/hydraulic/equipment/enable-flap") or getprop("controls/flight/alt-flaps") != 0) {
    	if(step == 0) return;
    	if(props.globals.getNode("/sim/flaps") != nil) {
        	globals.controls.stepProps("/controls/flight/flaps", "/sim/flaps", step);
        	return;
    	}
    	# Hard-coded flaps movement in 3 equal steps:
    	var val = 0.3333334 * step + getprop("/controls/flight/flaps");
    	setprop("/controls/flight/flaps", val > 1 ? 1 : val < 0 ? 0 : val);
    }
}

var altflaparm = props.globals.initNode("controls/flight/alt-flaps-arm",0,"BOOL");
var altflap = props.globals.initNode("controls/flight/alt-flaps",0,"INT");
var altn_flapsDown = func(step) {
    if (getprop("/controls/flight/alt-flaps-arm")) {
	if (step == 0) return;
	setprop("controls/flight/alt-flaps",step);
	settimer(func {setprop("controls/flight/alt-flaps",0);},0.15);
	if (getprop("controls/flight/flaps") >= 0.833 and step == 1) return;
	controls.flapsDown(step);
    }
}

## Flight Controls ##
#var fltctrls = props.globals.getNode("controls/flight",1);
#var ailnctrl = fltctrls.getNode("aileron",1);
#var elevctrl = fltctrls.getNode("elevator",1);
#var rudrctrl = fltctrls.getNode("rudder",1);
#var ailnpos = fltctrls.initNode("aileron-pos",0,"DOUBLE");
#var elevpos = fltctrls.initNode("elevator-pos",0,"DOUBLE");
#var rudrpos = fltctrls.initNode("rudder-pos",0,"DOUBLE");

#var set_fltctrls = func {
#    if (getprop("systems/hydraulic/equipment/enable-sfc")) {
#        ailnpos.setValue(ailnctrl.getValue());
#        elevpos.setValue(elevctrl.getValue());
#        rudrpos.setValue(rudrctrl.getValue());
#    }
#}

## Seatbelt Sign ##
var seatbelt_knob = props.globals.initNode("controls/switches/seatbelt-sign",0,"INT");
var seatbelt_on = props.globals.initNode("controls/cabin/seatbelt-sign",0,"BOOL");
var sblt_auto = func {
    if (getprop("instrumentation/altimeter/indicated-altitude-ft") < 10000) {
	seatbelt_on.setBoolValue(1);
    } else {
	seatbelt_on.setBoolValue(0);
    }
    settimer( func {
	if (seatbelt_knob.getValue() == 1) sblt_auto();
    }, 3);
}
setlistener("controls/switches/seatbelt-sign", func {
    if (seatbelt_knob.getValue() == 0)
	seatbelt_on.setBoolValue(0);
    if (seatbelt_knob.getValue() == 1)
	sblt_auto();
    if (seatbelt_knob.getValue() == 2)
	seatbelt_on.setBoolValue(1);
},0,0);
	    

## Switch click sound ##
var click_reset = func(propName) {
	setprop(propName,0);
}
controls.click = func {
	if (getprop("sim/freeze/replay-state"))
		return;
	var propName="sim/sound/click";
	setprop(propName,1);
	settimer(func { click_reset(propName) },0.4);
}

## Yoke charts ##
settimer(func {
	setprop("/instrumentation/groundradar/id", getprop("/sim/airport/closest-airport-id"));
},5);

# 777-300 systems
#Syd Adams
#

var SndOut = props.globals.getNode("/sim/sound/Ovolume",1);

##############################################
##############################################
#Engine control class
# ie: var Eng = Engine.new(engine number);
var Engine = {
    new : func(eng_num){
        m = { parents : [Engine]};
        m.fdensity = getprop("consumables/fuel/tank/density-ppg");
        if(m.fdensity ==nil)m.fdensity=6.72;
        m.eng = props.globals.getNode("engines/engine["~eng_num~"]",1);
        m.running = m.eng.getNode("running",1);
        m.running.setBoolValue(0);
	m.started = m.eng.initNode("started",0,"BOOL");
	m.started.setBoolValue(0);
        m.n1 = m.eng.getNode("n1",1);
        m.n2 = m.eng.getNode("n2",1);
        m.n1ind = m.eng.getNode("n1-ind",1);
        m.n1ind.setDoubleValue(0);
        m.n2ind = m.eng.getNode("n2-ind",1);
        m.n2ind.setDoubleValue(0);
        m.rpm = m.eng.getNode("rpm",1);
        m.rpm.setDoubleValue(0);
        m.throttle_lever = props.globals.getNode("controls/engines/engine["~eng_num~"]/throttle-lever",1);
        m.throttle_lever.setDoubleValue(0);
        m.throttle = props.globals.getNode("controls/engines/engine["~eng_num~"]/throttle",1);
        m.throttle.setDoubleValue(0);
	m.throttle_fdm = props.globals.initNode("controls/engines/engine["~eng_num~"]/throttle-fdm",1);
	m.throttle_fdm.setDoubleValue(0);
        m.cutoff = props.globals.getNode("controls/engines/engine["~eng_num~"]/cutoff",1);
        m.cutoff.setBoolValue(1);
        m.fuel_out = props.globals.getNode("engines/engine["~eng_num~"]/out-of-fuel",1);
        m.fuel_out.setBoolValue(0);
        m.starter = props.globals.getNode("controls/engines/engine["~eng_num~"]/starter",1);
        m.fuel_pph=m.eng.getNode("fuel-flow_pph",1);
        m.fuel_pph.setDoubleValue(0);
        m.fuel_gph=m.eng.getNode("fuel-flow-gph",1);
        m.hpump=props.globals.getNode("systems/hydraulic/pump-psi["~eng_num~"]",1);
        m.hpump.setDoubleValue(0);
    return m;
    },
#### update ####
    update : func {
	if (me.cutoff.getBoolValue()) me.started.setBoolValue(0);
	if (me.running.getBoolValue() and !me.started.getBoolValue())
		me.running.setBoolValue(0);
#        if(me.fuel_out.getBoolValue())me.cutoff.setBoolValue(1);
#        if(!me.cutoff.getBoolValue()){
        if (me.fuel_out.getBoolValue()) me.started.setBoolValue(0);
        if (me.started.getBoolValue()) {
        	me.rpm.setValue(me.n1.getValue());
        	me.n1ind.setValue(me.n1.getValue());
        	me.n2ind.setValue(me.n2.getValue());
        	
        	me.throttle_lever.setValue(me.throttle.getValue());
        } else {
            me.throttle_lever.setValue(0);
        	me.throttle.setValue(0.0);
        	
            if (me.starter.getBoolValue()) {
                me.spool_up();
            } else {
                var tmprpm = me.rpm.getValue();
                var tmpn1ind = me.n1ind.getValue();
                var tmpn2ind = me.n2ind.getValue();

                if (tmprpm > 0.0) {
                    tmprpm -= getprop("sim/time/delta-realtime-sec") * 0.5;
                    me.rpm.setValue(tmprpm);
                    tmpn1ind -= getprop("sim/time/delta-realtime-sec") * 0.5;
                    me.n1ind.setValue(tmpn1ind);
                    tmpn2ind -= getprop("sim/time/delta-realtime-sec") * 0.5;
                    me.n2ind.setValue(tmpn2ind);
                    
                }
            }
        }

#	var th_idle = 0.035;
	var th_idle = 0;

	me.throttle_fdm.setValue((me.throttle.getValue() * (1 - th_idle)) + th_idle);
	me.fuel_pph.setValue(me.fuel_gph.getValue() * me.fdensity);
	var hpsi = me.rpm.getValue();
	if (hpsi > 60) hpsi = 60;
	me.hpump.setValue(hpsi);
    },

    spool_up : func {
        if (!me.cutoff.getBoolValue()) {
#            return;
	    settimer(func {me.starter.setBoolValue(0);},0.2);
        } else {
            var tmpn1ind = me.n1ind.getValue();
            tmpn1ind += getprop("sim/time/delta-realtime-sec") * 0.5;
            me.n1ind.setValue(tmpn1ind);

            var tmpn2ind = me.n2ind.getValue();
            tmpn2ind += getprop("sim/time/delta-realtime-sec") * 0.5;
            me.n2ind.setValue(tmpn2ind);

            var tmprpm = me.rpm.getValue();
            tmprpm += getprop("sim/time/delta-realtime-sec") * 0.5;
            me.rpm.setValue(tmprpm);
            if(tmprpm >= me.n1.getValue()) {
		me.cutoff.setBoolValue(0);
		me.running.setBoolValue(1);
		me.started.setBoolValue(1);
		settimer(func {me.starter.setBoolValue(0);},1);
	    }
        }
    },

};
##########################

var LEHeng=Engine.new(0);
var LIHeng=Engine.new(1);
var RIHeng=Engine.new(2);
var REHeng=Engine.new(3);

setlistener("/sim/signals/fdm-initialized", func {
    itaf.ap_init();
    var autopilot = gui.Dialog.new("sim/gui/dialogs/autopilot/dialog", "Aircraft/747-8/Systems/autopilot-dlg.xml");
    SndOut.setDoubleValue(0.15);
    Shutdown();
    settimer(start_updates,1);
    settimer(update_fuel_apu,1);
});

var start_updates = func {
    if (getprop("position/gear-agl-ft")>30)
    {
        # airborne startup
        setprop("/controls/gear/brake-parking",0);
        controls.gearDown(-1);
	magic_autostart();
    }
    update_systems();
}

setlistener("/sim/signals/reinit", func {
    SndOut.setDoubleValue(0.15);
    Shutdown();
});

setlistener("/sim/current-view/internal", func(vw){
    if(vw.getValue()){
    SndOut.setDoubleValue(0.3);
    }else{
    SndOut.setDoubleValue(1.0);
    }
},1,0);

controls.toggleLandingLights = func()
{
    var state = getprop("controls/lighting/landing-light[1]");
    setprop("controls/lighting/landing-light[0]",!state);
    setprop("controls/lighting/landing-light[1]",!state);
    setprop("controls/lighting/landing-light[2]",!state);
}

var magic_autostart = func {
    setprop("systems/electrical/generator-off",0);
    setprop("systems/electrical/ac-bus",1);
    setprop("controls/fuel/tank[1]/pump-fwd",1);
    setprop("controls/fuel/tank[2]/pump-fwd",1);
    setprop("controls/fuel/tank[3]/pump-fwd",1);
    setprop("controls/fuel/tank[4]/pump-fwd",1);
    setprop("consumables/fuel/tank[1]/selected",1);
    setprop("consumables/fuel/tank[2]/selected",1);
    setprop("consumables/fuel/tank[3]/selected",1);
    setprop("consumables/fuel/tank[4]/selected",1);
    settimer( func{
    	if (getprop("sim/model/start-idling")) {
	    setprop("sim/model/start-idling",0);
    	} else {
	    setprop("sim/model/start-idling",1);
    	}
    } , 0.5);
}

setlistener("/sim/model/start-idling", func(idle){
    var run= idle.getBoolValue();
    if(run){
    Startup();
    }else{
    Shutdown();
    }
},0,0);

var Startup = func{
setprop("sim/model/armrest",1);
setprop("controls/electric/engine[0]/generator",1);
setprop("controls/electric/engine[1]/generator",1);
setprop("controls/electric/engine[2]/generator",1);
setprop("controls/electric/engine[3]/generator",1);

setprop("controls/electric/engine[0]/bus-tie",1);
setprop("controls/electric/engine[1]/bus-tie",1);
setprop("controls/electric/engine[2]/bus-tie",1);
setprop("controls/electric/engine[3]/bus-tie",1);

setprop("instrumentation/transponder/inputs/knob-pos",3);

setprop("controls/electric/APU-generator",1);
setprop("controls/electric/avionics-switch",1);
setprop("controls/electric/battery-switch",1);
setprop("controls/electric/battery",1);
setprop("systems/electrical/battery-off",0);
setprop("controls/electric/inverter-switch",1);

setprop("controls/pneumatic/engine-bleed",1);
setprop("controls/pneumatic/engine-bleed[1]",1);
setprop("controls/pneumatic/engine-bleed[2]",1);
setprop("controls/pneumatic/engine-bleed[3]",1);

settimer(func {
  setprop("controls/pneumatic/pack-control",1);
  setprop("controls/pneumatic/pack-control[1]",1);
  setprop("controls/pneumatic/pack-control[2]",1);
  setprop("controls/pneumatic/equip-cooling",1);

  setprop("controls/hydraulic/demand-pump",1);
  setprop("controls/hydraulic/demand-pump[1]",1);
  setprop("controls/hydraulic/demand-pump[2]",1);
  setprop("controls/hydraulic/demand-pump[3]",1);
},0.7);

setprop("controls/hydraulic/engine-pump",1);
setprop("controls/hydraulic/engine-pump[1]",1);
setprop("controls/hydraulic/engine-pump[2]",1);
setprop("controls/hydraulic/engine-pump[3]",1);

setprop("controls/inertial-reference/position",2);
setprop("controls/inertial-reference/position[1]",2);
setprop("controls/inertial-reference/position[2]",2);
setprop("systems/inertial-reference/mode",2);
setprop("systems/inertial-reference/mode[1]",2);
setprop("systems/inertial-reference/mode[2]",2);
setprop("systems/inertial-reference/alignment",2);
setprop("systems/inertial-reference/alignment[1]",2);
setprop("systems/inertial-reference/alignment[2]",2);

setprop("controls/lighting/instrument-norm",0.8);
setprop("controls/lighting/nav-lights",1);
setprop("controls/lighting/beacon",1);
setprop("controls/lighting/strobe",1);
setprop("controls/lighting/wing-lights",1);
setprop("controls/lighting/taxi-lights",1);
setprop("controls/lighting/logo-lights",1);
setprop("controls/lighting/cabin-lights",1);
setprop("controls/lighting/landing-lights[0]",1);
setprop("controls/lighting/landing-lights[1]",1);
setprop("controls/lighting/landing-lights[2]",1);

setprop("controls/engines/engine[0]/cutoff",0);
setprop("controls/engines/engine[1]/cutoff",0);
setprop("controls/engines/engine[2]/cutoff",0);
setprop("controls/engines/engine[3]/cutoff",0);

Boeing747.startup_dist();
setprop("engines/engine[0]/started",1);
setprop("engines/engine[1]/started",1);
setprop("engines/engine[2]/started",1);
setprop("engines/engine[3]/started",1);

setprop("controls/fuel/tank/pump",1);
setprop("controls/fuel/tank[7]/pump",1);
setprop("controls/fuel/tank[1]/pump-fwd",1);
setprop("controls/fuel/tank[1]/pump-aft",1);
setprop("controls/fuel/tank[2]/pump-fwd",1);
setprop("controls/fuel/tank[2]/pump-aft",1);
setprop("controls/fuel/tank[3]/pump-fwd",1);
setprop("controls/fuel/tank[3]/pump-aft",1);
setprop("controls/fuel/tank[4]/pump-fwd",1);
setprop("controls/fuel/tank[4]/pump-aft",1);
setprop("controls/fuel/tank[1]/x-feed",1);
setprop("controls/fuel/tank[2]/x-feed",1);
setprop("controls/fuel/tank[3]/x-feed",1);
setprop("controls/fuel/tank[4]/x-feed",1);
setprop("controls/fuel/tank[1]/ovrd-fwd",1);
setprop("controls/fuel/tank[1]/ovrd-aft",1);
setprop("controls/fuel/tank[2]/ovrd-fwd",1);
setprop("controls/fuel/tank[2]/ovrd-aft",1);
setprop("controls/fuel/auto-manage",1);

setprop("controls/flight/elevator-trim",0);
setprop("controls/flight/aileron-trim",0);
setprop("controls/flight/rudder-trim",0);

if (getprop("/sim/model/start-idling")==0) setprop("/sim/model/start-idling",1);

}

var Shutdown = func{
setprop("/controls/gear/brake-parking",1);

setprop("controls/electric/engine[0]/generator",0);
setprop("controls/electric/engine[1]/generator",0);
setprop("controls/electric/engine[2]/generator",0);
setprop("controls/electric/engine[3]/generator",0);

setprop("controls/electric/engine[0]/bus-tie",0);
setprop("controls/electric/engine[1]/bus-tie",0);
setprop("controls/electric/engine[2]/bus-tie",0);
setprop("controls/electric/engine[3]/bus-tie",0);

setprop("controls/pneumatic/engine-bleed",0);
setprop("controls/pneumatic/engine-bleed[1]",0);
setprop("controls/pneumatic/engine-bleed[2]",0);
setprop("controls/pneumatic/engine-bleed[3]",0);

setprop("controls/pneumatic/pack-control",0);
setprop("controls/pneumatic/pack-control[1]",0);
setprop("controls/pneumatic/pack-control[2]",0);
setprop("controls/pneumatic/equip-cooling",0);

setprop("controls/hydraulic/demand-pump",0);
setprop("controls/hydraulic/demand-pump[1]",0);
setprop("controls/hydraulic/demand-pump[2]",0);
setprop("controls/hydraulic/demand-pump[3]",0);

setprop("controls/hydraulic/engine-pump",0);
setprop("controls/hydraulic/engine-pump[1]",0);
setprop("controls/hydraulic/engine-pump[2]",0);
setprop("controls/hydraulic/engine-pump[3]",0);

setprop("controls/electric/APU-generator",0);
setprop("controls/electric/avionics-switch",0);
setprop("controls/electric/battery-switch",0);
setprop("controls/electric/battery",0);
setprop("systems/electrical/battery-off",1);
setprop("controls/electric/inverter-switch",0);

setprop("instrumentation/transponder/inputs/knob-pos",0);
setprop("controls/inertial-reference/position",0);
setprop("controls/inertial-reference/position[1]",0);
setprop("controls/inertial-reference/position[2]",0);
setprop("systems/inertial-reference/mode",0);
setprop("systems/inertial-reference/mode[1]",0);
setprop("systems/inertial-reference/mode[2]",0);
setprop("systems/inertial-reference/alignment",0);
setprop("systems/inertial-reference/alignment[1]",0);
setprop("systems/inertial-reference/alignment[2]",0);

setprop("controls/lighting/instruments-norm",0);
setprop("controls/lighting/nav-lights",0);
setprop("controls/lighting/beacon",0);
setprop("controls/lighting/strobe",0);
setprop("controls/lighting/wing-lights",0);
setprop("controls/lighting/taxi-lights",0);
setprop("controls/lighting/logo-lights",0);
setprop("controls/lighting/cabin-lights",0);
setprop("controls/lighting/landing-lights[0]",0);
setprop("controls/lighting/landing-lights[1]",0);
setprop("controls/lighting/landing-lights[2]",0);

setprop("controls/engines/engine[0]/cutoff",1);
setprop("controls/engines/engine[1]/cutoff",1);
setprop("controls/engines/engine[2]/cutoff",1);
setprop("controls/engines/engine[3]/cutoff",1);

setprop("controls/fuel/tank/pump",0);
setprop("controls/fuel/tank[1]/ovrd-fwd",0);
setprop("controls/fuel/tank[1]/ovrd-aft",0);
setprop("controls/fuel/tank[2]/ovrd-fwd",0);
setprop("controls/fuel/tank[2]/ovrd-aft",0);
setprop("controls/fuel/tank[1]/pump-fwd",0);
setprop("controls/fuel/tank[1]/pump-aft",0);
setprop("controls/fuel/tank[2]/pump-fwd",0);
setprop("controls/fuel/tank[2]/pump-aft",0);
setprop("controls/fuel/tank[3]/pump-fwd",0);
setprop("controls/fuel/tank[3]/pump-aft",0);
setprop("controls/fuel/tank[4]/pump-fwd",0);
setprop("controls/fuel/tank[4]/pump-aft",0);
setprop("controls/fuel/tank[7]/pump",0);
setprop("controls/fuel/tank[1]/x-feed",0);
setprop("controls/fuel/tank[2]/x-feed",0);
setprop("controls/fuel/tank[3]/x-feed",0);
setprop("controls/fuel/tank[4]/x-feed",0);

setprop("consumables/fuel/tank/selected",0);
setprop("consumables/fuel/tank[1]/selected",0);
setprop("consumables/fuel/tank[2]/selected",0);
setprop("consumables/fuel/tank[3]/selected",0);
setprop("consumables/fuel/tank[4]/selected",0);
setprop("consumables/fuel/tank[5]/selected",0);
setprop("consumables/fuel/tank[6]/selected",0);
setprop("consumables/fuel/tank[7]/selected",0);

setprop("sim/model/armrest",0);

if (getprop("/sim/model/start-idling")) setprop("/sim/model/start-idling",0);
}

var update_systems = func {
    LEHeng.update();
    LIHeng.update();
    RIHeng.update();
    REHeng.update();
    
    EngAPU.update();
	
    Efis.calc_kpa();
    Efis.update_temp();
    Efis.update_wind();
#    wiper.active();
    stall_horn();
#    set_fltctrls();
    maingear_steer.update();
    lighting_status.update();
    if(getprop("controls/gear/gear-down")){
        setprop("sim/multiplay/generic/float[0]",getprop("gear/gear[0]/compression-m"));
        setprop("sim/multiplay/generic/float[1]",getprop("gear/gear[1]/compression-m"));
        setprop("sim/multiplay/generic/float[2]",getprop("gear/gear[2]/compression-m"));
    }
    var et_tmp = getprop("/instrumentation/clock/ET-sec");
   
    var et_min = int(et_tmp * 0.0166666666667);
    var et_hr = int(et_min * 0.0166666666667) * 100;
    et_tmp = et_hr+et_min;
    setprop("instrumentation/clock/ET-display",et_tmp);

    
    settimer(update_systems,0);
}

var update_fuel_apu = func {
	EngAPU.fuelcons();
	settimer(update_fuel_apu,1);
}

