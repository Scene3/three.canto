/---------------------
 -- three_geometries.fun
 --
 -- Geometries for three.fun
 --
 -- Copyright (c) 2017 by Michael St. Hippolyte
 --
 --/
 
site three {


    /---- geometry base class ----/
        
    three_object geometry {
        three_class = "Geometry"
        position pos = position(0, 0, 0)
        options{} = {}
    }
    
    /---- geometries ----/
    
    geometry cube_geometry(float width, float height, float depth),
                          (float width, float height, float depth, int seg_width, int seg_height, int seg_depth) {
                          
        three_class = "CubeGeometry"

        args[] = [ width, height, depth,
                   with (seg_width) { seg_width, seg_height, seg_depth }
                 ]  

    }                          

    geometry box_geometry(float width, float height, float depth),
                         (float width, float height, float depth, int seg_width, int seg_height, int seg_depth) {
                          
        three_class = "BoxGeometry"

        args[] = [ width, height, depth,
                   with (seg_width) { seg_width, seg_height, seg_depth }
                 ]  

    }                          

    geometry sphere_geometry(float radius),
                            (float radius, int seg_width, int seg_height),
                            (float radius, int seg_width, int seg_height, float phi_start, float phi_length, float theta_start, float theta_length) {
                            
        three_class = "SphereGeometry"
                            
        args[] = [ radius,
                   with (seg_width) { seg_width, seg_height },
                   with (phi_start) { phi_start, phi_length, theta_start, theta_length }
                 ]  
    }
    
    geometry text_geometry(text) {
    
    
    }
    
        
}
