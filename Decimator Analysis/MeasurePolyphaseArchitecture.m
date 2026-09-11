function Metrics = MeasurePolyphaseArchitecture(Decimator, Parameters)
%% =====================================================
%% MEASURE POLYPHASE DECIMATOR IMPLEMENTATION TRADEOFFS
%% =====================================================
%
% Coordinates the structural and computational measurements used to
% justify the polyphase decimator architecture.

    %% ==========================================
    %% POLYPHASE STRUCTURE
    %% ==========================================

    Metrics.Structure = ...
        MeasurePolyphaseStructure(Decimator);

    DecimationFactor = ...
        Metrics.Structure.DecimationFactor;

    ParameterDecimationFactor = ...
        double(Parameters.getValue("DcF"));

    if ParameterDecimationFactor ~= DecimationFactor
        error('MeasurePolyphaseArchitecture:ParameterMismatch', ...
            ['The decimator and parameter object must use the same ', ...
             'decimation factor.']);
    end

    %% ==========================================
    %% SAMPLE-RATE REDUCTION
    %% ==========================================

    InputSampleRate = ...
        double(Parameters.getValue("Fs_DSP"));

    Metrics.SampleRate.InputHz = InputSampleRate;
    Metrics.SampleRate.OutputHz = ...
        InputSampleRate / DecimationFactor;
    Metrics.SampleRate.ReductionFactor = ...
        DecimationFactor;
    Metrics.SampleRate.ReductionPercent = ...
        100 * (1 - 1 / DecimationFactor);

    %% ==========================================
    %% STORAGE REQUIREMENTS
    %% ==========================================

    Metrics.Storage.UniqueCoefficientCount = ...
        Metrics.Structure.FilterLength;

    Metrics.Storage.RectangularCoefficientSlots = ...
        Metrics.Structure.RectangularBranchSlots;

    Metrics.Storage.DelayLineStateSamples = ...
        Metrics.Structure.RectangularBranchSlots;

    Metrics.Storage.DirectFIRDelayStateSamples = ...
        max(Metrics.Structure.FilterLength - 1, 0);

    %% ==========================================
    %% COMPUTATIONAL REQUIREMENTS
    %% ==========================================

    Metrics.Computation = ...
        MeasurePolyphaseComputation( ...
            Metrics.Structure.FilterLength, ...
            DecimationFactor, ...
            Metrics.Structure.RectangularBranchSlots);

    %% ==========================================
    %% COMMAND-WINDOW REPORT
    %% ==========================================

    fprintf('\nPOLYPHASE DECIMATOR ARCHITECTURE CHARACTERIZATION\n');

    fprintf('Input / output sample rate      = %.6g / %.6g Hz\n', ...
        Metrics.SampleRate.InputHz, ...
        Metrics.SampleRate.OutputHz);

    fprintf('Filter length                   = %d taps\n', ...
        Metrics.Structure.FilterLength);

    fprintf('Decimation factor / branches    = %d / %d\n', ...
        DecimationFactor, ...
        Metrics.Structure.NumberBranches);

    fprintf('Branch tap counts               = %s\n', ...
        mat2str(Metrics.Structure.BranchTapCounts));

    fprintf('Rectangular branch storage      = %d slots (%d padded)\n', ...
        Metrics.Structure.RectangularBranchSlots, ...
        Metrics.Structure.PaddingSlots);

    fprintf('Direct FIR MACs/input           = %.3f\n', ...
        Metrics.Computation.DirectMACsPerInputSample);

    fprintf('Ideal polyphase MACs/input      = %.3f\n', ...
        Metrics.Computation.IdealPolyphaseMACsPerInputSample);

    fprintf('Implemented polyphase MACs/input= %.3f\n', ...
        Metrics.Computation.ImplementedMACsPerInputSample);

    fprintf('Implemented MAC reduction       = %.3f %%\n\n', ...
        Metrics.Computation.ImplementedMACReductionPercent);
end
