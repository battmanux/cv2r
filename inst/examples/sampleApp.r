library(shiny)
library(cv2r)
library(ggplot2)
library(bioacoustics)

if ( cv2_available() ) {
    ui <- fluidPage(fluidRow(
        actionButton(inputId = "snap", label = "Take"),
        actionButton(inputId = "snap2", label = "Take2")),
        fluidRow(
          column(3,inputCv2Cam("capture",
                               auto_send_audio = T, audio = T)),
          column(3,plotOutput(outputId = "plot")),
          column(3,cv2Output(outputId = "zoom")),
          column(3,cv2Output(outputId = "border"))
    ),
    fluidRow(column(12, plotOutput(outputId = "fullplot"))))
    
    server <- function(input, output, session) {
        
        full_data <- numeric(0)
        
        observeEvent(input$capture_audio, {
        
            l_data_sel <- input$capture_audio
            
            output$plot <- renderPlot({
                ggplot() +
                    geom_line(aes(x=seq_along(l_data_sel), y = l_data_sel )) + 
                    theme_minimal()
            })
            
            output$fullplot <- renderPlot({
                spectro(tuneR::Wave(left = input$capture_audio, bit=16, samp.rate=44100),
                        flim = c(0, 4000),
                        FFT_size = 1024  )
                })
            
        })
        
        observeEvent(input$snap, {
          inputCv2CamSnap(session, "capture")
        })

        observeEvent(input$snap2, {
          inputCv2CamSnap(session, "capture", top = 100, left = 100, width = 200, height = 100)
        })
        
                
        output$zoom <- renderCv2({
            input$capture[5:200,5:200]
        }, use_svg = T)
        
        output$border <- renderCv2({
            imshow(mat = cv2r$Canny(input$capture, 10L, 50L) )
        })
    }
    
    if (interactive()) {
      shinyApp(ui, server)
    }
    
}

