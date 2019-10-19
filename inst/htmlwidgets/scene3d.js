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
          'controls':null
      };
      
    return {
      renderValue: function(x) {
        init(wg_data, el);
        animate(wg_data);
      },
      resize: function(width, height) {
          wg_data.renderer.setSize( width, height );
          wg_data.camera.aspect = width / height;
          wg_data.camera.updateProjectionMatrix();
      },
      wg_data: wg_data
    };
  }
});