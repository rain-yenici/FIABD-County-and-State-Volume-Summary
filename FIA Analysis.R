# imports

library(rFIA)
library(sf)
library(terra)
library(geodata)
library(dplyr)

# which state is analysed (used for automation of multiple states) is inputted thru args
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Missing state name or state abbreviation.")
}

state_name <- args[1]
state_abbr <- args[2]

cat("Selected state:", state_name, "\n")
cat("FIA abbreviation:", state_abbr, "\n")

data_dir <- file.path("Data", paste(state_name, "FIA"))

if (!dir.exists(data_dir) || length(list.files(data_dir)) == 0) {
  cat("FIA data for", state_name, "not found. Downloading...\n")
  dir.create(
    data_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )

  options(timeout = 3600)

  getFIA(
    states = state_abbr,
    dir = data_dir,
    common = FALSE
  )
} else {
  cat("FIA data for", state_name, "found in", data_dir, "\n")
}

db <- readFIA(dir = data_dir, common = FALSE)


# indentify currrent volume evaulation years in the FIA database
volume_evalids <- findEVALID(db, type = "VOL")
# keep only valid years
db_volume <- clipFIA(
  db,
  mostRecent = FALSE,
  evalid = volume_evalids
)

# if shape file exists, add here for county specific analysis
#shpbndy<- st_read("Data/Florida 5 FIA/FL5Cntys.shp")
#db <- clipFIA(db, mask = shpbndy)

# reference file for decoding state codes
reference <- read.csv("Data/FIADB_REFERENCE/REF_RESEARCH_STATION.csv")


# inspect loaded tables and available evaluation years
#print(names(db))
#db$POP_EVAL %>% select(EVALID, EVAL_DESCR, END_INVYR)


# VOLCFNET & VOLCFGRS by County within a state

# calculates total volume by state and county

volume_net <- volume(
  db = db_volume,
  grpBy = c(STATECD, COUNTYCD),
  landType = "forest",
  treeType = "live",
  volType = "NET",
  totals = TRUE
)

volume_gross <- volume(
  db = db_volume,
  grpBy = c(STATECD, COUNTYCD),
  landType = "forest",
  treeType = "live",
  volType = "GROSS",
  totals = TRUE
)

# combines net and gross volume estimates
volume_county <- volume_net %>%
  select(STATECD, COUNTYCD, YEAR, VOLCFNET = BOLE_CF_TOTAL) %>%
  left_join(
    volume_gross %>%
      select(STATECD, COUNTYCD, YEAR, VOLCFGRS = BOLE_CF_TOTAL),
    by = c("STATECD", "COUNTYCD", "YEAR")
  )


# adds county names (provided in COUNTYNM)
volume_county <- volume_county %>%
  left_join(
    db$COUNTY %>%
      select(STATECD, COUNTYCD, COUNTYNM) %>%
      distinct(),
    by = c("STATECD", "COUNTYCD")
  )

# adds state names using the reference file and state code
volume_county <- volume_county %>%
  left_join(
    reference %>%
      select(STATECD, STATE_NAME, STATE_ABBR) %>%
      distinct(),
    by = "STATECD"
  )

# rearranging the columns
volume_county <- volume_county %>%
  select(
    STATE_NAME,
    COUNTYNM,
    YEAR,
    VOLCFNET,
    VOLCFGRS
  )

#print("--- FIA: VOLCFNET & VOLCFGRS by County within" + state + " ---")
#print(volume_county)

# create the results/{statename} folder if it doesn't exist
results_path <- paste0("Results/", gsub(" ", "_", state_name))

dir.create(results_path, recursive = TRUE, showWarnings = FALSE)

# gather all data for the years available
years <- sort(unique(volume_county$YEAR))

# export one cvs year for each year
for (yr in years) {

  yearly_data <- volume_county %>%
    filter(YEAR == yr) %>%
    select(
      STATE_NAME,
      COUNTYNM,
      VOLCFNET,
      VOLCFGRS
    )

  filename <- paste0(
    results_path,
    "/FIA_VOLCFNET_VOLCFGRS_",
    gsub(" ", "_", state_name),
    "_",
    yr,
    ".csv"
  )

  print(filename)

  write.csv(
    yearly_data,
    filename,
    row.names = FALSE
  )

  cat("Saved:", filename, "\n")
}