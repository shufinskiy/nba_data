#! /opt/R/4.0.2/bin/Rscript --vanilla

library(httr, warn.conflicts = FALSE)
library(jsonlite, warn.conflicts = FALSE)
library(dplyr, warn.conflicts = FALSE)
library(tidyr, warn.conflicts = FALSE)
library(stringr, warn.conflicts = FALSE)

source('helpers.R')
source('utils.R')

command_line_work(get_season_pbp_full)