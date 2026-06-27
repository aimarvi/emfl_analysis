% split-run analysis used for the figure 5c anova workflow.
% rerun the glm with one run held out at a time.
 
clear;

%% set experiment and analysis arguments
subj_ids = {'kaneff01', 'kaneff24'};
run_ids_sets = {[8:12], [8:12]};

% directory housing the raw dicoms
dicom_name = 'dicom';

% localizer name
exp_name = 'audHalf';

% number of conditions including fixation
num_conditions = 6;

% block duration in seconds
block_length = 22;

c = 0;
c = c+1; contrast.names{c} = ['All-Fix']; contrast.cidleft{c} = [1:5]; contrast.cidright{c} = [0];
%% define contrasts
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

% smoothing kernel in mm
smoothing = '3';

% tr in seconds
TR = 2;

%% analysis switches
do_volume = 1;
do_surface = 0;
make_analysis = 1;
do_selxavg = 1;
do_glmSingle = 0;

%% run the pipeline
for sid = 1:length(subj_ids)
    subj_id = subj_ids{sid};
    run_ids = run_ids_sets{sid};

    for rid = 1:length(run_ids)

        % hold out one run.
        held_run = run_ids(rid);
        make_L2_splitruns(subj_id, [held_run], dicom_name, exp_name, num_conditions, block_length, contrast, ...
            TR);
        block_analysis_splitruns(subj_id, exp_name, make_analysis, do_selxavg, ...
            do_glmSingle, do_volume, do_surface, smoothing);


        % run the complement set.
        keep_runs = run_ids;
        keep_runs(rid) = [];
        make_L2_splitruns(subj_id, keep_runs, dicom_name, exp_name, num_conditions, block_length, contrast, ...
            TR);
        block_analysis_splitruns(subj_id, exp_name, make_analysis, do_selxavg, ...
            do_glmSingle, do_volume, do_surface, smoothing);


    end
end
