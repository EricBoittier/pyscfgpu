#version 3.6;
#include "colors.inc"
#include "finish.inc"

global_settings {assumed_gamma 2.2 max_trace_level 6}
background {color White transmit 1.0}
camera {orthographic angle 0
  right -7.32*x up 3.18*y
  direction 50.00*z
  location <0,0,50.00> look_at <0,0,0>}


light_source {<  2.00,   3.00,  40.00> color White
  area_light <0.70, 0, 0>, <0, 0.70, 0>, 3, 3
  adaptive 1 jitter}
// no fog
#declare simple = finish {phong 0.7 ambient 0.4 diffuse 0.55}
#declare pale = finish {ambient 0.9 diffuse 0.30 roughness 0.001 specular 0.2 }
#declare intermediate = finish {ambient 0.4 diffuse 0.6 specular 0.1 roughness 0.04}
#declare vmd = finish {ambient 0.2 diffuse 0.80 phong 0.25 phong_size 10.0 specular 0.2 roughness 0.1}
#declare jmol = finish {ambient 0.4 diffuse 0.6 specular 1 roughness 0.001 metallic}
#declare ase2 = finish {ambient 0.2 brilliance 3 diffuse 0.6 metallic specular 0.7 roughness 0.04 reflection 0.15}
#declare ase3 = finish {ambient 0.4 brilliance 2 diffuse 0.6 metallic specular 1.0 roughness 0.001 reflection 0.0}
#declare glass = finish {ambient 0.4 diffuse 0.35 specular 1.0 roughness 0.001}
#declare glass2 = finish {ambient 0.3 diffuse 0.3 specular 1.0 reflection 0.25 roughness 0.001}
#declare Rcell = 0.050;
#declare Rbond = 0.100;

#macro atom(LOC, R, COL, TRANS, FIN)
  sphere{LOC, R texture{pigment{color COL transmit TRANS} finish{FIN}}}
#end
#macro constrain(LOC, R, COL, TRANS FIN)
union{torus{R, Rcell rotate 45*z texture{pigment{color COL transmit TRANS} finish{FIN}}}
     torus{R, Rcell rotate -45*z texture{pigment{color COL transmit TRANS} finish{FIN}}}
     translate LOC}
#end

// no cell vertices
atom(< -2.46,   0.06,  -1.56>, 0.17, rgb <0.94, 0.04, 0.04>, 0.0, jmol) // #0
atom(< -3.41,  -0.08,   0.00>, 0.08, rgb <0.91, 0.81, 0.79>, 0.0, jmol) // #1
atom(< -0.71,  -0.01,  -0.97>, 0.08, rgb <0.91, 0.81, 0.79>, 0.0, jmol) // #2
atom(<  2.76,  -0.04,  -0.03>, 0.17, rgb <0.94, 0.04, 0.04>, 0.0, jmol) // #3
atom(<  3.36,   1.44,  -0.94>, 0.08, rgb <0.91, 0.81, 0.79>, 0.0, jmol) // #4
atom(<  3.41,  -1.44,  -1.03>, 0.08, rgb <0.91, 0.81, 0.79>, 0.0, jmol) // #5
cylinder {< -2.46,   0.06,  -1.56>, < -2.93,  -0.01,  -0.78>, Rbond texture{pigment {color rgb <0.94, 0.04, 0.04> transmit 0.0} finish{jmol}}}
cylinder {< -3.41,  -0.08,   0.00>, < -2.93,  -0.01,  -0.78>, Rbond texture{pigment {color rgb <0.91, 0.81, 0.79> transmit 0.0} finish{jmol}}}
cylinder {< -2.46,   0.06,  -1.56>, < -1.59,   0.02,  -1.26>, Rbond texture{pigment {color rgb <0.94, 0.04, 0.04> transmit 0.0} finish{jmol}}}
cylinder {< -0.71,  -0.01,  -0.97>, < -1.59,   0.02,  -1.26>, Rbond texture{pigment {color rgb <0.91, 0.81, 0.79> transmit 0.0} finish{jmol}}}
cylinder {<  2.76,  -0.04,  -0.03>, <  3.06,   0.70,  -0.49>, Rbond texture{pigment {color rgb <0.94, 0.04, 0.04> transmit 0.0} finish{jmol}}}
cylinder {<  3.36,   1.44,  -0.94>, <  3.06,   0.70,  -0.49>, Rbond texture{pigment {color rgb <0.91, 0.81, 0.79> transmit 0.0} finish{jmol}}}
cylinder {<  2.76,  -0.04,  -0.03>, <  3.08,  -0.74,  -0.53>, Rbond texture{pigment {color rgb <0.94, 0.04, 0.04> transmit 0.0} finish{jmol}}}
cylinder {<  3.41,  -1.44,  -1.03>, <  3.08,  -0.74,  -0.53>, Rbond texture{pigment {color rgb <0.91, 0.81, 0.79> transmit 0.0} finish{jmol}}}
// no constraints
// Vectors (as arrows)
#macro Arrow(Start, End, Thickness, HeadSize)
    union {
        // Shaft
        cylinder {
            Start,
            End - HeadSize * normalize(End - Start),
            Thickness
        }
        // Arrow head
        cone {
            End - HeadSize * normalize(End - Start),
            Thickness * 2,
            End,
            0
        }
        pigment { color Red }
    }
#end

// Plane (as a finite rectangle)
#macro Plane(Center, Normal, Width, Height)
    plane {
        Normal, 0
        translate Center
        clipped_by {
            box {
                Center - <Width/2, Height/2, Width/2>,
                Center + <Width/2, Height/2, Width/2>
            }
        }
        pigment { color Blue alpha 0.5 }
    }
#end

// Angle marker (as an arc)
#macro AngleMarker(Vertex, Point1, Point2, Radius)
    union {
        // Arc
        difference {
            torus {
                Radius,
                0.1
                rotate about_vector(Point1 - Vertex, Point2 - Vertex)
            }
            box {
                <-Radius, -Radius, -Radius>,
                <Radius, 0, Radius>
            }
        }
        pigment { color Green }
    }
#end

// Dihedral angle visualization
#macro DihedralAngle(P1, P2, P3, P4)
    union {
        // First plane
        Plane(P2, vcross(P1-P2, P3-P2), 2, 2)
        // Second plane
        Plane(P3, vcross(P2-P3, P4-P3), 2, 2)
        pigment { color Yellow alpha 0.3 }
    }
#end

// Example usage
#declare Vec1_Start = <0, 0, 0>;
#declare Vec1_End = <1, 1, 0>;
Arrow(Vec1_Start, Vec1_End, 0.05, 0.2)

#declare PlaneCenter = <0, 0, 0>;
#declare PlaneNormal = <0, 1, 0>;
Plane(PlaneCenter, PlaneNormal, 2, 2)

#declare Angle_Vertex = <0, 0, 0>;
#declare Angle_Point1 = <1, 0, 0>;
#declare Angle_Point2 = <0, 1, 0>;
AngleMarker(Angle_Vertex, Angle_Point1, Angle_Point2, 0.5)
