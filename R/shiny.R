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
  

imshow_decorator <- quote({ lf_out <- function() { } ; imshow(mat=lf_out()) }  )

#' Shiny bindings for OpenCV
#'
#' @param expr An expression that plots a OpenCV image (see [imshow()])
#' @param mat  an opencv mat
#' @param env  The environment in which to evaluate expr
#' @param quoted Is expr a quoted expression (with quote())? This is useful if you want to save an expression in a variable
#'
#' @export
#' 
#' @example inst/examples/sampleApp.r
#'  
renderCv2 <- function (expr, mat, env = parent.frame(), quoted = FALSE) 
{
  
  if (missing(expr) && !missing(mat)) {
    htmlwidgets::shinyRenderWidget(imshow(mat = mat), r2d3::d3Output, env, quoted = FALSE)
  } else {
    
    if (!quoted) {
      expr <- substitute(expr)
    }
    
    if ( length(grep("imshow", expr)) == 0 ) {
      l_fun <- imshow_decorator
      l_fun[[2]][[3]][[3]] <- expr
      expr <- l_fun
    }
    
    htmlwidgets::shinyRenderWidget(expr, r2d3::d3Output, env, quoted = TRUE)
  }
  
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
                        auto_send_video = T, 
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
        includeScript(path = system.file('lame.all.js', package = "cv2r", mustWork = T)),
        shiny::tags$script(shiny::HTML(paste0('
audioCtx = new AudioContext();
scriptNode = audioCtx.createScriptProcessor(',audio_buff_size,', 1, 1);
video = document.getElementById("',inputId,'"); // video is the id of video tag
canvas = document.getElementById("canvas") 
//gAudioBuffer = [];

var mp3encoder = new lamejs.Mp3Encoder(1, 44100, 64); 

function _arrayBufferToBase64( buffer ) {
    var binary = "";
    var bytes = new Uint8Array( buffer );
    var len = bytes.byteLength;
    for (var i = 0; i < len; i++) {
        binary += String.fromCharCode( bytes[ i ] );
    }
    return window.btoa( binary );
}

var gFrameOn = 0;

scriptNode.onaudioprocess = function(audioProcessingEvent) {
    arrayBufferIn = audioProcessingEvent.inputBuffer.getChannelData(0);
    arrayBufferOut = audioProcessingEvent.outputBuffer.getChannelData(0)
    
    var min = Math.min.apply(null, arrayBufferIn);
    var max = Math.max.apply(null, arrayBufferIn);
    
    if ( min < 0.1 && max > 0.1 ) {
      gFrameOn = 2;
    }
    
    if ( gFrameOn == 0 ) {
      Shiny.onInputChange("',inputId,'_audio", "" );
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
      Shiny.onInputChange("',inputId,'_audio", base64buff );
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

#' Capture picture from webcam
#'
#' @param width    Width of the captured image
#' @param height   Height of the captured image
#' @param encoding Picture encoding over HTTP
#' @param quality  Encoding quality (if encoding = image/jpeg)
#'
#' @return "numpy.ndarray"
#' @export
#'
#' @examples
#' 
#' if (interactive()) {
#' 
#'     l_imge <- capture()
#' 
#' }
#' 
capture <- function(width=320, height=240, encoding = "image/jpeg", quality = 0.9) {
  l_output <- NULL
  l_app <- shiny::shinyApp(ui = shiny::fluidPage(inputCv2Cam("picture", width = width, height, encoding = encoding, quality = quality ), shiny::tags$button(
    id="capture", class = "btn btn-primary action-button", 
    onclick = "setTimeout(function(){window.close();},500);",  "Capture" ) 
    ), 
    server = function(input, output, session) { shiny::observeEvent(input$capture, ignoreInit = T, ignoreNULL = T, { l_output <<- input$picture ; shiny::stopApp()  })  } )
  
  # if desktop app, run in a browser window
  if (Sys.getenv("RSTUDIO_HTTP_REFERER") == "")
    shiny::runApp(l_app, launch.browser = T)
  else
    shiny::runGadget(l_app)
  
  return(l_output)
}

# convert base64 string into an OpenCV Mat (numpy.ndarray)
#
# @param data base64 string
# @param ... 
#
# @return
base64img2ndarray <- function(data, ...) {

  l_array <- base64enc::base64decode(data)
  l_array <- np$frombuffer(l_array, dtype = np$uint8)  
  
  l_mat <- cv2r$imdecode(l_array, -1L)
  
  l_mat
}
