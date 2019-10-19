HTMLWidgets.widget({
  name: "scene3d",
  type: "output",
  factory: function(el, width, height) {
    var  wg_data = {
          'camera':null,
          'scene':null,
          'renderer':null,
          'geometry':null,
          'material':null,
          'mesh':null,
          'controls':null,
          'light':null,
          'gltfloader':null
          };
      
    return {
      renderValue: function(x) {
        if ( typeof(scenes) === "undefined" ) {
            scenes = [wg_data];
        } else {
            scenes.push(wg_data); 
        }
        init(wg_data, el);
        animate(wg_data);
        if ( x.gltf ) {
          loadGltf(wg_data, x.gltf);
        }
      },
      resize: function(width, height) {
          wg_data.renderer.setSize( width, height );
          wg_data.camera.aspect = width / height;
          wg_data.camera.updateProjectionMatrix();
      },
    };
  }
});