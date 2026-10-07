# ============================================================
# Forest Inventory and Analysis simple queries
# ============================================================
# Purpose: Generate summaries of BALIVE, TPA_LIVE,
#          and CARBON_L from both FIA (via rFIA) 
# ============================================================

# ============================================================
# help docs: https://doserlab.com/files/rfia/
# ============================================================

library(rFIA)
library(sf)
library(terra)
library(geodata)
library(dplyr)

# ============================================================
# SECTION 0: Download FIA CSVs from: https://research.fs.usda.gov/products/dataandtools/fia-datamart
# Change the datapath below to match where you extracted the data
datapath<- "Data/Florida 5 FIA/FIA_Data"
# ============================================================
# ============================================================
# SECTION 1: FIA STATE-LEVEL SUMMARY
# ============================================================

# ---- 1.1 Load Florida FIA data ----
# readFIA() reads all standard FIA CSV files from the directory
# (e.g., FL_PLOT.csv, FL_TREE.csv).
db <- readFIA(dir = datapath, common = FALSE)

# =======================================
# =======================================
# Note: skip if processing the entire state
# Load shapefile and clip FIA data to it
# Shapefile must be cast using geographic WGS 84 CRS
# =======================================
# I do not have access to FL5CNTYS.shp, so I will skip this step.
#shpbndy<- st_read("Data/Florida 5 FIA/FL5Cntys.shp")
#db <- clipFIA(db, mask = shpbndy)
# =======================================
# =======================================

# Reference file for decoding state codes
reference <- read.csv("Data/FIADB_REFERENCE/REF_RESEARCH_STATION.csv")


# Inspect loaded tables and available evaluation years
print(names(db))
db$POP_EVAL %>% select(EVALID, EVAL_DESCR, END_INVYR)


# VOLCFNET & VOLCFGRS by County within FL

# Calculates total volume by state and county
volume_county <- db$TREE %>%
  group_by(STATECD, COUNTYCD) %>%
  summarise(
    VOLCFNET = sum(VOLCFNET, na.rm = TRUE),
    VOLCFGRS = sum(VOLCFGRS, na.rm = TRUE),
    .groups = "drop"
  )

# Adds county names (provided in COUNTYNM)
volume_county <- volume_county %>%
  left_join(
    db$COUNTY %>%
      select(STATECD, COUNTYCD, COUNTYNM) %>%
      distinct(),
    by = c("STATECD", "COUNTYCD")
  )

# Adds state names using the reference file and state code
volume_county <- volume_county %>%
  left_join(
    reference %>%
      select(STATECD, STATE_NAME, STATE_ABBR) %>%
      distinct(),
    by = "STATECD"
  )

# Rearranging the columns
volume_county <- volume_county %>%
  select(
    STATE_ABBR,
    STATE_NAME,
    COUNTYNM,
    VOLCFNET,
    VOLCFGRS
  )

print("--- FIA: VOLCFNET & VOLCFGRS by County ---")
print(volume_county)

# Save the results to a csv file
write.csv(
  volume_county,
  "Results/FIA_VOLCFNET_VOLCFGRS_by_County.csv",
  row.names = FALSE
)
