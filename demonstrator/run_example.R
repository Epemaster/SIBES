# Run from repository root: Rscript demonstrator/run_example.R
# Demonstration uses only the included example dataset; it does NOT download
# or validate the complete NIOZ SIBES dataset.
source("demonstrator/R/indicators.R")
data("SIBES_dataset",package="SIBES")
station <- compute_station_indicators(
  samples=SIBES_dataset$samples,
  biota=SIBES_dataset$biota,
  empty_as_zero=FALSE
)
dir.create("demonstrator/output",recursive=TRUE,showWarnings=FALSE)
write.csv(station,"demonstrator/output/station_indicators.csv",row.names=FALSE)
write.csv(summarise_year_basin(station),
          "demonstrator/output/year_basin_summary.csv",row.names=FALSE)
message("Preliminary indicators written to demonstrator/output (not an EarthScore rating).")
