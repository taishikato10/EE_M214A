%##############################################################
% Sample script to perform speaker verficiation
% ECE214A: Digital Speech Processing, Winter 2019
%##############################################################

clear all;
clc;
%%
% Define lists
allFiles = 'allFiles.txt';
trainList = 'train_read.txt';  
testList = 'test_read.txt';

tic
%%
% Extract features
featureDict = containers.Map;
fid = fopen(allFiles);
myData = textscan(fid,'%s');
fclose(fid);
myFiles = myData{1};
for cnt = 1:length(myFiles)
    [snd,fs] = audioread(myFiles{cnt});
    [F0,lik] = fast_mbsc_fixedWinlen_tracking(snd,fs);
    featureDict(myFiles{cnt}) = mean(F0(lik>0.45));
    if(mod(cnt,10)==0)
        disp(['Completed ',num2str(cnt),' of ',num2str(length(myFiles)),' files.']);
    end
end

%%

% Train the classifier
fid = fopen(trainList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
trainLabels = myData{3};
trainFeatures = zeros(length(trainLabels),1);
for cnt = 1:length(trainLabels)
    trainFeatures(cnt) = -abs(featureDict(fileList1{cnt})-featureDict(fileList2{cnt}));
end

Mdl = fitcknn(trainFeatures,trainLabels,'NumNeighbors',15000,'Standardize',1);

%%
% Test the classifier
fid = fopen(testList);
myData = textscan(fid,'%s %s %f');
fclose(fid);
fileList1 = myData{1};
fileList2 = myData{2};
testLabels = myData{3};
testFeatures = zeros(length(testLabels),1);
for cnt = 1:length(testLabels)
    testFeatures(cnt) = -abs(featureDict(fileList1{cnt})-featureDict(fileList2{cnt}));
end

[~,prediction,~] = predict(Mdl,testFeatures);
testScores = (prediction(:,2)./(prediction(:,1)+1e-15));
[eer,~] = compute_eer(testScores, testLabels);
disp(['The EER is ',num2str(eer),'%.']);

toc
%%