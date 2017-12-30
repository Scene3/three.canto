/---------------------
 -- three_main.fun
 --
 -- Main module of three.fun
 -- Bento support for three.js
 --
 -- Copyright (c) 2017 by Michael St. Hippolyte
 --
 --/
 
site three {

    /------------ GLOBAL ---------------/

    /---- global constants ----/
    
    static int LOG_DEBUG   = 3
    static int LOG_INFO    = 2
    static int LOG_WARNING = 1
    static int LOG_ERROR   = 0


    /---- convenience ----/
    
    static float RADIANS_45_DEG = 0.785398163
    static float RADIANS_90_DEG = 1.570796327
    static float RADIANS_180_DEG = 3.141592654
    

    /---- global data ----/

    global int logging_level(int level) = level

    global set_logging_level(int level) {
        eval(logging_level(: level :));
        log("three.logging_level set to " + 
            (level == 0 ? "LOG_ERROR" :
            (level == 1 ? "LOG_WARNING" :
            (level == 2 ? "LOG_INFO" :
            (level == 3 ? "LOG_DEBUG" : "unrecognized value (" + level + ")")))));
    }
      
  
    
    /---- site initialization ----/
    init {
        info_log("three.init called");
    }
    
    /------------- SESSION --------------/

   
    /---- session initialization ----/
    
    session_init {
        info_log("three.session_init called");
    }


    /----------- OBJECT MODEL -----------/

   
    /------- classes for script components -------/


    /** base class of objects used in scene construction **/
    dynamic script_object {

        /** Every object has a name.  The default, defined here, is to use
         *  the current instance's type name.  So, for example:
         *
         *       camera p_camera = perspective_camera(60, 1, 1, 1000)
         *       p_camera.name;
         *
         *  would output
         *
         *       p_camera
         *
         *  The name is used to reference the object in client scripts, so it 
         *  must be unique in that scope.  If the type name is not unique,  
         *  the subclass should override this to implement a different naming
         *  scheme.    
         **/

        dynamic name = owner.type

        /** To generate basic scripting operations in a general way, we define
         *  "field" and "method", which translate Bento instantiations into 
         *  either property assignments or method calls.  A base class, "member",
         *  handles the common statement prologue.
         **/  

        javascript member {
            name = owner.type

            owner.name;
            [| . |]
            name;
            sub;
        }

        member field(x) {
            [| = |]
            x;
            [| ; |]
        }

        member immutable_field(x),(x, y),(x, y, z) {
            [| .set( |]
            x;
            with (y) {
                [| , |]
                y;
            }
            with (z) {
                [| , |]
                z;
            }
            [| ); |]
        }
            
        member method(x),(x, y),(x, y, z) {
            [| ( |]
            x;
            with (y) {
                [| , |]
                y;
            }
            with (z) {
                [| , |]
                z;
            }
            [| ); |]
        }
        
        dynamic javascript generate { 
            debug_log("constructing object " + name);
            sub;
        }
        
        this;
    }

    /** an object representing a javascript function **/
    dynamic script_object js_function {
      
        parameters[] = []
      
        javascript body [?]

        /-- declare the function --/
        javascript declare [/
            {= debug_log("declaring function " + name + " with " + parameters.count + " parameters"); =}
            function {= name; =}({= item_list(parameters); =}) {
            {= body; =}
            }
        /]


        /-- call the function --/
        this generate [/ {= name; =}(); |]
    }

    dynamic item_list(items[]) {
        int num_items = items.count
    
        if (num_items > 0) {
            for int i from 0 to (num_items - 1) {
                items[i];
                ", ";
            }
            items[num_items - 1];
        }
    }
         
    /----------- three.js-compatible object model ----------/

    /---- primitives ----/
    
    dynamic javascript vector3(xx, yy, zz) {
        double x = xx
        double y = yy
        double z = zz

        debug_log("...instantiating vector3 of type "+ type + " and x,y,z = " + x + "," + y + "," + z);
        [/ new THREE.Vector3({= x; =}, {= y; =}, {= z; =}) |]

    } 

    dynamic vector3(*) position(xx, yy, zz) [/]

    dynamic vector3(*) rotation(xx, yy, zz) [/]
    

    dynamic javascript three_color(c) {
        keep: int color = c
        
        [/ new THREE.Color({= color; =}) |]
    }

    /** Base class of objects used in scene construction.  These objects
     *  correspond directly or indirectly to three.js objects.  Objects
     *  with direct analogs among three.js objects generally have the same 
     *  name as their three.js doppelgangers.
     **/

    dynamic script_object three_object {
        decl [/]
        three_class = "Object3D"
        args[] = []
        options{} = {}
        position pos = position(0, 0, 0)
        rotation rot = rotation(0, 0, 0)

        three_object[] objs = []
        boolean is_composite = (objs.count > 1)
        
        /-- optional event handlers --/

        javascript on_point_to [?]
        javascript on_hover_over [?]
        javascript on_drag [?]
        
        /-- check for defined handlers --/

        dynamic boolean is_pointable = on_point_to ?? true : false
        dynamic boolean is_hoverable = on_hover_over ?? true : false
        dynamic boolean is_draggable = on_drag ?? true : false

        three_object[] pointable_objs = [
                if (owner.owner.is_pointable) {
                    owner.owner.def
                } else {
                    for three_object o in objs {
                        for three_object po in o.pointable_objs {
                            po.def
                        }
                    }
                }
            ]

        three_object[] hoverable_objs = [
                if (owner.owner.is_hoverable) {
                    owner.owner.def
                } else {
                    for three_object o in objs {
                        for three_object ho in o.hoverable_objs {
                            ho.def
                        }
                    }
                }
            ]

        three_object[] draggable_objs = [
                if (owner.owner.is_draggable) {
                    owner.owner.def
                } else {
                    for three_object o in objs {
                        for three_object dro in o.draggable_objs {
                            dro.def
                        }
                    }
                }
            ]

        
        /-- animation logic, called for each frame if defined --/
        javascript next_frame [?]

        /-- interaction logic, called to handle user interaction --/
        javascript interact [?]
        

        dynamic javascript add(three_object obj) {
            debug_log("....adding " + obj.name + " to " + name);
            name;
            [| .add( |]
            obj.name;
            [| ); |]
        }
        
        dynamic javascript rotate(float x, float y, float z) {
            newline;
            name; [| .rotation.x += {= x; =}; |]
            name; [| .rotation.y += {= y; =}; |]
            name; [| .rotation.z += {= z; =}; |]
        }
        
        dynamic javascript orient(float x, float y, float z) {
            newline;
            name; [| .rotation.x = {= x; =}; |]
            name; [| .rotation.y = {= y; =}; |]
            name; [| .rotation.z = {= z; =}; |]
        }
        
        dynamic javascript rotate_on_axis(vector3 axis, float angle) {
            newline;
            name; [| .rotateOnAxis({= axis; =},{= angle; =}); |]
        }

        dynamic javascript move(float x, float y, float z) {
            newline;
            name; [| .position.x += {= x; =}; |]
            name; [| .position.y += {= y; =}; |]
            name; [| .position.z += {= z; =}; |]
        }

        dynamic javascript locate(float x, float y, float z) {
            newline;
            name; [| .position.x = {= x; =}; |]
            name; [| .position.y = {= y; =}; |]
            name; [| .position.z = {= z; =}; |]
        }

        dynamic immutable_field(pos.x, pos.y, pos.z) set_position {
            name = "position"
        }

        dynamic immutable_field(rot.x, rot.y, rot.z) set_rotation {
            name = "rotation"
        }

        dynamic javascript construct {
            debug_log("...constructing " + three_class + "...");
            debug_log("    ...args: " + (string) args);  
            debug_log("    ...options: " + (string) options);  
            debug_log("    ...decorated options: " + decorate(options));  

            [/ new THREE. |]
            three_class;
            [| ( |]

            if (args) {
                arg_list(args);

            } else if (options) { 
                decorate(options);
            }

            [| ) |]
        }

        dynamic javascript set_attributes {
            debug_log("setting position of " + owner.type + " to " + pos);
            with (pos) [/
                {= name; =}.position.set({= pos.x; =}, {= pos.y; =}, {= pos.z; =});
            |]
            sub;            
        }         

        this generate {
            /-- declare the object and call its constructor --/
            if (decl) {
                decl;
                
            } else if (three_class) [/ 
                var {= name; =} = {= construct; =};
            |]
            
            set_attributes;
            
            sub;
    
            with (next_frame) [/
                {= name; =}.next_frame = function () {
                    {= next_frame; =}
                };
            |]

            with (interact) [/
                {= name; =}.interact = function () {
                    {= interact; =}
                };
            |]
            
            with (on_point_to) [/
                {= name; =}.onselect = function() {
                    {= on_point_to; =}
                };
            |]

            with (on_drag) [/
                {= name; =}.ondrag = function() {
                    {= on_drag; =}
                };
            |]
        }
    }


    /** containers of other objects **/
    three_object composite_object {
        three_class = "Object3D"
        position pos = position(0, 0, 0)

        three_object objs[] = []
        
        this set_attributes {
        
            name; 
            
            [| .raycast = function(raycaster, intersects) {
                    var childIntersects = [];
                    var children = this.children;
                    for ( var i = 0, len = children.length; i < len; i++ ) {
                       children[i].raycast(raycaster, childIntersects);
                       if (childIntersects.length > 0) {
                           var intersection = childIntersects[0];
                           intersection.object = this;
                           intersects.push(intersection);
                           return;
                       }
                    }          
                };
            |]
        
            sub;
        }
        
        this generate {
            debug_log("composite object " + name + " has " + objs.count + " objs"); 
            debug_log("  ..objs[0]: " + objs[0].name + "   class: " + objs[0].three_class);
            
            for three_object o in objs {
                o.generate;
                add(o);
            }
    
            sub;
        }
    }

    /** An object_group is a simple composite object in which all three_object
     *  children are added automatically to the objs array.
     **/
    composite_object object_group {
        three_object objs[] = [
            for three_object obj in owner.children_of_type("three_object") { 
                obj
            }
        ]
    }


    /** base class for synthetic objects, which do not have a direct three.js 
     *  corollary
     **/    

    three_object synthetic_object {
        three_class = owner.type
        position pos = position(0, 0, 0)
        name [?]
        javascript decl [?]
    }


    /------------- renderers -------------/

    three_object renderer(canvas_name, width, height),
                         (width, height),
                         (boolean size_to_window) {
        
        undecorated canv_name = canvas_name
        
        options{} = { if (canv_name) { "canvas": canv_name } }
     
        javascript set_size(width, height) {
            owner.name;
            [| .setSize({= width; =}, {= height; =}); |]
        }

        javascript set_attributes [/]
        
        this generate {                
            set_size(width, height);
            sub;
        }
    }


    
    renderer(*) canvas_renderer(canvas_name, width, height),
                               (width, height),
                               (boolean size_to_window) {
        three_class = "CanvasRenderer"
    }
    
    renderer(*) webgl_renderer(canvas_name, width, height),
                               (width, height),
                               (boolean size_to_window) {
        three_class = "WebGLRenderer"
    }
    

    /------------- raycaster -------------/

    dynamic javascript raycaster(),
                                (vector3 origin, vector3 direction),
                                (vector3 origin, vector3 direction, near, far) {
        three_class = "Raycaster"
    
        with (near)        [| new THREE.Raycaster({= origin; =}, {= direction; =}, {= near; =}, {= far; =}) |]
        else with (origin) [| new THREE.Raycaster({= origin; =}, {= direction; =}) |]
        else               [| new THREE.Raycaster() |]
    } 


    /-------------- the scene ------------/
   
    composite_object scene(three_object[] scene_objs, camera scene_cam, width, height),
                          (three_object[] scene_objs, width, height),
                          (three_object[] scene_objs, camera scene_cam),
                          (width, height),
                          (three_object[] scene_objs) {
        three_class = "Scene"

        javascript next_frame {
            for three_object o in objs {
                 if (o.next_frame) {
                     js_comment("next_frame for " + o.name);
                     o.next_frame;
                 }
            }
        }
        
        javascript interact {
        }

        keep: three_object objs[] = scene_objs
        keep: camera cam = scene_cam ? scene_cam : default_scene_cam
        keep: aspect_ratio = ((width && height) ? (width + "/" + height) : "1");
        
        scripts[] = []

        this generate {
        
            with (width) {
                info_log("constructing scene " + name + ", width " + width + "  height " + height); 
            } else {           
                info_log("constructing scene " + name); 
            }
            
            info_log(objs.count + " scene objects");
    
            eval(aspect_ratio);
    
            /-- instantiate and add camera --/
            js_comment_log("instantiate camera");
    
            cam.generate;
            if (width && height) {
                cam.aspect(aspect_ratio);
                cam.update_projection_matrix;
            }
            js_comment_log("add camera");
            add(cam);
        }
    }
    
    /---- default scene camera ----/
    
    dynamic perspective_camera default_scene_cam {
        position pos = position(0, 2, 25)
        name = "default_camera"

        this generate {
            far(2000);    /--- 1.5 * backdrop.horizon); ---/
            debug_log("default_scene_cam name: " + name);
            [|
                {= name; =}.target = new THREE.Vector3( 0, 2, 0 );
            |]
            sub;
        }
    }



        /-- lights --/

    three_object light(clr) {
        three_class = "Light"
        args[] = [ color ]
        undecorated color = clr
    }    

    light(*) ambient_light(clr) {
        three_class = "AmbientLight"
    }

    light(*) directional_light(clr) {
        three_class = "DirectionalLight"
    }

    light(*) point_light(clr) {
        three_class = "PointLight"
    }

    light(*) spot_light(clr) {
        three_class = "SpotLight"
    }


        /-- elementary visible objects --/
    
    dynamic three_object mesh(geometry g, material m) {
        three_class = "Mesh"
        geometry geo = g
        material mat = m
        args[] = [ geo.construct, mat.construct ]
    }

    
 
    /---- info/sample page ----/
  
    public page(params) three_info(params{}) {

        /-------------------------/
        /---- meta properties ----/

        title = "three.fun"
        viewport [| width=device-width, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0 |]

        style [| 
            html, body { 
                width: 100%;
                height: 100%;
                min-width: 100%;
                min-height: 100%;
                margin: 0;
                background: #111111;
            }
        |]

        /---------------------/
        /----  the scene  ----/

        scene sample_scene {
            phong_material blue_material {
                undecorated color = 0x3333CC
            }
            
            mesh(cube_geometry(7, 7, 7), blue_material) blue_cube {
                position pos = position(0, 2, 0)
                on_drag {
                    log("blue_cube.on_drag called");
                }
            }

            point_light(0xAAAAAA) soft_light {
                position pos = position(0, 12, 40)
            }

            three_object[] objs = [
                blue_cube,
                soft_light
            ]
            
            javascript next_frame {
                blue_cube.rotate(0.002, -0.002, -0.001);
            }
        }
      

        /--------------------/
        /---- the canvas ----/
    
        three_component(*) tc(scene s),(params{}) {
            style  [| position: absolute; top: 0; left: 0;
                      width: 100%; height: 100%; 
                      margin: 0; padding: 0;
                      z-index: 0;
                   |]

            canvas_id = "tc"
            
            drag_controls(*) my_drag_controls(id, three_object obj) {
                boolean z_lock = true
            }

            controls[] canvas_controls = [ my_drag_controls(canvas_id, s) ]
        }        

        [|
           <div style="position: absolute; top: 16px; left: 16px;
                       width: 30em; padding: 12px;
                       color: #88FFAA;
                       z-index: 100; background: rgba(255, 255, 255, 0.1)" >
               <h2>three.fun</h2>
               <h3>Bento support for three.js</h3>
               <p>
                   three.fun is a library that makes it easy to write server
                   applications that deliver interactive 3D content.
               </p>
           </div>
        |] 
        tc(sample_scene);
    }
    
    dobjs { 
        three_info.sample_scene.draggable_objs;
    }


    /----------- javascript generation utilities -----------/

    /** Construct a javascript comment, i.e. a comment in the code downloaded
     *  to the client.
     **/
    
    dynamic js_comment(comment) {
        newline; newline; "/"; "* ";
        comment;
        " *"; "/"; newline;
    }

    /** Convenience function to add a comment to the javascript source and log
     *  the comment at the same time.
     **/

    dynamic js_comment_log(comment) {
        js_comment(comment);
        info_log("adding comment to javascript: " + comment);
    }


    /** Construct a javascript argument list from an array. **/
    
    dynamic arg_list(arguments[]) {
        if (arguments) {
            for int i from 0 to arguments.count {
                if (i > 0) [| , |]
                arguments[i];
            } 
        }
    }


    /-- JSON helpers --/

    undecorated [/]

    dynamic decorate(items{}) {
        "{ "; 
        for k in items.keys and int i from 0 {
            if (i > 0) {
                ", ";
            }
            k;
            ": ";
            if (!(items[k] isa undecorated)) {
                debug_log(k + " gets decoration"); 
                '"';
                items[k];
                '"';
            } else { 
                debug_log(k + " is undecorated"); 
                items[k];
            }
        }
        " }";
    }   

    /-- Logging --/
    
    dynamic error_log(str) {
        if (logging_level >= LOG_ERROR) {
            log(str);
        }
    }
    
    dynamic warning_log(str) {
        if (logging_level >= LOG_WARNING) {
            log(str);
        }
    }

    dynamic info_log(str) {
        if (logging_level >= LOG_INFO) {
            log(str);
        }
    }

    dynamic debug_log(str) {
        if (logging_level >= LOG_DEBUG) {
            log(str);
        }
    }

}
