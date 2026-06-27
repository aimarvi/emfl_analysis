paths = emfl_matlab_paths();

hemisphere_names = {'right', 'left'};
view_angles = {[90 0], [-90 0], [180 -90]};

dir_output_relative = 'surface_maps';
dir_output = fullfile(paths.dir_project, 'figs', dir_output_relative);
mkdir(dir_output);

experiment.efficient.name = 'vis';
experiment.efficient.contrast = 'Fa-O';
experiment.parcel.dir = 'julian';
experiment.parcel.names = {'STS_functional'};

subject_ids = [1 10 14 17 21];

for hemisphere_index = 1:length(hemisphere_names)
    hemisphere_name = hemisphere_names{hemisphere_index};
    view_angle = view_angles{hemisphere_index};

    for subject_index = 1:length(subject_ids)
        subject_name = sprintf('kaneff%02d', subject_ids(subject_index));

        try
            surface(subject_name, hemisphere_name, view_angle, experiment);

            filename_output = [experiment.efficient.contrast '_' hemisphere_name '-' subject_name '_p3.png'];
            filepath_output = fullfile(dir_output, filename_output);
            saveas(gcf, filepath_output, 'png');
        catch err
            fprintf('error processing subject %s: %s\n', subject_name, err.message);
            continue;
        end
    end
end
