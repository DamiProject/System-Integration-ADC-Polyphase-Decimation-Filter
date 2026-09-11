# Fixed Point Digital Signal Processing of A High-Speed Received Signal

**Status: Under Active Development**

## Overview

While the broader goal is processing a high-speed analog signal, this project simulates the environment in MATLAB; therefore, DSP techniques will be applied to its discrete signal to produce a target-rate digital signal output. To implement this, the system architecture will follow the pipeline shown in Figure 1. Additionally, for each module in the architecture, strict system specification criteria will be followed. Design and trade-off choices will be examined using numerical and spectral analyzers, and the results will be benchmarked.

---
### System Architecture Modules

**1. Signal Generator:** Produces a low SNR composite sinusoidal discrete signal consisting of a DC offset, 2 data signals, and a high interference signal. This acts as the discrete signal that will be processed to produce a target-rate digital signal output.

**2. Butterworth High Pass Filter (HPF):**  Attenuates DC offset in the received signal.

**3. Butterworth Low Pass Filter (LPF):**  Attenuates the high interference signal and guards against aliasing of the received signal.

**4. Automatic Gain Control (AGC) and Noise Gate:** Performs signal conditioning on the filtered signal to protect against the clipping and saturation at the Analog-to-Digital-Converter (ADC). 

**5. Analog-to-Digital-Converter (ADC) and Encoder:** Converts the discrete received signal to digital signal and produces fixed-point represented digital signal.

**6. Polyphase FIR Decimation Filter:** Processes the digital signal to achieve the intended target-rate digital output.

<img width="1000" height="700" alt="image" src="https://github.com/user-attachments/assets/42c814f7-81ac-411c-afec-6ec54ebcbcb7" />

**Figure 1: Complete signal processing pipeline from discrete simulation to decimated digital signal output.**

#### Benchmark

1. All implemented stages met their defined functional and performance requirements through stage-by-stage numerical and spectral verification.
2. The signal generator successfully produced the required stationary and non-stationary low-SNR received signals.
3. The non-stationary Gaussian-pulsed tones produced apparent IM2/IM3 spectral artifacts, caused by time-domain pulse multiplication and the resulting frequency-domain spectral broadening.
4. The HPF and LPF attenuated the measured IM2-associated spectral components, while the downstream AGC, Sampler, Quantizer, and Encoder introduced no material additional IM3 distortion.
5. The low SNR and closely spaced desired tones demonstrated the difficulty of achieving reliable frequency-component resolvability.
6. The mixed-signal chain successfully produced a signed fixed-point digital representation for downstream polyphase FIR decimation.

---
### How To Run

---
### Future Work

- Exploring more non-idealities that affect SNR, ENOB, DSP algorithms and techniques such as coloured noise impact.
- Exploring software and hardware oriented optimization.
- Exploring demodulation, equalization, and adaptive filtering techniques.


## Simulation, Results, and Analysis

---
### Low-SNR Received Signal

The signal chain is driven by a deliberately noise-dominated composite received waveform. The configured signal provides known ground truth for benchmarking the spectral, time-frequency, correlation, phase, filtering, AGC, ADC, and decimation analyses performed later in the demonstration.

<table>
  <tr>
    <td valign="top">
      
#### Desired Signal Components

| Characteristic | Data Signal 1 | Data Signal 2 |                     
|---|---:|---:|
| Carrier frequency | 1.000 GHz | 1.001 GHz |
| Nominal peak amplitude | 20 V | 12 V |
| Time behavior | Nonstationary | Stationary |
| Gaussian amplitude | +10 V | None |
| Gaussian-burst centre | 1.5 µs | — |
| Gaussian width, σ | 0.40 µs | — |
| Exponential-fade onset | 3.5 µs | — |
| Exponential decay rate | 1.2 × 10⁶ s⁻¹ | — |
| Exponential time constant, τ | 0.833 µs | — |

</td>
    <td valign="top">
    
#### Unknown Input Impairments Ground Truth

| Impairment | Specification |
|---|---:|
| DC offset | 12 V DC |
| Deterministic interference frequency | 6.2 GHz |
| Deterministic interference peak amplitude | 20 V |
| Additive white Gaussian noise RMS voltage | 300 V RMS |
| AWGN variance | 90,000 V² |
| Nominal desired-signal-to-AWGN ratio | ≈ -27.81 dB |
| Nominal desired-signal SINR | ≈ -27.82 dB |

</td>
  </tr>
</table>

**Table 1: Ground specifications against which the signal generator will be benchmarked.**

#### Signal Generation Simulation

To verify that the output of the signal generator produced the required low SNR signal specified in Table 1, the following DSP techniques were explored:

**1. Normalized Autocorrelation and Welch-Power Spectral Density (PSD):** Normalized autocorrelation was used to examine periodic structure within the noisy received signal, while Welch PSD was used to identify dominant spectral components and estimate how signal power is distributed across frequency. Figures 2 shows the normalized autocorrelation response with the corresponding component power measurements shown after cross correlation.

<img width="2248" height="1071" alt="Signal Generator - Autocorrelation Analysis" src="https://github.com/user-attachments/assets/699e3b66-26ff-4563-a4ea-39b86ff9768a" />

**Figure 2: Normalized autocorrelation sequence and Welch PSD of the received signal observation record.**

##### Analysis

As shown in Figure 2, the normalized autocorrelation sequence reaches unity at zero lag, as expected for a signal correlated with itself, while its near-zero values away from zero lag demonstrate the AWGN-dominated character of the received signal. Meanwhile, the PSD reveals the deterministic frequency components within the composite signal, corresponding to the DC offset, Data Signal 1, and the high-interference signal, although Data Signal 2 is not independently resolved. The approximately flat broadband PSD also confirms the presence of white noise.

##### Result

Through the autocorrelation sequence and Welch-PSD processing of the generated signal, the frequency components and their power were detected and closely match their ground truth equivalents. However, clear evidence of both Data Signal 1 and Data Signal 2 has not been achieved, although the PSD spectrum does show a dominant mainlobe near the desired signal band. Therefore, cross-correlation will be utilized next to isolate and detect the presence of both specific data signals.

**2. Normalized Cross-Correlation and Cross-Correlation Power Spectral Density:** Utilizing the properties of cross-correlation, detection of Data 1 and Data 2 was achieved by extracting them from the noise floor as seen in Figure 3.

<img width="2260" height="1074" alt="Signal Generator - Cross-Correlation Detection" src="https://github.com/user-attachments/assets/a5290ecc-357e-4492-8928-8ad4b03cf850" />

**Figure 3: Detected Data 1 and Data 2 signal using cross-correlation PSD spectrum.**

<img width="1472" height="197" alt="image" src="https://github.com/user-attachments/assets/0661a7c9-b9b7-4bf5-8764-5c9de8999220" />

**Figure 4: Welch-PSD-based component power, RMS amplitude, and equivalent peak-amplitude estimates for Data Signal 1, Data Signal 2, and high-interference signal.** 

**3. Short Time Fourier Transform (STFT):** Utilizing STFT to view how each frequency component of the signal changed over time, the stationary behaviour of DC, Data Signal 2, and the high-interference signal was detected, while the non-stationary behaviour of Data Signal 1 was evident through the intensity of the colours and changes in the colour per time as seen in Figure 5.

<img width="2350" height="1074" alt="Signal Generator - Hamming STFT" src="https://github.com/user-attachments/assets/e4be1c82-345c-40dc-87ca-5fb603a05b27" />

**Figure 5: Frequency Components behaviour over time.**

**4. Phase Spectrum Analysis:** Characterized detected spectral components within the noisy received signal. The wrapped phase shows the random phase distribution of AWGN while preserving the principal-angle phase of deterministic components, whereas the unwrapped phase illustrates continuous phase evolution and the effect of 2π accumulation across noise-dominated bins. The detected 6.2 GHz narrowband interferer remains clearly identifiable at its measured phase location, as shown in Figure 6. 

<img width="2252" height="1074" alt="Signal Generator - Wrapped and Unwrapped Phase Spectrum" src="https://github.com/user-attachments/assets/27ca52dd-9c24-46ad-b3a6-da2fd6b75b72" />

**Figure 6: Frequency components wrapped and unwrapped phase angle.**

##### Benchmark

The signal generator satisfies its intended role as an AWGN-dominated received signal source. PSD analysis identifies the dominant spectral structure but does not independently resolve both closely spaced data signals under the configured low-SNR condition. Known-reference cross-correlation subsequently confirms both desired signals, while STFT analysis verifies their stationary and nonstationary time behaviour. Phase-spectrum analysis further characterizes the deterministic components within the random phase background produced by AWGN.

The numerical measurements in Figure 7 further validate the configured ground truth, measuring a 12.2943 V DC offset, 299.7891 V RMS broadband AWGN, and a 6.199951 GHz interferer. The measured input SNR of −26.431 dB and SINR of −26.442 dB confirm that the received waveform remains strongly noise dominated. Differences from the nominal power-ratio specifications are expected from the finite observation record, random AWGN realization, and the time-varying amplitude of Data Signal 1.

The signal-generator output is therefore accepted as the benchmark input to the HPF, LPF, AGC, ADC, and polyphase-decimation stages.

<img width="587" height="510" alt="image" src="https://github.com/user-attachments/assets/96152618-e782-4006-8769-fce428608c50" />

**Figure 7: Measurement summary of the signal generator module.**

---   
#### Filtering Received Signal Processing 

  <table>
  <tr>
    <td valign="top">  
      
##### Proposed HPF System Specifications

| Requirement | Proposed Value |
|---|---:|
| Input sampling rate | 40 GS/s |
| Frame length | 8,192 samples |
| Desired tones to preserve | 1.000 GHz and 1.001 GHz |
| Stopband edge | 50 MHz |
| Minimum stopband attenuation| ≥ 40 dB |
| Passband edge | 500 MHz |
| Maximum passband loss| ≤ 0.10 dB |
| Desired-tone attenuation | ≤ 0.01 dB at each data tone |
| DC rejection | ≥ 40 dB after settling |
| Equivalent residual from the 12 V DC component | ≤ 0.12 V |
| DC-step settling time | ≤ 10 ns to within ±1% |
| Frame processing | Continuous IIR state across frame boundaries |
| Stability | Every digital pole strictly inside the unit circle |

</td>
    <td valign="top">

##### Proposed Anti-Aliasing LPF System Specifications

| Requirement | Proposed Value |
|---|---:|
| High-rate input sampling frequency | 40 GS/s |
| Processing frame length | 8,192 samples |
| Planned sampler downsampling factor | 4 |
| Resulting ADC sampling frequency | 10 GS/s |
| ADC Nyquist frequency to protect | 5.0 GHz |
| Desired tones to preserve | 1.000 GHz and 1.001 GHz |
| LPF passband edge | 1.25 GHz |
| Maximum passband loss | ≤ 0.10 dB |
| LPF stopband edge | 5.0 GHz |
| Minimum stopband attenuation | ≥ 60 dB |
| Maximum desired-tone attenuation | ≤ 0.01 dB at each tone |
| 6.2 GHz interferer attenuation | ≥ 60 dB |
| Step-response settling time | ≤ 5 ns to within ±1% |
| Maximum step overshoot | ≤ 20% |
| Stability | Every pole strictly inside the unit circle |
| Frame continuity | LPF state must persist across frame boundaries |

</td>
  </tr>
</table>

**Table 2: Ground specifications against which the HPF and LPF will be benchmarked.**

##### Discrete Filtering (HPF/LPF) Simulation

Starting with **HPF** which attenuates DC offset in the received signal, design choices and tradeoffs will be examined to verify that the proposed system specifications were achieved using the following DSP techniques:

**1. Butterworth IIR Filter Transient and Stability:** The IIR filter stability and transient response were verified using the pole-zero and step response shown in Figures 8 and 9. All digital poles remain strictly inside the unit circle, while the step response verifies that the DC attenuation transient will settle within the specified time.

<img width="90%" alt="DC Attenuation HPF - Pole-Zero Stability" src="https://github.com/user-attachments/assets/5d211614-6c57-4201-ad05-700af8ed6b28" />

 **Figure 8: HPF Pole-Zero plot for stability verification.**
 
<img width="90%" alt="DC Attenuation HPF - Step Settling" src="https://github.com/user-attachments/assets/d32f8aa3-7128-4d4d-893a-ab99b2df53a4" />

  **Figure 9: HPF Step Response plot for transient and settling time verification.**

**2. HPF Magnitude Response and Received Signal Spectrum:** Figures 10 and 11 verify the HPF frequency-domain behavior. The realized magnitude response satisfies the required low-frequency attenuation while approaching unity gain within the passband. Applying the HPF to the received waveform suppresses the DC and low-frequency region while producing negligible spectral change around the desired 1.000 GHz and 1.001 GHz data tones.

<img width="85%" alt="DC Attenuation HPF - Magnitude Response" src="https://github.com/user-attachments/assets/1b699874-384a-4df2-8da9-df16d05c1f28" />

**Figure 10: Butterworth HPF Magnitude Response.**

<img width="95%" alt="DC Attenuation HPF - Received-Signal Spectrum" src="https://github.com/user-attachments/assets/39f77531-8b4f-4406-8191-878961f97efd" />

**Figure 11: Received-Signal Spectrum Before and After HPF, Showing Low-Frequency Rejection and Desired Tone Preservation.**  

The **LPF** is an anti-aliasing filter that attenuates the high interference signal and guards against aliasing of the received signal. Design choices and tradeoffs will be examined to verify that the proposed system specifications were achieved using the following DSP techniques:

**1. Butterworth IIR Filter Transient and Stability:** The IIR filter stability and transient response were verified using the pole-zero and step response shown in Figures 12 and 13. All digital poles remain strictly inside the unit circle, while the step response verifies that the high interference attenuation transient will settle within the specified time.

<img width="87%" alt="Anti-Aliasing LPF - Pole-Zero Stability" src="https://github.com/user-attachments/assets/96876e99-a97b-4cf2-b672-5614201d7938" />

**Figure 12: LPF Pole-Zero plot for stability verification.**

<img width="87%" alt="Anti-Aliasing LPF - Step Response" src="https://github.com/user-attachments/assets/e6479e8a-4b1c-49ae-b515-e7f5135cab2f" />

**Figure 13: LPF Step Response plot for transient and settling time verification.**

**2. LPF Magnitude Response and Received Signal Spectrum:** Figures 14 and 15 verify the LPF frequency-domain behavior. The realized magnitude response satisfies the required high-frequency attenuation while approaching unity gain within the passband. Applying the LPF to the received waveform suppresses the high-frequency region while producing negligible spectral change around the desired 1.000 GHz and 1.001 GHz data tones.

<img width="1950" height="978" alt="Anti-Aliasing LPF - Magnitude Response" src="https://github.com/user-attachments/assets/96c09ba8-d621-4422-97b9-f60e76e0fd2a" />

**Figure 14: Butterworth LPF Magnitude Response.**

<img width="2260" height="1074" alt="Anti-Aliasing LPF - Received-Signal Spectrum" src="https://github.com/user-attachments/assets/d7d1d470-aa33-49d4-a8ba-bf96d3e34653" />

**Figure 15: Received-Signal Spectrum Before and After LPF, Showing High-Frequency Rejection and Desired Tone Preservation.** 

**3. LPF Phase Delay and Group Delay Response:** Figures 16 and 17 characterize the phase response of the Butterworth LPF. The phase and group delay vary with frequency, confirming the expected non-linear phase response of the IIR filter. Within the desired signal region, the closely spaced 1.000 GHz and 1.001 GHz tones which are in the same frequency band experience nearly the same delay, indicating minimal relative phase distortion between the two data components.

<img width="90%" alt="Anti-Aliasing LPF - Phase Delay" src="https://github.com/user-attachments/assets/de0411b7-a347-435b-a324-d5831f31d7cb" />

**Figure 16: Phase-Delay Response of the LPF Butterworth IIR Filter.**

<img width="80%" alt="image" src="https://github.com/user-attachments/assets/c54d80eb-9ef9-45e5-a968-7514bacc80ef" />

**Figure 17: Group-Delay Response of the LPF Butterworth IIR Filter.**

##### Benchmark

| DC Attenuation (0 GHz)  | High Interference Attenuation (6.2 GHz)|
| :---: | :---: |
| <img width="70%" alt="image" src="https://github.com/user-attachments/assets/234f322a-f5fc-48d3-a819-a55b19e471bd" /> | <img width="70%" alt="image" src="https://github.com/user-attachments/assets/98513712-7c1a-4e2d-b598-39744f51a23e" />|

**Figure 18: Performance Summary of both Butterworth HPF and LPF meeting their respective proposed system specifications.**

| SNR and SINR After DC Attenuation (O GHz) | SNR and SINR After High Interference Attenuation (6.2 GHz)|
| :---: | :---: |
| <img width="200%" alt="image" src="https://github.com/user-attachments/assets/53542889-4949-4168-a42b-ec527523f180" /> | <img width="200%" alt="image" src="https://github.com/user-attachments/assets/7bc3977d-fdda-4d7b-8ca0-db24443e0fd0" />|

**Figure 19: Observed SNR and SINR improvement after the discrete filtering stage.**

The HPF and LPF performance summaries in Figure 18 verify that both filters satisfy their proposed system specifications.

| Measurement | Requirement | Measured Result | Status |
|---|---:|---:|:---:|
| **HPF stopband attenuation** | ≥ 40 dB | 43.69 dB | PASS |
| **HPF DC rejection** | ≥ 40 dB | 74.09 dB | PASS |
| **HPF residual DC** | ≤ 0.12 V | ≈ 0.0024 V | PASS |
| **HPF settling time** | ≤ 10 ns | 5.60 ns | PASS |
| **HPF Data 1 loss** | ≤ 0.01 dB | 0.00157 dB | PASS |
| **HPF Data 2 loss** | ≤ 0.01 dB | 0.00156 dB | PASS |
| **HPF maximum pole radius** | < 1 | 0.97923 | PASS |
| **LPF passband loss** | ≤ 0.10 dB | 0.08529 dB | PASS |
| **LPF stopband attenuation** | ≥ 60 dB | 70.31 dB | PASS |
| **LPF 6.2 GHz attenuation** | ≥ 60 dB | 85.24 dB | PASS |
| **LPF Data 1 loss** | ≤ 0.01 dB | 0.00373 dB | PASS |
| **LPF Data 2 loss** | ≤ 0.01 dB | 0.00378 dB | PASS |
| **LPF settling time** | ≤ 5 ns | 1.775 ns | PASS |
| **LPF step overshoot** | ≤ 20% | 15.56% | PASS |
| **LPF maximum pole radius** | < 1 | 0.94451 | PASS |

**Table 3: Benchmark results showing that the 3<sup>rd</sup>-order Butterworth HPF and 7<sup>th</sup>-order Butterworth LPF meet the proposed system specifications.**

The HPF removes the large DC component while having almost no effect on the desired data tones. Since this stage mainly targets DC and does not attenuates the 6.2 GHz interferer or most of the broadband noise, the measured SNR and SINR improvement is small at about **+0.059 dB**. The LPF produces the major signal-quality improvement. It strongly attenuates the 6.2 GHz interferer and reduces the broadband-noise power by **11.826 dB**, while keeping both desired tones nearly unchanged. This improves SNR by **11.823 dB** and SINR by **11.834 dB** across the LPF stage. Across the complete HPF/LPF filtering chain, SNR improves from **-26.431 dB to -14.548 dB**, while SINR improves from **-26.442 dB to -14.548 dB**. This gives an overall improvement of approximately **11.88 dB SNR** and **11.89 dB SINR**, showing that the filtering stage attenuates the unwanted DC and high-frequency interference while preserving the desired 1.000 GHz and 1.001 GHz data signals.

---

#### Signal Conditioning 

| Requirement | Proposed Value |
|---|---:|
| Input sampling rate | 40 GS/s |
| Frame length | 8,192 samples |
| Input | LPF Output |
| ADC full-scale range | 2 V peak-to-peak (−1 V to +1 V) |
| Projected-envelope target window | 0.30 V to 0.75 V |
| Supported gain range | 0.001 to 10 (−60 dB to +20 dB) |
| Maximum gain-attack response | ≤ 20 ns |
| Maximum gain-release response | ≤ 0.25 µs |
| Target-window occupancy after acquisition | ≥ 99% |
| Maximum clipping rate | ≤ 0.01% outside ±1 V |
| Noise-gate opening time to gain ≥ 0.90 | ≤ 0.10 µs |
| Noise-gate closing time to gain ≤ 0.10 | ≤ 0.25 µs |
| Settled noise-gate suppression | ≥ 40 dB |
| Active-region SNR/SINR degradation | ≤ 0.5 dB |
| Frame processing | Preserve envelope, AGC gain, and gate gain across frames |
| Reporting | Before/after SNR, SINR, and their changes |

**Table 4: Proposed system specifications against which the AGC and Noise Gate are benchmarked.**

The **Noise Gate** acts as a control mechanism for the **discrete-time, time-varying AGC**. When the noise gate is open, the AGC is allowed to condition the received signal by increasing or reducing its gain as required. When the noise gate is closed, the AGC-controlled signal is strongly attenuated, reducing the amount of low-level noise passed to the downstream ADC. Design choices and tradeoffs will be examined to verify that the proposed system specifications were achieved using the following time-domain and spectral analysis plots including numerical analysis:

| AGC Gain Response | Noise Gate Gain Response|
| :---: | :---: |
| <img width="110%" alt="AGC - Gain Response" src="https://github.com/user-attachments/assets/1c85dfbf-fb32-4338-ad29-3db489e375b2" />|<img width="110%"  alt="AGC - Noise-Gate Response" src="https://github.com/user-attachments/assets/8da3b23c-3741-4804-8a31-3ce31460d18e" />|

**Figure 20: Time-domain dynamic gain tracking for the AGC and Noise Gate.** The AGC gain response shows the time-varying gain adjustment applied to regulate the received-signal envelope, while the noise-gate response shows that the detected envelope remains above the configured threshold and the gate stays open with a gain near unity. Together, the plots verify that the AGC performs the required gain conditioning while the noise gate allows the valid received signal to pass without false closure.

| AGC Envelope Detector | Desired-Signal Preservation|
| :---: | :---: |
|<img width="100%" alt="AGC-Envelope Regulation" src="https://github.com/user-attachments/assets/d22d9d10-00ed-4f0b-b1de-b2fcc4e2bb31" />|<img width="100%" alt="Data-Tone Preservation" src="https://github.com/user-attachments/assets/1ddc6a05-d719-45d7-81d4-ac909f26cfde" />|

**Figure 21: AGC Envelope Regulation and Desired-Signal Preservation.** The left plot shows that the AGC envelope detector tracks the high-amplitude received signal while the projected output envelope is regulated predominantly within the specified 0.30 V to 0.75 V target window. The right plot verifies the frequency-domain effect of the AGC using Welch PSD and Hamming-windowed FFT analysis. Although the AGC reduces the overall signal level, the desired 1.000 GHz and 1.001 GHz components remain clearly identifiable at their original frequencies, demonstrating preservation of the desired spectral structure without significant observable distortion around the signal band.

| AGC Input and Output Signal | AGC Compliance with ADC's Full Range|
| :---: | :---: |
|<img width="100%" alt="AGC-Received Signal Response" src="https://github.com/user-attachments/assets/30e91207-3016-413a-a36a-fa703c91a528" />|<img width="100%" alt="AGC - ADC Full Scale" src="https://github.com/user-attachments/assets/b2c30d99-24a8-49e1-8bcd-f39d43a27a4c" />| 

**Figure 22: AGC Time-Domain Conditioning and ADC Full-Scale Compliance.** The received-signal response shows the reduction of the high-amplitude LPF output through the time-varying AGC, followed by the final noise-gated output. The corresponding ADC full-scale compliance plot verifies that the conditioned waveform remains predominantly within the ±1 V ADC input range, with only approximately 0.00286% of samples exceeding full scale.

<img width="70%" alt="image" src="https://github.com/user-attachments/assets/07201591-9b5b-4745-8a1e-84f5004d4e74" />

**Figure 23: Numerical performance summary of the AGC and Noise Gate for the exercised received-signal specifications.**

<img width="70%" alt="image" src="https://github.com/user-attachments/assets/112e8bc6-51e2-47f3-b838-847239138160" />

**Figure 24: Observed SNR and SINR preservation after signal conditioning.**

##### Benchmark

The AGC operated across a wide 0.001 to 10 gain range (−60 dB to +20 dB) and was initialized at its minimum gain to safely accommodate the exceptionally large post-LPF input before recovering toward its operating level. The configured 4 ns attack and 22.4 ns release time constants provide asymmetric gain control: rapid gain reduction for large excursions and slower recovery to reduce unnecessary gain pumping in the noisy received waveform. The measured release response was approximately 25.68 ns, well within the specified 250 ns maximum response time.

The noise gate remained open/pass throughout the received record because the detected envelope stayed above the configured 10 V threshold, allowing the time-varying AGC to condition the valid signal without gate-induced interruption. The signal-quality measurements further showed only approximately 0.0304 dB degradation in both SNR and SINR, significantly below the permitted 0.5 dB, confirming that the conditioning stage primarily performs amplitude regulation without materially degrading the desired signal-to-noise relationship.

The noise-gate opening, closing, and settled-suppression requirements remain part of the proposed design specification but were not exercised by this continuously active received record and are therefore not reported as measured results in this benchmark.

#### ADC (Sampling and Quantization) and Encoding


  <table>
  <tr>
    <td valign="top">
      
##### Proposed Sampler System Specifications

Here, the 40 GS/s signal is the high-rate simulation reference. The sampler represents the physical ADC operating at 10 GS/s.

| Requirement | Proposed Value |
|---|---:|
| Input sampling rate | 40 GS/s |
| Downsampling factor | 4 |
| ADC output sampling rate | 10 GS/s |
| ADC Nyquist frequency | 5 GHz |
| Input frame length | 8,192 samples |
| Output samples per frame | 2,048 samples |
| Total input samples | 524,288 |
| Total sampled output | 131,072 samples |
| Sampling phase | Global indices `0, 4, 8, ...` |
| FFT frequency resolution | 76.294 kHz |
| Desired-tone frequency error | ≤ 1 FFT bin |
| Desired-tone level change | ≤ 0.25 dB |
| Maximum SNR degradation | ≤ 0.5 dB |
| Maximum SINR degradation | ≤ 0.5 dB |
| Frame-boundary behavior | Continuous global sampling phase |
| Sampling-clock model | Ideal; aperture jitter excluded |

</td>
    <td valign="top">
      
##### Proposed Bipolar Midtread Quantizer System Specifications

| Requirement | Proposed Value |
|---|---:|
| Input | Actual sampler output |
| Input rate | 10 GS/s |
| Input samples | 131,072 |
| Quantizer type | Uniform bipolar midtread |
| Resolution | 8 bits |
| Available codes | 256 (`0–255`) |
| Full-scale range | 2 Vpp (`−1 V` to `+1 V`) |
| Quantization step, Δ | 7.8125 mV |
| Zero representation | Exactly `0 V`, code `128` |
| Reconstructed range | `−1 V` to `+0.9921875 V` |
| Non-saturated error bound | ≤ Δ/2 = 3.90625 mV |
| Ideal quantization-noise power | Δ²/12 = 5.086 × 10⁻⁶ V² |
| Ideal quantization-error RMS | Δ/√12 = 2.255 mV |
| Minimum measured quantization-only SQNR | ≥ 38 dB |
| Maximum overloaded samples | ≤ 0.01% |
| Data-tone frequency error | ≤ 1 true-resolution bin = 76.294 kHz |
| Data-tone level change | ≤ 0.05 dB |
| Maximum SNR degradation | ≤ 0.10 dB |
| Maximum SINR degradation | ≤ 0.10 dB |
| Output rate/sample count | Unchanged from sampler |
</td>
  </tr>
</table>

**Table 5: Proposed system specifications against which the ADC sampler and quantizer will be benchmarked.**

##### Sampling

The downsampler reduces the high-rate 40 GS/s simulation reference to the target ADC sampling rate of 10 GS/s using a downsampling factor of 4. The implementation retains one sample from every four input samples while maintaining a continuous global sampling phase across frame boundaries. At this stage, an ideal sampling clock is assumed, therefore aperture jitter is excluded from the model.

The main design objective is to verify that the sampling-rate reduction preserves the desired 1.000 GHz and 1.001 GHz signal components without introducing significant amplitude, frequency, SNR, or SINR degradation. Since the resulting ADC sampling rate is 10 GS/s, the new Nyquist frequency is 5 GHz. Consequently, the preceding anti-aliasing LPF is required to sufficiently suppress spectral content above 5 GHz before sampling.

| Time-domain plot| Desired-Signal Preservation|
| :---: | :---: |
|<img width="100%" alt="Sampler - Time-Domain Sampling" src="https://github.com/user-attachments/assets/c28bd52e-4d86-4b91-bbd6-42ed2fb17391" />|<img width="100%" alt="Sampler - Spectral Preservation and Aliasing" src="https://github.com/user-attachments/assets/431eaa6d-8699-4baa-99d8-f7bb3172a2a6" />|

**Figure 25: Time-domain ADC sampling operation and frequency-domain verification of desired-signal preservation and alias suppression.**

##### Quantization

The sampled signal was quantized using an 8-bit uniform bipolar midtread quantizer with a 2 Vpp input range from −1 V to +1 V. The resulting 256 unsigned output codes span `0–255`, with code `128` representing exactly 0 V. A quantization step of 7.8125 mV was used, while samples exceeding the nominal full-scale range were clamped to the corresponding endpoint code rather than discarded.

**1. Quantization Error and Digital Code Mapping:** Figure 26 shows the quantizer input together with its reconstructed quantized waveform, the corresponding quantization error, and the generated unsigned ADC codes. The reconstructed waveform closely follows the sampler output while the interior code error remains within the expected ±Δ/2 bound. The measured maximum interior-code error of approximately 3.906 mV satisfies the theoretical half-step limit, while the measured RMS quantization error of approximately 2.278 mV remains close to the ideal value. The digital code response also confirms the expected bipolar midtread mapping, with code 128 corresponding to zero volts.

<img width="100%" alt="Bipolar Midtread Quantizer - Time and Code Response" src="https://github.com/user-attachments/assets/bcac820c-9697-4c87-a08f-132653152c4d" />

**Figure 26: Bipolar Midtread Reconstruction, RMS Quantization Error, and Unsigned Codes.**

**2. ADC Output-Code Distribution:** Figure 27 shows the distribution of the generated 8-bit ADC output codes across the processed signal. The histogram demonstrates broad utilization of the available conversion range without sustained accumulation at either endpoint. Only 3 of 131,072 input samples exceeded the nominal full-scale limits, corresponding to approximately 0.0023% overload and remaining below the specified 0.01% maximum. This confirms that the preceding AGC stage provides sufficient ADC headroom while still allowing effective use of the available quantization range.

<img width="100%" alt="Bipolar Midtread Qunatizer - Code Histogram" src="https://github.com/user-attachments/assets/aa999595-7f21-469f-bfe5-62be3696cb1a" />

**Figure 27: ADC Output Code Distribution.**

**3. Spectral Preservation Through Quantization:** Figure 28 compares the quantizer input and output in both the Hamming-Welch PSD and the resolved Data 1/Data 2 frequency region. The desired data components remain aligned before and after quantization, confirming that the quantizer introduces no measurable frequency displacement of either tone. Their spectral levels are also effectively preserved, indicating negligible distortion of the desired signal components at the selected 8-bit resolution. Toward the upper end of the ADC Nyquist band, the quantized output PSD rises above the quantizer input PSD. This occurs because the filtered input noise floor continues to decrease with frequency while the approximately broadband quantization noise introduced by the ADC establishes its own output noise floor. The separation therefore represents the expected quantization noise contribution rather than a shift or distortion of the desired data tones.

<img width="100%" alt="Bipolar Midtread Quantizer - Spectral Preservation" src="https://github.com/user-attachments/assets/849a045c-5793-4890-b628-8a7166b54651" />

**Figure 28. Quantizer Spectral Preservation.**

**4. Intermodulation Distortion:** The two desired data tones were also evaluated for second- and third-order intermodulation products before and after quantization. The worst measured IM2 component changed from −28.850 dBc to −28.917 dBc, corresponding to a −0.067 dB change, while the worst IM3 component changed from −17.553 dBc to −17.568 dBc, corresponding to a −0.015 dB change. The negligible before-to-after variation confirms that the 8-bit quantization stage does not materially increase the intermodulation products already present at its input.

<img width="100%" alt="image" src="https://github.com/user-attachments/assets/ba8557a0-9041-40b9-a862-1ca8c1141191" />

**Figure 29: Recorded Intermodulation Distortion After ADC Quantization.**

### Encoding
Converts the ADC output codes into a signed two’s-complement representation for the downstream fixed-point DSP chain. The conversion is lossless, with the decoded two’s-complement signal reproducing the quantized voltage without introducing additional distortion. Therefore, this produces the fixed point represented input the polyphase decimation filter will be performing filtering on.

<img width="80%" alt="ADC Encoder" src="https://github.com/user-attachments/assets/25b91f33-6ae5-40f0-b7f3-3c96872808bc" />

**Figure 30: Offset Binary, Two's Complement, and Signal Reconstruction of the Digital Signal.**

### Benchmark

| ADC Sampler | ADC Quantizer| ADC Encoder|
| :---: | :---: | :---: |
|<img width="100%" alt="image" src="https://github.com/user-attachments/assets/8709a0f1-d7b2-4df1-94c0-0d08a66277bb" />|<img width="100%" alt="image" src="https://github.com/user-attachments/assets/bd59aa39-5a87-4ae3-917e-b9310107e348" />| <img width="100%" alt="image" src="https://github.com/user-attachments/assets/702ef76b-e0e8-4af0-83e9-2a853168ce6f" />|

**Figure 31: ADC Sampler, Quantizer, and Encoder Recorded Performance Summary.**

| ADC Sampler SNR/SINR | ADC Quantizer SNR/SINR | ADC Encoder SNR/SINR|
| :---: | :---: | :---: |
|<img width="130%" alt="image" src="https://github.com/user-attachments/assets/6686d0f8-3ac5-45fb-a0cf-7cf2206c7f8b" />|<img width="130%" alt="image" src="https://github.com/user-attachments/assets/08f22da2-bb2a-4fac-9318-a607856f7982" />|<img width="130%" alt="image" src="https://github.com/user-attachments/assets/c19a8522-ee89-4b01-ac81-079ff27f3151" />|

**Figure 32: SNR and SINR Report Summary of ADC Sampler, Quantizer, and Encoder.** 

The ADC chain met the proposed sampling, quantization, and encoding requirements. The sampler reduced the 40 GS/s simulation reference to 10 GS/s with continuous frame-to-frame sampling and negligible SNR/SINR change of approximately −0.000004 dB. The 8-bit bipolar midtread quantizer achieved 40.14 dB SQNR, 2.278 mV RMS error, 3.906 mV maximum interior code error, and only 0.0023% overload, while introducing negligible SNR/SINR and intermodulation change.

The encoder then converted the quantized output to signed 8-bit two’s-complement with no added or dropped samples and exactly 0 dB SNR/SINR change, confirming lossless handoff into the downstream fixed-point polyphase decimator.

#### FIR Polyphase Decimation Filter

### Proposed Polyphase Decimator System Specifications

| Requirement | Proposed Value |
|---|---:|
| Input format | Signed `int8`, two's-complement, Q8.0 |
| Voltage scaling | 7.8125 mV/code |
| Input sample rate | 10 GS/s |
| Decimation factor | 4 |
| Target output rate | 2.5 GS/s |
| Output Nyquist frequency | 1.25 GHz |
| Input/output frame size | 2,048 → 512 samples |
| Input/output record size | 131,072 → 32,768 samples |
| Desired tones | 1.000 GHz and 1.001 GHz |
| Passband edge | 1.10 GHz |
| Stopband edge | 1.25 GHz |
| Maximum passband ripple | ≤ 0.10 dB |
| Minimum stopband attenuation | ≥ 60 dB |
| Maximum desired-tone loss | ≤ 0.10 dB per tone |
| Frequency error | ≤ 1 true-record FFT bin, approximately 76.3 kHz |
| Alias-band protection | ≥ 60 dB from 1.25–5 GHz |
| Critical alias case | Suppress 3.8 GHz before it folds to 1.2 GHz |
| Filter phase | Type-I linear phase |
| Maximum group delay | ≤ 15 ns |
| Accumulator headroom | ≥ 1 additional integer bit |
| Accumulator overflow | Zero events |
| Fixed-vs-floating error SNR | ≥ 60 dB |
| Polyphase MAC reduction | ≥ 70% versus direct FIR filtering |
| Full-band SNR improvement target | ≥ 5.5 dB |
| Full-band SINR improvement target | ≥ 5.5 dB |
