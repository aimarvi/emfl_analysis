%% fMRI Block Design Analysis
% Efficient Multifunction fMRI Localizer
% @samhutch @amarvi 02/27/2025 

%% Set analysis parameters
% 
% args:
%     subj_id (str): subject name 
%     exp_name(str): localizer name (see below for full list)
% 
% returns:
%     none

function prep_analysis_final(subj_id, exp_name)

% EMFL runs as listed in scanning protocol
run_ids = [7,8,9,10,11];

% dir housing all .dcm files
dicom_name = 'dicom';

% including fixation (for EMFL visual: 5+1=6)
num_conditions = 6;

% in seconds
block_length = 22;

% fwhm smoothing (mm)
smoothing = '3';

% temporal resolution (sec)
TR = 2.0;

% paradigm file naming convention
para_stem = [subj_id '_'];
para_ext = ['_' exp_name '.para'];

%% Define contrasts (based on para files)
% EMFL exp names:
%     vis: visual conditions (faces, scenes, bodies, objects, words)
%     aud: auditory conditions (false belief, false photo, nonwords, quilted audio, arithmetic)
%     audHalf: half-block analysis for Theory of Mind regions (false belief, false photo)
% OTHER:
%     foss: Epstein & Kanwisher (1998)
%     langloc: Fedorenko et al (2010)
%     eploc: Jacoby et al (2016) 
%     spwm: Fedorenko et al (2013)
%     speechloc: speech localizer
%     ebavwfa: EBA & VWFA localizer
%     towerloc: Fischer et al (2016)

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
elseif strcmp(exp_name, 'foss')
    c = c+1; contrast.names{c} = ['Fa-O']; contrast.cidleft{c} = [1]; contrast.cidright{c} = [2];
    c = c+1; contrast.names{c} = ['S-O']; contrast.cidleft{c} = [4]; contrast.cidright{c} = [2];
    c = c+1; contrast.names{c} = ['O-Scr']; contrast.cidleft{c} = [2]; contrast.cidright{c} = [3];
    
    block_length = 16;
    num_conditions = 5;
    run_ids = [12,13,14,15];
elseif strcmp(exp_name, 'langloc')
    c = c+1; contrast.names{c} = ['S-NW']; contrast.cidleft{c} = [1]; contrast.cidright{c} = [2];
    
    block_length = 18;
    num_conditions = 3;
    run_ids = [16,17];
elseif strcmp(exp_name, 'speechloc')
    c = c+1; contrast.names{c} = ['NW-QLT']; contrast.cidleft{c} = [1]; contrast.cidright{c} = [2];
    
    block_length = 16;
    num_conditions = 4;
    run_ids = [18,19];
elseif strcmp(exp_name, 'spwm')
    c = c+1; contrast.names{c} = ['H-E']; contrast.cidleft{c} = [2]; contrast.cidright{c} = [1];
    
    block_length = 32;
    num_conditions = 3;
    run_ids = [21,22];
elseif strcmp(exp_name, 'eploc')
    c = c+1; contrast.names{c} = ['EP-PP']; contrast.cidleft{c} = [1]; contrast.cidright{c} = [2];
    
    block_length = 16;
    num_conditions = 3;
    run_ids = [20,21];
elseif strcmp(exp_name, 'towerloc')
    c = c+1; contrast.names{c} = ['P-C']; contrast.cidleft{c} = [1]; contrast.cidright{c} = [2];
    
    block_length = 18;
    num_conditions = 3;
    run_ids = [1]; % !!
end
 
%% Flags for analysis
do_volume = 1;
do_surface = 1;
unpack = 1;
do_preproc = 1;
make_analysis = 1;
do_selxavg = 1;
do_glmSingle = 0;

%% Run the commands!
clc;
make_L2_final(subj_id, run_ids, dicom_name, exp_name, num_conditions, block_length, contrast, TR);
block_analysis_final(subj_id, exp_name, unpack, do_preproc, make_analysis, do_selxavg, ...
    do_glmSingle, do_volume, do_surface, smoothing, para_stem, para_ext);

end
