import os
import numpy as np
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import nibabel as nib

from scipy import stats
from scipy.stats import norm
from tqdm import tqdm

import corr_utils as cuts

'''
calculates correlation (pearson's r) of voxel activity between two localizers
@aimarvi
'''
