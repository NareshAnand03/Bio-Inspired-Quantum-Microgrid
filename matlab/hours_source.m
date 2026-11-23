%% FIG. 4 - 24-HOUR SOURCE AND LOAD PROFILES
% AC Bio-Inspired Microgrid Architecture
%
% Required actual CSV file:
% microgrid_logs.csv
%
% Required columns:
% Time_s, PV_MW, Wind_MW, Load_MW
%
% Optional BESS columns:
% BESS_P_MW, BESS_SOC_pct
%
% If the CSV is missing or contains only headers,
% an illustrative preview is generated and labelled accordingly.
% Preview data is NOT a MATLAB/Simulink simulation result.

clear;
clc;
close all;

%% 1. OUTPUT FOLDER

outFolder = fullfile(pwd, 'microgrid_figures');

if ~exist(outFolder, 'dir')
    mkdir(outFolder);
end

csvFile = fullfile(pwd, 'microgrid_logs.csv');

%% 2. LOAD ACTUAL DATA OR CREATE AN ILLUSTRATIVE PREVIEW

usePreview = true;
hasBESS = false;

if isfile(csvFile)

    try
        T = readtable(csvFile);

        requiredColumns = ...
            {'Time_s','PV_MW','Wind_MW','Load_MW'};

        if height(T) > 1 && ...
                all(ismember(requiredColumns, ...
                T.Properties.VariableNames))

            time_s = T.Time_s;
            PV_MW = T.PV_MW;
            Wind_MW = T.Wind_MW;
            Load_MW = T.Load_MW;

            valid = isnumeric(time_s) && ...
                isnumeric(PV_MW) && ...
                isnumeric(Wind_MW) && ...
                isnumeric(Load_MW);

            if valid
                valid = all(isfinite(time_s)) && ...
                    all(isfinite(PV_MW)) && ...
                    all(isfinite(Wind_MW)) && ...
                    all(isfinite(Load_MW));
            end

            if valid && numel(time_s) > 1 && ...
                    all(diff(time_s) > 0)

                time_h = time_s / 3600;
                usePreview = false;

                if ismember('BESS_P_MW', ...
                        T.Properties.VariableNames) && ...
                   ismember('BESS_SOC_pct', ...
                        T.Properties.VariableNames)

                    bp = T.BESS_P_MW;
                    bs = T.BESS_SOC_pct;

                    if isnumeric(bp) && isnumeric(bs) && ...
                            any(isfinite(bp)) && ...
                            any(isfinite(bs))

                        hasBESS = true;
                        BESS_P_MW = bp;
                        BESS_SOC_pct = bs;

                    end
                end

                fprintf('Loaded data from: %s\n', csvFile);

            end
        end

    catch ME
        fprintf('CSV could not be read: %s\n', ME.message);
    end
end

%% 3. CREATE PREVIEW IF ACTUAL DATA IS UNAVAILABLE

if usePreview

    fprintf('\nNo valid simulation data found.\n');
    fprintf('Creating ILLUSTRATIVE PREVIEW ONLY.\n');

    time_h = linspace(0, 24, 289)';

    % Illustrative solar profile, MW
    solarShape = max(0, ...
        sin(pi*(time_h - 6)/12));

    PV_MW = 30 * solarShape.^1.5;

    % Illustrative wind profile, MW
    Wind_MW = 8 + 2.5 * ...
        sin(2*pi*time_h/8);

    Wind_MW = max(Wind_MW, 0);

    % Illustrative load profile, MW
    Load_MW = 52 ...
        + 6*sin(2*pi*(time_h - 7)/24) ...
        + 3*sin(4*pi*(time_h - 5)/24);

    % No BESS is invented for the preview.
    hasBESS = false;

end

%% 4. VALIDATE ARRAYS

time_h = time_h(:);
PV_MW = PV_MW(:);
Wind_MW = Wind_MW(:);
Load_MW = Load_MW(:);

if numel(time_h) ~= numel(PV_MW) || ...
   numel(time_h) ~= numel(Wind_MW) || ...
   numel(time_h) ~= numel(Load_MW)

    error('Time, PV, wind and load arrays must have equal lengths.');
end

if any(~isfinite(time_h)) || ...
   any(~isfinite(PV_MW)) || ...
   any(~isfinite(Wind_MW)) || ...
   any(~isfinite(Load_MW))

    error('The profile contains missing or non-finite data.');
end

%% 5. GENERATE FIGURE

fig = figure( ...
    'Color','w', ...
    'Name','Fig. 4 - 24-Hour Source and Load Profiles', ...
    'Position',[100 100 1150 720]);

if hasBESS

    %% TOP PANEL - GENERATION AND LOAD

    subplot(2,1,1);

    plot(time_h, PV_MW, 'LineWidth',1.6);
    hold on;

    plot(time_h, Wind_MW, 'LineWidth',1.6);
    plot(time_h, Load_MW, 'LineWidth',1.6);

    ylabel('Active Power (MW)');

    legend('PV Generation', ...
        'Wind Generation', ...
        'Load Demand', ...
        'Location','best');

    title('24-Hour Generation and Load');

    grid on;
    xlim([min(time_h), max(time_h)]);

    %% BOTTOM PANEL - BESS POWER AND STATE OF CHARGE

    subplot(2,1,2);

    yyaxis left;

    plot(time_h, BESS_P_MW, 'LineWidth',1.5);

    ylabel('BESS Power (MW)');

    yyaxis right;

    plot(time_h, BESS_SOC_pct, '--', ...
        'LineWidth',1.5);

    ylabel('State of Charge (%)');
    ylim([0 100]);

    xlabel('Time (hours)');

    title('Battery Power and State of Charge');

    grid on;
    xlim([min(time_h), max(time_h)]);

else

    %% SINGLE PANEL - GENERATION AND LOAD

    plot(time_h, PV_MW, 'LineWidth',1.7);
    hold on;

    plot(time_h, Wind_MW, 'LineWidth',1.7);
    plot(time_h, Load_MW, 'LineWidth',1.7);

    xlabel('Time (hours)');
    ylabel('Active Power (MW)');

    legend('PV Generation', ...
        'Wind Generation', ...
        'Load Demand', ...
        'Location','best');

    grid on;
    xlim([min(time_h), max(time_h)]);

end

%% 6. TITLE AND EVIDENCE STATUS

if usePreview

    sgtitle({ ...
        'ILLUSTRATIVE PREVIEW ONLY - NOT SIMULATION OUTPUT', ...
        '24-Hour Renewable Generation and Load Profiles'}, ...
        'FontWeight','bold');

else

    sgtitle({ ...
        'Fig. 4 - 24-Hour Source and Load Profiles', ...
        'Data read from microgrid_logs.csv'}, ...
        'FontWeight','bold');

end

%% 7. EXPORT FIGURE

pngFile = fullfile(outFolder, ...
    'Fig_4_24Hour_Source_Load_Profiles.png');

figFile = fullfile(outFolder, ...
    'Fig_4_24Hour_Source_Load_Profiles.fig');

try
    exportgraphics(fig, pngFile, 'Resolution',300);
catch
    print(fig, pngFile, '-dpng', '-r300');
end

savefig(fig, figFile);

fprintf('\nFigure generation completed.\n');
fprintf('PNG saved at:\n%s\n', pngFile);
fprintf('MATLAB figure saved at:\n%s\n', figFile);

if usePreview
    fprintf(['WARNING: This figure uses illustrative data. ' ...
        'Replace it with real simulation outputs before publication.\n']);
elseif max(time_h)-min(time_h) < 23.9
    warning(['The logged duration is less than 24 hours. ' ...
        'Do not describe it as a complete 24-hour result.']);
else
    fprintf('Source data covers approximately 24 hours.\n');
end