classdef Pedestrian_motion_model
  
    properties (Access = private)
        timestep;
    end
    
    properties (Access = public)
        
        F;
        H;
            
        Q;
        R;
        P_0;
    end
    
    methods
        
        %% Constructor
        
        function obj = Pedestrian_motion_model()
            
            obj.timestep = 1;

            % Constant velocity motion model
            %
            % State:
            %   x
            %   y
            %   x speed
            %   y speed
            
            obj.F = [   1   0   obj.timestep    0;
                        0   1   0               obj.timestep;
                        0   0   1               0;
                        0   0   0               1];
            
            obj.H = [   1   0   0               0;
                        0   1   0               0];

            obj.Q   = 0.005 * diag([  3   3   5  5]);
            obj.R   = 5    * diag([  2   2]);
            obj.P_0 = diag([1 1 5 5]);                          % Unsure about speed of target, hence greate variance
        end
    end
    
end

