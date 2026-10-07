# imports

library(rFIA)
library(sf)
library(terra)
library(geodata)
library(dplyr)

# path for data extraction
datapath<- "Data/Florida 5 FIA/FIA_Data"

# readFIA() reads all standard FIA CSV files from the directory
# (e.g., FL_PLOT.csv, FL_TREE.csv).
db <- readFIA(dir = datapath, common = FALSE)




# if shape file exists, add here for county specific analysis
#shpbndy<- st_read("Data/Florida 5 FIA/FL5Cntys.shp")
#db <- clipFIA(db, mask = shpbndy)

# reference file for decoding state codes
reference <- read.csv("Data/FIADB_REFERENCE/REF_RESEARCH_STATION.csv")


# inspect loaded tables and available evaluation years
print(names(db))
db$POP_EVAL %>% select(EVALID, EVAL_DESCR, END_INVYR)


# VOLCFNET & VOLCFGRS by County within FL

# calculates total volume by state and county
volume_county <- db$TREE %>%
  group_by(STATECD, COUNTYCD) %>%
  summarise(
    VOLCFNET = sum(VOLCFNET, na.rm = TRUE),
    VOLCFGRS = sum(VOLCFGRS, na.rm = TRUE),
    .groups = "drop"
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
    VOLCFNET,
    VOLCFGRS
  )

print("--- FIA: VOLCFNET & VOLCFGRS by County ---")
print(volume_county)

# save the results to a csv file
write.csv(
  volume_county,
  "Results/FIA_VOLCFNET_VOLCFGRS_by_County.csv",
  row.names = FALSE
)
