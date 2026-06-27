import pandas as pd

import corr_utils as corr


def main():
    """
    Collect across-localizer voxelwise correlation summaries.

    Returns:
        pd.DataFrame:
            results_df (pd.DataFrame):
                One row per subject, roi, and hemisphere.
    """

    subjects_main = ["kaneff01"] + [f"kaneff{subject_id:02d}" for subject_id in range(6, 25)]
    subjects_ebavwfa = [f"kaneff{subject_id:02d}" for subject_id in range(9, 25)]

    hemispheres = ["lh", "rh"]
    rois = ["FFA", "OFA", "STS", "PPA", "OPA", "RSC", "LOC", "EBA", "vwfa"]
    contrast_names_loc_1 = ["Fa-O", "Fa-O", "Fa-O", "S-O", "S-O", "S-O", "O-Scr", "B-O", "W-O"]
    contrast_names_loc_2 = ["Fa-O", "Fa-O", "Fa-O", "S-O", "S-O", "S-O", "O-Scr", "B-O", "Fa-O"]

    rows = []

    for roi_index, roi_name in enumerate(rois):
        for hemisphere_name in hemispheres:
            contrast_name_loc_1 = contrast_names_loc_1[roi_index]
            contrast_name_loc_2 = contrast_names_loc_2[roi_index]
            parcellation_name = "julian"
            localizer_name_loc_2 = "foss"
            subjects_current = subjects_main
            hemisphere_current = hemisphere_name

            if roi_name == "EBA":
                localizer_name_loc_2 = "ebavwfa"
                subjects_current = subjects_ebavwfa
            elif roi_name == "vwfa":
                localizer_name_loc_2 = "ebavwfa"
                parcellation_name = "vwfa"
                hemisphere_current = "lh"
                subjects_current = subjects_ebavwfa

            for subject_name in subjects_current:
                result_corrected = corr.get_correlations(
                    subj=subject_name,
                    roi=roi_name,
                    hemi=hemisphere_current,
                    parcellation=parcellation_name,
                    loc_1="vis",
                    contrast_1=contrast_name_loc_1,
                    within=False,
                    loc_2=localizer_name_loc_2,
                    contrast_2=contrast_name_loc_2,
                    full=True,
                )
                result_uncorrected = corr.get_correlations(
                    subj=subject_name,
                    roi=roi_name,
                    hemi=hemisphere_current,
                    parcellation=parcellation_name,
                    loc_1="vis",
                    contrast_1=contrast_name_loc_1,
                    within=False,
                    loc_2=localizer_name_loc_2,
                    contrast_2=contrast_name_loc_2,
                    full=False,
                )
                rows.append(
                    {
                        "subject": subject_name,
                        "contrast": roi_name,
                        "loc_1": result_corrected["loc_1"],
                        "loc_2": result_corrected["loc_2"],
                        "across": result_corrected["across"],
                        "across_uncorrected": result_uncorrected["r"],
                        "r_trans": result_corrected["r_trans"],
                    }
                )

    return pd.DataFrame(rows)


if __name__ == "__main__":
    dataframe_results = main()
