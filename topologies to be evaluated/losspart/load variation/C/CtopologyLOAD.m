%% C TOPOLOGY
clear all
close all
% load('B_loadvariated.mat')
topology_type = 'C';
P_GaN_cond=zeros();
P_GaN_sw=zeros();
P_Coss=zeros();
P_reverse_cond=zeros();
Pper=zeros();
PLC=zeros();
Pmodule=zeros();
E=zeros();
fsw=51050;
Eload_c=zeros();

%%

for satir=2:8
    clearvars -except satir E Pper topology_type P_GaNB_cond P_reverse_condB P_GaNB_sw P_CossB Id PLC Eload_b
    savename1 = strcat(topology_type,'_sw_currents_',num2str(satir),'000_W');
    load(savename1);
    savename2 = strcat(topology_type,'_sw_voltages_',num2str(satir),'000_W');
    load(savename2);
    Id(satir,:)= C_sw1_cur.signals.values;
    for la = 1:numel(Id)
        if (Id(la) < 1e-4)&&(Id(la) > -1e-4)
            Id(la) = 0;
        end
    end
    L=length(Id(satir,:));
    Ts=1e-7;
    % load=800*satir;
    
    Esw=0;
    Eoff=0;
    Eon=0;
    Eoss=0;
    Econd=0;
    Erevcond=0;
    
    swon=0;
    swoff=0;
    swrev=0;
    cond=0;
    revcond=0;
    %%
    for n=1:L
        if Id(satir,1) < 0
            Id(satir,1)= 0;
        end
        if (Id(satir,n)>0  && n>1 && n<L) %meaning that IGBT is on operation
            
            if (Id(satir,n-1)==0) %meaning that there is an on switching, the  swtiching period could take long
                Eon=GaN_sw(abs(Id(satir,n)),'on'); %J
                Esw = Esw + Eon;
                swon=swon+1;
                
                
            elseif (Id(satir,n+1)==0) %meaning that there is an off switching, a decline in the current
                Eoff=GaN_sw(abs(Id(satir,n)),'off'); %j
                Esw = Esw + Eoff;
                swoff=swoff+1;
                
            else
                Vds=GaN_cond(Id(satir,n));
                Econd= Econd + Id(satir,n)* Vds*Ts;
                cond=cond+1;
            end
            
            
        elseif  (Id(satir,n)<0 && n<L) %meaning that diode is on operation
            
            if (Id(satir,n+1)==0) %meaning that there is an off switching, a decline in the current
                Eoff=GaN_sw(abs(Id(satir,n)),'off'); %j
                Esw = Esw + Eoff;
                swoff=swoff+1;
                
            elseif (Id(satir,n-1)==0)
                Eon=GaN_sw(abs(Id(satir,n)),'on'); %J
                Esw = Esw + Eon;
                swon=swon+1;
                
            else
                Vds=GaN_reverse_cond(Id(satir,n));
                Erevcond= Erevcond + abs(Id(satir,n))* Vds*Ts;
                revcond=revcond+1;
            end
        end
    end
    
    Eoss=swon*11e-6; %J
    
    P_GaN_cond(satir) = (Econd)*50;       %Total loss per IGBT
    P_reverse_cond(satir) = (Erevcond)*50;
    P_GaN_sw(satir)= Esw*50;
    P_Coss(satir)=Eoss*50;
    
    %%Total Loss
    
    Pper(satir)=P_GaN_cond(satir)+P_reverse_cond(satir)+P_GaN_sw(satir)+P_Coss(satir);
    Pmodule(satir)=Pper(satir)*6;
    PLC(satir)=Pmodule(satir)*4;
    %     Eload_c(satir)=load/(PLC(satir)+load)*100;
    
    E(satir,1:4)=[Esw  Econd Eoss Erevcond ];
end

%%
load=[1000 2000 3000 4000 5000 6000 7000 8000];
satir=PLC+load;
Eload_c=load./(satir)*100;
Eload_c(1) = [];
load(1)=[];
plot(load/1000,Eload_c)
xlabel('Pout (kW)','FontSize',16,'FontWeight','bold')
ylabel('Efficiency (%)','FontSize',16,'FontWeight','bold')
title('Efficiency versus Pout for C','FontWeight','bold')

%% loss components versus power
load=[1000 2000 3000 4000 5000 6000 7000 8000];
plot(load/1000,E(:,1))
hold on
plot(load/1000,E(:,2))
hold on
plot(load/1000,E(:,3))
hold on
plot(load/1000,E(:,4))
hold off
xlabel('Pout (kW)','FontSize',16,'FontWeight','bold')
ylabel('Losses (W)','FontSize',16,'FontWeight','bold')
title('Losses per GaN versus Pout for C','FontWeight','bold')
legend('Esw','Econd','Eoss','Erevcond','FontWeight','bold','Location','northwest')
