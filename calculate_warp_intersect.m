function [p] = calculate_warp_intersect(v1,v2)
    A = [0,0];
    B = [0,1];
    C = [1,0];
    D = [.5,.5];
    P1 = (1-v1)*A+v1*B;
    P2 = (1-v1)*C+v1*D;
    P3 = (1-v2)*A+v2*C;
    P4 = (1-v2)*B+v2*D;
    disp(P1)
    xs = [P1(1); P2(1); P3(1); P4(1)];
    ys = [P1(2); P2(2); P3(2); P4(2)];
    % disp(xs)
    % disp(ys)
    p = linlinintersect(xs, ys);
    p(isnan(p))=0.5;
end

