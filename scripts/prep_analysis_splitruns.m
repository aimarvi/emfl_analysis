% fMRI block-design analysis for effloc project
% by Sam Hutchinson (7/14/2023)
% last edit: @amarvi 03/18/2025
% 
% performs the ANOVA analysis (Figure 5C)
% runs separate GLMs using different combinations of runs
% 
% set:
%     subj_ids (str): subject names
%     run_ids_sets (int): EMFL runs as listed in the scanning protocol
 
clear;

%% Set experiment/analysis arguments
subj_ids = {'kaneff01', 'kaneff24'};
run_ids_sets = {[8:12], [8:12]};

% dir name housing all .dcm files
dicom_name = 'dicom';

% localizer name ['vis', 'aud', 'audHalf']
exp_name = 'audHalf';

% including fixation (for EMFL visual: 5+1=6)
num_conditions = 6;

% in seconds
block_length = 22;

c = 0;
c = c+1; contrast.names{c} = ['All-Fix']; contrast.cidleft{c} = [1:5]; contrast.cidright{c} = [0];
%% define contrasts based on para file condition numbers
if strcmp(exp_name, 'vis')
    c = c+1; contrast.names{c} = ['Fa-O']; contrast.cidleft{c} = [1]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['B-O']; contrast.cidleft{c} = [3]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['S-O']; contrast.cidleft{c} = [2]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['W-O']; contrast.cidleft{c} = [5]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['O-Scr']; contrast.cidleft{c} = [4]; contrast.cidright{c} = [5];
elseif strcmp(exp_name, 'aud')
    c = c+1; contrast.names{c} = ['ENG-NW']; contrast.cidleft{c} = [1:2]; contrast.cidright{c} = [3];
    c = c+1; contrast.names{c} = ['NW-QLT']; contrast.cidleft{c} = [3]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['MATH-ENG']; contrast.cidleft{c} = [5]; contrast.cidright{c} = [1:2];
    c = c+1; contrast.names{c} = ['MATH-NW']; contrast.cidleft{c} = [5]; contrast.cidright{c} = [3];
    c = c+1; contrast.names{c} = ['MATH-ALL']; contrast.cidleft{c} = [5]; contrast.cidright{c} = [1:4];
    c = c+1; contrast.names{c} = ['FB-FP']; contrast.cidleft{c} = [1]; contrast.cidright{c} = [2];
elseif strcmp(exp_name, 'audHalf')
    c = c+1; contrast.names{c} = ['FB-FP']; contrast.cidleft{c} = [1]; contrast.cidright{c} = [2];
elseif strcmp(exp_name, 'foss')
    c = c+1; contrast.names{c} = ['Fa-O']; contrast.cidleft{c} = [1]; contrast.cidright{c} = [2];
    c = c+1; contrast.names{c} = ['S-O']; contrast.cidleft{c} = [4]; contrast.cidright{c} = [2];
    c = c+1; contrast.names{c} = ['O-Scr']; contrast.cidleft{c} = [2]; contrast.cidright{c} = [3];
elseif strcmp(exp_name, 'ebavwfa')
    c = c+1; contrast.names{c} = ['B-O']; contrast.cidleft{c} = [1]; contrast.cidright{c} = [3];
    c = c+1; contrast.names{c} = ['LineB-LineO']; contrast.cidleft{c} = [2]; contrast.cidright{c} = [4];
    c = c+1; contrast.names{c} = ['W-O']; contrast.cidleft{c} = [5]; contrast.cidright{c} = [3];
    c = c+1; contrast.names{c} = ['W-LineO']; contrast.cidleft{c} = [5]; contrast.cidright{c} = [4];
end

%set smoothing amount as string
smoothing = '3';

%how long is TR in seconds?
TR = 2;

%give para naming convention (split by run index usually)
para_stem = 'kaneff01_'; % change this if para files differ by subject
para_ext = ['_' exp_name '.para'];

%% Decide what to do
do_volume = 1;
do_surface = 0;
make_analysis = 1;
do_selxavg = 1;
do_glmSingle = 0;

%% Run the commands!
for sid = 1:length(subj_ids)
    subj_id = subj_ids{sid};
    run_ids = run_ids_sets{sid};

    for rid = 1:length(run_ids)

        %hold out one run
        held_run = run_ids(rid);
        make_L2_splitruns(subj_id, [held_run], dicom_name, exp_name, num_conditions, block_length, contrast, ...
            TR);
        block_analysis_splitruns(subj_id, exp_name, make_analysis, do_selxavg, ...
            do_glmSingle, do_volume, do_surface, smoothing);


        %now do the rest of the runs
        keep_runs = run_ids;
        keep_runs(rid) = [];
        make_L2_splitruns(subj_id, keep_runs, dicom_name, exp_name, num_conditions, block_length, contrast, ...
            TR);
        block_analysis_splitruns(subj_id, exp_name, make_analysis, do_selxavg, ...
            do_glmSingle, do_volume, do_surface, smoothing);


    end
end
