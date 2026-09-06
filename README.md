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

- Exploring more non-idealities that affects SNR, ENOB, DSP algorithms and techniques such as coloured noise impact.
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

**Table 1 outlines the ground specifications against which the signal generator will be benchmarked.**

### Signal Generator Simulation

To verify that the output of the signal generator produced the required low SNR signal specified in Table 1, the following DSP techniques were explored:

**1. Normalized Autocorrelation and Autocorrelation Power Spectral Density (PSD):** The property of autocorrelation was used to detect periodicity and its PSD was used to detect frequency components within the signal. Figure 2 shows the result of the autocorrelation sequence.

<img width="2248" height="1071" alt="Signal Generator - Autocorrelation Analysis" src="https://github.com/user-attachments/assets/699e3b66-26ff-4563-a4ea-39b86ff9768a" />

**Figure 2 shows the normalized autocorrelation sequence and PSD of the generated signal.**

#### Analysis

As seen in Figure 2, the normalized autocorrelation sequence produced a correlation of 1 at zero-lag time, indicating that the signal generator produced a composite signal that is sinusoidal, periodic, and noise-dominated. Meanwhile, the PSD spectrum reveals the frequency components within the composite signal. These correspond to the DC offset, Data Signal 1, and the high interference signal, though Data Signal 2 is missing. The PSD also confirms the noise is Additive White Gaussian Noise (AWGN) due to its flat spectral density.

Furthermore, the numerical analysis using the Welch-PSD approach (shown in Figure 3) demonstrates that the broadband AWGN RMS estimation was highly accurate, resulting in just a 0.0703% relative error. The DC magnitude estimation was slightly less precise with a 6.73% error. This higher error at DC is expected, as narrowband power estimation is highly sensitive to windowing choices and the finite length of the data record.

<img width="432" height="218" alt="image" src="https://github.com/user-attachments/assets/b44fa092-42e2-44dc-80f2-c77a6ff6a25c" />

**Figure 3 shows the numerical analysis of the autocorrelation PSD.**

### Result

Through the autocorrelation sequence processing of the generated signal, the high interference signal, noise power, and DC power were detected and closely match their ground truth equivalents. However, clear evidence of both Data Signal 1 and Data Signal 2 has not been achieved, although the PSD spectrum does show a mainlobe at 1.0001 GHz. Therefore, cross-correlation will be utilized next to isolate and detect the presence of both specific data signals.

**2. Normalized Cross-Correlation and Cross-Correlation Power Spectral Density:** Utilizing the properties of cross-correlation, detection of data 1 and data 2 was achieved by extracting them from the noise floor as seen in Figure 4.

<img width="2260" height="1074" alt="Signal Generator - Cross-Correlation Detection" src="https://github.com/user-attachments/assets/a5290ecc-357e-4492-8928-8ad4b03cf850" />

**Figure 4 shows the detected data 1 and data 2 signal using cross-correlation PSD spectrum.**

**3. Short Time Fourier Transform (STFT):** 
4. Unwrapped Phase Spectrum Analysis

