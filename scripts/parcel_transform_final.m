% transform subjects to cvs, mni152, and fsavg space
% required before getting parcellations for each subject (julian, language,
% ToM, vwfa, speech, physics, md)
% Created by: @amarvi 
% Last edit: 10/02/2023

function parcel_transform_final(subjname, run)

SUBJECTS_DIR = '../recons/';
setenv('SUBJECTS_DIR', SUBJECTS_DIR )

fprintf('subject: %s\n',subjname);

if run == 1
    %% cvs transform
    % generate m3z file from subject space -> cvs
    cmd = ['mri_cvs_register --mov ' subjname ' --outdir ' ...
        [SUBJECTS_DIR '../data_analysis/subj2cvs_tform/' subjname '/']];
    unix(cmd);
elseif run == 2
    %% cvs-mni152 transform
    cmd = ['mri_cvs_register --mov ' subjname ' --mni --outdir ' ...
        [SUBJECTS_DIR '../data_analysis/subj2cvsmni152_tform/' subjname '/']];
    unix(cmd);
elseif run == 3
    %% fsavg transform
    outdir = [SUBJECTS_DIR '/../vols_vis/' subjname filesep 'bold/'];
    tformdir = [SUBJECTS_DIR '/../data_analysis/fsavg2subj_tform/' subjname filesep]; mkdir(tformdir);

    % register subject-specific functional to subject-specific anat
    cmd = ['bbregister --s ' subjname ' --mov ' outdir 'vis.sm3.all/meanfunc.nii.gz '...
           '--reg ' tformdir 'func2anat.lta --init-coreg --init-best-fsl --init-best-header --bold --nocleanup'];
    unix(cmd);

    % register fsavg to subject-specific anat
    cmd = ['bbregister --s ' subjname ' --mov $SUBJECTS_DIR/fsaverage/mri/orig.mgz '...
           '--reg ' tformdir 'fsavg2anat.lta --init-coreg --init-best-fsl --init-best-header --t1 --nocleanup'];
    unix(cmd);

    % get the registration matrix by concatenating the previous steps
    cmd = ['mri_concatenate_lta -invert2 ' tformdir 'fsavg2anat.lta '...
        tformdir 'func2anat.lta ' tformdir 'fsavg2func.lta'];
    unix(cmd);

    %% mni152 transform
    % get the mni152 to subject anat transformation matrix
    cmd = ['mni152reg --s ' subjname]; % make sure the subject is in the SUBJECTS_DIR
    % the tform matrix reg.mni152.2mm.lta will be stored in SUBJECTS_DIR under subject-specific mri/transforms/ 
    unix(cmd);

    %% mni2fsavg transform
    % concatenate the mni2fsavg transformation with the func2anat
    % trasnsformation (under data_analysis/fsavg2subj_tform/) to get mni152
    % to subject functional transformation matrix
    cmd = ['mri_concatenate_lta -invert2 ' SUBJECTS_DIR ...
        subjname '/mri/transforms/reg.mni152.2mm.lta ' ...
        tformdir 'func2anat.lta ' tformdir 'mni152_to_func.lta'];
    unix(cmd);    
end

end
