nba_request_headers <- c(
  "Connection"= 'keep-alive',
  "Accept"= 'application/json, text/plain, */*',
  "x-nba-stats-token"= 'true',
  "X-NewRelic-ID"= 'VQECWF5UChAHUlNTBwgBVw==',
  "User-Agent"= 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36',
  "x-nba-stats-origin"= 'stats',
  "Sec-Fetch-Site"= 'same-origin',
  "Sec-Fetch-Mode"= 'cors',
  "Referer"= 'https=//stats.nba.com',
  "Accept-Encoding"= 'gzip, deflate, br',
  "Accept-Language"= 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7'
)

pbpstats_request_headers <- c(
  "user-agent" = "Mozilla/5.0"
)

### endpoints
nba_params <- list(
  
  playbyplayv2 = list(
    EndPeriod = 10,
    GameID = 0,
    StartPeriod = 1
  ),
  
  boxscoretraditionalv2 = list(
    EndPeriod = 10,
    EndRange = 0,
    GameID = 0,
    RangeType = 0,
    StartPeriod = 1,
    StartRange = 0
  ),

  boxscoresummaryv2 = list(
    GameID = 0
  ),
  
  shotchartdetail = list(
    AheadBehind = '',
    CFID = '',
    CFPARAMS = '',
    ClutchTime = '',
    Conference = '',
    ContextFilter = '',
    ContextMeasure = 'FGA',
    DateFrom = '',
    DateTo = '',
    Division = '',
    EndPeriod = '10',
    EndRange = '28800',
    GROUP_ID = '',
    GameEventID = '',
    GameID = '',
    GameSegment = '',
    GroupID = '',
    GroupMode = '',
    GroupQuantity = '5',
    LastNGames = '0',
    LeagueID = '00',
    Location = '',
    Month = '0',
    OnOff = '',
    OpponentTeamID = '0',
    Outcome = '',
    PORound = '0',
    Period = '0',
    PlayerID = '0',
    PlayerID1 = '',
    PlayerID2 = '',
    PlayerID3 = '',
    PlayerID4 = '',
    PlayerID5 = '',
    PlayerPosition = '',
    PointDiff = '',
    Position = '',
    RangeType = '0',
    RookieYear = '',
    Season = '',
    SeasonSegment = '',
    SeasonType = I('Regular+Season'),
    ShotClockRange = '',
    StartPeriod = '1',
    StartRange = '0',
    StarterBench = '',
    TeamID = 'S',
    VsConference = '',
    VsDivision = '',
    VsPlayerID1 = '',
    VsPlayerID2 = '',
    VsPlayerID3 = '',
    VsPlayerID4 = '',
    VsPlayerID5 = '',
    VsTeamID = ''
  )
  
)

### list Team ID
team_dict <- list(
  'ATL' = 1610612737,
  'BOS' = 1610612738,
  'BKN' = 1610612751,
  'CHA' = 1610612766,
  'CHI' = 1610612741,
  'CLE' = 1610612739,
  'DAL' = 1610612742,
  'DEN' = 1610612743,
  'DET' = 1610612765,
  'GSW' = 1610612744,
  'HOU' = 1610612745,
  'IND' = 1610612754,
  'LAC' = 1610612746,
  'LAL' = 1610612747,
  'MEM' = 1610612763,
  'MIA' = 1610612748,
  'MIL' = 1610612749,
  'MIN' = 1610612750,
  'NOP' = 1610612740,
  'NYK' = 1610612752,
  'OKC' = 1610612760,
  'ORL' = 1610612753,
  'PHI' = 1610612755,
  'PHX' = 1610612756,
  'POR' = 1610612757,
  'SAC' = 1610612758,
  'SAS' = 1610612759,
  'TOR' = 1610612761,
  'UTH' = 1610612762,
  'WAS' = 1610612764
)
