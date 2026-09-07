# Fixed Point Digital Signal Processing of A High-Speed Received Signal

**Status: Under Active Development**

## Overview

While the broader goal is processing a high-speed analog signal, this project simulates the environment in MATLAB, therefore, DSP techniques will be applied to its discrete signal to produce a target-rate digital signal output. To implement this, the system architecture will follow the pipeline shown in Figure 1. Additionally, for each module in the architecture, strict system specification criteria will be followed. Design and trade-off choices will be examined using numerical and spectral analyzers, and the results will be benchmarked.

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

### Low-SNR Received Signal Test Specification

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

### Signal Generator Simulation

To verify that the output of the signal generator produced the required low SNR signal specified in Table 1, the following DSP techniques were explored:

**1. Normalized Autocorrelation and Welch-Power Spectral Density (PSD):** Normalized autocorrelation was used to examine periodic structure within the noisy received signal, while Welch PSD was used to identify dominant spectral components and estimate how signal power is distributed across frequency. Figures 2 show the normalized autocorrelation response,with the corresponding component power measurements shown after cross correlation.

<img width="2248" height="1071" alt="Signal Generator - Autocorrelation Analysis" src="https://github.com/user-attachments/assets/699e3b66-26ff-4563-a4ea-39b86ff9768a" />

**Figure 2: Normalized autocorrelation sequence and Welch PSD of the received signal observation record.**

#### Analysis

As shown in Figure 2, the normalized autocorrelation sequence reaches unity at zero lag, as expected for a signal correlated with itself, while its near-zero values away from zero lag demonstrate the AWGN-dominated character of the received signal. Meanwhile, the PSD reveals the deterministic frequency components within the composite signal, corresponding to the DC offset, Data Signal 1, and the high-interference signal, although Data Signal 2 is not independently resolved. The approximately flat broadband PSD also confirms the presence of white noise.

### Result

Through the autocorrelation sequence and Welch-PSD processing of the generated signal; the frequency components and their power were detected and closely match their ground truth equivalents. However, clear evidence of both Data Signal 1 and Data Signal 2 has not been achieved, although the PSD spectrum does show a dominant mainlobe near the desired signal band. Therefore, cross-correlation will be utilized next to isolate and detect the presence of both specific data signals.

**2. Normalized Cross-Correlation and Cross-Correlation Power Spectral Density:** Utilizing the properties of cross-correlation, detection of data 1 and data 2 was achieved by extracting them from the noise floor as seen in Figure 3.

<img width="2260" height="1074" alt="Signal Generator - Cross-Correlation Detection" src="https://github.com/user-attachments/assets/a5290ecc-357e-4492-8928-8ad4b03cf850" />

**Figure 3: Detected Data 1 and Data 2 signal using cross-correlation PSD spectrum.**

<img width="1472" height="197" alt="image" src="https://github.com/user-attachments/assets/0661a7c9-b9b7-4bf5-8764-5c9de8999220" />

**Figure 4: Welch-PSD-based component power, RMS amplitude, and equivalent peak-amplitude estimates for Data Signal 1, Data Signal 2, and high-interference signal.** 

**3. Short Time Fourier Transform (STFT):** Utilizing STFT to view how each frequency component of the signal changed over time the stationary behaviour of DC, Data Signal 2, and the high-interference signal was detected, while the non-stationary behaviour of Data Signal 1 was evident through the intensity of the colours and changes in the colour per time as seen in Figure 5.

<img width="2350" height="1074" alt="Signal Generator - Hamming STFT" src="https://github.com/user-attachments/assets/e4be1c82-345c-40dc-87ca-5fb603a05b27" />

**Figure 5: Frequency Components behaviour over time.**

**4. Phase Spectrum Analysis:** Characterized detected spectral components within the noisy received signal. The wrapped phase shows the random phase distribution of AWGN while preserving the principal-angle phase of deterministic components, whereas the unwrapped phase illustrates continuous phase evolution and the effect of 2π accumulation across noise-dominated bins. The detected 6.2 GHz narrowband interferer remains clearly identifiable at its measured phase location, as shown in Figure 6. 

<img width="2252" height="1074" alt="Signal Generator - Wrapped and Unwrapped Phase Spectrum" src="https://github.com/user-attachments/assets/27ca52dd-9c24-46ad-b3a6-da2fd6b75b72" />

**Figure 6: Frequency components wrapped and unwrapped phase angle.**

### Benchmark

The signal generator satisfies its intended role as an AWGN-dominated received signal source. PSD analysis identifies the dominant spectral structure but does not independently resolve both closely spaced data signals under the configured low-SNR condition. Known-reference cross-correlation subsequently confirms both desired signals, while STFT analysis verifies their stationary and nonstationary time behaviour. Phase-spectrum analysis further characterizes the deterministic components within the random phase background produced by AWGN.

The numerical measurements in Figure 7 further validate the configured ground truth, measuring a 12.2943 V DC offset, 299.7891 V RMS broadband AWGN, and a 6.199951 GHz interferer. The measured input SNR of −26.431 dB and SINR of −26.442 dB confirm that the received waveform remains strongly noise dominated. Differences from the nominal power-ratio specifications are expected from the finite observation record, random AWGN realization, and the time-varying amplitude of Data Signal 1.

The signal-generator output is therefore accepted as the benchmark input to the HPF, LPF, AGC, ADC, and polyphase-decimation stages.

<img width="587" height="510" alt="image" src="https://github.com/user-attachments/assets/96152618-e782-4006-8769-fce428608c50" />

**Figure 7: Measurement summary of the signal generator module.**



