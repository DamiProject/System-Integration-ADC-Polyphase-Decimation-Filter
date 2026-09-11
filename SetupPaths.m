function SetupPaths()
%% ==========================================
%% SETUP PATHS FOR ADC-POLYPHASE SYSTEM INTEGRATION
%% ==========================================

    %% ==========================================
    %% SYSTEM INTEGRATION ROOT
    %% ==========================================

    IntegrationRoot = fileparts(mfilename("fullpath"));

    % Make the integration-owned files (for example EndToEndTestConfig.m)
    % available regardless of the caller's current working directory.
    addpath(IntegrationRoot);

    %% ==========================================
    %% DEMONSTRATION STAGES
    %% ==========================================

    DemoStages = fullfile(IntegrationRoot, "Demo Stages");

    if isfolder(DemoStages)
        addpath(DemoStages);
    end

    %% ==========================================
    %% DSP DOWNSTREAM ROOT
    %% ==========================================

    DSPDownstreamRoot = fileparts(IntegrationRoot);

    %% ==========================================
    %% LOCAL DEVELOPMENT PATHS
    %% ==========================================

    LocalADCDesign = fullfile( ...
        DSPDownstreamRoot, ...
        "ADC Signal Chain", ...
        "Design");

    LocalPolyphaseDesign = fullfile( ...
        DSPDownstreamRoot, ...
        "Polyphase Decimator DSP", ...
        "Design");

    %% ==========================================
    %% GITHUB ACTIONS DEPENDENCY PATHS
    %% ==========================================

    CIADCDesign = fullfile( ...
        IntegrationRoot, ...
        "dependencies", ...
        "adc", ...
        "Design");

    CIPolyphaseDesign = fullfile( ...
        IntegrationRoot, ...
        "dependencies", ...
        "polyphase", ...
        "Design");

    %% ==========================================
    %% SELECT AVAILABLE ENVIRONMENT
    %% ==========================================

    if isfolder(LocalADCDesign) && ...
            isfolder(LocalPolyphaseDesign)

        ADCDesign = LocalADCDesign;
        PolyphaseDesign = LocalPolyphaseDesign;

        fprintf( ...
            "Using local ADC Signal Chain and " + ...
            "Polyphase Decimator DSP repositories.\n");

    elseif isfolder(CIADCDesign) && ...
            isfolder(CIPolyphaseDesign)

        ADCDesign = CIADCDesign;
        PolyphaseDesign = CIPolyphaseDesign;

        fprintf( ...
            "Using GitHub Actions dependency repositories.\n");

    else

        error( ...
            'ADCPolyphaseSystemIntegration:DependenciesNotFound', ...
            ['Could not locate the ADC Signal Chain and ', ...
             'Polyphase Decimator DSP Design folders.']);
    end

    %% ==========================================
    %% VERIFY REQUIRED DEPENDENCY ENTRY POINTS
    %% ==========================================

    RequiredADCFile = fullfile(ADCDesign, "ADCParameters.m");
    RequiredDSPFile = fullfile(PolyphaseDesign, "DSPParameters.m");

    if ~isfile(RequiredADCFile)
        error( ...
            'ADCPolyphaseSystemIntegration:ADCDependencyInvalid', ...
            'ADCParameters.m was not found in the ADC Design folder.');
    end

    if ~isfile(RequiredDSPFile)
        error( ...
            'ADCPolyphaseSystemIntegration:DSPDependencyInvalid', ...
            'DSPParameters.m was not found in the Polyphase Design folder.');
    end

    %% ==========================================
    %% ADD DEPENDENCY DESIGN PATHS
    %% ==========================================

    addpath(genpath(ADCDesign));
    addpath(genpath(PolyphaseDesign));

    %% ==========================================
    %% ADD SYSTEM ANALYSIS PATHS
    %% ==========================================

    AnalysisFolders = [ ...
        "ADC Analysis", ...
        "AGC Analysis", ...
        "Decimator Analysis", ...
        "Filter Analysis", ...
        "Spectrum Analysis"];

    for k = 1:numel(AnalysisFolders)
        AnalysisPath = fullfile( ...
            IntegrationRoot, AnalysisFolders(k));

        if isfolder(AnalysisPath)
            addpath(AnalysisPath);
        end
    end

    %% ==========================================
    %% OPTIONAL INTEGRATION DESIGN FOLDER
    %% ==========================================

    IntegrationDesign = fullfile(IntegrationRoot, "Design");

    if isfolder(IntegrationDesign)
        addpath(genpath(IntegrationDesign));
    end
end
