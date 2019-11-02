HTMLWidgets.widget({
  name: "videoInput",
  type: "output",
  factory: function(el, width, height) {
    var size = {w:0,h:0};
    var wg = {
      video:null,
      canvas:null,
      overlay:null,
      gFrameOn: 0,
      inputId : ""
    };

    return {
      renderValue: function(x) {
        if ( typeof(wg_videoInput) === "undefined" ) {
            wg_videoInput = {};
        }
        
        wg.inputId = x.inputId;
        wg_videoInput[x.inputId] = wg; 
        
        el.style.textAlign = "center";
        
        size.h = x.height;
        size.w = x.width;
        
        var scale = Math.min(el.offsetWidth / size.w,  el.offsetHeight / size.h );
        var w = size.w * scale;
        var h = size.h * scale;
        
        init(wg, size, x);
      
        el.append(wg.overlay);
        el.append(wg.video);
        el.append(wg.canvas);
        
      },
      resize: function(width, height) {

        var scale = Math.min(width / size.w,  height / size.h );
        var w = size.w * scale;
        var h = size.h * scale;
        wg.overlay.width = w;
        wg.overlay.height = h;
        wg.video.width = w;
        wg.video.height = h;
        wg.canvas.width = w;
        wg.canvas.height = h;
        
      }
    };
  }
});