function generateModelsVsMethodsTables()
%% Make the models vs methods tables
%
%%
exceptionThreshold = 1;
dest = fullfile(pmtk3Root, 'docs', 'modelsByMethods');
modelTags = {
    'PMTKlatentmodel'
    'PMTKgraphicalmodel';
    'PMTKsupervisedmodel'
     'PMTKsimplemodel'};

titles = {
    'Latent Variable Models'
    'Graphical Models'
    'Supervised Models'
     'Simple Models'};

fnames = {
    'latentModels.html'
    'graphicalModels.html'
    'supervisedModels.html'
    'simpleModels.html'};

fnames = cellfuncell(@(f)fullfile(dest, f), fnames); 

R = pmtkTagReport(fullfile(pmtk3Root(), 'toolbox'));

for t = 1:numel(modelTags)
    [models, methods] = getModelsAndMethods(R, modelTags{t});
    [umodels, umethods, table] = aggregateModelsAndMethods(models, methods);
    printReport(umodels, umethods, table, exceptionThreshold, titles{t}, fnames{t});    
end
end

function [models, methods] = getModelsAndMethods(R, modelClass)
%% Return the model and method names for a given modelClass 'unaggregated'
% R is the full tag report
%%
files   = R.tagmap.(modelClass)';
fndx    = cellfun(@(f)R.filendx(f), files);
tags    = R.tags(fndx);
tagtext = R.tagtext(fndx);
maps    = cellfun(@createStruct, tags, tagtext, 'uniformoutput', false);
models  = strtrim(cellfuncell(@(m)m.(modelClass), maps));
fnames  = strtrim(fnameOnly(files));
for i = 1:numel(fnames)
    fname = fnames{i};
    model = models{i};
    if startswith(fname, model)
        fname = fname(length(model)+1:end);
    end
    fnames{i} = fname;
end
%methods = lower(fnames);
methods = fnames;
end

function [umodels, umethods, table] = aggregateModelsAndMethods(models, methods)
%% Aggregate the models and methods into a table
% umodels are the unique model names
% umethods are the unique method names
% table(i, j) = 1 if umodels{i} has umethods{j}
%%
umodels   = unique(models);
umethods  = unique(methods);
modelMap  = enumerate(umodels);
methodMap = enumerate(umethods);
table = zeros(numel(umodels), numel(umethods));
for i=1:numel(models)
   table(modelMap.(models{i}), methodMap.(methods{i})) = 1; 
end
end

function printReport(umodels, umethods, table, exceptionThreshold, title, fname)
%% Print the html report

count = sum(table); 
exceptions = count <= exceptionThreshold;

colNames = umethods(~exceptions);
rowNames = umodels;
data = repmat({'N'}, numel(rowNames), numel(colNames)); 
dataColors = repmat({'red'}, numel(rowNames), numel(colNames)); 
data(logical(table(:, ~exceptions))) = {'Y'};
dataColors(logical(table(:, ~exceptions))) = {'lightgreen'};

%% add exceptions
exceptionTxt = gatherExceptions(umodels, umethods, table, exceptionThreshold); 
colNames = [rowvec(colNames), {'Exceptions'}]; 
data = [data, exceptionTxt]; 
dataColors = [dataColors, repmat({'white'}, numel(rowNames), 1)]; 

pmtkRed = getConfigValue('PMTKred');
header = formatHtmlText(...
{    
'<font align="left" style="color:%s"><h2>PMTK Models-by-Methods Report: %s</h2></font>' 
'Auto-generated by %s.m'
''
'Revision Date: %s'
''
''
''
}, pmtkRed, title, mfilename, date);

len = cellfun('length', colNames);
maxNlen = max(len);
for i=1:numel(colNames)
    name = colNames{i};
    l = len(i);
    pad = repmat('&nbsp;', 1, ceil((maxNlen + 4 - l)/2));
    name = sprintf('%s%s%s',pad, name, pad);
    colNames{i} = name;
end

%% create table
htmlTable(  'data'          , data                         , ...
            'header'        , header                       , ...
            'dataAlign'     , 'center'                     , ...
            'rowNames'      , rowNames                     , ...
            'colNames'      , colNames                     , ...
            'doSave'        , true                         , ...
            'filename'      , fname                        , ...
            'doShow'        , false                        , ...
            'dataColors'    , dataColors                   , ...
            'dataValign'   , 'center'); 
end

function exceptionTxt = gatherExceptions(umodels, umethods, table, thresh)
%% Create the text for the exception column of a report
exceptionNdx = sum(table) <= thresh;
exceptionTxt = cell(numel(umodels), 1); 
for i=1:numel(umodels)
    exceptionTxt{i} = formatHtmlText(umethods(exceptionNdx & table(i, :)));
end
end

