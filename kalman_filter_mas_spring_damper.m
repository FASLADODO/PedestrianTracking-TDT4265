
clc;
clear all;

%% Model

n = 2;

m = 1;
d = 2;
k = 5;

F = [ 0       1;
     -(k / m)  -(d / m)];
 
G = [0 0.5]';
W = 1;

H = [1 0];

%% Kalman matrices

T = 0.1;

% Discretization of process noise from van Loan method

A = [-F          G * W * G';
     zeros(n)    F'];
B = expm(T * A);

phi = B((n + 1):(2 * n), (n + 1):(2 * n));
phi = phi';

Q          = phi * B(1:n, (n + 1):(2 * n));
Q_kalman   = Q;

R          = 0.01;
R_kalman   = R;

%% Simulation initialization

t_start = 0;
t_stop = 10;

timespan = t_start:T:t_stop;

x       = nan(n, length(timespan));
x_noisy = nan(n, length(timespan));
z       = nan(1, length(timespan));

x(:, 1) = [1 0]';
x_noisy(:, 1) = x(:, 1);

%% Kalman initialization

x_a_priori       = nan(n, length(timespan));
x_a_posteriori   = nan(n, length(timespan));
x_a_priori(:, 1) = [2.5 0]';

P_a_priori = diag([1 1]);
P_a_posteriori = nan(2);

%% Simulation and filtering

for i = 1:(length(timespan) - 1)
    
    % Generate measurement
    
    z(i) = H * x(:, i) + sqrt(R) * randn();
    
    % Current step kalman posterior
    
    y = z(i) - H * x_a_priori(:, i);
    S = H * P_a_priori * H' + R_kalman;
    
    K = P_a_priori * H' * inv(S);
    
    x_a_posteriori(:, i) = x_a_priori(:, i) + K * y;
    P_a_posteriori       = (eye(n) - K * H) * P_a_priori;
    
    % Draw driving process noise
    
    C = chol(Q);
    w = C' * randn(2, 1);
    
    % Simulate true model one step ahead
    
    x(:, i + 1)       = phi * x(:, i);
    x_noisy(:, i + 1) = phi * x(:, i) + w;
  
    
    % Predict kalman filter mean and covariance one step ahead
    
    x_a_priori(:, i + 1) = phi * x_a_priori(:, i);
    P_a_priori = phi * P_a_posteriori * phi' + Q_kalman;
end

%% Display results

figure(1);
hold on;

plot(timespan, x(1, :), 'r');
plot(timespan, x_noisy(1, :), 'b');
plot(timespan, z, 'k');
plot(timespan, x_a_posteriori(1, :), 'y');
