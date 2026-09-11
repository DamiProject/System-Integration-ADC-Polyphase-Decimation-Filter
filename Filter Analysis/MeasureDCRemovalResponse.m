function HPFMetrics = MeasureDCRemovalResponse( ...
        InputSignal, OutputSignal, SOS, Gain, Parameters)
%% =======================================================
%% MEASURE DC-REMOVAL HIGH-PASS FILTER RESPONSE
%% =======================================================
% Measures received-waveform DC rejection, unit-step settling time, and
% pole stability for the implemented SOS high-pass filter.
%
% Inputs:
%   InputSignal  - Complete received signal before HPF processing
%   OutputSignal - Complete signal after frame-based HPF processing
%   SOS          - Implemented high-pass second-order sections
%   Gain         - Overall scalar SOS cascade gain
%   Parameters   - ADCParameters containing Fs and HPF requirements
%
% Output:
%   HPFMetrics   - Structure containing measured results and requirements


    %% ==========================================
    %% VALIDATE SIGNALS AND FILTER DESCRIPTION
    %% ==========================================

    ValidInput = ...
        isnumeric(InputSignal) && ...
        isreal(InputSignal) && ...
        isvector(InputSignal) && ...
        ~isempty(InputSignal) && ...
        all(isfinite(InputSignal(:)));

    ValidOutput = ...
        isnumeric(OutputSignal) && ...
        isreal(OutputSignal) && ...
        isvector(OutputSignal) && ...
        ~isempty(OutputSignal) && ...
        all(isfinite(OutputSignal(:)));

    if ~ValidInput || ~ValidOutput
        error('MeasureDCRemovalResponse:InvalidSignal', ...
            ['InputSignal and OutputSignal must be nonempty, finite, ', ...
             'real-valued numeric vectors.']);
    end

    InputSignal = double(InputSignal(:));
    OutputSignal = double(OutputSignal(:));

    if numel(InputSignal) ~= numel(OutputSignal)
        error('MeasureDCRemovalResponse:SignalLengthMismatch', ...
            'InputSignal and OutputSignal must have equal lengths.');
    end

    ValidSOS = ...
        isnumeric(SOS) && ...
        isreal(SOS) && ...
        ismatrix(SOS) && ...
        ~isempty(SOS) && ...
        size(SOS, 2) == 6 && ...
        all(isfinite(SOS(:)));

    if ~ValidSOS
        error('MeasureDCRemovalResponse:InvalidSOS', ...
            'SOS must be a nonempty, finite, real matrix with six columns.');
    end

    validateattributes(Gain, {'numeric'}, ...
        {'scalar', 'real', 'finite'}, mfilename, 'Gain');


    %% ==========================================
    %% RETRIEVE APPROVED HPF REQUIREMENTS
    %% ==========================================

    Fs = Parameters.getValue("Fs");
    RequiredDCRejection_dB = ...
        Parameters.getValue("DCRejectionHPF");
    RequiredSettlingTime_s = ...
        Parameters.getValue("MaxSettlingTimeHPF");
    SettlingTolerance = ...
        Parameters.getValue("SettlingToleranceHPF");

    validateattributes(Fs, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(RequiredDCRejection_dB, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(RequiredSettlingTime_s, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(SettlingTolerance, {'numeric'}, ...
        {'scalar', 'real', 'finite', '>', 0, '<', 1});


    %% ==========================================
    %% MEASURE NORMALIZED DC-STEP SETTLING TIME
    %% ==========================================
    % Analyze ten times the required settling interval so a failure to
    % meet the requirement does not immediately truncate the response.

    StepRecordLength = ...
        max(ceil(10 * RequiredSettlingTime_s * Fs) + 1, 2);

    UnitDCStep = ones(StepRecordLength, 1);
    StepResponse = sosfilt(SOS, Gain * UnitDCStep);
    StepTime_s = (0:StepRecordLength-1)' / Fs;

    LastOutsideTolerance = ...
        find(abs(StepResponse) > SettlingTolerance, 1, "last");

    if isempty(LastOutsideTolerance)
        SettlingSamples = 0;
        SettlingTime_s = 0;
    elseif LastOutsideTolerance == StepRecordLength
        SettlingSamples = Inf;
        SettlingTime_s = Inf;
    else
        % LastOutsideTolerance is also the number of elapsed sample
        % intervals before the response remains inside the tolerance band.
        SettlingSamples = LastOutsideTolerance;
        SettlingTime_s = SettlingSamples / Fs;
    end

    SettlingTimeOK = ...
        SettlingTime_s <= RequiredSettlingTime_s;


    %% ==========================================
    %% MEASURE RECEIVED-WAVEFORM DC REJECTION
    %% ==========================================
    % Exclude the approved settling interval from both signal means so the
    % HPF startup transient is not mistaken for steady-state residual DC.

    NumberSamples = numel(InputSignal);
    MeasurementStartSample = ...
        min(ceil(RequiredSettlingTime_s * Fs) + 1, NumberSamples);

    MeasurementIndices = MeasurementStartSample:NumberSamples;

    InputDC_V = mean(InputSignal(MeasurementIndices));
    OutputDC_V = mean(OutputSignal(MeasurementIndices));

    if abs(InputDC_V) > 0
        DCRejection_dB = 20 * log10( ...
            abs(InputDC_V) / ...
            max(abs(OutputDC_V), realmin("double")));
    else
        DCRejection_dB = NaN;
    end

    MaximumResidualDC_V = ...
        abs(InputDC_V) * 10^(-RequiredDCRejection_dB / 20);

    DCRejectionOK = ...
        isfinite(DCRejection_dB) && ...
        DCRejection_dB >= RequiredDCRejection_dB;

    ResidualDCOK = ...
        abs(OutputDC_V) <= MaximumResidualDC_V;


    %% ==========================================
    %% MEASURE IMPLEMENTED POLE STABILITY
    %% ==========================================

    Poles = zeros(0, 1);

    for SectionIndex = 1:size(SOS, 1)
        Denominator = double(SOS(SectionIndex, 4:6));

        if Denominator(1) == 0
            error('MeasureDCRemovalResponse:InvalidDenominator', ...
                'Every SOS denominator must have a nonzero leading term.');
        end

        Poles = [Poles; roots(Denominator)]; %#ok<AGROW>
    end

    MaximumPoleRadius = max(abs(Poles));
    StabilityOK = MaximumPoleRadius < 1;


    %% ==========================================
    %% STORE HPF PERFORMANCE MEASUREMENTS
    %% ==========================================

    HPFMetrics.InputDC_V = InputDC_V;
    HPFMetrics.OutputDC_V = OutputDC_V;
    HPFMetrics.ResidualDCMagnitude_V = abs(OutputDC_V);
    HPFMetrics.MaximumResidualDC_V = MaximumResidualDC_V;
    HPFMetrics.DCRejection_dB = DCRejection_dB;
    HPFMetrics.RequiredDCRejection_dB = RequiredDCRejection_dB;
    HPFMetrics.DCRejectionOK = DCRejectionOK;
    HPFMetrics.ResidualDCOK = ResidualDCOK;

    HPFMetrics.SettlingSamples = SettlingSamples;
    HPFMetrics.SettlingTime_s = SettlingTime_s;
    HPFMetrics.RequiredSettlingTime_s = RequiredSettlingTime_s;
    HPFMetrics.SettlingTolerance = SettlingTolerance;
    HPFMetrics.SettlingTimeOK = SettlingTimeOK;
    HPFMetrics.StepTime_s = StepTime_s;
    HPFMetrics.StepResponse = StepResponse;

    HPFMetrics.Poles = Poles;
    HPFMetrics.MaximumPoleRadius = MaximumPoleRadius;
    HPFMetrics.StabilityOK = StabilityOK;

    HPFMetrics.MeasurementStartSample = MeasurementStartSample;
    HPFMetrics.OverallOK = ...
        DCRejectionOK && ...
        ResidualDCOK && ...
        SettlingTimeOK && ...
        StabilityOK;
end
