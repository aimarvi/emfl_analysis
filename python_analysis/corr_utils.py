import numpy as np
from scipy import stats

from gen_utils import load_betas, load_parcel, load_sigs


def get_correlations(
    subj,
    roi,
    hemi,
    parcellation,
    loc_1,
    contrast_1,
    within=True,
    loc_2=None,
    contrast_2=None,
    full=False,
):
    """
    Compute within-localizer or across-localizer voxelwise correlations.

    Args:
        subj (str):
            Subject identifier.
        roi (str):
            Region-of-interest name.
        hemi (str):
            Hemisphere label.
        parcellation (str):
            Parcel family name.
        loc_1 (str):
            First localizer name.
        contrast_1 (str):
            Contrast used for the first localizer.
        within (bool):
            If ``True``, compute split-half reliability within ``loc_1``.
        loc_2 (str | None):
            Second localizer name for across-localizer comparisons.
        contrast_2 (str | None):
            Contrast used for the second localizer.
        full (bool):
            If ``True``, use all even/odd pairings across localizers.

    Returns:
        dict:
            correlation_results (dict):
                Correlation summary for the requested comparison.
    """

    parcel_mask = load_parcel(subj=subj, parcellation=parcellation, roi=roi, hemi=hemi)
    parcel_index = parcel_mask != 0

    if within:
        sig_values_even = np.squeeze(load_sigs(subj, loc_1, contrast_1, "even")[parcel_index])
        sig_values_odd = np.squeeze(load_sigs(subj, loc_1, contrast_1, "odd")[parcel_index])
        correlation_result = stats.pearsonr(sig_values_even, sig_values_odd)
        r_value = correlation_result.statistic
        return {
            "r": r_value,
            "p": correlation_result.pvalue,
            "r_trans": np.arctanh(r_value),
            "even": sig_values_even,
            "odd": sig_values_odd,
        }

    if not full:
        sig_values_loc_1 = np.squeeze(load_sigs(subj, loc_1, contrast_1, "all")[parcel_index])
        sig_values_loc_2 = np.squeeze(load_sigs(subj, loc_2, contrast_2, "all")[parcel_index])
        correlation_result = stats.pearsonr(sig_values_loc_1, sig_values_loc_2)
        r_value = correlation_result.statistic
        return {
            "r": r_value,
            "p": correlation_result.pvalue,
            "r_trans": np.arctanh(r_value),
            "loc_1": sig_values_loc_1,
            "loc_2": sig_values_loc_2,
        }

    sig_values_loc_1_even = np.squeeze(load_sigs(subj, loc_1, contrast_1, "even")[parcel_index])
    sig_values_loc_1_odd = np.squeeze(load_sigs(subj, loc_1, contrast_1, "odd")[parcel_index])
    sig_values_loc_2_even = np.squeeze(load_sigs(subj, loc_2, contrast_2, "even")[parcel_index])
    sig_values_loc_2_odd = np.squeeze(load_sigs(subj, loc_2, contrast_2, "odd")[parcel_index])

    r_loc_1_within = stats.pearsonr(sig_values_loc_1_even, sig_values_loc_1_odd).statistic
    r_loc_2_within = stats.pearsonr(sig_values_loc_2_even, sig_values_loc_2_odd).statistic

    r_across_even_even = stats.pearsonr(sig_values_loc_1_even, sig_values_loc_2_even).statistic
    r_across_even_odd = stats.pearsonr(sig_values_loc_1_even, sig_values_loc_2_odd).statistic
    r_across_odd_odd = stats.pearsonr(sig_values_loc_1_odd, sig_values_loc_2_odd).statistic
    r_across_odd_even = stats.pearsonr(sig_values_loc_1_odd, sig_values_loc_2_even).statistic

    r_across_mean = np.mean(
        [r_across_even_even, r_across_even_odd, r_across_odd_odd, r_across_odd_even]
    )
    return {
        "loc_1": r_loc_1_within,
        "loc_2": r_loc_2_within,
        "across": r_across_mean,
        "r_trans": np.arctanh(r_across_mean),
    }


def sort_voxels_for_growing_window(subj, roi, hemi, parcellation, localizer, contrast, conds):
    """
    Sort voxels by held-out localizer significance for a growing-window analysis.

    Args:
        subj (str):
            Subject identifier.
        roi (str):
            Region-of-interest name.
        hemi (str):
            Hemisphere label.
        parcellation (str):
            Parcel family name.
        localizer (str):
            Localizer name.
        contrast (str):
            Contrast used to rank voxels.
        conds (list[str]):
            Localizer conditions in paradigm order.

    Returns:
        dict:
            growing_window_results (dict):
                Sorted significance values and running beta means by condition.
    """

    parcel_mask = load_parcel(subj=subj, parcellation=parcellation, roi=roi, hemi=hemi)
    parcel_index = parcel_mask != 0

    sig_values_even = load_sigs(subj, localizer, contrast, "even")
    beta_values_odd = load_betas(subj, localizer, "odd")
    sig_values_even_parcel = np.squeeze(sig_values_even[parcel_index])

    sorted_indices = np.argsort(sig_values_even_parcel)[::-1]
    betas_by_condition = {}

    for condition_index, condition_name in enumerate(conds):
        beta_values_condition = np.squeeze(beta_values_odd[:, :, :, condition_index])
        beta_values_parcel = np.squeeze(beta_values_condition[parcel_index])
        beta_values_sorted = beta_values_parcel[sorted_indices]

        voxel_windows = np.arange(1, len(sorted_indices), 1)
        running_means = []
        for window_size in voxel_windows:
            running_means.append(np.mean(beta_values_sorted[:window_size]))
        betas_by_condition[condition_name] = running_means

    sig_values_sorted = sig_values_even_parcel[sorted_indices]
    return {"sigs": sig_values_sorted, "betas": betas_by_condition}


def sort_voxels_gw_across_localizers(
    subj,
    roi,
    hemi,
    parcellation,
    loc_1,
    contrast_1,
    loc_2,
    conds_2,
):
    """
    Sort voxels by one localizer and measure running means in another.

    Args:
        subj (str):
            Subject identifier.
        roi (str):
            Region-of-interest name.
        hemi (str):
            Hemisphere label.
        parcellation (str):
            Parcel family name.
        loc_1 (str):
            Localizer used to rank voxels.
        contrast_1 (str):
            Contrast used to rank voxels.
        loc_2 (str):
            Localizer used to measure beta responses.
        conds_2 (list[str]):
            Condition names for ``loc_2``.

    Returns:
        dict:
            growing_window_results (dict):
                Sorted significance values and running beta means by condition.
    """

    parcel_mask = load_parcel(subj=subj, parcellation=parcellation, roi=roi, hemi=hemi)
    parcel_index = parcel_mask != 0

    sig_values = load_sigs(subj, loc_1, contrast_1, "all")
    beta_values = load_betas(subj, loc_2, "all")
    sig_values_parcel = np.squeeze(sig_values[parcel_index])

    sorted_indices = np.argsort(sig_values_parcel)[::-1]
    betas_by_condition = {}

    for condition_index, condition_name in enumerate(conds_2):
        beta_values_condition = np.squeeze(beta_values[:, :, :, condition_index])
        beta_values_parcel = np.squeeze(beta_values_condition[parcel_index])
        beta_values_sorted = beta_values_parcel[sorted_indices]

        voxel_windows = np.arange(1, len(sorted_indices), 1)
        running_means = []
        for window_size in voxel_windows:
            running_means.append(np.mean(beta_values_sorted[:window_size]))
        betas_by_condition[condition_name] = running_means

    sig_values_sorted = sig_values_parcel[sorted_indices]
    return {"sigs": sig_values_sorted, "betas": betas_by_condition}
