# Anime Dashboard — R Shiny

An interactive anime browser built with [Shiny](https://shiny.posit.co/). Browse thousands of anime from AniList, filter by type/status/genre/year, search by title, and click any card for details with cover art.

**Live demo:** https://invweb.shinyapps.io/anime-dashboard/

![Dashboard](screenshot.png)

## Features

- **Card grid** — anime cover art, title, score, type at a glance
- **Detail modal** — click any card to see episodes, studio, synopsis, genres, rating
- **Filters** — Type, Status, Genre, Year with instant results
- **Search** — by title (English or Japanese)
- **Language toggle** — EN / RU switch via header button (JS-powered, no reload)
- **Pagination** — 40 cards per page
- **Dark theme** — custom CSS, no Shiny themes dependency

## Tech Stack

| Layer    | Tool     |
|----------|----------|
| UI       | Shiny `fluidPage` + custom CSS |
| Charts   | ggplot2 (unused, available) |
| Data     | dplyr |
| Data     | AniList GraphQL API via Python fetcher |
| Hosting  | shinyapps.io (free tier) |

## Getting Started

### Run locally

```bash
Rscript run.R
```

Opens at `http://127.0.0.1:3838`.

### Dependencies

```r
install.packages(c("shiny", "dplyr"))
```

## Project Structure

```
.
├── app.R                    # Shiny application (UI + Server + i18n)
├── run.R                    # Launch script
├── anime_data.csv           # Anime dataset (~6000+ entries from AniList)
├── fetch_anilist.py         # AniList API fetcher (Python, uses curl)
├── fetch_anime_final.py     # Legacy Jikan API fetcher
├── screenshot.png           # Dashboard screenshot
└── README.md
```

## Data Source

Anime metadata is fetched from the [AniList GraphQL API](https://anilist.gitbook.io/anilist-apiv2-docs/overview/graphql/getting-started) via `fetch_anilist.py`. Cover images are served from AniList CDN (`s4.anilist.co`).

## Deployment

```r
rsconnect::setAccountInfo(
  name   = "invweb",
  token  = "...",
  secret = "..."
)
rsconnect::deployApp(appName = "anime-dashboard", forceUpdate = TRUE)
```
