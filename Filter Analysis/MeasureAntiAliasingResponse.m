function LPFMetrics = MeasureAntiAliasingResponse(SOS, Gain, Parameters)
%% =======================================================
%% MEASURE ANTI-ALIASING LOW-PASS FILTER RESPONSE
%% =======================================================
% Measures sampler-boundary protection, desired-tone preservation,
% narrowband-interference attenuation, unit-step transient response, and
% pole stability for the implemented SOS low-pass filter.


    %% ==========================================
    %% VALIDATE FILTER DESCRIPTION
    %% ==========================================

    ValidSOS = ...
        isnumeric(SOS) && ...
        isreal(SOS) && ...
        ismatrix(SOS) && ...
        ~isempty(SOS) && ...
        size(SOS, 2) == 6 && ...
        all(isfinite(SOS(:)));

    if ~ValidSOS
        error('MeasureAntiAliasingResponse:InvalidSOS', ...
            'SOS must be a nonempty, finite, real matrix with six columns.');
    end

    validateattributes(Gain, {'numeric'}, ...
        {'scalar', 'real', 'finite'}, mfilename, 'Gain');


    %% ==========================================
    %% RETRIEVE APPROVED LPF REQUIREMENTS
    %% ==========================================

    Fs = Parameters.getValue("Fs");
    DownsamplingFactor = Parameters.getValue("DF");

    Fstop = Parameters.getValue("FstopLPF");
    DesiredFrequencies = [ ...
        Parameters.getValue("FData"); ...
        Parameters.getValue("FData2")];
    InterferenceFrequency = Parameters.getValue("Fnoise");

    MaximumDesiredToneLoss_dB = ...
        Parameters.getValue("MaxDesiredToneLossLPF");
    RequiredInterferenceAttenuation_dB = ...
        Parameters.getValue("MinInterferenceAttenuationLPF");
    RequiredSettlingTime_s = ...
        Parameters.getValue("MaxSettlingTimeLPF");
    SettlingTolerance = ...
        Parameters.getValue("SettlingToleranceLPF");
    MaximumStepOvershoot = ...
        Parameters.getValue("MaxStepOvershootLPF");

    validateattributes(Fs, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(DownsamplingFactor, {'numeric'}, ...
        {'scalar', 'integer', 'finite', 'positive'});
    validateattributes(Fstop, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive', '<', Fs/2});
    validateattributes(DesiredFrequencies, {'numeric'}, ...
        {'vector', 'real', 'finite', 'positive', '<', Fs/2});
    validateattributes(InterferenceFrequency, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive', '<', Fs/2});
    validateattributes(MaximumDesiredToneLoss_dB, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(RequiredInterferenceAttenuation_dB, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(RequiredSettlingTime_s, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(SettlingTolerance, {'numeric'}, ...
        {'scalar', 'real', 'finite', '>', 0, '<', 1});
    validateattributes(MaximumStepOvershoot, {'numeric'}, ...
        {'scalar', 'real', 'finite', '>=', 0, '<', 1});


    %% ==========================================
    %% VERIFY SAMPLER ALIAS-BOUNDARY PROTECTION
    %% ==========================================

    ADCSamplingFrequency = Fs / DownsamplingFactor;
    ProtectedNyquistFrequency = ADCSamplingFrequency / 2;
    AliasBoundaryMarginHz = ProtectedNyquistFrequency - Fstop;

    FrequencyToleranceHz = ...
        100 * eps(max(ProtectedNyquistFrequency, Fstop));

    AliasBoundaryOK = ...
        Fstop <= ProtectedNyquistFrequency + FrequencyToleranceHz;


    %% ==========================================
    %% DESIRED-TONE AND INTERFERENCE RESPONSE
    %% ==========================================

    EvaluationFrequencies = [ ...
        DesiredFrequencies; ...
        InterferenceFrequency];

    [EvaluationResponse, ~] = ...
        freqz(SOS, EvaluationFrequencies, Fs);

    EvaluationResponse = Gain .* EvaluationResponse;
    EvaluationAttenuation_dB = ...
        -20 * log10(max(abs(EvaluationResponse), realmin("double")));

    DesiredToneLoss_dB = EvaluationAttenuation_dB(1:2);
    InterferenceAttenuation_dB = EvaluationAttenuation_dB(3);

    DifferentialToneLoss_dB = ...
        abs(DesiredToneLoss_dB(1) - DesiredToneLoss_dB(2));

    DesiredToneLossOK = ...
        all(DesiredToneLoss_dB <= MaximumDesiredToneLoss_dB);

    InterferenceAttenuationOK = ...
        InterferenceAttenuation_dB >= ...
        RequiredInterferenceAttenuation_dB;


    %% ==========================================
    %% MEASURE NORMALIZED UNIT-STEP RESPONSE
    %% ==========================================
    % Analyze ten times the required settling interval so a failure to
    % meet the requirement does not immediately truncate the response.

    StepRecordLength = ...
        max(ceil(10 * RequiredSettlingTime_s * Fs) + 1, 2);

    UnitStep = ones(StepRecordLength, 1);
    StepResponse = sosfilt(SOS, Gain * UnitStep);
    StepTime_s = (0:StepRecordLength-1)' / Fs;

    % Evaluate the cascade DC gain directly from the SOS coefficients.
    % This avoids the scalar-input ambiguity of freqz, where a value of
    % zero may be interpreted as a requested FFT length instead of 0 Hz.
    SectionDCNumerators = sum(SOS(:, 1:3), 2);
    SectionDCDenominators = sum(SOS(:, 4:6), 2);

    if any(abs(SectionDCDenominators) <= realmin("double"))
        error('MeasureAntiAliasingResponse:UndefinedDCGain', ...
            'The implemented LPF must have a finite DC response.');
    end

    FinalStepValue = real( ...
        Gain * prod(SectionDCNumerators ./ SectionDCDenominators));

    if abs(FinalStepValue) <= realmin("double")
        error('MeasureAntiAliasingResponse:ZeroDCGain', ...
            'The implemented LPF must have nonzero DC gain.');
    end

    NormalizedStepResponse = StepResponse / FinalStepValue;

    LastOutsideTolerance = find( ...
        abs(NormalizedStepResponse - 1) > SettlingTolerance, ...
        1, ...
        "last");

    if isempty(LastOutsideTolerance)
        SettlingSamples = 0;
        SettlingTime_s = 0;
    elseif LastOutsideTolerance == StepRecordLength
        SettlingSamples = Inf;
        SettlingTime_s = Inf;
    else
        SettlingSamples = LastOutsideTolerance;
        SettlingTime_s = SettlingSamples / Fs;
    end

    StepOvershoot = ...
        max(0, max(NormalizedStepResponse) - 1);

    SettlingTimeOK = ...
        SettlingTime_s <= RequiredSettlingTime_s;
    StepOvershootOK = ...
        StepOvershoot <= MaximumStepOvershoot;


    %% ==========================================
    %% MEASURE IMPLEMENTED POLE STABILITY
    %% ==========================================

    Poles = zeros(0, 1);

    for SectionIndex = 1:size(SOS, 1)
        Denominator = double(SOS(SectionIndex, 4:6));

        if Denominator(1) == 0
            error('MeasureAntiAliasingResponse:InvalidDenominator', ...
                'Every SOS denominator must have a nonzero leading term.');
        end

        Poles = [Poles; roots(Denominator)]; %#ok<AGROW>
    end

    MaximumPoleRadius = max(abs(Poles));
    StabilityOK = MaximumPoleRadius < 1;


    %% ==========================================
    %% STORE LPF PERFORMANCE MEASUREMENTS
    %% ==========================================

    LPFMetrics.DownsamplingFactor = DownsamplingFactor;
    LPFMetrics.ADCSamplingFrequency_Hz = ADCSamplingFrequency;
    LPFMetrics.ProtectedNyquistFrequency_Hz = ...
        ProtectedNyquistFrequency;
    LPFMetrics.StopbandEdge_Hz = Fstop;
    LPFMetrics.AliasBoundaryMargin_Hz = AliasBoundaryMarginHz;
    LPFMetrics.AliasBoundaryOK = AliasBoundaryOK;

    LPFMetrics.DesiredFrequencies_Hz = DesiredFrequencies;
    LPFMetrics.DesiredToneLoss_dB = DesiredToneLoss_dB;
    LPFMetrics.DifferentialToneLoss_dB = DifferentialToneLoss_dB;
    LPFMetrics.MaximumDesiredToneLoss_dB = ...
        MaximumDesiredToneLoss_dB;
    LPFMetrics.DesiredToneLossOK = DesiredToneLossOK;

    LPFMetrics.InterferenceFrequency_Hz = InterferenceFrequency;
    LPFMetrics.InterferenceAttenuation_dB = ...
        InterferenceAttenuation_dB;
    LPFMetrics.RequiredInterferenceAttenuation_dB = ...
        RequiredInterferenceAttenuation_dB;
    LPFMetrics.InterferenceAttenuationOK = ...
        InterferenceAttenuationOK;

    LPFMetrics.SettlingSamples = SettlingSamples;
    LPFMetrics.SettlingTime_s = SettlingTime_s;
    LPFMetrics.RequiredSettlingTime_s = RequiredSettlingTime_s;
    LPFMetrics.SettlingTolerance = SettlingTolerance;
    LPFMetrics.SettlingTimeOK = SettlingTimeOK;
    LPFMetrics.StepOvershoot = StepOvershoot;
    LPFMetrics.MaximumStepOvershoot = MaximumStepOvershoot;
    LPFMetrics.StepOvershootOK = StepOvershootOK;
    LPFMetrics.FinalStepValue = FinalStepValue;
    LPFMetrics.StepTime_s = StepTime_s;
    LPFMetrics.StepResponse = StepResponse;
    LPFMetrics.NormalizedStepResponse = NormalizedStepResponse;

    LPFMetrics.Poles = Poles;
    LPFMetrics.MaximumPoleRadius = MaximumPoleRadius;
    LPFMetrics.StabilityOK = StabilityOK;

    LPFMetrics.OverallOK = ...
        AliasBoundaryOK && ...
        DesiredToneLossOK && ...
        InterferenceAttenuationOK && ...
        SettlingTimeOK && ...
        StepOvershootOK && ...
        StabilityOK;
end
