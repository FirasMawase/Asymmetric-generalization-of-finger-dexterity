function varargout=calibrate_V2N_analyze()
close all

LoadFileName=input('Which file do you want to analyze?\n','s');
SaveFileName=input('How to call output file?\n','s');

clc
D = dload(LoadFileName);

g=9.80665002864; 

figure(1); hold on;
color_s = [1 ,0, 0 ;
   0.6350, 0.0780, 0.1840;
   0.8500 ,0.3250, 0.0980;
   0.9290, 0.6940, 0.1250;
   0.4660 ,0.6740, 0.1880;
   0, 1, 0;
   0, 0, 1;
   0, 0.4470, 0.7410;
   0.4940, 0.1840, 0.5560;
    1, 0, 1];

%----make matrix
for f=[1:10]
    C=getrow(D,D.finger==f); 
    i=find(C.weight==0 ); 
    x=C.(['meanV',num2str(f)]);        % Pick the right finger
    volts0=mean(x(i)); % Calculate force baseline
    %[r,b]=scatterplot(C.weight,x-volts0,'regression','linear','intercept',0,'markercolor',colors(f,:),'leg',{num2str(f)});   
    X=C.weight;
    Y= x-volts0;
    myfittype = fittype(' a*(X)','dependent',{'Y'},'independent',{'X'},'coefficients',{'a'});
    myfit = fit(X,Y,myfittype);
    b=myfit.a;
    Volts2N(f)=g/1000/b;
    h=plot(myfit,X,Y,':')
    set(h, 'markersize',10,'color',color_s(f,:)');
    legend('1','1', '2','2', '3','3', '4', '4', '5','5', '6','6', '7', '7','8','8', '9', '9','10','10')
end

Volts2N
mean(Volts2N)
save(['Calib_' SaveFileName '.mat'],'Volts2N');

% %---- 9.80665 newton per kilo
% %---- =>0.600 kg * 9.80665 = 5.8840  N
% %---- =>1.200 kg * 9.80665 = 11.7680 N

