%% FIGURE 3: MODEL PARAMETER SETTINGS
% AC Bio-Inspired Microgrid Architecture
%
% Reads solver settings from an existing Simulink model.
% Creates a publication-ready parameter summary figure.
%
% IMPORTANT:
% Paper assumptions are distinguished from actual model settings.
% Missing settings are explicitly labelled.
% This figure alone does not prove simulation validation.

clear;
clc;
close all;

%% 1. SELECT THE SIMULINK MODEL

% Change this name if your actual model has a different name.
model = 'BioInspiredMicrogrid_SystemLevel_Template';

outFolder = fullfile(pwd, 'microgrid_figures');

if ~exist(outFolder, 'dir')
    mkdir(outFolder);
end

%% 2. CHECK WHETHER THE MODEL EXISTS

modelAvailable = false;

if bdIsLoaded(model)
    modelAvailable = true;

elseif exist([model '.slx'], 'file') == 2
    load_system(model);
    modelAvailable = true;

elseif exist([model '.mdl'], 'file') == 2
    load_system(model);
    modelAvailable = true;
end

%% 3. READ ACTUAL SIMULINK SOLVER SETTINGS

if modelAvailable

    solverType = readParam(model, 'SolverType');
    solverName = readParam(model, 'Solver');
    fixedStep  = readParam(model, 'FixedStep');
    maxStep    = readParam(model, 'MaxStep');
    startTime  = readParam(model, 'StartTime');
    stopTime   = readParam(model, 'StopTime');

    modelStatus = ...
        'Model file found; see model-type warning below';

else

    solverType = 'NOT AVAILABLE - model not found';
    solverName = 'NOT AVAILABLE';
    fixedStep  = 'NOT AVAILABLE';
    maxStep    = 'NOT AVAILABLE';
    startTime  = 'NOT AVAILABLE';
    stopTime   = 'NOT AVAILABLE';

    modelStatus = ...
        'Model not found; solver settings were not read';

end

%% 4. DEFINE DOCUMENTED VALUES AND EVIDENCE STATUS

parameters = {
    'Model name', model
    'Model availability', modelStatus
    'Model type', ...
        'Verify whether this is a physical electrical model or signal-flow template'
    'Solver type', solverType
    'Solver algorithm', solverName
    'Fixed-step size', fixedStep
    'Maximum variable-step size', maxStep
    'Simulation start time', startTime
    'Simulation stop time', stopTime
    'Sample time', ...
        'Block-specific; inspect actual discrete blocks and controller settings'
    'Nominal AC line-line voltage', ...
        '11 kV - paper assumption; confirm against actual model'
    'Nominal frequency', ...
        '50 Hz - paper assumption; confirm against actual model'
    'Total reference load', ...
        '70 MW - analytical reference case, not proof of model loading'
    'Number of feeders', ...
        '10 - intended architecture'
    'Reference load per feeder', ...
        '7 MW - equal analytical split'
    'PV rated power', ...
        'NOT SPECIFIED in the supplied paper'
    'Wind rated power', ...
        'NOT SPECIFIED in the supplied paper'
    'DC bus voltage', ...
        'NOT SPECIFIED in the supplied paper'
    'GFM controller', ...
        'Controller type and gains NOT SPECIFIED'
    'GFL controller', ...
        'Controller type and gains NOT SPECIFIED'
    'BESS rating and SOC limits', ...
        'Optional; NOT SPECIFIED'
    'Power factor', ...
        '0.92 urban / 0.98 proposed - analytical assumptions'
    'Feeder lengths', ...
        '8 km urban / 3 km proposed - analytical assumptions'
    };

%% 5. PRINT SETTINGS TO COMMAND WINDOW

fprintf('\nFIGURE 3 - MODEL PARAMETER SETTINGS\n');
fprintf('====================================\n');

for k = 1:size(parameters, 1)
    fprintf('%-32s : %s\n', ...
        parameters{k,1}, parameters{k,2});
end

%% 6. CREATE THE REPORT FIGURE

fig = figure( ...
    'Name', 'Fig. 3 - Model Parameter Settings', ...
    'Color', 'w', ...
    'Units', 'pixels', ...
    'Position', [80 50 1400 900], ...
    'NumberTitle', 'off');

annotation(fig, 'textbox', ...
    [0.035 0.925 0.93 0.045], ...
    'String', 'FIG. 3 - MODEL PARAMETER SETTINGS', ...
    'EdgeColor', 'none', ...
    'FontSize', 17, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');

annotation(fig, 'textbox', ...
    [0.035 0.885 0.93 0.03], ...
    'String', ...
    'AC Bio-Inspired Microgrid Architecture for Renewable-Rich Urban Distribution Systems', ...
    'EdgeColor', 'none', ...
    'FontSize', 10, ...
    'HorizontalAlignment', 'center');

%% 7. ADD PARAMETER TABLE

uitable(fig, ...
    'Data', parameters, ...
    'ColumnName', {'Parameter', 'Value / Evidence Status'}, ...
    'ColumnWidth', {300, 960}, ...
    'RowName', [], ...
    'FontSize', 10, ...
    'Units', 'normalized', ...
    'Position', [0.035 0.105 0.93 0.765]);

%% 8. ADD IMPORTANT EVIDENCE NOTE

annotation(fig, 'textbox', ...
    [0.04 0.025 0.92 0.06], ...
    'String', ...
    ['Evidence note: Values labelled as assumptions or NOT SPECIFIED ' ...
     'must be confirmed from the actual model. A signal-flow diagram ' ...
     'does not validate voltage, current, inverter controls or power losses.'], ...
    'EdgeColor', 'none', ...
    'FontSize', 9, ...
    'HorizontalAlignment', 'left');

%% 9. EXPORT THE FIGURE

pngFile = fullfile(outFolder, ...
    'Fig_3_Model_Parameter_Settings.png');

figFile = fullfile(outFolder, ...
    'Fig_3_Model_Parameter_Settings.fig');

csvFile = fullfile(outFolder, ...
    'Fig_3_Model_Parameter_Settings.csv');

try
    exportgraphics(fig, pngFile, 'Resolution', 250);
catch
    print(fig, pngFile, '-dpng', '-r250');
end

savefig(fig, figFile);

settingsTable = cell2table(parameters, ...
    'VariableNames', {'Parameter','Value_Status'});

writetable(settingsTable, csvFile);

fprintf('\nFigure 3 has been generated.\n');
fprintf('PNG: %s\n', pngFile);
fprintf('Editable FIG: %s\n', figFile);
fprintf('CSV report: %s\n', csvFile);

%% 10. HELPER FUNCTION TO READ MODEL PARAMETERS

function value = readParam(modelName, parameterName)

    try
        rawValue = get_param(modelName, parameterName);

        if isnumeric(rawValue)
            value = num2str(rawValue);

        elseif isstring(rawValue)
            value = char(rawValue);

        else
            value = rawValue;
        end

        if isempty(value)
            value = 'Not set';
        end

    catch
        value = 'Unavailable - inspect model configuration';
    end

end