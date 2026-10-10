clc
clearvars
close all
warning off

Path0=uigetdir;
Subs =  dir(fullfile(Path0));

for i=3:size(Subs,1)
    i
    Path=strcat(Path0,'\',Subs(i).name);
    Q1=ReadData(Path);
    P(i-2)=Q1;
end


%%
% load P
KNEE={'LKneeAngles','RKneeAngles'};
Ang={'LHipAngles','LKneeAngles','LAnkleAngles';...
    'RHipAngles','RKneeAngles','RAnkleAngles' };
Mom={'LHipMoment','LKneeMoment','LAnkleMoment';...
    'RHipMoment','RKneeMoment','RAnkleMoment' };

for sub=1:size(P,2)
    sub
    Q1=P(sub);
    for j=1:size(Q1.Events,2)
        if ~contains(lower(Q1.Events(j).TrialName),'st')
            % Detect Foot
            Fz=-Q1.FP2(j).Force(:,3);
            rate=Q1.Rate(j).F;
            [~,loc]=max(Fz); loc=round(loc/rate);
            if Q1.Trajectory(j).LTOE(loc,3)<Q1.Trajectory(j).RTOE(loc,3)
                Q1.Events(j).Foot=1;
                h=1;
            else
                Q1.Events(j).Foot=2;
                h=2;
            end
            
            % Detect Events
            KneeAng=Q1.Kinematics(j).(KNEE{h})(:,1);
            c1=find(Fz>Q1.Weight*.05,1,'first'); c1_t=round(c1/rate);
            o=find(Fz(c1+10:end)<Q1.Weight*.05,1,'first')+c1+10-1; o_t=round(o/rate);
            c2=find(Fz(o+10:end)>Q1.Weight*.05,1,'first')+o+10-1; c2_t=round(c2/rate);
            [~,max1]=max(KneeAng(c1_t:o_t)); max1=max1+c1_t-1;
            [~,max2]=max(KneeAng(c2_t:c2_t+Q1.Rate(j).Camera/2)); max2=max2+c2_t-1;
            Q1.Events(j).P1=[c1_t max1];
            Q1.Events(j).P2=[max1+1 o_t];
            Q1.Events(j).P3=[c2_t max2];
            
            % Kinematics
            for k=1:size(Ang,2)
                temp=Q1.Kinematics(j).(Ang{h,k});
                dtemp=diff(Q1.Kinematics(j).(Ang{h,k}))*Q1.Rate(j).Camera;
                Q1.Out(j).(strcat(Ang{h,k}(2:end),'_atEvents'))=temp(c2_t,:);
                Q1.Out(j).(strcat(Ang{h,k}(2:end),'_ROMatPhase'))=max(temp(c2_t:max2,:),[],1)-min(temp(c2_t:max2,:),[],1);
                Q1.Out(j).(strcat(Ang{h,k}(2:end),'_MaxatPhase'))=max(temp(c2_t:max2,:),[],1);
                Q1.Out(j).(strcat(Ang{h,k}(2:end),'_MinatPhase'))= min(temp(c2_t:max2,:),[],1);
                Q1.Out(j).(strcat(Ang{h,k}(2:end),'_VelatEvents'))=dtemp(c2_t,:);
                Q1.Out(j).(strcat(Ang{h,k}(2:end),'_VelMean'))=mean(temp(c2_t:max2,:),1);
                Q1.Out(j).(strcat(Ang{h,k}(2:end),'_MeanatPhase'))=mean(temp(c2_t:max2,:),1);
            end
            
            % Kinetics
            for k=1:size(Mom,2)
                temp=Q1.Kinetics(j).(Mom{h,k});
                Q1.Out(j).(strcat(Mom{h,k}(2:end),'_atEvents'))=temp(c2_t,:);
                Q1.Out(j).(strcat(Mom{h,k}(2:end),'_MaxatPhase'))=max(temp(c2_t:max2,:),[],1);
                Q1.Out(j).(strcat(Mom{h,k}(2:end),'_MinatPhase'))= min(temp(c2_t:max2,:),[],1);
                Q1.Out(j).(strcat(Mom{h,k}(2:end),'_MeanatPhase'))=mean(temp(c2_t:max2,:),1);
            end
            
            
            % Coordination
            CRP_HK=CRP(Q1.Kinematics(j).(Ang{h,1}),Q1.Kinematics(j).(Ang{h,2}));
            CRP_KA=CRP(Q1.Kinematics(j).(Ang{h,2}),Q1.Kinematics(j).(Ang{h,3}));
            Q1.Out(j).CRP_HipKne_MeanatPhase=mean(CRP_HK(c2_t:max2,:),1);
            Q1.Out(j).CRP_KneAnk_MeanatPhase=mean(CRP_KA(c2_t:max2,:),1);
            Q1.Out(j).CRP_HipKne_SDatPhase=std(CRP_HK(c2_t:max2,:),0,1);
            Q1.Out(j).CRP_KneAnk_SDatPhase=std(CRP_KA(c2_t:max2,:),0,1);
            Q1.Out(j).CRP_HipKne_atEvents=CRP_HK(c2_t,:);
            Q1.Out(j).CRP_KneAnk_atEvents=CRP_KA(c2_t,:);

            
            % emg
            Mus={'Glut_Max','Glut_Med','TFL','VMO','VM','GC_Med'};
            for i=1:length(Mus)
                temp=Q1.EMG_Filt(j).(Mus{i});
                temp=MinaSize(temp/max(temp)*100,size(Q1.Trajectory(j).LASI,1));
                OnOff=zeros(size(Q1.Trajectory(j).LASI,1),1);
                for k=1:size(Q1.OnOff(j).(Mus{i}),1)
                    if Q1.OnOff(j).(Mus{i})(k,1)==0
                        Q1.OnOff(j).(Mus{i})(k,1)=1;
                    end
                    OnOff(Q1.OnOff(j).(Mus{i})(k,1):Q1.OnOff(j).(Mus{i})(k,2))=1;
                end
                On3=find(OnOff(c2_t:max2)==1,1,'first');
                if isempty(On3)
                    On3=nan;
                elseif On3~=1
                    On3=On3/(max2-c2_t+1)*100;
                end
                Q1.Out(j).(strcat(Mus{i},'_On'))=On3;
                Q1.Out(j).(strcat(Mus{i},'_Mean'))=mean(temp(c2_t:max2),1);
                Q1.Out(j).(strcat(Mus{i},'_atEvents'))=temp(c2_t);
            end
            VM=MinaSize(Q1.EMG_Filt(j).VM/max(Q1.EMG_Filt(j).VM)*100,size(Q1.Trajectory(j).LASI,1));
            VMO=MinaSize(Q1.EMG_Filt(j).VMO/max(Q1.EMG_Filt(j).VMO)*100,size(Q1.Trajectory(j).LASI,1));
            Glut_Med=MinaSize(Q1.EMG_Filt(j).Glut_Med/max(Q1.EMG_Filt(j).Glut_Med)*100,size(Q1.Trajectory(j).LASI,1));
            TFL=MinaSize(Q1.EMG_Filt(j).TFL/max(Q1.EMG_Filt(j).TFL)*100,size(Q1.Trajectory(j).LASI,1));
            Q1.Out(j).VM_VMOatEvents=VM(c2_t)/VMO(c2_t)*100;
            Q1.Out(j).GMED_TFLatEvents=Glut_Med(c2_t)/TFL(c2_t)*100;
             Q1.Out(j).VM_VMOatPhase=mean(VM(c2_t:max2),1)/mean(VMO(c2_t:max2),1)*100;
            Q1.Out(j).GMED_TFLatPhase=mean(Glut_Med(c2_t:max2),1)/mean(TFL(c2_t:max2),1)*100;
             
            % TTS , DPSI
            if c2+3*Q1.Rate(j).ForcePlate<length(Fz)
            F=-Q1.FP2(j).Force(c2:c2+3*Q1.Rate(j).ForcePlate,:);
            else
                F=-Q1.FP2(j).Force(c2:end,:);
            end
            F=sqrt(sum(F.^2,2));
            Q1.Out(j).DPSI=mean((F-0).^2,1);
            temp=[];
            F=-Q1.FP2(j).Force;
            for i=c2:length(F)-2*Q1.Rate(j).ForcePlate
               F2=F(i: i+2*Q1.Rate(j).ForcePlate,:);
               F2=sqrt(sum(F2.^2,2));
               if max(F2)-min(F2)<Q1.Weight*.1
                   temp=i;
                   break
               end
            end
            if ~isempty(temp)
            Q1.Out(j).TTS=(temp-c2)/Q1.Rate(j).ForcePlate;
            else
                Q1.Out(j).TTS=nan;
            end
        end
    end
    
    
    P(sub).Out=Q1.Out;
    P(sub).Events=Q1.Events;
end

%%
dst=strcat(pwd,'\Result');
FN1={'HipAngles_atEvents','KneeAngles_atEvents','AnkleAngles_atEvents',...
    'HipAngles_VelatEvents','KneeAngles_VelatEvents','AnkleAngles_VelatEvents',...
    'HipMoment_atEvents','KneeMoment_atEvents','AnkleMoment_atEvents',...
    'CRP_HipKne_atEvents','CRP_KneAnk_atEvents',...
    'Glut_Max_atEvents','Glut_Med_atEvents','TFL_atEvents','VMO_atEvents','VM_atEvents','GC_Med_atEvents',...
    'VM_VMOatEvents','GMED_TFLatEvents'};
FN2={'HipAngles_MinatPhase','KneeAngles_MinatPhase','AnkleAngles_MinatPhase',...
    'HipAngles_MaxatPhase','KneeAngles_MaxatPhase','AnkleAngles_MaxatPhase',...
    'HipAngles_ROMatPhase','KneeAngles_ROMatPhase','AnkleAngles_ROMatPhase',...
    'HipAngles_MeanatPhase','KneeAngles_MeanatPhase','AnkleAngles_MeanatPhase',...
    'HipAngles_VelMean','KneeAngles_VelMean','AnkleAngles_VelMean',...
    'HipMoment_MinatPhase','KneeMoment_MinatPhase','AnkleMoment_MinatPhase',...
    'HipMoment_MaxatPhase','KneeMoment_MaxatPhase','AnkleMoment_MaxatPhase',...
    'HipMoment_MeanatPhase','KneeMoment_MeanatPhase','AnkleMoment_MeanatPhase',...
    'CRP_HipKne_MeanatPhase','CRP_HipKne_SDatPhase','CRP_KneAnk_MeanatPhase','CRP_KneAnk_SDatPhase'...
    'Glut_Max_Mean','Glut_Med_Mean','TFL_Mean','VMO_Mean','VM_Mean','GC_Med_Mean',...
    'Glut_Max_On','Glut_Med_On','TFL_On','VMO_On','VM_On','GC_Med_On',...
    'VM_VMOatPhase','GMED_TFLatPhase','DPSI','TTS'};
    
for sub=1:size(P,2)
    sub
    Q1=P(sub);
   
    copyfile ([pwd ,'\','Result.xlsx'], dst);
    FileName=strcat(pwd,'\Result\Result.xlsx');
    EX01=[]; EX11=[]; EX21=[];
    EX02=[]; EX12=[]; EX22=[];
    clear TN0 TN1 TN2
    for j=1:size(Q1.Events,2)
        temp01=[]; temp11=[]; temp21=[];
        temp02=[]; temp12=[]; temp22=[];
        if contains(lower(Q1.Events(j).TrialName),'p0') || contains(lower(Q1.Events(j).TrialName),'p 0')
            for k=1:length(FN1)
                temp01=[temp01 Q1.Out(j).(FN1{k})];
            end
            if size(EX01,1)<7
            EX01=[EX01; temp01];
            end
            TN0{size(EX01,1),1}=Q1.Events(j).TrialName;
            for k=1:length(FN2)
                temp02=[temp02 Q1.Out(j).(FN2{k})];
            end
            if size(EX02,1)<7
            EX02=[EX02; temp02];
            end
            
        elseif contains(lower(Q1.Events(j).TrialName),'p1') || contains(lower(Q1.Events(j).TrialName),'p 1')
            for k=1:length(FN1)
                temp11=[temp11 Q1.Out(j).(FN1{k})];
            end
            if size(EX11,1)<7
            EX11=[EX11; temp11];
            TN1{size(EX11,1),1}=Q1.Events(j).TrialName;
            end
            
             for k=1:length(FN2)
                temp12=[temp12 Q1.Out(j).(FN2{k})];
             end
            if size(EX12,1)<7
            EX12=[EX12; temp12];
            end
        elseif contains(lower(Q1.Events(j).TrialName),'p2') || contains(lower(Q1.Events(j).TrialName),'p 2')
            for k=1:length(FN1)
                temp21=[temp21 Q1.Out(j).(FN1{k})];
            end
            if size(EX21,1)<7
            EX21=[EX21; temp21];
            end
            TN2{size(EX21,1),1}=Q1.Events(j).TrialName;
            for k=1:length(FN2)
                temp22=[temp22 Q1.Out(j).(FN2{k})];
            end
            if size(EX22,1)<7
            EX22=[EX22; temp22];
            end
        end
        
    end
    xlswrite(FileName,EX01,'Jump0','B6');
    xlswrite(FileName,EX02,'Jump0','B22');
    xlswrite(FileName,TN0,'Jump0','A6');
    xlswrite(FileName,TN0,'Jump0','A22');
    
    xlswrite(FileName,EX11,'Jump1','B6');
    xlswrite(FileName,EX12,'Jump1','B22');
    xlswrite(FileName,TN1,'Jump1','A6');
    xlswrite(FileName,TN1,'Jump1','A22');
    
    xlswrite(FileName,EX21,'Jump2','B6');
    xlswrite(FileName,EX22,'Jump2','B22');
    xlswrite(FileName,TN2,'Jump2','A6');
    xlswrite(FileName,TN2,'Jump2','A22');
    
    src=strcat(dst,'\Result.xlsx');
    dst2=strcat(dst,'\Result_',Q1.Name,'.xlsx');
    movefile (src, dst2)
end