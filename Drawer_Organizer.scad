/*
*DEVELOPER: 	Dasan Costandi
*SUMMARY:		Script to generate simple, printable organizers for a drawer.
*USER INPUT:	- Dimensions of Drawer
*				- Number of slots to include
*				- Depth of slots
*				- Slot Style (should be drag and drop)
*/
/* [Detail] */
//This setting controls the detail of your model. Keep it low until you have a design you are happy with!
RENDER = 12;	//[12:Low, 24:Medium, 48:High, 70:Max **very slow!**]

/* [Basic Settings] */
//How far back should the organizer go? (in)
Length = 8;	//[4:0.5:24]
//How wide is your drawer? (in)
Width = 14;		//[4:0.5:24]
//How deep should the slots be? (in)
Depth = 1.5;		//[1.25:0.25:6]
//How many slots do you need? 
SLOT_COUNT = 5;
//SLOT_OPTION = [0: SLOT_COUNT-1]; //Will be used in a future update!

/* [Advanced Settings] */
//How wide should the top brim be? (in)
Outer_Margin = 0.125;	//[0:None, 0.125:1/8 Inch, 0.25:1/4 Inch, 0.5:1/2 Inch]
//How thick should the walls between each slot be? (in)
Wall_Thickness = 0.125;	//[0.125:1/8 Inch, 0.1875:3/16 Inch, 0.25:1/4 Inch]
//How concave should the inside of the slot be?
Slot_Roundness = 10;	//[6:Small, 10:Normal, 14:Large, 18:Extreme]
//Make stackable?
Is_Stackable = false; 	//[true:Yes, false:No]

/* [Hidden] */
//Stacking logic
Top_Wall = (Is_Stackable?Depth-mm_in(Slot_Roundness) : 0.25);
//Convert inches to mm, like god intended
LENGTH = in_mm(Length);
WIDTH = in_mm(Width); //in_mm(Width);
DEPTH = in_mm(Depth);
SHELL_SLOT = in_mm(Wall_Thickness);
SHELL_TOP = in_mm(Top_Wall);
//Shorthand to access most commonly used user inputs
D = [LENGTH, WIDTH , DEPTH];
//Margin data and shorthand to access margin data
	MARGIN_0 = (Is_Stackable && Outer_Margin == 0?in_mm(0.125):in_mm(Outer_Margin));	//Outer margin, if enough room
	MARGIN_1 = SHELL_SLOT;	//Inner margin, if enough room
	MARGIN_2 = in_mm(0.125);	//Additional margin
M = [MARGIN_0,MARGIN_1,MARGIN_2];
//Fillet radius size for the slots
	FILLET_0 = in_mm(0.25);	//Outermost fillet
	FILLET_1 = Slot_Roundness;	//Slot fillet
	FILLET_2 = 0;	//Additional fillet, likely for edge breaking
F = [FILLET_0,FILLET_1,FILLET_2];
//Settings for Slot type #1
ARB_LENGTH = D[0]/2; 
ARB_DEPTH = D[2]/4;
ARB_FIL = F[0];
Fix_for_stack = F[1]>16?3.5:1;
$fn = RENDER;

/* [Hidden] */

//MAIN//
/******************************************************************************/
//Drop in the methods that need to be called and state machine/selection logic
module MAIN(){
	//Getters for the slod dimensions
	slot_width = get_slot_width();
	slot_length = get_slot_length();
	//Provide info on the slot dims
	echo(str("Slot Dimensions:    Width:",mm_in(slot_width))," in    Length:", mm_in(slot_length)," in");
	if(SLOT_COUNT > get_max_slots()){
		echo(str("With your current width, you can only fit ",get_max_slots()," slots!"));
	}
	else{
		difference(){
			for(i=[0:SLOT_COUNT-1]){
				//Generate every pocket based on user parameters
				translate([M[0] + i*(slot_width + M[1]), M[0],0]) make_pocket(X=slot_width + 2*SHELL_SLOT, Y= slot_length, Z=D[2]);
				//Add in the "wedges" between the corners of each pocket to make a clean surface
				if(i!=SLOT_COUNT-1){
					translate([(slot_width + M[1]) * (i+1) + SHELL_SLOT/2 + M[0],0,D[2] - SHELL_TOP]) make_triangular_fill();
				}
			}
			if(Is_Stackable){
				translate([M[0],M[0],D[2] - F[1] + Fix_for_stack]) make_spherized_box(X=D[1]-2*M[0], Y=D[0]-2*M[0],Z=D[2],fil = F[1]);
			}
		}
		if(M[0]!=0){
			// for(i=[0:SLOT_COUNT-1]){
			// 	translate([M[0] + i*(slot_width + M[1]) - SHELL_SLOT, M[0]-SHELL_SLOT,0]) make_pocket(X=slot_width + 2*SHELL_SLOT, Y= slot_length + 2*SHELL_SLOT, Z=D[2]);
			// }
			translate([0,0,D[2] -SHELL_TOP]) difference(){
				make_rounded_box();
				translate([M[0] ,M[0],-SHELL_TOP]) make_rounded_box(X=D[1] -2*M[0], Y=D[0] - 2*M[0], Z=4*SHELL_TOP, fil = F[1]);
			}
		}
	}
}

//FUNCTIONS//
/******************************************************************************/
//Inch to mm conversion; everyone in the US can think in inches, but openSCAD uses mm.
function in_mm(inch) = inch * 25.4; 
//mm to inch converter
function mm_in(mm) = mm / 25.4; 
//Calculates the appropriate width for each slot
function get_slot_width() = (D[1] - (SLOT_COUNT-1)*M[1] - 2*M[0] - 2*SHELL_SLOT)/SLOT_COUNT;
//Calculates the appropriate length for each slot
function get_slot_length() = D[0] -  2*M[0];
//Boolean: TRUE if the max # of slots was reached for the given width
function at_max_slots() = get_slot_width() <= 2*F[1]?true:false;
function get_max_slots() = floor((D[1] + M[1] - 2*(M[0] - SHELL_SLOT))/(2*F[1] + M[1]));
//METHODS//
/******************************************************************************/
//Generates the top face of the Drawer Organizer
module make_rounded_box(Y = -1, X = -1, Z = -1, fil = -1){
	//Set default values for inputs, good coding practice
	Y = Y==-1?D[0]:Y;
	X = X==-1?D[1]:X;
	Z = Z==-1?SHELL_TOP:Z;
	fil = fil==-1?F[0]:fil;
	ALPHA = 1.0;
	//Bulk of the surface, we will add in the fillet in a moment. This method is
	//less memory intense than a Minkowski() operation.
	translate([fil,fil,0]) color("green") cube([X-2*fil, Y-2*fil,Z]);
	//Fill in the space between the corner fillets
	translate([0,fil,0]) 	color("green", ALPHA) 	cube([fil,Y-2*fil,Z]);
	translate([fil,Y-fil,0]) color("green", ALPHA) 	cube([X-2*fil,fil,Z]);
	translate([X-fil,fil,0]) color("green", ALPHA) 	cube([fil,Y-2*fil,Z]);
	translate([fil,0,0])	color("green", ALPHA) 	cube([X-2*fil,fil,Z]);

	//Add in circles for outer fillet
	translate([fil,fil,0]) color("green", ALPHA) linear_extrude(Z) circle(r=fil);
	translate([fil,Y-fil,0]) color("green", ALPHA) linear_extrude(Z) circle(r=fil);
	translate([X-fil,Y-fil,0]) color("green", ALPHA) linear_extrude(Z) circle(r=fil);
	translate([X-fil,fil,0]) color("green", ALPHA) linear_extrude(Z) circle(r=fil);

}

module make_pocket_profile(Y = -1, X = -1, Z = -1, fil = -1){
	//Set default values for inputs, good coding practice
	Y = Y==-1?get_slot_length():Y;
	X = X==-1?get_slot_width():X;
	Z = Z==-1?SHELL_TOP*4:Z;
	fil = fil==-1?F[1]:fil;
	ALPHA = 1.0;
	//Make a rounded box to subtract from the top shell
	color("blue", ALPHA) make_rounded_box(X=X,Y=Y,Z=Z, fil=fil);
}

module make_pocket(Y = -1, X = -1, Z = -1, fil = -1){
	Y = Y==-1?get_slot_length():Y;
	X = X==-1?get_slot_width():X;
	Z = Z==-1?D[2] + SHELL_SLOT:Z;
	fil = fil==-1?F[1]:fil;
	ALPHA = 0.5;
	difference(){
		//Make the outer shell of the rounded box
		make_spherized_box(X=X,Y=Y,Z=Z-fil,fil=fil);
		//Make the cutting section
		if(M[0]!=0){
			translate([SHELL_SLOT,M[0],SHELL_SLOT]) make_spherized_box(X=X-2*SHELL_SLOT,Y=Y-2*M[0],Z=Z,fil=fil);
		}
		else{
			translate(SHELL_SLOT*[1,1,1]) make_spherized_box(X=X-2*SHELL_SLOT,Y=Y-2*SHELL_SLOT,Z=Z,fil=fil);
		}


	}
}

module make_spherized_box(Y = -1, X = -1, Z = -1, fil = -1){
	//render(){
	fil = fil==-1?F[1]:fil;
	Y = Y==-1?get_slot_length():Y;
	X = X==-1?get_slot_width():X;
	Z = Z==-1?D[2] - SHELL_SLOT - SHELL_TOP - fil:Z;
	ALPHA = 1;
	translate(fil*[0,0,1])color("green", ALPHA) make_rounded_box(X=X,Y=Y,Z=Z, fil=fil);
	translate(fil*[1,1,1]) color("orange", ALPHA) sphere(fil);
	translate([X-fil,fil,fil]) color("orange", ALPHA) sphere(fil);
	translate([fil,Y-fil,fil]) color("orange", ALPHA) sphere(fil);
	translate([X-fil,Y-fil,fil]) color("orange", ALPHA) sphere(fil);
	translate(fil*[1,1,1]) rotate(90*[0,1,0]) color("orange", ALPHA) cylinder(r=fil,h=X-2*fil);
	translate([fil,Y-fil,fil]) rotate(90*[0,1,0]) color("orange", ALPHA) cylinder(r=fil,h=X-2*fil);
	translate(fil*[1,1,1]) rotate(90*[-1,0,0]) color("orange", ALPHA) cylinder(r=fil,h=Y-2*fil);
	translate([X-fil,fil,fil]) rotate(90*[-1,0,0]) color("orange", ALPHA) cylinder(r=fil,h=Y-2*fil);
	translate(fil*[1,1,0]) color("orange", ALPHA) make_rounded_box(X=X-2*fil, Y=Y-2*fil, Z=fil,fil = 0);
	//}
}

module make_triangle(r = -1, h = -1){
	r = r==-1?F[1]:r;
	h = h==-1?SHELL_TOP:h;
	difference(){
		cube([2*r + M[1],r,h]);
		translate([2*r + M[1],r + M[0],-h]) color("green") linear_extrude(3*h) circle(r=r);
		translate([0,r + M[0],-h]) color("green") linear_extrude(3*h) circle(r=r);
	}
}

module make_triangular_fill(h = -1){
	x = get_slot_width();
	y = get_slot_length();
	r = F[1];
	h = h==-1?SHELL_TOP:h;
	translate([r + M[1]/2,y + M[0],0]) rotate([0,0,180]) make_triangle(r,h);
	translate([-r - M[1]/2,M[0],0])  make_triangle(r,h);
}

MAIN();