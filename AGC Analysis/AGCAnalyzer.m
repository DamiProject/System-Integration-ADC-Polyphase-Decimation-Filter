classdef AGCAnalyzer < handle
    %% ==============================================
    %% AUTOMATIC GAIN CONTROL PERFORMANCE ANALYZER
    %% ==============================================
    properties
        Parameters
    end

    methods
        function obj = AGCAnalyzer(P)
            %% =================================
            %% AGC ANALYZER INSTANCE CONSTRUCTOR
            %% =================================

            obj.Parameters = P;
        end


        function [AGCMetrics, GateMetrics] = ...
                MeasurePerformance(obj, History)
            %% =====================================
            %% MEASURE AGC AND NOISE-GATE PERFORMANCE
            %% =====================================

            AGCMetrics = ...
                MeasureAGCResponse(History, obj.Parameters);

            GateMetrics = ...
                MeasureNoiseGateResponse(History, obj.Parameters);
        end


        function PlotGainResponse(~, t, History)
            %% =====================================
            %% PLOT AGC AND EFFECTIVE GAIN RESPONSE
            %% =====================================

            t = t(:);
            Gain = History.Gain(:);
            EffectiveGain = History.EffectiveGain(:);

            N = numel(t);

            if numel(Gain) ~= N || numel(EffectiveGain) ~= N
                error("AGCAnalyzer:GainLengthMismatch", ...
                    "Time and AGC gain histories must have equal lengths.");
            end

            figure( ...
                "Name", "AGC - Gain Response", ...
                "Color", "w");

            plot(t * 1e6, Gain, ...
                "LineWidth", 1.2, ...
                "DisplayName", "AGC Gain");

            hold on;

            plot(t * 1e6, EffectiveGain, ...
                "--", ...
                "LineWidth", 1.2, ...
                "DisplayName", "Effective Gain");

            grid on;

            xlabel("Time (microseconds)");
            ylabel("Gain");
            title("Automatic Gain Control Gain Response");

            legend("Location", "best");

            hold off;
        end


        function PlotEnvelopeResponse(obj, t, History)
            %% ==========================================
            %% PLOT AGC ENVELOPE AND REGULATION RESPONSE
            %% ==========================================

            t = t(:);
            Envelope = History.Envelope(:);
            ProjectedEnvelope = History.ProjectedEnvelope(:);

            N = numel(t);

            if numel(Envelope) ~= N || ...
                    numel(ProjectedEnvelope) ~= N

                error("AGCAnalyzer:EnvelopeLengthMismatch", ...
                    "Time and AGC envelope histories must have equal lengths.");
            end

            AGCMetrics = ...
                MeasureAGCResponse(History, obj.Parameters);

            % Use the same threshold-selection rule as AGC.GainControl():
            % configured NoiseGateThreshold first, then the legacy 2*|Anf|
            % fallback when the configured threshold is NaN.
            NoiseThreshold = obj.GetNoiseGateThreshold();

            figure( ...
                "Name", "AGC - Envelope Regulation", ...
                "Color", "w");

            TiledFigure = tiledlayout(2,1);
            TiledFigure.TileSpacing = "compact";
            TiledFigure.Padding = "compact";


            %% INPUT ENVELOPE / NOISE-GATE THRESHOLD

            nexttile;

            plot(t * 1e6, Envelope, ...
                "LineWidth", 1.2, ...
                "DisplayName", "Envelope");

            hold on;

            yline( ...
                NoiseThreshold, ...
                "--", ...
                "Noise-Gate Threshold", ...
                "LineWidth", 1.0, ...
                "HandleVisibility", "off");

            grid on;

            xlabel("Time (microseconds)");
            ylabel("Amplitude (V)");
            title("AGC Input Envelope");

            legend("Location", "best");

            hold off;


            %% PROJECTED OUTPUT ENVELOPE / AGC TARGET WINDOW

            nexttile;

            plot(t * 1e6, ProjectedEnvelope, ...
                "LineWidth", 1.2, ...
                "DisplayName", "Projected Envelope");

            hold on;

            yline( ...
                AGCMetrics.UpperAGCLimit, ...
                "--", ...
                "Upper AGC Limit", ...
                "LineWidth", 1.0, ...
                "HandleVisibility", "off");

            yline( ...
                AGCMetrics.LowerAGCLimit, ...
                "--", ...
                "Lower AGC Limit", ...
                "LineWidth", 1.0, ...
                "HandleVisibility", "off");

            grid on;

            xlabel("Time (microseconds)");
            ylabel("Amplitude (V)");
            title("AGC Projected Output Envelope");

            legend("Location", "best");

            hold off;
        end


        function PlotNoiseGateResponse(obj, t, History)
            %% ==================================
            %% PLOT COMPLETE NOISE-GATE RESPONSE
            %% ==================================
            % The noise gate is OPEN when the detected envelope is above
            % threshold. In that condition GateGain approaches 1 and the
            % AGC-controlled signal is passed. When the envelope falls below
            % threshold, the gate CLOSES and GateGain approaches 0.

            t = t(:);
            Envelope = History.Envelope(:);
            GateGain = History.GateGain(:);

            N = numel(t);

            if numel(Envelope) ~= N || numel(GateGain) ~= N
                error("AGCAnalyzer:GateLengthMismatch", ...
                    "Time and noise-gate histories must have equal lengths.");
            end

            NoiseThreshold = obj.GetNoiseGateThreshold();

            % Command/state requested by the detector.
            % 1 = Open / Pass
            % 0 = Close / Suppress
            GateOpenCommand = Envelope > NoiseThreshold;

            figure( ...
                "Name", "AGC - Noise-Gate Response", ...
                "Color", "w");

            TiledFigure = tiledlayout(3,1);
            TiledFigure.TileSpacing = "compact";
            TiledFigure.Padding = "compact";


            %% DETECTED ENVELOPE / THRESHOLD

            nexttile;

            plot(t * 1e6, Envelope, ...
                "LineWidth", 1.2, ...
                "DisplayName", "Envelope");

            hold on;

            yline( ...
                NoiseThreshold, ...
                "--", ...
                "Noise-Gate Threshold", ...
                "LineWidth", 1.0, ...
                "HandleVisibility", "off");

            grid on;

            xlabel("Time (microseconds)");
            ylabel("Amplitude (V)");
            title("Noise-Gate Detection Envelope");

            legend("Location", "best");

            hold off;


            %% CONTINUOUS NOISE-GATE GAIN

            nexttile;

            plot(t * 1e6, GateGain, ...
                "LineWidth", 1.2, ...
                "DisplayName", "Gate Gain");

            hold on;

            yline(0.90, ":", "90% Open Criterion", ...
                "LineWidth", 1.0, ...
                "HandleVisibility", "off");

            yline(0.10, ":", "10% Closed Criterion", ...
                "LineWidth", 1.0, ...
                "HandleVisibility", "off");

            ylim([-0.05 1.05]);
            grid on;

            xlabel("Time (microseconds)");
            ylabel("Gate Gain");
            title("Noise-Gate Gain Response");

            legend("Location", "best");

            hold off;


            %% OPEN / CLOSE COMMAND

            nexttile;

            stairs(t * 1e6, double(GateOpenCommand), ...
                "LineWidth", 1.2);

            ylim([-0.1 1.1]);

            yticks([0 1]);
            yticklabels(["Close / Suppress", "Open / Pass"]);

            grid on;

            xlabel("Time (microseconds)");
            ylabel("Gate Command");
            title("Noise-Gate Open / Close Command");
        end


        function PlotSignalResponse(~, t, InputSignal, ...
                OutputAGCSignal, History)
            %% =====================================
            %% PLOT AGC / NOISE-GATE SIGNAL RESPONSE
            %% =====================================

            t = t(:);
            InputSignal = InputSignal(:);
            OutputAGCSignal = OutputAGCSignal(:);
            AGCSignal = History.AGCSignal(:);

            N = numel(t);

            if numel(InputSignal) ~= N || ...
                    numel(OutputAGCSignal) ~= N || ...
                    numel(AGCSignal) ~= N

                error("AGCAnalyzer:SignalLengthMismatch", ...
                    "Time and AGC signal vectors must have equal lengths.");
            end

            figure( ...
                "Name", "AGC - Received-Signal Response", ...
                "Color", "w");

            TiledFigure = tiledlayout(3,1);
            TiledFigure.TileSpacing = "compact";
            TiledFigure.Padding = "compact";


            %% INPUT SIGNAL

            nexttile;

            plot(t * 1e6, InputSignal, ...
                "LineWidth", 1.0);

            grid on;

            xlabel("Time (microseconds)");
            ylabel("Amplitude (V)");
            title("AGC Input Signal");


            %% SIGNAL AFTER AGC GAIN / BEFORE NOISE GATE

            nexttile;

            plot(t * 1e6, AGCSignal, ...
                "LineWidth", 1.0);

            grid on;

            xlabel("Time (microseconds)");
            ylabel("Amplitude (V)");
            title("Signal After AGC Gain");


            %% FINAL SIGNAL AFTER NOISE GATE

            nexttile;

            plot(t * 1e6, OutputAGCSignal, ...
                "LineWidth", 1.0);

            grid on;

            xlabel("Time (microseconds)");
            ylabel("Amplitude (V)");
            title("Final AGC and Noise-Gate Output");
        end
    end


    methods (Access = private)
        function NoiseThreshold = GetNoiseGateThreshold(obj)
            %% =========================================
            %% RESOLVE NOISE-GATE DETECTION THRESHOLD
            %% =========================================
            % Keep plotting logic consistent with AGC.GainControl().

            NoiseThreshold = ...
                obj.Parameters.getValue("NoiseGateThreshold");

            if isnan(NoiseThreshold)
                NoiseThreshold = ...
                    2 * abs(obj.Parameters.getValue("Anf"));
            end
        end
    end
end
