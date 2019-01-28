#' Shiny bindings for OpenCV
#' 
#' Output and render functions for using OpenCV within Shiny applications and interactive Rmd documents
#'
#' @param outputId output variable to write in
#' @param width    Must be a valid CSS unit (like '400px', 'auto', ...) or a number, which will be coerced to a string and have 'px' appended.
#' @param height   Must be a valid CSS unit (like '400px', 'auto', ...) or a number, which will be coerced to a string and have 'px' appended.
#'
#' @return output widget
#' @export
#'
#' @example inst/examples/sampleApp.r
#' 
#' 
cv2Output <- function (outputId, width = "320", height = "240px") 
{
  htmlwidgets::shinyWidgetOutput(outputId, "r2d3", width, 
                                 height)
}
  

#' Shiny bindings for OpenCV
#'
#' @param expr An expression that plots a OpenCV image (see [imshow()])
#' @param env  The environment in which to evaluate expr
#' @param quoted Is expr a quoted expression (with quote())? This is useful if you want to save an expression in a variable
#'
#' @export
#' 
#' @example inst/examples/sampleApp.r
#'  
renderCv2 <- function (expr, env = parent.frame(), quoted = FALSE) 
{
  if (!quoted) {
    expr <- substitute(expr)
  }
  htmlwidgets::shinyRenderWidget(expr, r2d3::d3Output, env, quoted = TRUE)
}


#' Capture WebCam as OpenCV Mat
#' 
#' Add this component to a shiny ui and you will be able to access captured image through input$<inputId> 
#'
#' @param inputId  The input slot that will be used to access the value
#' @param width    Width of the captured image
#' @param height   Height of the captured image
#' @param fps      Frames per secondes
#' @param show_live  Shall we show webcam stream
#' @param show_captured  Shall we show the captured image
#' @param select_cam  Prefered camera on smartphone (user or environment, default)
#' @param auto_send_video Send video picture every fps
#' @param auto_send_audio Send audio buffer every audio_buff_size
#' @param encoding Picture encoding over HTTP
#' @param quality  Encoding quality (if encoding = image/jpeg)
#'
#' @return A WebCam capture control that can be added to a UI definition
#' @export
#'
#' @example inst/examples/sampleApp.r
#'
inputCv2Cam <- function(inputId, 
                        width=320, height=240, fps=15, 
                        show_live=T, show_captured = F, 
                        select_cam = "default",
                        auto_send_video = F, 
                        auto_send_audio = T,
                        audio_buff_size = 4096,
                        encoding = "image/jpeg", quality = 0.9,
                        audio=F) {
  
  if (select_cam == "default") {
    cam_mode  <- ""
  } else if (select_cam == "user" ) {
    cam_mode  <- ', facingMode:  \'user\'  '
  } else {
    cam_mode  <- ', facingMode:  \'environment\'  '
  }
  
  
    l_stream_audio <- ifelse(audio, "true", "false")
    if ( audio ) 
      l_go_bt <- shiny::actionButton(inputId = "go", label = "Start Audio Feedback")
    else
      l_go_bt <- list()
    
    shiny::div(
        l_go_bt,
        shiny::tags$video(id=inputId, width=width, height=height, autoplay="", muted="", style=if (!show_live) "display:none;" else ""),
        shiny::tags$canvas(id="canvas", width=width, height=height, style=if (!show_captured) "display:none;" else ""),
        shiny::tags$script(shiny::HTML(paste0('
audioCtx = new AudioContext();
scriptNode = audioCtx.createScriptProcessor(',audio_buff_size,', 1, 1);
video = document.getElementById("',inputId,'"); // video is the id of video tag
canvas = document.getElementById("canvas") 
gAudioBuffer = [];

function _arrayBufferToBase64( buffer ) {
    var binary = "";
    var bytes = new Uint8Array( buffer );
    var len = bytes.byteLength;
    for (var i = 0; i < len; i++) {
        binary += String.fromCharCode( bytes[ i ] );
    }
    return window.btoa( binary );
}

scriptNode.onaudioprocess = function(audioProcessingEvent) {
    arrayBufferIn = audioProcessingEvent.inputBuffer.getChannelData(0);
    arrayBufferOut = audioProcessingEvent.outputBuffer.getChannelData(0)
    
    base64buff = _arrayBufferToBase64(arrayBufferIn.buffer);
  
    Shiny.onInputChange("',inputId,'_audio", base64buff );
  
    if ( gAudioBuffer.length > 0 ) {

      for (var sample = 0; sample < gAudioBuffer.length; sample++) {
        // make output equal to the same as the input
        arrayBufferOut[sample] = gAudioBuffer[sample];
      }

      gAudioBuffer = [];
    }
    
    }


start = function(){
      
  constraint = { video: { width: ',width,', height: ',height,' ',cam_mode,' }', ifelse(audio, ', audio: true }', '}'), '
  
  count = 0;    
  navigator.mediaDevices.enumerateDevices().then(function(mediaDevices) { 
  mediaDevices.forEach(mediaDevice => {
    if (mediaDevice.kind === "videoinput") {
        count += 1 
    } } ) ; 
    console.log(count) } ) 
    
  if ( count == 1) {
    constraint["video"]["facingMode"] = "default";
  }
    
  navigator.mediaDevices.getUserMedia(constraint)
  .then(function(stream) {
    
    ',ifelse(!audio, '', '
  go.addEventListener("click", function() {
    if ( video.muted == false ) 
      video.muted = true;
    else
      video.muted = false;
  });
  
    microphone = audioCtx.createMediaStreamSource(stream);
 
    microphone.connect(scriptNode);
    scriptNode.connect(audioCtx.destination);
    '),'
    video.srcObject = stream;

    video.play();
  })
  .catch(function(err) {
    console.log("An error occurred! " + err);
  });

  function snap(message) {
    console.log(message);
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    context = canvas.getContext("2d")
    context.drawImage(video, 0, 0, video.videoWidth, video.videoHeight);
    imgBase = canvas.toDataURL("',encoding,'", ',quality,')
    Shiny.onInputChange("',inputId,':base64img", imgBase.replace(/^data:image.*;base64,/, ""))
  }

  Shiny.addCustomMessageHandler("',inputId,'_snap", snap);

  function audio_play(message) {
  
  }

  Shiny.addCustomMessageHandler("',inputId,'_audio_play", audio_play);

  auto_send_video = ',ifelse(auto_send_video,"true", "false") ,';

  if ( auto_send_video ) {
    setInterval(snap, ',as.integer(1000/fps),');
  }

};



  start();

', collapse = "")))
    )
}

#' Request a picture to a inputCv2Cam
#'
#' @param session shny session
#' @param inputId inputCv2Cam inputId
#' @param crop crop picture before sending
#'
#' @return no return. input$[inputId] will contain the new frame
#' @export
#'
cv2rInputSnap <- function(session, inputId, crop = list(x=0,y=0,w=-1,h=-1)) {
  session$sendCustomMessage("video_snap", crop)
}

# convert base64 string into an OpenCV Mat (numpy.ndarray)
#
# @param data base64 string
# @param ... 
#
# @return
base64img2ndarray <- function(data, ...) {
  l_png <- base64enc::base64decode(what = data)
  l_mat <- cv2r$imdecode(reticulate::np_array(as.integer(l_png), dtype = "uint8"), -1L)
  l_mat
}