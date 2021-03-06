function [CI] = getCI_C14(data)

a = 3;
b = 4;

cal_curve = cell(3,1);
cal_curve{1} = load('Calibration_Curves/IntCal13.txt');
cal_curve{2} = load('Calibration_Curves/Marine13.txt');
cal_curve{3} = load('Calibration_Curves/SHCal13.txt');

for k = 1:3
    cal_curve{k}(:,3:4) = [];
    cal_curve{k} = cal_curve{k}/1000;
end



L = length(data);
CI = struct('name',cell(L,1),'depth',cell(L,1),'lower',cell(L,1),'upper',cell(L,1));

parfor ll = 1:L
    CI(ll).name = data(ll).name;
    M = 0;
    for n = 1:length(data(ll).depth)
        if isempty(data(ll).radiocarbon{n}) == 0
            M = M + size(data(ll).radiocarbon{n},1);
        end
    end
    
    depth = zeros(M,1);
    lower = zeros(M,1);
    upper = zeros(M,1);
    
    k = 0;
    for n = 1:length(data(ll).depth)
        if isempty(data(ll).radiocarbon{n}) == 0
            Table = data(ll).radiocarbon{n};
            for m = 1:size(Table,1)
                k = k + 1;
                depth(k) = data(ll).depth(n);
                
                rand_seed = log(rand(100,10000));
                
                c14_age = min(max(Table(m,1)-Table(m,3),cal_curve{Table(m,5)}(1,2)),cal_curve{Table(m,5)}(end,2));
                x = interp1q(cal_curve{Table(m,5)}(:,2),cal_curve{Table(m,5)}(:,1),c14_age)*ones(1,10000);
                
                for iters = 1:100
                    c14_x = min(max(x,cal_curve{Table(m,5)}(1,1)),cal_curve{Table(m,5)}(end,1));
                    det_x = interp1q(cal_curve{Table(m,5)}(:,1),cal_curve{Table(m,5)}(:,2),c14_x')';
                    err_x = interp1q(cal_curve{Table(m,5)}(:,1),cal_curve{Table(m,5)}(:,3),c14_x')';
                    RR_x = - (a+0.5)*log(2*b+(det_x+Table(m,3)-Table(m,1)).^2./(err_x.^2+Table(m,2)^2+Table(m,4)^2)) - 0.5*log(err_x.^2+Table(m,2)^2+Table(m,4)^2);
                    
                    z = normrnd(x,0.3);
                    c14_z = min(max(z,cal_curve{Table(m,5)}(1,1)),cal_curve{Table(m,5)}(end,1));                    
                    det_z = interp1q(cal_curve{Table(m,5)}(:,1),cal_curve{Table(m,5)}(:,2),c14_z')';
                    err_z = interp1q(cal_curve{Table(m,5)}(:,1),cal_curve{Table(m,5)}(:,3),c14_z')';
                    RR_z = - (a+0.5)*log(2*b+(det_z+Table(m,3)-Table(m,1)).^2./(err_z.^2+Table(m,2)^2+Table(m,4)^2)) - 0.5*log(err_z.^2+Table(m,2)^2+Table(m,4)^2);
                    
                    RR_z(z<0|z>50) = -inf;
                    
                    index = (RR_z-RR_x>rand_seed(iters,:));
                    x(index) = z(index);
                end
                
                x_samples = x;
                
                lower(k) = quantile(x_samples,0.025);
                upper(k) = quantile(x_samples,0.975);
            end
        end
    end
    CI(ll).depth = depth;
    CI(ll).lower = lower;
    CI(ll).upper = upper;
end


end