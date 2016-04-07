function [pedestrian, belongs_to] = contains(position_measurement, pedestrians, width, height)

    break_flag = false;
    
    m.position = [0; 0];
    m.time = 0;
    
    pedestrian = Pedestrian(m);
    belongs_to = false;
    
    for i = 1:length(pedestrians)
        
        measurements = pedestrians{i}.get_measurements();
        
        for j = 1:length(measurements)
            
            position_offset = position_measurement - pedestrians{i}.get_position();
           
            if (abs(position_offset(1)) <= width/2) && (abs(position_offset(2)) <= height/2)
                
                pedestrian = pedestrians{i};
                belongs_to = true;
                
                break_flag = true;
                break;
                
            end
        end
        
        if break_flag
            break;
        end
    end
end