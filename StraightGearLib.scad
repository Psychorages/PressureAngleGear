include <..\..\UTILZ\utilz.scad>

//Parameters INDEXES
NAME_PRM	=0;
COLOR_PRM	=1;
NBTOOTH_PRM	=2;
H_PRM		=3;
MODULE_PRM	=4;
ALPHA_PRM	=5;
HOLED_PRM	=6;
R_PRM		=7;
HEADT_PRM	=8;
PTDEG_PRM	=9;

function point2D(point3D)=[point3D[0],point3D[1]];

// axes hole diameter
defaultHoleD = 5;

function gearPrm(name,c,nbDt,h,m,alpha,holeD)=
let(
	//radius
	r=m*nbDt/2,
	//Foot radius
	fR= r -1.25*m,
	//Module :
	// m=(r-fR)/1.25,
	//Head Radius
	hR= r + m,
	//baseR (radius where start the developpante)
	bR=r*cos(alpha),
	// t angle where developpante cross circle having hR radius
	hT = sqrt( (pow(hR,2)/pow(bR,2)) - 1 ),
	// t angle where developpante cross circle having hR radius
	bT = sqrt( (pow(hR,2)/pow(fR,2)) - 1 ),

	// t angle where developpante cross circle having r radius (primitive)
	pT = sqrt( (pow(r,2)/pow(bR,2)) - 1 ),
	// angle beetween first point of developpante, and it point on primitive radius
	pTDeg=(pT*180/PI)-atan(pT)
)
[
	name,c,nbDt,h,m,alpha,holeD,r,hT,pTDeg
];


//developpante
function developpante(t,r)=
let(a=t*180/PI)
[
	r*(cos(a)+t*sin(a)),
	r*(sin(a)-t*cos(a)),
	0
];

function oneTooth(m,hT,r,pTDeg,alpha) = flatten(
	[
		[[r -1.25*m,0]],
		[for(i=[0:hT/$fn*5:hT])	developpante(i,r*cos(alpha))],
		[for(i=[hT:-hT/$fn*5:0])	zRotateCoord(developpante(-i,r*cos(alpha)),-2*pTDeg-(360*(PI*m/2)/(2*PI*r)))],
		[zRotateCoord([r -1.25*m,0],-2*pTDeg-(360*(PI*m/2)/(2*PI*r)))],
	]
);

function allTooth(m,hT,r,nbDt,hTDeg,alpha)=flatten(
[
	for(i=[0:360/nbDt:359])
	[
		for(pt=oneTooth(m,hT,r,hTDeg,alpha))point2D(zRotateCoord(pt,-i))
	]
]
);

module gear(gearprm){
	points=allTooth(
			gearprm[MODULE_PRM],
			gearprm[HEADT_PRM],
			gearprm[R_PRM],
			gearprm[NBTOOTH_PRM],
			gearprm[PTDEG_PRM],
			gearprm[ALPHA_PRM]);
			
	echo(str("Gear",gearprm[NAME_PRM]," radius is ",gearprm[R_PRM]));
	
	baseR = gearprm[R_PRM] - 1.25*gearprm[MODULE_PRM];
	
	// for(i=[0:len(points)])translate(points[i])cube(.05,center=true);
	
	color(gearprm[COLOR_PRM])
	difference(){
		linear_extrude(height=gearprm[H_PRM],convexity=15)
		polygon(points);
		cylinder(h=3*gearprm[H_PRM],d=gearprm[HOLED_PRM],center=true);
		for(i=[0:120:240])
		rotate([0,0,i])
		translate([0,0,-1])
		beanShape(45,
			1/7*(baseR-gearprm[HOLED_PRM]/2)+gearprm[HOLED_PRM]/2,
			5/7*(baseR-gearprm[HOLED_PRM]/2)+gearprm[HOLED_PRM]/2,
			gearprm[H_PRM]*3);
		// #translate([0,0,gearprm[H_PRM]])	scale([1,1,gearprm[H_PRM]/28])sphere(r=6/7*baseR);
	}
	
}

module emptyCircle(r,h=1){
	difference(){
		cylinder(r=r,h=h,center=true);
		cylinder(r=r*.999,h=h*1.01,center=true);
	}
}


function beanShapeCoord(beanAngle,beanMinR,beanMaxR)=flatten(
	[
		[
			for(i=[0:100/$fn:180])
			let(r=(beanMaxR-beanMinR)/2)
			point2D(transformCoord([r*cos(i),r*sin(i),0],[r+beanMinR,0,0]))
		],
		[
			for(i=[0:-100/$fn:-beanAngle])
			point2D([beanMinR*cos(i),beanMinR*sin(i),0])		
		],
		[
			for(i=[180:100/$fn:360])
			let(r=(beanMaxR-beanMinR)/2)
			point2D(zRotateCoord(transformCoord([r*cos(i),r*sin(i),0],[r+beanMinR,0,0]),beanAngle))
		],
		[
			for(i=[-beanAngle:100/$fn:0])
			point2D([beanMaxR*cos(i),beanMaxR*sin(i),0])		
		],
	]
);


module  beanShape(beanAngle,beanMinR,beanMaxR,h){
	linear_extrude(height=h)
	polygon(beanShapeCoord(beanAngle,beanMinR,beanMaxR));
}



