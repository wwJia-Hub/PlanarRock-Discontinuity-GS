% ---------------------------------------------------------------------------------------------------------------------- % 

% Newton-Raphson Search Rule Function
function NRSR = SearchRule(Best_Pos, Worst_Pos, Position, rho, Flag)
    % Inputs:
    % Best_Pos, Worst_Pos   - Best and worst positions in the population
    % Position              - Current position
    % rho                   - Step size
    % Flag                  - Indicator for search rule application

    dim = size(Position, 2); % Number of dimensions
    DelX = rand(1, dim) .* abs(Best_Pos - Position); % Delta X for search rule

    % Initial Newton-Raphson step
    NRSR = randn * ((Best_Pos - Worst_Pos) .* DelX) ./ (2 * (Best_Pos + Worst_Pos - 2 * Position));  

    % Adjust position based on flag
    if Flag == 1
        Xa = Position - NRSR + rho;                                   
    else
        Xa = Best_Pos - NRSR + rho;
    end    

    % Further refine the Newton-Raphson step
    r1 = rand; r2 = rand; 
    yp = r1 * (mean(Xa + Position) + r1 * DelX);                   
    yq = r2 * (mean(Xa + Position) - r2 * DelX);                   
    NRSR = randn * ((yp - yq) .* DelX) ./ (2 * (yp + yq - 2 * Position));  
end