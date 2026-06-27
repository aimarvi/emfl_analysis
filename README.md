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

## Parcel Template Spaces

Parcels come from different template spaces before they are moved into each subject's native functional volume:

- `julian`: CVS average space
- `vwfa`: MNI152 space
- `md`: MNI152 space
- `language`: MNI152 space
- `speech`: MNI152 space
- `tom`: MNI152 space

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
  - `matlab_analysis/plot_surface_maps.m`
  - `matlab_analysis/get_surface_maps.m`
- Behavioral summary:
  - `matlab_analysis/plot_behavioral_data.m`
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

## Notes

This repository assumes:

- FreeSurfer and FS-FAST are installed
- subject reconstructions exist under `recons/`
- paradigm files exist under the appropriate `paras_*` directory
- first-level outputs are written under the relevant `vols_*` directory

## Publication Materials

`PUBLICATION/` contains the paper text and extracted publication assets used to map analyses in this repository back to the final paper.

## Citation

If you found this repository or data useful, please cite:

```
@article{marvi_efficient_2025,
	title = {An efficient multifunction {fMRI} localizer for high-level visual, auditory, and cognitive regions in humans},
	volume = {3},
	issn = {2837-6056},
	url = {https://direct.mit.edu/imag/article/doi/10.1162/IMAG.a.905/133159/An-efficient-multifunction-fMRI-localizer-for-high},
	doi = {10.1162/IMAG.a.905},
	language = {en},
	urldate = {2026-06-27},
	journal = {Imaging Neuroscience},
	author = {Marvi, Ammar I. and Hutchinson, Sam and Fedorenko, Evelina and Saxe, Rebecca R. and Kamps, Frederik S. and Regev, Tamar I. and Chen, Emily M. and Kanwisher, Nancy G.},
	month = oct,
	year = {2025},
}
```
