# MATLAB Simulation & Figure Generation Files

| Script | Description | Key Outputs |
| :--- | :--- | :--- |
| `system_level_model.m` | Programmatically builds the 70 MW, 11 kV, 10-feeder Simulink active-power signal-flow model (`BioInspiredMicrogrid_SystemLevel_Template.slx`). | `.slx` Simulink model |
| `model_parameter.m` | Reads solver configuration from the Simulink model and generates a parameter summary table. | `Fig_3_Model_Parameter_Settings.png` |
| `hours_source.m` | Plots 24-hour PV, wind, load, and optional BESS SOC profiles from `microgrid_logs.csv` (or an illustrative preview). | `Fig_4_24Hour_Source_Load_Profiles.png` |
| `bus_voltage.m` | Plots per-unit or kV bus voltage profiles against ±5% screening limits and computes min/max/RMS statistics. | `Fig_5_Bus_Voltage_Profile.png` |
| `biogrid.m` | Computes analytical feeder, transformer, and converter losses vs. a conventional urban grid and creates empty CSV log templates. | `Fig_1_Component_Losses.png`, `Fig_2_Total_Losses.png`, CSV templates |
