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
#' @param encoding Picture encoding over HTTP
#' @param quality  Encoding quality (if encoding = image/jpeg)
#'
#' @return A WebCam capture control that can be added to a UI definition
#' @export
#'
#' @example inst/examples/sampleApp.r
#'
inputCv2Cam <- function(inputId, width=320, height=240, fps=6, show_live=F, show_captured = T, encoding = "image/jpeg", quality = 0.9) {
    shiny::div(
        shiny::tags$video(id=inputId, width=width, height=height, style=if (!show_live) "display:none;" else ""),
        shiny::tags$canvas(id="canvas", width=width, height=height, style=if (!show_captured) "display:none;" else ""),
        shiny::tags$script(shiny::HTML(paste0('
$(document).ready(function(){
  let video = document.getElementById("',inputId,'"); // video is the id of video tag
  navigator.mediaDevices.getUserMedia({ video: { width: ',width,', height: ',height,' }, audio: false })
  .then(function(stream) {
    video.srcObject = stream;
    video.play();
  })
  .catch(function(err) {
    console.log("An error occurred! " + err);
  });


  function snap() {
    var canvas = document.getElementById("canvas") 
    context = canvas.getContext("2d")
    context.drawImage(video, 0, 0, ',width,', ',height,');
    imgBase = canvas.toDataURL("',encoding,'", ',quality,')
    Shiny.onInputChange("',inputId,':base64img", imgBase.replace(/^data:image.*;base64,/, ""))
  }

  setInterval(snap, ',as.integer(1000/fps),');

});

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
  np      <- reticulate::import("numpy", convert = F)
  l_array <- np$frombuffer(l_array, dtype = np$uint8)  
  
  l_mat <- cv2r$imdecode(l_array, -1L)
  
  l_mat
}
