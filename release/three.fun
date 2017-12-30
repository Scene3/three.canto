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
            [| (); |]            
        } 

        dynamic javascript recalc_canvas_size_logic {
            if (size_to_window) [|
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
            |] else [|
                canvasWidth = {= canvas_container; =}.clientWidth;
                canvasHeight = {= canvas_container; =}.clientHeight;
            |]
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
        canvas_width [| canvasWidth |]
        canvas_height [| canvasHeight |]
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
                [| . |]
            } else {
                [| window. |]
            }
            event;
            [| = |]
            with (handler) {
                handler.name;
            } else {
                default_handler_name(event);
            }
            [| ; |]
        } 

        dynamic js_function default_handler(event) {
            name = default_handler_name(event)
            
            [|            
                function {= default_handler_name(event); =}(event) {
                    {= body; =}
                }
            |]
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
                [| .appendChild( |]
                name;
                [| .domElement); |]
                sub;
            }
        }


        /-----------------------/
        /------ scripting ------/
        
        scripts {
            info_log("instantiating include_scripts");
            for s in include_scripts [|
                <script src="{= s; =}"></script>
            |]

            info_log("instantiating main_script");

            [| <script> |]
            main_script;
            [| </script> |]    
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
                [| function {= default_handler_name("onload"); =}() { |]
            }
            
            /-- proceed, providing there is webgl --/            
            [| if (webglEnabled) { |]

                [| recalcCanvasSize(); |]

                debug_log("constructing renderer id " + canvas_id + "   width " + canvas_width + "   height " + canvas_height);
                this_renderer(canvas_id, canvas_width, canvas_height).generate;

                if (size_to_window) [|
                    window.addEventListener("resize", resizeCanvas, false);
                |]

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

                [| updateCamera(); |]

                /-- drop into the rendering loop, from whence we will not return --/
                info_log("begin rendering loop");
                run;

            /-- no webgl --/
            [| } else { |]
                /-- notify the user and exit --/
                canvas_container;
                [| .innerHTML = "<p><strong>Your hardware or software does not support the graphics capability required by this page.</strong></p>"; |]
            [| } |]

            if (run_scripts_on_load) {
                [| } |]
                set_handler("onload");
            }
            
            js_comment_log("declare global functions");
            declare_funcs;
        }

        /** Declare top level variables, including the  variable corresponding to this 
         *  component.
         **/
        javascript declare_global_vars [|
            var {= canvas_container; =} = document.getElementById("{= id; =}");
            var canvasWidth = {= canvas_container; =}.clientWidth;
            var canvasHeight = {= canvas_container; =}.clientHeight;
            var {= canvas_renderer; =};
            var {= canvas_scene; =};
            var {= canvas_camera; =};
        |]  
        
        camera this_cam = this_scene.cam
        javascript assign_global_vars [|
            {= canvas_renderer; =} = this_renderer;
            {= canvas_scene; =} = {= this_scene.name; =};
            {= canvas_camera; =} = {= this_scene.cam.name; =};

        |]

        javascript update_global_vars(params{}) {
            cam_pos = canvas_camera + ".position"
                   
            if (params["camera_x"]) {
                cam_pos;
                [| .setX( |]
                params["camera_x"];
                [| ); |]
            }
            if (params["camera_x"]) {
                cam_pos;
                [| .setX( |]
                params["camera_x"];
                [| ); |]
            }
            if (params["camera_x"]) {
                cam_pos;
                [| .setX( |]
                params["camera_x"];
                [| ); |]
            }
       }       
        
        
        /** Create the canvas, depending on what kind of graphics support is available on the client. **/
        javascript create_canvas [|
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
        |]
        
                      
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
        javascript run [|
            animate();
        |]

        /-- top-level javascript functions for this component --/


        js_function animate {
        
            args[] = [ "timestamp" ]
            
            body [|
                requestAnimationFrame(animate);
                {= canvas_scene; =}.next_frame();
                render();
                post_render();
            |]
        }

        js_function interact {
            body [/]
        }
        
        js_function render {
            body {
                canvas_renderer; 
                [| .render( |]
                canvas_scene;
                [| , |]
                canvas_camera;
                [| ); |]
            }
        }

        js_function post_render {
            body [/]
        }
       
       
        javascript declare_utils [|

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
                      
        |]

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
/---------------------
 -- three_controls.fun
 --
 -- Controls for three.fun
 --
 -- Copyright (c) 2017 by Michael St. Hippolyte
 --
 --/
 
site three {

    /---- interaction model ----/

    dynamic dom_event(nm) {
       name = nm
       [| '{= name; =}' |]
    }
        
    dynamic event_handler {
        boolean capture = false
        name = "on" + owner.type
        declare [?]
    }
    
    dynamic event_listener(element, dom_event event, event_handler handler) {
        [/
            {= element; =}.addEventListener({= event; =}, {= handler.name; =}, {= handler.capture; =});
        |]            
    }

    /---- interaction events ----/

    static dom_event("mousedown") MOUSEDOWN [/]
    static dom_event("mouseup")   MOUSEUP   [/]
    static dom_event("mousemove") MOUSEMOVE [/]


    controls {
        boolean enabled_by_default = true;
    
        declare [?]
        
        event_handler mousedown [?]
        event_handler mouseup [?]
        event_handler mousemove [?]
        
        add_listeners(dom_element) {
            with (mousedown) {
                event_listener(dom_element, MOUSEDOWN, mousedown);
            }
            with (mouseup) {
                event_listener(dom_element, MOUSEUP, mouseup);
            }
            with (mousemove) {
                event_listener(dom_element, MOUSEMOVE, mousemove);
            }
        
        }
        
        dynamic attach(cam_var) [/]
        dynamic activate(boolean flag) [/]
    
        this;
    }
    
    /**
     * point_controls is a controls object that enables picking objects that have the pointable
     * property.
     *
     **/
     
    controls point_controls(id, three_object obj) {
        controls_var = id + "_point_controls"

        declare [/
            var point_controls = function(_camera, _objects) {
                var _domElement = document.getElementById("{= id; =}");
                var _raycaster = new THREE.Raycaster();
                var _offset = new THREE.Vector3();
                var _selected = null;
                var _hovered = null;
                var _this = this;

                if (_objects instanceof THREE.Scene) {
                    _objects = _objects.children;
                }

                this.onmousedown = {= mousedown.declare; =};
                this.onmouseup =   {= mouseup.declare; =};
                this.onmousemove = {= mousemove.declare; =};

                this.enabled = {= enabled_by_default; =};
            }
            point_controls.prototype = Object.create( THREE.EventDispatcher.prototype );
            point_controls.prototype.constructor = point_controls;
        /]
    
        event_handler mousedown {
           name = controls_var + ".onmousedown"
           declare [/
               function(event) {
                   if (_this.enabled === false) {
                       return;
                   }
                  
                   event.preventDefault();
                   var mouse = new THREE.Vector2( (event.offsetX / _domElement.width) * 2 - 1, -(event.offsetY / _domElement.height) * 2 + 1 );
                   _raycaster.setFromCamera( mouse, _camera );
                   var intersects = _raycaster.intersectObjects(_objects);
                   var ray = _raycaster.ray;
                   var normal = ray.direction; // normal ray to the camera position
                   if (intersects.length > 0) {
                       _selected = intersects[0];
                       _selected.ray = ray;
                       _selected.normal = normal ;
                       _offset.copy( _selected.point ).sub( _selected.object.position );
                       if ("onselect" in _selected.object) {
                           _selected.object.onselect();
                       }
                       _this.dispatchEvent( { type: 'select', object: _selected } );
                   }
               }
           |]
        }

        event_handler mouseup {
           name = controls_var + ".onmouseup"
           declare [/
               function(event) {
                   event.preventDefault();
                   if (_selected) {
                       _selected = null;
                   }
                   _domElement.style.cursor = 'auto';
               }
           |]
        }

        event_handler mousemove {
           name = controls_var + ".onmousemove"
           declare [/
               function(event) {
                   if (_this.enabled === false) {
                       return;
                   }

                   event.preventDefault();
                   var mouse = new THREE.Vector2( (event.offsetX / _domElement.width) * 2 - 1, -(event.offsetY / _domElement.height) * 2 + 1 );
                   _raycaster.setFromCamera( mouse, _camera );
                   var intersects = _raycaster.intersectObjects( _objects );
                   if (intersects.length > 0) {
                       _domElement.style.cursor = 'pointer';
                       _hovered = intersects[0];
                       if ("onhoveron" in _hovered.object) {
                           _hovered.object.onhoveron();
                       }
                       _this.dispatchEvent( { type: 'hoveron', object: _hovered } );
                   } else if (_hovered !== null) {
                       if ("onhoveroff" in _hovered.object) {
                           _hovered.object.onhoveroff();
                       }
                       _this.dispatchEvent( { type: 'hoveroff', object: _hovered } );
                       _hovered = null;
                       _domElement.style.cursor = 'auto';
                   }
               }
           |]
        }

        attach(cam_var) [/
            var {= id; =}_pointable_objs = [ {= for three_obj o in obj.pointable_objs {= o.name; ","; =} =} ]; 
            var {= controls_var; =} = new point_controls({= cam_var; =}, {= id; =}_pointable_objs);
        |]
        
        activate(boolean flag) [/
            {= controls_var; =}.enabled = {= flag; =};    
        |]

        this;
    }

    /**
     * drag_controls is a controls object that enables dragging of objects that have the draggable
     * property.
     *
     * Much of the javascript is borrowed from DragControls.js by zz85 / https://github.com/zz85 
     *
     **/
    
    controls drag_controls(id, three_object obj) {
        boolean x_lock = false
        boolean y_lock = false
        boolean z_lock = false
        
        controls_var = id + "_drag_controls"

        declare [/
            var drag_controls = function( _camera, _objects ) {

                var _domElement = document.getElementById("{= id; =}");

                var _raycaster = new THREE.Raycaster();

                var _offset = new THREE.Vector3();
                var _selected = null;
                var _hovered = null;

                var p3subp1 = new THREE.Vector3();
                var targetposition = new THREE.Vector3();
                var zerovector = new THREE.Vector3();

                var _this = this;

                if ( _objects instanceof THREE.Scene ) {
                    _objects = _objects.children;
                }

                this.onmousedown = {= mousedown.declare; =};
                this.onmouseup =   {= mouseup.declare; =};
                this.onmousemove = {= mousemove.declare; =};
                
                this.enabled = {= enabled_by_default; =};
            }
            drag_controls.prototype = Object.create( THREE.EventDispatcher.prototype );
            drag_controls.prototype.constructor = drag_controls;
        /]



        event_handler mousedown {
           name = controls_var + ".onmousedown"
           declare [/
               function(event) {
                   if (_this.enabled === false) {
                       return;
                   }
                  
                   event.preventDefault();
                   var mouse = new THREE.Vector2( (event.offsetX / _domElement.width) * 2 - 1, -(event.offsetY / _domElement.height) * 2 + 1 );
                   _raycaster.setFromCamera( mouse, _camera );
                   var intersects = _raycaster.intersectObjects( _objects );
                   var ray = _raycaster.ray;
                   var normal = ray.direction; // normal ray to the camera position
                   if (intersects.length > 0) {
                       _selected = intersects[0];
                       _selected.ray = ray;
                       _selected.normal = normal ;
                       _offset.copy(_selected.point).sub(_selected.object.position);
                       _domElement.style.cursor = 'move';
                       if ("ondragstart" in _selected.object) {
                           _selected.object.ondragstart();
                       }
                       _this.dispatchEvent( { type: 'dragstart', object: _selected } );
                   }
               }
           |]
        }

        event_handler mouseup {
           name = controls_var + ".onmouseup"
           declare [/
               function( event ) {
                   event.preventDefault();
                   if ( _selected ) {
                       if ("ondragend" in _selected.object) {
                           _selected.object.ondragend();
                       }
                       _this.dispatchEvent( { type: 'dragend', object: _selected } );
                       _selected = null;
                   }
                   _domElement.style.cursor = 'auto';
               }
           |]
        }

        event_handler mousemove {
           name = controls_var + ".onmousemove"
           declare [/
               function( event ) {
                   if (_this.enabled === false) {
                       return;
                   }

                   event.preventDefault();
                   var mouse = new THREE.Vector2( (event.offsetX / _domElement.width) * 2 - 1, -(event.offsetY / _domElement.height) * 2 + 1 );
                   _raycaster.setFromCamera( mouse, _camera );

                   var ray = _raycaster.ray;
                   if (_selected) {
                       var normal = _selected.normal;
                       var denom = normal.dot( ray.direction );
                       if (denom == 0) {
                           console.log( 'no or infinite solutions' );
                           return;
                       }

                       var num = normal.dot(p3subp1.copy(_selected.point).sub(ray.origin));
                       var u = num / denom;

                       targetposition.copy(ray.direction).multiplyScalar(u).add(ray.origin).sub(_offset);

                       {=
                           if (!x_lock) [/
                               _selected.object.position.x = targetposition.x;
                           |]
                           if (!y_lock) [/
                               _selected.object.position.y = targetposition.y;
                           |]
                           if (!z_lock) [/
                              _selected.object.position.z = targetposition.z;
                           |]
                       =}

                       if ("ondrag" in _selected.object) {
                           _selected.object.ondrag();
                       }
                       _this.dispatchEvent( { type: 'drag', object: _selected } );
                       return;
                   }

                  var intersects = _raycaster.intersectObjects( _objects );
                  if (intersects.length > 0) {
                      _domElement.style.cursor = 'pointer';
                      _hovered = intersects[0];
                       if ("onhoveron" in _hovered.object) {
                           _hovered.object.onhoveron();
                       }
                       _this.dispatchEvent( { type: 'hoveron', object: _hovered } );
                  } else if (_hovered !== null) {
                       if ("onhoveroff" in _hovered.object) {
                           _hovered.object.onhoveroff();
                       }
                       _this.dispatchEvent( { type: 'hoveroff', object: _hovered } );
                      _hovered = null;
                      _domElement.style.cursor = 'auto';
                  }
               }
           |]
        }
 
        attach(cam_var) [/
            var {= id; =}_draggable_objs = [ {= for three_obj o in obj.draggable_objs {= o.name; ","; =} =} ]; 
            var {= controls_var; =} = new drag_controls({= cam_var; =}, {= id; =}_draggable_objs);
        |]
        
        activate(boolean flag) [/
            {= controls_var; =}.enabled = {= flag; =};    
        |]

        this;
    }
    
    

}
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
        info_log("Generating code: " + comment);
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
                      with (overdraw)       { "overdraw": overdraw }
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
        
        decl [|
            var {= name; =} = new THREE.Mesh( {= geo.construct; =}, {= mat.construct; =} ); 
            {= name; =}.scale.x = -1;
        |]
    }

        
    three_object ambience {
        light lt [?]
        backdrop bd [/]
        
        three_object[] objs = [ with (lt) { lt }, if (bd) { bd } ]

    }


    /---- very simple objects ----/

 
}
