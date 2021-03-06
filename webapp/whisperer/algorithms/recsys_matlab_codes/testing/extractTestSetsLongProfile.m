function [positive,negative]=extractTestSetsLongProfile (urm,percentagePos,percentageNeg, profileLength, kfolder)
% function [positive,negative]=extractTestSets (URMpath,percentagePos,percentageNeg)
%
% - urm = urm users x items matrix
% - percentagePos,percentageNeg = percentage of positive (negative)ratings
% to fill the test sets with
%
% - profileLength = If profileLength is a two-element vector, then it
% selects only users with a number of ratings in the range
% [profileLength(1) profileLength(2)]. Else, if profileLength is a single
% integer, it creates test sets discarding users with less then
% 'profileLength' ratings.  
%
% kfolder. If k-folder is non-null positive/negative tests are generated
% for each fold (as used by the k-folder function)

if (exist('kfolder')~=1)
    kfolder = 1;
end

numUsers=size(urm,1);
numRowsToTest = floor(numUsers/kfolder);

for fold=1:kfolder
%suddivido in parte di test (urmTest) e parte di train (urmTrain)

    maxIndexRowTest = numRowsToTest * fold;
    %urmTrain = [urm(1 : maxIndexRowTest - numRowsToTest, :) ; urm(maxIndexRowTest + 1:end ,:)];
    urmTest = urm(maxIndexRowTest - numRowsToTest + 1 : maxIndexRowTest , :);
    
    [poss,negg]=extractTestSetsLongProfileIn (urmTest,percentagePos,percentageNeg, profileLength);        
    poss.i=poss.i + maxIndexRowTest - numRowsToTest;
    negg.i=negg.i + maxIndexRowTest - numRowsToTest;
    
    positive(fold)=poss;
    negative(fold)=negg;
%    skipped(fold)=skippedtmp;
    
end

end


function [positive,negative,skipped]=extractTestSetsLongProfileIn (urm,percentagePos,percentageNeg, profileLength)

    if (exist('percentageNeg')==0)
       percentageNeg=1; 
    end
    if (exist('percentagePos')==0)
       percentagePos=1; 
    end
    
    skipped=[];

    urmspones=spones(urm);
    usersViews=full(sum(urmspones,2));

    %if (profileLength>0)
    %    orderedUsersViews = sort(usersViews,2,'descend');
    %    viewsThreshold = orderedUsersViews(profileLength);
    %else
    %    viewsThreshold = 0;
    %end 
    
    
    if (length(profileLength)==2)
        viewsThresholdInf=profileLength(1);
        viewsThresholdSup=profileLength(2);
    elseif (length(profileLength)==1)
        viewsThresholdInf=profileLength;
        viewsThresholdSup=+Inf;
    else
        warning ('check profileLength input');
    end
        
    

    if (percentageNeg <0)
    % estrae solo positivi
        [posItmp,posJtmp]=find(urm);

        posI=zeros(size(posItmp));
        posJ=zeros(size(posJtmp));

        indexPos=0;
        for i=1:length(posItmp)
            user = posItmp(i);
            item = posJtmp(i);
            if (usersViews(user)>=viewsThreshold )
                indexPos = indexPos +1;
                posI(indexPos)=user;
                posJ(indexPos)=item;
            end
        end    

        numPos=ceil(indexPos*percentagePos);
        posIndex = randsample(indexPos,numPos);
        positive.i=posI(posIndex);
        positive.j=posJ(posIndex);
        negative.i=[];
        negative.j=[];
    else

        userAvg=zeros(1,size(urm,1));
        itemAvg=zeros(1,size(urm,2));
        skipped=[];

        h = waitbar(0,'Please wait...');
        for i=1:size(urm,1)
            if (~isempty(find(urm(i,:))))
                userAvg(i)=mean(urm(i,find(urm(i,:))));
            else
                skipped=[skipped;i];
            end
            if mod(i,100)==0
                waitbar(i/size(urm,1),h,num2str(i))
            end
        end
        close(h);
        drawnow;
        % for i=1:size(urm,2)
        %     itemAvg(i)=mean(urm(find(urm(:,i)),i));
        % end

        [urmI,urmJ]=find(urm);

        posI=zeros(size(urmI));
        posJ=zeros(size(urmI));
        negI=zeros(size(urmI));
        negJ=zeros(size(urmI));

        indexPos=0;
        indexNeg=0;
        for i=1:length(urmI)
            user = urmI(i);
            item = urmJ(i);
            rating = urm(user,item);
            if (rating>=3 && rating>userAvg(user) && usersViews(user)>=viewsThresholdInf && usersViews(user)<=viewsThresholdSup)
                indexPos = indexPos +1;
                posI(indexPos)=user;
                posJ(indexPos)=item;
                else
                if (rating<3 && rating<userAvg(user) && rating>0 && usersViews(user)>=viewsThresholdInf && usersViews(user)<=viewsThresholdSup)
                    indexNeg = indexNeg +1;
                    negI(indexNeg)=user;
                    negJ(indexNeg)=item;  
                end
            end
        end

        posI=posI(1:indexPos);
        posJ=posJ(1:indexPos);
        negI=negI(1:indexNeg);
        negJ=negJ(1:indexNeg);

        if (percentageNeg==1 && percentagePos==1)
            positive.i=posI;
            positive.j=posJ;
            negative.i=negI;
            negative.j=negJ;
            return
        end

        numPos=ceil(indexPos*percentagePos);
        numNeg=ceil(indexNeg*percentageNeg);

        posIndex = randsample(indexPos,numPos);
        negIndex = randsample(indexNeg,numNeg);

        positive.i=posI(posIndex);
        positive.j=posJ(posIndex);
        negative.i=negI(negIndex);
        negative.j=negJ(negIndex);
    end
end