function _arrayBufferToBase64( buffer ) {
    var binary = "";
    var bytes = new Uint8Array( buffer );
    var len = bytes.byteLength;
    for (var i = 0; i < len; i++) {
        binary += String.fromCharCode( bytes[ i ] );
    }
    return window.btoa( binary );
}

function _base64ToArrayBuffer(base64) {
    var binary_string = window.atob(base64);
    var len = binary_string.length;
    var bytes = new Uint8Array(len);
    for (var i = 0; i < len; i++) {
        bytes[i] = binary_string.charCodeAt(i);
    }
    return bytes.buffer;
}

function createAudioProcess(wg) {
  return(function(audioProcessingEvent) {
    arrayBufferIn = audioProcessingEvent.inputBuffer.getChannelData(0);
    arrayBufferOut = audioProcessingEvent.outputBuffer.getChannelData(0);

    //for(var i=0;i<arrayBufferOut.length;i++) {
    //  arrayBufferOut[i] += arrayBufferIn[i];
    //}
    
    if (wg.playbuffer.length > 0) {
      l_buf = wg.playbuffer.pop();
      var minLen = Math.min(l_buf.length, arrayBufferOut.length);
      for(var i=0;i<minLen;i++) {
        arrayBufferOut[i] += l_buf[i]/32767.5;
      }
    }
    
    var min = Math.min.apply(null, arrayBufferIn);
    var max = Math.max.apply(null, arrayBufferIn);
    var mp3Tmp;
    var base64buff;
    
    if ( min < 0.1 && max > 0.1 ) {
      if ( wg.gFrameOn <= 0 ) {
        wg.gFrameOn = 2;
      } else {
        wg.gFrameOn += 1;
      }
    }

    wg.gFrameOn -= 1;
    
    if ( wg.gFrameOn === 0 ) {
      // close file
      mp3Tmp = wg.mp3encoder.flush();
      base64buff = _arrayBufferToBase64(mp3Tmp);
      Shiny.onInputChange(wg.inputId+"_audio:mp3base64", base64buff, {priority: "event"} );
    }
    else if ( wg.gFrameOn > 0 ) {
      for(var i=0;i<arrayBufferIn.length;i++) {
        arrayBufferIn[i] = arrayBufferIn[i]*32767.5;
      }
      
      mp3Tmp = wg.mp3encoder.encodeBuffer(arrayBufferIn); //encode mp3
      base64buff = _arrayBufferToBase64(mp3Tmp);
      Shiny.onInputChange(wg.inputId+"_audio:mp3base64", base64buff, {priority: "event"} );
    } else {
      
    }
    
  });
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

function createPlay(wg) {
  return(function(message) {
    var l_buf = _base64ToArrayBuffer(message.buffer);
    var dataAsInt32Array = new Int32Array(l_buf);
    var chunks = dataAsInt32Array.length / 4096;
    for ( i=0; i<chunks; i+=1) {
      wg.playbuffer.unshift(dataAsInt32Array.slice(4096*i,4096*(i+1)) );      
    }
  });
}

function createSnap(wg) {
  return(function(message) {
  
    if ( message === undefined ) message = {
        "width":0,
        "height":0,
        "left":0,
        "top":0, 
        "encoding":"image/jpeg",
        "quality":0.9,
        "auto_send_video" : false,
        };
    
    if ( message.width === 0 ) message.width = wg.video.videoWidth;
    if ( message.height === 0 ) message.height = wg.video.videoHeight;
    
    var context = wg.canvas.getContext("2d");
  
    wg.canvas.width = wg.video.videoWidth;
    wg.canvas.height = wg.video.videoHeight;
    context.drawImage(wg.video, 0, 0, wg.video.videoWidth, wg.video.videoHeight);
    
    var imageData = context.getImageData(message.left, message.top, message.width, message.height);
  
    wg.canvas.width = message.width;
    wg.canvas.height = message.height;
    context.putImageData(imageData, 0, 0);
  
    var imgBase = wg.canvas.toDataURL(message.encoding, message.quality);
    Shiny.onInputChange(wg.inputId+":base64img", {
        "data":   imgBase.replace(/^data:image.*;base64,/, ""),
        "type":   imgBase.replace(/^data:image.(.*);base64,.*/, "$1"), 
        "height": wg.video.videoHeight, 
        "width":  wg.video.videoWidth
    }, {priority: "event"} );
  });
}

function init_capture(wg, size, x) {

    constraint = { video: { "width": x.width, "height": x.height } };
    if ( x.use_audio === true ) {
      constraint.audio = true;
    }
    
    var count = 0;
    wg.devices = [];
    navigator.mediaDevices.enumerateDevices().then(function(mediaDevices) { 
        mediaDevices.forEach(mediaDevice => {
          if (mediaDevice.kind === "videoinput") {
              count += 1;
              wg.devices.push(mediaDevice.deviceId);
          } } ) ; 
          
          var reg = /^\d+$/;
          if ( wg.devices.length === 1) {
            constraint.video.facingMode = "default";
          } else if ( wg.devices.length > 1 ) {
            if ( reg.test(x.select_cam) ) {
              constraint.video.deviceId = wg.devices[parseInt(x.select_cam)];
            } else {
              constraint.video.facingMode = x.select_cam;
            }
          } else {
              console.log("No video available!");
          }
            
          navigator.mediaDevices.getUserMedia(constraint).then(function(stream) {
              
            console.log("found video for "+wg.inputId);
                
            wg.video.srcObject = stream;
            wg.video.onloadedmetadata = function(e) {
              wg.video.play();
              wg.video.muted = true;
            };
            
            if (x.use_audio === true) {
                console.log("audio for "+wg.inputId);
                wg.audioCtx = new AudioContext();
                wg.scriptNode = wg.audioCtx.createScriptProcessor(x.audio_buff_size*2, 1, 1);
                wg.scriptNode.onaudioprocess =  createAudioProcess(wg);
                wg.mp3encoder = new lamejs.Mp3Encoder(1, 44100, 128); 
                var microphone = wg.audioCtx.createMediaStreamSource(stream);
                microphone.connect(wg.scriptNode);
                wg.scriptNode.connect(wg.audioCtx.destination);
            }
            
          }).catch(function(err) {
            console.log("An error occurred! " + err);
          });
          
          if ( x.auto_send_video ) {
            setInterval(wg.snap, 1000 / x.fps);
          }
    } );
    
}
    
function vi_init(wg, size, x) {
    
    inputId = x.inputId;
    
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
      l_style = "display:none;" ;
    } else if ( x.flip === true ) {
      l_style = l_flip_style;
    }  else { 
     l_style = "" ;
    }
    
    wg.video = document.createElement("video");
    wg.video.id = x.inputId+"_video";
    wg.video.height = size.h;
    wg.video.width = size.w;
    wg.video.autoplay="";
    wg.video.muted="";
    wg.video.class="cv2r_input_video";
    wg.video.style= l_style;
    
    wg.canvas = document.createElement("canvas");
    wg.canvas.id = x.inputId+"_canvas";
    wg.canvas.height = size.h;
    wg.canvas.width = size.w;
    
    if ( ! x.show_captured ) {
      wg.canvas.style="display:none;";
    }
    
    wg.playbuffer = [];
    wg.snap = createSnap(wg);
    wg.play = createPlay(wg);
    
    if ( HTMLWidgets.shinyMode === true ) {
        init_capture(wg, size, x);
        update_overlay(wg, size.w, size.h );
        Shiny.addCustomMessageHandler(x.inputId+'_snap', wg.snap);
        Shiny.addCustomMessageHandler(x.inputId+'_play', wg.play);
    }
}