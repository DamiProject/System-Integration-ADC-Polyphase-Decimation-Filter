%% Runs ADC-Polyphase System Integration Tests

clear;
clc;

%% ==========================================
%% PROJECT ROOT
%% ==========================================

ProjectRoot = fileparts(mfilename("fullpath"));

% Ensure integration-owned helper/configuration files are visible even if
% this script is launched from another MATLAB working directory.
addpath(ProjectRoot);

%% ==========================================
%% SETUP PROJECT PATHS
%% ==========================================

SetupPaths();

%% ==========================================
%% RUN SYSTEM TESTS
%% ==========================================

TestRoot = fullfile(ProjectRoot, "Tests");

if ~isfolder(TestRoot)
    error( ...
        'ADCPolyphaseSystemIntegration:TestsNotFound', ...
        'The system Tests folder could not be located.');
end

Results = runtests( ...
    TestRoot, ...
    "IncludeSubfolders", true);

disp(Results);

%% ==========================================
%% VERIFY TEST RESULTS
%% ==========================================

assertSuccess(Results);
