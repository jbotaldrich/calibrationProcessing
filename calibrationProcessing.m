clc; clear;
kill;

% The plan here is that we get a directory, we get the files present in this
% directory.  We then iterate through this list collecting all the data we are
% interested into a matrix.  Additionally the list of filenames used will be
% retained to create provide concentrations values for plotting.
%/Users/kderyckx/CloudStation/Computer\ A/KseniyaS/7032018/TestText
%

% Put your directory here.
calibrationDir = '/Users/kderyckx/CloudStation/Computer A/KseniyaS/7032018/TestText'; %<<< CHANGE ME!!!

% This may change later for the filename extension.
files = dir(strcat(calibrationDir, '/', '*.txt'));
delimiterIn = '\t';

% Read in all the intensity files.
initialIntensities = [];
for c = 1:size(files)
    filename = strcat(files(c).folder, '/', files(c).name);
	cvData = importdata(filename, delimiterIn);
	initialIntensities = [initialIntensities, cvData(:,2)];
end

% Generates the Wavenumbers
% The variables set here can change between runs.
calibrationFirst = getCalibrationDataPoint(1000, 19.7);  %<<< CHANGE ME!!!!
calibrationSecond = getCalibrationDataPoint(1027, 19.63);  %<<< CHANGE ME!!!!
[slope, intercept] = getCalibrationFxn(calibrationFirst, calibrationSecond);

%This can change each run.
waveNumbers = getWavenumbers(120, 0.005, 19.35, [slope, intercept]);

% Does an initial plot of wavenumber vs intensity for each dataset.
plotAllLines(waveNumbers, files, initialIntensities);
% Removes the background by subtracting minimum point in a specified range.
intensitiesWithBackgroundRemoved = removeBackground([1010 1040], waveNumbers, initialIntensities);
plotAllLines(waveNumbers, files, intensitiesWithBackgroundRemoved);

% Generate the peak ratios.
peakRatio = getPeakRatio([955 975], [1070 1100], waveNumbers, intensitiesWithBackgroundRemoved);
concentration = getConcentrationsFromFile(files);

figure();
% Scatter plot of the concentration vs peakRatio.
scatter(concentration, peakRatio);

% Parses the filename to pull out the concentration value.  Probably a more elegant way to do this.
function concentrations = getConcentrationsFromFile(files)
	concentrations = [];
	for i = 1:size(files)
		startIndex = strfind(files(i).name, 'Conc') + 4;
		endIndex = strfind(files(i).name, 'view') - 1;
        concString = files(i).name;
		concentrations = [concentrations str2double(concString(startIndex:endIndex))];
	end
end

% Generates the peak ratio as a ratio of 2 given wavelengths intensities.  Get the max value in 
% in two wavelength ranges of interest and take the ratio.
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

% This generates an excel spreadsheet of the intensities based on wavelength.
function excelSpreadSheet = saveSpreadsheet(filename, headers, wavenumbers, intensityArray)
	dataCells = num2cell(intensityArray);
	outputMatrix = [{'wavenumber'} headers; wavenumbers dataCells];
	xlswrite(filename, outputMatrix);
end

% Creates a data point 1x2 array provided a peak and stage distance.  (maybe change parameter
% name from benzoPeak to just peak)
function calibrationDataPoint = getCalibrationDataPoint(benzoPeak, stageDistance)
	calibrationDataPoint = [benzoPeak stageDistance];
end

% Generates a calibration funciton based on start and end calibration data points.
function [slope, intercept] = getCalibrationFxn(calibrationStart, calibrationEnd) 
	slope = (calibrationStart(1) - calibrationEnd(1))./(calibrationStart(2) - calibrationEnd(2));
	intercept = calibrationStart(1) - slope*calibrationStart(2);
end

%Converts stage information into wavenumbers.
function wavenumbers = getWavenumbers(numberOfSteps, stepSize, startStage, calibrationCurve)
	endStage = startStage + stepSize * numberOfSteps;
	stageRange = linspace(startStage, endStage, numberOfSteps);
	wavenumbers = fliplr(calibrationCurve(1) * stageRange + calibrationCurve(2));
end

% Subtract background expects 
% removalRange, 1x2 array of start and end of removal range
% wavenumbers, an array of 1-d array of wavenumbers (wavelengths)
% intensityArray, array of intensity where each experiment is a column.
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

% Plots all the experiments in one figure.
function someFigure = plotAllLines(wavenumbers, dataLabel, intensityArray)
	someFigure = figure;
	hold on;
    labels = [];
	for i = 1:size(intensityArray, 2)
		plot(wavenumbers, intensityArray(:,i), 'Linewidth', 2.0);
        labels = [labels, dataLabel(i).name];
	end
	xlim([906 1135]);
	xlabel('Raman Shift');
	legend(cellstr(labels));
	title('Calibration for Calc');
	hold off
end





