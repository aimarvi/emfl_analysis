import pandas as pd
import statsmodels.api as sm
from statsmodels.formula.api import ols

from emfl_paths import get_python_analysis_paths


PARCEL_CONTRAST_MAP = [
    ("FFA", ["Fa", "O"]),
    ("OFA", ["Fa", "O"]),
    ("STS", ["Fa", "O"]),
    ("PPA", ["S", "O"]),
    ("OPA", ["S", "O"]),
    ("RSC", ["S", "O"]),
    ("EBA", ["B", "O"]),
    ("LOC", ["O", "Scr_W"]),
    ("vwfa", ["W", "O"]),
    ("RTPJ", ["FB", "FP", "EP", "PP"]),
    ("language", ["S_FB_FP", "NW"]),
    ("speech", ["NW", "QLT"]),
    ("frontal", ["H", "E", "MATH", "FB", "FP"]),
    ("parietal", ["H", "E", "MATH", "FB", "FP"]),
]


def simplify_contrast_labels(dataframe_input):
    """
    Collapse condition labels into preferred and unpreferred categories.

    Args:
        dataframe_input (pd.DataFrame):
            Consolidated beta dataframe.

    Returns:
        pd.DataFrame:
            dataframe_output (pd.DataFrame):
                Dataframe with simplified contrast labels.
    """

    rows = []

    for parcel_name, contrast_names in PARCEL_CONTRAST_MAP:
        contrast_string = "_".join(contrast_names)
        dataframe_subset = dataframe_input[
            (dataframe_input["parcel"] == parcel_name)
            & (dataframe_input["contrast"].isin(contrast_string.split("_")))
        ].copy()

        if len(contrast_names) > 2:
            preferred_names = {contrast_names[0], contrast_names[2]}
        else:
            preferred_names = {contrast_names[0]}

        dataframe_subset["contrast"] = dataframe_subset["contrast"].map(
            lambda contrast_name: "preferred" if contrast_name in preferred_names else "unpreferred"
        )
        rows.append(dataframe_subset)

    return pd.concat(rows, ignore_index=True)


def main():
    """
    Run omnibus and within-roi ANOVAs from a saved dataframe.
    """

    paths = get_python_analysis_paths()
    filepath_input = paths["dir_final_data"] / "anova_data.pkl"
    dataframe_input = pd.read_pickle(filepath_input)
    dataframe_simplified = simplify_contrast_labels(dataframe_input=dataframe_input)

    dataframe_subject = (
        dataframe_simplified.groupby(["definer", "measurer", "contrast", "parcel", "subject"])["betas"]
        .agg(["mean"])
        .reset_index()
    )

    model_omnibus = ols("mean ~ C(contrast)*C(definer)*C(measurer)*C(parcel)", data=dataframe_subject).fit()
    table_omnibus = sm.stats.anova_lm(model_omnibus, typ=1)
    print(table_omnibus)

    for parcel_name, _ in PARCEL_CONTRAST_MAP:
        dataframe_subset = (
            dataframe_simplified[dataframe_simplified["parcel"] == parcel_name]
            .groupby(["definer", "measurer", "contrast", "subject"])["betas"]
            .agg(["mean"])
            .reset_index()
        )
        model_roi = ols("mean ~ C(contrast)*C(definer)*C(measurer)", data=dataframe_subset).fit()
        table_roi = sm.stats.anova_lm(model_roi, typ=1)
        print(f"\n{parcel_name}")
        print(table_roi)


if __name__ == "__main__":
    main()
