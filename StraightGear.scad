include <StraightGearLib.scad>

$fn=200;

// ============
//  PARAMETERS
// ============

//module
m=5;
//Pressure angle
alpha=20;
//hole diameter
holeD=22.4;

//Number of teeth GEAR 1
nbDt1=22;

//Number of teeth GEAR2
nbDt2=11;

//% of one tooth rotation
pctDt=0.0;

gearPrm1 = gearPrm("1","lightblue",nbDt1,3*m,m,alpha,holeD);
gearPrm2 = gearPrm("2","lightgreen",nbDt2,3*m,m,alpha,holeD);

// gearPrm1[HOLED_PRM]=22.5;

r1=gearPrm1[R_PRM];
r2=gearPrm2[R_PRM];


rotate([0,0,rotation(pctDt,gearPrm1)])
gear(gearPrm1);


translate([r1+r2,0,])
rotate([0,0,rotation(pctDt,gearPrm2,true)])
gear(gearPrm2);

function rotation(pctDt,gearPrm,inv=false)=((inv?-1:1)*360/gearPrm[NBTOOTH_PRM]*pctDt)-(m/4/(2*gearPrm[R_PRM])*360+gearPrm[PTDEG_PRM]);


echo(r12=r1+r2);
echo(holeR=holeD/2);
echo(minrs=2/7*(r1-holeD/2)+holeD/2);

//cylinder(d=22,h=3*m);

module pole(){
	difference(){
		union(){
			cylinder(h=6+15+7,d=8);
			cylinder(h=6,d=12);
			translate([0,0,-7])cylinder(h=10,d=22);
		}
		cylinder(h=30,d=2.5,center=true);
	}
}

*translate([83/2,0,0]){
	difference(){
		union(){
			translate([-83/2,0,0])pole();
			translate([-83/2,-11,-7])cube([83,22,10]);
			translate([83/2,0,0])pole();
		}
		translate([-25,10,-2])rotate([0,90,0])cylinder(d=7,h=50);
		translate([-25,-10,-2])rotate([0,90,0])cylinder(d=7,h=50);
	}
}