`%>%` <- magrittr::`%>%`

#' Call function with argument from CLI
#' 
#' @description
#' Call function with argument from CLI
#' 
#' @details
#' later
#' 
#' @param func function function which need call with argument from CLI
#' @return None
command_line_work <- function(func){
  args <- commandArgs(trailingOnly = TRUE)
  
  if(any(args %in% c('--season'))){
    season <- as.numeric(args[(which(args %in% c('--season')))+1])
    
    if(is.na(season)){
      season <- 2020
    }
  } else {
    season <- 2020
  }
  
  if(any(args %in% c('-s', '--start'))){
    start <- as.numeric(args[(which(args %in% c('-s', '--start')))+1])
    if(is.na(start)){
      start <- 1
    }
  } else {
    start <- 1
  }
  
  if(any(args %in% c('-e', '--end'))){
    end <- as.numeric(args[(which(args %in% c('-e', '--end')))+1])
    if(is.na(end)){
      end <- 1230
    }
  } else {
    end <- 1230
  }
  
  if(any(args %in% c('-l', '--league'))){
    league <- as.character(args[(which(args %in% c('-l', '--league')))+1])
    if(is.na(league)){
      league <- 'nba'
    }
  } else {
    league <- 'nba'
  }
  
  if(any(args %in% c('-d', '--datatype'))){
    datatype <- as.character(args[(which(args %in% c('-d', '--datatype')))+1])
    if(is.na(datatype)){
      datatype <- 'all'
    }
  } else {
    datatype <- 'all'
  }
  
  if(any(args %in% c('-st', '--seasontype'))){
    seasontype <- as.character(args[(which(args %in% c('-st', '--seasontype')))+1])
    if(is.na(seasontype)){
      seasontype <- 'rg'
    }
  } else {
    seasontype <- 'rg'
  }
  
  if(any(args %in% c('--stop'))){
    early_stop <- as.numeric(args[(which(args %in% c('--stop')))+1])
    if(is.na(early_stop)){
      early_stop <- 5
    }
  } else {
    early_stop <- 5
  }
  
  do.call(func, list(season, start, end, league, datatype, seasontype, early_stop))
}


#' Checking existence of a folder
#' 
#' @description
#' Checking existence of a folder
#' 
#' @details
#' Checking existence of a folder. If not, then create
#' 
#' @param path character path to folder
#' @param recursive logical. Should elements of the path other than the last be created? If true, like the Unix command mkdir -p.
#' @return None
exists_folder <- function(path, recursive = TRUE){
  if (!dir.exists(suppressWarnings(normalizePath(path)))){
    dir.create(suppressWarnings(normalizePath(path)), recursive = TRUE)
  }
}


#' Get NBA endpoint name from URL
#'
#' @description
#' Get NBA endpoint name from URL
#' 
#' @details
#' later
#' 
#' @param url character URL NBA endpoint
#' @return character NBA endpoint name
re_type_stats <- function(url){
  return(regmatches(url, regexpr('(?<=\\/)[[:alnum:]]+(?=\\?)', url, perl = TRUE)))
}


#' Get list parameters for NBA endpoint
#'
#' @description
#' Get list parameters for NBA endpoint
#' 
#' @details
#' later
#' 
#' @param url character URL NBA endpoint
#' @return description
get_endpoints <- function(url){
  return(nba_params[[re_type_stats(url)]])
}


#' title
#'
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @return description
unlist_columns <- function(data, column){
  unlist(sapply(seq(1, length(data[[column]])), function(x){
    qualifiers <- data[[column]][[x]]
    if(length(qualifiers) == 1){
      return(qualifiers)
    } else if(length(qualifiers > 1)){
      qualifiers <- paste(qualifiers, collapse = ', ')
    } else {
      qualifiers <- ''
    }
    return(qualifiers)
  }, USE.NAMES = FALSE))
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @param \\dots Additional arguments passed to requests_nba().
#' @return response from NBA API
requests_nba <- function(url, count, n_rep, ...){
  argg <- c(as.list(environment()), list(...))
  param_nba <- get_endpoints(url)
  param_nba[intersect(names(argg), names(param_nba))] <- argg[intersect(names(argg), names(param_nba))]
  res <- trycatch_nbastats(url, 10, nba_request_headers, param_nba, count, n_rep, ...)
  return(res)
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param \\dots Additional arguments passed to requests_nba().
#' @return response from NBA API
trycatch_nbastats <- function(url, t, nba_request_headers, param_nba, count, n_rep, ...){

  tryCatch({res <- httr::GET(url = url, httr::timeout(t), httr::add_headers(nba_request_headers), query = param_nba)
  if(res$status_code != 200 | res$url == 'https://www.nba.com/stats/error/') {stop()}; return(res)},
  error = function(e){
    if (exists('res')){
      mes <- ' Response status is not equal to 200. Number of remaining attempts: '
    } else {
      mes <- ' No response was received from nbastats, a repeat request. Number of remaining attempts: '
    }
    if (count < n_rep){
      message(paste0(Sys.time(), mes, n_rep - count))
      Sys.sleep(2)
      return(requests_nba(url, count + 1, n_rep, ...))
    } else{
      stop(Sys.time(), ' No response was received from nbastats for ', n_rep, ' request attempts')
    }
  })
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param \\dots Additional arguments passed to requests_nba().
#' @return response from NBA API
requests_pbpstats <- function(url, season, team_id, game_date, league_id, season_type, count, n_rep=5, ...){
  
  pbpstats_params <- list(
    TeamId = team_id,
    Season = if(league_id == "00") paste(season, substr(season + 1, 3, 4), sep = '-') else as.character(season),
    SeasonType = I(season_type),
    OffDef = 'Offense',
    StartType = 'All',
    FromDate = game_date,
    ToDate = game_date
  )

  res <- trycatch_pbpstats(url, season, 10, pbpstats_request_headers, pbpstats_params, team_id, game_date, count, n_rep, ...)
  return(res)
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @return response from NBA API
trycatch_datanba <- function(url, t, nba_request_headers, count, n_rep){
  
  tryCatch({res <- httr::GET(url = url, httr::timeout(t), httr::add_headers(nba_request_headers))
  if(res$status_code != 200) {stop()}; return(res)},
  error = function(e){
    if (exists('res')){
      mes <- ' Response status is not equal to 200. Number of remaining attempts: '
    } else {
      mes <- ' No response was received from data.nba.com, a repeat request. Number of remaining attempts: '
    }
    if (count < n_rep){
      message(paste0(Sys.time(), mes, n_rep - count))
      Sys.sleep(2)
      return(trycatch_datanba(url, t, nba_request_headers, count + 1, n_rep))
    } else{
      stop(Sys.time(), ' No response was received from data.nba.com for ', n_rep, ' request attempts')
    }
  })
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param \\dots Additional arguments passed to requests_nba().
#' @return response from NBA API
trycatch_pbpstats <- function(url, season, t, pbpstats_request_headers, param_poss, team_id, game_date, count, n_rep, ...){
  
  tryCatch({res <- httr::GET(url = url, httr::timeout(t), httr::add_headers(pbpstats_request_headers), query = param_poss, 
                             config = httr::config(ssl_verifypeer = FALSE)); res},
           error = function(e){
             if (count < n_rep){
               message(paste0(Sys.time(), ' No response was received from pbpstats, a repeat request. Number of remaining attempts: ', n_rep - count))
               Sys.sleep(2)
               return(requests_pbpstats(url, season=season, team_id=team_id, game_date=game_date, count=count+1, n_rep=n_rep, ...))
             } else{
               stop(Sys.time(), ' No response was received from pbpstats for ', n_rep, ' request attempts')
             }
           })
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param \\dots Additional arguments passed to requests_nba().
#' @return A leaguegamelog data.frame
league_game_log <- function(season, league_id, ...){
  if(league_id == '00'){
    url <- 'https://stats.nba.com/stats/leaguegamelog?'
  } else {
    url <- 'https://stats.wnba.com/stats/leaguegamelog?'
  }
  
  count <- 1
  response <- requests_nba(url, count, 5, Season = season, LeagueID = league_id, ...)
  json <- jsonlite::fromJSON(httr::content(response, as = "text"))
  
  nba_data <- tryCatch({data.frame(matrix(unlist(json$resultSets$rowSet[[1]]), 
                                          ncol = length(json$resultSets$headers[[1]]), byrow = FALSE))}, 
                       error = function(e) return(NULL))
  if(is.null(nba_data)){
    return(NULL)
  }
  names(nba_data) <- json$resultSets$headers[[1]]
  
  return(nba_data)
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @param \\dots Additional arguments passed to requests_nba().
#' @return A play-by-play data.frame from data.stats.com
load_datanba <- function(game_id, season, gamelog, league_id, ...){
  if(league_id == "00"){
    url <- paste0("https://data.nba.com/data/v2015/json/mobile_teams/nba/", season, "/scores/pbp/", game_id, "_full_pbp.json")
  } else {
    url <- paste0("https://data.wnba.com/data/v2015/json/mobile_teams/wnba/", season, "/scores/pbp/", game_id, "_full_pbp.json")
  }
  
  count <- 1
  response <- trycatch_datanba(url, 10, nba_request_headers, count, 5)
  json <- jsonlite::fromJSON(httr::content(response, as = "text", encoding = 'UTF-8'))
  
  game_id <- json$g$gid
  period <- json$g$pd$p
  
  data <- dplyr::bind_rows(lapply(period, function(period){dplyr::mutate(json$g$pd$pla[[period]], PERIOD = period)}))
  data <- dplyr::mutate(data, GAME_ID = game_id)
  
  return(data)
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @param \\dots Additional arguments passed to requests_nba().
#' @return A play-by-play data.frame from cdn.nba.com
load_cdnnba <- function(game_id, season, gamelog, league_id, ...){
  if(league_id == "00"){
    url <- paste0("https://cdn.nba.com/static/json/liveData/playbyplay/playbyplay_", game_id, ".json")
  } else {
    url <- paste0("https://cdn.wnba.com/static/json/liveData/playbyplay/playbyplay_", game_id, ".json")
  }
  
  count <- 1
  response <- trycatch_datanba(url, 10, nba_request_headers, count, 5)
  json <- jsonlite::fromJSON(httr::content(response, as = "text", encoding = 'UTF-8'))
  
  data <- json$game$actions
  data$gameId <- json$game$gameId
  
  data$qualifiers <- unlist_columns(data, "qualifiers")
  data$personIdsFilter <- unlist_columns(data, "personIdsFilter")
  
  return(data)
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @param \\dots Additional arguments passed to requests_nba().
#' @return A play-by-play data.frame from pbpstats.com
load_pbpstats <- function(game_id, season, gamelog, league_id, ...){
  
  season_type <- ifelse(substr(game_id, 1, 3) %in% c('002', '102'), 'Regular%2BSeason', 'Playoffs')
  game_date <- unique(gamelog[gamelog$GAME_ID == game_id, "GAME_DATE"])
  team_id <- gamelog[gamelog$GAME_ID == game_id, "TEAM_ID"]
  
  ### Get offense possessions teams
  count <- 1
  if(league_id == '00'){
    url <- 'https://api.pbpstats.com/get-possessions/nba'
  } else {
    url <- 'https://api.pbpstats.com/get-possessions/wnba'
  }
  
  response <- lapply(team_id, requests_pbpstats, url = url, season = season, game_date = game_date, 
                     league_id = league_id, season_type = season_type, count = count, n_rep = 5)
  
  pbp_data <- dplyr::bind_rows(lapply(response, function(x){
    json <- jsonlite::fromJSON(httr::content(x, as = "text", encoding = 'UTF-8'))
    pbp_data <- json[['possessions']]
    
    pbp_data <- pbp_data %>%
      tidyr::unnest(., VideoUrls, keep_empty = TRUE) %>%
      dplyr::rename_all(toupper)
  }))
  
  return(pbp_data)
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @param \\dots Additional arguments passed to requests_nba().
#' @return A play-by-play data.frame from nba.stats.com
load_playbyplayv2 <- function(game_id, season, gamelog, league_id, ...){
  if(league_id == '00'){
    url <- 'https://stats.nba.com/stats/playbyplayv2?'
  } else {
    url <- 'https://stats.wnba.com/stats/playbyplayv2?'
  }
  
  ## application request counter
  count <- 1
  
  response <- requests_nba(url, count, 5, GameID = game_id, LeagueID = league_id, ...)
  json <- jsonlite::fromJSON(httr::content(response, as = "text"))
  
  nba_data <- tryCatch({data.frame(matrix(unlist(json$resultSets$rowSet[[1]]), 
                                          ncol = length(json$resultSets$headers[[1]]), byrow = FALSE))}, 
                       error = function(e) return(NULL))
  if(is.null(nba_data)){
    return(NULL)
  }
  names(nba_data) <- json$resultSets$headers[[1]]
  
  return(nba_data)
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @param \\dots Additional arguments passed to requests_nba().
#' @return A play-by-play data.frame from nba.stats.com
load_playbyplayv3 <- function(game_id, season, gamelog, league_id, ...){
  if(league_id == "00"){
    url <- 'https://stats.nba.com/stats/playbyplayv3?'
  } else {
    url <- 'https://stats.wnba.com/stats/playbyplayv3?'
  }
  
  ## application request counter
  count <- 1
  
  response <- requests_nba(url, count, 5, GameID = game_id, LeagueID = league_id, ...)
  json <- jsonlite::fromJSON(httr::content(response, as = "text"))
  
  nba_data <- tryCatch({json$game$actions}, 
                       error = function(e) return(NULL))
  if(is.null(nba_data)){
    return(NULL)
  } else {
    nba_data$gameId <- json$game$gameId
  }
  
  return(nba_data)
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param \\dots Additional arguments passed to requests_nba().
#' @return A shotdetail data.frame
load_shotchartdetail <- function(team_id, season, league_id, ...){
  
  if(league_id == '00'){
    url <- 'https://stats.nba.com/stats/shotchartdetail?'
    season <- paste(season, substr(season + 1, 3, 4), sep = '-')
  } else {
    url <- 'https://stats.wnba.com/stats/shotchartdetail?'
    season <- as.character(season)
  }
  
  count <- 1
  response <- requests_nba(url, count, 5, TeamID = as.character(team_id), Season = season, LeagueID = league_id, ...)
  json <- jsonlite::fromJSON(httr::content(response, as = "text"))
  raw_data <- json$resultSets$rowSet[[1]]
  col_names <- json$resultSets$headers[[1]]
  nba_data <- tryCatch({data.frame(matrix(unlist(raw_data), 
                                          ncol = length(col_names), byrow = FALSE))}, 
                       error = function(e) return(0))
  if(!is.data.frame(nba_data)){
    return(0)
  }
  tryCatch({names(nba_data) <- col_names}, error = function(e) return(nba_data))
  return(nba_data)
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @return None
load_season_shotchartdetail <- function(season, seasontype, league_id, teams_id, early_stop = 5){
  season <- as.integer(season)
  season_type <- ifelse(seasontype == 'Playoffs', 'po', 'rg')
  league_type <- ifelse(league_id == '00', 'nba', 'wnba')
  
  early_st <- 0
  for (i in seq_along(teams_id)){
    if (file.exists(suppressWarnings(normalizePath(paste('./datasets', season, season_type, league_type, 'shotdetail', paste0(names(teams_id[i]), '.csv'), sep = '/'))))){
      next
    }
    
    t <- load_shotchartdetail(teams_id[[i]], season, league_id = league_id, SeasonType = seasontype)
    if(is.numeric(t)){
      next
    }
    if (sum(dim(t)) == 0){
      early_st <- early_st + 1
      if (early_st >= early_stop){
        break
      } else {
        Sys.sleep(5)
        next
      }
    }
    early_st <- 0
    
    write.csv(t, file = suppressWarnings(normalizePath(paste('./datasets',  season, season_type, league_type, 'shotdetail', paste0(names(teams_id[i]), '.csv'), sep = '/'))),
              row.names = FALSE)
    Sys.sleep(5)
  }
}


parse_boxscorematchupsv3_json <- function(matchups){
  data <- matchups %>%
    purrr::pluck("boxScoreMatchups") %>%
    dplyr::as_tibble()
  
  ids_df <- data %>%
    data.frame() %>%
    dplyr::select("gameId","awayTeamId","homeTeamId") %>%
    dplyr::distinct()
  
  home_team_data <- data %>%
    purrr::pluck("homeTeam")
  
  home_team_info <- data.frame(
    teamId = home_team_data %>% purrr::pluck("teamId"),
    teamName = home_team_data %>% purrr::pluck("teamName"),
    teamCity = home_team_data %>% purrr::pluck("teamCity"),
    teamTricode = home_team_data %>% purrr::pluck("teamTricode"),
    teamSlug = home_team_data %>% purrr::pluck("teamSlug")
  )
  
  home_team_players <- home_team_data %>%
    purrr::pluck("players") %>%
    data.frame(stringsAsFactors = F) %>%
    tidyr::unnest("matchups", names_sep = "_") %>%
    tidyr::unnest("matchups_statistics")
  
  home_team_players <- ids_df %>%
    dplyr::bind_cols(home_team_info) %>%
    dplyr::bind_cols(home_team_players) %>% 
    janitor::clean_names()
  
  away_team_data <- data %>%
    purrr::pluck("awayTeam")
  
  away_team_info <- data.frame(
    teamId = away_team_data %>% purrr::pluck("teamId"),
    teamName = away_team_data %>% purrr::pluck("teamName"),
    teamCity = away_team_data %>% purrr::pluck("teamCity"),
    teamTricode = away_team_data %>% purrr::pluck("teamTricode"),
    teamSlug = away_team_data %>% purrr::pluck("teamSlug")
  )
  
  away_team_players <- away_team_data %>%
    purrr::pluck("players") %>%
    data.frame(stringsAsFactors = F) %>%
    tidyr::unnest("matchups", names_sep = "_") %>%
    tidyr::unnest("matchups_statistics")
  
  away_team_players <- ids_df %>%
    dplyr::bind_cols(away_team_info) %>%
    dplyr::bind_cols(away_team_players) %>% 
    janitor::clean_names()
  
  matchups_data <- rbind(home_team_players, away_team_players)
  
  return(matchups_data)
}


load_matchups<- function(game_id, season, gamelog, league_id, ...){
  if(league_id == "00"){
    url <- 'https://stats.nba.com/stats/boxscorematchupsv3?'
  } else {
    url <- 'https://stats.wnba.com/stats/boxscorematchupsv3?'
  }
  
  ## application request counter
  count <- 1
  
  response <- requests_nba(url, count, 5, GameID = game_id, LeagueID = league_id, ...)
  json <- jsonlite::fromJSON(httr::content(response, as = "text"))
  
  nba_data <- tryCatch({parse_boxscorematchupsv3_json(json)},
                       error = function(e) return(NULL))
  if(is.null(nba_data)){
    return(NULL)
  }
  
  return(nba_data)
}


#' title
#' 
#' @description
#' A short description...
#' 
#' @details
#' Additional details...
#' 
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @param name description
#' @return None
load_season <- function(season, start=1, end=1230, league = 'nba', datatype = 'all', seasontype = 'rg', early_stop = 5){
  
  season_limit <- list(
    ## order limits: nbastats(v2 and v3),pbpstats, datanba, cdnnba, matchups
    "00" = c(1996, 2000, 2016, 2019, 2017),
    "10" = c(1997, 2009, 2017, 2022, 3000)
  )
  season_limit <- if(league == 'nba') season_limit[['00']] else season_limit[['10']]
  
  if(datatype %in% c('all', 'pbp', 'nbastats', 'nbastatsv3', 'datanba', 'pbpstats', 'cdnnba', 'matchups')){
    exists_folder(path=paste('datasets', season, seasontype, league, sep = '/'))
    if(season >= season_limit[1] & datatype %in% c('all', 'pbp', 'nbastats')){
      exists_folder(path=paste('datasets', season, seasontype, league, 'nbastats', sep = '/'))
    }
    if(season >= season_limit[1] & datatype %in% c('all', 'pbp', 'nbastatsv3')){
      exists_folder(path=paste('datasets', season, seasontype, league, 'nbastatsv3', sep = '/'))
    }
    if (season >= season_limit[2] & datatype %in% c('all', 'pbp', 'pbpstats')){
      exists_folder(path=paste('datasets', season, seasontype, league, 'pbpstats', sep = '/'))
    }
    if (season >= season_limit[3] & datatype %in% c('all', 'pbp', 'datanba')){
      exists_folder(path=paste('datasets', season, seasontype, league, 'datanba', sep ='/'))
    }
    if (season >= season_limit[4] & datatype %in% c('all', 'pbp', 'cdnnba')){
      exists_folder(path=paste('datasets', season, seasontype, league, 'cdnnba', sep ='/'))
    }
    if (season >= season_limit[5] & datatype %in% c('all', 'pbp', 'matchups')){
      exists_folder(path=paste('datasets', season, seasontype, league, 'matchups', sep ='/'))
    }
  }

  if(datatype %in% c('all', 'shot')){
    exists_folder(path=paste('datasets', season, seasontype, league, 'shotdetail', sep = '/'))
  }
  teams_id <- if(league == 'nba') team_dict else wteam_dict
  league_id <- if(league == 'nba') '00' else '10'

  request_seasontype <- switch(seasontype,
                               'rg' = I('Regular+Season'),
                               'po' = 'Playoffs'
  )

  if(datatype %in% c('all', 'shot')){
    load_season_shotchartdetail(season, request_seasontype, league_id, teams_id)
  }

  early_st <- 0
  sleep <- 1

  if(datatype %in% c('all', 'pbp', 'nbastats', 'nbastatsv3', 'datanba', 'pbpstats', 'cdnnba', 'matchups')){
    gamelog <- league_game_log(season = season, league_id = league_id, SeasonType = request_seasontype)
    
    if(request_seasontype == 'Playoffs'){
      games_id <- unique(gamelog$GAME_ID)
    } else {
      if(league_id == "00"){
        prefix <- '002'
      } else {
        prefix <- '102'
      }
      start <- as.integer(paste0(paste0(substr(season, 3, 4), '0'), paste0(paste(rep('0', 4 - nchar(start)), collapse = ''), start)))
      end <- as.integer(paste0(paste0(substr(season, 3, 4), '0'), paste0(paste(rep('0', 4 - nchar(end)), collapse = ''), end)))
      games_id <- sapply(seq(start, end), function(x) if(nchar(x) == 7) paste0(prefix, x) else paste0(prefix, sprintf("%07d", as.numeric(x))))
    }

    for (i in games_id){
      exists_nbastats <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, seasontype, league, 'nbastats', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))
      exists_nbastatsv3 <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, seasontype, league, 'nbastatsv3', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))
      exists_pbpstats <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, seasontype, league, 'pbpstats', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))
      exists_nbadata <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, seasontype, league, 'datanba', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))
      exists_cdnnba <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, seasontype, league, 'cdnnba', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))
      exists_matchups <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, seasontype, league, 'matchups', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))

      if(datatype == 'nbastats'){
        exists_nbastatsv3 <- 0
        exists_pbpstats <- 0
        exists_nbadata <- 0
        exists_cdnnba <- 0
        exists_matchups <- 0
      } else if(datatype == 'nbastatsv3'){
        exists_nbastats <- 0
        exists_pbpstats <- 0
        exists_nbadata <- 0
        exists_cdnnba <- 0
        exists_matchups <- 0
      } else if(datatype == 'pbpstats'){
        exists_nbastats <- 0
        exists_nbastatsv3 <- 0
        exists_nbadata <- 0
        exists_cdnnba <- 0
        exists_matchups <- 0
      } else if(datatype == 'datanba'){
        exists_nbastats <- 0
        exists_nbastatsv3 <- 0
        exists_pbpstats <- 0
        exists_cdnnba <- 0
        exists_matchups <- 0
      } else if(datatype == 'cdnnba'){
        exists_nbastats <- 0
        exists_nbastatsv3 <- 0
        exists_pbpstats <- 0
        exists_nbadata <- 0
        exists_matchups <- 0
      } else if(datatype == 'matchups'){
        exists_nbastats <- 0
        exists_nbastatsv3 <- 0
        exists_pbpstats <- 0
        exists_nbadata <- 0
        exists_cdnnba <- 0
      }

      if(sum(c(exists_nbastats, exists_nbastatsv3, exists_pbpstats,
               exists_nbadata, exists_cdnnba, exists_matchups)) == 0){
        next
      } else {
        if (sleep %% 100 == 0){
          Sys.sleep(600)
        }

        sleep <- sleep + 1
        for(n in c("load_playbyplayv2"[exists_nbastats], "load_playbyplayv3"[exists_nbastatsv3], "load_pbpstats"[exists_pbpstats],
                   "load_datanba"[exists_nbadata], "load_cdnnba"[exists_cdnnba], "load_matchups"[exists_matchups])){
          if(season < season_limit[1]){
            if(n %in% c("load_playbyplayv2", "load_playbyplayv3")){
              next
            }
          }
          if(season < season_limit[2]){
            if(n  == "load_pbpstats"){
              next
            }
          }
          if(season < season_limit[3]){
            if(n == "load_datanba"){
              next
            }
          }
          if(season < season_limit[4]){
            if(n == "load_cdnnba"){
              next
            }
          }
          if(season < season_limit[5]){
            if(n == "load_matchups"){
              next
            }
          }

          dt <- do.call(n, list(game_id = i, season = season, gamelog = gamelog, league_id = league_id))

          if (is.null(dt)){
            early_st <- early_st + 1
            if (early_st >= early_stop){
              break
              } else {
                Sys.sleep(5)
                next
              }
          } else if (dim(dt)[1] == 0){
            early_st <- early_st + 1
            if (early_st >= early_stop){
              break
            } else {
              Sys.sleep(5)
              next
            }
          }
          early_st <- 0
          pbp_folder <- switch(n,
                               "load_playbyplayv2" = "nbastats",
                               "load_playbyplayv3" = "nbastatsv3",
                               "load_pbpstats" = "pbpstats",
                               "load_datanba" = "datanba",
                               "load_cdnnba" = "cdnnba",
                               "load_matchups" = "matchups")

          write.csv(dt, file = suppressWarnings(normalizePath(paste('./datasets', season, seasontype, league,
                                                                    pbp_folder, paste0(paste(season, i, sep = '_'), '.csv'), sep = '/'))),
                    row.names = FALSE)
        }
      }
      Sys.sleep(5)
    }
  }
}
