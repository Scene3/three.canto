/---------------------
 -- three_cameras.fun
 --
 -- Cameras for three.fun
 --
 -- Copyright (c) 2017 by Michael St. Hippolyte
 --
 --/
 
site three {


    /-- camera base class --/
    
    three_object camera {
        three_class = "Camera"
        
        keep: name = owner.type
        keep: position pos = position(0, 0, 0)
    }
    
    dynamic camera perspective_camera {
        three_class = "PerspectiveCamera"

        field(field_of_view) fov(field_of_view) [/]
        field(aspect_ratio)  aspect(aspect_ratio) [/]
        field(near_frame)    near(near_frame) [/]
        field(far_frame)     far(far_frame) [/]

        method update_projection_matrix {
            name = "updateProjectionMatrix"
        }

    }
    
    camera orthographic_camera {
        three_class = "OrthographicCamera"
    
    }
}
