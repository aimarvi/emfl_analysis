% build the subject-space transforms needed before parcelizing anything.
% run steps 1 to 3 separately.

function parcel_transform_final(subjname, run)

paths = emfl_paths();
SUBJECTS_DIR = paths.recons_dir;
setenv('SUBJECTS_DIR', SUBJECTS_DIR);

fprintf('subject: %s\n',subjname);

if run == 1
    %% cvs transform
    cmd = ['mri_cvs_register --mov ' subjname ' --outdir ' ...
        fullfile(paths.data_analysis_dir, 'subj2cvs_tform', subjname)];
    unix(cmd);
elseif run == 2
    %% cvs -> mni152 transform
    cmd = ['mri_cvs_register --mov ' subjname ' --mni --outdir ' ...
        fullfile(paths.data_analysis_dir, 'subj2cvsmni152_tform', subjname)];
    unix(cmd);
elseif run == 3
    %% fsaverage transform
    outdir = fullfile(paths.vols_vis_dir, subjname, 'bold');
    tformdir = fullfile(paths.data_analysis_dir, 'fsavg2subj_tform', subjname);
    mkdir(tformdir);

    % register subject functional to subject anatomy.
    filepath_meanfunc = fullfile(outdir, 'vis.sm3.all', 'meanfunc.nii.gz');
    filepath_func2anat = fullfile(tformdir, 'func2anat.lta');
    cmd = ['bbregister --s ' subjname ' --mov ' filepath_meanfunc ...
           ' --reg ' filepath_func2anat ' --init-coreg --init-best-fsl --init-best-header --bold --nocleanup'];
    unix(cmd);

    % register fsaverage anatomy to subject anatomy.
    filepath_fsavg2anat = fullfile(tformdir, 'fsavg2anat.lta');
    cmd = ['bbregister --s ' subjname ' --mov $SUBJECTS_DIR/fsaverage/mri/orig.mgz '...
           ' --reg ' filepath_fsavg2anat ' --init-coreg --init-best-fsl --init-best-header --t1 --nocleanup'];
    unix(cmd);

    % concatenate the transforms.
    filepath_fsavg2func = fullfile(tformdir, 'fsavg2func.lta');
    cmd = ['mri_concatenate_lta -invert2 ' filepath_fsavg2anat ...
        ' ' filepath_func2anat ' ' filepath_fsavg2func];
    unix(cmd);

    %% mni152 transform
    % write reg.mni152.2mm.lta under the subject transforms directory.
    cmd = ['mni152reg --s ' subjname];
    unix(cmd);

    %% mni152 -> subject functional transform
    filepath_mni152reg = fullfile(SUBJECTS_DIR, subjname, 'mri', 'transforms', 'reg.mni152.2mm.lta');
    filepath_mni152_to_func = fullfile(tformdir, 'mni152_to_func.lta');
    cmd = ['mri_concatenate_lta -invert2 ' filepath_mni152reg ...
        ' ' ...
        filepath_func2anat ' ' filepath_mni152_to_func];
    unix(cmd);    
end

end
