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
    l_env <- new.env(parent = env)
    assign("mat", mat, l_env)
    lOutput <- htmlwidgets::shinyRenderWidget(imshow(mat = mat, use_svg = F), base64imgOutput, l_env, quoted = FALSE)
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

  if ( missing(overlay_svg)) {
    l_overlay <- shiny::HTML("<svg/>")  
  } else {
    l_overlay <- includeHTML(overlay_svg)
  }
    
  x <- list(
    inputId=inputId,
    width=width,
    height=height,
    fps=fps, 
    show_live=show_live,
    show_captured = show_captured, 
    select_cam = select_cam,
    flip = flip,
    auto_send_video = auto_send_video, 
    auto_send_audio = auto_send_audio,
    audio_buff_size = audio_buff_size,
    video_encoding = encoding,
    video_quality = quality,
    use_audio=audio,
    overlay_svg=l_overlay
  )
  
  htmlwidgets::createWidget("videoInput", package = "cv2r",
                            x,  width = width, height = height)
  
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
                    select_cam = "default",
                    overlay_svg) {
  l_output <- NULL
  l_app <- shiny::shinyApp(
    ui = shiny::fluidPage(
      inputCv2Cam("picture", width = width, height, flip = flip,
                  encoding = encoding, quality = quality, overlay_svg = overlay_svg, select_cam = select_cam ), 
      shiny::tags$button(
        id="capture", class = "btn btn-primary action-button", 
        onclick = "wg_videoInput['picture'].snap(); setTimeout(function(){window.close();},500);",  "Capture" ) 
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


#' @export
videoInputPlay <- function(session, inputId, audio) {
  session$sendCustomMessage(
    paste0(inputId,"_play"),
    list(
      buffer = base64enc::base64encode( 
        writeBin(
          as.integer(audio),
          raw(0),
          size = 4)
      ) 
    ) 
  )
}
