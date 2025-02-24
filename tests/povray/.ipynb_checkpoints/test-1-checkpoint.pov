#include "colors.inc"
#include "textures.inc"
#include "math.inc"

// Camera setup
camera {
    location <3, 4, -5>
    look_at <0, 0, 0>
}

// Light source
light_source {
    <10, 10, -10>
    color White
}

// Background
background { color White }

// Vectors (as arrows)
#macro Arrow(Start, End, Thickness, HeadSize)
    union {
        // Shaft
        cylinder {
            Start,
            End - HeadSize * vnormalize(End - Start),
            Thickness
        }
        // Arrow head
        cone {
            End - HeadSize * vnormalize(End - Start),
            Thickness * 2,
            End,
            0
        }
        pigment { color Red }
    }
#end

// Plane (as a finite rectangle)
#macro Plane(Center, Normal, Width, Height)
    intersection {
        plane {
            Normal, 0
            translate Center
        }
        box {
            Center - <Width/2, Height/2, Width/2>,
            Center + <Width/2, Height/2, Width/2>
        }
        pigment { color Blue transmit 0.5 }
    }
#end

// Angle marker (as an arc)
#macro AngleMarker(Vertex, Point1, Point2, Radius)
    union {
        difference {
            torus {
                Radius, 0.02
                rotate z*degrees(atan2(vdot(Point1 - Vertex, <1,0,0>), 
                                    vdot(Point1 - Vertex, <0,1,0>)))
            }
            box {
                Point1,
                Point2
            }
        }
        pigment { color Black }
    }
#end

// Dihedral angle visualization
#macro DihedralAngle(P1, P2, P3, P4)
    union {
        // First plane
        Plane(P2, vcross(P1-P2, P3-P2), 2, 2)
        // Second plane
        Plane(P3, vcross(P2-P3, P4-P3), 2, 2)
        pigment { color Yellow transmit 1.0 }
    }
#end

// Example usage

#declare Angle_Vertex = <0, 0, 0>;
#declare Angle_Point1 = <1, 0, 0>;
#declare Angle_Point2 = <0, 1, 0>;
AngleMarker(Angle_Vertex, Angle_Point1, Angle_Point2, 0.5)  // Added missing Radius parameter

// Add coordinate axes for reference
Arrow(<0,0,0>, <2,0,0>, 0.02, 0.1)  // X-axis
Arrow(<0,0,0>, <0,2,0>, 0.02, 0.1)  // Y-axis
Arrow(<0,0,0>, <0,0,2>, 0.02, 0.1)  // Z-axis

#declare PlaneCenter = <0, 0, 0>;
#declare PlaneNormal = <0, 1, 0>;
Plane(PlaneCenter, PlaneNormal, 2, 0.1)
