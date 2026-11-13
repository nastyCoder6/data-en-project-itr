[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared api_key = "43f27a6543ffeeb2c6141bd3bff36db2935ab39016d02d8af4c9c11a4e3778c0" meta [IsParameterQuery = true, IsParameterQueryRequired = false, Type = type text, DefaultValue = ""];
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "geospatialQuery_DataDestination", IsNewTarget = true], Settings = [Kind = "Manual", AllowCreation = true, ColumnSettings = [Mappings = {[SourceColumnName = "id", DestinationColumnName = "id"], [SourceColumnName = "name", DestinationColumnName = "name"], [SourceColumnName = "locality", DestinationColumnName = "locality"], [SourceColumnName = "id.1", DestinationColumnName = "id.1"], [SourceColumnName = "name.2", DestinationColumnName = "name.2"], [SourceColumnName = "id.2", DestinationColumnName = "id.2"], [SourceColumnName = "name.3", DestinationColumnName = "name.3"], [SourceColumnName = "isMobile", DestinationColumnName = "isMobile"], [SourceColumnName = "isMonitor", DestinationColumnName = "isMonitor"], [SourceColumnName = "id.3", DestinationColumnName = "id.3"], [SourceColumnName = "name.4", DestinationColumnName = "name.4"], [SourceColumnName = "sensorId", DestinationColumnName = "sensorId"], [SourceColumnName = "name.1", DestinationColumnName = "name.1"], [SourceColumnName = "id.4", DestinationColumnName = "id.4"], [SourceColumnName = "name.5", DestinationColumnName = "name.5"], [SourceColumnName = "units", DestinationColumnName = "units"], [SourceColumnName = "displayName", DestinationColumnName = "displayName"], [SourceColumnName = "latitude", DestinationColumnName = "latitude"], [SourceColumnName = "longitude", DestinationColumnName = "longitude"], [SourceColumnName = "id.5", DestinationColumnName = "id.5"], [SourceColumnName = "name.6", DestinationColumnName = "name.6"], [SourceColumnName = "name.7", DestinationColumnName = "name.7"], [SourceColumnName = "url", DestinationColumnName = "url"], [SourceColumnName = "dateFrom", DestinationColumnName = "dateFrom"], [SourceColumnName = "dateTo", DestinationColumnName = "dateTo"], [SourceColumnName = "distance", DestinationColumnName = "distance"], [SourceColumnName = "startDate", DestinationColumnName = "startDate"], [SourceColumnName = "recentDate", DestinationColumnName = "recentDate"]}], DynamicSchema = true, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared geospatialQuery = let
    BaseUrl = "https://api.openaq.org/v3/locations",
    
    GetPage = (pageNumber as number) =>
        let
            Source = Web.Contents(BaseUrl, [
                Headers=[#"X-API-Key"=api_key],
                Query=[page=Text.From(pageNumber), limit="1000", coordinates="40.710565379274385, -73.97241157428745", radius="25000"] 
            ]),
            Json = Json.Document(Source)
        in
            Json,

    Paginate = List.Generate(
        () => [Page = 1, Data = GetPage(1)],                         
        each not List.IsEmpty([Data][results]),                
        each [Page = [Page] + 1, Data = GetPage([Page] + 1)],          
        each [Data][results]                                         
    ),
    
    CombinedList = List.Combine(Paginate),
    
    ToTable = Table.FromList(CombinedList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
  #"Expanded Column1" = Table.ExpandRecordColumn(ToTable, "Column1", {"id", "name", "locality", "timezone", "country", "owner", "provider", "isMobile", "isMonitor", "instruments", "sensors", "coordinates", "licenses", "bounds", "distance", "datetimeFirst", "datetimeLast"}, {"id", "name", "locality", "timezone", "country", "owner", "provider", "isMobile", "isMonitor", "instruments", "sensors", "coordinates", "licenses", "bounds", "distance", "datetimeFirst", "datetimeLast"}),
  #"Expanded sensors" = Table.ExpandListColumn(#"Expanded Column1", "sensors"),
  #"Expanded sensors 1" = Table.ExpandRecordColumn(#"Expanded sensors", "sensors", {"id", "name", "parameter"}, {"id.1", "name.1", "parameter"}),
  #"Renamed columns" = Table.RenameColumns(#"Expanded sensors 1", {{"id.1", "sensorId"}}),
  #"Removed columns" = Table.RemoveColumns(#"Renamed columns", {"timezone", "country"}),
  #"Expanded owner" = Table.ExpandRecordColumn(#"Removed columns", "owner", {"id", "name"}, {"id.1", "name.2"}),
  #"Expanded provider" = Table.ExpandRecordColumn(#"Expanded owner", "provider", {"id", "name"}, {"id.2", "name.3"}),
  #"Expanded coordinates" = Table.ExpandRecordColumn(#"Expanded provider", "coordinates", {"latitude", "longitude"}, {"latitude", "longitude"}),
  #"Expanded instruments" = Table.ExpandListColumn(#"Expanded coordinates", "instruments"),
  #"Expanded instruments 1" = Table.ExpandRecordColumn(#"Expanded instruments", "instruments", {"id", "name"}, {"id.3", "name.4"}),
  #"Expanded parameter" = Table.ExpandRecordColumn(#"Expanded instruments 1", "parameter", {"id", "name", "units", "displayName"}, {"id.4", "name.5", "units", "displayName"}),
  #"Expanded licenses" = Table.ExpandListColumn(#"Expanded parameter", "licenses"),
  #"Expanded licenses 1" = Table.ExpandRecordColumn(#"Expanded licenses", "licenses", {"id", "name", "attribution", "dateFrom", "dateTo"}, {"id.5", "name.6", "attribution", "dateFrom", "dateTo"}),
  #"Expanded attribution" = Table.ExpandRecordColumn(#"Expanded licenses 1", "attribution", {"name", "url"}, {"name.7", "url"}),
  #"Expanded bounds" = Table.ExpandListColumn(#"Expanded attribution", "bounds"),
  #"Expanded datetimeFirst" = Table.ExpandRecordColumn(#"Expanded bounds", "datetimeFirst", {"utc", "local"}, {"utc", "local"}),
  #"Expanded datetimeLast" = Table.ExpandRecordColumn(#"Expanded datetimeFirst", "datetimeLast", {"utc", "local"}, {"utc.1", "local.1"}),
  #"Removed columns 1" = Table.RemoveColumns(#"Expanded datetimeLast", {"bounds"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed columns 1", {{"id", type text}, {"name", type text}, {"locality", type text}, {"id.1", type text}, {"name.2", type text}, {"id.2", type text}, {"name.3", type text}, {"isMobile", type logical}, {"isMonitor", type logical}, {"id.3", type text}, {"name.4", type text}, {"sensorId", type text}, {"name.1", type text}, {"id.4", type text}, {"name.5", type text}, {"units", type text}, {"displayName", type text}, {"latitude", type number}, {"longitude", type number}, {"id.5", type text}, {"url", type text}, {"name.6", type text}, {"name.7", type text}, {"dateFrom", type date}, {"utc", type datetime}, {"local", type datetime}, {"utc.1", type datetime}, {"local.1", type datetime}, {"distance", type number}, {"dateTo", type text}}),
  #"Removed columns 2" = Table.RemoveColumns(#"Changed column type", {"local", "local.1"}),
  #"Renamed columns 1" = Table.RenameColumns(#"Removed columns 2", {{"utc", "startDate"}, {"utc.1", "recentDate"}})
in
    #"Renamed columns 1";
shared geospatialQuery_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "eaae3c98-2b09-40ae-a50e-1ebe083859a5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "65d2627a-9e4f-4063-b7ff-748fee4dc732"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "OpenAQ_SENSORS_LOC_raw", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "sensorsId_DataDestination", IsNewTarget = true], Settings = [Kind = "Manual", AllowCreation = true, ColumnSettings = [Mappings = {[SourceColumnName = "ID", DestinationColumnName = "ID"], [SourceColumnName = "startDate", DestinationColumnName = "startDate"], [SourceColumnName = "recentDate", DestinationColumnName = "recentDate"]}], DynamicSchema = true, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared sensorsId = let
  Source = geospatialQuery,
  #"Removed other columns" = Table.SelectColumns(Source, {"sensorId", "startDate", "recentDate"}),
  #"Removed duplicates" = Table.Distinct(#"Removed other columns", {"sensorId", "startDate", "recentDate"}),
  #"Renamed columns" = Table.RenameColumns(#"Removed duplicates", {{"sensorId", "ID"}}),
  #"Extracted year" = Table.TransformColumns(#"Renamed columns", {{"startDate", each Date.Year(_), type nullable number}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Extracted year", {{"startDate", Int64.Type}}),
  #"Extracted year 1" = Table.TransformColumns(#"Changed column type", {{"recentDate", each Date.Year(_), type nullable number}}),
  #"Changed column type 1" = Table.TransformColumnTypes(#"Extracted year 1", {{"recentDate", Int64.Type}})
in
  #"Changed column type 1";
shared sensorsId_DataDestination = let
  Pattern = Lakehouse.Contents([HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true, CreateNavigationProperties = false, EnableFolding = false]),
  Navigation_1 = Pattern{[workspaceId = "eaae3c98-2b09-40ae-a50e-1ebe083859a5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "65d2627a-9e4f-4063-b7ff-748fee4dc732"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "sensors", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
