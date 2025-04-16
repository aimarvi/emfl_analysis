import numpy as np
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt

import scipy.stats as stats
import statsmodels.api as sm
from statsmodels.formula.api import ols
import statsmodels.formula.api as smf

'''
performs OMNIBUS and within-ROI ANOVA
requires that you already have consolidated data into a dataframe
see collect_anova.py
'''

# see collect_anova.py to get this data
df = pd.read_pickle('./final_data/anova_data.pkl')

# List of parcel-contrast mappings
parcel_list = [
    ('FFA', ['Fa', 'O']),
    ('OFA', ['Fa', 'O']),
    ('STS', ['Fa', 'O']),
    ('PPA', ['S', 'O']),
    ('OPA', ['S', 'O']),
    ('RSC', ['S', 'O']),
    ('EBA', ['B', 'O']),
    ('LOC', ['O', 'Scr_W']),
    ('vwfa', ['W', 'O']),
    ('RTPJ', ['FB', 'FP', 'EP', 'PP']),
    ('language', ['S_FB_FP', 'NW']),
    ('speech', ['NW', 'QLT']),
    ('frontal', ['H', 'E', 'MATH', 'FB', 'FP']),
    ('parietal', ['H', 'E', 'MATH', 'FB', 'FP']),
]

#####################################################
### simplify contrasts to preferred and non-preferred
#####################################################
all_rows = []
for k, v in parcel_list:
    v2 = '_'.join(v)
    sub_df = df[(df['parcel'] == k) & (df['contrast'].isin(v2.split('_')))].copy()
    print(len(sub_df), k, v2)
    
    # Map 'contrast' values to "preferred" or "unpreferred"
    if len(v)>2:
        sub_df['contrast'] = sub_df['contrast'].map(lambda x: "preferred" if x in [v[0], v[2]] else "unpreferred")   
    else:
        sub_df['contrast'] = sub_df['contrast'].map(lambda x: "preferred" if x in v[0] else "unpreferred")
        
    all_rows.append(sub_df)
new_df = pd.concat(all_rows, ignore_index=True)

# aggregate over hemispheres (if available)
subj_df = new_df.groupby(['definer', 'measurer', 'contrast', 'parcel', 'subject'])['betas'].agg(['mean']).reset_index()

# 2x2x2x14 ANOVA
# does not average over subjects beforehand
# this would be the huge OMNIBUS anova
model = ols('mean ~ C(contrast)*C(definer)*C(measurer)*C(parcel)', data=subj_df).fit()
aov_table = sm.stats.anova_lm(model, typ=1)
display(aov_table)

# now do the anova within each ROI
# 2x2x2, data is not averaged over subjects
# type 1v2v3 should NOT matter because each group is the same size(?)
for parcel, _ in parcel_list:
    sub_df = new_df[new_df['parcel']==parcel].groupby(['definer', 'measurer', 'contrast','subject'])['betas'].agg(['mean']).reset_index()
    
    model = ols('mean ~ C(contrast)*C(definer)*C(measurer)', data=sub_df).fit()
    aov_table = sm.stats.anova_lm(model, typ=1)
    print('\n\n\n', parcel)
    display(aov_table)
