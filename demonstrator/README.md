# Waddenzee Ecological EarthScore — exploratory demonstrator v0.1

**Status:** code scaffold; not an operational ecological score, verified MRV
system, restoration attribution, or financeable performance claim.

This folder is a **separate demonstration layer** extending the NIOZ SIBES
R package without changing its existing functions or the upstream baseline.

## Inputs and chain of custody

- Source: NIOZ SIBES dataset, https://doi.nioz.nl/dataset/sibes-dataset
- DOI: https://doi.org/10.25850/nioz/7b.b.ug
- Three independent source files: \`samples.csv\`, \`biota.csv\`, \`species.csv\`.
- Confirm **dataset version, exact license, release dates, embargo and downloaded
  files** at the moment of retrieval. Do not infer "latest" from the README.
- Record source retrieval time and cryptographic hashes using
  \`R/evidence_register.R\`. Hashes do not validate sampling protocols.
- The underlying SIBES research dataset has licensing distinct from this
  repository's GPL-3.0 code. Verify reuse requirements independently.

## Outputs and limitations

\`R/indicators.R\` computes **preliminary station-level** abundance per m2,
ash-free dry mass per m2 (AFDM), and observed SIBES-taxon richness; then
summarises means by sample year and tidal basin. These are **descriptive
statistics, not an Ecological EarthScore**.

Important safeguards:
1. Do not equate a missing biota record to a confirmed zero by default.
   \`empty_as_zero=TRUE\` is an explicit opt-in that must be justified by
   sampling completeness and the NIOZ data dictionary.
2. A missing measurement remains NA; a duplicated or unmatched sample ID raises
   an error. Review multi-sample protocols before deploying the join.
3. Station-level richness is not whole-basin richness and does not control for
   sampling effort or taxonomic detectability.
4. Simple basin-year means are unweighted and may be biased by spatial coverage
   and survey timing. They are not an area-weighted ecological trend.
5. Validate taxonomic IDs, methods, station coordinates, CRS, seasonal dates,
   measurement units, dataset changes and replicate sampling before publication.
6. SIBES alone does not establish restoration impact, counterfactual, bird food
   supply, causal attribution or financeable outcomes.
7. The future Sovon / WATLAS / GBIF / Copernicus / AlphaEarth interfaces remain
   proposals, **not implemented connectors**.

## Running

From the repository root, after installing R and the original SIBES package:

\`\`\`r
devtools::install_github("Epemaster/SIBES")
\`\`\`

\`\`\`sh
Rscript demonstrator/tests/test_indicators.R
Rscript demonstrator/run_example.R
\`\`\`

\`run_example.R\` uses the small **bundled example dataset**; it is not
the full production SIBES CSV dataset. Outputs are gitignored.

To process a verified local SIBES download, load it with
\`SIBES::sibes_load(directory_path = "...")\`, validate input schema,
then pass \`$samples\` and \`$biota\` to
\`compute_station_indicators(...,empty_as_zero=FALSE)\`.

For file evidence:

\`\`\`r
source("demonstrator/R/evidence_register.R")
manifest <- build_evidence_manifest(
  paths = c("raw/samples.csv", "raw/biota.csv", "raw/species.csv"),
  dataset_version = "VERIFY_WITH_NIOZ",
  retrieved_utc = "VERIFY_SOURCE_RETRIEVAL_TIMESTAMP"
)
write.csv(manifest,"manifest.csv",row.names=FALSE)
\`\`\`

Install the \`digest\` package to calculate SHA-256.

## Proposed next crosswalk

- NIOZ SIBES: benthic density/biomass and sediment
- NIOZ WATLAS: movements and habitat use (access and permission pending)
- Sovon: appropriately licensed bird counts and trends
- Copernicus: georeferenced physical context
- GBIF / Naturalis / eDNA: taxonomy and independent measurements
- Ecological EarthScore / Akashic Record: evidence-qualified scoring interface
- NFB / gebiedsboekhouding: distinct attribution and finance evaluation layers

Maintain source IDs, spatial support, temporal support, methodology and uncertainty.
Do not double count observations syndicated through multiple providers.
