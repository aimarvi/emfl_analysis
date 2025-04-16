hemispheres = {'right', 'left'};
views = {[90 0], [-90 0], [180 -90]}; % views{3} for ventral
save_dir =  'surface_maps/';
mkdir(['figs/' save_dir]);


experiment.efficient.name = 'vis';
experiment.efficient.contrast = 'Fa-O';
experiment.parcel.dir = 'julian_parcels';
experiment.parcel.names = {'STS_functional'};

% subjects: 1 10 14 17 21 (randomly chosen for EMFL figs)
subj_ids = [1 10 14 17 21];
for hid = 1:length(hemispheres)
    hemisphere = hemispheres{hid};
    view = views{hid};
    for id = 1:length(subj_ids)
        try
            subj = sprintf('kaneff%02d', subj_ids(id));
            surface(subj, hemisphere, view, experiment)

            fname = ['figs/' save_dir filesep experiment.efficient.contrast '_' hemisphere '-' subj '_p3'];
            saveas(gcf, fname, 'png');
        catch ME
            % Display error message and continue to the next iteration
            fprintf('Error processing subject %s: %s\n', subj, ME.message);
            continue;
        end
    end
end
