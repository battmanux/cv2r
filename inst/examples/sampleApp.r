library(shiny)
library(cv2r)


if ( cv2_available() ) {
    ui <- fluidPage(fluidRow(
        column(4,inputCv2Cam("video")),
        column(4,cv2Output(outputId = "zoom")),
        column(4,cv2Output(outputId = "border"))
    ))
    
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
            input$video[100:200,120:280]
        })
        
        output$border <- renderCv2({
            cv2r$Canny(input$video, 10L, 50L)
        })
    }
    
    if (interactive()) {
        shinyApp(ui, server)
    }
    
}
