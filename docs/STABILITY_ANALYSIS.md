# Frequency Stability and Time Wander Metrology

This document explains the mathematical foundations of frequency stability metrics implemented in Escapement: Allan Deviation (ADEV), Modified Allan Deviation (MDEV), Time Deviation (TDEV), and Maximum Time Interval Error (MTIE).

## 1. Phase and Frequency Fluctuations

Let $x(t)$ denote the continuous phase time error (in seconds) between the device under test (DUT) and an ideal reference clock. The fractional frequency fluctuation $y(t)$ is defined as:

$$y(t) = \frac{d x(t)}{dt}$$

Given discrete phase measurements $x_k = x(t_0 + k \tau_0)$ sampled at uniform cadence $\tau_0$, the average fractional frequency over interval $[t_k, t_k + \tau]$ where $\tau = m \tau_0$ is:

$$\bar{y}_k(\tau) = \frac{x_{k+m} - x_k}{\tau}$$

## 2. Standard Allan Deviation (ADEV)

Standard variance diverges for flicker frequency noise and random walk frequency noise. The two-sample Allan variance $\sigma_y^2(\tau)$ provides a convergent measure of frequency stability:

$$\sigma_y^2(\tau) = \frac{1}{2(N - 2m)} \sum_{k=0}^{N - 2m - 1} (\bar{y}_{k+m}(\tau) - \bar{y}_k(\tau))^2$$

In terms of phase samples $x_k$:

$$\sigma_y^2(\tau) = \frac{1}{2 \tau^2 (N - 2m)} \sum_{k=0}^{N - 2m - 1} (x_{k+2m} - 2x_{k+m} + x_k)^2$$

Allan Deviation is defined as the square root of Allan variance:
$$\sigma_y(\tau) = \sqrt{\sigma_y^2(\tau)}$$

## 3. Modified Allan Deviation (MDEV)

Standard Allan deviation cannot distinguish between white phase modulation (WPM) and flicker phase modulation (FPM). The Modified Allan variance $\text{Mod }\sigma_y^2(\tau)$ incorporates an additional internal phase averaging step:

$$\text{Mod }\sigma_y^2(\tau) = \frac{1}{2 m^2 \tau^2 (N - 3m + 1)} \sum_{j=0}^{N - 3m} \left( \sum_{i=j}^{j+m-1} (x_{i+2m} - 2x_{i+m} + x_i) \right)^2$$

$$\text{MDEV}(\tau) = \sqrt{\text{Mod }\sigma_y^2(\tau)}$$

## 4. Time Deviation (TDEV)

Time deviation converts the dimensionless Modified Allan deviation into units of time (seconds), characterizing phase wander over observation period $\tau$:

$$\text{TDEV}(\tau) = \frac{\tau}{\sqrt{3}} \cdot \text{MDEV}(\tau)$$

## 5. Maximum Time Interval Error (MTIE)

MTIE measures the peak-to-peak phase wander within sliding observation windows of duration $\tau = m \tau_0$. It evaluates worst-case phase swings:

$$\text{MTIE}(\tau) = \max_{0 \le i \le N - m} \left( \max_{i \le k \le i + m} x_k - \min_{i \le k \le i + m} x_k \right)$$

### ITU-T G.811 Primary Reference Clock (PRC) Mask Limits
For telecommunication synchronization networks, ITU-T Recommendation G.811 specifies the maximum permitted MTIE for Primary Reference Clocks:

$$\text{Limit}(\tau) = \begin{cases} 
52.5\text{ ns} & \text{for } 0.1 \le \tau \le 100\text{ s} \\
0.275 \cdot \tau + 25\text{ ns} & \text{for } 100 < \tau \le 1000\text{ s} \\
300\text{ ns} & \text{for } \tau > 1000\text{ s}
\end{cases}$$
