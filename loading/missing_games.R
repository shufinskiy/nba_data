`%>%` <- magrittr::`%>%`

source('utils.R')
source('helpers.R')
source('../function_for_download/get_nba_data.R')

check_data_from_github <- function(season, seasontype = 'rg', datatype = 'nbastats', league = 'nba', local_path = NA, verbose = TRUE){
  
  season_limit <- list(
    ## order limits: nbastats(v2 and v3),pbpstats, datanba, cdnnba
    "nba" = c(1996, 2000, 2016, 2020),
    "wnba" = c(1997, 2009, 2017, 2022)
  )
  season_limit <- season_limit[[league]]
  
  if((datatype %in% c('nbastats', 'nbastatsv3') & season < season_limit[1]) | (datatype == 'pbpstats' & season < season_limit[2]) | (datatype == 'datanba' & season < season_limit[3]) | (datatype == 'cdnnba' & season < season_limit[4])){
    return(data.frame(season = integer(),
                      seasontype = character(),
                      datatype = character(),
                      league = character(),
                      missing_games = integer(), stringsAsFactors = FALSE))
  }
  
  st_tmp <- if(seasontype == 'rg') '' else 'po_'
  if(is.na(local_path)){
    load_nba_data(seasons = season, data = datatype, seasontype = seasontype, untar = TRUE)
  } else {
    untar(paste0(local_path, '/', datatype, '_', st_tmp, season, '.tar.xz'))
  }
  df <- read.csv(paste0(datatype, '_', st_tmp, season, '.csv')) #TODO: не работает для регулярки
  unlink(paste0(datatype, '_', st_tmp, season, '.csv'))
  
  lid <- if (league == 'nba') '00' else '10'
  st <- if (seasontype == 'rg') I('Regular+Season') else 'Playoffs'
  gamelog <- league_game_log(season = season, league_id = lid, SeasonType = st)
  
  games_id <- if (datatype %in% c('cdnnba', 'nbastatsv3')) 'gameId' else  if (datatype == 'pbpstats') 'GAMEID' else 'GAME_ID'
    
  game_id_files <- unique(df[[games_id]])
  game_id_gamelog <- unique(gamelog$GAME_ID)
  
  etalon <- sort(sapply(game_id_gamelog, as.integer, USE.NAMES = FALSE, simplify = TRUE))
  diff <- setdiff(etalon, game_id_files)
  
  if(length(diff) == 0){
    if(verbose){
      print('ID игр и их количество совпадают с эталоном')
    }
    return(data.frame(season = integer(),
                      seasontype = character(),
                      datatype = character(),
                      league = character(),
                      missing_games = integer(), stringsAsFactors = FALSE))
  } else {
    if(verbose){
      print(diff)
    }
    return(data.frame(season = season,
                      seasontype = seasontype,
                      datatype = datatype,
                      league = league,
                      missing_games = diff, stringsAsFactors = FALSE))
  }
}

check_data_from_tmp_files <- function(path, season, seasontype = 'rg', datatype = 'nbastats', league = 'nba', verbose = TRUE){
  
  season_limit <- list(
    ## order limits: nbastats(v2 and v3),pbpstats, datanba, cdnnba
    "nba" = c(1996, 2000, 2016, 2020),
    "wnba" = c(1997, 2009, 2017, 2022)
  )
  season_limit <- season_limit[[league]]
  
  if((datatype %in% c('nbastats', 'nbastatsv3') & season < season_limit[1]) | (datatype == 'pbpstats' & season < season_limit[2]) | (datatype == 'datanba' & season < season_limit[3]) | (datatype == 'cdnnba' & season < season_limit[4])){
    return(data.frame(season = integer(),
                      seasontype = character(),
                      datatype = character(),
                      league = character(),
                      missing_games = integer(), stringsAsFactors = FALSE))
  }
  
  l <- list.files(paste(path, season, seasontype, league, datatype, sep='/'), pattern = 'csv$')
  
  if(length(l) == 0){
    print('Не найдено')
    return(data.frame(season = season,
                      seasontype = seasontype,
                      datatype = datatype,
                      league = league,
                      missing_games = 1, stringsAsFactors = FALSE))
  }
  game_id_files <- sort(sapply(l, function(game_id){
    as.integer(regmatches(game_id, m = regexpr("\\d{10}", game_id)))
  }, USE.NAMES = FALSE, simplify = TRUE))
  
  lid <- if (league == 'nba') '00' else '10'
  st <- if (seasontype == 'rg') I('Regular+Season') else 'Playoffs'
  gamelog <- league_game_log(season = season, league_id = lid, SeasonType = st)
  game_id_gamelog <- unique(gamelog$GAME_ID)
  etalon <- sort(sapply(game_id_gamelog, as.integer, USE.NAMES = FALSE, simplify = TRUE))
  
  diff <- setdiff(etalon, game_id_files)
  
  if(length(diff) == length(etalon)){
    print('ID игр и их количество совпадают с эталоном')
    return(data.frame(season = season,
                      seasontype = seasontype,
                      datatype = datatype,
                      league = league,
                      missing_games = 1, stringsAsFactors = FALSE))
  }
  
  if(length(diff) == 0){
    if(verbose){
      print('ID игр и их количество совпадают с эталоном')
    }
    return(data.frame(season = integer(),
                      seasontype = character(),
                      datatype = character(),
                      league = character(),
                      missing_games = integer(), stringsAsFactors = FALSE))
  } else {
    if(verbose){
      print(diff)
    }
    return(data.frame(season = season,
                      seasontype = seasontype,
                      datatype = datatype,
                      league = league,
                      missing_games = diff, stringsAsFactors = FALSE))
  }
}

miss_games <- data.frame(season = integer(),
                         seasontype = character(),
                         datatype = character(),
                         league = character(),
                         missing_games = integer(), stringsAsFactors = FALSE)

check_data_from_github(season = 2000, datatype = 'pbpstats')

for(season in seq(1996, 2023)){
  for(data in c("datanba", "nbastats", "pbpstats", "cdnnba", "nbastatsv3")){
    for(st in c('rg', 'po')){
      miss_game <- check_data_from_github(season = season, 
                                          seasontype = st,
                                          datatype = data,
                                          league = 'nba',
                                          verbose = FALSE)
      miss_games <- rbind(miss_games, miss_game)
    }
  }
}
