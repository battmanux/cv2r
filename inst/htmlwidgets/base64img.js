HTMLWidgets.widget({
  name: "base64img",
  type: "output",
  factory: function(el, width, height) {
    return {
      renderValue: function(x) {
        el.style.textAlign = "center";
        txt = '<img style="height: 100%;" src="data:image/' 
                        + x.type + ';base64,' 
                        + x.data + '" />' ;
        el.innerHTML = txt;
      },
      resize: function(width, height) {}
    };
  }
});