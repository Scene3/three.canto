/---------------------
 -- three_materials.fun
 --
 -- Materials for three.fun
 --
 -- Copyright (c) 20174 by Michael St. Hippolyte
 --
 --/
 
site three {


    /---- material base class ----/
        
    three_object material {
        three_class = "Material"
        
        float opacity [?]
        boolean transparent [?]
        blending [?]
        boolean depth_test [?]
        boolean depth_write [?]
        boolean polygon_offset [?]
        polygon_offset_factor [?]        
        polygon_offset_units [?]        
        alpha_test [?]
        boolean overdraw [?]
           
        options{} = { with (opacity)        { "opacity": opacity },
                      with (transparent)    { "transparent": transparent },
                      with (blending)       { "blending": blending },
                      with (depth_test)     { "depthTest": depth_test },
                      with (depth_write)    { "depthWrite": depth_write },
                      with (polygon_offset) { "polygonOffset": polygon_offset },
                      with (offset_factor)  { "offsetFactor": offset_factor },
                      with (offset_units)   { "offsetUnits": offset_units },
                      with (alpha_test)     { "alphaTest": alpha_test },
                      with (overdraw)       { "overdraw": overdraw },
                      with (side)           { "side": side }
                      
                    }
    }
    
    /---- materials ----/
    
    material basic_material {
        three_class = "MeshBasicMaterial"
        
        undecorated color [?]
        undecorated map [?]
        light_map [?]
        env_map [?]
        combine [?]
        reflectivity [?]
        refraction_ratio [?]
        boolean fog [?]
        shading [?]
        boolean wireframe [?]
        line_width [?]
        line_cap [?]
        line_join [?]
        boolean vertex_colors [?]
        boolean skinning [?]
        boolean morph_targets [?]
    
        options{} = { with (color)            { "color": color },
                      if   (map)              { "map": map },
                      if   (light_map)        { "lightMap": light_map },
                      if   (env_map)          { "envMap": env_map },
                      with (combine)          { "combine": combine },
                      with (reflectivity)     { "reflectivity": reflectivity },
                      with (refraction_ratio) { "refractionRatio": refraction_ratio },
                      with (fog)              { "fog": fog },
                      with (shading)          { "shading": shading },
                      with (wireframe)        { "wireframe": wireframe },
                      with (line_width)       { "wireframeLinewidth": line_width },
                      with (line_cap)         { "wireframeLinecap": line_cap },
                      with (line_join)        { "wireframeLinejoin": line_join },
                      with (vertex_colors)    { "vertexColors": vertex_colors },
                      with (skinning)         { "skinning": skinning },
                      with (morph_targets)    { "morphTargets": morph_targets }
                    }                     
    }

    basic_material lambert_material {
        three_class = "MeshLambertMaterial"
    }

    basic_material phong_material {
        three_class = "MeshPhongMaterial"
    }
    
    /---- textures ----/

    undecorated load_texture(image_path) {
        [| THREE.ImageUtils.loadTexture("{= image_path; =}") |]
    }

    
}
