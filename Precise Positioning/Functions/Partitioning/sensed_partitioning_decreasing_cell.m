% Copyright 2017 Sotiris Papatheodorou
% 
% Licensed under the Apache License, Version 2.0 (the \"License\");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%    http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an \"AS IS\" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

function W = sensed_partitioning_decreasing_cell(region, a, b, X, Y, Z, C, f_u, i, PPC)

N = length(X);
R = zeros(1,N);
R(i) = Z(i) * tan(a);

if nargin < 10
    PPC = 60;
end

% Initialize cell to sensing disk
W = C{i};


% Loop over all other nodes
for j=1:N
    if j ~= i
        % Find radius
        R(j) = Z(j) * tan(a);
        
        if Z(i) == Z(j)
            % Degenerate case, split the common region at the
            % intersection points
            % Find intersection points
            [xx, yy, ii] = polyxpoly( C{i}(1,:), C{i}(2,:),...
                        C{j}(1,:), C{j}(2,:) );
            % only if the sensing circles intersect
            if ~isempty(xx)
                % Add the intersection points
                Ci = C{i};
                for k=1:length(xx)
                    % assuming ii is sorted
                    Ci = [Ci(:,1:ii(k)+(k-1)) [xx(k) ; yy(k)] ...
                        Ci(:,ii(k)+k:end)];
                end
                % Remove the points of Ci that are inside Cj
                [inCj, onCj] = inpolygon( Ci(1,:), Ci(2,:),...
                    C{j}(1,:), C{j}(2,:) );
                Ci = Ci(:, ~inCj | onCj);
                % Polybool the new Ci with Wi
                [pbx, pby] = polybool( 'and', W(1,:), W(2,:),...
                    Ci(1,:), Ci(2,:) );
                W = [pbx ; pby];
            end
        else
            % Remove a portion of the sensing disk if zi ~= zj
            % Create the Intersection Circle
            Ki = (1-b) / R(i)^2;
            Kj = (1-b) / R(j)^2;
            ICx = (Ki*f_u(i)*X(i) - Kj*f_u(j)*X(j)) / (Ki*f_u(i) - Kj*f_u(j));
            ICy = (Ki*f_u(i)*Y(i) - Kj*f_u(j)*Y(j)) / (Ki*f_u(i) - Kj*f_u(j));
            ICr = sqrt( ICx^2 + ICy^2 + (-Ki*f_u(i)*(X(i)^2 + Y(i)^2)...
                + Kj*f_u(j)*(X(j)^2 + Y(j)^2) + f_u(i)-f_u(j)) / (Ki*f_u(i) - Kj*f_u(j)));
            % If the radius of IC is large, use more points for
            % the creation of IC
            ep = floor(2*ICr/(R(i)+R(j)));
            tt = linspace(0, 2*pi, (ep+1)*PPC+1);
            tt = tt(1:end-1); % remove duplicate last element
            tt = fliplr(tt); % flip to create CW ordered circles
            IC = [ICx + ICr * cos(tt) ; ICy + ICr * sin(tt)];

            % If i is the dominant node, intersect
            if Z(i) < Z(j)
                    [pbx, pby] = polybool( 'and', W(1,:), W(2,:),...
                        IC(1,:), IC(2,:) );
            % else remove the intersection of Cj with IC
            else
                    [pbx, pby] = polybool( 'and', C{j}(1,:), C{j}(2,:),...
                        IC(1,:), IC(2,:) );
                    [pbx, pby] = polybool( 'minus', W(1,:), W(2,:),...
                        pbx, pby );
            end

            % Change the currecnt cell
            W = [pbx ; pby];
        end % Z(i),Z(j) check
    end % j~=i
end % for j

% AND with the region omega
[pbx, pby] = polybool( 'and', W(1,:), W(2,:), region(1,:), region(2,:) );
W = [pbx ; pby];
