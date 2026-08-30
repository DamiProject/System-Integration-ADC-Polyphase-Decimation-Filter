classdef TestFloatingDSPDecimator < matlab.unittest.TestCase
    %% ========================================================
    %% SYSTEM TEST SUITE FOR ADC TO FLOATING POLYPHASE DECIMATOR
    %% ========================================================

    methods (Test)
        function testQuantizedADCToFloatingDecimatorIntegration(testCase)
            %% Validates Full Frame Chain Through Floating Polyphase FIR

            Config = EndToEndConfig();
            ADCParams = Config.ADCParams;
            DSPParams = Config.DSPParams;

            DcF = DSPParams.getValue("DcF");
            DF = ADCParams.getValue("DF");

            OldRngState = rng;
            CleanupObj = onCleanup(@() rng(OldRngState)); %#ok<NASGU>
            rng(37, "twister");

            %% ==========================================
            %% FRAMED ADC -> FLOATING DSP CHAIN
            %% ==========================================

            SG = SignalGenerator(ADCParams);
            FrameFilter = ADCFilter(ADCParams);
            FrameAGC = AGC(ADCParams);
            FrameADC = ADC(ADCParams);
            FrameDSP = DSP(DSPParams);

            CompleteInput = zeros(0, 1);
            CompleteSampledOutput = zeros(0, 1);
            CompleteQuantizedInput = zeros(0, 1);
            CompleteDSPOutput = zeros(0, 1);
            CompleteDSPOutputIndex = zeros(0, 1);

            while ~SG.IsDone()
                [InputFrame, ~, ~, SignalFrameInfo] = ...
                    SG.GenNoisySignal();

                HPFOutputFrame = ...
                    FrameFilter.ProcessHPFFrame(InputFrame);
                LPFOutputFrame = ...
                    FrameFilter.ProcessLPFFrame(HPFOutputFrame);
                AGCOutputFrame = ...
                    FrameAGC.GainControl(LPFOutputFrame);
                SampledOutputFrame = ...
                    FrameADC.Sampler(AGCOutputFrame);
                QuantizedOutputFrame = ...
                    FrameADC.Midtread(SampledOutputFrame);

                [DSPOutputFrame, DSPFrameInfo] = ...
                    FrameDSP.ProcessFrame( ...
                        QuantizedOutputFrame, ...
                        SignalFrameInfo.IsLastFrame);

                CompleteInput = ...
                    [CompleteInput; InputFrame]; %#ok<AGROW>
                CompleteSampledOutput = ...
                    [CompleteSampledOutput; ...
                     SampledOutputFrame]; %#ok<AGROW>
                CompleteQuantizedInput = ...
                    [CompleteQuantizedInput; ...
                     QuantizedOutputFrame]; %#ok<AGROW>
                CompleteDSPOutput = ...
                    [CompleteDSPOutput; DSPOutputFrame]; %#ok<AGROW>
                CompleteDSPOutputIndex = ...
                    [CompleteDSPOutputIndex; ...
                     DSPFrameInfo.OutputSampleIndex]; %#ok<AGROW>
            end

            %% ==========================================
            %% INDEPENDENT WHOLE-VECTOR ADC REFERENCE
            %% ==========================================

            ReferenceFilter = ADCFilter(ADCParams);
            [sosHPF, gHPF] = ReferenceFilter.DCRemoval();
            [sosLPF, gLPF] = ReferenceFilter.AAF();

            ExpectedHPFOutput = ...
                sosfilt(sosHPF, gHPF * CompleteInput);
            ExpectedLPFOutput = ...
                sosfilt(sosLPF, gLPF * ExpectedHPFOutput);

            ReferenceAGC = AGC(ADCParams);
            ExpectedAGCOutput = ...
                ReferenceAGC.GainControl(ExpectedLPFOutput);

            ReferenceADC = ADC(ADCParams);
            ExpectedSampledOutput = ...
                ReferenceADC.Sampler(ExpectedAGCOutput);

            % The quantizer is stateless, so quantizing the concatenated
            % framed sampler output must match concatenating per-frame results.
            QuantizerReferenceADC = ADC(ADCParams);
            ExpectedQuantizedInput = ...
                QuantizerReferenceADC.Midtread( ...
                    CompleteSampledOutput);

            %% ==========================================
            %% INDEPENDENT FIR -> DOWNSAMPLE REFERENCE
            %% ==========================================

            ExpectedDSPOutput = ...
                testCase.directFIRDecimatorReference( ...
                    ExpectedQuantizedInput, ...
                    FrameDSP.FilterCoefficients, DcF);

            %% ==========================================
            %% VERIFY SYSTEM HANDOFFS
            %% ==========================================

            testCase.verifyEqual( ...
                CompleteSampledOutput, ExpectedSampledOutput, ...
                "AbsTol", 1e-12);

            testCase.verifyEqual( ...
                CompleteQuantizedInput, ExpectedQuantizedInput, ...
                "AbsTol", 1e-12);

            testCase.verifyEqual( ...
                CompleteDSPOutput, ExpectedDSPOutput, ...
                "AbsTol", 1e-12);

            testCase.verifyEqual( ...
                CompleteDSPOutputIndex, ...
                (0:numel(ExpectedDSPOutput)-1)');

            ExpectedADCSampleCount = ...
                ceil(numel(CompleteInput) / DF);

            ExpectedDSPOutputCount = ...
                ceil(ExpectedADCSampleCount / DcF);

            testCase.verifyEqual( ...
                FrameDSP.InputSamplesReceived, ExpectedADCSampleCount);
            testCase.verifyEqual( ...
                FrameDSP.OutputSamplesProduced, ExpectedDSPOutputCount);
            testCase.verifyEqual( ...
                FrameDSP.FramesProcessed, SG.FramesGenerated);
            testCase.verifyEqual( ...
                FrameDSP.PendingInput, zeros(0, 1));
            testCase.verifyTrue(FrameDSP.StreamFinalized);
            testCase.verifyTrue(SG.IsDone());
        end
    end

    methods (Access = private)
        function ExpectedOutput = directFIRDecimatorReference( ...
                ~, InputSignal, FilterCoefficients, DcF)
            %% Creates Independent FIR-Then-Downsample Reference Output

            InputSignal = double(InputSignal(:));

            PadLength = mod( ...
                DcF - mod(numel(InputSignal), DcF), DcF);

            PaddedInput = ...
                [InputSignal; zeros(PadLength, 1)];

            FullFIR = conv( ...
                PaddedInput, FilterCoefficients(:));

            ExpectedOutput = ...
                FullFIR(DcF:DcF:numel(PaddedInput));
        end
    end
end
