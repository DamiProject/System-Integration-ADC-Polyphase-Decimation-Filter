classdef EndToEndTestConfig
    %% ==========================================
    %% ADC-POLYPHASE SYSTEM CONFIGURATION
    %% ==========================================

    properties (SetAccess = private)
        ADCParams
        DSPParams
    end

    methods
        function obj = EndToEndTestConfig()

            %% ==========================================
            %% ADC PARAMETERS
            %% ==========================================

            obj.ADCParams = ADCParameters();

            % Simulation / framing
            obj.ADCParams.setValue("Fs", 20000);
            obj.ADCParams.setValue("FrameLength", 31);
            obj.ADCParams.setValue("Dur", 0.021);
            obj.ADCParams.setValue("DF", 4);

            % Signal generator
            obj.ADCParams.setValue("Aburst", 0.5);
            obj.ADCParams.setValue("mu", 0.004);
            obj.ADCParams.setValue("Sigma", 0.001);
            obj.ADCParams.setValue("Ad", 1.0);
            obj.ADCParams.setValue("Ad2", 0.5);
            obj.ADCParams.setValue("Lambda", 120);
            obj.ADCParams.setValue("EST", 0.015);
            obj.ADCParams.setValue("FData", 200);
            obj.ADCParams.setValue("FData2", 400);
            obj.ADCParams.setValue("An", 0.1);
            obj.ADCParams.setValue("Fnoise", 7000);
            obj.ADCParams.setValue("Anf", 1e-3);
            obj.ADCParams.setValue("DC", 0.25);

            % ADC filters
            obj.ADCParams.setValue("FcHigh", 20);
            obj.ADCParams.setValue("FcLow", 2000);
            obj.ADCParams.setValue("nHpf", 4);
            obj.ADCParams.setValue("nLpf", 6);

            % HPF characterization specifications
            obj.ADCParams.setValue("FstopHPF", 5);
            obj.ADCParams.setValue("FpassHPF", 50);
            obj.ADCParams.setValue("ApassHPF", 1);
            obj.ADCParams.setValue("AstopHPF", 40);

            % LPF characterization specifications
            obj.ADCParams.setValue("FpassLPF", 1500);
            obj.ADCParams.setValue("FstopLPF", 4000);
            obj.ADCParams.setValue("ApassLPF", 1);
            obj.ADCParams.setValue("AstopLPF", 40);

            % FFT / STFT / Welch PSD analysis
            obj.ADCParams.setValue("N", 512);
            obj.ADCParams.setValue("STFTWindowLength", 128);
            obj.ADCParams.setValue("STFTOverlapLength", 64);
            obj.ADCParams.setValue("STFTFFTLength", 256);
            obj.ADCParams.setValue("PSDWindowLength", 128);
            obj.ADCParams.setValue("PSDOverlapLength", 64);
            obj.ADCParams.setValue("PSDFFTLength", 256);

            % ADC / AGC
            obj.ADCParams.setValue("Vfs", 1.0);
            obj.ADCParams.setValue("NumBits", 8);
            obj.ADCParams.setValue("EnvAttack", 0.005);
            obj.ADCParams.setValue("EnvRelease", 0.020);
            obj.ADCParams.setValue("GainAttack", 0.005);
            obj.ADCParams.setValue("GainRelease", 0.020);
            obj.ADCParams.setValue("GateAttack", 0.005);
            obj.ADCParams.setValue("GateRelease", 0.020);

            %% ==========================================
            %% DSP PARAMETERS
            %% ==========================================

            obj.DSPParams = DSPParameters();

            obj.DSPParams.setValue("DcF", 4);

            % The DSP input sampling rate is the ADC output sampling rate.
            ADCOutputFs = ...
                obj.ADCParams.getValue("Fs") / ...
                obj.ADCParams.getValue("DF");

            obj.DSPParams.setValue("Fs_DSP", ADCOutputFs);
            obj.DSPParams.setValue("Fpass", 400);
            obj.DSPParams.setValue("Fstop", 600);
            obj.DSPParams.setValue("Astop", 60);
            obj.DSPParams.setValue("Apass", 1);
            obj.DSPParams.setValue("B", 25);
        end
    end
end
