[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared api_key = "43f27a6543ffeeb2c6141bd3bff36db2935ab39016d02d8af4c9c11a4e3778c0" meta [IsParameterQuery = true, IsParameterQueryRequired = true, Type = type text];
shared target_year = "2017" meta [IsParameterQuery = true, IsParameterQueryRequired = true, Type = type text];
shared sensor_id = "674" meta [IsParameterQuery = true, IsParameterQueryRequired = true, Type = type text];
shared fetchHourlyData = let
  BaseUrl = "https://api.openaq.org/v3/",
  GetPage = (pageNumber as number) =>
  let
  Source = Web.Contents(
    BaseUrl, 
    [
      RelativePath= "sensors/" & sensor_id &"/hours", 
      Headers = [#"X-API-Key" = api_key], 
      Query= [page= Text.From(pageNumber), limit="1000", datetime_from= target_year & "-01-01", datetime_to= target_year & "-12-31"],
      Timeout= #duration(0,0,3,0)
    ]),
  Json = Json.Document(Source)
  in
    Json,

  Pages = List.Generate(
    () => [Page = 1, Data = GetPage(1)],
    each not List.IsEmpty([Data][results]),
    each [Page = [Page] + 1, Data = GetPage([Page] + 1)],
    each [Data][results]
  ),

  CombList = List.Combine(Pages),
  ToTable = Table.FromRecords(CombList),
  #"Changed column type" = Table.TransformColumnTypes(ToTable, {{"value", type number}}),
  #"Expanded flagInfo" = Table.ExpandRecordColumn(#"Changed column type", "flagInfo", {"hasFlags"}, {"hasFlags"}),
  #"Expanded parameter" = Table.ExpandRecordColumn(#"Expanded flagInfo", "parameter", {"id", "name", "units", "displayName"}, {"id", "name", "units", "displayName"}),
  #"Expanded period" = Table.ExpandRecordColumn(#"Expanded parameter", "period", {"label", "interval", "datetimeFrom", "datetimeTo"}, {"label", "interval", "datetimeFrom", "datetimeTo"}),
  #"Expanded summary" = Table.ExpandRecordColumn(#"Expanded period", "summary", {"min", "q02", "q25", "median", "q75", "q98", "max", "avg", "sd"}, {"min", "q02", "q25", "median", "q75", "q98", "max", "avg", "sd"}),
  #"Expanded datetimeFrom" = Table.ExpandRecordColumn(#"Expanded summary", "datetimeFrom", {"utc", "local"}, {"utc", "local"}),
  #"Expanded datetimeTo" = Table.ExpandRecordColumn(#"Expanded datetimeFrom", "datetimeTo", {"utc", "local"}, {"utc.1", "local.1"}),
  #"Changed column type 1" = Table.TransformColumnTypes(#"Expanded datetimeTo", {{"hasFlags", type logical}, {"id", type text}, {"name", type text}, {"units", type text}, {"displayName", type text}, {"label", type text}, {"interval", type time}}),
  #"Removed columns" = Table.RemoveColumns(#"Changed column type 1", {"displayName", "interval", "label", "local", "local.1"}),
  #"Changed column type 2" = Table.TransformColumnTypes(#"Removed columns", {{"utc", type datetime}, {"utc.1", type datetime}}),
  #"Renamed columns" = Table.RenameColumns(#"Changed column type 2", {{"utc", "timeFrom"}, {"utc.1", "timeTo"}}),
  #"Changed column type 3" = Table.TransformColumnTypes(#"Renamed columns", {{"sd", type number}, {"avg", type number}, {"max", type number}, {"q98", type number}, {"q75", type number}, {"median", type number}, {"q25", type number}, {"q02", type number}, {"min", type number}}),
  #"Removed columns 1" = Table.RemoveColumns(#"Changed column type 3", {"coverage", "coordinates", "min", "q02", "q25", "median", "q75", "q98", "max", "avg", "sd"}),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Removed columns 1", "sensorId", each sensor_id), {{"sensorId", type text}}),
  #"Reordered columns" = Table.ReorderColumns(#"Added custom", {"sensorId", "value", "hasFlags", "id", "name", "units", "timeFrom", "timeTo"})
in
  #"Reordered columns";
