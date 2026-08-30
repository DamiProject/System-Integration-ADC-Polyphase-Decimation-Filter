classdef TestADCFixedDSPDecimator < matlab.unittest.TestCase
    %% ============================================================
    %% SYSTEM TEST SUITE FOR ADC TO FIXED-POINT POLYPHASE DECIMATOR
    %% ============================================================

    methods (Test)
        function testADCEncoderFloatingAndFixedFrameIntegration(testCase)
            %% ADC midtread -> encoder -> floating/fixed decimator comparison

            Config = EndToEndConfig();
            ADCParams = Config.ADCParams;
            DSPParams = Config.DSPParams;

            NumBits = ADCParams.getValue("NumBits");
            Vfs = ADCParams.getValue("Vfs");

            n = (0:72)';
            ADCInput = ...
                0.38 * sin(2*pi*0.043*n) + ...
                0.09 * cos(2*pi*0.117*n);

            %% ==========================================
            %% ADC QUANTIZATION AND ENCODING
            %% ==========================================

            Quantizer = ADC(ADCParams);
            [QuantizedSignal, Indices] = ...
                Quantizer.Midtread(ADCInput);

            Encoder = ADCEncoder(ADCParams);
            [~, TwosComplement] = Encoder.Encode(Indices);
            InputCodes = int64(TwosComplement(:));

            InputFormat.WL = NumBits;
            InputFormat.IWL = NumBits;
            InputFormat.FWL = 0;

            %% ==========================================
            %% FIXED-POINT DSP REFERENCE AND FRAME PATH
            %% ==========================================

            WholeD = FixedDSPDecimator(DSPParams);
            FrameD = FixedDSPDecimator(DSPParams);

            CoefficientFormat.WL = WholeD.CoeffWL;
            CoefficientFormat.IWL = WholeD.CoeffIWL;
            CoefficientFormat.FWL = WholeD.CoeffFWL;

            [InPadded, NumBlocks] = ...
                WholeD.FixedPrepareInput(InputCodes);

            [ReferenceCodes, ReferenceMACData] = ...
                WholeD.FixedDecimator( ...
                    InPadded, NumBlocks, ...
                    InputFormat, CoefficientFormat);

            MACFormat = FindMACFormat( ...
                InputFormat, ...
                CoefficientFormat, ...
                WholeD.BranchCoefficients, ...
                ReferenceMACData, ...
                1);

            [ExpectedCodes, ExpectedMACData] = ...
                WholeD.FixedDecimator( ...
                    InPadded, NumBlocks, ...
                    InputFormat, CoefficientFormat, MACFormat);

            [ActualCodes, ActualMACData, OutputSampleIndex] = ...
                testCase.processFixedFrames( ...
                    FrameD, InputCodes, [5 1 13 7 47], ...
                    InputFormat, CoefficientFormat, MACFormat);

            testCase.verifyEqual(ExpectedCodes, ReferenceCodes);
            testCase.verifyEqual(ActualCodes, ExpectedCodes);
            testCase.verifyEqual(ActualMACData, ExpectedMACData);
            testCase.verifyEqual( ...
                OutputSampleIndex, (0:NumBlocks-1)');

            %% ==========================================
            %% FIXED-POINT TO VOLTAGE-DOMAIN COMPARISON
            %% ==========================================

            [FixedCodeDomainSignal, ConvertedMACData] = ...
                FixedToRealConverter(ActualCodes, ActualMACData);

            ADCStep = Vfs / 2^NumBits;
            FixedVoltageSignal = ...
                FixedCodeDomainSignal(:) * ADCStep;

            FloatingD = DSP(DSPParams);
            FloatingOutput = ...
                FloatingD.ProcessFrame(QuantizedSignal, true);

            QuantizedCoefficientValues = ...
                double(FrameD.FixedFilterCoefficients(:)) / ...
                FrameD.CoeffScale;

            CoefficientErrorBound = ...
                max(abs(QuantizedSignal)) * ...
                sum(abs( ...
                    FloatingD.FilterCoefficients(:) - ...
                    QuantizedCoefficientValues)) + 1e-12;

            testCase.verifyEqual( ...
                double(InputCodes) * ADCStep, ...
                QuantizedSignal);

            testCase.verifyLessThanOrEqual( ...
                max(abs(FixedVoltageSignal - FloatingOutput)), ...
                CoefficientErrorBound);

            testCase.verifyEqual( ...
                ConvertedMACData.TotalAccumulatorOverflowCount, 0);
        end
    end

    methods (Access = private)
        function [OutputCodes, FinalMACData, OutputSampleIndex] = ...
                processFixedFrames( ...
                testCase, D, InputCodes, FrameLengths, ...
                InputFormat, CoefficientFormat, MACFormat)
            %% Process One Integer-Code Stream Using an Explicit Partition

            if sum(FrameLengths) ~= numel(InputCodes)
                error( ...
                    'TestADCFixedDSPDecimator:FrameLengthMismatch', ...
                    ['The frame lengths must contain every input code ', ...
                     'exactly once.']);
            end

            OutputCodes = zeros(1, 0, 'int64');
            FinalMACData = [];
            OutputSampleIndex = zeros(0, 1);
            StartIndex = 1;

            for k = 1:numel(FrameLengths)
                EndIndex = StartIndex + FrameLengths(k) - 1;
                InputFrame = InputCodes(StartIndex:EndIndex);
                IsLastFrame = k == numel(FrameLengths);

                [OutputFrame, FinalMACData, FrameInfo] = ...
                    D.ProcessFrame( ...
                        InputFrame, ...
                        IsLastFrame, ...
                        InputFormat, ...
                        CoefficientFormat, ...
                        MACFormat);

                OutputCodes = ...
                    [OutputCodes, OutputFrame]; %#ok<AGROW>

                OutputSampleIndex = [ ...
                    OutputSampleIndex; ...
                    FrameInfo.OutputSampleIndex]; %#ok<AGROW>

                StartIndex = EndIndex + 1;
            end

            testCase.verifyTrue(D.StreamFinalized);
        end
    end
end
