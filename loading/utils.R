## Functions from advanced_nba_data
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
  
  if(any(args %in% c('--stop'))){
    early_stop <- as.numeric(args[(which(args %in% c('--stop')))+1])
    if(is.na(early_stop)){
      early_stop <- 5
    }
  } else {
    early_stop <- 5
  }
  
  if(any(args %in% c('-v', '--verbose'))){
    verbose <- as.character(args[(which(args %in% c('-v', '--verbose')))+1])
    if(is.na(verbose)){
      verbose <- 'FALSE'
    }
  } else {
    verbose <- 'FALSE'
  }
  
  do.call(func, list(season, start, end, early_stop, verbose))
}

### Get endpoints name
re_type_stats <- function(url){
  return(str_extract(url, '(?<=\\/)[:alnum:]+(?=\\?)'))
}

### get endpoints
get_endpoints <- function(url){
  return(nba_params[[re_type_stats(url)]])
}

### GET function to nbastats.com
requests_nba <- function(url, count, n_rep, ...){
  argg <- c(as.list(environment()), list(...))
  param_nba <- get_endpoints(url)
  param_nba[intersect(names(argg), names(param_nba))] <- argg[intersect(names(argg), names(param_nba))]
  
  res <- trycatch_nbastats(url, 10, nba_request_headers, param_nba, count, n_rep, ...)
  return(res)
}

trycatch_nbastats <- function(url, t, nba_request_headers, param_nba, count, n_rep, ...){
  
  tryCatch({res <- GET(url = url, timeout(t), add_headers(nba_request_headers), query = param_nba)
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

### GET function to pbpstats.com
requests_pbpstats <- function(url, season, team_id, game_date, count, n_rep=5, ...){
  
  param_poss <- list(
    TeamId = team_id,
    Season = paste0(season, '-', str_pad(as.numeric(str_sub(season, 3, 4)) + 1, 2, pad = "0")),
    SeasonType = I('Regular%2BSeason'),
    OffDef = 'Offense',
    StartType = 'All',
    FromDate = game_date,
    ToDate = game_date
  )
  
  res <- trycatch_pbpstats(url, season, 10, pbpstats_request_headers, param_poss, team_id, game_date, count, n_rep, ...)
  return(res)
}

### GET function to data.nba.com
trycatch_datanba <- function(url, t, nba_request_headers, count, n_rep){
  
  tryCatch({res <- GET(url = url, timeout(t), add_headers(nba_request_headers))
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

trycatch_pbpstats <- function(url, season, t, pbpstats_request_headers, param_poss, team_id, game_date, count, n_rep, ...){
  
  tryCatch({res <- GET(url = url, timeout(t), add_headers(pbpstats_request_headers), query = param_poss, config = config(ssl_verifypeer = FALSE)); res},
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

get_nba_data <- function(GameID, season){
  GameID <- paste0(paste0('002', str_sub(season, 3, 4), '0'), str_pad(GameID, 4, side = "left", pad = 0))
  url <- paste0("https://data.nba.com/data/v2015/json/mobile_teams/nba/", season, "/scores/pbp/", GameID, "_full_pbp.json")
  
  count <- 1
  response <- trycatch_datanba(url, 10, nba_request_headers, count, 5)
  json <- fromJSON(content(response, as = "text", encoding = 'UTF-8'))
  
  game_id <- json$g$gid
  period <- json$g$pd$p
  
  data <- bind_rows(lapply(period, function(period){mutate(json$g$pd$pla[[period]], PERIOD = period)}))
  data <- mutate(data, GAME_ID = game_id)
  
  return(data)
}

get_pbp_stats <- function(GameID, season, ...){
  
  ### Get game date
  if (season < 2000){
    message('Statistics on pbpstats.com start from 2000/01 season')
    return(NULL)
  }
  game_summary <- get_boxscore_summary(GameID, season, headers = 'GameSummary')
  game_date <- format(as.Date(game_summary$GAME_DATE_EST[1],format="%Y-%m-%d"))
  team_id <- c(game_summary$HOME_TEAM_ID[1], game_summary$VISITOR_TEAM_ID[1])
  start_period <- 1
  end_period <- game_summary$LIVE_PERIOD[1]
  
  ### Get offense possessions teams
  count <- 1
  url <- 'https://api.pbpstats.com/get-possessions/nba'
  
  response <- lapply(team_id, requests_pbpstats, url = url, season = season, game_date = game_date, count = count, n_rep = 5)
  
  pbp_data <- bind_rows(lapply(response, function(x){
    json <- fromJSON(content(x, as = "text", encoding = 'UTF-8'))
    pbp_data <- json[['possessions']]
    
    pbp_data <- pbp_data %>%
      unnest(., VideoUrls, keep_empty = TRUE) %>%
      rename_all(toupper)
  }))
  
  return(pbp_data)
}

get_nba_pbp <- function(GameID, season, player_on_floor = FALSE, ...){
  GameID <- paste0(paste0('002', str_sub(season, 3, 4), '0'), str_pad(GameID, 4, side = "left", pad = 0))
  url <- 'https://stats.nba.com/stats/playbyplayv2?'
  
  ## application request counter
  count <- 1
  
  response <- requests_nba(url, count, 5, GameID = GameID, ...)
  json <- fromJSON(content(response, as = "text"))
  
  nba_data <- tryCatch({data.frame(matrix(unlist(json$resultSets$rowSet[[1]]), ncol = length(json$resultSets$headers[[1]]), byrow = FALSE))}, error = function(e) return(NULL))
  if(is.null(nba_data)){
    return(NULL)
  }
  names(nba_data) <- json$resultSets$headers[[1]]
  
  if (player_on_floor){
    nba_data <- purrr::map_dfr(nba_data %>% group_split(), add_player_on_floor)
  }
  return(nba_data)
}

get_boxscore_summary <- function(GameID, season, headers = c('all', "GameSummary", "OtherStats", "Officials", "InactivePlayers", "GameInfo", "LineScore", "LastMeeting", "SeasonSeries", "AvailableVideo")){
  match.arg(headers)
  GameID <- paste0(paste0('002', str_sub(season, 3, 4), '0'), str_pad(GameID, 4, side = "left", pad = 0))
  url <- 'https://stats.nba.com/stats/boxscoresummaryv2?'
  
  count <- 1
  response <- requests_nba(url, count, 5, GameID = GameID)
  json <- fromJSON(content(response, as = "text"))
  if (headers == 'all'){
    l <- lapply(seq_along(json$resultSets$name), function(x){
      dt <-data.frame(matrix(unlist(json$resultSets$rowSet[[x]]), ncol = length(json$resultSets$headers[[1]]), byrow = FALSE))
      colnames(dt) <- json$resultSets$headers[[x]]
      return(dt)
    })
    names(l) <- json$resultSets$name
    return(l)
  } else {
    n <- which(json$resultSets$name == headers)
    df <- data.frame(matrix(unlist(json$resultSets$rowSet[[n]]), ncol = length(json$resultSets$headers[[1]]), byrow = FALSE))
    colnames(df) <- json$resultSets$headers[[n]]
    return(df)
  }
}

get_season_pbp_full <- function(season, start=1, end=1230, early_stop = 5, verbose='FALSE'){
  
  if (!dir.exists(suppressWarnings(normalizePath(paste0('datasets/', season))))){
    dir.create(suppressWarnings(normalizePath(paste0('datasets/', season))), recursive = TRUE)
  }
  
  if (!dir.exists(suppressWarnings(normalizePath(paste0('datasets/', season, '/nbastats'))))){
    dir.create(suppressWarnings(normalizePath(paste0('datasets/', season, '/nbastats'))), recursive = TRUE)
  }
  
  if (season >= 2000){
    if (!dir.exists(suppressWarnings(normalizePath(paste0('datasets/', season, '/pbpstats'))))){
      dir.create(suppressWarnings(normalizePath(paste0('datasets/', season, '/pbpstats'))), recursive = TRUE)
    }
  }
  
  if (season >= 2016){
    if (!dir.exists(suppressWarnings(normalizePath(paste0('datasets/', season, '/datanba'))))){
      dir.create(suppressWarnings(normalizePath(paste0('datasets/', season, '/datanba'))), recursive = TRUE)
    }
  }
  
  early_st <- 0
  sleep <- 1
  for (i in seq(start, end)){
    
    exists_nbastats <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, '/nbastats', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))
    exists_pbpstats <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, '/pbpstats', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))
    exists_nbadata <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, '/datanba', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))
    
    if(sum(c(exists_nbastats, exists_pbpstats, exists_nbadata)) == 0){
      next
    } else {
      if (sleep %% 100 == 0){
        Sys.sleep(600)
      }
      
      sleep <- sleep + 1
      for(n in c("get_nba_pbp"[exists_nbastats], "get_pbp_stats"[exists_pbpstats], "get_nba_data"[exists_nbadata])){
        if(season < 2000){
          if(n %in% c("get_pbp_stats")){
            next
          }
        } else if(season < 2016){
          if(n == "get_nba_data"){
            next
          }
        }
        
        dt <- do.call(n, list(GameID = i, season = season))
        
        if(n == "get_nba_pbp"){
          if (is.null(dt)){
            early_st <- early_st + 1
            if (early_st >= early_stop){
              break
            } else {
              Sys.sleep(5)
              next
            }
          }
        }
        early_st <- 0
        folder <- switch(n,
                         "get_nba_pbp" = "nbastats",
                         "get_pbp_stats" = "pbpstats",
                         "get_nba_data" = "datanba")
        
        write.csv(dt, file = suppressWarnings(normalizePath(paste('./datasets',  season, '/', folder, paste0(paste(season, i, sep = '_'), '.csv'), sep = '/'))), 
                  row.names = FALSE)
      }
    }
    
    if (as.logical(verbose)){
      print(paste('Файл',  paste0(paste(season, i, sep = '_'), '.csv'), 'сохранён в папке', normalizePath(paste('./datasets', season, sep = '/'))))
    }
    Sys.sleep(5)
  }
}

## Functions from experiment_dff_shot
### Functions for work with CLI
processing_args_command_line <- function(args, need_arg, default_value, as_func = "as.numeric"){
  if(any(args %in% need_arg)){
    arg <- do.call(as_func, list(args[which(args %in% need_arg)+1]))
    
    if(is.na(arg)){
      arg <- default_value
    }
  } else {
    arg <- default_value
  }
  return(arg)
}

# command_line_work <- function(){
#   args <- commandArgs(trailingOnly = TRUE)
#   
#   season <- processing_args_command_line(args, "--season", 2020)
#   start <- processing_args_command_line(args, c('-s', '--start'), 1)
#   end <- processing_args_command_line(args, c('-e', '--end'), 1230)
#   early_stop <- processing_args_command_line(args, '--stop', 5)
#   verbose <- processing_args_command_line(args, c('-v', '--verbose'), "FALSE", "as.character")
#   datatype <- processing_args_command_line(args, "-d", "pbp", "as.character")
#   player_id <- processing_args_command_line(args, c("-p1", "--player_id"), NA)
#   partner_id <- processing_args_command_line(args, c("-p2", "--partner_id"), NA)
#   
#   return(list(season, start, end, early_stop, verbose, datatype, player_id, partner_id))  
# }

loading_nba_data <- function(){
  
  args <- command_line_work()
  
  if(args[[6]] == 'pbp'){
    do.call("get_season_pbp_full", list(args[[1]], args[[2]], args[[3]], args[[4]], args[[5]]))
  } else  if(args[[6]] == "shot"){
    do.call("get_season_shot_details", list(args[[1]], args[[4]], args[[5]]))
  } else if(args[[6]] == "players") {
    do.call("get_commonal_players", list(args[[1]], args[[5]]))
  } else {
    stop("Введён неверный аргумент datatype")
  }
}

get_shot_details <- function(team_id, season, ...){
  url <- 'https://stats.nba.com/stats/shotchartdetail?'
  season <- str_c(season, str_sub(season + 1, 3, 4), sep='-')
  
  count <- 1
  response <- requests_nba(url, count, 5, TeamID = as.character(team_id), Season = season, ...)
  json <- jsonlite::fromJSON(httr::content(response, as = "text"))
  raw_data <- json$resultSets$rowSet[[1]]
  col_names <- json$resultSets$headers[[1]]
  nba_data <- data.frame(matrix(unlist(raw_data), ncol = length(col_names), byrow = FALSE))
  tryCatch({names(nba_data) <- col_names}, error = function(e) return(nba_data))
  return(nba_data)
}

get_season_shot_details <- function(season, early_stop = 5, verbose = 'FALSE'){
  season <- as.integer(season)
  if (!dir.exists(suppressWarnings(normalizePath(paste0('datasets/', season))))){
    dir.create(suppressWarnings(normalizePath(paste0('datasets/', season))), recursive = TRUE)
  }
  
  if (!dir.exists(suppressWarnings(normalizePath(paste0('datasets/', season, '/shotdetail'))))){
    dir.create(suppressWarnings(normalizePath(paste0('datasets/', season, '/shotdetail'))), recursive = TRUE)
  }
  
  early_st <- 0
  for (i in seq_along(team_dict)){
    
    if (file.exists(suppressWarnings(normalizePath(paste('./datasets', season, '/shotdetail', paste0(names(team_dict[i]), '.csv'), sep = '/'))))){
      next
    }
    
    t <- get_shot_details(team_dict[[i]], season)
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
    
    write.csv(t, file = suppressWarnings(normalizePath(paste('./datasets',  season, '/shotdetail', paste0(names(team_dict[i]), '.csv'), sep = '/'))),
              row.names = FALSE)
    if (as.logical(verbose)){
      print(paste('Shot details сезона', stringr::str_c(season, stringr::str_sub(season + 1, 3, 4), sep='-'), names(team_dict[i]), 
                  'сохранены в папке', normalizePath(paste('./datasets', season, '/shotdetail', sep = '/'))))
    }
    Sys.sleep(5)
  }
}
