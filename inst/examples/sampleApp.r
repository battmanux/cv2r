library(shiny)
library(cv2r)
library(ggplot2)
library(bioacoustics)

if ( cv2_available() ) {
    ui <- fluidPage(fluidRow(
        actionButton(inputId = "snap", label = "Take"),
        actionButton(inputId = "snap2", label = "Take2")),
        fluidRow(
          column(3,inputCv2Cam("video", auto_send_video = F, fps = 5,
                               auto_send_audio = T, audio = T, 
                               audio_buff_size = 4096*4)),
          column(3,plotOutput(outputId = "plot")),
          column(3,cv2Output(outputId = "zoom", width = "100%")),
          column(3,cv2Output(outputId = "border"))
    ),
    fluidRow(column(12, plotOutput(outputId = "fullplot"))))
    
    server <- function(input, output, session) {
        
        full_data <- numeric(0)
        
        observeEvent(input$video_audio, {
            
            if (is.null(input$video_audio) || nchar(input$video_audio) < 10) {
                output$plot <- renderPlot(NULL)
                full_data <<- numeric(0)
            } else {
                l_x <- base64enc::base64decode(what = input$video_audio)
                writeBin(l_x, size = 1,  con = "out.mp3")
                l_wave <- tuneR::readMP3("out.mp3")
                
                l_data_sel <- l_wave@left[1366:length(l_wave@left)]
                full_data <<- c(full_data, l_data_sel)
                
                output$plot <- renderPlot({
                    ggplot() +
                        geom_line(aes(x=seq_along(l_data_sel), y = l_data_sel )) + 
                        theme_minimal()
                })
                
                output$fullplot <- renderPlot({
                    spectro(tuneR::Wave(left = full_data, bit=16, samp.rate=44100),
                            flim = c(0, 4000),
                            FFT_size = 1024  )
                    })
                
            } 
        })
        
        observeEvent(input$snap, {
          inputCv2CamSnap(session, "video")
        })

        observeEvent(input$snap2, {
          inputCv2CamSnap(session, "video", top = 100, left = 100, width = 200, height = 100)
        })
        
                
        output$zoom <- renderCv2({
            input$video[50:50,120:280]
        }, use_svg = T)
        
        output$border <- renderCv2({
            imshow(mat = cv2r$Canny(input$video, 10L, 50L) )
        })
    }
    
    if (interactive()) {
      
    }
    
}
shinyApp(ui, server)
