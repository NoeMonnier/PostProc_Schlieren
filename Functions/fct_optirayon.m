function erreur=fct_optirayon(Param,temps,Rayon)
CP1=Param(1);
CP2=Param(2);
CP3=Param(3);

if CP2>0
    x=1/exp(1):0.0001:1;
    t=real(2*(CP2/CP1)*expint((log(x.^2)))-2*(CP2/CP1)*(1./(x.^2.*log(x)))+CP3);
    rf=-2*CP2./(x.*log(x));
    if min(rf)>min(Rayon)
        c=find(Rayon<min(rf));
        b=max(c)+1;
        Rayonnew=Rayon(b:end);


    else
        b=1;
        Rayonnew=Rayon;
    end
    for l=1:length(Rayonnew)
        a = find(rf<Rayonnew(l));
        if abs(rf(max(a))-Rayonnew(l))>abs(rf(max(a+1))-Rayonnew(l))
            indice(l)=max(a)+1;
        else
            indice(l)=max(a);
        end
    end

else
    x=1:0.00005:10;
    t=real(2*(CP2/CP1)*expint((log(x.^2)))-2*(CP2/CP1)*(1./(x.^2.*log(x)))+CP3);
    rf=-2*CP2./(x.*log(x));
    b=1;
    Rayonnew=Rayon;
    for l=1:length(Rayonnew)
        a = find(rf<Rayonnew(l));
        if abs(rf(min(a))-Rayonnew(l))>abs(rf(min(a-1))-Rayon(l))
            indice(l)=min(a)-1;
        else
            indice(l)=min(a);
        end

    end
end



% if max(rf)<0
%     CP2=0.0001;
%     t=real(2*(CP2/CP1)*expint((log(x.^2)))-2*(CP2/CP1)*(1./(x.^2.*log(x)))+CP3);
%     rf=-2*CP2./(x.*log(x));
% end

%Param
erreur=sum((temps(b:end)'-t(indice)).^2);
% figure;
% plot(t,rf,'.b');
% hold on;
% plot(temps(b:end),Rayonnew,'+g');
% axis([temps(min(b)) temps(end) Rayon(min(b)) Rayon(end)]);
% 
