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

% path to your project directory (specifically the ./recons folder)
SUBJECTS_DIR = '/XXX/recons/';
setenv('SUBJECTS_DIR',SUBJECTS_DIR);

srcParcelDir = 'PARCELS/';
hemis = {'lh', 'rh'};

dJP = dir([srcParcelDir 'julian/*.nii.gz']);
dLang = dir([srcParcelDir 'language/.nii.gz']);
dSpeech = dir([srcParcelDir 'speech/*.nii.gz']);
dToM = dir([srcParcelDir 'tom/*.nii.gz']);
dVWFA = dir([srcParcelDir 'vwfa/*.nii.gz']);
dMD = dir([srcParcelDir 'md/*.nii.gz']);

fprintf('subject: %s\n', subjname);

logDir = [SUBJECTS_DIR '../data_analysis/masks/surf/' subjname '/log/']; mkdir(logDir);
diaryname = ['parcelize_' subjname '.txt'];
diary([logDir diaryname]);

%% julian parcels
outdir = [SUBJECTS_DIR '../data_analysis/masks/surf/' ...
    subjname '/julian/']; mkdir(outdir);
tform_dir = [SUBJECTS_DIR '../data_analysis/subj2cvs_tform/' ...
    subjname '/final_CVSmorph_tocvs_avg35.m3z'];

% Transform parcel from CVS volume to subject's anatomial volume
for did = 1:length(dJP)
    parcel = dJP(did).name;
    pnames = split(parcel, '.');

    anatParcelName = [outdir pnames(1) '.' pnames(2) '.anat.nii.gz'];
    funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];

    cmd = ['mri_vol2vol --noDefM3zPath'...
        ' --mov ' SUBJECTS_DIR subjname '/mri/orig.mgz'...
        ' --targ ' srcParcelDir 'julian/' parcel ...
        ' --m3z ' tform_dir ...
        ' --o ' anatParcelName ...
        ' --nearest' ...
        ' --inv-morph'];
    unix(cmd);

    % Transform parcels from the subject's anatomical volume to the subject's functional volume
    cmd = ['mri_vol2surf --regheader ' subjname ' --hemi ' pnames(1) ' --mov ' anatParcelName ...
        ' --surf-fwhm 1 --o ' funcParcelName];
    unix(cmd);
end

%% vwfa parcels
% only does left hemisphere
outdir = [SUBJECTS_DIR '../data_analysis/masks/surf/' ...
   subjname '/vwfa/']; mkdir(outdir);
tform_dir = [SUBJECTS_DIR '../data_analysis/subj2cvsmni152_tform/' ...
   subjname '/final_CVSmorph_tocvs_avg35_inMNI152.m3z'];

for did = 1:length(dVWFA)
    parcel = dVWFA(did).name;
    pnames = split(parcel, '.');

    anatParcelName = [outdir pnames(1) '.' pnames(2) '.anat.nii.gz'];
    funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];
 
    % Transform parcel from CVS-MNI152 volume to subject's anatomial volume
    cmd = ['mri_vol2vol --noDefM3zPath'...
        ' --mov ' SUBJECTS_DIR subjname '/mri/orig.mgz'...
        ' --targ ' srcParcelDir parcel ...
        ' --m3z ' tform_dir ...
        ' --o ' anatParcelName ...
        ' --nearest' ...
        ' --inv-morph'];
    unix(cmd)

    % Transform parcels from the subject's anatomical volume to the subject's functional volume
    cmd = ['mri_vol2surf --regheader ' subjname ' --hemi' pnames(1) ' --mov ' anatParcelName ...
        ' --surf-fwhm 1 --o ' funcParcelName];
    unix(cmd);
end

%% MD parcels
outdir = [SUBJECTS_DIR '../data_analysis/masks/surf/' ...
   subjname '/md/']; mkdir(outdir);

for did = 1:length(dMD)
    parcel = dMD(did).name;
    pnames = split(parcel, '.');

    if strcmp(pnames(1), 'all')
        continue
    end

    anatParcelName = [outdir pnames(1) '.' pnames(2) '.anat.nii.gz'];
    funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];

    % Transform parcel from CVS-MNI152 volume to subject's anatomial volume
    cmd = ['mri_vol2vol --noDefM3zPath'...
      ' --mov ' SUBJECTS_DIR subjname '/mri/orig.mgz'...
      ' --targ ' srcParcelDir 'md/' parcel ...
      ' --m3z ' tform_dir ...
      ' --o ' anatParcelName ...
      ' --nearest' ...
      ' --inv-morph'];
    unix(cmd)

    % Transform parcels from the subject's anatomical volume to the subject's functional volume
    cmd = ['mri_vol2surf --regheader ' subjname ' --hemi ' pnames(1) ' --mov ' anatParcelName ...
       ' --surf-fwhm 1 --o ' funcParcelName];
    unix(cmd);
end

%% language parcels
voldir = [SUBJECTS_DIR '/../data_analysis/masks/vols/' ...
   subjname '/language/'];
outdir = [SUBJECTS_DIR '/../data_analysis/masks/surf/' ...
   subjname '/language/']; mkdir(outdir);

% convert the fsavg space parcel to subject space
for did = 1:length(dLang)
    parcel = dLang(did).name;
    pnames = strtok(parcel, '.');

    if strcmp(pnames(1), 'all')
        continue
    end

    funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];

    % Transform parcels from the subject's anatomical volume to the subject's functional volume
    cmd = ['mri_vol2surf --regheader ' subjname ' --hemi ' pnames(1) ' --mov ' voldir parcel ...
        ' --surf-fwhm 1 --o ' funcParcelName];
    unix(cmd);
end

%% ToM parcels
voldir = [SUBJECTS_DIR '/../data_analysis/masks/vols/' ...
   subjname '/tom/'];
outdir = [SUBJECTS_DIR '/../data_analysis/masks/surf/' ...
   subjname '/tom/']; mkdir(outdir);

% use the transformation to bring the ToM parcels to subject functional space
% convert the fsavg space parcel to subject space
for did = 1:length(dToM)
    parcel = dToM(did).name;
    pnames = split(parcel, '.');
 
    if contains(pnames(1), 'h')
        funcParcelName = [outdir pnames(1) '.' pnames(2) '.func.nii.gz'];  
        % Transform parcels from the subject's anatomical volume to the subject's functional volume
        cmd = ['mri_vol2surf --regheader ' subjname ' --hemi ' pnames(1) ' --mov ' voldir parcel ...
            ' --surf-fwhm 1 --o ' funcParcelName];
        unix(cmd);
    else
        for hid = 1:length(hemis)
            hemi = hemis{hid};
            funcParcelName = [outdir hemi '.' pnames(2) '.func.nii.gz'];
            % Transform parcels from the subject's anatomical volume to the subject's functional volume
            cmd = ['mri_vol2surf --regheader ' subjname ' --hemi ' hemi ' --mov ' voldir parcel ...
                ' --surf-fwhm 1 --o ' funcParcelName];
            unix(cmd);
        end
    end
end

voldir = [SUBJECTS_DIR '/../data_analysis/masks/vols/' ...
   subjname '/speech/'];
outdir = [SUBJECTS_DIR '/../data_analysis/masks/surf/' ...
   subjname '/speech/']; mkdir(outdir);

% Transform parcel from CVS volume to subject's anatomial volume
for did = 1:length(dSpeech)
    parcel = dSpeech(did).name;
    pnames = split(parcel, '.');

    for hid = 1:length(hemis)
        hemi = hemis{hid};
        funcParcelName = [outdir hemi '.' pnames(2) '.func.nii.gz'];
        % Transform parcels from the subject's anatomical volume to the subject's functional volume
        cmd = ['mri_vol2surf --regheader ' subjname ' --hemi ' hemi ' --mov ' voldir parcel ...
            ' --surf-fwhm 1 --o ' funcParcelName];
        unix(cmd);
    end
end

diary off

end
                                                                                                                          
