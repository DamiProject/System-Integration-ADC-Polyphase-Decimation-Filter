function GateMetrics = MeasureNoiseGateResponse(History, Parameters)
%% ==========================================
%% MEASURE NOISE GATE PERFORMANCE RESPONSE
%% ==========================================
% Measures the dynamic and attenuation performance of the AGC noise gate
% using the historical signals returned by AGC.GainControl().
%
% Inputs:
%   History    - AGC history structure returned by GainControl()
%   Parameters - ADC parameter object containing Fs and the noise-gate
%                threshold configuration
%
% Output:
%   GateMetrics - Structure containing noise-gate performance measurements


    %% ============================================
    %% VALIDATE REQUIRED NOISE-GATE HISTORY FIELDS
    %% ============================================

    RequiredFields = ["Envelope", "GateGain", "AGCSignal"];

    for k = 1:numel(RequiredFields)

        if ~isfield(History, RequiredFields(k))
            error("MeasureNoiseGateResponse:MissingHistoryField", ...
                "History.%s is required.", RequiredFields(k));
        end
    end


    %% ===========================
    %% FORCE COLUMN-VECTOR FORMAT
    %% ===========================

    Envelope = History.Envelope(:);
    GateGain = History.GateGain(:);
    AGCSignal = History.AGCSignal(:);

    N = numel(Envelope);

    if numel(GateGain) ~= N || numel(AGCSignal) ~= N
        error("MeasureNoiseGateResponse:HistoryLengthMismatch", ...
            "Noise-gate history vectors must have equal lengths.");
    end


    %% ================================
    %% HANDLE AN EMPTY HISTORY CLEANLY
    %% ================================

    if N == 0

        GateMetrics = struct( ...
            "NoiseThreshold", NaN, ...
            "ActiveSampleCount", 0, ...
            "InactiveSampleCount", 0, ...
            "InactivePercentage", NaN, ...
            "MinimumGateGainObserved", NaN, ...
            "MaximumGateGainObserved", NaN, ...
            "MeanInactiveGateGain", NaN, ...
            "InactiveGateGainVariation", NaN, ...
            "InactiveInputPower", NaN, ...
            "InactiveOutputPower", NaN, ...
            "NoiseGateSuppression", NaN, ...
            "GateOpenTimes", zeros(0,1), ...
            "MeanGateOpenTime", NaN, ...
            "MaximumGateOpenTime", NaN, ...
            "GateCloseTimes", zeros(0,1), ...
            "MeanGateCloseTime", NaN, ...
            "MaximumGateCloseTime", NaN);

        return
    end


    %% ===================================
    %% DERIVE THE AGC NOISE-GATE THRESHOLD
    %% ===================================

    Fs = Parameters.getValue("Fs");

    % Use the same configured threshold and legacy fallback as
    % AGC.GainControl().
    NoiseThreshold = Parameters.getValue("NoiseGateThreshold");

    if isnan(NoiseThreshold)
        Anf = Parameters.getValue("Anf");
        NoiseThreshold = abs(Anf) * 2;
    end


    %% =========================================
    %% IDENTIFY ACTIVE AND INACTIVE SIGNAL AREAS
    %% =========================================

    ActiveMask = Envelope > NoiseThreshold;
    InactiveMask = ~ActiveMask;

    ActiveSampleCount = sum(ActiveMask);
    InactiveSampleCount = sum(InactiveMask);

    InactivePercentage = ...
        100 * InactiveSampleCount / N;


    %% ===============================
    %% MEASURE OBSERVED GATE-GAIN RANGE
    %% ===============================

    MinimumGateGainObserved = min(GateGain);
    MaximumGateGainObserved = max(GateGain);


    %% =========================================
    %% MEASURE GATE BEHAVIOUR IN INACTIVE AREAS
    %% =========================================

    if InactiveSampleCount > 0

        InactiveGateGain = GateGain(InactiveMask);

        MeanInactiveGateGain = mean(InactiveGateGain);

        InactiveGateGainVariation = ...
            max(InactiveGateGain) - min(InactiveGateGain);

    else

        MeanInactiveGateGain = NaN;
        InactiveGateGainVariation = NaN;
    end


    %% ===========================================
    %% MEASURE NOISE-REGION POWER SUPPRESSION
    %% ===========================================

    if InactiveSampleCount > 0

        % Signal immediately before application of the noise gate.
        InactiveAGCSignal = AGCSignal(InactiveMask);

        % Reconstruct the final post-gate signal from the recorded history.
        InactiveOutputSignal = ...
            InactiveAGCSignal .* GateGain(InactiveMask);

        InactiveInputPower = ...
            mean(abs(InactiveAGCSignal).^2);

        InactiveOutputPower = ...
            mean(abs(InactiveOutputSignal).^2);

        if InactiveInputPower == 0

            % There is no noise-region signal power to suppress.
            NoiseGateSuppression = NaN;

        elseif InactiveOutputPower == 0

            % Complete suppression of non-zero pre-gate signal power.
            NoiseGateSuppression = Inf;

        else

            % Positive dB values indicate reduction of inactive-region power.
            NoiseGateSuppression = ...
                10*log10(InactiveInputPower / InactiveOutputPower);
        end

    else

        InactiveInputPower = NaN;
        InactiveOutputPower = NaN;
        NoiseGateSuppression = NaN;
    end


    %% ==========================================
    %% BUILD SAMPLE INDEX FOR TRANSITION TIMING
    %% ==========================================

    if isfield(History, "SampleIndex")

        SampleIndex = History.SampleIndex(:);

        if numel(SampleIndex) ~= N
            error("MeasureNoiseGateResponse:SampleIndexLengthMismatch", ...
                "History.SampleIndex must match the history length.");
        end

    else

        % Fall back to a local zero-based sample index when global frame
        % position information is unavailable.
        SampleIndex = (0:N-1)';
    end


    %% ===============================
    %% MEASURE NOISE-GATE OPENING TIME
    %% ===============================

    % GatePeak = 1.0 in the AGC implementation. Reaching 90% of GatePeak
    % is used as the practical gate-open settling criterion.
    GateOpenThreshold = 0.90;

    GateOpenEvent = ...
        ActiveMask & [true; ~ActiveMask(1:end-1)];

    GateOpenTimes = MeasureGateTransitionTimes( ...
        GateOpenEvent, ...
        ActiveMask, ...
        GateGain >= GateOpenThreshold, ...
        SampleIndex, ...
        Fs);

    if isempty(GateOpenTimes)

        MeanGateOpenTime = NaN;
        MaximumGateOpenTime = NaN;

    else

        MeanGateOpenTime = mean(GateOpenTimes);
        MaximumGateOpenTime = max(GateOpenTimes);
    end


    %% ===============================
    %% MEASURE NOISE-GATE CLOSING TIME
    %% ===============================

    % GateFloor = 0.0 in the AGC implementation. Reaching 10% of GatePeak
    % is used as the practical gate-closed settling criterion.
    GateCloseThreshold = 0.10;

    GateCloseEvent = ...
        InactiveMask & [true; ~InactiveMask(1:end-1)];

    GateCloseTimes = MeasureGateTransitionTimes( ...
        GateCloseEvent, ...
        InactiveMask, ...
        GateGain <= GateCloseThreshold, ...
        SampleIndex, ...
        Fs);

    if isempty(GateCloseTimes)

        MeanGateCloseTime = NaN;
        MaximumGateCloseTime = NaN;

    else

        MeanGateCloseTime = mean(GateCloseTimes);
        MaximumGateCloseTime = max(GateCloseTimes);
    end


    %% =====================================
    %% STORE NOISE-GATE PERFORMANCE METRICS
    %% =====================================

    GateMetrics.NoiseThreshold = NoiseThreshold;

    GateMetrics.ActiveSampleCount = ActiveSampleCount;
    GateMetrics.InactiveSampleCount = InactiveSampleCount;
    GateMetrics.InactivePercentage = InactivePercentage;

    GateMetrics.MinimumGateGainObserved = MinimumGateGainObserved;
    GateMetrics.MaximumGateGainObserved = MaximumGateGainObserved;

    GateMetrics.MeanInactiveGateGain = MeanInactiveGateGain;
    GateMetrics.InactiveGateGainVariation = ...
        InactiveGateGainVariation;

    GateMetrics.InactiveInputPower = InactiveInputPower;
    GateMetrics.InactiveOutputPower = InactiveOutputPower;
    GateMetrics.NoiseGateSuppression = NoiseGateSuppression;

    GateMetrics.GateOpenTimes = GateOpenTimes;
    GateMetrics.MeanGateOpenTime = MeanGateOpenTime;
    GateMetrics.MaximumGateOpenTime = MaximumGateOpenTime;

    GateMetrics.GateCloseTimes = GateCloseTimes;
    GateMetrics.MeanGateCloseTime = MeanGateCloseTime;
    GateMetrics.MaximumGateCloseTime = MaximumGateCloseTime;
end


function TransitionTimes = MeasureGateTransitionTimes( ...
        EventStartMask, RequiredStateMask, SettledCondition, ...
        SampleIndex, Fs)
%% =============================================
%% MEASURE COMPLETED NOISE-GATE TRANSITION TIMES
%% =============================================
% Measures each complete gate transition while the corresponding active or
% inactive state remains uninterrupted.


    N = numel(EventStartMask);

    EventStartIndex = find(EventStartMask);

    TransitionTimes = zeros(0,1);


    for k = 1:numel(EventStartIndex)

        StartIndex = EventStartIndex(k);

        % If the gate already satisfies the settling criterion at the event
        % boundary, its measured transition time is zero.
        if SettledCondition(StartIndex)

            TransitionTimes(end+1,1) = 0; %#ok<AGROW>
            continue
        end

        SearchState = RequiredStateMask(StartIndex+1:N);
      
        % The transition is valid only until the requested active/inactive
        % state changes again.
        StateEndRelative = find(~SearchState, 1, "first");

        if isempty(StateEndRelative)

            SearchEnd = N;

        else

            SearchEnd = StartIndex + StateEndRelative - 1;
        end

        if SearchEnd <= StartIndex
            continue
        end

        RelativeEndIndex = find( ...
            SettledCondition(StartIndex+1:SearchEnd), ...
            1, ...
            "first");

        if isempty(RelativeEndIndex)
            continue
        end

        EndIndex = StartIndex + RelativeEndIndex;

        DurationSamples = ...
            SampleIndex(EndIndex) - SampleIndex(StartIndex);

        TransitionTimes(end+1,1) = DurationSamples / Fs; %#ok<AGROW>
    end
end
