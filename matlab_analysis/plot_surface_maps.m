function surface(subj, hemisphere, view, experiment)
% plot activations in subject native surface space.
% require read_freesurfer_brain.m and freesurfer.

paths = emfl_matlab_paths();
dir_recon_subject = fullfile(paths.dir_recons, subj);

[brain_data, vertex_data] = read_freesurfer_brain(dir_recon_subject);

if strcmp(hemisphere, 'left')
    hemi = 'lh';
    inflated_brain = brain_data.inflated_left;
    curvature = vertex_data.left.vertex_curvature_index;
else
    hemi = 'rh';
    inflated_brain = brain_data.inflated_right;
    curvature = vertex_data.right.vertex_curvature_index;
end

curvature = -sign(curvature);

clf;
brain_handle = plot_mesh_brain(inflated_brain, view, -curvature);
colormap gray
clim([-10 1]);

exp_name = experiment.efficient.name;
contrast_name = experiment.efficient.contrast;
filepath_activation = fullfile(paths.dir_project, ['vols_' exp_name], subj, 'bold', ...
    [exp_name '.sm3.all.' hemi], contrast_name, 'sig.nii.gz');
activation_data = MRIread(filepath_activation).vol;
activation_data(activation_data < 3) = nan;

paint_mesh(activation_data, 0, true);
colormap(autumn);
clim([-5 20]);

parcel_group = experiment.parcel.dir;

for parcel_index = 1:length(experiment.parcel.names)
    parcel_name = experiment.parcel.names{parcel_index};
    filename_parcel = [hemi '.' parcel_name '.func.nii.gz'];
    filepath_parcel = fullfile(paths.dir_data_analysis, 'masks', 'surf', subj, parcel_group, filename_parcel);

    parcel_data = MRIread(filepath_parcel).vol;

    if strcmp(parcel_group, 'language') || strcmp(parcel_group, 'speech')
        lower_bound = 0.1;
        upper_bound = 0.9;
    else
        lower_bound = 0.2;
        upper_bound = 0.8;
    end

    parcel_data(parcel_data < lower_bound) = nan;
    parcel_data(parcel_data > upper_bound) = nan;

    paint_mesh(parcel_data, [], true, brain_handle);
    colormap(slanCM('Greys'));
    clim([-10 -2]);
end

end
