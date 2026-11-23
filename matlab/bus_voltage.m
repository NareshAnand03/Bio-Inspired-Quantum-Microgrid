%% FIG. 5 - BUS VOLTAGE PROFILE
% AC Bio-Inspired Microgrid Architecture
%
% INPUT FILE:
% microgrid_logs.csv
%
% Required:
% Time_s, Vbus1_pu, Vbus2_pu, ...
%
% Alternatively:
% Time_s, Vbus1_kV, Vbus2_kV, ...
%
% Use only actual voltages logged from the electrical model.
% The code does not create synthetic voltage measurements.
%
% Nominal system voltage: 11 kV line-to-line (paper assumption)
% Illustrative screening limits: 0.95 to 1.05 pu
% Replace these limits if your study requires different limits.

clear;
clc;
close all;

%% 1. CONFIGURATION

csvFile = fullfile(pwd, 'microgrid_logs.csv');

outFolder = fullfile(pwd, 'microgrid_figures');

if ~exist(outFolder, 'dir')
    mkdir(outFolder);
end

nominalVoltage_kV = 11;

lowerLimit_pu = 0.95;
upperLimit_pu = 1.05;

%% 2. LOAD SIMULATION DATA

if ~isfile(csvFile)
    error(['Simulation data not found: %s\n' ...
        'Export actual bus voltages and Time_s from Simulink first.'], ...
        csvFile);
end

T = readtable(csvFile);

variables = T.Properties.VariableNames;

if ~ismember('Time_s', variables)
    error('CSV must contain a numeric Time_s column.');
end

time_s = T.Time_s;

if ~isnumeric(time_s) || ...
        numel(time_s) < 2 || ...
        any(~isfinite(time_s)) || ...
        any(diff(time_s) <= 0)

    error(['Time_s must contain at least two finite, ' ...
        'strictly increasing time samples.']);
end

%% 3. FIND VOLTAGE COLUMNS

puColumns = variables( ...
    startsWith(variables, 'Vbus') & ...
    endsWith(variables, '_pu'));

kVColumns = variables( ...
    startsWith(variables, 'Vbus') & ...
    endsWith(variables, '_kV'));

if ~isempty(puColumns) && ~isempty(kVColumns)
    error(['Use either VbusN_pu or VbusN_kV columns, ' ...
        'not a mixture of both.']);
end

if ~isempty(puColumns)

    voltageColumns = puColumns;
    voltageUnit = 'pu';

    lowerLimit = lowerLimit_pu;
    upperLimit = upperLimit_pu;
    nominalVoltage = 1;

elseif ~isempty(kVColumns)

    voltageColumns = kVColumns;
    voltageUnit = 'kV';

    % Assumes each monitored bus is rated at 11 kV line-to-line.
    nominalVoltage = nominalVoltage_kV;

    lowerLimit = lowerLimit_pu * nominalVoltage;
    upperLimit = upperLimit_pu * nominalVoltage;

else

    error(['No bus voltage columns found.\n' ...
        'Expected Vbus1_pu, Vbus2_pu, ... OR ' ...
        'Vbus1_kV, Vbus2_kV, ...']);

end

%% 4. EXTRACT VOLTAGE MEASUREMENTS

V = T{:, voltageColumns};

if ~isnumeric(V)
    error('Voltage columns must contain numeric measurements.');
end

V = double(V);

% Treat missing/invalid individual samples as missing data.
V(~isfinite(V)) = NaN;

% Remove buses for which no measurements are available.
hasData = any(isfinite(V), 1);

if any(~hasData)
    warning('Ignoring voltage columns with no valid measurements.');
end

V = V(:, hasData);
voltageColumns = voltageColumns(hasData);

if isempty(voltageColumns)
    error('No valid voltage measurements are available.');
end

%% 5. DETERMINE EXACT TIME INTERVAL

tStart_s = time_s(1);
tEnd_s = time_s(end);
duration_s = tEnd_s - tStart_s;

tStart_h = tStart_s / 3600;
tEnd_h = tEnd_s / 3600;
duration_h = duration_s / 3600;

if duration_s >= 3600
    plotTime = time_s / 3600;
    xLabelText = 'Simulation Time (hours)';
    tStart = tStart_h;
    tEnd = tEnd_h;
else
    plotTime = time_s;
    xLabelText = 'Simulation Time (seconds)';
    tStart = tStart_s;
    tEnd = tEnd_s;
end

periodText = sprintf( ...
    'Start = %.6g s | End = %.6g s | Duration = %.6g s', ...
    tStart_s, tEnd_s, duration_s);

fprintf('\nFIG. 5 - BUS VOLTAGE PROFILE\n');
fprintf('====================================\n');
fprintf('%s\n', periodText);
fprintf('Number of monitored buses: %d\n', ...
    numel(voltageColumns));
fprintf('Voltage unit: %s\n', voltageUnit);
fprintf('Lower limit: %.4f %s\n', lowerLimit, voltageUnit);
fprintf('Upper limit: %.4f %s\n', upperLimit, voltageUnit);

%% 6. CREATE BUS VOLTAGE PROFILE

fig = figure( ...
    'Name', 'Fig. 5 - Bus Voltage Profile', ...
    'Color', 'w', ...
    'Position', [100 100 1200 700]);

hold on;

for k = 1:numel(voltageColumns)

    plot(plotTime, V(:,k), ...
        'LineWidth', 1.15, ...
        'DisplayName', strrep(voltageColumns{k}, '_', '\_'));

end

% Voltage limits
yline(lowerLimit, 'k--', ...
    sprintf('Lower limit: %.4g %s', ...
    lowerLimit, voltageUnit), ...
    'LineWidth', 1.3);

yline(upperLimit, 'k--', ...
    sprintf('Upper limit: %.4g %s', ...
    upperLimit, voltageUnit), ...
    'LineWidth', 1.3);

% Nominal voltage/reference line
yline(nominalVoltage, 'k:', ...
    sprintf('Nominal: %.4g %s', ...
    nominalVoltage, voltageUnit), ...
    'LineWidth', 1.3);

xlabel(xLabelText);
ylabel(['Bus Voltage (' voltageUnit ')']);

title({'Fig. 5 - Bus Voltage Profiles', periodText}, ...
    'FontWeight', 'bold', ...
    'FontSize', 12);

legend('Location', 'eastoutside', ...
    'Interpreter', 'tex');

grid on;
box on;

xlim([tStart tEnd]);

%% 7. CALCULATE BUS VOLTAGE STATISTICS

nBus = numel(voltageColumns);

MinVoltage = nan(nBus,1);
MaxVoltage = nan(nBus,1);
MeanVoltage = nan(nBus,1);
RMSVoltage = nan(nBus,1);
SamplesOutsideLimits = zeros(nBus,1);
PercentOutsideLimits = nan(nBus,1);

for k = 1:nBus

    x = V(:,k);
    valid = isfinite(x);
    xv = x(valid);

    if isempty(xv)
        continue;
    end

    MinVoltage(k) = min(xv);
    MaxVoltage(k) = max(xv);
    MeanVoltage(k) = mean(xv);
    RMSVoltage(k) = sqrt(mean(xv.^2));

    violations = xv < lowerLimit | xv > upperLimit;

    SamplesOutsideLimits(k) = sum(violations);

    PercentOutsideLimits(k) = ...
        100 * sum(violations) / numel(xv);

end

Bus = voltageColumns(:);

VoltageSummary = table( ...
    Bus, ...
    MinVoltage, ...
    MaxVoltage, ...
    MeanVoltage, ...
    RMSVoltage, ...
    SamplesOutsideLimits, ...
    PercentOutsideLimits);

disp(' ');
disp('BUS VOLTAGE STATISTICS');
disp(VoltageSummary);

%% 8. EXPORT FIGURE AND RESULTS

pngFile = fullfile(outFolder, ...
    'Fig_5_Bus_Voltage_Profile.png');

figFile = fullfile(outFolder, ...
    'Fig_5_Bus_Voltage_Profile.fig');

csvSummary = fullfile(outFolder, ...
    'Fig_5_Bus_Voltage_Statistics.csv');

try
    exportgraphics(fig, pngFile, 'Resolution', 300);
catch
    print(fig, pngFile, '-dpng', '-r300');
end

savefig(fig, figFile);
writetable(VoltageSummary, csvSummary);

fprintf('\nFigure 5 generated successfully.\n');
fprintf('PNG: %s\n', pngFile);
fprintf('Editable MATLAB figure: %s\n', figFile);
fprintf('Voltage statistics: %s\n', csvSummary);

fprintf(['\nNOTE: Limits are an illustrative +/-5%% screening band. ' ...
    'Confirm the applicable limits for your study.\n']);