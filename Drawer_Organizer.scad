/*
*DEVELOPER: 	Dasan Costandi
*SUMMARY:		Script to generate simple, printable organizers for a drawer.
*USER INPUT:	- Dimensions of Drawer
*				- Number of slots to include
*				- Depth of slots
*				- Slot Style (should be drag and drop)
*/

//USER INPUTS//
/******************************************************************************/
LENGTH = in_mm(10);
WIDTH = in_mm(18);
DEPTH = in_mm(2);
SLOT_TYPE = 0;
SLOT_COUNT = 6;

//PROCESS VARIABLES//
/******************************************************************************/
//Inch to mm conversion, for preference
function in_mm(inch) = inch * 25.4; 
//Shorthand to access most commonly used user inputs
D = [WIDTH, LENGTH, DEPTH];
//Thickness of object shell
SHELL_SLOT = 4;
SHELL_TOP = 2;
//Margin data and shorthand to access margin data
	MARGIN_0 = 5;	//Outer margin, if enough room
	MARGIN_1 = 1;	//Inner margin, if enough room
	MARGIN_2 = 5;	//Additional margin
M = MARGIN_1<=SHELL_SLOT?[MARGIN_0,SHELL_SLOT,MARGIN_2]:[MARGIN_0,MARGIN_1,MARGIN_2];
//Fillet radius size for the slots
	FILLET_0 = 10;	//Outermost fillet
	FILLET_1 = 10;	//Slot fillet
	FILLET_2 = 0;	//Additional fillet, likely for edge breaking
F = [FILLET_0,FILLET_1,FILLET_2];
//Settings for Slot type #1
ARB_LENGTH = LENGTH/2; 
ARB_DEPTH = DEPTH/4;
ARB_FIL = F[0];
$fn = 20;


//MAIN//
/******************************************************************************/
//Drop in the methods that need to be called and state machine/selection logic
module MAIN(){
	slot_width = get_slot_width();
	slot_length = get_slot_length();
	if(at_max_slots()){
		echo("Make your drawer width larger to include more slots!" );
	}
	else if(SLOT_TYPE==0){
		for(i=[0:SLOT_COUNT-1]){
			translate([M[0] + i*(slot_width + M[1]) - SHELL_SLOT, M[0]-SHELL_SLOT,0]) make_pocket(X=slot_width + 2*SHELL_SLOT, Y= slot_length + 2*SHELL_SLOT);
		}
		translate([0,0,DEPTH + SHELL_SLOT]) difference(){
			make_rounded_box();
			for(i=[0:SLOT_COUNT-1]){
				translate([M[0] + i*(slot_width + M[1]),M[0],-SHELL_TOP]) make_pocket_profile();
			}
		}
	}
	else if(SLOT_TYPE == 1){
		difference(){
			union(){
				for(i=[0:SLOT_COUNT-1]){
					translate([M[0] + i*(slot_width + M[1]) - SHELL_SLOT, M[0]-SHELL_SLOT,0]) make_pocket(X=slot_width + 2*SHELL_SLOT, Y= slot_length + 2*SHELL_SLOT);
				}
				translate([0,0,DEPTH + SHELL_SLOT]) difference(){
					make_rounded_box();
					for(i=[0:SLOT_COUNT-1]){
						translate([M[0] + i*(slot_width + M[1]),M[0],-SHELL_TOP]) make_pocket_profile();
					}
				}
			}
			translate([2*M[0],ARB_LENGTH/2,DEPTH + SHELL_SLOT+ SHELL_TOP - ARB_DEPTH]) make_spherized_box(X=WIDTH - 4*M[0], Y=ARB_LENGTH, Z=ARB_DEPTH, fil = ARB_FIL);
		}
	}
}


//METHODS//
/******************************************************************************/
//Generates the top face of the Drawer Organizer
module make_rounded_box(Y = -1, X = -1, Z = -1, fil = -1){
	//Set default values for inputs, good coding practice
	Y = Y==-1?LENGTH:Y;
	X = X==-1?WIDTH:X;
	Z = Z==-1?SHELL_TOP:Z;
	fil = fil==-1?F[0]:fil;
	ALPHA = 1.0;
	//Bulk of the surface, we will add in the fillet in a moment. This method is
	//less memory intense than a Minkowski() operation.
	translate([fil,fil,0]) color("Red") cube([X-2*fil, Y-2*fil,Z]);
	//Fill in the space between the corner fillets
	translate([0,fil,0]) 	color("Red", ALPHA) 	cube([fil,Y-2*fil,Z]);
	translate([fil,Y-fil,0]) color("Red", ALPHA) 	cube([X-2*fil,fil,Z]);
	translate([X-fil,fil,0]) color("Red", ALPHA) 	cube([fil,Y-2*fil,Z]);
	translate([fil,0,0])	color("Red", ALPHA) 	cube([X-2*fil,fil,Z]);

	//Add in circles for outer fillet
	translate([fil,fil,0]) color("Red", ALPHA) linear_extrude(Z) circle(r=fil);
	translate([fil,Y-fil,0]) color("Red", ALPHA) linear_extrude(Z) circle(r=fil);
	translate([X-fil,Y-fil,0]) color("Red", ALPHA) linear_extrude(Z) circle(r=fil);
	translate([X-fil,fil,0]) color("Red", ALPHA) linear_extrude(Z) circle(r=fil);

}

module make_pocket_profile(Y = -1, X = -1, Z = -1, fil = -1){
	//Set default values for inputs, good coding practice
	Y = Y==-1?get_slot_length():Y;
	X = X==-1?get_slot_width():X;
	Z = Z==-1?SHELL_TOP*3:Z;
	fil = fil==-1?F[1]:fil;
	ALPHA = 1.0;
	//Make a rounded box to subtract from the top shell
	color("blue", ALPHA) make_rounded_box(X=X,Y=Y,Z=Z, fil=fil);
}

module make_pocket(Y = -1, X = -1, Z = -1, fil = -1){
	Y = Y==-1?get_slot_length():Y;
	X = X==-1?get_slot_width():X;
	Z = Z==-1?DEPTH + SHELL_SLOT:Z;
	fil = fil==-1?F[1]:fil;
	ALPHA = 0.5;
	difference(){
		//Make the outer shell of the rounded box
		make_spherized_box(X=X,Y=Y,Z=Z-fil,fil=fil);
		//Make the cutting section
		translate([SHELL_SLOT,SHELL_SLOT,SHELL_SLOT]) make_spherized_box(X=X-2*SHELL_SLOT,Y=Y-2*SHELL_SLOT,Z=Z,fil=fil);
	}
}

module make_spherized_box(Y = -1, X = -1, Z = -1, fil = -1){
	render(){
	fil = fil==-1?F[1]:fil;
	Y = Y==-1?get_slot_length():Y;
	X = X==-1?get_slot_width():X;
	Z = Z==-1?DEPTH - SHELL_SLOT - SHELL_TOP - fil:Z;
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
	}
}

function get_slot_width() = (WIDTH - (SLOT_COUNT-1)*M[1] - 2*M[0])/SLOT_COUNT;
function get_slot_length() = LENGTH -  2*M[0];
function at_max_slots() = get_slot_width() <= 2*F[1]?true:false;

MAIN();