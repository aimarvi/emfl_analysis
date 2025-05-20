% requires first running volume_parcels.m
% surface parcels are a transformed version of the native volume parcels
%
% move all parcels to the surface
% julian, vwfa, language, ToM, MD parcels
% Last Edit: amarvi 04/17/2025
% 
% args: 
%     subjname (str): subject name
% 
% returns:
%     none


%%% this is all you need to change (hopefully) %%%
function surface_parcels(subjname)

SUBJECTS_DIR = '/mindhive/nklab5/projects/efficient_localizer/recons/';
setenv('SUBJECTS_DIR',SUBJECTS_DIR);

% source parcel directory
srcParcelDir = '../parcels/';

hemis = {'lh', 'rh'};

dJP = dir([srcParcelDir 'all/*.nii.gz']);
dLang = dir([srcParcelDir 'EvLab_lang_parcels/langparcel*.nii']);
dSpeech = dir([srcParcelDir 'speech_parcels/*.nii']);
dSpeech = dir();
dToM = dir([srcParcelDir 'ToM_parcels/*.nii.gz']);
dVWFA = dir([srcParcelDir 'lvwfa.nii.gz']);
dMD = dir([srcParcelDir 'md/*.nii.gz']);

fprintf('subject: %s\n', subjname);

logDir = [SUBJECTS_DIR '../data_analysis/masks/vols/' subjname '/log/']; mkdir(logDir);
diaryname = ['parcelize_' subjname '.txt'];
diary([logDir diaryname]);

%% julian parcels
outdir = [SUBJECTS_DIR '../data_analysis/masks/surf/' ...
    subjname '/julian_parcels/']; mkdir(outdir);
tform_dir = [SUBJECTS_DIR '../data_analysis/subj2cvs_tform/' ...
    subjname '/final_CVSmorph_tocvs_avg35.m3z'];

% Transform parcel from CVS volume to subject's anatomial volume
for did = 1:length(dJP)
    parcel = dJP(did).name;
    pname = strtok(parcel, '.');
    hemi = [pname(1) 'h'];
    func_pname = pname(2:end)
    anatParcelName = [outdir pname '_anatomical.nii.gz'];

    cmd = ['mri_vol2vol --noDefM3zPath'...
        ' --mov ' SUBJECTS_DIR subjname '/mri/orig.mgz'...
        ' --targ ' srcParcelDir 'all/' parcel ...
        ' --m3z ' tform_dir ...
        ' --o ' anatParcelName ...
        ' --nearest' ...
        ' --inv-morph'];
    unix(cmd);

    funcParcelName = [outdir hemi(1) func_pname '_functional_smoothed.nii.gz'];
    % Transform parcels from the subject's anatomical volume to the subject's functional volume
    cmd = ['mri_vol2surf --regheader ' subjname ' --hemi ' hemi ' --mov ' anatParcelName ...
        ' --surf-fwhm 1 --o ' funcParcelName];
    unix(cmd);
end

%% vwfa parcels
% only does left hemisphere
outdir = [SUBJECTS_DIR '../data_analysis/masks/surf/' ...
   subjname '/vwfa_parcels/']; mkdir(outdir);
tform_dir = [SUBJECTS_DIR '../data_analysis/subj2cvsmni152_tform/' ...
   subjname '/final_CVSmorph_tocvs_avg35_inMNI152.m3z'];

for did = 1:length(dVWFA)
    parcel = dVWFA(did).name;
    pname = strtok(parcel, '.');
 
    anatParcelName = [outdir pname '_anatomical.nii.gz'];
 
    % Transform parcel from CVS-MNI152 volume to subject's anatomial volume
    cmd = ['mri_vol2vol --noDefM3zPath'...
        ' --mov ' SUBJECTS_DIR subjname '/mri/orig.mgz'...
        ' --targ ' srcParcelDir parcel ...
        ' --m3z ' tform_dir ...
        ' --o ' anatParcelName ...
        ' --nearest' ...
        ' --inv-morph'];
    unix(cmd)

    funcParcelName = [outdir pname '_functional_smoothed.nii.gz'];
    % Transform parcels from the subject's anatomical volume to the subject's functional volume
    cmd = ['mri_vol2surf --regheader ' subjname ' --hemi lh --mov ' anatParcelName ...
        ' --surf-fwhm 1 --o ' funcParcelName];
    unix(cmd);
end

%% MD parcels
outdir = [SUBJECTS_DIR '../data_analysis/masks/surf/' ...
   subjname '/md_parcels/']; mkdir(outdir);

for did = 1:length(dMD)
   parcel = dMD(did).name;
   pname = strtok(parcel, '.');
   anatParcelName = [outdir pname '_anatomical.nii.gz'];

   % Transform parcel from CVS-MNI152 volume to subject's anatomial volume
   cmd = ['mri_vol2vol --noDefM3zPath'...
       ' --mov ' SUBJECTS_DIR subjname '/mri/orig.mgz'...
       ' --targ ' srcParcelDir 'md/' parcel ...
       ' --m3z ' tform_dir ...
       ' --o ' anatParcelName ...
       ' --nearest' ...
       ' --inv-morph'];
   unix(cmd)

   for hid = 1:length(hemis)
        hemi = hemis{hid};
        funcParcelName = [outdir hemi(1) pname '_functional_smoothed.nii.gz'];
        % Transform parcels from the subject's anatomical volume to the subject's functional volume
        cmd = ['mri_vol2surf --regheader ' subjname ' --hemi ' hemi ' --mov ' anatParcelName ...
            ' --surf-fwhm 1 --o ' funcParcelName];
        unix(cmd);
    end
end

%% language parcels
voldir = [SUBJECTS_DIR '/../data_analysis/masks/vols/' ...
   subjname '/lang_parcels/'];
outdir = [SUBJECTS_DIR '/../data_analysis/masks/surf/' ...
   subjname '/lang_parcels/']; mkdir(outdir);

% convert the fsavg space parcel to subject space
for did = 1:length(dLang)
   parcel = dLang(did).name;
   pname = strtok(parcel, '.');

    for hid = 1:length(hemis)
        hemi = hemis{hid};
        funcParcelName = [outdir hemi(1) pname '_functional_smoothed.nii.gz'];
        % Transform parcels from the subject's anatomical volume to the subject's functional volume
        cmd = ['mri_vol2surf --regheader ' subjname ' --hemi ' hemi ' --mov ' voldir parcel ...
            ' --surf-fwhm 1 --o ' funcParcelName];
        unix(cmd);
    end
end

%% ToM parcels
voldir = [SUBJECTS_DIR '/../data_analysis/masks/vols/' ...
   subjname '/ToM_parcels/'];
outdir = [SUBJECTS_DIR '/../data_analysis/masks/surf/' ...
   subjname '/ToM_parcels/']; mkdir(outdir);

% use the transformation to bring the ToM parcels to subject functional space
% convert the fsavg space parcel to subject space
for did = 1:length(dToM)
   parcel = dToM(did).name;
   
    for hid = 1:length(hemis)
        hemi = hemis{hid};
        funcParcelName = [outdir hemi(1) parcel '_functional_smoothed.nii.gz'];
        % Transform parcels from the subject's anatomical volume to the subject's functional volume
        cmd = ['mri_vol2surf --regheader ' subjname ' --hemi ' hemi ' --mov ' voldir parcel ...
            ' --surf-fwhm 1 --o ' funcParcelName];
        unix(cmd);
    end
end

voldir = [SUBJECTS_DIR '/../data_analysis/masks/vols/' ...
   subjname '/speech_parcels_v2/lang_'];
outdir = [SUBJECTS_DIR '/../data_analysis/masks/surf/' ...
   subjname '/speech_parcels_v2/']; mkdir(outdir);

% Transform parcel from CVS volume to subject's anatomial volume
for did = 1:length(dSpeech)
    parcel = dSpeech(did).name;

    for hid = 1:length(hemis)
        hemi = hemis{hid};
        funcParcelName = [outdir hemi(1) 'speech_functional_smoothed.nii.gz'];
        % Transform parcels from the subject's anatomical volume to the subject's functional volume
        cmd = ['mri_vol2surf --regheader ' subjname ' --hemi ' hemi ' --mov ' voldir parcel ...
            ' --surf-fwhm 1 --o ' funcParcelName];
        unix(cmd);
    end
end

diary off

end
                                                                                                                          
