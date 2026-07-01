library(shiny)
library(dplyr)
library(DT)

anime_df <- read.csv("anime_data.csv", stringsAsFactors = FALSE)
anime_df$score[is.na(anime_df$score)] <- 0
anime_df$year[is.na(anime_df$year)] <- 0
anime_df$display_id <- ifelse(is.na(anime_df$id) | anime_df$id == "", seq_len(nrow(anime_df)), anime_df$id)
if (!"image_url" %in% names(anime_df)) anime_df$image_url <- ""
if (!"synopsis" %in% names(anime_df)) anime_df$synopsis <- ""

showAnimeModal <- function(r) {
  img_html <- if (!is.null(r$image_url) && nchar(r$image_url) > 0) {
    tags$img(src = r$image_url, style = "width:100%; height:300px; object-fit:cover; border-radius:10px 10px 0 0;",
             onerror = "this.style.display='none';this.nextElementSibling.style.display='flex';")
  } else {
    div(style = "width:100%;height:300px;background:#1a1a2e;display:flex;align-items:center;justify-content:center;color:#333;font-size:60px;border-radius:10px 10px 0 0;", "?")
  }
  modal_fallback <- if (!is.null(r$image_url) && nchar(r$image_url) > 0) {
    div(style = "width:100%;height:300px;background:#1a1a2e;display:flex;align-items:center;justify-content:center;color:#333;font-size:60px;border-radius:10px 10px 0 0;display:none;", "?")
  } else { NULL }
  genre_html <- paste(sapply(unlist(strsplit(r$genres, ", ")), function(g) {
    paste0('<span style="background:rgba(233,69,96,0.2);color:#e94560;padding:4px 10px;border-radius:15px;font-size:12px;margin:2px;display:inline-block;">', trimws(g), '</span>')
  }), collapse = "")
  detail <- function(label, value) {
    div(style = "margin-bottom:8px;",
        tags$span(style = "color:#888;font-size:12px;", label), tags$br(),
        tags$span(style = "color:#e0e0e0;font-size:14px;font-weight:600;", value))
  }

  showModal(modalDialog(
    tags$head(tags$style(HTML("
      .modal-content { background:#16213e; color:#e0e0e0; border-radius:15px; max-width:700px; overflow:hidden; }
      .modal-header { background:none; border:none; padding:0; }
      .modal-body { padding:20px 25px; }
      .modal-footer { border-top:1px solid #1a1a2e; padding:10px 25px; }
      .modal-footer .btn-default { background:#333; color:#e0e0e0; border:none; }
      .modal-close { position:absolute; top:10px; right:15px; background:rgba(0,0,0,0.6); color:#fff; border:none; border-radius:50%; width:35px; height:35px; font-size:18px; cursor:pointer; z-index:10; }
    "))),
    footer = NULL,
    size = "l",
    easyClose = TRUE,
    tags$button(class = "modal-close", `data-dismiss` = "modal", "\u2715"),
    img_html,
    modal_fallback,
    tags$h2(style = "color:#fff;margin:15px 0 5px 0;font-size:22px;", r$title),
    tags$p(style = "color:#888;font-size:14px;margin:0 0 12px 0;", r$title_japanese),
    if (nchar(genre_html) > 0) div(style = "margin-bottom:15px;", HTML(genre_html)),
    div(style = "display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:15px;",
        detail("Type", r$type),
        detail("Score", paste(r$score, "/ 10")),
        detail("Episodes", ifelse(r$episodes > 0, r$episodes, "Unknown")),
        detail("Status", r$status),
        detail("Year", ifelse(r$year > 0, r$year, "Unknown")),
        detail("Season", ifelse(nchar(r$season) > 0, r$season, "N/A")),
        detail("Source", r$source),
        detail("Studio", r$studios),
        detail("Duration", r$duration),
        detail("Rating", ifelse(nchar(r$rating) > 0, r$rating, "N/A"))
    ),
    if (!is.null(r$synopsis) && nchar(r$synopsis) > 0) {
      div(style = "margin-top:10px;padding:15px;background:#0f0f23;border-radius:10px;",
          tags$strong(style = "color:#e94560;", "Synopsis: "),
          tags$span(style = "color:#bbb;font-size:13px;line-height:1.6;", r$synopsis))
    }
  ))
}

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      * { font-family: 'Segoe UI', Arial, sans-serif; }
      body { background: #0f0f23; color: #e0e0e0; margin: 0; }
      .header-bar {
        background: linear-gradient(135deg, #1a1a2e, #16213e);
        padding: 15px 30px;
        display: flex; align-items: center; justify-content: space-between;
        box-shadow: 0 2px 10px rgba(0,0,0,0.3);
      }
      .header-bar h1 { margin: 0; color: #e94560; font-size: 24px; }
      .filters {
        background: #16213e; padding: 15px 30px;
        display: flex; gap: 15px; flex-wrap: wrap; align-items: flex-end;
        border-bottom: 1px solid #1a1a2e;
      }
      .filter-group { display: flex; flex-direction: column; gap: 4px; }
      .filter-group label { font-size: 12px; color: #888; text-transform: uppercase; }
      .filter-group select, .filter-group input[type=text] {
        background: #0f0f23; color: #e0e0e0; border: 1px solid #333;
        padding: 8px 12px; border-radius: 6px; min-width: 160px; font-size: 14px;
      }
      .stats-bar {
        padding: 10px 30px; background: #0a0a1a; display: flex; gap: 20px;
        font-size: 13px; color: #888; border-bottom: 1px solid #1a1a2e;
      }
      .stats-bar span { color: #e94560; font-weight: bold; }
      .grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
        gap: 15px; padding: 20px 30px;
      }
      .card {
        background: #16213e; border-radius: 10px; overflow: hidden;
        cursor: pointer; transition: transform 0.2s, box-shadow 0.2s;
        position: relative;
      }
      .card:hover {
        transform: translateY(-4px);
        box-shadow: 0 8px 25px rgba(233,69,96,0.3);
      }
      .card img {
        width: 100%; height: 250px; object-fit: cover;
        background: #1a1a2e;
      }
      .card-info { padding: 10px; }
      .card-title {
        font-size: 13px; font-weight: 600; white-space: nowrap;
        overflow: hidden; text-overflow: ellipsis; color: #fff;
      }
      .card-meta { font-size: 11px; color: #888; margin-top: 4px; }
      .card-score {
        position: absolute; top: 8px; right: 8px;
        background: rgba(0,0,0,0.7); color: #ffd700;
        padding: 3px 8px; border-radius: 12px; font-size: 12px; font-weight: bold;
      }
      .card-type {
        position: absolute; top: 8px; left: 8px;
        background: rgba(233,69,96,0.8); color: #fff;
        padding: 2px 8px; border-radius: 12px; font-size: 10px;
      }
      .no-img {
        width: 100%; height: 250px; background: linear-gradient(135deg, #1a1a2e, #16213e);
        display: flex; align-items: center; justify-content: center;
        color: #333; font-size: 40px;
      }
      .pagination { display: flex; justify-content: center; gap: 10px; padding: 20px; }
      .pagination button {
        background: #16213e; color: #e0e0e0; border: 1px solid #333;
        padding: 8px 16px; border-radius: 6px; cursor: pointer; font-size: 14px;
      }
      .pagination button:hover { border-color: #e94560; color: #e94560; }
      .pagination button:disabled { opacity: 0.3; cursor: default; }
      .pagination .page-info { padding: 8px; color: #888; font-size: 14px; }
      .modal-backdrop { background: rgba(0,0,0,0.85) !important; }
    "))
  ),

  div(class = "header-bar",
      h1("Anime Dashboard"),
      tags$span(style = "color:#888; font-size:14px",
                textOutput("anime_count", inline = TRUE))
  ),

  div(class = "filters",
      div(class = "filter-group",
          tags$label("Search"),
          textInput("search", "", placeholder = "Title...", width = "220px")),
      div(class = "filter-group",
          tags$label("Type"),
          selectInput("type_f", "", choices = c("All", "TV", "Movie", "OVA", "ONA", "Special", "Music"))),
      div(class = "filter-group",
          tags$label("Status"),
          selectInput("status_f", "", choices = c("All", "Finished Airing", "Currently Airing", "Not yet aired"))),
      div(class = "filter-group",
          tags$label("Genre"),
          selectInput("genre_f", "", choices = c("All"))),
      div(class = "filter-group",
          tags$label("Year"),
          selectInput("year_f", "", choices = c("All")))
  ),

  div(class = "stats-bar",
      span(textOutput("total_text", inline = TRUE)),
      "anime found"
  ),

  uiOutput("anime_grid"),
  uiOutput("pagination_ui")
)

server <- function(input, output, session) {

  all_genres <- tryCatch({
    sort(unique(unlist(strsplit(anime_df$genres[anime_df$genres != ""], ", "))))
  }, error = function(e) character(0))
  updateSelectInput(session, "genre_f", choices = c("All", all_genres))

  all_years <- sort(unique(anime_df$year[anime_df$year > 0]), decreasing = TRUE)
  updateSelectInput(session, "year_f", choices = c("All", as.character(all_years)))

  per_page <- reactiveVal(40)
  current_page <- reactiveVal(1)

  filtered <- reactive({
    df <- anime_df
    if (!is.null(input$search) && input$search != "") {
      df <- df[grepl(input$search, df$title, ignore.case = TRUE) |
               grepl(input$search, df$title_japanese, ignore.case = TRUE), ]
    }
    if (input$type_f != "All") df <- df[df$type == input$type_f, ]
    if (input$status_f != "All") df <- df[df$status == input$status_f, ]
    if (input$genre_f != "All") df <- df[grepl(input$genre_f, df$genres), ]
    if (input$year_f != "All") df <- df[df$year == as.integer(input$year_f), ]
    df[order(-df$score), ]
  })

  observeEvent(list(input$search, input$type_f, input$status_f, input$genre_f, input$year_f), {
    current_page(1)
  })

  output$anime_count <- renderText({
    paste(nrow(anime_df), "anime")
  })

  output$total_text <- renderText({
    nrow(filtered())
  })

  observeEvent(input$selected_anime, {
    sel_id <- as.character(input$selected_anime)
    r <- anime_df[as.character(anime_df$display_id) == sel_id, ]
    if (nrow(r) > 0) showAnimeModal(r[1, ])
  })

  output$anime_grid <- renderUI({
    df <- filtered()
    pp <- per_page()
    pg <- current_page()
    total <- nrow(df)
    start <- (pg - 1) * pp + 1
    end <- min(pg * pp, total)
    if (start > total) return(div(style = "padding:40px;text-align:center;color:#888;", "No results found."))
    page_df <- df[start:end, ]

    cards <- lapply(seq_len(nrow(page_df)), function(i) {
      r <- page_df[i, ]
      score_text <- ifelse(r$score > 0, sprintf("%.1f", r$score), "?")
      img_html <- if (!is.null(r$image_url) && nchar(r$image_url) > 0) {
        tags$img(src = r$image_url, alt = r$title, loading = "lazy",
                 onerror = "this.style.display='none';this.nextElementSibling.style.display='flex';")
      } else {
        div(class = "no-img", "?")
      }
      fallback_img <- if (!is.null(r$image_url) && nchar(r$image_url) > 0) {
        div(class = "no-img", style = "display:none;", "?")
      } else { NULL }
      div(class = "card",
          onclick = paste0("Shiny.setInputValue('selected_anime', '", r$display_id, "', {priority: 'event'})"),
          div(class = "card-score", score_text),
          div(class = "card-type", r$type),
          img_html,
          fallback_img,
          div(class = "card-info",
              div(class = "card-title", title = r$title, r$title),
              div(class = "card-meta", paste0(r$type, " | ", ifelse(r$year > 0, r$year, "N/A")))
          )
      )
    })

    div(class = "grid", cards)
  })

  output$pagination_ui <- renderUI({
    df <- filtered()
    pp <- per_page()
    pg <- current_page()
    total <- nrow(df)
    total_pages <- max(1, ceiling(total / pp))

    btns <- list()
    btns[[length(btns) + 1]] <- tags$button("\u00AB",
      onclick = paste0("Shiny.setInputValue('go_page', ", max(1, pg - 1), ")"),
      disabled = if (pg <= 1) "disabled" else NA)
    page_start <- max(1, min(pg - 2, total_pages - 4))
    page_end <- min(total_pages, max(pg + 2, 5))
    for (p in page_start:page_end) {
      style <- if (p == pg) "background:#e94560;color:#fff;border-color:#e94560;" else ""
      btns[[length(btns) + 1]] <- tags$button(p, style = style,
        onclick = paste0("Shiny.setInputValue('go_page', ", p, ")"))
    }
    btns[[length(btns) + 1]] <- tags$button("\u00BB",
      onclick = paste0("Shiny.setInputValue('go_page', ", min(total_pages, pg + 1), ")"),
      disabled = if (pg >= total_pages) "disabled" else NA)
    btns[[length(btns) + 1]] <- tags$span(class = "page-info", paste0("Page ", pg, " / ", total_pages))
    div(class = "pagination", btns)
  })

  observeEvent(input$go_page, {
    current_page(input$go_page)
  })
}

shinyApp(ui, server)
