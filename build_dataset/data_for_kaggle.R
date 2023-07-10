full_path <- list.files(path = "../datasets", full.names = TRUE)
files_name <- list.files(path = "../datasets", full.names = FALSE)

for(i in seq_along(full_path)){
  file_name <- regmatches(files_name[i], regexpr('.+(?=\\.tar)', files_name[i], perl = TRUE))
  print(file_name)
  untar(full_path[i])
  df <- data.table::fread(paste0(file_name, '.csv'))
  if(strsplit(file_name, '_')[[1]][1] == 'nbastats'){
    df[, c('MIN', 'SEC') := data.table::tstrsplit(PCTIMESTRING, ':')][
      , c('MIN', "SEC") := lapply(.SD, as.integer), .SDcols = c('MIN', 'SEC')
    ][
      , PCTIMESTRING := data.table::fifelse(PERIOD < 5, abs((MIN * 60 + SEC) - 720 * PERIOD), abs((MIN * 60 + SEC) - (2880 + 300 * (PERIOD - 4))))
    ][
      , c('MIN', 'SEC') := NULL
    ][
      , SCOREMARGIN := data.table::fifelse(SCOREMARGIN == '', NA_integer_,
                                           data.table::fifelse(SCOREMARGIN == 'TIE', 0, as.double(SCOREMARGIN)))
    ][
      , PERSON1TYPE := data.table::fifelse(is.na(PERSON1TYPE), 0, PERSON1TYPE)
    ]
  }
  unlink(paste0(file_name, '.csv'))
  data.table::fwrite(df, paste('../for_kaggle', paste0(file_name, '.csv'), sep = '/'))
}