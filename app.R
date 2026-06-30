library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)

ui <- dashboardPage(
  dashboardHeader(title = "Аналитический дашборд"),
  dashboardSidebar(
    selectInput("dataset", "Датасет:",
                choices = c("iris", "mtcars", "faithful")),
    selectInput("chart_type", "Тип графика:",
                choices = c("scatter", "bar", "histogram", "boxplot")),
    sliderInput("sample_size", "Размер выборки:",
                min = 10, max = 100, value = 50)
  ),
  dashboardBody(
    fluidRow(
      valueBoxOutput("rows_box"),
      valueBoxOutput("cols_box"),
      valueBoxOutput("unique_box")
    ),
    fluidRow(
      box(title = "График", status = "primary", solidHeader = TRUE,
          width = 8, plotOutput("main_plot", height = 400)),
      box(title = "Статистика", status = "info", solidHeader = TRUE,
          width = 4, verbatimTextOutput("summary_stats"))
    ),
    fluidRow(
      box(title = "Таблица данных", status = "warning", solidHeader = TRUE,
          width = 12, DT::dataTableOutput("data_table"))
    )
  )
)

server <- function(input, output, session) {
  data <- reactive({
    df <- get(input$dataset)
    df[sample(nrow(df), min(input$sample_size, nrow(df))), ]
  })

  output$rows_box <- renderValueBox({
    valueBox(nrow(data()), "Строк", icon = icon("table"), color = "blue")
  })

  output$cols_box <- renderValueBox({
    valueBox(ncol(data()), "Столбцов", icon = icon("columns"), color = "green")
  })

  output$unique_box <- renderValueBox({
    valueBox(length(unique(data()[[1]])), "Уникальных значений", icon = icon("star"), color = "orange")
  })

  output$main_plot <- renderPlot({
    df <- data()
    numeric_cols <- names(df)[sapply(df, is.numeric)]

    if (input$chart_type == "scatter" && length(numeric_cols) >= 2) {
      ggplot(df, aes_string(x = numeric_cols[1], y = numeric_cols[2])) +
        geom_point(color = "steelblue", size = 2, alpha = 0.7) +
        labs(title = paste(numeric_cols[1], "vs", numeric_cols[2])) +
        theme_minimal()
    } else if (input$chart_type == "bar") {
      ggplot(df, aes_string(x = names(df)[1])) +
        geom_bar(fill = "steelblue", alpha = 0.7) +
        labs(title = paste("Распределение", names(df)[1])) +
        theme_minimal()
    } else if (input$chart_type == "histogram" && length(numeric_cols) >= 1) {
      ggplot(df, aes_string(x = numeric_cols[1])) +
        geom_histogram(fill = "steelblue", alpha = 0.7, bins = 15) +
        labs(title = paste("Гистограмма", numeric_cols[1])) +
        theme_minimal()
    } else if (input$chart_type == "boxplot" && length(numeric_cols) >= 1) {
      ggplot(df, aes_string(y = numeric_cols[1])) +
        geom_boxplot(fill = "steelblue", alpha = 0.7) +
        labs(title = paste("Бокс-плот", numeric_cols[1])) +
        theme_minimal()
    }
  })

  output$summary_stats <- renderPrint({
    summary(data())
  })

  output$data_table <- DT::renderDataTable({
    data()
  })
}

shinyApp(ui, server)
