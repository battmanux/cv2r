library(shiny)
library(cv2r)

if ( cv2_available()) {
    ui <- fluidPage(
        includeScript(system.file("OggVorbisEncoder.min.js", package = "cv2r")),
        inputCv2Cam("video", audio = T, fps = 1),
        cv2Output(outputId = "zoom"),
        textOutput("level"),
        actionButton(inputId = "snap", label = "Snap"),
        actionButton(inputId = "audio_snap", label = "Snap Audio"),
        plotlyOutput("plot"),
        sliderInput("level", label = "seuil", min = 0, max = 1, step = 0.1, value = 0.3)
    )
    
    server <- function(input, output, session) {
        
        
        observeEvent(input$audio_snap, {
            
            l_x <- base64enc::base64decode(what = input$video_audio)
            o <- readBin(l_x, "double", size = 4, n = 50000)
            
            output$plot <- renderPlotly({
                ggplotly(ggplot() + geom_line(aes(x=seq_along(o), y = o )))
                })
        })
        
        observeEvent(input$snap, {
            session$sendCustomMessage("video_snap", list(x=0,y=0,w=-1,h=-1))
        })
        
        output$zoom <- renderCv2({
            img <- input$video
            
            if (is.null(img))
                return(NULL)
            
            imshow("id", input$video) })
        
    }
    
    shinyApp(ui, server)
    
}



