HTMLWidgets.widget({
  name: "base64img",
  type: "output",
  factory: function(el, width, height) {
    var size = {w:0,h:0};
    return {
      renderValue: function(x) {
        el.style.textAlign = "center";
        
        size.h = x.height;
        size.w = x.width;
        
        var scale = Math.min(el.offsetWidth / size.w,  el.offsetHeight / size.h );
        var w = size.w * scale;
        var h = size.h * scale;
        
        txt = '<img style="max-height:100%; max-width:100%;image-rendering:optimize-contrast;image-rendering:crisp-edges;image-rendering:pixelated;" width="'+w+'px" height="'+h+'px" src="data:image/' 
                        + x.type + ';base64,' 
                        + x.data + '" />' ;
        el.innerHTML = txt;
      },
      resize: function(width, height) {

        var scale = Math.min(width / size.w,  height / size.h );
        var w = size.w * scale;
        var h = size.h * scale;
        el.children[0].width = w;
        el.children[0].height = h;
        
      }
    };
  }
});