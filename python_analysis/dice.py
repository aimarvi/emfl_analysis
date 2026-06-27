import numpy as np
import pandas as pd

import gen_utils as utils


def compute_dice_by_percent(sigs_1, sigs_2, subject, roi, label, percentages, dataframe_input):
    """
    Compute dice coefficients for matched top-percent voxel sets.

    Args:
        sigs_1 (np.ndarray):
            First significance vector.
        sigs_2 (np.ndarray):
            Second significance vector.
        subject (str):
            Subject identifier.
        roi (str):
            Region-of-interest name.
        label (str):
            Comparison label.
        percentages (np.ndarray):
            Percentages to evaluate.
        dataframe_input (pd.DataFrame):
            Results dataframe to append to.

    Returns:
        pd.DataFrame:
            dataframe_output (pd.DataFrame):
                Updated results dataframe.
    """

    sorted_indices_1 = np.argsort(sigs_1)[::-1]
    sorted_indices_2 = np.argsort(sigs_2)[::-1]
    assert len(sorted_indices_1) == len(sorted_indices_2)

    num_voxels = len(sorted_indices_1)
    for percentage in percentages:
        num_selected = int(num_voxels * percentage)
        voxel_set_1 = set(sorted_indices_1[:num_selected])
        voxel_set_2 = set(sorted_indices_2[:num_selected])
        intersection_size = len(voxel_set_1 & voxel_set_2)
        dice_value = (2 * intersection_size) / (len(voxel_set_1) + len(voxel_set_2))

        dataframe_input.loc[len(dataframe_input)] = {
            "Subject": subject,
            "ROI": roi,
            "Experiment": label,
            "Percent": percentage,
            "Dice": dice_value,
        }

    return dataframe_input


def compute_dice_by_threshold(sigs_1, sigs_2, subject, roi, label, threshold, dataframe_input):
    """
    Compute a dice coefficient for thresholded voxel sets.

    Args:
        sigs_1 (np.ndarray):
            First significance vector.
        sigs_2 (np.ndarray):
            Second significance vector.
        subject (str):
            Subject identifier.
        roi (str):
            Region-of-interest name.
        label (str):
            Comparison label.
        threshold (float):
            Threshold applied to both vectors.
        dataframe_input (pd.DataFrame):
            Results dataframe to append to.

    Returns:
        pd.DataFrame:
            dataframe_output (pd.DataFrame):
                Updated results dataframe.
    """

    voxel_set_1 = set(np.where(sigs_1 > threshold)[0])
    voxel_set_2 = set(np.where(sigs_2 > threshold)[0])

    if len(voxel_set_1) + len(voxel_set_2) == 0:
        dice_value = np.nan
    else:
        intersection_size = len(voxel_set_1 & voxel_set_2)
        dice_value = (2 * intersection_size) / (len(voxel_set_1) + len(voxel_set_2))

    dataframe_input.loc[len(dataframe_input)] = {
        "Subject": subject,
        "ROI": roi,
        "Experiment": label,
        "Threshold": 10 ** (-1 * threshold),
        "Dice": dice_value,
    }
    return dataframe_input


def main():
    """
    Compute within-localizer and between-localizer dice coefficients.

    Returns:
        pd.DataFrame:
            results_df (pd.DataFrame):
                Dice summary dataframe.
    """

    subjects = [f"kaneff{subject_id:02d}" for subject_id in [1, 13, 14, 17, 18]]
    localizer_names = ["vis", "bot_in_effloc5_space"]
    use_corrected_between = False
    method_name = "percent"

    contrast_names = ["B-O"]
    roi_names = ["EBA"]
    hemisphere_names = ["rh"]
    parcellation_names = ["julian"] * len(contrast_names)

    if method_name == "percent":
        columns = ["Subject", "ROI", "Experiment", "Percent", "Dice"]
        percentages = np.arange(0.1, 1.1, 0.1)
    elif method_name == "threshold":
        columns = ["Subject", "ROI", "Experiment", "Threshold", "Dice"]
        threshold = 2
    else:
        raise ValueError(f"{method_name} not implemented")

    dataframe_results = pd.DataFrame(columns=columns)

    for roi_index, roi_name in enumerate(roi_names):
        contrast_name = contrast_names[roi_index]
        parcellation_name = parcellation_names[roi_index]

        for hemisphere_name in hemisphere_names:
            for subject_name in subjects:
                parcel_mask = utils.load_parcel(
                    subj=subject_name,
                    parcellation=parcellation_name,
                    roi=roi_name,
                    hemi=hemisphere_name,
                )
                parcel_index = np.where(parcel_mask != 0)

                for exp_name, label_name in zip(localizer_names, ["loc_1", "loc_2"]):
                    sig_values_even = utils.load_sigs(subject_name, exp_name, contrast_name, "even")[
                        parcel_index
                    ].squeeze()
                    sig_values_odd = utils.load_sigs(subject_name, exp_name, contrast_name, "odd")[
                        parcel_index
                    ].squeeze()

                    if method_name == "percent":
                        dataframe_results = compute_dice_by_percent(
                            sig_values_even,
                            sig_values_odd,
                            subject_name,
                            roi_name,
                            label_name,
                            percentages,
                            dataframe_results,
                        )
                    else:
                        dataframe_results = compute_dice_by_threshold(
                            sig_values_even,
                            sig_values_odd,
                            subject_name,
                            roi_name,
                            label_name,
                            threshold,
                            dataframe_results,
                        )

                if use_corrected_between:
                    for run_label_1 in ["even", "odd"]:
                        for run_label_2 in ["even", "odd"]:
                            sig_values_loc_1 = utils.load_sigs(
                                subject_name, localizer_names[0], contrast_name, run_label_1
                            )[parcel_index].squeeze()
                            sig_values_loc_2 = utils.load_sigs(
                                subject_name, localizer_names[1], contrast_name, run_label_2
                            )[parcel_index].squeeze()

                            if method_name == "percent":
                                dataframe_results = compute_dice_by_percent(
                                    sig_values_loc_1,
                                    sig_values_loc_2,
                                    subject_name,
                                    roi_name,
                                    "between",
                                    percentages,
                                    dataframe_results,
                                )
                            else:
                                dataframe_results = compute_dice_by_threshold(
                                    sig_values_loc_1,
                                    sig_values_loc_2,
                                    subject_name,
                                    roi_name,
                                    "between",
                                    threshold,
                                    dataframe_results,
                                )
                else:
                    sig_values_loc_1 = utils.load_sigs(
                        subject_name, localizer_names[0], contrast_name, "all"
                    )[parcel_index].squeeze()
                    sig_values_loc_2 = utils.load_sigs(
                        subject_name, localizer_names[1], contrast_name, "all"
                    )[parcel_index].squeeze()

                    if method_name == "percent":
                        dataframe_results = compute_dice_by_percent(
                            sig_values_loc_1,
                            sig_values_loc_2,
                            subject_name,
                            roi_name,
                            "between",
                            percentages,
                            dataframe_results,
                        )
                    else:
                        dataframe_results = compute_dice_by_threshold(
                            sig_values_loc_1,
                            sig_values_loc_2,
                            subject_name,
                            roi_name,
                            "between",
                            threshold,
                            dataframe_results,
                        )

    if method_name == "percent":
        dataframe_grouped = dataframe_results.groupby(["ROI", "Experiment", "Percent"])["Dice"].agg(
            ["mean", "std"]
        )
    else:
        dataframe_grouped = dataframe_results.groupby(["ROI", "Experiment", "Threshold"])["Dice"].agg(
            ["mean", "std"]
        )

    print(dataframe_grouped)
    print("success!", localizer_names[0], localizer_names[1])
    return dataframe_results


if __name__ == "__main__":
    dataframe_results = main()
