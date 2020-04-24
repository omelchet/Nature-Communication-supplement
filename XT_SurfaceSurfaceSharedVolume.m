%Surface Surface Contact Area

%Written by Matthew J. Gastinger, Bitplane Advanced Application Scientist.  
%March 2015.
%
%<CustomTools>
%      <Menu>
%       <Submenu name="Surfaces Functions">
%        <Item name="Surface-Surface Shared Volume" icon="Matlab">
%          <Command>MatlabXT::XT_SurfaceSurfaceSharedVolume(%i)</Command>
%        </Item>
%       </Submenu>
%      </Menu>
%      <SurpassTab>
%        <SurpassComponent name="bpSurfaces">
%          <Item name="Surface-Surface Shared Volume" icon="Matlab">
%            <Command>MatlabXT::XT_SurfaceSurfaceSharedVolume(%i)</Command>
%          </Item>
%        </SurpassComponent>
%      </SurpassTab>
%    </CustomTools>
% 
%Description
%This XTension will find the surface contact area between 2 surfaces.  The
%primary surface is the base, and secondary is one covering the primary. 
%
%The result of the XTension will generate a one voxel thick unsmoothed 
%surface object above the primary surface representing where the 2 surfaces
%physically overlap.
%
%Two new statistics will be generated.  1)The first will be a total surface
%area of each new surface object.  The measurement will be estimate by
%taking the number of voxels and multiplying by the area a a single (XY
%pixel).  2) The second statistic will be in the "overall" tab, reporting
%the percentage of surface contact area relative to the total surface area
%of the primary surfaces.


function XT_SurfaceSurfaceSharedVolume(aImarisApplicationID)

% connect to Imaris interface
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

% the user has to create a scene with some surfaces
vSurpassScene = vImarisApplication.GetSurpassScene;
if isequal(vSurpassScene, [])
    msgbox('Please create some Surfaces in the Surpass scene!');
    return;
end

%%
% get all Surpass surfaces names
vSurfaces = vImarisApplication.GetFactory.ToSurfaces(vImarisApplication.GetSurpassSelection);
vSurfacesSelected = vImarisApplication.GetFactory.IsSurfaces(vSurfaces);

if vSurfacesSelected
    vScene = vSurfaces.GetParent;
else
    vScene = vImarisApplication.GetSurpassScene;
end
vNumberOfSurfaces = 0;
vSurfacesList{vScene.GetNumberOfChildren} = [];
vNamesList{vScene.GetNumberOfChildren} = [];
for vChildIndex = 1:vScene.GetNumberOfChildren
    vDataItem = vScene.GetChild(vChildIndex - 1);
    if vImarisApplication.GetFactory.IsSurfaces(vDataItem)
        vNumberOfSurfaces = vNumberOfSurfaces+1;
        vSurfacesList{vNumberOfSurfaces} = vImarisApplication.GetFactory.ToSurfaces(vDataItem);
        vNamesList{vNumberOfSurfaces} = char(vDataItem.GetName);
    end
end

if vNumberOfSurfaces<2
    msgbox('Please create at least 2 surfaces objects!');
    return;
end

vNamesList = vNamesList(1:vNumberOfSurfaces);
%%
%Choose the surfaces
%Choose how many surfaces to colocalize
vPrimarySurface=1;
vSecondarySurface=1;
vPair = [];
while vPrimarySurface==vSecondarySurface
%Create Dialog box and allow user to choose the Reference Position
    vPair = [];
        [vPair, vOk] = listdlg('ListString',vNamesList,'SelectionMode','single',...
            'ListSize',[250 150],'Name','Surface-Surface Contact Area','InitialValue',1, ...
            'PromptString',{'Please select Primary Surface'});
    vPrimarySurface = vSurfacesList{vPair(1)};
    NumberPrimarySurfaces=vPrimarySurface.GetNumberOfSurfaces;
%Create Dialog box and allow user to choose the Reference Position
    vPair = [];
        [vPair, vOk] = listdlg('ListString',vNamesList,'SelectionMode','single',...
            'ListSize',[250 150],'Name','Surface-Surface Contact Area','InitialValue',2, ...
            'PromptString',{'Please select Secondary coverage surface'});
    vSecondarySurface = vSurfacesList{vPair(1)};
    if vPrimarySurface==vSecondarySurface
        uiwait(msgbox('Please choose 2 different surfaces'));
        
    end
end

% Create dialog box for timepoint
timePoint = inputdlg('Enter in timepoint starting at 1','Time Point',1);
timePoint = str2num(timePoint{1}) - 1;

%%
%Get Image Data parameters
vDataSet0 = vImarisApplication.GetDataSet;

aExtendMaxX = vDataSet0.GetExtendMaxX;
aExtendMaxY = vDataSet0.GetExtendMaxY;
aExtendMaxZ = vDataSet0.GetExtendMaxZ;
aExtendMinX = vDataSet0.GetExtendMinX;
aExtendMinY = vDataSet0.GetExtendMinY;
aExtendMinZ = vDataSet0.GetExtendMinZ;
aSizeX = vDataSet0.GetSizeX;
aSizeY = vDataSet0.GetSizeY;
aSizeZ = vDataSet0.GetSizeZ;
aSizeC = vDataSet0.GetSizeC;
aSizeT = vDataSet0.GetSizeT;
Xvoxelspacing = (aExtendMaxX-aExtendMinX)/aSizeX;
Zvoxelspacing = (aExtendMaxZ-aExtendMinZ)/aSizeZ;

vSmoothingFactor=Xvoxelspacing*2;
ZLimit=((3*Xvoxelspacing)+100*Xvoxelspacing)/100;%test percent Xvoxelsize

vDataMin = [aExtendMinX, aExtendMinY, aExtendMinZ];
vDataMax = [aExtendMaxX, aExtendMaxY, aExtendMaxZ];
vDataSize = [aSizeX, aSizeY, aSizeZ];

% Getting surface masks vPrimarySurface, vSecondarySurface
vSurfaceOneData = vPrimarySurface.GetMask( ...
      vDataMin(1), vDataMin(2), vDataMin(3), ...
      vDataMax(1), vDataMax(2), vDataMax(3), ...
      vDataSize(1), vDataSize(2), vDataSize(3), timePoint);
  
vSurfaceTwoData = vSecondarySurface.GetMask( ...
      vDataMin(1), vDataMin(2), vDataMin(3), ...
      vDataMax(1), vDataMax(2), vDataMax(3), ...
      vDataSize(1), vDataSize(2), vDataSize(3), timePoint);  
  
vSurfaceOneArr = vSurfaceOneData.GetDataVolumeBytes(0, 0);
vSurfaceTwoArr = vSurfaceTwoData.GetDataVolumeBytes(0, 0);

vSharedSurfaceLog = vSurfaceOneArr & vSurfaceTwoArr;
vSharedSurface = uint8(vSharedSurfaceLog*255);

volSOne = nnz(vSurfaceOneArr);
volSTwo = nnz(vSurfaceTwoArr);
volSSha = nnz(vSharedSurface);

disp('Voxel volumes, S1, S2, SBoth')
disp([volSOne volSTwo volSSha])

disp([max(vSharedSurface(:)) mean(vSharedSurface(:))])

aType = Imaris.tType.eTypeUInt8;
vDataSet1 = vImarisApplication.GetFactory.CreateDataSet;
vDataSet1.Create(aType, aSizeX, aSizeY, aSizeZ, 1, 1);
vDataSet1.SetExtendMaxX(aExtendMaxX);
vDataSet1.SetExtendMaxY(aExtendMaxY);
vDataSet1.SetExtendMaxZ(aExtendMaxZ);
vDataSet1.SetExtendMinX(aExtendMinX);
vDataSet1.SetExtendMinY(aExtendMinY);
vDataSet1.SetExtendMinZ(aExtendMinZ);
%vDataSet1 = vImarisApplication.GetDataSet.Clone;
%vDataSet1.SetSizeC(1);
vDataSet1.SetDataVolumeBytes(vSharedSurface, 0, 0);

ip = vImarisApplication.GetImageProcessing;
vSharedSurfaceObj = ip.DetectSurfaces(vDataSet1, [], 0, 0, 0, false, eps, '');

vImarisApplication.SetDataSet(vDataSet0);

% Create new surface
vNewSurfaces = vImarisApplication.GetFactory.CreateSurfaces;

vNewSurfaces.AddSurface(vSharedSurfaceObj.GetVertices(0), ...
    vSharedSurfaceObj.GetTriangles(0), vSharedSurfaceObj.GetNormals(0), ...
    timePoint);

vNewSurfaces.SetName(sprintf('Shared Surface'));

vSurpassScene.AddChild(vNewSurfaces, -1);

disp('Complete')
pause;

