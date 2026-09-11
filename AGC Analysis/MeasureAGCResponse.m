function AGCMetrics = MeasureAGCResponse(History, Parameters)
%% ======================================================
%% MEASURE AUTOMATIC GAIN CONTROL PERFORMANCE RESPONSE
%% ======================================================
% Measures the dynamic and steady-state regulation performance of the AGC
% using the historical signals returned by AGC.GainControl().
%
% The noise gate itself is intentionally not characterized here. Noise-gate
% performance is handled separately by MeasureNoiseGateResponse().
%
% Inputs:
%   History    - AGC history structure returned by GainControl()
%   Parameters - ADC parameter object containing Fs, the noise-gate
%                threshold configuration, and Vfs
%
% Output:
%   AGCMetrics - Structure containing AGC performance measurements


    %% ==========================================
    %% VALIDATE REQUIRED AGC HISTORY INFORMATION
    %% ==========================================

    RequiredFields = ["Gain", "Envelope", "ProjectedEnvelope"];

    for k = 1:numel(RequiredFields)

        if ~isfield(History, RequiredFields(k))
            error("MeasureAGCResponse:MissingHistoryField", ...
                "History.%s is required.", RequiredFields(k));
        end
    end


    %% ===========================
    %% FORCE COLUMN-VECTOR FORMAT
    %% ===========================

    Gain = History.Gain(:);
    Envelope = History.Envelope(:);
    ProjectedEnvelope = History.ProjectedEnvelope(:);

    N = numel(Gain);

    if numel(Envelope) ~= N || numel(ProjectedEnvelope) ~= N
        error("MeasureAGCResponse:HistoryLengthMismatch", ...
            "AGC history vectors must have equal lengths.");
    end


    %% ================================
    %% HANDLE AN EMPTY HISTORY CLEANLY
    %% ================================

    if N == 0

        AGCMetrics = struct( ...
            "UpperAGCLimit", NaN, ...
            "LowerAGCLimit", NaN, ...
            "NoiseThreshold", NaN, ...
            "ActiveSampleCount", 0, ...
            "TargetWindowSampleCount", 0, ...
            "TargetWindowOccupancyPercentage", NaN, ...
            "MaximumOvershoot", NaN, ...
            "MaximumUndershoot", NaN, ...
            "MinimumGainObserved", NaN, ...
            "MaximumGainObserved", NaN, ...
            "AttackTimes", zeros(0,1), ...
            "MeanAttackTime", NaN, ...
            "MaximumAttackTime", NaN, ...
            "ReleaseTimes", zeros(0,1), ...
            "MeanReleaseTime", NaN, ...
            "MaximumReleaseTime", NaN);

        return
    end


    %% ==========================================
    %% DERIVE AGC OPERATING LIMITS AND THRESHOLD
    %% ==========================================

    Fs = Parameters.getValue("Fs");

    % Use the same configured threshold and legacy fallback as
    % AGC.GainControl().
    NoiseThreshold = Parameters.getValue("NoiseGateThreshold");

    if isnan(NoiseThreshold)
        Anf = Parameters.getValue("Anf");
        NoiseThreshold = abs(Anf) * 2;
    end

    % Quantizer full-scale amplitude
    Vfs = Parameters.getValue("Vfs");

    % Quantizer peak voltage
    QuantizerPeak = abs(Vfs) / 2;

    % Same AGC output-envelope operating window used by AGC.GainControl()
    UpperAGCLimit = 0.75 * QuantizerPeak;
    LowerAGCLimit = 0.30 * QuantizerPeak;


    %% ==========================================
    %% IDENTIFY ACTIVE-SIGNAL REGULATION SAMPLES
    %% ==========================================

    % AGC gain regulation is active only above the noise threshold.
    ActiveMask = Envelope > NoiseThreshold;

    ActiveSampleCount = sum(ActiveMask);

    % Samples whose projected AGC output envelope lies inside the desired
    % regulation window while the signal is active.
    TargetWindowMask = ...
        ActiveMask & ...
        ProjectedEnvelope >= LowerAGCLimit & ...
        ProjectedEnvelope <= UpperAGCLimit;

    TargetWindowSampleCount = sum(TargetWindowMask);

    if ActiveSampleCount > 0

        TargetWindowOccupancyPercentage = ...
            100 * TargetWindowSampleCount / ActiveSampleCount;

    else
        TargetWindowOccupancyPercentage = NaN;
    end


    %% ==============================
    %% MEASURE OVERSHOOT / UNDERSHOOT
    %% ==============================

    if ActiveSampleCount > 0

        ActiveProjectedEnvelope = ProjectedEnvelope(ActiveMask);

        MaximumOvershoot = max( ...
            max(ActiveProjectedEnvelope - UpperAGCLimit, 0));

        MaximumUndershoot = max( ...
            max(LowerAGCLimit - ActiveProjectedEnvelope, 0));

    else

        MaximumOvershoot = NaN;
        MaximumUndershoot = NaN;
    end


    %% ===============================
    %% MEASURE OBSERVED AGC GAIN RANGE
    %% ===============================

    MinimumGainObserved = min(Gain);
    MaximumGainObserved = max(Gain);


    %% ==========================================
    %% BUILD SAMPLE INDEX FOR RESPONSE-TIME TESTS
    %% ==========================================

    if isfield(History, "SampleIndex")

        SampleIndex = History.SampleIndex(:);

        if numel(SampleIndex) ~= N
            error("MeasureAGCResponse:SampleIndexLengthMismatch", ...
                "History.SampleIndex must match the AGC history length.");
        end

    else

        % Fall back to a local zero-based sample index when global frame
        % position information is unavailable.
        SampleIndex = (0:N-1)';
    end


    %% ===========================
    %% MEASURE AGC ATTACK RESPONSE
    %% ===========================

    % Attack regulation occurs when the active projected envelope is above
    % the upper AGC limit and the AGC must reduce gain.
    AttackCondition = ...
        ActiveMask & ProjectedEnvelope > UpperAGCLimit;

    AttackTimes = MeasureTransitionTimes( ...
        AttackCondition, ...
        ActiveMask, ...
        ProjectedEnvelope <= UpperAGCLimit, ...
        SampleIndex, ...
        Fs);

    if isempty(AttackTimes)

        MeanAttackTime = NaN;
        MaximumAttackTime = NaN;

    else

        MeanAttackTime = mean(AttackTimes);
        MaximumAttackTime = max(AttackTimes);
    end


    %% ============================
    %% MEASURE AGC RELEASE RESPONSE
    %% ============================

    % Release regulation occurs when the active projected envelope is below
    % the lower AGC limit and the AGC must increase gain.
    ReleaseCondition = ...
        ActiveMask & ProjectedEnvelope < LowerAGCLimit;

    ReleaseTimes = MeasureTransitionTimes( ...
        ReleaseCondition, ...
        ActiveMask, ...
        ProjectedEnvelope >= LowerAGCLimit, ...
        SampleIndex, ...
        Fs);

    if isempty(ReleaseTimes)

        MeanReleaseTime = NaN;
        MaximumReleaseTime = NaN;

    else

        MeanReleaseTime = mean(ReleaseTimes);
        MaximumReleaseTime = max(ReleaseTimes);
    end


    %% ===========================================
    %% STORE AUTOMATIC GAIN CONTROL MEASUREMENTS
    %% ===========================================

    AGCMetrics.UpperAGCLimit = UpperAGCLimit;
    AGCMetrics.LowerAGCLimit = LowerAGCLimit;
    AGCMetrics.NoiseThreshold = NoiseThreshold;

    AGCMetrics.ActiveSampleCount = ActiveSampleCount;
    AGCMetrics.TargetWindowSampleCount = TargetWindowSampleCount;
    AGCMetrics.TargetWindowOccupancyPercentage = ...
        TargetWindowOccupancyPercentage;

    AGCMetrics.MaximumOvershoot = MaximumOvershoot;
    AGCMetrics.MaximumUndershoot = MaximumUndershoot;

    AGCMetrics.MinimumGainObserved = MinimumGainObserved;
    AGCMetrics.MaximumGainObserved = MaximumGainObserved;

    AGCMetrics.AttackTimes = AttackTimes;
    AGCMetrics.MeanAttackTime = MeanAttackTime;
    AGCMetrics.MaximumAttackTime = MaximumAttackTime;

    AGCMetrics.ReleaseTimes = ReleaseTimes;
    AGCMetrics.MeanReleaseTime = MeanReleaseTime;
    AGCMetrics.MaximumReleaseTime = MaximumReleaseTime;
end


function TransitionTimes = MeasureTransitionTimes( ...
        TransitionCondition, ActiveMask, SettledCondition, ...
        SampleIndex, Fs)
%% ==========================================
%% MEASURE COMPLETED AGC TRANSITION DURATIONS
%% ==========================================
% Measures each completed out-of-range AGC response from the first sample
% outside the regulation window to the first active sample that reaches the
% corresponding regulation boundary.


    N = numel(TransitionCondition);

    % Locate the first sample of every independent transition event.
    EventStart = ...
        TransitionCondition & ...
        [true; ~TransitionCondition(1:end-1)];

    EventStartIndex = find(EventStart);

    TransitionTimes = zeros(0,1);


    for k = 1:numel(EventStartIndex)

        StartIndex = EventStartIndex(k);

        % Search forward for the first active sample that satisfies the
        % requested regulation boundary.
        SearchMask = ...
            ActiveMask(StartIndex+1:N) & ...
            SettledCondition(StartIndex+1:N);

        RelativeEndIndex = find(SearchMask, 1, "first");

        if isempty(RelativeEndIndex)
            continue
        end

        EndIndex = StartIndex + RelativeEndIndex;

        % Ignore a transition if another inactive/noise-gated region occurs
        % before regulation is completed. That event is not a clean AGC
        % response measurement.
        if any(~ActiveMask(StartIndex:EndIndex))
            continue
        end

        DurationSamples = ...
            SampleIndex(EndIndex) - SampleIndex(StartIndex);

        TransitionTimes(end+1,1) = DurationSamples / Fs; %#ok<AGROW>
    end
end
