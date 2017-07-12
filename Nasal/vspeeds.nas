# Calculate V-speeds and stall speed
var V1announced = 0;
var V2announced = 0;
var VRannounced = 0;
var V1 = "";
var V2 = "";
var VR = "";
var Vref= "";

props.globals.initNode("instrumentation/fmc/vspeeds/stall-speed",0.0,"DOUBLE");

var vspeeds = func {
	
	WT = getprop("/yasim/gross-weight-lbs")*0.00045359237;
	flaps = getprop("/controls/flight/flaps");
	var flap_pos = 15;
	if (flaps > 0.55) flap_pos = 20;
	setprop("/instrumentation/fmc/to-flap",flap_pos);
	if (flap_pos == 15) {
		V1 = (0.3*(WT-200))+100;
		VR = (0.3*(WT-200))+115;
		V2 = (0.3*(WT-200))+135;
	}
	if (flap_pos == 20) {
		V1 = (0.3*(WT-200))+95;
		VR = (0.3*(WT-200))+110;
		V2 = (0.3*(WT-200))+130;
	}
#	if (flaps == 0.833) {
#		Vref = (0.3*(WT-200))+132;
#	}
#	if (flaps == 1) {
#		Vref = (0.285*(WT-200))+127;
#i	}

	var vgrosswt = math.sqrt(getprop("/yasim/gross-weight-lbs")/getprop("/limits/mass-and-balance/maximum-takeoff-mass-lbs"));

        var vref_table = [
                [0, vgrosswt * 166 + 80],
                [0.033, vgrosswt * 166 + 60],
                [0.166, vgrosswt * 166 + 40],
                [0.500, vgrosswt * 166 + 20],
                [0.666, vgrosswt * 180],
                [0.833, vgrosswt * 174],
                [1.000, vgrosswt * 166]];

        var vref_flap = interpolate_table(vref_table, flaps);
        var stallspeed = (vref_flap - 25 + getprop("instrumentation/altimeter/indicated-altitude-ft") / 1000);

	setprop("/instrumentation/fmc/vspeeds/V1",V1);
	setprop("/instrumentation/fmc/vspeeds/VR",VR);
	setprop("/instrumentation/fmc/vspeeds/Vref",vref_flap);
	setprop("/instrumentation/fmc/vspeeds/V2",V2);
	setprop("/instrumentation/fmc/vspeeds/stall-speed",stallspeed);

}
var do_vspeeds = func {
	vspeeds();
	settimer(do_vspeeds, 1);
}
	

setlistener("/sim/signals/fdm-initialized", func {
	settimer(do_vspeeds,2);
},0,0);


# interpolates a value
var interpolate_table = func(table, v)
 {
 var x = 0;
 forindex (i; table)
  {
  if (v >= table[i][0])
   {
   x = i + 1 < size(table) ? (v - table[i][0]) / (table[i + 1][0] - table[i][0]) * (table[i + 1][1] - table[i][1]) + table[i][1] : table[i][1];
   }
  }
 return x;
 };
