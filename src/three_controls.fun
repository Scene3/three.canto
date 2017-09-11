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
       [/ '{= name; =}' /]
    }
        
    dynamic event_handler {
        boolean capture = false
        name = "on" + owner.type
        declare [?]
    }
    
    dynamic event_listener(element, dom_event event, event_handler handler) {
        [|
            {= element; =}.addEventListener({= event; =}, {= handler.name; =}, {= handler.capture; =});
        /]            
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

        declare [|
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
        |]
    
        event_handler mousedown {
           name = controls_var + ".onmousedown"
           declare [|
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
           /]
        }

        event_handler mouseup {
           name = controls_var + ".onmouseup"
           declare [|
               function(event) {
                   event.preventDefault();
                   if (_selected) {
                       _selected = null;
                   }
                   _domElement.style.cursor = 'auto';
               }
           /]
        }

        event_handler mousemove {
           name = controls_var + ".onmousemove"
           declare [|
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
           /]
        }

        attach(cam_var) [|
            var {= id; =}_pointable_objs = [ {= for three_obj o in obj.pointable_objs {= o.name; ","; =} =} ]; 
            var {= controls_var; =} = new point_controls({= cam_var; =}, {= id; =}_pointable_objs);
        /]
        
        activate(boolean flag) [|
            {= controls_var; =}.enabled = {= flag; =};    
        /]

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

        declare [|
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
        |]



        event_handler mousedown {
           name = controls_var + ".onmousedown"
           declare [|
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
           /]
        }

        event_handler mouseup {
           name = controls_var + ".onmouseup"
           declare [|
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
           /]
        }

        event_handler mousemove {
           name = controls_var + ".onmousemove"
           declare [|
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
                           if (!x_lock) [|
                               _selected.object.position.x = targetposition.x;
                           /]
                           if (!y_lock) [|
                               _selected.object.position.y = targetposition.y;
                           /]
                           if (!z_lock) [|
                              _selected.object.position.z = targetposition.z;
                           /]
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
           /]
        }
 
        attach(cam_var) [|
            var {= id; =}_draggable_objs = [ {= for three_obj o in obj.draggable_objs {= o.name; ","; =} =} ]; 
            var {= controls_var; =} = new drag_controls({= cam_var; =}, {= id; =}_draggable_objs);
        /]
        
        activate(boolean flag) [|
            {= controls_var; =}.enabled = {= flag; =};    
        /]

        this;
    }
    
    

}
