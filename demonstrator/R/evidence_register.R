# Evidence/provenance registry for the Waddenzee EarthScore demonstrator.
# SHA-256 requires the 'digest' R package: install.packages("digest").
# Original retrieval dates, dataset versions and permissions must be validated
# separately. Processing time is NOT an original data retrieval timestamp.

build_evidence_manifest <- function(paths,
                                    dataset_doi = "10.25850/nioz/7b.b.ug",
                                    source_url = "https://doi.nioz.nl/dataset/sibes-dataset",
                                    dataset_license = "CC BY-SA 4.0",
                                    dataset_version = "UNVERIFIED",
                                    retrieved_utc = NA_character_) {
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop("Install the 'digest' package to compute mandatory SHA-256 hashes")
  }
  if (!length(paths) || any(!file.exists(paths))) {
    stop("All manifest inputs must be existing local files")
  }
  if (anyDuplicated(basename(paths))) stop("Input filenames must be unique")
  processed_utc <- format(as.POSIXct(Sys.time(), tz = "UTC"),
                          "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  data.frame(
    source_provider = rep("NIOZ", length(paths)),
    dataset_doi = rep(dataset_doi, length(paths)),
    source_url = rep(source_url, length(paths)),
    dataset_version = rep(dataset_version, length(paths)),
    source_license = rep(dataset_license, length(paths)),
    source_retrieved_utc = rep(retrieved_utc, length(paths)),
    processed_utc = rep(processed_utc, length(paths)),
    filename = basename(paths),
    file_bytes = as.numeric(file.info(paths)$size),
    sha256 = vapply(paths, function(p) digest::digest(file = p, algo = "sha256"),
                    character(1), USE.NAMES = FALSE),
    stringsAsFactors = FALSE
  )
}
