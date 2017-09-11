/---------------------
 -- three.fun
 --
 -- Component for rendering three.js content
 --
 -- Copyright (c) 2017 by Michael St. Hippolyte
 --
 --/
 
site three {

     
    /--------- THREE_COMPONENT ----------/

    /** Component to display and control a three.js scene.
     *
     *  A three_component is a DOM element that corresponds to a rendering 
     *  canvas.  
     *
     *  There are two scenarios in which this component is called: during
     *  page construction and via ajax.  These correspond to the two 
     *  parameter lists.  When passed a scene, the component constructs it
     *  and keeps it.  When passed a param table, the component processes 
     *  the params and responds with any changes to the kept scene.  Changes 
     *  may include modification of objects in the scene, addition or removal 
     *  of objects, or wholesale replacement of the scene.
     *
     **/ 
   
    public component three_component(scene new_scene),(params{}) {
    
        /--------------------------------/
        /---- overridable properties ----/
        
        /---- required override: subclasses must define this ----/
        canvas_id [?]

        id = canvas_container

        /---- optional overrides ----/
  
        dynamic default_handler_name(event) = canvas_name + "_" + event
        dynamic javascript handle(event) {
            default_handler_name(event);
            [/ (); /]            
        } 

        dynamic javascript recalc_canvas_size_logic {
            if (size_to_window) [/
                var x = 0;
                var y = 0;
                var width = 0;
                var height = 0;
                for (var element = {= canvas_container; =}; element != null; element = element.offsetParent) {
                   x += element.offsetLeft;
                   y += element.offsetTop;
                   if (element.offsetParent == null) {
                       width = element.offsetWidth;
                       height = element.offsetHeight;
                   }
                }
                canvasWidth = width - x;
                canvasHeight = height - y;
            /] else [/
                canvasWidth = {= canvas_container; =}.clientWidth;
                canvasHeight = {= canvas_container; =}.clientHeight;
            /]
        }

        sub_script [/]
        sub_funcs [/]
        
        controls[] canvas_controls = []

        /---- the three_component is the rendering canvas. ----/
        canvas_name = canvas_id

        /---- subclasses may override these fields to define a fixed size 
         ---- canvas; otherwise the canvas is set to the width and height 
         ---- of the component containing it.
         ----/
        canvas_width [/ canvasWidth /]
        canvas_height [/ canvasHeight /]
        boolean size_to_window = true

        /---- names of various canvas-related things ----/
        canvas_container = canvas_id + "_container"
        canvas_renderer = canvas_id + "_renderer"
        canvas_scene = canvas_id + "_scene"
        canvas_camera = canvas_id + "_camera"

        /---- subclasses may override this to add additional scripts to the list  ----/
        include_scripts = [ "/js/lib/three.js" ]

        /** if true, an onLoad handler is defined and all the scripts defined by this component
         *  are embedded in the handler.
         **/
        boolean run_scripts_on_load = true

        /-------------------------------/
        /---- global event handling ----/
  
        /** Sets the handler for the event. **/
        dynamic set_handler(script_object element, event, js_function handler),
                                                      (event, js_function handler),
                                                      (event) {
            newline;
            with (element)  {
                element.name;
                [/ . /]
            } else {
                [/ window. /]
            }
            event;
            [/ = /]
            with (handler) {
                handler.name;
            } else {
                default_handler_name(event);
            }
            [/ ; /]
        } 

        dynamic js_function default_handler(event) {
            name = default_handler_name(event)
            
            [/            
                function {= default_handler_name(event); =}(event) {
                    {= body; =}
                }
            /]
        }            



        /------------- controls --------------/
    
        dynamic javascript add_controls {
            for controls c in canvas_controls {
                c.attach(canvas_camera);
                c.add_listeners(canvas_id);
            }
        }

        dynamic javascript activate_controls(boolean flag),
                                            (controls_type, boolean flag) {
                                 
            with (controls_type) {
                for controls c in canvas_controls {
                    if (c.def.is_a(controls_type)) {
                        c.activate(flag);
                        log(controls.type + " activated");
                    }
                }

            } else {
                for controls c in canvas_controls {
                    c.activate(flag);
                }
            }
        }

        dynamic javascripts declare_controls {
            for controls c in canvas_controls {
                c.declare;
            }
        }


        /-------------------------------/
        /---------- the scene ----------/

        keep: scene this_scene = new_scene
        

        /-------------------------------/
        /-------- the renderer ---------/

        webgl_renderer(*) this_renderer(cname, width, height) {
        
            this generate {
                canvas_container;
                [/ .appendChild( /]
                name;
                [/ .domElement); /]
                sub;
            }
        }


        /-----------------------/
        /------ scripting ------/
        
        scripts {
            info_log("instantiating include_scripts");
            for s in include_scripts [/
                <script src="{= s; =}"></script>
            /]

            info_log("instantiating main_script");

            [/ <script> /]
            main_script;
            [/ </script> /]    
         }

    
         javascript main_script {

            debug_log("main_script called with scene " + this_scene.name + " with " + this_scene.objs.count + " objects");
            debug_log(" obj[0] " + this_scene.objs[0].type); 
            for three_object o in this_scene.objs {
                debug_log("   ..." + o.type);
            }
            
            /-- create the canvas for rendering, and in the process see 
             -- if HTML5 and WebGL are supported
             --/  
            debug_log("create canvas");
            create_canvas;

            /-- declare top-level functions and variables --/
            js_comment_log("declare global variables");
            declare_global_vars;
            declare_controls;
            
            if (run_scripts_on_load) {
                [/ function {= default_handler_name("onload"); =}() { /]
            }
            
            /-- proceed, providing there is webgl --/            
            [/ if (webglEnabled) { /]

                [/ recalcCanvasSize(); /]

                debug_log("constructing renderer id " + canvas_id + "   width " + canvas_width + "   height " + canvas_height);
                this_renderer(canvas_id, canvas_width, canvas_height).generate;

                if (size_to_window) [/
                    window.addEventListener("resize", resizeCanvas, false);
                /]

                /-- construct the scene --/
                js_comment_log("construct the scene");
                this_scene.generate;

                js_comment_log("assign global variables");
                assign_global_vars;
                

                /-- let the scene add to the script --/
                if (this_scene.scripts) {
                    js_comment_log("add scene scripts");
                    this_scene.scripts;
                }

                /-- add script defined by subclass, if any --/
                if (sub_script) {
                    js_comment_log("add subclass script");
                    sub_script;
                }

                /-- add mouse listeners etc. --/
                add_controls;

                [/ updateCamera(); /]

                /-- drop into the rendering loop, from whence we will not return --/
                info_log("begin rendering loop");
                run;

            /-- no webgl --/
            [/ } else { /]
                /-- notify the user and exit --/
                canvas_container;
                [/ .innerHTML = "<p><strong>Your hardware or software does not support the graphics capability required by this page.</strong></p>"; /]
            [/ } /]

            if (run_scripts_on_load) {
                [/ } /]
                set_handler("onload");
            }
            
            js_comment_log("declare global functions");
            declare_funcs;
        }

        /** Declare top level variables, including the  variable corresponding to this 
         *  component.
         **/
        javascript declare_global_vars [/
            var {= canvas_container; =} = document.getElementById("{= id; =}");
            var canvasWidth = {= canvas_container; =}.clientWidth;
            var canvasHeight = {= canvas_container; =}.clientHeight;
            var {= canvas_renderer; =};
            var {= canvas_scene; =};
            var {= canvas_camera; =};
        /]  
        
        camera this_cam = this_scene.cam
        javascript assign_global_vars [/
            {= canvas_renderer; =} = this_renderer;
            {= canvas_scene; =} = {= this_scene.name; =};
            {= canvas_camera; =} = {= this_scene.cam.name; =};

        /]

        javascript update_global_vars(params{}) {
            cam_pos = canvas_camera + ".position"
                   
            if (params["camera_x"]) {
                cam_pos;
                [/ .setX( /]
                params["camera_x"];
                [/ ); /]
            }
            if (params["camera_x"]) {
                cam_pos;
                [/ .setX( /]
                params["camera_x"];
                [/ ); /]
            }
            if (params["camera_x"]) {
                cam_pos;
                [/ .setX( /]
                params["camera_x"];
                [/ ); /]
            }
       }       
        
        
        /** Create the canvas, depending on what kind of graphics support is available on the client. **/
        javascript create_canvas [/
             var {= canvas_name; =} = document.createElement("canvas");
             {= canvas_name; =}.id = "{= canvas_id; =}";
             var canvasEnabled = {= canvas_name; =} && !!window.CanvasRenderingContext2D;
             var webglEnabled = {= canvas_name; =} && (
                 function (canvas) { 
                     try {
                         if (!window.WebGLRenderingContext) {
                             return false;
                         }
                         if (canvas.getContext("webgl")) {
                             return true;
                         }
                         if (canvas.getContext("experimental-webgl")) { 
                             return true;
                         }
                     } catch (e) { 
                         return false;
                     }
                 } ({= canvas_name; =}));
        /]
        
                      
        /** Declare functions. **/
        javascript declare_funcs {
            declare_utils;
            render.declare;
            post_render.declare;                
            animate.declare;

            /-- let the subclass declare functions --/
            sub_funcs;
        }
        
        
        /** Run the animation. **/
        javascript run [/
            animate();
        /]

        /-- top-level javascript functions for this component --/


        js_function animate {
        
            args[] = [ "timestamp" ]
            
            body [/
                requestAnimationFrame(animate);
                {= canvas_scene; =}.next_frame();
                render();
                post_render();
            /]
        }

        js_function interact {
            body [/]
        }
        
        js_function render {
            body {
                canvas_renderer; 
                [/ .render( /]
                canvas_scene;
                [/ , /]
                canvas_camera;
                [/ ); /]
            }
        }

        js_function post_render {
            body [/]
        }
       
       
        javascript declare_utils [/

            function resizeCanvas() {
                recalcCanvasSize();
                {= canvas_renderer; =}.setSize(canvasWidth, canvasHeight);
                updateCamera();
            }
            
            function updateCamera() {
                {= canvas_camera; =}.aspect = canvasWidth / canvasHeight;
                {= canvas_camera; =}.updateProjectionMatrix();
            }
        
            function recalcCanvasSize() { 
                {= recalc_canvas_size_logic; =}
            }

            var debounceTimeOut = null;
            function debounce(func) {
                if (debounceTimeOut != null) {
                    clearTimeout(debounceTimeOut);
                    debounceTimeOut = setTimeout(func, 100);
                }
            }
                      
        /]

        /--------------------------------/
        /---- component construction ----/

        /---- full instantiation ----/
        with (new_scene) {
            info_log("instantiating three_component");    
            sub;
            debug_log("instantiating three_component scripts");
            scripts;
            
        /---- respond to ajax call ----/
        } else with (params) {
        
        
        }
    }

}
