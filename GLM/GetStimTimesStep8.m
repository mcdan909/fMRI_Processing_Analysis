%%% Trial type 1 == hand block, 2 == eye block

%subjNum = '006';
numTRWAIT = 0;
tr = 2.25;

clear all;

% if exist('AFNITGT2STIM.txt','file')
%     'You have to delete the files first'
%     return;

% Set your data directory here
cd ('<YOUR_MATLAB_DATA_DIR>');
%subFiles = dir('M*');

%subList = [3:6,8:21];
subList = 9;

for subNum = 1:length(subList)
    
    ['Making stim time files for Sub',num2str(subList(subNum))]
    
    if subList(subNum) < 10
        load(strcat('eye Movements/EyeProcessedFiles/EyeMovementData_0',num2str(subList(subNum))),'eyeACC');
        load(strcat('Hand Movements/ProcessedFiles/MovementData_0',num2str(subList(subNum))));
    else
        load(strcat('eye Movements/EyeProcessedFiles/EyeMovementData_',num2str(subList(subNum))),'eyeACC');
        load(strcat('Hand Movements/ProcessedFiles/MovementData_',num2str(subList(subNum))));
    end
    
    acc = ACC + eyeACC;
    
    for a = 1:numRuns
        
        trialShift = blockLength*(a-1);
        
        blockTimes = stimTiming(1+trialShift:blockLength+trialShift);
        blockTarLoc = targetLocation(1+trialShift:blockLength+trialShift);
        blockTarShape = targetLocation(1+trialShift:blockLength+trialShift);
        blockTarColor = targetColor(1+trialShift:blockLength+trialShift)';
        blockType = trialType(1+trialShift:blockLength+trialShift)';
        blockAcc = acc(1+trialShift:blockLength+trialShift);
        blockFix = saccadeDuringReach(1+trialShift:blockLength+trialShift);
        
        % Accurate trials only
        handAcc = blockTimes(blockAcc & ~blockFix & blockType == 1);
        eyeAcc = blockTimes(blockAcc & ~blockFix & blockType == 2);
        
        % Trials are errors if they were inaccurate or broke fixation
        handErr = blockTimes(~blockAcc & blockType == 1 | blockFix & blockType == 1);
        eyeErr = blockTimes(~blockAcc & blockType == 2 | blockFix & blockType == 2);
        
        % Target Side
        targetAccL = blockTimes(blockAcc & ~blockFix & blockTarLoc <= 2);
        targetAccR = blockTimes(blockAcc & ~blockFix & blockTarLoc > 2);
        
        targetErrL = blockTimes(~blockAcc & blockTarLoc <= 2 | blockFix & blockTarLoc <= 2);
        targetErrR = blockTimes(~blockAcc & blockTarLoc > 2 | blockFix & blockTarLoc > 2);
        
        % Target Location
        targetAccLL = blockTimes(blockAcc & ~blockFix & blockTarLoc == 1);
        targetAccUL = blockTimes(blockAcc & ~blockFix & blockTarLoc == 2);
        targetAccUR = blockTimes(blockAcc & ~blockFix & blockTarLoc == 3);
        targetAccLR = blockTimes(blockAcc & ~blockFix & blockTarLoc == 4);
        
        targetErrLL = blockTimes(~blockAcc & blockTarLoc == 1 | blockFix & blockTarLoc == 1);
        targetErrUL = blockTimes(~blockAcc & blockTarLoc == 2 | blockFix & blockTarLoc == 2);
        targetErrUR = blockTimes(~blockAcc & blockTarLoc == 3 | blockFix & blockTarLoc == 3);
        targetErrLR = blockTimes(~blockAcc & blockTarLoc == 4 | blockFix & blockTarLoc == 4);
        
        % Target Side Reach
        handAccL = blockTimes(blockAcc & ~blockFix & blockTarLoc <= 2 & blockType == 1);
        handAccR = blockTimes(blockAcc & ~blockFix & blockTarLoc > 2 & blockType == 1);
        
        handErrL = blockTimes(~blockAcc & blockTarLoc <= 2 & blockType == 1 | blockFix & blockTarLoc <= 2 & blockType == 1);
        handErrR = blockTimes(~blockAcc & blockTarLoc > 2 & blockType == 1 | blockFix & blockTarLoc > 2 & blockType == 1);
        
        % Target Side Eye
        eyeAccL = blockTimes(blockAcc & ~blockFix & blockTarLoc <= 2 & blockType == 2);
        eyeAccR = blockTimes(blockAcc & ~blockFix & blockTarLoc > 2 & blockType == 2);
        
        eyeErrL = blockTimes(~blockAcc & blockTarLoc <= 2 & blockType == 2 | blockFix & blockTarLoc <= 2 & blockType == 2);
        eyeErrR = blockTimes(~blockAcc & blockTarLoc > 2 & blockType == 2 | blockFix & blockTarLoc > 2 & blockType == 2);
        
        % Target location hand
        handAccLL = blockTimes(blockAcc & ~blockFix & blockTarLoc == 1 & blockType == 1);
        handAccUL = blockTimes(blockAcc & ~blockFix & blockTarLoc == 2 & blockType == 1);
        handAccUR = blockTimes(blockAcc & ~blockFix & blockTarLoc == 3 & blockType == 1);
        handAccLR = blockTimes(blockAcc & ~blockFix & blockTarLoc == 4 & blockType == 1);
        
        handErrLL = blockTimes(~blockAcc & blockTarLoc == 1 & blockType == 1 | blockFix & blockTarLoc == 1 & blockType == 1);
        handErrUL = blockTimes(~blockAcc & blockTarLoc == 2 & blockType == 1 | blockFix & blockTarLoc == 2 & blockType == 1);
        handErrUR = blockTimes(~blockAcc & blockTarLoc == 3 & blockType == 1 | blockFix & blockTarLoc == 3 & blockType == 1);
        handErrLR = blockTimes(~blockAcc & blockTarLoc == 4 & blockType == 1 | blockFix & blockTarLoc == 4 & blockType == 1);
        
        % Target location eye
        eyeAccLL = blockTimes(blockAcc & ~blockFix & blockTarLoc == 1 & blockType == 2);
        eyeAccUL = blockTimes(blockAcc & ~blockFix & blockTarLoc == 2 & blockType == 2);
        eyeAccUR = blockTimes(blockAcc & ~blockFix & blockTarLoc == 3 & blockType == 2);
        eyeAccLR = blockTimes(blockAcc & ~blockFix & blockTarLoc == 4 & blockType == 2);
        
        eyeErrLL = blockTimes(~blockAcc & blockTarLoc == 1 & blockType == 2 | blockFix & blockTarLoc == 1 & blockType == 2);
        eyeErrUL = blockTimes(~blockAcc & blockTarLoc == 2 & blockType == 2 | blockFix & blockTarLoc == 2 & blockType == 2);
        eyeErrUR = blockTimes(~blockAcc & blockTarLoc == 3 & blockType == 2 | blockFix & blockTarLoc == 3 & blockType == 2);
        eyeErrLR = blockTimes(~blockAcc & blockTarLoc == 4 & blockType == 2 | blockFix & blockTarLoc == 4 & blockType == 2);
        
        % Determine repeat vs switch trials
        colorPrimed = abs([2;diff(blockTarColor)]);
        locPrimed = abs([2;diff(blockTarLoc)]);
        
        % Color repeat vs switch
        colorSwitchAcc = blockTimes(colorPrimed & blockAcc & ~blockFix);
        colorRepeatAcc = blockTimes(~colorPrimed & blockAcc & ~blockFix);
        
        colorSwitchErr = blockTimes(colorPrimed & ~blockAcc | colorPrimed & blockFix);
        colorRepeatErr = blockTimes(~colorPrimed & ~blockAcc | ~colorPrimed & blockFix);
        
        % Location repeat vs switch
        locSwitchAcc = blockTimes(locPrimed & blockAcc & ~blockFix);
        locRepeatAcc = blockTimes(~locPrimed & blockAcc & ~blockFix);
        
        locSwitchErr = blockTimes(locPrimed & ~blockAcc | locPrimed & blockFix);
        locRepeatErr = blockTimes(~locPrimed & ~blockAcc | ~locPrimed & blockFix);
        
        % Color repeat vs switch hand
        handColorSwitchAcc = blockTimes(colorPrimed & blockType == 1 & blockAcc & ~blockFix);
        handColorRepeatAcc = blockTimes(~colorPrimed & blockType == 1 & blockAcc & ~blockFix);
        
        handColorSwitchErr = blockTimes(colorPrimed & blockType == 1 & ~blockAcc | colorPrimed & blockType == 1 & blockFix);
        handColorRepeatErr = blockTimes(~colorPrimed & blockType == 1 & ~blockAcc | ~colorPrimed & blockType == 1 & blockFix);
        
        % Color repeat vs switch eye
        eyeColorSwitchAcc = blockTimes(colorPrimed & blockType == 2 & blockAcc & ~blockFix);
        eyeColorRepeatAcc = blockTimes(~colorPrimed & blockType == 2 & blockAcc & ~blockFix);
        
        eyeColorSwitchErr = blockTimes(colorPrimed & blockType == 2 & ~blockAcc | colorPrimed & blockType == 2 & blockFix);
        eyeColorRepeatErr = blockTimes(~colorPrimed & blockType == 2 & ~blockAcc | ~colorPrimed & blockType == 2 & blockFix);
        
        % Location repeat vs switch hand
        handLocSwitchAcc = blockTimes(locPrimed & blockType == 1 & blockAcc & ~blockFix);
        handLocRepeatAcc = blockTimes(~locPrimed & blockType == 1 & blockAcc & ~blockFix);
        
        handLocSwitchErr = blockTimes(locPrimed & blockType == 1 & ~blockAcc | locPrimed & blockType == 1 & blockFix);
        handLocRepeatErr = blockTimes(~locPrimed & blockType == 1 & ~blockAcc | ~locPrimed & blockType == 1 & blockFix);
        
        % Location repeat vs switch eye
        eyeLocSwitchAcc = blockTimes(locPrimed & blockType == 2 & blockAcc & ~blockFix);
        eyeLocRepeatAcc = blockTimes(~locPrimed & blockType == 2 & blockAcc & ~blockFix);
        
        eyeLocSwitchErr = blockTimes(locPrimed & blockType == 2 & ~blockAcc | locPrimed & blockType == 2 & blockFix);
        eyeLocRepeatErr = blockTimes(~locPrimed & blockType == 2 & ~blockAcc | ~locPrimed & blockType == 2 & blockFix);
        
        % Color & Location repeat vs switch hand
        handColorSwitchLocSwitchAcc = blockTimes(colorPrimed & locPrimed & blockType == 1 & blockAcc & ~blockFix);
        handColorRepeatLocSwitchAcc = blockTimes(~colorPrimed & locPrimed & blockType == 1 & blockAcc & ~blockFix);
        handColorSwitchLocRepeatAcc = blockTimes(colorPrimed & ~locPrimed & blockType == 1 & blockAcc & ~blockFix);
        handColorRepeatLocRepeatAcc = blockTimes(~colorPrimed & ~locPrimed & blockType == 1 & blockAcc & ~blockFix);
        
        handColorSwitchLocSwitchErr = blockTimes(colorPrimed & locPrimed & blockType == 1 & ~blockAcc...
            | colorPrimed & locPrimed & blockType == 1 & blockFix);
        handColorRepeatLocSwitchErr = blockTimes(~colorPrimed & locPrimed & blockType == 1 & ~blockAcc...
            | ~colorPrimed & locPrimed & blockType == 1 & blockFix);
        handColorSwitchLocRepeatErr = blockTimes(colorPrimed & ~locPrimed & blockType == 1 & ~blockAcc...
            | colorPrimed & ~locPrimed & blockType == 1 & blockFix);
        handColorRepeatLocRepeatErr = blockTimes(~colorPrimed & ~locPrimed & blockType == 1 & ~blockAcc...
            | ~colorPrimed & ~locPrimed & blockType == 1 & blockFix);
        
        % Color & Location repeat vs switch eye
        eyeColorSwitchLocSwitchAcc = blockTimes(colorPrimed & locPrimed & blockType == 2 & blockAcc & ~blockFix);
        eyeColorRepeatLocSwitchAcc = blockTimes(~colorPrimed & locPrimed & blockType == 2 & blockAcc & ~blockFix);
        eyeColorSwitchLocRepeatAcc = blockTimes(colorPrimed & ~locPrimed & blockType == 2 & blockAcc & ~blockFix);
        eyeColorRepeatLocRepeatAcc = blockTimes(~colorPrimed & ~locPrimed & blockType == 2 & blockAcc & ~blockFix);
        
        eyeColorSwitchLocSwitchErr = blockTimes(colorPrimed & locPrimed & blockType == 2 & ~blockAcc...
            | colorPrimed & locPrimed & blockType == 2 & blockFix);
        eyeColorRepeatLocSwitchErr = blockTimes(~colorPrimed & locPrimed & blockType == 2 & ~blockAcc...
            | ~colorPrimed & locPrimed & blockType == 2 & blockFix);
        eyeColorSwitchLocRepeatErr = blockTimes(colorPrimed & ~locPrimed & blockType == 2 & ~blockAcc...
            | colorPrimed & ~locPrimed & blockType == 2 & blockFix);
        eyeColorRepeatLocRepeatErr = blockTimes(~colorPrimed & ~locPrimed & blockType == 2 & ~blockAcc...
            | ~colorPrimed & ~locPrimed & blockType == 2 & blockFix);
        
        % Set up txt file if there were no errors
        if isempty(handErr)
            handErr = ['*','*'];
        end
        
        if isempty(handErrL)
            handErrL = ['*','*'];
        end
        
        if isempty(handErrR)
            handErrR = ['*','*'];
        end
        
        if isempty(handErrLL)
            handErrLL = ['*','*'];
        end
        
        if isempty(handErrUL)
            handErrUL = ['*','*'];
        end
        
        if isempty(handErrUR)
            handErrUR = ['*','*'];
        end
        
        if isempty(handErrLR)
            handErrLR = ['*','*'];
        end
        
        if isempty(handColorSwitchErr)
            handColorSwitchErr = ['*','*'];
        end
        
        if isempty(handColorRepeatErr)
            handColorRepeatErr = ['*','*'];
        end
        
        if isempty(handLocSwitchErr)
            handLocSwitchErr = ['*','*'];
        end
        
        if isempty(handLocRepeatErr)
            handLocRepeatErr = ['*','*'];
        end
        
        if isempty(handColorSwitchLocSwitchErr)
            handColorSwitchLocSwitchErr = ['*','*'];
        end
        
        if isempty(handColorRepeatLocSwitchErr)
            handColorRepeatLocSwitchErr = ['*','*'];
        end
        
        if isempty(handColorSwitchLocRepeatErr)
            handColorSwitchLocRepeatErr = ['*','*'];
        end
        
        if isempty(handColorRepeatLocRepeatErr)
            handColorRepeatLocRepeatErr = ['*','*'];
        end
        
        if isempty(eyeErr)
            eyeErr = ['*','*'];
        end
        
        if isempty(eyeErrL)
            eyeErrL = ['*','*'];
        end
        
        if isempty(eyeErrR)
            eyeErrR = ['*','*'];
        end
        
        if isempty(eyeErrLL)
            eyeErrLL = ['*','*'];
        end
        
        if isempty(eyeErrUL)
            eyeErrUL = ['*','*'];
        end
        
        if isempty(eyeErrUR)
            eyeErrUR = ['*','*'];
        end
        
        if isempty(eyeErrLR)
            eyeErrLR = ['*','*'];
        end
        
        if isempty(eyeColorSwitchErr)
            eyeColorSwitchErr = ['*','*'];
        end
        
        if isempty(eyeColorRepeatErr)
            eyeColorRepeatErr = ['*','*'];
        end
        
        if isempty(eyeLocSwitchErr)
            eyeLocSwitchErr = ['*','*'];
        end
        
        if isempty(eyeLocRepeatErr)
            eyeLocRepeatErr = ['*','*'];
        end
        
        if isempty(eyeColorSwitchLocSwitchErr)
            eyeColorSwitchLocSwitchErr = ['*','*'];
        end
        
        if isempty(eyeColorRepeatLocSwitchErr)
            eyeColorRepeatLocSwitchErr = ['*','*'];
        end
        
        if isempty(eyeColorSwitchLocRepeatErr)
            eyeColorSwitchLocRepeatErr = ['*','*'];
        end
        
        if isempty(eyeColorRepeatLocRepeatErr)
            eyeColorRepeatLocRepeatErr = ['*','*'];
        end
        
        % Set up txt file for missing block data
        if isempty(handAcc)
            handAcc = ['*','*'];
            handErr = ['*','*'];
            
            handAccL = ['*','*'];
            handAccR = ['*','*'];
            
            handErrL = ['*','*'];
            handErrR = ['*','*'];
            
            handAccLL = ['*','*'];
            handAccUL = ['*','*'];
            handAccUR = ['*','*'];
            handAccLR = ['*','*'];
            
            handErrLL = ['*','*'];
            handErrUL = ['*','*'];
            handErrUR = ['*','*'];
            handErrLR = ['*','*'];
            
            handColorSwitchAcc = ['*','*'];
            handColorRepeatAcc = ['*','*'];
            
            handColorSwitchErr = ['*','*'];
            handColorRepeatErr = ['*','*'];
            
            handLocSwitchAcc = ['*','*'];
            handLocRepeatAcc = ['*','*'];
            
            handLocSwitchErr = ['*','*'];
            handLocRepeatErr = ['*','*'];
            
            handColorSwitchLocSwitchAcc = ['*','*'];
            handColorRepeatLocSwitchAcc = ['*','*'];
            handColorSwitchLocRepeatAcc = ['*','*'];
            handColorRepeatLocRepeatAcc = ['*','*'];
            
            handColorSwitchLocSwitchErr = ['*','*'];
            handColorRepeatLocSwitchErr = ['*','*'];
            handColorSwitchLocRepeatErr = ['*','*'];
            handColorRepeatLocRepeatErr = ['*','*'];
            
        end
        
        if isempty(eyeAcc)
            eyeAcc = ['*','*'];
            eyeErr = ['*','*'];
            
            eyeAccL = ['*','*'];
            eyeAccR = ['*','*'];
            
            eyeErrL = ['*','*'];
            eyeErrR = ['*','*'];
            
            eyeAccLL = ['*','*'];
            eyeAccUL = ['*','*'];
            eyeAccUR = ['*','*'];
            eyeAccLR = ['*','*'];
            
            eyeErrLL = ['*','*'];
            eyeErrUL = ['*','*'];
            eyeErrUR = ['*','*'];
            eyeErrLR = ['*','*'];
            
            eyeColorSwitchAcc = ['*','*'];
            eyeColorRepeatAcc = ['*','*'];
            
            eyeColorSwitchErr = ['*','*'];
            eyeColorRepeatErr = ['*','*'];
            
            eyeLocSwitchAcc = ['*','*'];
            eyeLocRepeatAcc = ['*','*'];
            
            eyeLocSwitchErr = ['*','*'];
            eyeLocRepeatErr = ['*','*'];
            
            eyeColorSwitchLocSwitchAcc = ['*','*'];
            eyeColorRepeatLocSwitchAcc = ['*','*'];
            eyeColorSwitchLocRepeatAcc = ['*','*'];
            eyeColorRepeatLocRepeatAcc = ['*','*'];
            
            eyeColorSwitchLocSwitchErr = ['*','*'];
            eyeColorRepeatLocSwitchErr = ['*','*'];
            eyeColorSwitchLocRepeatErr = ['*','*'];
            eyeColorRepeatLocRepeatErr = ['*','*'];

        end
        
        if a > 1
            
            dlmwrite(strcat('handAcc.txt'), handAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handErr.txt'), handErr , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeAcc.txt'), eyeAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeErr.txt'), eyeErr , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handAccL.txt'), handAccL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handAccR.txt'), handAccR , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handErrL.txt'), handErrL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handErrR.txt'), handErrR , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeAccL.txt'), eyeAccL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeAccR.txt'), eyeAccR , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeErrL.txt'), eyeErrL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeErrR.txt'), eyeErrR , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handAccLL.txt'), handAccLL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handAccUL.txt'), handAccUL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handAccUR.txt'), handAccUR , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handAccLR.txt'), handAccLR , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handErrLL.txt'), handErrLL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handErrUL.txt'), handErrUL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handErrUR.txt'), handErrUR , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handErrLR.txt'), handErrLR , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeAccLL.txt'), eyeAccLL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeAccUL.txt'), eyeAccUL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeAccUR.txt'), eyeAccUR , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeAccLR.txt'), eyeAccLR , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeErrLL.txt'), eyeErrLL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeErrUL.txt'), eyeErrUL , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeErrUR.txt'), eyeErrUR , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeErrLR.txt'), eyeErrLR , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handColorSwitchAcc.txt'), handColorSwitchAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatAcc.txt'), handColorRepeatAcc , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handColorSwitchErr.txt'), handColorSwitchErr , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatErr.txt'), handColorRepeatErr , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeColorSwitchAcc.txt'), eyeColorSwitchAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatAcc.txt'), eyeColorRepeatAcc , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeColorSwitchErr.txt'), eyeColorSwitchErr , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatErr.txt'), eyeColorRepeatErr , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handLocSwitchAcc.txt'), handLocSwitchAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handLocRepeatAcc.txt'), handLocRepeatAcc , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handLocSwitchErr.txt'), handLocSwitchErr , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handLocRepeatErr.txt'), handLocRepeatErr , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeLocSwitchAcc.txt'), eyeLocSwitchAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeLocRepeatAcc.txt'), eyeLocRepeatAcc , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeLocSwitchErr.txt'), eyeLocSwitchErr , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeLocRepeatErr.txt'), eyeLocRepeatErr , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handColorSwitchLocSwitchAcc.txt'), handColorSwitchLocSwitchAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatLocSwitchAcc.txt'), handColorRepeatLocSwitchAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorSwitchLocRepeatAcc.txt'), handColorSwitchLocRepeatAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatLocRepeatAcc.txt'), handColorRepeatLocRepeatAcc , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handColorSwitchLocSwitchErr.txt'), handColorSwitchLocSwitchErr , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatLocSwitchErr.txt'), handColorRepeatLocSwitchErr , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorSwitchLocRepeatErr.txt'), handColorSwitchLocRepeatErr , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatLocRepeatErr.txt'), handColorRepeatLocRepeatErr , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeColorSwitchLocSwitchAcc.txt'), eyeColorSwitchLocSwitchAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatLocSwitchAcc.txt'), eyeColorRepeatLocSwitchAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorSwitchLocRepeatAcc.txt'), eyeColorSwitchLocRepeatAcc , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatLocRepeatAcc.txt'), eyeColorRepeatLocRepeatAcc , '-append', 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeColorSwitchLocSwitchErr.txt'), eyeColorSwitchLocSwitchErr , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatLocSwitchErr.txt'), eyeColorRepeatLocSwitchErr , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorSwitchLocRepeatErr.txt'), eyeColorSwitchLocRepeatErr , '-append', 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatLocRepeatErr.txt'), eyeColorRepeatLocRepeatErr , '-append', 'roffset', [], 'delimiter', '\t');
            
        else
            
            dlmwrite(strcat('handAcc.txt'), handAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handErr.txt'), handErr , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeAcc.txt'), handAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeErr.txt'), handErr , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handAccL.txt'), handAccL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handAccR.txt'), handAccR , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handErrL.txt'), handErrL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handErrR.txt'), handErrR , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeAccL.txt'), eyeAccL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeAccR.txt'), eyeAccR , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeErrL.txt'), eyeErrL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeErrR.txt'), eyeErrR , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handAccLL.txt'), handAccLL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handAccUL.txt'), handAccUL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handAccUR.txt'), handAccUR , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handAccLR.txt'), handAccLR , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handErrLL.txt'), handErrLL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handErrUL.txt'), handErrUL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handErrUR.txt'), handErrUR , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handErrLR.txt'), handErrLR , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeAccLL.txt'), eyeAccLL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeAccUL.txt'), eyeAccUL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeAccUR.txt'), eyeAccUR , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeAccLR.txt'), eyeAccLR , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeErrLL.txt'), eyeErrLL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeErrUL.txt'), eyeErrUL , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeErrUR.txt'), eyeErrUR , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeErrLR.txt'), eyeErrLR , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handColorSwitchAcc.txt'), handColorSwitchAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatAcc.txt'), handColorRepeatAcc , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handColorSwitchErr.txt'), handColorSwitchErr , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatErr.txt'), handColorRepeatErr , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeColorSwitchAcc.txt'), eyeColorSwitchAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatAcc.txt'), eyeColorRepeatAcc , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeColorSwitchErr.txt'), eyeColorSwitchErr , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatErr.txt'), eyeColorRepeatErr , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handLocSwitchAcc.txt'), handLocSwitchAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handLocRepeatAcc.txt'), handLocRepeatAcc , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handLocSwitchErr.txt'), handLocSwitchErr , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handLocRepeatErr.txt'), handLocRepeatErr , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeLocSwitchAcc.txt'), eyeLocSwitchAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeLocRepeatAcc.txt'), eyeLocRepeatAcc , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeLocSwitchErr.txt'), eyeLocSwitchErr , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeLocRepeatErr.txt'), eyeLocRepeatErr , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handColorSwitchLocSwitchAcc.txt'), handColorSwitchLocSwitchAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatLocSwitchAcc.txt'), handColorRepeatLocSwitchAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorSwitchLocRepeatAcc.txt'), handColorSwitchLocRepeatAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatLocRepeatAcc.txt'), handColorRepeatLocRepeatAcc , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('handColorSwitchLocSwitchErr.txt'), handColorSwitchLocSwitchErr , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatLocSwitchErr.txt'), handColorRepeatLocSwitchErr , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorSwitchLocRepeatErr.txt'), handColorSwitchLocRepeatErr , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('handColorRepeatLocRepeatErr.txt'), handColorRepeatLocRepeatErr , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeColorSwitchLocSwitchAcc.txt'), eyeColorSwitchLocSwitchAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatLocSwitchAcc.txt'), eyeColorRepeatLocSwitchAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorSwitchLocRepeatAcc.txt'), eyeColorSwitchLocRepeatAcc , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatLocRepeatAcc.txt'), eyeColorRepeatLocRepeatAcc , 'roffset', [], 'delimiter', '\t');
            
            dlmwrite(strcat('eyeColorSwitchLocSwitchErr.txt'), eyeColorSwitchLocSwitchErr , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatLocSwitchErr.txt'), eyeColorRepeatLocSwitchErr , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorSwitchLocRepeatErr.txt'), eyeColorSwitchLocRepeatErr , 'roffset', [], 'delimiter', '\t');
            dlmwrite(strcat('eyeColorRepeatLocRepeatErr.txt'), eyeColorRepeatLocRepeatErr , 'roffset', [], 'delimiter', '\t');
            
        end
        
        ['Done with block #',num2str(a)]
    end
    
    mkdir(strcat('<YOUR_DATA_DIR>/Sub',num2str(subList(subNum)),'/StimTimes'));
    movefile('*.txt',strcat('<YOUR_DATA_DIR>/Sub',num2str(subList(subNum)),'/StimTimes'))
    
end
