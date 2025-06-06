
DYNAMICS=@quadrotor;

nX = 12;%number of states
nU = 4;%number of inputs

% quadrotor w^2 to force/torque matrix
kf = 8.55*(1e-6)*91.61;
L = 0.17;
b = 1.6*(1e-2)*91.61;
m = 0.716;
g = 9.81;

A = [kf, kf, kf, kf; ...
    0, L*kf, 0, -L*kf; ...
    -L*kf, 0, L*kf, 0; ...
    b, -b, b, -b];


%initial conditions
x0= [0;0;0;0;0;0;0;0;0;0;0;0];
xd= [5;5;0;0;0;0;0;0;0;0;0;0];


% Initialization
num_samples = 3000;
N = 5;

utraj = zeros(nU, N-1);
utraj(1,:) = m*g;
uOpt = [];
xf = [];
dt = 0.02;
lambda = 100;
nu = 1000;
covu = diag([2.5,5*1e-3,5*1e-3,5*1e-3]);

xtraj = zeros(nX, N);
R = lambda*inv(covu);

x = x0;

for iter =1:300
    x
    Straji = zeros(N,num_samples);
    Straj = zeros(1,num_samples); 
    for k = 1:num_samples
        du = covu*randn(nU, N);
        dU{k} = du;
        xtraj = [];
        xtraj(:,1) = x;
        for t = 1:N-1
            u = utraj(:,t);
            xtraj(:,t+1) = xtraj(:,t) + DYNAMICS(xtraj(:,t), u+du(:,t))*dt;
            Straji(t+1,k) = Straji(t,k) + runningCost(xtraj(:,t), xd, R, u, du(:,t), nu);
        end
        Straj(k) = Straji(N,k) + finalCost(xtraj(:,N), xd);
    end

    for t = 1:N-1
        ss = 0;
        su = 0;
        for k = 1:num_samples
            ss = ss + exp(-1/lambda*(Straji(t,k)-min(Straji(t,:))));
            su = su + exp(-1/lambda*(Straji(t,k)-min(Straji(t,:))))*dU{k}(:,t);
        end
        
        utraj(:,t) = utraj(:,t) + su/ss;
    end

    x = x + DYNAMICS(x, utraj(:,1))*dt;
    uOpt = [uOpt, utraj(:,1)];
    
    for t = 2:N-1
        utraj(:,t-1) = utraj(:,t);
    end
    utraj(:,N-1) = [m*g;0;0;0];

end


function J = runningCost(x, xd, R, u, du, nu)
    Q = diag([2.5, 2.5, 15, 1, 1, 15, zeros(1, 6)]);
    qx = (x-xd)'*Q*(x-xd);
    J = qx + 1/2*u'*R*u + (1-1/nu)/2*du'*R*du + u'*R*du;
end

function J = finalCost(xT,xd)
    Qf = 20*diag([2.5, 2.5, 15, 1, 1, 15, zeros(1, 6)]);
    J = (xT-xd)'*Qf*(xT-xd);
end