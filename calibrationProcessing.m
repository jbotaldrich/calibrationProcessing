clc; clear;
kill;

% The plan here is that we get a directory, we get the files present in this
% directory.  We then iterate through this list collecting all the data we are
% interested into a matrix.  Additionally the list of filenames used will be
% retained to create provide concentrations values for plotting.
%/Users/kderyckx/CloudStation/Computer\ A/KseniyaS/7032018/TestText
%
calibrationDir = '/Users/kderyckx/CloudStation/Computer A/KseniyaS/7032018/TestText';
% This may change later for the filename extension.
test = strcat(calibrationDir, '/', '*.txt');
files = dir(strcat(calibrationDir, '/', '*.txt'));
delimiterIn = '\t';
initialIntensities = [];
for c = 1:size(files)
    filename = strcat(files(c).folder, '/', files(c).name);
	cvData = importdata(filename, delimiterIn);
	initialIntensities = [initialIntensities, cvData(:,2)];
end

% Generates the Wavenumbers
% The variables set here can change between runs.
calibrationFirst = getCalibrationDataPoint(1000, 19.7);
calibrationSecond = getCalibrationDataPoint(1027, 19.63);
[slope, intercept] = getCalibrationFxn(calibrationFirst, calibrationSecond);

%This can change each run.
waveNumbers = getWavenumbers(120, 0.005, 19.35, [slope, intercept]);

% Does an initial plot of wavenumber vs intensity for each dataset.
whaIsThis = files.name;
plotAllLines(waveNumbers, files, initialIntensities);
% Removes the background by subtracting minimum point in a specified range.
intensitiesWithBackgroundRemoved = removeBackground([1010 1040], waveNumbers, initialIntensities);
plotAllLines(waveNumbers, files, intensitiesWithBackgroundRemoved);
l=legend();

peakRatio = getPeakRatio([955 975], [1070 1100], waveNumbers, intensitiesWithBackgroundRemoved);
concentration = getConcentrationsFromFile(files);

figure();
scatter(concentration, peakRatio);


function concentrations = getConcentrationsFromFile(files)
	concentrations = [];
	for i = 1:size(files)
		startIndex = strfind(files(i).name, 'Conc') + 4;
		endIndex = strfind(files(i).name, 'view') - 1;
        concString = files(i).name;
		concentrations = [concentrations str2double(concString(startIndex:endIndex))];
	end
end


function peakRatios = getPeakRatio(firstPeakWaveNumberRange, secondPeakWaveNumberRange, wavenumbers, intensityArray)
	[~, wavenumberTargetOneIndexStart] = min(abs(wavenumbers - firstPeakWaveNumberRange(1)));
	[~, wavenumberTargetOneIndexEnd] = min(abs(wavenumbers - firstPeakWaveNumberRange(2)));
	[~, wavenumberTargetTwoIndexStart] = min(abs(wavenumbers - secondPeakWaveNumberRange(1)));
	[~, wavenumberTargetTwoIndexEnd] = min(abs(wavenumbers - secondPeakWaveNumberRange(2)));
	peakRatios = [];
	for i = 1:size(intensityArray, 2)
		peakOneIntensity = max(intensityArray(wavenumberTargetOneIndexStart:wavenumberTargetOneIndexEnd, i));
		peakTwoIntensity = max(intensityArray(wavenumberTargetTwoIndexStart:wavenumberTargetTwoIndexEnd, i));
		peakRatios = [peakRatios, peakOneIntensity / peakTwoIntensity];
	end
end

function excelSpreadSheet = saveSpreadsheet(filename, headers, wavenumbers, intensityArray)
	dataCells = num2cell(intensityArray);
	outputMatrix = [{'wavenumber'} headers; wavenumbers dataCells];
	xlswrite(filename, outputMatrix);
end

function calibrationDataPoint = getCalibrationDataPoint(benzoPeak, stageDistance)
	calibrationDataPoint = [benzoPeak stageDistance];
end

function [slope, intercept] = getCalibrationFxn(calibrationStart, calibrationEnd) 
	slope = (calibrationStart(1) - calibrationEnd(1))./(calibrationStart(2) - calibrationEnd(2));
	intercept = calibrationStart(1) - slope*calibrationStart(2);
end

function wavenumbers = getWavenumbers(numberOfSteps, stepSize, startStage, calibrationCurve)
	endStage = startStage + stepSize * numberOfSteps;
	stageRange = linspace(startStage, endStage, numberOfSteps);
	wavenumbers = fliplr(calibrationCurve(1) * stageRange + calibrationCurve(2));
end

function backgroundSubtracted = removeBackground(removalRange, wavenumbers, intensityArray)
	[~, wavenumberIndexStart] = min(abs(wavenumbers - removalRange(1)));
	[~, wavenumberIndexEnd] = min(abs(wavenumbers - removalRange(2)));
	backgroundSubtracted = [];
	for i = 1:size(intensityArray, 2)
        valuesTested = intensityArray(wavenumberIndexStart:wavenumberIndexEnd, i);
		minIntensity = min(intensityArray(wavenumberIndexStart:wavenumberIndexEnd, i));
		backgroundSubtracted = [backgroundSubtracted intensityArray(:,i)-minIntensity];
	end
end

function someFigure = plotAllLines(wavenumbers, dataLabel, intensityArray)
	someFigure = figure;
	hold on;
    labels = [];
	for i = 1:size(intensityArray, 2)
		plot(wavenumbers, intensityArray(:,i), 'Linewidth', 2.0);
        %labels = [labels, dataLabel(i).name];
        %l=legend(files(1,i))
	end
	xlim([906 1135]);
	xlabel('Raman Shift');
	legend(cellstr(labels));
	title('Calibration for Calc');
	hold off
end





