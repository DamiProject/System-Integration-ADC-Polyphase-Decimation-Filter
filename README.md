# Fixed Point Digital Signal Processing of A High-Speed Received Signal

**Status: Under Active Development**

## Overview

While the broader goal is processing a high-speed analog signal, this project simulates the environment in MATLAB; therefore, DSP techniques will be applied to its discrete signal to produce a target-rate digital signal output. To implement this, the system architecture will follow the pipeline shown in Figure 1. Additionally, for each module in the architecture, strict system specification criteria will be followed. Design and trade-off choices will be examined using numerical and spectral analyzers, and the results will be benchmarked.

---
### System Architecture Modules

**1. Signal Generator:** Produces a low SNR composite sinusoidal discrete signal consisting of a DC offset, 2 data signals, and a high interference signal. This acts as the discrete signal that will be processed to produce a target-rate digital signal output.

**2. Butterworth High Pass Filter (HPF):**  Attenuates DC offset in the received signal.

**3. Butterworth Low Pass Filter (LPF):**  Attenuates the high interference signal and guards against aliasing of the received signal.

**4. Automatic Gain Control (AGC) & Noise Gate:** Performs signal conditioning on the filtered signal to protect against the clipping and saturation at the Analog-to-Digital-Converter (ADC). 

**5. Analog-to-Digital-Converter (ADC):** Converts the discrete received signal to digital signal.

**6. Polyphase FIR Decimation Filter:** Processes the digital signal to achieve the intended target-rate digital output.

<img width="1000" height="700" alt="image" src="https://github.com/user-attachments/assets/42c814f7-81ac-411c-afec-6ec54ebcbcb7" />

**Figure 1: Complete signal processing pipeline from discrete simulation to decimated digital signal output.**

---
### How To Run

---
### Future Work

- Exploring more non-idealities that affect SNR, ENOB, DSP algorithms and techniques such as coloured noise impact.
- Exploring software and hardware oriented optimization.
- Exploring demodulation, equalization, and adaptive filtering techniques.


## Simulation, Results, & Analysis

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

### Signal Generation Simulation

To verify that the output of the signal generator produced the required low SNR signal specified in Table 1, the following DSP techniques were explored:

**1. Normalized Autocorrelation and Welch-Power Spectral Density (PSD):** Normalized autocorrelation was used to examine periodic structure within the noisy received signal, while Welch PSD was used to identify dominant spectral components and estimate how signal power is distributed across frequency. Figures 2 shows the normalized autocorrelation response with the corresponding component power measurements shown after cross correlation.

<img width="2248" height="1071" alt="Signal Generator - Autocorrelation Analysis" src="https://github.com/user-attachments/assets/699e3b66-26ff-4563-a4ea-39b86ff9768a" />

**Figure 2: Normalized autocorrelation sequence and Welch PSD of the received signal observation record.**

#### Analysis

As shown in Figure 2, the normalized autocorrelation sequence reaches unity at zero lag, as expected for a signal correlated with itself, while its near-zero values away from zero lag demonstrate the AWGN-dominated character of the received signal. Meanwhile, the PSD reveals the deterministic frequency components within the composite signal, corresponding to the DC offset, Data Signal 1, and the high-interference signal, although Data Signal 2 is not independently resolved. The approximately flat broadband PSD also confirms the presence of white noise.

#### Result

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

#### Benchmark

The signal generator satisfies its intended role as an AWGN-dominated received signal source. PSD analysis identifies the dominant spectral structure but does not independently resolve both closely spaced data signals under the configured low-SNR condition. Known-reference cross-correlation subsequently confirms both desired signals, while STFT analysis verifies their stationary and nonstationary time behaviour. Phase-spectrum analysis further characterizes the deterministic components within the random phase background produced by AWGN.

The numerical measurements in Figure 7 further validate the configured ground truth, measuring a 12.2943 V DC offset, 299.7891 V RMS broadband AWGN, and a 6.199951 GHz interferer. The measured input SNR of −26.431 dB and SINR of −26.442 dB confirm that the received waveform remains strongly noise dominated. Differences from the nominal power-ratio specifications are expected from the finite observation record, random AWGN realization, and the time-varying amplitude of Data Signal 1.

The signal-generator output is therefore accepted as the benchmark input to the HPF, LPF, AGC, ADC, and polyphase-decimation stages.

<img width="587" height="510" alt="image" src="https://github.com/user-attachments/assets/96152618-e782-4006-8769-fce428608c50" />

**Figure 7: Measurement summary of the signal generator module.**

<table>
  <tr>
    <td valign="top">
    
## Filtering Received Signal Processing 

### Proposed HPF System Specifications

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

### Proposed Anti-Aliasing LPF System Specifications

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

### Discrete Filtering (HPF/LPF) Simulation

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

#### Benchmark

| DC Attenuation (0 GHz)  | High Interference Attenuation (6.2 GHz)|
| :---: | :---: |
| <img width="70%" alt="image" src="https://github.com/user-attachments/assets/234f322a-f5fc-48d3-a819-a55b19e471bd" /> | <img width="70%" alt="image" src="https://github.com/user-attachments/assets/98513712-7c1a-4e2d-b598-39744f51a23e" />|

**Figure 18: Performance Summary of both Butterworth HPF and LPF meeting their respective proposed system specifications.**

| SNR & SINR After DC Attenuation (O GHz) | SNR & SINR After High Interference Attenuation (6.2 GHz)|
| :---: | :---: |
| <img width="200%" alt="image" src="https://github.com/user-attachments/assets/53542889-4949-4168-a42b-ec527523f180" /> | <img width="200%" alt="image" src="https://github.com/user-attachments/assets/7bc3977d-fdda-4d7b-8ca0-db24443e0fd0" />|

**Figure 19: Observed SNR & SINR improvement after the discrete filtering stage.**

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
