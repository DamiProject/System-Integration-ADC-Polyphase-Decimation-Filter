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

%% ==========================================
%% CREATE TEST SUITE
%% ==========================================

TestSuite = testsuite( ...
    TestRoot, ...
    "IncludeSubfolders", true);

%% ==========================================
%% CONFIGURE TEST RUNNER
%% ==========================================

Runner = matlab.unittest.TestRunner.withDefaultPlugins;

%% ==========================================
%% CI TEST REPORTING
%% ==========================================

if strcmpi(getenv("GITHUB_ACTIONS"), "true")

    ReportRoot = fullfile( ...
        projectRoot, ...
        "test-results");

    if ~isfolder(ReportRoot)
        mkdir(ReportRoot);
    end

    %% JUnit XML report
    import matlab.unittest.plugins.XMLPlugin

    XMLReport = fullfile( ...
        ReportRoot, ...
        "system-test-results.xml");

    Runner.addPlugin( ...
        XMLPlugin.producingJUnitFormat(XMLReport));

    %% HTML report
    import matlab.unittest.plugins.TestReportPlugin

    HTMLReport = fullfile( ...
        ReportRoot, ...
        "system-test-report.html");

    Runner.addPlugin( ...
        TestReportPlugin.producingHTML( ...
            HTMLReport, ...
            "Title", ...
            "ADC-Polyphase System Verification Report"));
end

%% ==========================================
%% RUN TESTS
%% ==========================================

results = Runner.run(TestSuite);

disp(results);

%% ==========================================
%% VERIFY TEST RESULTS
%% ==========================================

assertSuccess(results);