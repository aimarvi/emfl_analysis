%% fMRI Block Design Analysis
% Efficient Localizer
% @samhutch @amarvi 06/17/2025

%% Set analysis parameters

function prep_analysis_revision(i, exp_name)

subj_ids = [1 6:24] % use in conjunction with: subj_id = sprintf('kaneff%02d', id);
run_sets = {[8,9,10,11,12], [7,8,9,10,11], [8,9,10,11,12], [11,12,13,14,15], [8,9,10,11,12], [7,8,9,10,11], [7,8,9,10,11], [16,17,18,19,20], [7,8,9,10,11], [7,8,9,10,11], [7,8,9,10,11], [7,8,9,10,11], [11,12,13,14,15], [7,8,9,10,11], [11,12,13,14,15], [7,8,9,10,11], [7,8,9,10,11], [7,8,9,10,11], [7,8,9,10,11], [8,9,10,11,12]};

subj_id = sprintf('kaneff%02d', subj_ids(i));
run_ids = run_sets{i};

%give para naming convention (split by run index usually)
para_stem = [subj_id '_'];
para_ext = ['_' exp_name '.para'];

dicom_name = 'dicom';
num_conditions = 6; % including fixation
block_length = 22;
smoothing = '3';

TR = 2.0;

%% Define contrasts (based on para files)
c = 0;
c = c+1; contrast.names{c} = ['All-Fix']; contrast.cidleft{c} = [1:5]; contrast.cidright{c} = [0];

if strcmp(exp_name, 'vis')
    c = c+1; contrast.names{c} = ['Fa-O']; contrast.cidleft{c} = [1]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['S-O']; contrast.cidleft{c} = [2]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['B-O']; contrast.cidleft{c} = [3]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['W-O']; contrast.cidleft{c} = [5]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['O-Scr']; contrast.cidleft{c} = [4]; contrast.cidright{c} = [5];
elseif strcmp(exp_name, 'aud')
    c = c+1; contrast.names{c} = ['ENG-NW']; contrast.cidleft{c} =[1:2]; contrast.cidright{c} = [3];
    c = c+1; contrast.names{c} = ['NW-QLT']; contrast.cidleft{c} = [3]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['MATH-ENG']; contrast.cidleft{c} = [5]; contrast.cidright{c} = [1:2];
    c = c+1; contrast.names{c} = ['MATH-NW']; contrast.cidleft{c} = [5]; contrast.cidright{c} = [3];
    c = c+1; contrast.names{c} = ['MATH-QLT']; contrast.cidleft{c} = [5]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['FB-FP']; contrast.cidleft{c} =[1]; contrast.cidright{c} = [2];
elseif strcmp(exp_name, 'audHalf')
    c = c+1; contrast.names{c} = ['FB-FP']; contrast.cidleft{c} =[1]; contrast.cidright{c} = [2];

    block_length = 11;
end

%% Flags for analysis
do_volume = 1;
do_surface = 1;
unpack = 0;
do_preproc = 0;
make_analysis = 1;
do_selxavg = 1;
do_glmSingle = 0;

%% Run the commands!
clc;
make_L2_final(subj_id, run_ids, dicom_name, exp_name, num_conditions, block_length, contrast, TR);
block_analysis_revision(subj_id, exp_name, unpack, do_preproc, make_analysis, do_selxavg, ...
    do_glmSingle, do_volume, do_surface, smoothing, para_stem, para_ext);

end
