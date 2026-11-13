[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Query_DataDestination", IsNewTarget = true], Settings = [Kind = "Manual", AllowCreation = true, ColumnSettings = [Mappings = {[SourceColumnName = "id.1", DestinationColumnName = "id.1"], [SourceColumnName = "value.2", DestinationColumnName = "value.2"], [SourceColumnName = "id", DestinationColumnName = "id"], [SourceColumnName = "value.1", DestinationColumnName = "value.1"], [SourceColumnName = "countryiso3code", DestinationColumnName = "countryiso3code"], [SourceColumnName = "date", DestinationColumnName = "date"], [SourceColumnName = "value", DestinationColumnName = "value"], [SourceColumnName = "unit", DestinationColumnName = "unit"], [SourceColumnName = "obs_status", DestinationColumnName = "obs_status"], [SourceColumnName = "decimal", DestinationColumnName = "decimal"]}], DynamicSchema = true, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared Query = let
  Source = Json.Document(Web.Contents("https://api.worldbank.org/v2/country/USA/indicator/NY.GDP.MKTP.CD?format=json")),
  Navigation = Source{1},
  #"Converted to table" = Table.FromList(Navigation, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
  #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to table", "Column1", {"indicator", "country", "countryiso3code", "date", "value", "unit", "obs_status", "decimal"}, {"indicator", "country", "countryiso3code", "date", "value", "unit", "obs_status", "decimal"}),
  #"Expanded country" = Table.ExpandRecordColumn(#"Expanded Column1", "country", {"id", "value"}, {"id", "value.1"}),
  #"Expanded indicator" = Table.ExpandRecordColumn(#"Expanded country", "indicator", {"id", "value"}, {"id.1", "value.2"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Expanded indicator", {{"id.1", type text}, {"value.2", type text}, {"id", type text}, {"value.1", type text}, {"countryiso3code", type text}, {"unit", type text}, {"obs_status", type text}, {"date", Int64.Type}, {"value", Int64.Type}, {"decimal", Int64.Type}})
in
  #"Changed column type";
shared Query_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true]),
  Navigation_1 = Pattern{[workspaceId = "eaae3c98-2b09-40ae-a50e-1ebe083859a5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "65d2627a-9e4f-4063-b7ff-748fee4dc732"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "WB_USGDP_raw", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
