# Efficient Multifunction fMRI Localizer (EMFL) Analysis

Analysis code for:

*Marvi, Hutchinson, Fedorenko, Saxe, Kamps, Regev, Chen, and Kanwisher (2025), "An efficient multifunction fMRI localizer for high-level visual, auditory, and cognitive regions in humans."*

This repository contains the analysis pipeline for EMFL: first-level FS-FAST analyses, parcel transforms into subject native space, surface visualization utilities, and Python analyses used to evaluate fROI localization and compare EMFL with standard localizers.

## Repository at a Glance

```text
scripts/            MATLAB entry points for analysis and parcel workflows
matlab_analysis/    MATLAB visualization and behavioral summaries
python_analysis/    Python analyses for selectivity, overlap, correlations, and ANOVAs

PARCELS/            template parcels used to define anatomical constraints
PUBLICATION/        paper text and publication assets
analysis/           subject-level analysis metadata and outputs
recons/             subject reconstructions
vols_vis/           visual localizer outputs
vols_aud/           auditory localizer outputs
vols_audHalf/       half-block auditory outputs used for ToM checks
paras_vis/          visual paradigm files
paras_aud/          auditory paradigm files
paras_audHalf/      half-block auditory paradigm files
```

## Core Workflow

The main analysis path is:

1. Define subject-, run-, and contrast-level settings in `scripts/prep_analysis_final.m`.
2. Build the per-subject `L2` analysis structure in `scripts/make_L2_final.m`.
3. Run unpacking, preprocessing, run splits, contrast setup, and FS-FAST first-level analyses in `scripts/block_analysis_final.m`.
4. Transform anatomical parcels into native volume and surface space with:
   - `scripts/parcel_transform_final.m`
   - `scripts/volume_parcels.m`
   - `scripts/surface_parcels.m`
5. Run paper analyses from `python_analysis/`.

## Paper Map

The main code-to-paper mapping is:

- Preprocessing and first-level GLMs:
  - `scripts/prep_analysis_final.m`
  - `scripts/make_L2_final.m`
  - `scripts/block_analysis_final.m`
- Parcel definition in subject native space:
  - `scripts/parcel_transform_final.m`
  - `scripts/volume_parcels.m`
  - `scripts/surface_parcels.m`
- Surface activation figures:
  - `matlab_analysis/surface.m`
  - `matlab_analysis/plot.m`
- Behavioral summary:
  - `matlab_analysis/behavioral.m`
- EMFL fROI response profiles:
  - `python_analysis/effect_size.py`
- Cross-localizer ANOVA dataset and models:
  - `python_analysis/collect_anova.py`
  - `python_analysis/perform_anova.py`
- Dice overlap analyses:
  - `python_analysis/dice.py`
- Voxelwise correlation and growing-window helpers:
  - `python_analysis/corr_utils.py`
  - `python_analysis/correlation.py`

## Intended Code Organization

The repository should be organized around three clear layers.

### `scripts/`

`scripts/` is the execution layer. It should stay self-contained and remain the main place a user starts when running the pipeline.

Recommended structure:

```text
scripts/
  startup.m

  first_level/
    prep_analysis_final.m
    make_L2_final.m
    block_analysis_final.m

  parceling/
    parcel_transform_final.m
    volume_parcels.m
    surface_parcels.m

  revisions/
    prep_analysis_revision.m
    block_analysis_revision.m
    prep_analysis_splitruns.m

  utilities/
    dist_paras.sh
```

### `matlab_analysis/`

Recommended structure:

```text
matlab_analysis/
  surface_viz/
    surface.m
    plot.m
    read_freesurfer_brain.m
    plot_mesh_brain.m
    paint_mesh.m

  behavioral/
    behavioral.m
```

### `python_analysis/`

Recommended structure:

```text
python_analysis/
  emfl_analysis/
    io/
      gen_utils.py

    metrics/
      corr_utils.py

    paper/
      effect_size.py
      collect_anova.py
      perform_anova.py
      dice.py
      correlation.py
      count_sig_voxels.py
      unimodal.py
      growing_window.py
```

## Current Assumptions

This repository assumes:

- FreeSurfer and FS-FAST are installed
- subject reconstructions exist under `recons/`
- paradigm files exist under the appropriate `paras_*` directory
- first-level outputs are written under the relevant `vols_*` directory

## Publication Materials

`PUBLICATION/` contains the paper text and extracted publication assets used to map analyses in this repository back to the final paper.
