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
cv2Output <- function (outputId, width = "100%", height = "240px", use_svg = FALSE) 
{
  if ( use_svg == TRUE) {
    l_ret <-  div(style="margin-bottom:10px;",
                  htmlwidgets::shinyWidgetOutput(outputId, l_type , width, 
                                                 height))
  } else {
    l_ret <- base64imgOutput(outputId, width = width, height = height)
  }
   
  l_ret 
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
renderCv2 <- function (expr, mat, env = parent.frame(), quoted = FALSE, use_svg=FALSE) 
{

  
  if (missing(expr) && !missing(mat)) {
    lOutput <- htmlwidgets::shinyRenderWidget(imshow(mat = mat, use_svg = use_svg), lOutput, env, quoted = FALSE)
  } else {
    
    if (!quoted) {
      expr <- substitute(expr)
    }
    
    if ( length(grep("imshow", expr)) == 0 ) {
      l_fun <- imshow_decorator
      l_fun[[2]][[3]][[3]] <- expr
      expr <- l_fun
    }
    
    if (use_svg == TRUE) {
      lOutput <- htmlwidgets::shinyRenderWidget(expr, r2d3::d3Output , env, quoted = TRUE)
    } else {
      lOutput <- htmlwidgets::shinyRenderWidget(expr, base64imgOutput, env, quoted = TRUE)
    }
   
  }
  lOutput
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
#' @param flip do we show a mirrored version of the picture in live feedback
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
                        flip = F,
                        auto_send_video = F, 
                        auto_send_audio = F,
                        audio_buff_size = 4096,
                        encoding = "image/jpeg", quality = 0.9,
                        audio=F,
                        overlay_svg) {
  
  if (select_cam == "default") {
    cam_mode  <- ""
  } else if (select_cam == "user" ) {
    cam_mode  <- ', facingMode:  \'user\'  '
  } else {
    cam_mode  <- ', facingMode:  \'environment\'  '
  }
  
  
    l_stream_audio <- ifelse(audio, "true", "false")
    if ( audio ) 
      l_audio_scripts <- list(
        shiny::tags$script(shiny::HTML(paste0(
          "var audio_buff_size = ", audio_buff_size, "\n"))),
        shiny::includeScript(path = system.file('lame.all.js', package = "cv2r", mustWork = T)), 
        shiny::includeScript(path = system.file('cv2r_audio.js', package = "cv2r", mustWork = T))
      )
    else
      l_audio_scripts <- list()
    
    l_flip_style <- "-moz-transform: scale(-1, 1); 
-webkit-transform: scale(-1, 1); -o-transform: scale(-1, 1); transform: scale(-1, 1); filter: FlipH;"
    if ( missing(overlay_svg)) {
      l_overlay <- shiny::HTML("<svg/>")  
    } else {
      l_overlay <- includeHTML(overlay_svg)
    }
    
    shiny::div(
      shiny::tags$script(shiny::HTML(paste(
        "var inputId         = '" ,inputId, "';\n"
      , collapse = "", sep = ""))),
      l_audio_scripts,
      shiny::tags$div(
        shiny::tags$div(id=paste0(inputId, "_overlay"), class="cv2r_input_overlay",
                        style=paste0("position: absolute; z-index:1; width:", width, "px; height:",height,"px;" ),
                        l_overlay),
        shiny::tags$video(id=inputId,
                          width="100%", height="100%", 
                          autoplay="", muted="", class="cv2r_input_video",
                          style=if (!show_live) "display:none;" else if ( flip == T ) l_flip_style else "" )
        ),
        shiny::tags$canvas(id="canvas", width=width, height=height, style=if (!show_captured) "display:none;" else ""),
        shiny::tags$script(shiny::HTML(paste0('
video = document.getElementById("',inputId,'"); // video is the id of video tag
canvas = document.getElementById("canvas") ;

function update_overlay(inputId) {
  v=$("#"+inputId+"_overlay svg");
  if ( v.length > 0 )  {
    overlay = v[0];
  }
  overlay.setAttribute("width", "',width,'");
  overlay.setAttribute("height", "',height,'");
  
  if ( overlay.children.length > 0) {
    $(overlay.children[0].children).each(function(){
            if ( (""+$(this).attr(\'id\')).startsWith("linkToSvg_") ) {
            var href = $(this).attr(\'id\').replace("linkToSvg_", "");
            $(this).bind("click", function() {
             Shiny.setInputValue(inputId+"_load_svg", href);  
            })
      
            }
    });
  
  }
  
}

update_overlay("',inputId,'");

function snap(message) {
  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;
  context = canvas.getContext("2d");
  if (message.width == 0) message.width = video.videoWidth;
  if (message.height == 0) message.height = video.videoHeight;
  context.drawImage(video, message.left, message.top, message.width, message.height);
  imgBase = canvas.toDataURL("',encoding,'", ',quality,');
  Shiny.onInputChange("',inputId,':base64img", { "data": imgBase.replace(/^data:image.*;base64,/, ""), "type": imgBase.replace(/^data:image.(.*);base64,.*/, "$1"), "height":video.videoHeight, "width":video.videoWidth} );
}


constraint = { video: { width: ',width,', height: ',height,' ',cam_mode,' }', ifelse(audio, ', audio: true }', '}'), '

count = 0;    
navigator.mediaDevices.enumerateDevices().then(function(mediaDevices) { 
mediaDevices.forEach(mediaDevice => {
  if (mediaDevice.kind === "videoinput") {
      count += 1 
  } } ) ; 
} ) 
  
if ( count == 1) {
  constraint["video"]["facingMode"] = "default";
}
  
navigator.mediaDevices.getUserMedia(constraint)
.then(function(stream) {
  
  ',ifelse(!audio, '', '
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

Shiny.addCustomMessageHandler("',inputId,'_snap", snap);

auto_send_video = ',ifelse(auto_send_video,"true", "false") ,';

if ( auto_send_video ) {
  setInterval(snap, ',as.integer(1000/fps),');
}
', collapse = "")))
    )
}

#' @export
inputCv2CamSnap <- function(session = session, inputId, top=0, left=0, width=0, height=0) {
  session$sendCustomMessage(paste0(inputId, "_snap"), 
                                   list(left=left,top=top,width=width,height=height))
}

#' Capture picture from webcam
#'
#' @param width    Width of the captured image
#' @param height   Height of the captured image
#' @param flip do we show a mirrored version of the picture in live feedback
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
capture <- function(width=320, height=240, flip = T,
                    encoding = "image/jpeg", 
                    quality = 0.9,
                    overlay_svg) {
  l_output <- NULL
  l_app <- shiny::shinyApp(
    ui = shiny::fluidPage(
      inputCv2Cam("picture", width = width, height, flip = flip,
                  encoding = encoding, quality = quality, overlay_svg = overlay_svg ), 
      shiny::tags$button(
        id="capture", class = "btn btn-primary action-button", 
        onclick = "snap(); setTimeout(function(){window.close();},500);",  "Capture" ) 
    ), 
    server = function(input, output, session) { 
      shiny::observeEvent(
        input$capture, ignoreInit = T, ignoreNULL = T, 
        { l_output <<- input$picture ; shiny::stopApp()  }
        )  
      shiny::observeEvent(input$picture_load_svg, ignoreNULL = T, ignoreInit = T, {
        shiny::removeUI("#picture_overlay svg", immediate = T)
        shiny::insertUI("#picture_overlay", ui = shiny::HTML(readLines(input$picture_load_svg)))
      })
      } )
  
  # if desktop app, run in a browser window
  if (Sys.getenv("RSTUDIO_HTTP_REFERER") == "")
    shiny::runApp(l_app, launch.browser = T)
  else
    shiny::runGadget(l_app)
  
  return(l_output)
}
