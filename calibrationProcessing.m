clc; clear;
kill;

% Josh's stuff
% The plan here is that we get a directory, we get the files present in this
% directory.  We then iterate through this list collecting all the data we are
% interested into a 2x2 array.  Additionally the list of filenames used will be
% retained to create a final .xls file which can be viewed.
calibrationDir = 'whatever';
% This may change later for the filename extension.
files = dir(strcat(calibrationDir, '/', '*.csv'));
delimiterIn = ',';
headlinesIn = 1;
initialIntensities = []
for c = 1:size(files)
	cvData = importdata(files, delimiterIn, headlinesIn);
	initialIntensities = [initialIntensities cvData.data(:,2)];
end

% Generates the Wavenumbers
calibrationFirst = calibrationDataPoint(1000, 19.7);
calibrationSecond = calibrationDataPoint(1027, 19.63);
calibrationCurve = getCalibrationFxn(calibrationFirst, calibrationSecond);
waveNumbers = getWavenumbers(120, 0.005, 19.35, calibrationCurve);

% Does an initial plot of wavenumber vs intensity for each dataset.
plotAllLines(waveNumbers, files, initialIntensities);
% Removes the background by subtracting minimum point in a specified range.
intensitiesWithBackgroundRemoved = backgroundSubtracted([1010 1040], wavenumbers, initialIntensities);
plotAllLines(wavenumbers, files, intensitiesWithBackgroundRemoved);

peakRatio = getPeakRatio([1010 1020], [1100 1120], intensitiesWithBackgroundRemoved);
concentration = getConcentrationsFromFile(files);

plot(concentration, peakRatio);


function concentrations = getConcentrationsFromFile(files)
	concentrations = []
	for i = 1:size(files)
		startIndex = strfind(files(i), 'conc') + 4
		endIndex = strfind(files(i)), '%') - 1
		concentration = [concentration str2num(files(i)(startIndex:endIndex))];
	end
end


function peakRatios = getPeakRatio(firstPeakWaveNumberRange, secondPeakWaveNumberRange, wavenumbers, intensityArray)
	wavenumberTargetOneIndexStart = min(abs(wavenumbers - firstPeakWaveNumberRange(1)));
	wavenumberTargetOneIndexEnd = min(abs(wavenumbers - firstPeakWaveNumberRange(2)));
	wavenumberTargetTwoIndexStart = min(abs(wavenumbers - secondPeakWaveNumberRange(1)));
	wavenumberTargetTwoIndexEnd = min(abs(wavenumbers - secondPeakWaveNumberRange(2)));
	peakRatios = []
	for i = 1:size(intensityArray, 2)
		peakOneIntensity = max(intensityArray(wavenumberTargetOneIndexStart:wavenumberTargetOneIndexEnd, i))
		peakTwoIntensity = max(intensityArray(wavenumberTargetTwoIndexStart:wavenumberTargetTwoIndexEnd, i))
		peakRatios = [peakRatios, peakOneIntensity / peakTwoIntensity]
	end
end

function excelSpreadSheet = saveSpreadsheet(filename, headers, wavenumbers, intensityArray)
	dataCells = num2cell(intensityArray);
	outputMatrix = [{'wavenumber'} headers; wavenumbers intensityArray]
	xlswrite(filenam, outputMatrix);
end

function calibrationDataPoint = getCalibrationDataPoint(benzoPeak, stageDistance)
	calibrationDataPoint = [benzoPeak stageDistance]
end

function [slope intercept] = getCalibrationFxn(calibrationStart, calibrationEnd) 
	slope = (calibrationStart(1) - calibrationEnd(1))./(calibrationStart(2) - calibrationEnd(2));
	intercept = calibrationStart(1) - slope*calibrationStart(2);
end

function wavenumbers = getWavenumbers(numberOfSteps, stepSize, startStage, calibrationCurve)
	endStage = startStage + stepSize * numberOfSteps;
	stageRange = linspace(startStage, endStage, numberOfSteps);
	wavenumbers = calibrationCurve(1) * stageRange + calibrationCurve(2)
end

function backgroundSubtracted = removeBackground(removalRange, wavenumbers, intensityArray)
	wavenumberIndexStart = min(abs(wavenumbers - removalRange(1)));
	wavenumberIndexEnd = min(abs(wavenumbers - removalRange(2)));
	backgroundSubtracted = []
	for i = 1:size(intensityArray, 2)
		minIntensity = min(intensityArray(wavenumberIndexStart:wavenumberIndexEnd, i));
		backgroundSubtracted = [backgroundSubtracted intensityArray(:,i)-minIntensity];
	end
end

function someFigure = plotAllLines(wavenumbers, dataLabel, intensityArray)
	someFigure = figure;
	hold on;
	for i = 1:size(intensityArray, 2)
		plot(wavenumbers, intensityArray(:,i), 'Linewidth', 2.0);
	end
	xlim([906 1135]);
	xlabel('Raman Shift');
	l = legend(dataLabel)
	t = title('Calibration for Calc');
	hold off
end





