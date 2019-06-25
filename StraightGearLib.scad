
//Parameters INDEXES
G_NB_TEETH   =  0;
G_MODULE     =  1; // Distance between teeth (mm)
G_STEP       =  2; // Distance between teeth (degree)
G_ALPHA      =  3; // Pressure angle
G_RPITCH     =  4; // Radius of Pitch circle
G_RBOT       =  5; // Radius of Bottom circle
G_RTOP       =  6; // Radius of Top circle
G_RBASE      =  7; // Radius of Base circle
G_PHI_T      =  8; // Tooth width (degree) from base circle to base circle
G_THETA_H    =  9;
G_CTBEVEL    = 10; // Center of Top bevel circle, contains radius, start angle, end angle
G_CBBEVEL    = 11; // Center of Bottom bevel circle, contains radius, start angle, end angle

G_HEIGHT     = 12; // Gear thickness
G_HOLED      = 13; // Center hole diameter

// point2D([x,y,z]) => [x,y]
function point2D(point3D)=[point3D[0],point3D[1]];
// flatten([[0,1],[2,3]]) => [0,1,2,3]
function flatten(list) = [ for (i = list, v = i) v ];
// Rotate 3D point around z axis
function zRotateCoord ( coordXYZ, angle ) = [
	 coordXYZ[0] * cos(angle) + coordXYZ[1] * sin(angle),
	-coordXYZ[0] * sin(angle) + coordXYZ[1] * cos(angle),
	 coordXYZ[2]
];
// Apply a translation on a 2D or 3D point
function transformCoord(coord,transform) = [
	for(i=[0:2])
		(coord[i] + transform[i])
];

// Ratio of m for of Top and Bottom radius
RTD = 1.0;
RFD = 1.2;

// z:     Number of teeth on the gear
// m:     Module of the gear: distance between 2 teeth on Pitch circle
// alpha: Pressure angle from tangent on Pitch circle at Phi=0
// bevel: Bevel circles radiu as a ration of m
function gearPrm2D ( z, m, alpha=20, bevel=0.2 )=
let(
    // T is a point on Base circle, its position is given by angle Theta
    // M is a point on Involute curve following T, its position is given by angle Phi

    // Bevel radius
    Rv     = bevel*m,
    // Pitch radius: radius of Pitch circle where tooth width equals tooth interval
    Rp = m*z/2,
    // Base radius: radius of Base circle (for T point) where involute curves starts
    Rb = Rp*cos(alpha),
    // Floor radius: radius of Bottom circle: bottom of gear teeth
    Rf = min(Rb-Rv, Rp -RFD*m -Rv ),
    // Top Radius: radius of Top circle: top of gear teeth
    Rt = Rp +RTD*m,
    // Angle (radian) of point T for which involute cross Top circle
    ThetaH = sqrt( (pow(Rt,2)/pow(Rb,2)) - 1 ),
    // Angle (radian) of point T for which involute cross Pitch circle
    ThetaP = sqrt( (pow(Rp,2)/pow(Rb,2)) - 1 ),
    // Angle (degree) of point M when T is at ThetaP hence the point where involute crosses Pitch circle
    PhiP   = (180/PI)*ThetaP-atan(ThetaP),
    // Angle (degree) of CBB on its Bottom bevel circle
    PhiBB  = - (180/PI)*Rv/(Rf+Rv),
    // Total width (degree) of a tooth from base circle to base circle
    PhiT   = 2*PhiP + 180/z,
    // Step = Circular pitch: Distance between 2 teeth (degree)
    Step   = 360/z,

    // Point at the end of involute (on Top circle)
    H      = involute(Rb,ThetaH),
    // PH: Perpendicular of involute curve at H: y = PHa.x + PHb
    PHa    = -1/(tan( (180/PI)*ThetaH) ),
    PHb    = H[1]+H[0]/(tan( (180/PI)*ThetaH) ),
    // CTB(Cx,Cy): Center of top bevel circle (placed on PH)
    Cx     = H[0] - Rv/sqrt(1+pow(PHa,2)),
    Cy     = PHa*Cx + PHb,
    CTB    = [ Cx, Cy, 0, Rv, atan( (H[1]-Cy)/(H[0]-Cx) ), atan(Cy/Cx) ],
    CBB    = [ (Rf+Rv)*cos(PhiBB), (Rf+Rv)*sin(PhiBB), 0, Rv, PhiBB ]
)[ z,m,Step,alpha,Rp,Rf,Rt,Rb,PhiT,ThetaH,CTB,CBB ];

// 2D parameters +
//   name:  Gear name
//   c:     Color name
//   h:     Thickness of the gear, only used for 3D gears
//   holeD: Center hole diameter, only used with lightWeightGear
function gearPrm3D ( z, h, m, alpha, holeD, bevel=0 )=
    flatten( [ gearPrm2D(z,m,alpha,bevel), [h, holeD] ] );


// Involute curve starting on base circle from involution angle
function involute (Rb,theta)= let(a=theta*180/PI) [
    Rb*(cos(a)+theta*sin(a)),
    Rb*(sin(a)-theta*cos(a)),
    0
];
// Point on a circle at specified angle (degree)
function arc (C,R,angle) = [
    C[0] + R*cos(angle),
    C[1] + R*sin(angle),
    0
];

function halfTooth(g) = flatten( let( Rf=g[G_RBOT],Rb=g[G_RBASE],ThetaH=g[G_THETA_H],PhiT=g[G_PHI_T],PhiB=(PhiT-g[G_STEP])/2,CTB=g[G_CTBEVEL],CBB=g[G_CBBEVEL],Rt=sqrt(pow(CTB[0],2)+pow(CTB[1],2))+CTB[3] ) [
    [ // Bottom circle arc
        for ( i=[PhiB:+360/$fn:CBB[4]] )
            arc ( [0,0,0], Rf, i )
    ],
    [ // Bottom bevel
        if ( CBB[4]<0 )
            for ( i=[180+CBB[4]:-360/$fn:90+CBB[4]] )
                arc ( CBB, CBB[3], i )
    ],
    [ // Involute curve
        for ( i=[0:5/$fn:ThetaH] )
            involute(Rb,i)
    ],
    [ // Top bevel
        for ( i=[CTB[4]:360/$fn:CTB[5]] )
            arc ( CTB, CTB[3], i )
    ],
    [ // Top circle arc
        for ( i=[CTB[5]:-360/$fn:PhiT/2] )
            arc ( [0,0,0], Rt, i )
    ]
]);

function oneTooth(g) = flatten( let( PhiT=g[G_PHI_T], halfPoints=halfTooth(g) ) [
    [ // First tooth half
        for( i=[0 : +1 : len(halfPoints)-1] )
            zRotateCoord ( [halfPoints[i][0],+halfPoints[i][1],0], 0 )
    ],
    [ // For second half we browser points in reverse order
        for( i=[len(halfPoints)-1 : -1 : 0] )
            zRotateCoord ( [halfPoints[i][0],-halfPoints[i][1],0], -PhiT )
    ]
]);

function allTooth(g)=flatten( let( z=g[G_NB_TEETH],step=g[G_STEP],Rf=g[G_RBOT],PhiT=g[G_PHI_T],PhiB=(PhiT-g[G_STEP])/2,PhiAlign=(360-floor(z)*step)/2,PhiE=floor(z)*359/z, toothPoints=oneTooth(g) ) [
    [
        for(i=[0:360/z:PhiE])
            for(pt=toothPoints) zRotateCoord(pt,-i +PhiT/2 - PhiAlign)
    ],
    [ // Fill bottom circle in case z is not an integer
        for(i=[PhiE+PhiB+360/$fn:360/$fn:360+PhiB-360/$fn])
            arc ( [0,0,0], Rf, i )
    ]
]);

module gear2D ( params2D ){
    // debug
    // point3Ds = halfTooth( params2D );
    // point3Ds = oneTooth( params2D );

    point3Ds = allTooth( params2D );
    points = [ for(pt=point3Ds) point2D(pt) ];
    polygon(points);

    // debug
    // echo( "NB Points in gear: ", len(points) );
	// for(i=[0:len(points)])translate(points[i])cube(.05,center=true);
}

module gear3D ( params3D ){
    linear_extrude(height=params3D[G_HEIGHT],convexity=15)
    gear2D(params3D);
}

module lightWeightGear3D ( params3D ){
	// echo(str("Gear radius is ",params3D[G_RPITCH]));

	baseR = params3D[G_RPITCH] - 1.25*params3D[G_MODULE];

	difference(){
        gear3D(params3D);
		cylinder(h=3*params3D[G_HEIGHT],d=params3D[G_HOLED],center=true);
		for(i=[0:120:240])
		rotate([0,0,i])
		translate([0,0,-1])
		beanShape(45,
			1/7*(baseR-params3D[G_HOLED]/2)+params3D[G_HOLED]/2,
			5/7*(baseR-params3D[G_HOLED]/2)+params3D[G_HOLED]/2,
			params3D[G_HEIGHT]*3);
        // debug
		// #translate([0,0,params3D[G_HEIGHT]])	scale([1,1,params3D[G_HEIGHT]/28])sphere(r=6/7*baseR);
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
