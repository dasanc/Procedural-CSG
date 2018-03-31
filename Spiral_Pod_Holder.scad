//User Inputs
PODS = 18;			//Unit: num of pods; Affects: get_height, make_spiral
RENDER = 18;		//Unit: resolution; Keep at 12 until you have a winning shape, then 25-50 for final render.

//Process Inputs
$fn = RENDER;			//Unit: fragments; controls render settings
LEG_ANGLE = 6; 	//Unit: degrees; angle between XY plane and leg
LEG_LENGTH = 55;	//Unit: mm; represents dist along XY plane, not diagonal len of leg;
LEG_DIAM = 12;		//Unit: mm
LEG_COUNT = 5;		//Unit: num of legs
FEET_TYPE = "frog";	//Options: round, flat, hole, frog; end caps for feet - use flat/hole if you want to attach pads
MAST_DIAM = 12;		//Unit: mm; diam of center column
FEET_HOLE_DIAM = 4;	//Unit: mm
BLEND_RADIUS = 0.1;	//Unit: mm; corner breaking radius for Minkowski op
SHELL = 1.6;			//Unit: mm; wall thickness
PI = 3.14159;		//Constant for math
POD_HEIGHT = 30;	//Unit: mm; Height of pod
GROOVE	= 3;		//Unit:mm; depth of cut for thumb groove to make removal easier

//***See make_pod_tree for Spiral Input Variables***//

//Module Debugging
make_base();
make_pod_tree(20,4);

module make_base(){
	//MODULE VARIABLES
	mast_len = get_mast_len() +  sin(RING_ANGLE);		//Gets the distance from spiral to feet top
	angle = 360/LEG_COUNT;			//Angle between each leg
	mast_rise = get_mast_rise();
	leg_hypotenuse = LEG_LENGTH/cos(LEG_ANGLE);
	//Generate mast (center column)
	color("FireBrick") {
		union(){
			translate([0,0,mast_rise]) cylinder(d=MAST_DIAM, h=mast_len);
			make_legs(mast_rise,leg_hypotenuse,angle);		
		}
	}
}

module make_legs(mast_rise=1, leg_hypotenuse=1, angle=90) {
	choice = FEET_TYPE =="round" ? 1: 
	 FEET_TYPE == "flat" ? 2:
	 FEET_TYPE == "hole" ? 3: 
	 FEET_TYPE == "frog" ? 4:
		//Default feet type is rounded
		1;
	//Round feet
	if(choice==1){
		for(i=[1:LEG_COUNT]){
			translate([0,0,mast_rise]) rotate([90+LEG_ANGLE,0,angle*i]) cylinder(d=LEG_DIAM,h=leg_hypotenuse);
			rotate([0,0,angle*i]) translate([0,-LEG_LENGTH,LEG_DIAM/2]) sphere(LEG_DIAM/2);
		}
	}
	//Flat bottom feet with round ends
	if(choice==2){
		for(i=[1:LEG_COUNT]){
			difference(){
				union(){
					translate([0,0,mast_rise]) rotate([90+LEG_ANGLE,0,angle*i]) cylinder(d=LEG_DIAM,h=leg_hypotenuse);
					rotate([0,0,angle*i]) translate([0,-LEG_LENGTH,0]) sphere(LEG_DIAM/2);
				}
				translate([0,0,-LEG_DIAM/2]) cylinder(r=leg_hypotenuse+LEG_DIAM,h=LEG_DIAM,center=true);
			}
		}
	}
	//Flat bottom feet with round ends and thru hole
	if(choice==3){
		for(i=[1:LEG_COUNT]){
			difference(){
				union(){
					translate([0,0,mast_rise]) rotate([90+LEG_ANGLE,0,angle*i]) cylinder(d=LEG_DIAM,h=leg_hypotenuse);
					rotate([0,0,angle*i]) translate([0,-LEG_LENGTH,0]) sphere(LEG_DIAM/2);
				}
				translate([0,0,-LEG_DIAM/2]) cylinder(r=leg_hypotenuse+LEG_DIAM,h=LEG_DIAM,center=true);
				rotate([0,0,angle*i]) translate([0,-LEG_LENGTH,-1]) cylinder(d=FEET_HOLE_DIAM, h=LEG_DIAM*2);
			}
		}
	}
	//Flat bottom feet with large round ends
	if(choice==4){
		for(i=[1:LEG_COUNT]){
			difference(){
				hull(){
					translate([0,0,mast_rise]) rotate([90+LEG_ANGLE,0,angle*i]) cylinder(d=LEG_DIAM,h=leg_hypotenuse);
					rotate([0,0,angle*i]) translate([0,-LEG_LENGTH,0]) scale([1,1,0.5]) sphere(LEG_DIAM);
				}
				translate([0,0,-LEG_DIAM/2]) cylinder(r=leg_hypotenuse+LEG_DIAM,h=LEG_DIAM,center=true);
			}
		}
	}
}  

//SPIRAL ALGORITHM INPUTS 
POD_DIAM = 32;			//Unit: mm; diameter of top of pod
POD_CS = 8;				//Unit: mm; Outer diamer to inner diameter of hole
MAX_ROTATION = PODS*32 > 360? PODS*(POD_DIAM + SHELL) : 360;	//Number of rotations to perform
RADIUS_CONST = 60;	//Largest radius of spiral at the base
HOLE_TYPE = "ring";		//Unit: ring, sheet, octagon
RING_ANGLE = 45;		//Angle the ring faces upward
START_HEIGHT = get_mast_len() + get_mast_rise();
//echo(START_HEIGHT);

module make_pod_tree(fn = 5, steps = 5){
	//MODULE VARIABLES
	STEP = steps;
	STEPS = STEP*PODS;
	difference(){
		for(i = [0:STEPS - STEP]){
			R = RADIUS_CONST + i * PODS/STEPS;
			TRANSLATION = [R*cos(i/(STEPS) * MAX_ROTATION), R*sin(i/(STEPS) * MAX_ROTATION), START_HEIGHT  + R/tan(RING_ANGLE) - i * START_HEIGHT/STEPS ];
			ORIENTATION = [RING_ANGLE, 0, face_normal(TRANSLATION)];	//Starting orientation in degrees
			translate(TRANSLATION) rotate(ORIENTATION)
			if(i%STEP == 0){
				make_pod_disc($fn = fn);
			}
			else{
				make_pod_disc_gap($fn = fn);
			}
		}

		for(i = [0:PODS-1]){
			R = RADIUS_CONST + i;
			TRANSLATION = [R*cos(i/(PODS) * MAX_ROTATION), R*sin(i/(PODS) * MAX_ROTATION), START_HEIGHT +R/tan(RING_ANGLE) - i * START_HEIGHT/PODS ];
			ORIENTATION = [RING_ANGLE, 0, face_normal(TRANSLATION)];	//Starting orientation in degrees
			translate(TRANSLATION) rotate(ORIENTATION) make_pod_cut(POD_HEIGHT);
		}
	}
}

module make_pod_disc(){
	//cylinder(d=POD_DIAM+POD_CS*2,h=SHELL,center=true);
	translate([0,0,-RADIUS_CONST*cos(RING_ANGLE)]) cylinder(r1=POD_DIAM/4 + SHELL, r2=POD_DIAM/2 + SHELL,h=RADIUS_CONST/cos(RING_ANGLE),center=true);
	translate([0,0,-RADIUS_CONST*1.4]) sphere(POD_DIAM/4 + SHELL);
}
module make_pod_disc_gap(){
	//cylinder(d=POD_DIAM+POD_CS*2,h=SHELL,center=true);
	R1 = POD_DIAM/5 + SHELL;
	R2 = POD_DIAM/3 + SHELL;
	H = 0.8*(RADIUS_CONST/cos(RING_ANGLE));
	translate([0,0,-RADIUS_CONST*cos(RING_ANGLE)]) cylinder(r1=R1, r2=R2,h=H,center=true);
	translate([0,0,-RADIUS_CONST*1.4]) sphere(POD_DIAM/4 + SHELL);
}

module make_pod_cut(H = POD_HEIGHT){
	//cylinder(d=POD_DIAM+POD_CS*2,h=SHELL,center=true);
	R2 = POD_DIAM/2;
	R1 = 26/2;
	translate([0,0,-H/2 + 4]) cylinder(r2=R2, r1=R1, h=H+4,center=true);
	translate([-8,-(POD_DIAM + SHELL + 4)/2,-GROOVE + 1]) cube([16,POD_DIAM+SHELL*4,GROOVE + 1]);
}

module make_pod_hole(type = "ring", O = [0,0,0]){
	//MODULE VARIABLES
	if(type=="ring"){
		rotate(O) 
		difference(){
			cylinder(d=POD_DIAM+POD_CS*2,h=SHELL,center=true);
			cylinder(d=POD_DIAM,h=SHELL+2,center=true);
		}
	}

	if(type=="sheet"){
		rotate(O)		
		difference(){
			cube([POD_DIAM+POD_CS*2, POD_DIAM+POD_CS*2,SHELL],center=true);
			cylinder(d=POD_DIAM,h=SHELL+2,center=true);
		}
	}

}

function get_mast_len() = (POD_HEIGHT/5)*sin(RING_ANGLE)*PODS;

function get_mast_rise() = FEET_TYPE=="round" ? LEG_LENGTH*tan(LEG_ANGLE) + LEG_DIAM/2 : LEG_LENGTH*tan(LEG_ANGLE);

function face_normal(pos = []) = pos[0] > 0 ? 90 + atan(pos[1]/pos[0]) : pos[0] != 0 ? atan(pos[1]/pos[0]) - 90 : pos[1] > 1 ? 180 : 0;