function dseg = dsegemodel(spikes, dseg)
% DSEGEMODEL constructs an event model for a DATASEG object
%
% DSEG = DSEGEMODEL(DSEG) returns a DSEG object with an event
%  model.
% 
% The returned DSEG object will contain two new fields, EVENTMODEL
% and EVENTFORM.  The EVENTFORM object contains as many columns as
% there are events and as many rows as there are trials.  Each entry
% corresponds to the spike time for a given event and a given trial.
%
% The EVENTMODEL object countains a list of event structures which
% have the following fields:
%   spikes:     Contains the spike times for the given event.
%   trials:     Contains the trials for the spikes listed in spikes
%   
%   EVENTMODEL also includes some misc items for internal use.
%
%   See also DSEGMODEL, DSEVTPICKER, DATASEG, DATASET
%

dsconstants;

spikes = section(spikes(:,:,1), dseg.start, dseg.finish );

cm = dseg.clusmod;
cc = dseg.tchosen;

em.events.spikes = [];
em.events.trials = [];
em.events.id = [];
em.events = repmat(em.events, [1 max(dsegcmids(dseg))]);

sfs = [];
tfs = [];
ifs = [];

for i=1:length(cm)
    
    for j=1:length(cm(i).events)
        if ~isempty(cm(i).events(j).id)
            ti = find(cc==i);
            ss = spikes(ti,:,1);
            inz = find(ss>0);
            ti = repmat(ti',[1 size(ss,2)]);
            ss = ss(inz);
            tt = ti(inz);
            scc = dseg.schosen{i};
            ss = ss(scc==j);
            tt = tt(scc==j);
            if(length(ss) > 2)
                disp(sprintf('merging cm(%d).events(%d)\n',i,j));
              

                s = em.events(cm(i).events(j).id).spikes;
                t = em.events(cm(i).events(j).id).trials;
                
                if ~isnan(mean(s)) & ~isnan(mean(ss))
                    if abs(diff(mean(s)-mean(ss))) > 60
                        disp('!!!!')
                        disp(sprintf('prev mean is %f current mean is %f\n',mean(s),mean(ss)));
                        keyboard
                    end
                end
                s = [s; ss];
                t = [t; tt];

    %             sp = s;
    %             m = mean(sp);
    %             s = std(sp);
    %             d = abs(m-sp)/s;
    %             jj = find(d>5);
    %             if ~isempty(jj)
    %                 for rib=jj
    %                     disp(sprintf('dsegemodel: I found a spike at %f greater than 5 sigma away from the mean of %f\n',sp(rib),m));
    %                 end
    %                 keyboard
    %             end

    %            if cm(i).events(j).id == 6 & i == 2
    %                disp('Something weird.');
    %                keyboard
    %            end
                em.events(cm(i).events(j).id).spikes = s;
                em.events(cm(i).events(j).id).trials = t;
                em.events(cm(i).events(j).id).id = cm(i).events(j).id;


                %disp(sprintf('I am appending things to id %d',cm(i).events(j).id));
                sfs = [sfs; ss];
                tfs = [tfs; tt];
                ifs = [ifs; repmat(cm(i).events(j).id,[length(ss) 1])];
            end
        end
    end
end



emi = 1;
for i=1:length(em.events)
    if ~isempty(em.events(i).spikes)
        emr.events(emi).spikes = em.events(i).spikes;
        emr.events(emi).trials = em.events(i).trials;
        emr.events(emi).mean = mean(em.events(i).spikes);
        emr.events(emi).prec = 1/std(em.events(i).spikes);
        emr.events(emi).reli = length(em.events(i).spikes)/size(spikes,1);
        emr.events(emi).id = em.events(i).id;
        emi = emi + 1;
    end
end

%keyboard
em = emr;

[nothing,ii] = sort( [em.events(:).mean] );
em.events = em.events(ii);
ifs = relabel(ifs);

dseg.eventmodel = em;
dseg.eventform = full(sparse(tfs,ifs,sfs));
norm = full(sparse(tfs,ifs,ones(size(sfs))));
norm(norm==0) = 1;

dseg.eventform = dseg.eventform./norm;
dseg.eventform = dseg.eventform(:,ii);
dseg.status = EMODELED;
