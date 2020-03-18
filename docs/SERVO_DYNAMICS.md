# Clock Servo Dynamics and Filter Mathematical Formulation

This document details the mathematical derivation of the clock servo algorithms implemented in Escapement: the Proportional-Integral (PI/PID) servo with anti-windup clamping, and the 2-State Discrete Kalman Filter.

## 1. Physical Clock Drift Model

A physical local crystal oscillator exhibits phase error $\theta(t)$ and frequency drift $\omega(t)$ governed by:

$$\frac{d\theta(t)}{dt} = \omega(t) + w_\theta(t)$$
$$\frac{d\omega(t)}{dt} = -\frac{1}{\tau_c}\omega(t) + w_\omega(t)$$

where:
- $\theta(t)$ is the instantaneous phase error (in nanoseconds).
- $\omega(t)$ is the relative frequency offset (fractional frequency offset in parts per billion, ppb).
- $w_\theta(t)$ is white phase noise (WPM).
- $w_\omega(t)$ is white frequency noise (random walk frequency, RWFM).
- $\tau_c$ is the correlation time constant for crystal thermal wander.

## 2. Proportional-Integral (PI/PID) Servo with Anti-Windup Clamping

The PI servo calculates a frequency tuning command $u_k$ (in parts-per-billion) applied to the local clock hardware:

$$e_k = \theta_{\text{measured}, k}$$
$$P_k = K_p \cdot e_k$$
$$I_k = I_{k-1} + K_i \cdot e_k \cdot \Delta t$$
$$D_k = K_d \cdot \frac{e_k - e_{k-1}}{\Delta t}$$
$$u_k = \text{clamp}(P_k + I_k + D_k, -u_{\max}, u_{\max})$$

### Anti-Windup Integrator Clamping
To prevent integrator windup when large transit delay transients or packet queueing bursts occur, the accumulated integral state $I_k$ is clamped at each epoch before computing the total control effort:

$$I_k \leftarrow \max(-u_{\max}, \min(u_{\max}, I_k))$$

This ensures that once network transients subside, the loop filter immediately resumes tracking without experiencing severe phase overshoots.

## 3. 2-State Discrete Kalman Filter Formulation

When network packet jitter is significant, a linear quadratic Gaussian estimator (Kalman filter) provides optimal phase and frequency drift estimates by separating transit delay noise from physical clock wander.

### State Vector and Transition Matrix
The continuous clock dynamics are discretized with observation interval $\Delta t$:

$$x_k = \begin{bmatrix} \theta_k \\ \omega_k \end{bmatrix} \in \mathbb{R}^2$$

The state transition matrix $F$ and control input matrix $B$ are:

$$F = \begin{bmatrix} 1 & \Delta t \\ 0 & 1 \end{bmatrix}, \quad B = \begin{bmatrix} 0 \\ -\Delta t \end{bmatrix}$$

### Process Noise Covariance Matrix $Q$
The process noise matrix models physical oscillator wander:

$$Q = \begin{bmatrix} q_\theta \Delta t + \frac{1}{3} q_\omega \Delta t^3 & \frac{1}{2} q_\omega \Delta t^2 \\ \frac{1}{2} q_\omega \Delta t^2 & q_\omega \Delta t \end{bmatrix}$$

In Escapement, default process parameters for typical TCXO/OCXO oscillators are $q_\theta = 0.1\text{ ns}^2/\text{s}$ and $q_\omega = 0.01\text{ (ppb)}^2/\text{s}$.

### Measurement Model
The PTP protocol measures phase offset with measurement variance $R$:

$$z_k = H x_k + v_k, \quad H = \begin{bmatrix} 1 & 0 \end{bmatrix}, \quad R = \sigma_{\text{jitter}}^2$$

### Prediction Phase
At epoch $k$, state and covariance predictions are computed:

$$\hat{x}_{k|k-1} = F \hat{x}_{k-1|k-1}$$
$$P_{k|k-1} = F P_{k-1|k-1} F^T + Q$$

Explicit scalar expansion:
$$p_{00}' = p_{00} + \Delta t(p_{10} + p_{01}) + \Delta t^2 p_{11} + q_\theta$$
$$p_{01}' = p_{01} + \Delta t p_{11}$$
$$p_{10}' = p_{10} + \Delta t p_{11}$$
$$p_{11}' = p_{11} + q_\omega$$

### Correction Phase
The innovation residual $y_k$ and innovation covariance $S_k$ are:

$$y_k = z_k - H \hat{x}_{k|k-1} = z_k - \hat{\theta}_{k|k-1}$$
$$S_k = H P_{k|k-1} H^T + R = p_{00}' + R$$

The optimal Kalman gain $K_k$ is:

$$K_k = \begin{bmatrix} K_0 \\ K_1 \end{bmatrix} = \frac{1}{S_k} \begin{bmatrix} p_{00}' \\ p_{10}' \end{bmatrix}$$

The state and error covariance updates:

$$\hat{x}_{k|k} = \hat{x}_{k|k-1} + K_k y_k$$
$$P_{k|k} = (I - K_k H) P_{k|k-1}$$
