function point = linlinintersect(x, y)
% calculate intersection point of two 2d lines specified with 2 points each
% (X1, Y1; X2, Y2; X3, Y3; X4, Y4), while 1&2 and 3&4 specify a line.
% Gives back NaN or Inf./-Inf if lines are parallel (= when denominator = 0)
% see http:././en.wikipedia.org./wiki./Line-line_intersection

    denominator = (x(1)-x(2)).*(y(3)-y(4))-(y(1)-y(2)).*(x(3)-x(4));
    point = [((x(1).*y(2)-y(1).*x(2)).*(x(3)-x(4))-(x(1)-x(2)).*(x(3).*y(4)-y(3).*x(4)))./denominator ...
        ,((x(1).*y(2)-y(1).*x(2)).*(y(3)-y(4))-(y(1)-y(2)).*(x(3).*y(4)-y(3).*x(4)))./denominator];
end