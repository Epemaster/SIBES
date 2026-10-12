# Waddenzee EarthScore demonstrator: transparent, preliminary SIBES indicators.
# Standalone functions. No changes to the NIOZ SIBES R package are required.
# This file is distributed under GPL-3.0, consistent with the parent repository.

assert_columns <- function(data, required, dataset) {
  missing <- setdiff(required, names(data))
  if (length(missing)) {
    stop(dataset, " is missing required columns: ", paste(missing, collapse = ", "))
  }
}

aggregate_complete <- function(values, keys) {
  # Preserve NA when any constituent measurement is missing; never turn NA into 0.
  out <- tapply(values, keys, function(x) {
    if (anyNA(x) || any(!is.finite(x))) NA_real_ else sum(x)
  })
  as.numeric(out[unique(keys)]) # helper not used for matching
}

compute_station_indicators <- function(samples, biota, empty_as_zero = FALSE) {
  assert_columns(samples, c("sample_id", "date", "tidal_basin_name"), "samples")
  assert_columns(biota, c("sample_id", "sibes_id", "abundance_m2", "afdm_m2"), "biota")
  if (!is.logical(empty_as_zero) || length(empty_as_zero) != 1L ||
      is.na(empty_as_zero)) stop("empty_as_zero must be TRUE or FALSE")

  samples <- as.data.frame(samples, stringsAsFactors = FALSE)
  biota <- as.data.frame(biota, stringsAsFactors = FALSE)
  samples$sample_id <- as.character(samples$sample_id)
  biota$sample_id <- as.character(biota$sample_id)
  if (anyNA(samples$sample_id) || any(!nzchar(samples$sample_id)) ||
      anyDuplicated(samples$sample_id)) {
    stop("samples requires a non-empty, unique sample_id per record")
  }
  if (anyNA(biota$sample_id) || any(!nzchar(biota$sample_id)) ||
      any(!biota$sample_id %in% samples$sample_id)) {
    stop("biota contains missing or unmatched sample_id; inspect the input versions")
  }
  dates <- as.Date(samples$date)
  if (anyNA(dates)) stop("Invalid or missing sample date")
  if (!is.numeric(biota$abundance_m2) || !is.numeric(biota$afdm_m2)) {
    stop("SIBES abundance_m2 and afdm_m2 must be numeric")
  }
  if (any(biota$abundance_m2 < 0, na.rm = TRUE) ||
      any(biota$afdm_m2 < 0, na.rm = TRUE)) {
    stop("Negative abundance or biomass value requires scientific QC")
  }

  all_ids <- samples$sample_id
  has_biota <- all_ids %in% biota$sample_id
  count_or_na <- function(x) {
    if (anyNA(x) || any(!is.finite(x))) NA_real_ else sum(x)
  }
  if (nrow(biota)) {
    count_by_sample <- tapply(biota$abundance_m2, biota$sample_id, count_or_na)
    mass_by_sample <- tapply(biota$afdm_m2, biota$sample_id, count_or_na)

    # Richness counts distinct, detected taxon IDs rather than number of rows.
    present <- (!is.na(biota$abundance_m2) & biota$abundance_m2 > 0) |
      (!is.na(biota$afdm_m2) & biota$afdm_m2 > 0)
    richness_by_sample <- tapply(seq_len(nrow(biota)), biota$sample_id, function(idx) {
      if (anyNA(biota$sibes_id[idx])) return(NA_real_)
      length(unique(as.character(biota$sibes_id[idx][present[idx]])))
    })
    abundance <- unname(as.numeric(count_by_sample[all_ids]))
    biomass <- unname(as.numeric(mass_by_sample[all_ids]))
    richness <- unname(as.numeric(richness_by_sample[all_ids]))
  } else {
    abundance <- biomass <- richness <- rep(NA_real_, length(all_ids))
  }

  # Absence of a biota row is ambiguous until sampling completeness is established.
  # The optional policy can be used only after verifying true non-detection.
  if (empty_as_zero) {
    abundance[!has_biota] <- 0
    biomass[!has_biota] <- 0
    richness[!has_biota] <- 0
  }
  result <- data.frame(
    sample_id = all_ids,
    date = dates,
    year = as.integer(format(dates, "%Y")),
    tidal_basin_name = as.character(samples$tidal_basin_name),
    abundance_m2 = abundance,
    afdm_m2 = biomass,
    station_species_richness = richness,
    has_biota_record = has_biota,
    observation_status = ifelse(
      has_biota, "biota_reported",
      if (empty_as_zero) "zero_assumed_after_review" else "not_verified"
    ),
    stringsAsFactors = FALSE
  )
  if (anyNA(result$tidal_basin_name) ||
      any(!nzchar(result$tidal_basin_name))) {
    stop("Missing tidal_basin_name; do not silently assign locations")
  }
  result
}

summarise_year_basin <- function(station_indicators) {
  assert_columns(station_indicators,
                 c("year", "tidal_basin_name", "abundance_m2", "afdm_m2",
                   "station_species_richness", "observation_status"),
                 "station_indicators")
  if (!nrow(station_indicators)) stop("No station records to summarise")
  groups <- split(station_indicators,
                  interaction(station_indicators$year,
                              station_indicators$tidal_basin_name, drop = TRUE))
  mean_known <- function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
  rows <- lapply(groups, function(x) {
    data.frame(
      year = x$year[1],
      tidal_basin_name = x$tidal_basin_name[1],
      n_stations = nrow(x),
      n_with_biota = sum(x$observation_status == "biota_reported"),
      n_without_verified_observation = sum(x$observation_status == "not_verified"),
      n_zero_assumed = sum(x$observation_status == "zero_assumed_after_review"),
      n_valid_biomass = sum(!is.na(x$afdm_m2)),
      mean_abundance_m2 = mean_known(x$abundance_m2),
      mean_afdm_m2 = mean_known(x$afdm_m2),
      mean_station_species_richness = mean_known(x$station_species_richness),
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result[order(result$year, result$tidal_basin_name), , drop = FALSE]
}
