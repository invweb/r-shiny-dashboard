#!/usr/bin/env Rscript

required_packages <- c("shiny", "shinydashboard", "ggplot2", "dplyr", "DT")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
}

shiny::runApp("app.R", port = 3838, launch.browser = TRUE)
