function P2 = FilterEMG_Q1(P,Task)
    

        sf= P.Rate(1).EMG; %Hz - Sampling Freqeuncy
        HP30=designfilt('highpassiir','FilterOrder',5,'HalfPowerFrequency',30,'SampleRate',sf,'DesignMethod','butter');
        LP10=designfilt('lowpassiir','FilterOrder',4,'HalfPowerFrequency',10,'SampleRate',sf,'DesignMethod','butter');

        if Task==4 || Task==3
            tempEMG=P.EMG;
            P.EMG=[];
            P.EMG.Left=tempEMG;
            P.EMG.Right=[];
        end
        EMG.Ltrial=P.EMG.Left;
        EMG.Rtrial=P.EMG.Right;


        if isempty(EMG.Ltrial)==0
            for i=1:size(EMG.Ltrial,2)
                Lmus=fieldnames(P.EMG.Left);
                for j=1:length(Lmus)
                    temp=EMG.Ltrial(i).(Lmus{j});
                    temp2=filtfilt(HP30,temp);
                    temp3=detrend(temp2);
                    temp4=abs(temp3);
                    temp5= filtfilt(LP10,temp4); %temp5=temp5/max(abs(temp5));
%                     temp6=MinaSize(temp5,1000);
                    fEMG.Ltrial(i).(Lmus{j})=temp5;
                    clear temp temp1 temp2 temp3 temp4 temp5
                end
            end
            P.EMG_Filt.Left=fEMG.Ltrial;
        else
            P.EMG_Filt.Left=[];
        end

        if isempty(EMG.Rtrial)==0
            for i=1:size(EMG.Rtrial,2)
                Rmus=fieldnames(P.EMG.Right);
                for j=1:length(Rmus)
                    temp=EMG.Rtrial(i).(Rmus{j});
                    temp2=filtfilt(HP30,temp);
                    temp3=detrend(temp2);
                    temp4=abs(temp3);
                    temp5= filtfilt(LP10,temp4); %temp5=temp5/max(abs(temp5));
%                     temp6=MinaSize( temp5,1000);
                    fEMG.Rtrial(i).(Rmus{j})=temp5;
                    clear temp temp1 temp2 temp3 temp4 temp5
                end
            end
            P.EMG_Filt.Right=fEMG.Rtrial;
        else
            P.EMG_Filt.Right=[];
        end

        if Task==4 || Task==3
            P.EMG=[];
            P.EMG=tempEMG;

            tempEMG2=P.EMG_Filt.Left;
            P.EMG_Filt=[];
            P.EMG_Filt=tempEMG2;
        end
    P2=P;
    
end

