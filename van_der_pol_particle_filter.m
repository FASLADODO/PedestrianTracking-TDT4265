
%% Particle filter shell

function van_der_pol_particle_filter()
   
    clc;
    clear all;
    close all;

    % Simulation parameters

    pause_step = 20;
    pause_time = 0.1;
    
    h = 0.01;
    
    t_start = 0;
    t_stop = 10;
    
    t = t_start:h:t_stop;
    
    % Simulation model initialization
    
    x       = nan(2, length(t));
    x(:, 1) = [0 1]';
    
    % Sensor model: gaussian, no bias
    
    sensor_bias = [0 0]';
    sensor_sigma = 0.005 * diag([1 1]);
    
    sensor_readings = nan(2, length(t));
    
    % Initialization of particles
    
    N = 50;
    
    particles = nan(2, N, length(t));
    particles(:, :, 1) = rand(2, N) + repmat([-0.5 0.5]', 1, N);
    
    particle_noise_mu = [0 0];
    particle_noise_sigma = 0.01 * diag([1 1]);
    
    % Simulate
    
    display_x_sensor_readings_and_particles(x, sensor_readings, particles, 1);
    pause(pause_time);
    
    for i = 2:length(t)
        
        % Increment underlying model
        
        x(:, i) = van_der_pol_increment(x(:, i - 1), h); 
        
        % Make sensor reading
        
        sensor_readings(:, i) = mvnrnd(x(:, i) + sensor_bias, sensor_sigma, 1);
        
        % ----------------------------------------------
        % Particle filter
        
        % Predict and add noise
        
        particle_x = nan(2, N);
        particle_w = nan(1, N);
        
        for j = 1:N
           particle_x(:, j) = van_der_pol_increment(particles(:, j, i - 1), h);
           particle_x(:, j) = particle_x(:, j) + mvnrnd(particle_noise_mu, particle_noise_sigma, 1)';
        end
        
        % Weight
        
        for j = 1:N
           particle_w(j) = mvnpdf(sensor_readings(:, i), particle_x(:, j), sensor_sigma);
        end
        
        % Normalize weights
        
        particle_w = particle_w / norm(particle_w);
        
        % Resample
        
        particle_c = nan(length(particle_w), 1);
        particle_c(1) = particle_w(1);
        
        for j = 2:length(particle_w)
            particle_c(j) = particle_c(j - 1) + particle_w(j);
        end
        
        r = rand() * (1 / N) * max(particle_c);
        z = 1;
        
        for j = 1:N
            
            while (particle_c(z + 1) < r && z < N)
                z = z + 1;
            end
            
            particles(:, j, i) = particle_x(:, z);
            r = r + (1 / N) * max(particle_c);
        end
        
        % Particle filter
        % ----------------------------------------------
        
        % Show simulation, sensor readings and particle filter
        
        if (mod(i, pause_step) == 0)
            
            display_x_sensor_readings_and_particles(x, sensor_readings, particles, i);
            pause(pause_time);
        end
    end
    
    % Plot results
    
    display_x_sensor_readings_and_particles(x, sensor_readings, particles, length(t));
end

%% Display state, sensor and particles

function display_x_sensor_readings_and_particles(x, sensor_readings, particles, i)
    
    figure(1);
    clf;
    hold on;

    plot(x(1, :), x(2, :), 'b');
    plot(sensor_readings(1, 1:i), sensor_readings(2, 1:i), 'ko');
    plot(particles(1, :, i), particles(2, :, i), 'rx');
    
    axis([-3 3 -5 5]);
end

%% Van der Pol state space
% Gaussian driving noise on change in speed

function x_t_1 = van_der_pol_increment(x_t, h)
    
    mu = 2;
    
    x = x_t(1);
    dx = x_t(2);
    
    x_t_1 = [0 0]';
    
    u = randn();

    x_t_1(1) = x + h * dx;
    x_t_1(2) = dx + h * (mu * (1 - x * x) * dx - x + u);
end