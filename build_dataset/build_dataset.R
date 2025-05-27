build_season_data <- function(season, folder = '../loading/datasets', seasontype = 'rg', league = 'nba', data = 'nbastats', save = FALSE){
  l <- list.files(paste(folder, season, seasontype, league, data, sep = '/'), full.names = TRUE)
  df <- data.table::rbindlist(lapply(l, data.table::fread), fill = TRUE)
  if(save){
    seasontype <- if (seasontype == 'rg') '_' else '_po_'
    league_name <- if (league == 'wnba') 'wnba_' else ''
    data.table::fwrite(df, paste0(league_name, data, seasontype,  season, '.csv'))
  } else {
    return(df)
  }
}

dataset_for_github <- function(files, tar_file, compression = 'xz', compression_level = 9, tar = 'tar'){
  tar(tar_file, files = files, compression = 'xz', compression_level = 9, tar = 'tar')
  if(file.copy(tar_file, paste0('../datasets/', tar_file))){
    file.remove(tar_file)
    file.remove(files)
  }
}

check_datatype <- function(season, folder = '../loading/datasets', seasontype = 'rg', league = 'nba', data = 'nbastats'){
  check_dir <- dir.exists(paste(folder, season, seasontype, league, data, sep = '/'))
  return(check_dir)
}

upd_list_data <- function(path="../list_data.txt", path_data="../datasets/"){
  l <- list.files(path_data, pattern = "tar.xz")
  
  files_str <- sapply(l, function(file_str){
    paste0(gsub(".tar.xz", "", file_str), "=https://github.com/shufinskiy/nba_data/raw/main/datasets/", file_str)
  }, USE.NAMES = FALSE)
  
  write(files_str, file = file(path), sep="")
}

dt <- NA
st <- 'rg'
league <- 'wnba'

for(season in seq(2025, 2025)){
  season_limit <- list(
    # order limits: nbastats(v2 and v3),pbpstats, datanba, cdnnba, matchups
    "nba" = c(1996, 2000, 2016, 2020, 2017),
    "wnba" = c(1997, 2009, 2017, 2022)
  )
  season_limit <- season_limit[[league]]
  if (league == 'nba'){
    if(season < season_limit[2]){
      datatype <- c('nbastats', 'nbastatsv3', 'shotdetail')
    } else if(season < season_limit[3]){
      datatype <- c('nbastats', 'nbastatsv3', 'shotdetail', 'pbpstats')
    } else if(season < season_limit[5]){
      datatype <- c('nbastats', 'nbastatsv3', 'shotdetail', 'pbpstats', 'datanba')
    } else if(season < season_limit[4]){
      datatype <- c('nbastats', 'nbastatsv3', 'shotdetail', 'pbpstats', 'datanba', 'matchups')
    } else {
      datatype <- c('nbastats', 'nbastatsv3', 'shotdetail', 'pbpstats', 'datanba', 'matchups', 'cdnnba')
    }   
  } else {
    if(season < season_limit[2]){
      datatype <- c('nbastats', 'nbastatsv3', 'shotdetail')
    } else if(season < season_limit[3]){
      datatype <- c('nbastats', 'nbastatsv3', 'shotdetail', 'pbpstats')
    } else if(season < season_limit[4]){
      datatype <- c('nbastats', 'nbastatsv3', 'shotdetail', 'pbpstats', 'datanba')
    } else {
      datatype <- c('nbastats', 'nbastatsv3', 'shotdetail', 'pbpstats', 'datanba', 'cdnnba')
    }
  }

  if(!is.na(dt)){
    datatype <- dt
  }
  for(data in datatype){
    dt_exists <- check_datatype(season = season, seasontype = st, league = league, data = data)
    if(dt_exists){
      build_season_data(season = season, seasontype = st, data = data, league = league, save=TRUE)
      seasontype <- if (st == 'rg') '_' else '_po_'
      league_name <- if (league == 'wnba') 'wnba_' else ''
      dataset_for_github(files = paste0(league_name, data, seasontype, season, '.csv'), tar_file = paste0(league_name, data, seasontype, season, '.tar.xz'))
      seasontype <- if (seasontype == '_') 'rg' else 'po'
    }
  }
}

upd_list_data()