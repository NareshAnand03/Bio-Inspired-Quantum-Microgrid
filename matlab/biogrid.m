%% BIO-INSPIRED MICROGRID - FIGURE GENERATOR
% Project: AC Bio-Inspired Microgrid Architecture
% 70 MW reference load, 10 feeders, 11 kV, 50 Hz
%
% IMPORTANT:
% Analytical figures are calculated from the paper's assumptions.
% Simulation figures require real data exported from MATLAB/Simulink.
% This script does not invent simulation results.

clear;
clc;
close all;

%% 1. CREATE OUTPUT FOLDER

OUT = fullfile(pwd, 'microgrid_figures');

if ~exist(OUT, 'dir')
    mkdir(OUT);
end

fprintf('\nBio-Inspired Microgrid Figure Generator\n');
fprintf('=======================================\n');

%% 2. ANALYTICAL LOSS CALCULATION
% These are screening estimates, NOT simulation results.

Pload_MW = 70;
N = 10;
VLL = 11000;
R_per_km = 0.2;

L_urban = 8;
L_bio = 3;

PF_urban = 0.92;
PF_bio = 0.98;

P_feeder_W = (Pload_MW/N)*1e6;

I_urban = P_feeder_W/(sqrt(3)*VLL*PF_urban);
I_bio = P_feeder_W/(sqrt(3)*VLL*PF_bio);

R_urban = R_per_km*L_urban;
R_bio = R_per_km*L_bio;

Line_urban = N*3*I_urban^2*R_urban/1e6;
Line_bio = N*3*I_bio^2*R_bio/1e6;

% Transformer losses
etaTr_urban = 0.98*0.98;
etaTr_bio = 0.985;

Transformer_urban = Pload_MW*(1-etaTr_urban);
Transformer_bio = Pload_MW*(1-etaTr_bio);

% Converter losses: assumed 60% renewable share
Prenewable = 0.60*Pload_MW;

etaConv_urban = 0.96*0.96;
etaConv_bio = 0.98;

Converter_urban = Prenewable*(1-etaConv_urban);
Converter_bio = Prenewable*(1-etaConv_bio);

% Total losses
Total_urban = Line_urban + Transformer_urban ...
    + Converter_urban;

Total_bio = Line_bio + Transformer_bio ...
    + Converter_bio;

Percent_urban = 100*Total_urban/Pload_MW;
Percent_bio = 100*Total_bio/Pload_MW;

Reduction = 100*(Total_urban-Total_bio)/Total_urban;

fprintf('\nANALYTICAL ESTIMATES - NOT SIMULATION OUTPUTS\n');
fprintf('Urban feeder current: %.2f A\n', I_urban);
fprintf('Bio-inspired feeder current: %.2f A\n', I_bio);

fprintf('\nUrban line losses: %.3f MW\n', Line_urban);
fprintf('Bio-inspired line losses: %.3f MW\n', Line_bio);

fprintf('Urban transformer losses: %.3f MW\n', ...
    Transformer_urban);
fprintf('Bio-inspired transformer losses: %.3f MW\n', ...
    Transformer_bio);

fprintf('Urban converter losses: %.3f MW\n', Converter_urban);
fprintf('Bio-inspired converter losses: %.3f MW\n', Converter_bio);

fprintf('\nUrban total losses: %.3f MW (%.2f%%)\n', ...
    Total_urban, Percent_urban);

fprintf('Bio total losses: %.3f MW (%.2f%%)\n', ...
    Total_bio, Percent_bio);

fprintf('Estimated relative reduction: %.2f%%\n', Reduction);

%% 3. FIGURE 1 - COMPONENT-WISE LOSS COMPARISON

figure('Color','w');

LossComponents = [
    Line_urban Transformer_urban Converter_urban
    Line_bio   Transformer_bio   Converter_bio
];

bar(LossComponents);

set(gca, 'XTickLabel', ...
    {'Conventional Urban Grid','Bio-Inspired Microgrid'});

ylabel('Estimated Loss (MW)');
title('Analytical Component-Wise Loss Comparison');

legend({'Feeder I^2R Loss', ...
    'Transformer Loss','Converter Loss'}, ...
    'Location','northwest');

grid on;
saveas(gcf, fullfile(OUT, ...
    'Fig_1_Component_Losses.png'));

%% 4. FIGURE 2 - TOTAL LOSS COMPARISON

figure('Color','w');

bar([Total_urban Total_bio]);

set(gca, 'XTickLabel', ...
    {'Conventional Urban Grid','Bio-Inspired Microgrid'});

ylabel('Estimated Total Loss (MW)');

title(sprintf('Analytical Loss Comparison - %.2f%% Reduction', ...
    Reduction));

grid on;

text(1, Total_urban, sprintf(' %.3f MW',Total_urban), ...
    'VerticalAlignment','bottom', ...
    'HorizontalAlignment','center');

text(2, Total_bio, sprintf(' %.3f MW',Total_bio), ...
    'VerticalAlignment','bottom', ...
    'HorizontalAlignment','center');

saveas(gcf, fullfile(OUT, ...
    'Fig_2_Total_Losses.png'));

%% 5. CREATE CSV TEMPLATES
% Replace template data with data exported from your actual model.
% Do not enter made-up values.

createTemplate('microgrid_logs.csv', ...
['Time_s,PV_MW,Wind_MW,Load_MW,GridP_MW,BESS_P_MW,' ...
 'BESS_SOC_pct,PlineLoss_MW,PtransformerLoss_MW,' ...
 'PconverterLoss_MW,Pcurtailment_MW,Qload_Mvar,' ...
 'Qgrid_Mvar,Vbus1_pu,Vbus2_pu,Vbus3_pu,Vbus4_pu,' ...
 'Vbus5_pu,Vbus6_pu,Vbus7_pu,Vbus8_pu,Vbus9_pu,' ...
 'Vbus10_pu,Frequency_Hz']);

createTemplate('microgrid_emt_logs.csv', ...
    'Time_s,Va_V,Vb_V,Vc_V,Ia_A,Ib_A,Ic_A');

createTemplate('microgrid_fault_logs.csv', ...
['Time_s,FaultFlag,BreakerMainClosed,TieSwitchClosed,' ...
 'CriticalLoad_MW,Frequency_Hz,Vbus1_pu,Vbus2_pu']);

%% 6. FIGURE 3 - 24-HOUR GENERATION AND LOAD
% Required CSV columns:
% Time_s, PV_MW, Wind_MW, Load_MW

file = fullfile(pwd,'microgrid_logs.csv');

if isfile(file)

    T = readtable(file);

    if height(T)>1 && ...
        all(ismember({'Time_s','PV_MW','Wind_MW','Load_MW'}, ...
        T.Properties.VariableNames))

        t = T.Time_s/3600;

        figure('Color','w');
        hold on;

        plot(t,T.PV_MW,'LineWidth',1.5);
        plot(t,T.Wind_MW,'LineWidth',1.5);
        plot(t,T.Load_MW,'LineWidth',1.5);

        xlabel('Time (hours)');
        ylabel('Power (MW)');

        title('24-Hour Renewable Generation and Load');

        legend('Solar PV','Wind Generation','Load Demand', ...
            'Location','best');

        grid on;

        saveas(gcf,fullfile(OUT, ...
            'Fig_3_Generation_Load.png'));

    else
        fprintf('\nFigure 3 skipped: valid daily signals are missing.\n');
    end
end

%% 7. FIGURE 4 - BUS VOLTAGE PROFILES
% Required columns: Time_s and one or more VbusN_pu columns.
% Voltage limit lines shown here are illustrative screening limits.

if isfile(file)

    T = readtable(file);

    if height(T)>1 && ismember('Time_s',T.Properties.VariableNames)

        voltageColumns = T.Properties.VariableNames( ...
            startsWith(T.Properties.VariableNames,'Vbus') & ...
            endsWith(T.Properties.VariableNames,'_pu'));

        figure('Color','w');
        hold on;
        plotted = false;

        for k = 1:numel(voltageColumns)

            y = T.(voltageColumns{k});

            if isnumeric(y) && any(isfinite(y))
                plot(T.Time_s/3600,y,'LineWidth',1.1);
                plotted = true;
            end
        end

        if plotted

            yline(0.95,'k--','0.95 pu');
            yline(1.05,'k--','1.05 pu');

            xlabel('Time (hours)');
            ylabel('Voltage (pu)');

            title('Bus Voltage Profiles');
            grid on;

            saveas(gcf,fullfile(OUT, ...
                'Fig_4_Bus_Voltages.png'));

        else
            close(gcf);
            fprintf('Figure 4 skipped: no valid voltage data.\n');
        end
    end
end

%% 8. FIGURE 5 - THREE-PHASE INVERTER WAVEFORMS
% Requires actual short-duration EMT data.
% All voltages are in volts; currents are in amperes.

fileEMT = fullfile(pwd,'microgrid_emt_logs.csv');

if isfile(fileEMT)

    T = readtable(fileEMT);

    required = {'Time_s','Va_V','Vb_V','Vc_V', ...
        'Ia_A','Ib_A','Ic_A'};

    if height(T)>2 && all(ismember(required, ...
            T.Properties.VariableNames))

        t = T.Time_s;

        % Display approximately three cycles at 50 Hz.
        idx = t <= t(1) + 3/50;

        if nnz(idx)>2

            figure('Color','w');

            subplot(2,1,1);

            plot(t(idx),[T.Va_V(idx),T.Vb_V(idx), ...
                T.Vc_V(idx)],'LineWidth',1.1);

            ylabel('Voltage (V)');
            title('Three-Phase Inverter Voltages');
            legend('V_a','V_b','V_c');
            grid on;

            subplot(2,1,2);

            plot(t(idx),[T.Ia_A(idx),T.Ib_A(idx), ...
                T.Ic_A(idx)],'LineWidth',1.1);

            xlabel('Time (s)');
            ylabel('Current (A)');
            title('Three-Phase Inverter Currents');

            legend('I_a','I_b','I_c');
            grid on;

            saveas(gcf,fullfile(OUT, ...
                'Fig_5_Three_Phase_Waveforms.png'));

        else
            fprintf('Figure 5 skipped: insufficient EMT samples.\n');
        end

    else
        fprintf('Figure 5 skipped: required EMT columns missing.\n');
    end
end

%% 9. FIGURE 6 - FAULT AND RECOVERY RESPONSE
% Requires data exported from an actual fault simulation.

fileFault = fullfile(pwd,'microgrid_fault_logs.csv');

if isfile(fileFault)

    T = readtable(fileFault);

    required = {'Time_s','FaultFlag', ...
        'BreakerMainClosed','TieSwitchClosed', ...
        'CriticalLoad_MW','Frequency_Hz'};

    if height(T)>1 && all(ismember(required, ...
            T.Properties.VariableNames))

        figure('Color','w');

        subplot(3,1,1);

        stairs(T.Time_s,T.FaultFlag,'LineWidth',1.2);
        hold on;

        stairs(T.Time_s,T.BreakerMainClosed,'LineWidth',1.2);
        stairs(T.Time_s,T.TieSwitchClosed,'LineWidth',1.2);

        ylabel('State');
        title('Fault and Switch States');

        legend('Fault','Main Breaker Closed', ...
            'Tie Switch Closed');

        grid on;

        subplot(3,1,2);

        plot(T.Time_s,T.Frequency_Hz,'LineWidth',1.2);
        hold on;
        yline(50,'k--','50 Hz');

        ylabel('Frequency (Hz)');
        title('Frequency Response');
        grid on;

        subplot(3,1,3);

        plot(T.Time_s,T.CriticalLoad_MW,'LineWidth',1.2);

        xlabel('Time (s)');
        ylabel('Power (MW)');
        title('Critical Load Supplied');

        grid on;

        saveas(gcf,fullfile(OUT, ...
            'Fig_6_Fault_Recovery.png'));

    else
        fprintf('Figure 6 skipped: fault log data is incomplete.\n');
    end
end

%% 10. SAVE ANALYTICAL SUMMARY TABLE

Architecture = {'Conventional Urban';'Bio-Inspired'};

LineLoss_MW = [Line_urban;Line_bio];

TransformerLoss_MW = [Transformer_urban;Transformer_bio];

ConverterLoss_MW = [Converter_urban;Converter_bio];

TotalLoss_MW = [Total_urban;Total_bio];

Loss_Percent = [Percent_urban;Percent_bio];

Summary = table(Architecture,LineLoss_MW, ...
    TransformerLoss_MW,ConverterLoss_MW, ...
    TotalLoss_MW,Loss_Percent);

writetable(Summary,fullfile(OUT, ...
    'Analytical_Loss_Summary.csv'));

fprintf('\nFinished.\n');
fprintf('Figures and summary saved in:\n%s\n',OUT);
fprintf(['Remember: analytical plots are estimates; all ' ...
    'simulation plots require actual exported model data.\n']);

%% LOCAL FUNCTION TO CREATE EMPTY CSV TEMPLATES

function createTemplate(filename,header)

    if ~isfile(filename)

        fid = fopen(filename,'w');

        if fid == -1
            warning('Cannot create template file: %s',filename);
            return;
        end

        fprintf(fid,'%s\n',header);

        fclose(fid);

        fprintf('Created empty data template: %s\n',filename);
    end
end