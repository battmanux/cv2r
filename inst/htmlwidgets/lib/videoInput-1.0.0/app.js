var gWg = {};
var gFrameOn = 0;
var inputId = "";

function _arrayBufferToBase64( buffer ) {
    var binary = "";
    var bytes = new Uint8Array( buffer );
    var len = bytes.byteLength;
    for (var i = 0; i < len; i++) {
        binary += String.fromCharCode( bytes[ i ] );
    }
    return window.btoa( binary );
}

function audioProcess(audioProcessingEvent) {
    arrayBufferIn = audioProcessingEvent.inputBuffer.getChannelData(0);
    arrayBufferOut = audioProcessingEvent.outputBuffer.getChannelData(0);
    
    var min = Math.min.apply(null, arrayBufferIn);
    var max = Math.max.apply(null, arrayBufferIn);
    
    if ( min < 0.1 && max > 0.1 ) {
      gFrameOn = 2;
    }
    
    if ( gFrameOn === 0 ) {
      Shiny.onInputChange(inputId+"_audio", "" );
    }
    else if ( gFrameOn > 0 ) {
      gFrameOn -= 1;
      
       for(var i=0;i<arrayBufferIn.length;i++) {
          arrayBufferIn[i] = arrayBufferIn[i]*32767.5;
      }
      
      var lBuff = [];
      var mp3Tmp = mp3encoder.encodeBuffer(arrayBufferIn); //encode mp3
      lBuff.push(new Int8Array(mp3Tmp) );
      mp3Tmp = mp3encoder.flush();
      lBuff.push(new Int8Array(mp3Tmp) );

      var c = new Int8Array(lBuff[0].length + lBuff[1].length);
      c.set(lBuff[0]);
      c.set(lBuff[1], lBuff[0].length);

      var base64buff = _arrayBufferToBase64(c.buffer);
      Shiny.onInputChange(inputId+"_audio", base64buff );
    }
}
         
function update_overlay(wg, inputId, width, height) {

  var svg = wg.overlay.children[0];
  
  
  svg.setAttribute("width", width);
  svg.setAttribute("height", height);
  
  if ( svg.children.length > 0) {
    $(svg.children[0].children).each(function(){
            if ( (""+$(this).attr('id')).startsWith("linkToSvg_") ) {
                var href = $(this).attr('id').replace("linkToSvg_", "");
                
                $(this).bind("click", function() {
                    Shiny.setInputValue(inputId+"_load_svg", href);  
                });
            }
    });
  
  }
  
}

function snap(message) {
    
  if ( message === undefined ) message = {
      "width":0,
      "height":0,
      "left":0,
      "top":0, 
      "encoding":"image/jpeg",
      "quality":0.9,
      "auto_send_video" : false
      };
      
  if (message.width === 0) message.width = gWg.video.videoWidth;
  if (message.height === 0) message.height = gWg.video.videoHeight;

  var context = gWg.canvas.getContext("2d");

  gWg.canvas.width = gWg.video.videoWidth;
  gWg.canvas.height = gWg.video.videoHeight;
  context.drawImage(gWg.video, 0, 0, gWg.video.videoWidth, gWg.video.videoHeight);
  
  var imageData = context.getImageData(message.left, message.top, message.width, message.height);

  gWg.canvas.width = message.width;
  gWg.canvas.height = message.height;
  context.putImageData(imageData, 0, 0);

  var imgBase = gWg.canvas.toDataURL(message.encoding, message.quality);
  Shiny.onInputChange(inputId+":base64img", {
      "data":   imgBase.replace(/^data:image.*;base64,/, ""),
      "type":   imgBase.replace(/^data:image.(.*);base64,.*/, "$1"), 
      "height": gWg.video.videoHeight, 
      "width":  gWg.video.videoWidth
  } );
}

function init_capture(wg, size, x) {

    constraint = { video: { "width": x.width, "height": x.height } };
    if ( x.use_audio === true ) {
      constraint.audio = true;
    }
    
    count = 0;    
    navigator.mediaDevices.enumerateDevices().then(function(mediaDevices) { 
        mediaDevices.forEach(mediaDevice => {
          if (mediaDevice.kind === "videoinput") {
              count += 1; 
          } } ) ; 
    } );
      
    if ( count == 1) {
      constraint.video.facingMode = "default";
    } else if ( count > 1 ) {
        constraint.video.facingMode = camera_mode;
    } else {
        console.log("No video available!");
    }
      
    navigator.mediaDevices.getUserMedia(constraint).then(function(stream) {
        
        if (x.use_audio === true) {
            var microphone = audioCtx.createMediaStreamSource(stream);
            microphone.connect(wg.scriptNode);
            scriptNode.connect(wg.audioCtx.destination);
        }
        
      wg.video.srcObject = stream;
      wg.video.play();
    
    }).catch(function(err) {
      console.log("An error occurred! " + err);
    });
    
    if ( x.auto_send_video ) {
      setInterval(snap, 1000 / x.fps);
    }
}
    
function init(wg, size, x) {
    
    inputId = x.inputId;
    gWg = wg;
    
    if ( x.audio === true ) {
      wg.audioCtx = new AudioContext();
      wg.scriptNode = audioCtx.createScriptProcessor(audio_buff_size, 1, 1);
      wg.scriptNode.onaudioprocess =  audioProcess;
      wg.mp3encoder = new lamejs.Mp3Encoder(1, 44100, 64); 
    }
    
    wg.overlay = document.createElement("div");
    wg.overlay.id = x.inputId+"_overlay";
    wg.overlay.class = "cv2r_input_overlay";
    wg.overlay.width = size.w;
    wg.overlay.height = size.h;
    wg.overlay.style = "position: absolute; z-index:1;";
    wg.overlay.append(document.createElement("svg"));
    
    if ( x.flip === true ) {
          l_flip_style = "-moz-transform: scale(-1, 1); "+ 
                          "-webkit-transform: scale(-1, 1);"+
                          " -o-transform: scale(-1, 1); transform: scale(-1, 1);"+
                          " filter: FlipH;";
    } else {
      l_flip_style = "";
    }
    
    if ( ! x.show_live ) {
      l_style = "display=none;" ;
    } else if ( x.flip === true ) {
      l_style = l_flip_style;
    }  else { 
     l_style = "" ;
    }
    
    wg.video = document.createElement("video");
    wg.video.id = inputId+"_video";
    wg.video.height = size.h;
    wg.video.width = size.w;
    wg.video.autoplay="";
    wg.video.muted="";
    wg.video.class="cv2r_input_video";
    wg.video.style= l_style;
    
    wg.canvas = document.createElement("canvas");
    wg.canvas.id = inputId+"_canvas";
    wg.canvas.height = size.h;
    wg.canvas.width = size.w;
    
    if ( ! x.show_captured ) {
      wg.canvas.style="display:none;";
    }
    
    if ( HTMLWidgets.shinyMode === true ) {
        init_capture(wg, size, x);
        update_overlay(wg, size.w, size.h );
        Shiny.addCustomMessageHandler(inputId+'_snap', snap);
    }
        
}