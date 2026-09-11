classdef ADCPerformanceAnalyzer < handle
    %% ===================================
    %% ADC PERFORMANCE ANALYZER
    %% ===================================
    properties
        Parameters
    end


    methods
        function obj = ADCPerformanceAnalyzer(P)
            %% ===========================================
            %% ADC PERFORMANCE ANALYZER INSTANCE CONSTRUCTOR
            %% ===========================================

            obj.Parameters = P;
        end


        function [QuantizationMetrics, CodeMetrics, SpectralMetrics] = ...
                MeasurePerformance(obj, SampledSignal, ...
                QuantizedSignal, Indices)
            %% =================================
            %% MEASURE ADC PERFORMANCE METRICS
            %% =================================

            QuantizationMetrics = ...
                MeasureQuantizationPerformance( ...
                    SampledSignal, ...
                    QuantizedSignal, ...
                    obj.Parameters);

            CodeMetrics = ...
                MeasureADCCodeUsage( ...
                    SampledSignal, ...
                    Indices, ...
                    obj.Parameters);

            SpectralMetrics = ...
                MeasureADCSpectralPerformance( ...
                    QuantizedSignal, ...
                    obj.Parameters);
        end


        function IMDMetrics = ...
                MeasureIntermodulationPerformance(obj, ...
                Signal, ToneFrequencies)
            %% ==============================================
            %% MEASURE ADC INTERMODULATION DISTORTION METRICS
            %% ==============================================

            IMDMetrics = ...
                MeasureADCIntermodulationPerformance( ...
                    Signal, ...
                    ToneFrequencies, ...
                    obj.Parameters);
        end


        function PlotSampledVsQuantized(~, SampleIndex, ...
                SampledSignal, QuantizedSignal)
            %% ======================================
            %% PLOT SAMPLED AND QUANTIZED ADC SIGNAL
            %% ======================================

            SampleIndex = SampleIndex(:);
            SampledSignal = SampledSignal(:);
            QuantizedSignal = QuantizedSignal(:);

            N = numel(SampleIndex);

            if numel(SampledSignal) ~= N || ...
                    numel(QuantizedSignal) ~= N

                error("ADCPerformanceAnalyzer:SignalLengthMismatch", ...
                    "SampleIndex and ADC signal vectors must have equal lengths.");
            end

            figure;

            plot( ...
                SampleIndex, ...
                SampledSignal, ...
                "LineWidth", 1.0);

            hold on;

            stairs( ...
                SampleIndex, ...
                QuantizedSignal, ...
                "LineWidth", 1.0);

            grid on;

            xlabel("Sample Index");
            ylabel("Amplitude");

            title("ADC Sampled and Quantized Signal");

            legend( ...
                "Sampled Signal", ...
                "Quantized Signal", ...
                "Location", "best");

            hold off;
        end


        function PlotQuantizationError(~, SampleIndex, ...
                SampledSignal, QuantizedSignal)
            %% ===============================
            %% PLOT ADC QUANTIZATION ERROR
            %% ===============================

            SampleIndex = SampleIndex(:);
            SampledSignal = SampledSignal(:);
            QuantizedSignal = QuantizedSignal(:);

            N = numel(SampleIndex);

            if numel(SampledSignal) ~= N || ...
                    numel(QuantizedSignal) ~= N

                error("ADCPerformanceAnalyzer:ErrorLengthMismatch", ...
                    "SampleIndex and ADC signal vectors must have equal lengths.");
            end

            QuantizationError = ...
                QuantizedSignal - SampledSignal;

            figure;

            plot( ...
                SampleIndex, ...
                QuantizationError, ...
                "LineWidth", 1.0);

            grid on;

            xlabel("Sample Index");
            ylabel("Quantization Error");

            title("ADC Quantization Error");
        end


        function PlotCodeHistogram(obj, Indices)
            %% ================================
            %% PLOT ADC OUTPUT CODE HISTOGRAM
            %% ================================

            ValidIndices = ...
                isnumeric(Indices) && ...
                isreal(Indices) && ...
                isvector(Indices) && ...
                ~isempty(Indices) && ...
                all(isfinite(Indices(:)));

            if ~ValidIndices
                error("ADCPerformanceAnalyzer:InvalidIndices", ...
                    "Indices must be a finite real-valued numeric vector.");
            end

            Indices = double(Indices(:));

            if any(Indices ~= floor(Indices))
                error("ADCPerformanceAnalyzer:NonIntegerIndices", ...
                    "ADC output indices must contain integer-valued codes.");
            end

            NumBits = obj.Parameters.getValue("NumBits");
            MaxCode = 2^NumBits - 1;
            TickStep = 2^(NumBits - 2);
            TickValues = [ ...
                0:TickStep:(2^NumBits - TickStep), MaxCode];

            if any(Indices < 0 | Indices > MaxCode)
                error("ADCPerformanceAnalyzer:IndexOutOfRange", ...
                    "ADC output indices exceed the configured code range.");
            end

            figure( ...
                "Name", "Bipolar Midtread Quantizer - Code Histogram", ...
                "Color", "w");

            histogram( ...
                Indices, ...
                "BinMethod", "integers");

            grid on;

            xlim([0 MaxCode]);
            xticks(TickValues);

            xlabel("Unsigned ADC Output Code");
            ylabel("Count");

            title("Bipolar Midtread Output-Code Distribution");
        end


        function PlotADCResponse(obj, Time, ...
                SampledSignal, QuantizedSignal, Indices)
            %% ==================================
            %% PLOT ADC TIME / CODE RESPONSE
            %% ==================================

            Time = Time(:);
            SampledSignal = SampledSignal(:);
            QuantizedSignal = QuantizedSignal(:);
            Indices = Indices(:);

            N = numel(Time);

            if numel(SampledSignal) ~= N || ...
                    numel(QuantizedSignal) ~= N || ...
                    numel(Indices) ~= N

                error("ADCPerformanceAnalyzer:ResponseLengthMismatch", ...
                    "ADC response vectors must have equal lengths.");
            end

            QuantizationError = ...
                QuantizedSignal - SampledSignal;

            NumBits = obj.Parameters.getValue("NumBits");
            Vfs = obj.Parameters.getValue("Vfs");
            QuantizationStep = Vfs / 2^NumBits;

            MaxCode = 2^NumBits - 1;
            TickStep = 2^(NumBits - 2);
            TickValues = [ ...
                0:TickStep:(2^NumBits - TickStep), MaxCode];

            TimeMicroseconds = Time * 1e6;

            figure( ...
                "Name", "Bipolar Midtread Quantizer - Time and Code Response", ...
                "Color", "w");

            TiledFigure = tiledlayout(3,1);
            TiledFigure.TileSpacing = "compact";
            TiledFigure.Padding = "compact";


            %% SAMPLED / QUANTIZED SIGNAL

            nexttile;

            plot( ...
                TimeMicroseconds, ...
                SampledSignal, ...
                "LineWidth", 1.0);

            hold on;

            stairs( ...
                TimeMicroseconds, ...
                QuantizedSignal, ...
                "LineWidth", 1.0);

            grid on;

            xlabel("Time (microseconds)");
            ylabel("Amplitude (V)");

            title("Sampler Output and Bipolar Midtread Reconstruction");

            legend( ...
                "Quantizer input", ...
                "Reconstructed voltage", ...
                "Location", "best");

            hold off;


            %% QUANTIZATION ERROR

            nexttile;

            plot( ...
                TimeMicroseconds, ...
                QuantizationError, ...
                "LineWidth", 1.0);

            hold on;

            yline( ...
                QuantizationStep / 2, ...
                "--", ...
                "+Delta/2", ...
                "HandleVisibility", "off");

            yline( ...
                -QuantizationStep / 2, ...
                "--", ...
                "-Delta/2", ...
                "HandleVisibility", "off");

            grid on;

            xlabel("Time (microseconds)");
            ylabel("Error (V)");

            title("Quantization Error (Endpoint Saturation Can Exceed Delta/2)");

            hold off;


            %% ADC OUTPUT CODE

            nexttile;

            stairs( ...
                TimeMicroseconds, ...
                Indices, ...
                "LineWidth", 1.0);

            grid on;

            title("Unsigned ADC Output Code Indices");

            xlabel("Time (microseconds)");
            ylabel("Code");

            ylim([0 MaxCode]);
            yticks(TickValues);

            yline( ...
                (2^NumBits) / 2, ...
                "--", ...
                "Zero-Volt Code", ...
                "HandleVisibility", "off");

            legend("Midtread Codes", "Location", "best");
        end


        function PlotSpectralPreservation(~, PlotData)
            %% ================================================
            %% PLOT QUANTIZER SPECTRAL AND TONE PRESERVATION
            %% ================================================

            RequiredFields = [ ...
                "FFTFrequency"; ...
                "InputMagnitude"; ...
                "OutputMagnitude"; ...
                "PSDFrequency"; ...
                "InputPSD"; ...
                "OutputPSD"; ...
                "DesiredFrequencies"; ...
                "AliasFrequency"; ...
                "SamplingFrequency"];

            for k = 1:numel(RequiredFields)
                if ~isfield(PlotData, RequiredFields(k))
                    error( ...
                        "ADCPerformanceAnalyzer:MissingPlotData", ...
                        "PlotData.%s is required.", RequiredFields(k));
                end
            end

            FFTFrequency = PlotData.FFTFrequency(:);
            InputMagnitude = PlotData.InputMagnitude(:);
            OutputMagnitude = PlotData.OutputMagnitude(:);
            PSDFrequency = PlotData.PSDFrequency(:);
            InputPSD = PlotData.InputPSD(:);
            OutputPSD = PlotData.OutputPSD(:);
            DesiredFrequencies = PlotData.DesiredFrequencies(:);
            AliasFrequency = PlotData.AliasFrequency;
            SamplingFrequency = PlotData.SamplingFrequency;

            if numel(FFTFrequency) ~= numel(InputMagnitude) || ...
                    numel(FFTFrequency) ~= numel(OutputMagnitude) || ...
                    numel(PSDFrequency) ~= numel(InputPSD) || ...
                    numel(PSDFrequency) ~= numel(OutputPSD)
                error( ...
                    "ADCPerformanceAnalyzer:SpectralLengthMismatch", ...
                    "Each spectral axis and its data vectors must match.");
            end

            figure( ...
                "Name", "Bipolar Midtread Quantizer - Spectral Preservation", ...
                "Color", "w");

            TiledFigure = tiledlayout(2,1);
            TiledFigure.TileSpacing = "compact";
            TiledFigure.Padding = "compact";


            %% FULL FIRST-NYQUIST-ZONE PSD

            nexttile;

            plot( ...
                PSDFrequency / 1e9, ...
                10 * log10(max(InputPSD, realmin("double"))), ...
                "LineWidth", 1.0);

            hold on;

            plot( ...
                PSDFrequency / 1e9, ...
                10 * log10(max(OutputPSD, realmin("double"))), ...
                "LineWidth", 1.0);

            xline( ...
                AliasFrequency / 1e9, ...
                ":", ...
                "Predicted alias", ...
                "HandleVisibility", "off");

            grid on;

            xlim([0 SamplingFrequency / 2] / 1e9);

            xlabel("Frequency (GHz)");
            ylabel("PSD (dB V^2/Hz)");

            title("Quantizer Input/Output Hamming-Welch PSD");

            legend( ...
                "Quantizer input", ...
                "Quantizer output", ...
                "Location", "best");

            hold off;


            %% ADJACENT DATA-TONE HAMMING-FFT DETAIL

            nexttile;

            plot( ...
                FFTFrequency / 1e9, ...
                20 * log10(max(InputMagnitude, realmin("double"))), ...
                "LineWidth", 1.0);

            hold on;

            plot( ...
                FFTFrequency / 1e9, ...
                20 * log10(max(OutputMagnitude, realmin("double"))), ...
                "LineWidth", 1.0);

            xline( ...
                DesiredFrequencies(1) / 1e9, ...
                ":", ...
                "Data 1", ...
                "HandleVisibility", "off");

            xline( ...
                DesiredFrequencies(2) / 1e9, ...
                ":", ...
                "Data 2", ...
                "HandleVisibility", "off");

            ToneSeparation = abs(diff(sort(DesiredFrequencies)));
            ZoomMargin = max(2 * ToneSeparation, 1e6);

            xlim([ ...
                min(DesiredFrequencies) - ZoomMargin, ...
                max(DesiredFrequencies) + ZoomMargin] / 1e9);

            grid on;

            xlabel("Frequency (GHz)");
            ylabel("Magnitude (dBV)");

            title("Hamming-FFT Detail of Data 1 and Data 2");

            legend( ...
                "Quantizer input", ...
                "Quantizer output", ...
                "Location", "best");

            hold off;

        end


        function PlotEncoderResponse(obj, Time, OffsetBinary, ...
                TwosComplement, QuantizedVoltage, DecodedVoltage)
            %% =============================================
            %% PLOT ADC ENCODER CODE AND VOLTAGE RESPONSE
            %% =============================================

            Time = Time(:);
            OffsetBinary = OffsetBinary(:);
            TwosComplement = TwosComplement(:);
            QuantizedVoltage = QuantizedVoltage(:);
            DecodedVoltage = DecodedVoltage(:);

            NumberSamples = numel(Time);

            if numel(OffsetBinary) ~= NumberSamples || ...
                    numel(TwosComplement) ~= NumberSamples || ...
                    numel(QuantizedVoltage) ~= NumberSamples || ...
                    numel(DecodedVoltage) ~= NumberSamples
                error( ...
                    "ADCPerformanceAnalyzer:EncoderLengthMismatch", ...
                    "ADC encoder plot vectors must have equal lengths.");
            end

            NumBits = obj.Parameters.getValue("NumBits");
            NumberCodes = 2^NumBits;
            HalfScale = NumberCodes / 2;
            MaximumOffsetCode = NumberCodes - 1;
            MinimumSignedCode = -HalfScale;
            MaximumSignedCode = HalfScale - 1;
            TickStep = 2^(NumBits - 2);

            OffsetTickValues = [ ...
                0:TickStep:(NumberCodes - TickStep), ...
                MaximumOffsetCode];
            SignedTickValues = [ ...
                MinimumSignedCode:TickStep: ...
                (HalfScale - TickStep), ...
                MaximumSignedCode];

            TimeMicroseconds = Time * 1e6;

            figure( ...
                "Name", "ADC Encoder - Code Representations", ...
                "Color", "w");

            TiledFigure = tiledlayout(3,1);
            TiledFigure.TileSpacing = "compact";
            TiledFigure.Padding = "compact";


            %% NATURAL UNSIGNED OFFSET-BINARY OUTPUT

            nexttile;

            stairs( ...
                TimeMicroseconds, ...
                double(OffsetBinary), ...
                "LineWidth", 1.0);

            hold on;
            grid on;

            title("Unsigned Offset-Binary ADC Output");
            xlabel("Time (microseconds)");
            ylabel("Code");

            ylim([0 MaximumOffsetCode]);
            yticks(OffsetTickValues);

            yline( ...
                HalfScale, ...
                "--", ...
                "Zero-Volt Code", ...
                "HandleVisibility", "off");

            legend("Offset-binary codes", "Location", "best");
            hold off;


            %% SIGNED TWO'S-COMPLEMENT OUTPUT

            nexttile;

            stairs( ...
                TimeMicroseconds, ...
                double(TwosComplement), ...
                "LineWidth", 1.0);

            hold on;
            grid on;

            title("Signed Two's-Complement Fixed-Point Codes");
            xlabel("Time (microseconds)");
            ylabel("Code");

            ylim([MinimumSignedCode MaximumSignedCode]);
            yticks(SignedTickValues);

            yline( ...
                0, ...
                "--", ...
                "Zero-Volt Code", ...
                "HandleVisibility", "off");

            legend("Two's-complement codes", "Location", "best");
            hold off;


            %% CODE-TO-VOLTAGE RECONSTRUCTION

            nexttile;

            plot( ...
                TimeMicroseconds, ...
                QuantizedVoltage, ...
                "LineWidth", 1.0);

            hold on;

            stairs( ...
                TimeMicroseconds, ...
                DecodedVoltage, ...
                "--", ...
                "LineWidth", 1.0);

            grid on;

            title("Voltage Reconstruction from Two's-Complement Codes");
            xlabel("Time (microseconds)");
            ylabel("Amplitude (V)");

            legend( ...
                "Quantizer reconstructed voltage", ...
                "Two's-complement decoded voltage", ...
                "Location", "best");

            hold off;
        end
    end
end
