HTMLWidgets.widget({
  name: "scene3d",
  type: "output",
  factory: function(el, width, height) {
    var  wg_data = {
          'camera':null,
          'scene':null,
          'renderer':null,
          'controls':null,
          'light':null,
          'objloader':null,
          'gltfloader':null,
          'id':el.id
          };
    
    var res = init(wg_data, el, true);
    
    if ( typeof(scenes) === "undefined" ) {
        scenes = [wg_data];
    } else {
        scenes.push(wg_data); 
    }
    
    return {
      renderValue: function(x) {
          
        res.then(function() {
          if ( x.use_vr ) {
             if ( $("#"+wg_data.id).children("button").length === 0 ) {
                $("#"+wg_data.id).appendChild( VR.VRButton.createButton( renderer ) );    
             }
             $("#"+wg_data.id).children("button").show();
          } else {
              $("#"+wg_data.id).children("button").hide();
          }
                      
          wg_data.camera.position.y=1;
          
          // remove all but camera
          while( wg_data.scene.children.length > 1 ) { 
              wg_data.scene.remove(wg_data.scene.children[1]); 
          }

          if ( x.show_ground )
              addGround(wg_data);
          if ( x.obj ) {
            loadObj(wg_data, x.obj);
          }
          if ( x.gltf ) {
            loadGltf(wg_data, x.gltf);
          }  

          var scene = wg_data.scene;
          var data = x.data;
          eval(x.code);

        });
        
      },
      resize: function(width, height) {
          wg_data.renderer.setSize( width, height );
          wg_data.camera.aspect = width / height;
          wg_data.camera.updateProjectionMatrix();
      },
    };
  }
});