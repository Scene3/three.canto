/---------------------
 -- three_objects.fun
 --
 -- Full-fledged general objects for three.fun
 --
 -- Copyright (c) 2017 by Michael St. Hippolyte
 --
 --/
 
site three {

    /---- background objects ----/

    dynamic synthetic_object backdrop {
        geometry geo = sphere_geometry(horizon, seg_width, seg_height)
        material mat = basic_material
        name = owner.type
        
        /-- default distance to horizon -- one kilometer  --/
        int horizon = 1000
        int seg_width = 100
        int seg_height = 100
        
        decl [/
            var {= name; =} = new THREE.Mesh( {= geo.construct; =}, {= mat.construct; =} ); 
            {= name; =}.scale.x = -1;
        /]
    }

        
    three_object ambience {
        light lt [?]
        backdrop bd [/]
        
        three_object[] objs = [ with (lt) { lt }, if (bd) { bd } ]

    }


    /---- very simple objects ----/

 
}
