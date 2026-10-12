source("demonstrator/R/indicators.R")

samples <- data.frame(sample_id=c("a","b","c"),date=as.Date(c("2020-09-01","2020-09-02","2021-09-02")),
 tidal_basin_name=c("Vlie","Vlie","Eierlandse Gat"))
biota <- data.frame(sample_id=c("a","a","b"),sibes_id=c(11,12,11),
 abundance_m2=c(2,3,4),afdm_m2=c(1,2,3))
out <- compute_station_indicators(samples,biota)
stopifnot(nrow(out)==3, out$abundance_m2[1]==5, out$afdm_m2[1]==3,
 out$station_species_richness[1]==2, is.na(out$abundance_m2[3]),
 out$observation_status[3]=="not_verified")
by_basin <- summarise_year_basin(out)
stopifnot(nrow(by_basin)==2, sum(by_basin$n_stations)==3,
 sum(by_basin$n_without_verified_observation)==1)
zero <- compute_station_indicators(samples,biota,empty_as_zero=TRUE)
stopifnot(zero$abundance_m2[3]==0,zero$observation_status[3]=="zero_assumed_after_review")
bad <- biota
bad$sample_id[1] <- "unknown"
stopifnot(inherits(try(compute_station_indicators(samples,bad),silent=TRUE),"try-error"))
missing <- biota
missing$afdm_m2[1] <- NA_real_
stopifnot(is.na(compute_station_indicators(samples,missing)$afdm_m2[1]))
duplicate <- rbind(samples,samples[1,])
stopifnot(inherits(try(compute_station_indicators(duplicate,biota),silent=TRUE),"try-error"))
cat("Waddenzee indicator tests passed\n")
