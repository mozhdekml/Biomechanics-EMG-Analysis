function [on, off]=OnsetOffsetDetection(emg,BL,fs)
on=[];
off=[];
s=.05*fs;

a=find(emg>BL,1,'first');
while ~isempty(a) && a<=length(emg)
    if a+s>length(emg)
        c=length(emg);
    else
        c=a+s-1;
    end
    if  min(emg(a:c)>BL)==1
        on=[on; a];
        flag=1;
        while flag==1
            b=find(emg(a:end)<BL,1,'first')+a-1;
            if b+s>length(emg)
                d=length(emg);
            else
                d=b+s-1;
            end
            if isempty(b)
                off=[off; length(emg)];
                a=[];
                flag=0;
            elseif  min(emg(b:d)<BL)==1
                off=[off; b];
                a=find(emg(b:end)>BL,1,'first')+b-1;
                flag=0;
            else
                a=find(emg(b:end)>BL,1,'first')+b-1;
            end
        end
    else
        b=find(emg(a:end)<BL,1,'first')+a-1;
        a=find(emg(b:end)>BL,1,'first')+b-1;
    end
end
end

