function Q1=ReadData(Path)

TrialName =  dir(fullfile(Path, '*.csv'));   % All trial names
a=strfind(Path,'\');
Q1.Name=Path(a(end)+1:end);
task=Path(a(end)+1:end);
g=1;
s=1;
for i=1:size(TrialName,1)
    test=[Path,'\',TrialName(i).name];
    [num, txt]=xlsread(test);
    
    [a, b]=find(contains(lower(txt),'myon'));
    [c, ~]=find(contains(txt,'Model Outputs'));
    [d, ~]=find(contains(txt,'Trajectories'));
    [e, ~]=find(contains(txt,'Fx'));
    if isempty(c)
        c=d;
    end
        Fs_Device=num(e(1)-3,1);
        Fs_Camera=num(c(1),1);
        Q1.Rate(g).F=round(Fs_Device/Fs_Camera);
        Q1.Rate(g).Camera=Fs_Camera;
        Q1.Rate(g).EMG=Fs_Device;
        Q1.Rate(g).ForcePlate=Fs_Device;
        Q1.Events(g).TrialName=TrialName(i).name;
        Q1.Events(g).StartFrame=num(a+2,1);
        
        FN=txt(a+1,b:end);
        FN2=txt(a+2,b:end);
        if ~isempty(FN)
            for j=1:length(FN)
                if ~isempty(FN{j}) && strcmp(FN2{j},'V')
                    temp=strfind(FN{j},'-');
                    Mus=FN{j};
                    if ~isempty(temp)
                        Mus(temp)='_';
                    end
                    Q1.EMG(g).(Mus)=num(a+2:c-3,j+b-1);
                end
            end
        else
            Q1.EMG=[];
        end
        
        [a, b]=find(contains(txt,'Fx'));
        Q1.Events(g).StartFrame=num(a(1)+1,1);
        if length(a)==2
            Q1.FP1(g).Force=num(a(1)+1:c-3,b(1):b(1)+2);
            Q1.FP1(g).Moment=num(a(1)+1:c-3,b(1)+3:b(1)+5);
            Q1.FP1(g).COP=num(a(1)+1:c-3,b(1)+6:b(1)+8);
            Q1.FP2(g).Force=num(a(2)+1:c-3,b(2):b(2)+2);
            Q1.FP2(g).Moment=num(a(2)+1:c-3,b(2)+3:b(2)+5);
            Q1.FP2(g).COP=num(a(2)+1:c-3,b(2)+6:b(2)+8);
        else
            Q1.FP2(g).Force=num(a(end)+1:c-3,b(end):b(end)+2);
            Q1.FP2(g).Moment=num(a(end)+1:c-3,b(end)+3:b(end)+5);
            Q1.FP2(g).COP=num(a(end)+1:c-3,b(end)+6:b(end)+8);
        end
        
        FN=txt(c+2,:);
        for j=1:length(FN)
            if ~isempty(FN{j})
                temp=strfind(FN{j},':');
                MRK=FN{j}(temp(end)+1:end);
                if contains(FN{j},'Force') || contains(FN{j},'Moment') || contains(FN{j},'Power')
                    Q1.Kinetics(g).(MRK)=num(c+4:d-3,j:j+2);
                elseif contains(FN{j},'Angle')
                    Q1.Kinematics(g).(MRK)=num(c+4:d-3,j:j+2);
                elseif contains(FN{j},'JC')
                    Q1.JC(g).(MRK)=num(c+4:d-3,j:j+2);
                end
            end
        end
        
        FN=txt(d+2,:);
        for j=1:length(FN)
            if ~isempty(FN{j})
                temp=strfind(FN{j},':');
                MRK=FN{j}(temp(end)+1:end);
                a=strfind(MRK,'-');
                MRK(a)='_';
                try
                Q1.Trajectory(g).(MRK)=num(d+4:end,j:j+2);
                catch
                    Q1.Trajectory(g).(MRK)=nan*num(d+4:end,1:3);
                end
            end
        end
        
        g=g+1;

   end

Q1 = FilterEMG_Q1(Q1,3);

% Mus={'LRF','LVM','LVL','LBF','LSEMI', 'RRF','RVM','RVL','RBF','RSEMI'};
Mus=fieldnames(Q1.EMG);
st=find(strcmp(lower({Q1.Events.TrialName}'),'static'),1,'first');
if isempty(st)
   st=find(contains(lower({Q1.Events.TrialName}'),'static'),1,'first'); 
end
for k=1:length(Mus)
    BL=mean(Q1.EMG_Filt(st).(Mus{k}))+2*std(Q1.EMG_Filt(st).(Mus{k}));
    for j=1:size(Q1.EMG_Filt,2)
        if j~=st
            [on, off]=OnsetOffsetDetection(Q1.EMG_Filt(j).(Mus{k}),BL,Q1.Rate(j).EMG);
            Q1.OnOff(j).(Mus{k})=round([on off]/10);
        end
    end
end
Q1.Weight=mean(-Q1.FP2(st).Force(1000:2000,3)) ;   
end

