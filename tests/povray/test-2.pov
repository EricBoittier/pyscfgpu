#include "colors.inc"
#include "textures.inc"
#include "math.inc"

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
                <-Radius, -Radius, -Radius>,
                <Radius, 0, Radius>
            }
        }
        pigment { color Black }
    }
#end


#macro DihedralAngle(P1, P2, P3, P4, Size)
    union {
        // Intersection line (P2-P3)
        cylinder {
            P2,
            P3,
            0.03
            pigment { color Red }
        }
        
        // First plane
        intersection {
            plane {
                vnormalize(vcross(P1-P2, P3-P2)), 0
                translate P2
            }
            box {
                P2 - <Size, Size, Size>,
                P2 + <Size, Size, Size>
            }
            pigment { color Blue transmit 0.7 }
        }
        
        // Second plane
        intersection {
            plane {
                vnormalize(vcross(P2-P3, P4-P3)), 0
                translate P3
            }
            box {
                P3 - <Size, Size, Size>,
                P3 + <Size, Size, Size>
            }
            pigment { color Green transmit 0.7 }
        }
        
        // Optional: Add small spheres at the points for clarity
        sphere { P1, 0.05 pigment { color Red } }
        sphere { P2, 0.05 pigment { color Red } }
        sphere { P3, 0.05 pigment { color Red } }
        sphere { P4, 0.05 pigment { color Red } }
    }
#end

// Example usage with realistic molecular geometry
#declare P1 = <0, 1, 0.6>;    // First atom
#declare P2 = <0, 0.1, 0>;    // Second atom (axis start)
#declare P3 = <1, 0, 0>;    // Third atom (axis end)
#declare P4 = <1, 0.6, 1>;    // Fourth atom

DihedralAngle(P1, P2, P3, P4, 1.0)

// Add coordinate axes for reference
Arrow(<0,0,0>, <2,0,0>, 0.02, 0.1)  // X-axis
Arrow(<0,0,0>, <0,2,0>, 0.02, 0.1)  // Y-axis
Arrow(<0,0,0>, <0,0,2>, 0.02, 0.1)  // Z-axis