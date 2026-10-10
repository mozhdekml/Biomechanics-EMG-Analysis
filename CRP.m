function crp = CRP(temp1,temp2)

    dtemp1=MinaSize(diff(temp1),length(temp1));
    dtemp2=MinaSize(diff(temp2),length(temp2));

    Ntemp1=2*(temp1-min(temp1))./(max(temp1)-min(temp1))-1;
    Ntemp2=2*(temp2-min(temp2))./(max(temp2)-min(temp2))-1;
    Ndtemp1=dtemp1./max(abs(dtemp1));
    Ndtemp2=dtemp2./max(abs(dtemp2));        
    
    phi_temp1=atand(abs(Ndtemp1./Ntemp1));
    phi_temp2=atand(abs(Ndtemp2./Ntemp2));

    a=find(Ntemp1<0);
    phi_temp1(a)=180-phi_temp1(a);
    
    a=find(Ntemp2<0);
    phi_temp2(a)=180-phi_temp2(a);
    
    crp=phi_temp1-phi_temp2;
%     a=find(crp<0);
%     crp(a)=360+crp(a);
end

