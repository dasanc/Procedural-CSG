//User Inputs
PODS = 3;			//Unit: num of pods; Affects: get_height, make_spiral
RENDER = 15;		//Unit: resolution; Keep at 12 until you have a winning shape, then 25-50 for final render.

//Process Inputs
$fn = RENDER;			//Unit: fragments; controls render settings
LEG_ANGLE = 20; 	//Unit: degrees; angle between XY plane and leg
LEG_LENGTH = 80;	//Unit: mm; represents dist along XY plane, not diagonal len of leg;
LEG_DIAM = 10;		//Unit: mm
LEG_COUNT = 3;		//Unit: num of legs
FEET_TYPE = "hole";	//Options: round, flat, hole, frog; end caps for feet - use flat/hole if you want to attach pads
MAST_DIAM = 12;		//Unit: mm; diam of center column
FEET_HOLE_DIAM = 4;	//Unit: mm
BLEND_RADIUS = 0.1;	//Unit: mm; corner breaking radius for Minkowski op
SHELL = 2;			//Unit: mm; wall thickness

//***See make_pod_tree for Spiral Input Variables***//

//Module Debugging
make_base();
make_pod_hole();
!make_pod_tree();

module make_base(){
	//MODULE VARIABLES
	mast_len = get_mast_len();		//Gets the distance from spiral to feet top
	angle = 360/LEG_COUNT;			//Angle between each leg
	mast_rise = FEET_TYPE=="round" ? LEG_LENGTH*tan(LEG_ANGLE) + LEG_DIAM/2 : LEG_LENGTH*tan(LEG_ANGLE);
	leg_hypotenuse = LEG_LENGTH/cos(LEG_ANGLE);
	//Generate mast (center column)
	color("FireBrick") {//minkowski(){ 
		union(){
			translate([0,0,mast_rise]) cylinder(d=MAST_DIAM, h=mast_len);
			make_legs(mast_rise,leg_hypotenuse,angle);		
		}
		sphere(BLEND_RADIUS);
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
				union(){
					translate([0,0,mast_rise]) rotate([90+LEG_ANGLE,0,angle*i]) cylinder(d=LEG_DIAM,h=leg_hypotenuse);
					rotate([0,0,angle*i]) translate([0,-LEG_LENGTH,0]) scale([1,1,0.5]) sphere(LEG_DIAM);
				}
				translate([0,0,-LEG_DIAM/2]) cylinder(r=leg_hypotenuse+LEG_DIAM,h=LEG_DIAM,center=true);
			}
		}
	}
}  

//SPIRAL ALGORITHM INPUTS 
ANGLE0 = [90,0,0];		//Unit: degrees; base orientation of each pod
ANGLE_STEP = [0,0,PODS*30];	//Unit: degrees; degrees to increment for next pod
COORD0 = [0,0,0];		//test
COORD_STEP = [0,0,0];	//test
POD_DIAM = 32;			//Unit: mm; diameter of top of pod
POD_CS = 8;				//Unit: mm; Outer diamer to inner diameter of hole
HOLE_TYPE = "ring";		//Unit: ring, sheet, octagon 

module make_pod_tree(){
	//MODULE VARIABLES
	current_angle = [0,0,0];

	for(i = [0:PODS-1]){
		rotate((i/(PODS-1)) * ANGLE_STEP) translate([i/(PODS-1) * LEG_LENGTH ,0,0])
		rotate(ANGLE0) translate(COORD0) make_pod_hole();
	}
}

module make_pod_hole(type = "ring"){
	//MODULE VARIABLES
	if(type=="ring"){
		difference(){
			cylinder(d=POD_DIAM+POD_CS*2,h=SHELL,center=true);
			cylinder(d=POD_DIAM,h=SHELL+2,center=true);
		}
	}

	if(type=="sheet"){
		difference(){
			cube([POD_DIAM+POD_CS*2, POD_DIAM+POD_CS*2,SHELL],center=true);
			cylinder(d=POD_DIAM,h=SHELL+2,center=true);
		}
	}

}

function get_mast_len() = PODS * 1;
