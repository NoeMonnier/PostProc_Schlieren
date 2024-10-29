function erreur=fct_decalage(decalage,temps,Rayon,Lb,Vs)
decal=decalage;


if Lb>0
    x=1/exp(1):0.00005:1;
    t=real(2*(Lb/Vs)*expint((log(x.^2)))-2*(Lb/Vs)*(1./(x.^2.*log(x)))+decal);
    rf=-2*Lb./(x.*log(x));
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
    t=real(2*(Lb/Vs)*expint((log(x.^2)))-2*(Lb/Vs)*(1./(x.^2.*log(x)))+decal);
    rf=-2*Lb./(x.*log(x));
    b=1;
    Rayonnew=Rayon;
    for l=1:length(Rayonnew)
        a = find(rf<=Rayonnew(l));
        if abs(rf(min(a))-Rayonnew(l))>abs(rf(min(a-1))-Rayon(l))
            indice(l)=min(a)-1;
        else
            indice(l)=min(a);
        end

    end
 end

erreur=sum(abs(temps(b:end)-t(indice)').^2);


