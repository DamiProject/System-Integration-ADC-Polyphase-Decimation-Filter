%% =======================================================
%% HIGH-SPEED ADC-POLYPHASE DEMONSTRATION ORCHESTRATOR
%% =======================================================
% Run the approved signal-chain stages in physical processing order. Each
% stage receives and returns State, making every inter-stage dependency
% explicit without relying on variables left in the base workspace.

clear;
clc;
close all;

SetupPaths();

Config = HighSpeedDesignConfig();

%% ==========================================
%% STAGE PLOT VISIBILITY
%% ==========================================
% Processing and numerical measurements still run when a stage's plots
% are hidden. Change only the corresponding logical value to restore them.

ShowPlots.SignalGenerator = false;
ShowPlots.HPF = false;
ShowPlots.LPF = false;
ShowPlots.AGC = false;
ShowPlots.Sampler = false;
ShowPlots.Quantizer = false;
ShowPlots.ADCEncoder = false;
ShowPlots.Decimator = true;

%% ==========================================
%% SIGNAL GENERATOR
%% ==========================================

State = RunDemoSigGen( ...
    Config, ShowPlots.SignalGenerator);

%% ==========================================
%% DC-REMOVAL HIGH-PASS FILTER
%% ==========================================

State = RunDemoHPF( ...
    State, ShowPlots.HPF);

%% ==========================================
%% ANTI-ALIASING LOW-PASS FILTER
%% ==========================================

State = RunDemoLPF( ...
    State, ShowPlots.LPF);

%% ==========================================
%% AUTOMATIC GAIN CONTROL WITH NOISE GATING
%% ==========================================

State = RunDemoAGC( ...
    State, ShowPlots.AGC);

%% ==========================================
%% FRAME-BASED ADC SAMPLER
%% ==========================================

State = RunDemoSampler( ...
    State, ShowPlots.Sampler);

%% ==========================================
%% BIPOLAR MIDTREAD QUANTIZER
%% ==========================================

State = RunDemoQuantizer( ...
    State, ShowPlots.Quantizer);

%% ==========================================
%% ADC CODE ENCODER
%% ==========================================

State = RunDemoADCEncoder( ...
    State, ShowPlots.ADCEncoder);

%% ==========================================
%% FIXED-POINT POLYPHASE FIR DECIMATOR
%% ==========================================

State = RunDemoDecimator( ...
    State, ShowPlots.Decimator);
