classdef HighSpeedDesignConfig
    %% =======================================================
    %% HIGH-SPEED ADC-POLYPHASE DESIGN CONFIGURATION
    %% =======================================================
    % Design-time configuration used by RunDemoMain.m and its demonstration
    % stage functions. The low-frequency unit and integration test
    % configuration is independent.

    properties (SetAccess = private)
        ADCParams
        DSPParams
        DecimatorRequirements
        RandomSeed
    end

    methods
        function obj = HighSpeedDesignConfig()

            obj.ADCParams = ADCParameters();
            obj.DSPParams = DSPParameters();
            obj.RandomSeed = 42;

            %% ==========================================
            %% HIGH-SPEED SIMULATION AND FRAMING
            %% ==========================================

            Fs = 40e9;
            TotalSamples = 2^19;

            obj.ADCParams.setValue("Fs", Fs);
            obj.ADCParams.setValue("Dur", TotalSamples / Fs);
            obj.ADCParams.setValue("FrameLength", 8192);

            %% ==========================================
            %% TWO-DATA-SIGNAL INPUT STIMULUS
            %% ==========================================

            obj.ADCParams.setValue("FData", 1.000e9);
            obj.ADCParams.setValue("FData2", 1.001e9);

            obj.ADCParams.setValue("Ad", 20);
            obj.ADCParams.setValue("Ad2", 12);
            obj.ADCParams.setValue("Aburst", 10);

            obj.ADCParams.setValue("mu", 1.5e-6);
            obj.ADCParams.setValue("Sigma", 0.40e-6);
            obj.ADCParams.setValue("EST", 3.5e-6);
            obj.ADCParams.setValue("Lambda",1.2e6);

            %% ==========================================
            %% INPUT NONIDEALITIES
            %% ==========================================

            obj.ADCParams.setValue("DC", 12);
            obj.ADCParams.setValue("Fnoise", 6.2e9);
            obj.ADCParams.setValue("An", 20);

            % White-noise power intentionally exceeds the individual
            % powers of the deterministic input components.
            obj.ADCParams.setValue("Anf", 300);

            %% ==========================================
            %% DC-REMOVAL HIGH-PASS FILTER
            %% ==========================================

            % Approved frequency-response specifications.
            obj.ADCParams.setValue("FstopHPF", 50e6);
            obj.ADCParams.setValue("FpassHPF", 500e6);
            obj.ADCParams.setValue("ApassHPF", 0.10);
            obj.ADCParams.setValue("AstopHPF", 40);

            % Approved received-waveform and transient requirements.
            obj.ADCParams.setValue("DCRejectionHPF", 40);
            obj.ADCParams.setValue("MaxSettlingTimeHPF", 10e-9);
            obj.ADCParams.setValue("SettlingToleranceHPF", 0.01);
            obj.ADCParams.setValue("MaxDesiredToneLossHPF", 0.01);

            % Minimum-order Butterworth design obtained from buttord using
            % the approved passband and stopband requirements. FcHigh is
            % the Butterworth natural (-3 dB) cutoff, not the passband edge.
            obj.ADCParams.setValue("nHpf", 3);
            obj.ADCParams.setValue("FcHigh", 267.300887544189e6);

            %% ==========================================
            %% ANTI-ALIASING LOW-PASS FILTER
            %% ==========================================

            % The planned sampler reduces 40 GS/s to 10 GS/s. Its 5 GHz
            % Nyquist frequency therefore defines the LPF stopband edge.
            % The sampler itself remains a later signal-chain stage.
            obj.ADCParams.setValue("DF", 4);

            % Approved frequency-response specifications.
            obj.ADCParams.setValue("FpassLPF", 1.25e9);
            obj.ADCParams.setValue("FstopLPF", 5.00e9);
            obj.ADCParams.setValue("ApassLPF", 0.10);
            obj.ADCParams.setValue("AstopLPF", 60);

            % Approved desired-signal, interference, and transient
            % requirements. Overshoot and tolerance are stored as ratios.
            obj.ADCParams.setValue( ...
                "MinInterferenceAttenuationLPF", 60);
            obj.ADCParams.setValue("MaxDesiredToneLossLPF", 0.01);
            obj.ADCParams.setValue("MaxSettlingTimeLPF", 5e-9);
            obj.ADCParams.setValue("SettlingToleranceLPF", 0.01);
            obj.ADCParams.setValue("MaxStepOvershootLPF", 0.20);

            % Retain the minimum Butterworth order obtained from buttord.
            % Its returned natural cutoff places the realized response
            % exactly on the 0.10 dB passband boundary, leaving no numeric
            % design margin. Moving FcLow modestly upward improves the
            % passband margin while retaining more than the required
            % 60 dB stopband attenuation. FcLow remains the natural
            % (-3 dB) cutoff, not the passband edge.
            obj.ADCParams.setValue("nLpf", 7);
            obj.ADCParams.setValue("FcLow", 1.650e9);

            %% ==========================================
            %% PRE-ADC AUTOMATIC GAIN CONTROL
            %% ==========================================

            % The quantizer uses a 2 V peak-to-peak input range. The AGC
            % therefore controls its output within the corresponding
            % -1 V to +1 V ADC input limits.
            obj.ADCParams.setValue("Vfs", 2.0);

            % The high-speed received waveform requires substantially more
            % attenuation than the general 0.1 minimum-gain default. A
            % 0.001 lower bound supplies up to 60 dB of attenuation, while
            % the 10.0 upper bound permits up to 20 dB of amplification.
            obj.ADCParams.setValue("MinAGCGain", 0.001);
            obj.ADCParams.setValue("MaxAGCGain", 10.0);

            % Begin at minimum gain so the large initial input cannot
            % immediately overdrive the ADC while the control loop is
            % acquiring its operating level.
            obj.ADCParams.setValue("InitialAGCGain", 0.001);

            % The gate operates on the post-LPF envelope, so its threshold
            % is independent of the generator's pre-filter AWGN amplitude.
            % Ten volts remains below the 12 V secondary data tone and
            % keeps this continuously active two-tone record unmuted.
            obj.ADCParams.setValue("NoiseGateThreshold", 10.0);

            % Fast envelope acquisition captures rising peaks before the
            % gain loop responds. The longer envelope release smooths the
            % high-noise waveform instead of following every downward
            % fluctuation.
            obj.ADCParams.setValue("EnvAttack", 1e-9);
            obj.ADCParams.setValue("EnvRelease", 25e-9);

            % Gain reduction settles quickly enough to protect full scale.
            % Slower gain recovery reduces envelope modulation and spectral
            % gain pumping during short signal dips.
            obj.ADCParams.setValue("GainAttack", 4e-9);
            obj.ADCParams.setValue("GainRelease", 22.4e-9);

            % Preserve the existing fast-open/slow-close noise-gate design
            % while translating its timing to the high-speed record.
            obj.ADCParams.setValue("GateAttack", 4e-9);
            obj.ADCParams.setValue("GateRelease", 50e-9);

            % Received-record AGC performance requirements used by
            % RunDemoAGC. This continuously active waveform supports
            % regulation, gain-release, ADC full-scale, and signal-quality
            % checks. Dedicated step-response overshoot/undershoot and
            % noise-gate switching metrics are intentionally left to
            % separate verification rather than claimed from this record.
            obj.ADCParams.setValue("MinAGCTargetOccupancy", 99.0);
            obj.ADCParams.setValue("MaxAGCClippingPercentage", 0.01);
            obj.ADCParams.setValue("MaxAGCReleaseTime", 250e-9);
            obj.ADCParams.setValue("MaxAGCSNRDegradation", 0.5);
            obj.ADCParams.setValue("MaxAGCSINRDegradation", 0.5);

            %% ==========================================
            %% FRAME-BASED ADC SAMPLER REQUIREMENTS
            %% ==========================================

            % The ideal sampler must preserve both adjacent desired tones
            % while reducing the working rate from 40 GS/s to 10 GS/s.
            % Frequency error is normalized by the true full-record
            % resolution; zero padding used for display is not credited as
            % additional resolving power.
            obj.ADCParams.setValue( ...
                "MaxSamplerFrequencyErrorBins", 1.0);
            obj.ADCParams.setValue( ...
                "MaxSamplerToneLevelChange", 0.25);
            obj.ADCParams.setValue( ...
                "MaxSamplerSNRDegradation", 0.5);
            obj.ADCParams.setValue( ...
                "MaxSamplerSINRDegradation", 0.5);

            %% ==========================================
            %% BIPOLAR MIDTREAD QUANTIZER REQUIREMENTS
            %% ==========================================

            % Eight bits provide 256 unsigned output-code indices while
            % retaining the existing bipolar 2 V peak-to-peak input range.
            % The resulting 7.8125 mV step is well below the received
            % record's analog-noise floor, so additional bits would widen
            % the downstream datapath without materially improving the
            % system-level SNR for this demonstration.
            obj.ADCParams.setValue("NumBits", 8);

            % Received-record quantizer requirements. Frequency error is
            % normalized by the true 131072-sample record resolution;
            % zero padding used by HammingFFT is not treated as additional
            % resolving power.
            obj.ADCParams.setValue("MinQuantizerSQNR", 38.0);
            obj.ADCParams.setValue( ...
                "MaxQuantizerOverloadPercentage", 0.01);
            obj.ADCParams.setValue( ...
                "MaxQuantizerFrequencyErrorBins", 1.0);
            obj.ADCParams.setValue( ...
                "MaxQuantizerToneLevelChange", 0.05);
            obj.ADCParams.setValue( ...
                "MaxQuantizerSNRDegradation", 0.10);
            obj.ADCParams.setValue( ...
                "MaxQuantizerSINRDegradation", 0.10);

            %% ==========================================
            %% FIXED-POINT POLYPHASE FIR DECIMATOR
            %% ==========================================

            % The ADC encoder supplies signed Q8.0 two's-complement codes
            % at 10 GS/s. A second factor-of-four rate reduction produces
            % the final 2.5 GS/s target-rate digital output.
            ADCSamplingFrequency = ...
                Fs / obj.ADCParams.getValue("DF");
            ADCFrameLength = ...
                obj.ADCParams.getValue("FrameLength") / ...
                obj.ADCParams.getValue("DF");

            obj.DSPParams.setValue("Fs_DSP", ADCSamplingFrequency);
            obj.DSPParams.setValue("DcF", 4);
            obj.DSPParams.setValue("FrameLength", ADCFrameLength);

            % The passband leaves approximately 99 MHz above Data 2. The
            % stopband begins at the 1.25 GHz Nyquist frequency of the
            % target-rate output so every folding band is protected.
            obj.DSPParams.setValue("Fpass", 1.10e9);
            obj.DSPParams.setValue("Fstop", 1.25e9);
            obj.DSPParams.setValue("Apass", 0.10);
            obj.DSPParams.setValue("Astop", 60);

            % Twenty-five terms retain the established manual Bessel-I0
            % implementation used to generate the Kaiser window.
            obj.DSPParams.setValue("B", 25);

            % System-level requirements and implementation limits remain
            % in the design configuration rather than being hard-coded in
            % the demonstration stage.
            obj.DecimatorRequirements = struct( ...
                "HeadroomBits", 1, ...
                "MaxCoefficientWordLength", 16, ...
                "MaxAccumulatorWordLength", 32, ...
                "MaxGroupDelay_s", 15e-9, ...
                "MaxDesiredToneLoss_dB", 0.10, ...
                "MaxFrequencyErrorBins", 1.0, ...
                "MinAliasAttenuation_dB", 60, ...
                "MinFixedPointErrorSNR_dB", 60, ...
                "MinMACReductionPercent", 70, ...
                "MinSNRImprovement_dB", 5.5, ...
                "MinSINRImprovement_dB", 5.5);

            %% ==========================================
            %% SPECTRUM-ANALYSIS CONFIGURATION
            %% ==========================================

            % The full-record FFT retains the resolution required to
            % separate the data tones spaced 1 MHz apart.
            obj.ADCParams.setValue("N", TotalSamples);

            % The shorter STFT window prioritizes time localization of the
            % Gaussian burst and exponential fade over tone separation.
            obj.ADCParams.setValue("STFTWindowLength", 65536);
            obj.ADCParams.setValue("STFTOverlapLength", 32768);
            obj.ADCParams.setValue("STFTFFTLength", 65536);


            % Welch averaging provides a lower-variance noise-floor
            % estimate at the expense of resolving the adjacent tones.
            obj.ADCParams.setValue("PSDWindowLength", 262144);
            obj.ADCParams.setValue("PSDOverlapLength", 131072);
            obj.ADCParams.setValue("PSDFFTLength", 262144);
        end
    end
end
