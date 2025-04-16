function surface(subj, hemisphere, view, experiment)
%%
% script to plot activations in subject native surface space
% requires read_freesurfer_brain.m and FreeSurfer 7.2.0
% adapted by @amarvi

PROJ_DIR = '~/mount2/recons';
RECON_DIR = [PROJ_DIR filesep subj];

[brain_data, vertex_data] = read_freesurfer_brain(RECON_DIR);

if strcmp(hemisphere, 'left')
    hemi = 'lh';
    inflated_brain = brain_data.inflated_left;
    curv = vertex_data.left.vertex_curvature_index;
else
    hemi = 'rh';
    inflated_brain = brain_data.inflated_right;
    curv = vertex_data.right.vertex_curvature_index;
end
curv = -sign(curv); % Adjust curvature data

%% Plot the anatomical 
clf;
h = plot_mesh_brain(inflated_brain, view, -curv); % Initial viewing position
colormap gray
clim([-10 1]);

%% Efficient localizer
exp = experiment.efficient.name;
contrast = experiment.efficient.contrast;
vol_path = [PROJ_DIR filesep '..' filesep 'vols_' exp ...
    filesep subj filesep 'bold' filesep exp '.sm3.all.' hemi ...
    filesep contrast filesep 'sig.nii.gz'];
surf2 = MRIread(vol_path).vol;
surf2(surf2 < 3) = nan;

%% paint the anatomical with activation maps
paint_mesh(surf2, 0, true);
colormap(autumn);
clim([-5 20]);

%% parcel
pdir = experiment.parcel.dir;

for pid = 1:length(experiment.parcel.names)
    parcel_name = experiment.parcel.names{pid};
    pname = [hemi(1) parcel_name '_smooth_' hemi '.nii.gz'];
    
    vol_path = [PROJ_DIR filesep '..' filesep 'data_analysis/masks/surf' ...
    filesep subj filesep pdir filesep pname];
    
    par = MRIread(vol_path).vol;
    
    if strcmp(pdir, 'lang_parcels') || strcmp(pdir, 'speech_parcels_v2')
        lower = 0.1;
        upper = 0.9;
    else
        lower = 0.2;
        upper = 0.8;
    
    end
    par(par<lower)=nan; % 0.33 - 0.66 for normal use
    par(par>upper)=nan; % 0.1 - 0.9 for lang parcels
    
    paint_mesh(par, [], true, h);
    colormap(slanCM('Greys'));
    clim([-10 -2]);

end


end
