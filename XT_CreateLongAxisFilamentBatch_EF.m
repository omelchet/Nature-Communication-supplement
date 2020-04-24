%
%
%  Filaments Split Into Branches Function for Imaris 7.3.0
%
%  Copyright Bitplane AG 2011
%
%
%  Installation:
%
%  - Copy this file into the XTensions folder in the Imaris installation directory.
%  - You will find this function in the Image Processing menu
%
%    <CustomTools>
%      <Menu>
%       <Submenu name="Filaments Functions">
%        <Item name="Create Filaments Long Axis Batch" icon="Matlab" tooltip="Split filament into branches.">
%          <Command>MatlabXT::XT_CreateLongAxisFilamentBatch_EF(%i)</Command>
%        </Item>
%       </Submenu>
%      </Menu>
%      <SurpassTab>
%        <SurpassComponent name="bpFilaments">
%          <Item name="Create Filaments Long Axis Batch" icon="Matlab" tooltip="Split filament into branches.">
%            <Command>MatlabXT::XT_CreateLongAxisFilamentBatch_EF(%i)</Command>
%          </Item>
%        </SurpassComponent>
%      </SurpassTab>
%    </CustomTools>
% 
%
%  Description:
%
%   Split one filament object in different filaments. 
%   The new filaments go from the root to a terminal of the original
%       filament and they do not have branches. 
%   The number of filaments created is equal to the number of terminals
%       of the original filament.
%

function XT_CreateLongAxisFilamentBatch_EF(aImarisApplicationID)

% connect to Imaris interface
fprintf('Initializing...\n')
if ~isa(aImarisApplicationID, 'Imaris.IApplicationPrxHelper')
  javaaddpath ImarisLib.jar
  vImarisLib = ImarisLib;
  if ischar(aImarisApplicationID)
    aImarisApplicationID = round(str2double(aImarisApplicationID));
  end
  vImarisApplication = vImarisLib.GetApplication(aImarisApplicationID);
else
  vImarisApplication = aImarisApplicationID;
end

%% Getting All Surfaces

fprintf('Finding all surfaces...\n')
vSurpassScene = vImarisApplication.GetSurpassScene;
vSel = vImarisApplication.GetSurpassSelection;

if ~vImarisApplication.GetFactory.IsDataContainer(vSel)
    msgbox('Please select folder containing all cell surfaces');
    return
end

vFolder = vImarisApplication.GetFactory.ToDataContainer(vSel);
vFolderName = vFolder.GetName;

numChildren = vFolder.GetNumberOfChildren;

vNumSurf = 0;
vSurfList = cell(1, numChildren);
vSurfNames = cell(1, numChildren);

for vChild = 1:numChildren
    vData = vFolder.GetChild(vChild-1);
    if vImarisApplication.GetFactory.IsSurfaces(vData)
        vNumSurf = vNumSurf + 1;
        vSurfList{vNumSurf} = vImarisApplication.GetFactory.ToSurfaces(vData);
        vSurfNames{vNumSurf} = char(vData.GetName);
        %disp(char(vData.GetName))
    end
end

vSurfNames = vSurfNames(1:vNumSurf);

%% Get Image Data parameters

fprintf('Reading data...\n')
aExtendMaxX = vImarisApplication.GetDataSet.GetExtendMaxX;
aExtendMaxY = vImarisApplication.GetDataSet.GetExtendMaxY;
aExtendMaxZ = vImarisApplication.GetDataSet.GetExtendMaxZ;
aExtendMinX = vImarisApplication.GetDataSet.GetExtendMinX;
aExtendMinY = vImarisApplication.GetDataSet.GetExtendMinY;
aExtendMinZ = vImarisApplication.GetDataSet.GetExtendMinZ;
aSizeX = vImarisApplication.GetDataSet.GetSizeX;
aSizeY = vImarisApplication.GetDataSet.GetSizeY;
aSizeZ = vImarisApplication.GetDataSet.GetSizeZ;
aSizeC = vImarisApplication.GetDataSet.GetSizeC;
aSizeT = vImarisApplication.GetDataSet.GetSizeT;

%% Create Data Container 

fprintf('Creating data containers...\n')
vFolderSepTimePt = vImarisApplication.GetFactory.CreateDataContainer;
vFolderSepTimePt.SetName('Long Axis Filaments Separate Time Point');

vFolderOneTimePt = vImarisApplication.GetFactory.CreateDataContainer;
vFolderOneTimePt.SetName('Long Axis Filaments One Time Point');


%% Batch surface reading 

fprintf('Creating all filaments...\n')
aWidth = 0.0169;
numPoints = 4;

for iSurf = 1:vNumSurf
    fprintf('Starting surface %d/%d...\n', iSurf, vNumSurf)
    vName = vSurfNames{iSurf};
    vSurfAll = vSurfList{iSurf};
    vTimeSurf = vSurfAll.GetNumberOfSurfaces;
    vColor = vSurfAll.GetColorRGBA;
    
    vStats = vSurfAll.GetStatistics; 
    vStatNames = cell(vStats.mNames);
    vValues = vStats.mValues;
    % Ordering Statistics
    [vUniNames, iA, ~] = unique(vStatNames);
    if strcmp(ver, '2017a')
        posEllipCX0 = iA(contains(vUniNames, 'Ellipsoid Axis C X'));
        posEllipCY0 = iA(contains(vUniNames, 'Ellipsoid Axis C Y'));
        posEllipCZ0 = iA(contains(vUniNames, 'Ellipsoid Axis C Z'));
        posEllipCL0 = iA(contains(vUniNames, 'BoundingBoxOO Length C'));
        posCoMX0 = iA(contains(vUniNames, 'Center of Homogeneous Mass X'));
        posCoMY0 = iA(contains(vUniNames, 'Center of Homogeneous Mass Y'));
        posCoMZ0 = iA(contains(vUniNames, 'Center of Homogeneous Mass Z'));
    else
        posEllipCX0 = iA(cellfun(@(x) ~isempty(strfind(x, 'Ellipsoid Axis C X')), vUniNames));
        posEllipCY0 = iA(cellfun(@(x) ~isempty(strfind(x, 'Ellipsoid Axis C Y')), vUniNames));
        posEllipCZ0 = iA(cellfun(@(x) ~isempty(strfind(x, 'Ellipsoid Axis C Z')), vUniNames));
        posEllipCL0 = iA(cellfun(@(x) ~isempty(strfind(x, 'BoundingBoxOO Length C')), vUniNames));
        posCoMX0 = iA(cellfun(@(x) ~isempty(strfind(x, 'Center of Homogeneous Mass X')), vUniNames));
        posCoMY0 = iA(cellfun(@(x) ~isempty(strfind(x, 'Center of Homogeneous Mass Y')), vUniNames));
        posCoMZ0 = iA(cellfun(@(x) ~isempty(strfind(x, 'Center of Homogeneous Mass Z')), vUniNames));
    end
    
    % Sub Folder
    vSubFolderSep = vImarisApplication.GetFactory.CreateDataContainer;
    vSubFolderSep.SetName(vName)
    vSubFolderOne = vImarisApplication.GetFactory.CreateDataContainer;
    vSubFolderOne.SetName(vName)
    
    for iTime = 1:vTimeSurf
        fprintf('Starting time point %d/%d... (%s)\n', iTime, vTimeSurf, vName)
        vEllipCX = vValues(posEllipCX0 + iTime - 1);
        vEllipCY = vValues(posEllipCY0 + iTime - 1);
        vEllipCZ = vValues(posEllipCZ0 + iTime - 1);
        vEllipCL = vValues(posEllipCL0 + iTime - 1)/2;
        vCoMX = vValues(posCoMX0 + iTime - 1);
        vCoMY = vValues(posCoMY0 + iTime - 1);
        vCoMZ = vValues(posCoMZ0 + iTime - 1);
        
        VecEllip = [vEllipCX vEllipCY vEllipCZ];
        VecCoM = [vCoMX vCoMY vCoMZ];
        
        % Removes duplicate statistic entries
        VecEllip = VecEllip(1,:);
        VecCoM = VecCoM(1,:);
        vEllipCL = vEllipCL(1);

        ptA = VecCoM + VecEllip*vEllipCL;
        ptB = VecCoM - VecEllip*vEllipCL;
        
        aPosXYZ = [VecCoM; ptA; VecCoM; ptB];
        aRadii = single(ones(numPoints, 1)*aWidth);
        aTypesFil = int32(zeros(numPoints, 1));
        aEdges = [(1:numPoints-1)' (2:numPoints)'];
        aTimeIdxFilOne = 0;
        aTimeIdxFilSep = iTime-1;
        
        % Creating Filaments
        vFilamentsSep = vImarisApplication.GetFactory.CreateFilaments;
        vFilamentsSep.AddFilament(aPosXYZ, aRadii, aTypesFil, aEdges, aTimeIdxFilSep);
        vFilamentsSep.SetName([vName ' Filaments t' num2str(iTime)]);  
        vFilamentsSep.SetColorRGBA(vColor);
        vFilamentsSep.SetColorSpinesRGBA(vColor);
        vSubFolderSep.AddChild(vFilamentsSep, -1)
        
        vFilamentsOne = vImarisApplication.GetFactory.CreateFilaments;
        vFilamentsOne.AddFilament(aPosXYZ, aRadii, aTypesFil, aEdges, aTimeIdxFilOne);
        vFilamentsOne.SetName([vName ' Filaments t' num2str(iTime)]);  
        vFilamentsOne.SetColorRGBA(vColor);
        vFilamentsOne.SetColorSpinesRGBA(vColor);
        vSubFolderOne.AddChild(vFilamentsOne, -1)        
    end
    vFolderSepTimePt.AddChild(vSubFolderSep, -1)
    vFolderOneTimePt.AddChild(vSubFolderOne, -1)
end

vSurpassScene.AddChild(vFolderSepTimePt, -1)
vSurpassScene.AddChild(vFolderOneTimePt, -1)