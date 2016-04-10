classdef PedestrianMotionModel
  
    properties (Access = private)
        timestep;
    end
    
    properties (Access = public)
        
        F;
        H;
            
        Q;
        R;
    end
    
    methods
        
        %% Constructor
        
        function obj = PedestrianMotionModel()
            
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

            obj.Q = diag([  1   1   5   5]);
            obj.R = diag([  1   1]);
        end
    end
    
end

