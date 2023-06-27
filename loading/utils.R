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
  
  do.call(func, list(season, start, end, datatype, seasontype, early_stop))
}

exists_folder <- function(path, recursive = TRUE){
  if (!dir.exists(suppressWarnings(normalizePath(path)))){
    dir.create(suppressWarnings(normalizePath(path)), recursive = TRUE)
  }
}

### Get endpoints name
re_type_stats <- function(url){
  return(regmatches(url, regexpr('(?<=\\/)[[:alnum:]]+(?=\\?)', url, perl = TRUE)))
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
requests_pbpstats <- function(url, season, team_id, game_date, season_type, count, n_rep=5, ...){
  
  pbpstats_params <- list(
    TeamId = team_id,
    Season = paste(season, substr(season + 1, 3, 4), sep = '-'),
    SeasonType = I(season_type),
    OffDef = 'Offense',
    StartType = 'All',
    FromDate = game_date,
    ToDate = game_date
  )

  res <- trycatch_pbpstats(url, season, 10, pbpstats_request_headers, pbpstats_params, team_id, game_date, count, n_rep, ...)
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

league_game_log <- function(season, ...){
  url <- 'https://stats.nba.com/stats/leaguegamelog?'
  
  count <- 1
  response <- requests_nba(url, count, 5, Season = season, ...)
  json <- fromJSON(content(response, as = "text"))
  
  nba_data <- tryCatch({data.frame(matrix(unlist(json$resultSets$rowSet[[1]]), ncol = length(json$resultSets$headers[[1]]), byrow = FALSE))}, error = function(e) return(NULL))
  if(is.null(nba_data)){
    return(NULL)
  }
  names(nba_data) <- json$resultSets$headers[[1]]
  
  return(nba_data)
}

load_datanba <- function(game_id, season, gamelog, ...){
  url <- paste0("https://data.nba.com/data/v2015/json/mobile_teams/nba/", season, "/scores/pbp/", game_id, "_full_pbp.json")
  
  count <- 1
  response <- trycatch_datanba(url, 10, nba_request_headers, count, 5)
  json <- fromJSON(content(response, as = "text", encoding = 'UTF-8'))
  
  game_id <- json$g$gid
  period <- json$g$pd$p
  
  data <- bind_rows(lapply(period, function(period){mutate(json$g$pd$pla[[period]], PERIOD = period)}))
  data <- mutate(data, GAME_ID = game_id)
  
  return(data)
}

load_pbpstats <- function(game_id, season, gamelog, ...){
  
  ### Get game date
  if (season < 2000){
    message('Statistics on pbpstats.com start from 2000/01 season')
    return(NULL)
  }
  season_type <- ifelse(substr(game_id, 1, 3) == '002', 'Regular%2BSeason', 'Playoffs')
  game_date <- unique(gamelog[gamelog$GAME_ID == game_id, "GAME_DATE"])
  team_id <- gamelog[gamelog$GAME_ID == game_id, "TEAM_ID"]
  
  ### Get offense possessions teams
  count <- 1
  url <- 'https://api.pbpstats.com/get-possessions/nba'
  
  response <- lapply(team_id, requests_pbpstats, url = url, season = season, game_date = game_date, season_type = season_type, count = count, n_rep = 5)
  
  pbp_data <- bind_rows(lapply(response, function(x){
    json <- fromJSON(content(x, as = "text", encoding = 'UTF-8'))
    pbp_data <- json[['possessions']]
    
    pbp_data <- pbp_data %>%
      unnest(., VideoUrls, keep_empty = TRUE) %>%
      rename_all(toupper)
  }))
  
  return(pbp_data)
}

load_playbyplayv2 <- function(game_id, season, gamelog, ...){
  url <- 'https://stats.nba.com/stats/playbyplayv2?'
  
  ## application request counter
  count <- 1
  
  response <- requests_nba(url, count, 5, GameID = game_id, ...)
  json <- fromJSON(content(response, as = "text"))
  
  nba_data <- tryCatch({data.frame(matrix(unlist(json$resultSets$rowSet[[1]]), ncol = length(json$resultSets$headers[[1]]), byrow = FALSE))}, error = function(e) return(NULL))
  if(is.null(nba_data)){
    return(NULL)
  }
  names(nba_data) <- json$resultSets$headers[[1]]
  
  return(nba_data)
}

load_shotchartdetail <- function(team_id, season, ...){
  url <- 'https://stats.nba.com/stats/shotchartdetail?'
  season <- paste(season, substr(season + 1, 3, 4), sep = '-')
  
  count <- 1
  response <- requests_nba(url, count, 5, TeamID = as.character(team_id), Season = season, ...)
  json <- jsonlite::fromJSON(httr::content(response, as = "text"))
  raw_data <- json$resultSets$rowSet[[1]]
  col_names <- json$resultSets$headers[[1]]
  nba_data <- tryCatch({data.frame(matrix(unlist(raw_data), ncol = length(col_names), byrow = FALSE))}, error = function(e) return(0))
  if(!is.data.frame(nba_data)){
    return(0)
  }
  tryCatch({names(nba_data) <- col_names}, error = function(e) return(nba_data))
  return(nba_data)
}

load_season_shotchartdetail <- function(season, seasontype, early_stop = 5){
  season <- as.integer(season)
  season_type <- ifelse(seasontype == 'Playoffs', 'po', 'rg')
  
  early_st <- 0
  for (i in seq_along(team_dict)){
    
    if (file.exists(suppressWarnings(normalizePath(paste('./datasets', season, season_type, 'shotdetail', paste0(names(team_dict[i]), '.csv'), sep = '/'))))){
      next
    }
    
    t <- load_shotchartdetail(team_dict[[i]], season, SeasonType = seasontype)
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
    
    write.csv(t, file = suppressWarnings(normalizePath(paste('./datasets',  season, season_type, 'shotdetail', paste0(names(team_dict[i]), '.csv'), sep = '/'))),
              row.names = FALSE)
    Sys.sleep(5)
  }
}

load_season_pbp <- function(season, start=1, end=1230, datatype = 'all', seasontype = 'rg', early_stop = 5, verbose='FALSE'){
  
  if(datatype %in% c('all', 'pbp')){
    exists_folder(path=paste('datasets', season, seasontype, sep = '/'))
    exists_folder(path=paste('datasets', season, seasontype, 'nbastats', sep = '/'))
    if (season >= 2000){
      exists_folder(path=paste('datasets', season, seasontype, 'pbpstats', sep = '/'))
    }
    if (season >= 2016){
      exists_folder(path=paste('datasets', season, seasontype, 'datanba', sep ='/'))
    }
  }
  if(datatype %in% c('all', 'shot')){
    exists_folder(path=paste('datasets', season, seasontype, 'shotdetail', sep = '/'))
  }
  request_seasontype <- switch (seasontype,
                                'rg' = I('Regular+Season'),
                                'po' = 'Playoffs'
  )
  
  if(datatype %in% c('all', 'shot')){
    load_season_shotchartdetail(season, request_seasontype)
  }
  
  early_st <- 0
  sleep <- 1

  if(datatype %in% c('all', 'pbp')){
    gamelog <- league_game_log(season = season, SeasonType = request_seasontype)
    if(request_seasontype == 'Playoffs'){
      games_id <- unique(gamelog$GAME_ID)
    } else {
      start <- as.integer(paste0(paste0(substr(season, 3, 4), '0'), paste0(paste(rep('0', 4 - nchar(start)), collapse = ''), start)))
      end <- as.integer(paste0(paste0(substr(season, 3, 4), '0'), paste0(paste(rep('0', 4 - nchar(end)), collapse = ''), end)))
      games_id <- sapply(seq(start, end), function(x) paste0('002', x))
    }
    
    for (i in games_id){

      exists_nbastats <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, seasontype, 'nbastats', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))
      exists_pbpstats <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, seasontype, 'pbpstats', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))
      exists_nbadata <- as.integer(!file.exists(suppressWarnings(normalizePath(paste('./datasets', season, seasontype, 'datanba', paste0(paste(season, i, sep = '_'), '.csv'), sep = '/')))))
      
      if(sum(c(exists_nbastats, exists_pbpstats, exists_nbadata)) == 0){
        next
      } else {
        if (sleep %% 100 == 0){
          Sys.sleep(600)
        }
        
        sleep <- sleep + 1
        for(n in c("load_playbyplayv2"[exists_nbastats], "load_pbpstats"[exists_pbpstats], "load_datanba"[exists_nbadata])){
          if(season < 2000){
            if(n %in% c("load_pbpstats")){
              next
            }
          } else if(season < 2016){
            if(n == "load_datanba"){
              next
            }
          }
          
          dt <- do.call(n, list(game_id = i, season = season, gamelog = gamelog))
          
          if(n == "load_playbyplayv2"){
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
          pbp_folder <- switch(n,
                               "load_playbyplayv2" = "nbastats",
                               "load_pbpstats" = "pbpstats",
                               "load_datanba" = "datanba")

          write.csv(dt, file = suppressWarnings(normalizePath(paste('./datasets', season, seasontype, 
                                                                    pbp_folder, paste0(paste(season, i, sep = '_'), '.csv'), sep = '/'))), 
                    row.names = FALSE)
        }
      }
      
      Sys.sleep(5)
    }
  }
}
