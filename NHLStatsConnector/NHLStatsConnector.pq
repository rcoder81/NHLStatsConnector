// This file contains your Data Connector logic
section NHLStatsConnector;

///////
//      DEFINITION
//////

// Data Source UI publishing description
NHLStatsConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { "NHL REST API DEMO", "NHL REST API DEMO" },
    SourceImage = NHLStatsConnector.Icons,
    SourceTypeImage = NHLStatsConnector.Icons
];

NHLStatsConnector.Icons = [
    Icon16 = { Extension.Contents("NHLStatsConnector16.png"), Extension.Contents("NHLStatsConnector20.png"), Extension.Contents("NHLStatsConnector24.png"), Extension.Contents("NHLStatsConnector32.png") },
    Icon32 = { Extension.Contents("NHLStatsConnector32.png"), Extension.Contents("NHLStatsConnector40.png"), Extension.Contents("NHLStatsConnector48.png"), Extension.Contents("NHLStatsConnector64.png") }
];


//////
//      IMPLEMENTATION
//////


BaseUrl = "https://statsapi.web.nhl.com/api/v1/";

NHLStatsConnector.Feed = (url as text) =>
    let
        source = Web.Contents(url),
        json = Json.Document(source)
    in
        json;

//Value.ReplaceType(nhlImpl, type function (url as Uri.Type) as any);

[DataSource.Kind="NHLStatsConnector", Publish="NHLStatsConnector.Publish"]
shared NHLStatsConnector.Contents = () => NHLNavTable (BaseUrl) as table;

// Data Source Kind description
NHLStatsConnector = [
    Authentication = [
        // Key = [],
        // UsernamePassword = [],
        // Windows = [],
        Implicit = []
    ],
    Label = "NHL - REST API DEMO"
];


GetTeamDetails = (url as text) as table =>
    let
        Source = NHLStatsConnector.Feed(url & "teams"),
        teams = Source[teams],
        #"Converted to Table" = Table.FromList(teams, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "name", "link", "venue", "abbreviation", "teamName", "locationName", "firstYearOfPlay", "division", "conference", "franchise", "shortName", "officialSiteUrl", "franchiseId", "active"}, {"id", "name", "link", "venue", "abbreviation", "teamName", "locationName", "firstYearOfPlay", "division", "conference", "franchise", "shortName", "officialSiteUrl", "franchiseId", "active"}),
        #"Expanded venue" = Table.ExpandRecordColumn(#"Expanded Column1", "venue", {"name", "link", "city", "timeZone", "id"}, {"venue.name", "venue.link", "venue.city", "venue.timeZone", "venue.id"}),
        #"Expanded conference" = Table.ExpandRecordColumn(#"Expanded venue", "conference", {"name"}, {"Conference.name"}),
        #"Expanded division" = Table.ExpandRecordColumn(#"Expanded conference", "division", {"name"}, {"division.name"}),
        #"Expanded franchise" = Table.ExpandRecordColumn(#"Expanded division", "franchise", {"teamName"}, {"franchise.teamName"}),
        #"Removed Columns" = Table.RemoveColumns(#"Expanded franchise",{"venue.timeZone", "venue.link", "venue.id", "franchise.teamName"}),
        #"Renamed Columns" = Table.RenameColumns(#"Removed Columns",{{"division.name", "Division"}, {"Conference.name", "Conference"}})
    in
        #"Renamed Columns";

// GetPlayers = (url as text) as table =>
//     let
//     Source = YahooFantasyHockeyConnector.Feed(url & "teams"),
//     teams = Source[teams],
//     #"Converted to Table" = Table.FromList(teams, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
//     #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "link"}, {"id", "link"}),
//     #"Added Custom" = Table.AddColumn(#"Expanded Column1", "Custom", each YahooFantasyHockeyConnector.Feed (url & "teams/" & Text.From([id]) & "/roster")),
//     #"Expanded Custom" = Table.ExpandRecordColumn(#"Added Custom", "Custom", {"roster"}, {"roster"}),
//     #"Expanded roster" = Table.ExpandListColumn(#"Expanded Custom", "roster"),
//     #"Expanded roster1" = Table.ExpandRecordColumn(#"Expanded roster", "roster", {"person"}, {"person"}),
//     #"Expanded person" = Table.ExpandRecordColumn(#"Expanded roster1", "person", {"id", "fullName"}, {"id.1", "fullName"}),
//     #"Removed Columns" = Table.RemoveColumns(#"Expanded person",{"id", "link"})
// in
//     #"Removed Columns";

GetPlayers = (url as text) as table =>
    let
        Source = NHLStatsConnector.Feed(url & "teams"),
        teams = Source[teams],
        #"Converted to Table" = Table.FromList(teams, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "link"}, {"id", "link"}),
        #"Added Custom" = Table.AddColumn(#"Expanded Column1", "Custom", each NHLStatsConnector.Feed ("https://statsapi.web.nhl.com/api/v1/teams/" & Text.From([id]) & "/roster")),
        #"Expanded Custom" = Table.ExpandRecordColumn(#"Added Custom", "Custom", {"roster"}, {"roster"}),
        #"Expanded roster" = Table.ExpandListColumn(#"Expanded Custom", "roster"),
        #"Expanded roster1" = Table.ExpandRecordColumn(#"Expanded roster", "roster", {"person"}, {"person"}),
        #"Expanded person" = Table.ExpandRecordColumn(#"Expanded roster1", "person", {"id", "fullName"}, {"id.1", "fullName"}),
        #"Removed Columns" = Table.RemoveColumns(#"Expanded person",{"id", "link"}),
        newCol = Table.AddColumn(#"Removed Columns", "PlayerDets", each NHLStatsConnector.Feed ("https://statsapi.web.nhl.com/api/v1/people/" & Text.From([id.1]))),
        #"Expanded PlayerDets" = Table.ExpandRecordColumn(newCol, "PlayerDets", {"people"}, {"people"}),
        #"Expanded people" = Table.ExpandListColumn(#"Expanded PlayerDets", "people"),
        #"Expanded people1" = Table.ExpandRecordColumn(#"Expanded people", "people", {"firstName", "lastName", "primaryNumber", "birthDate", "birthCity", "birthCountry", "nationality", "height", "weight", "active", "alternateCaptain", "captain", "rookie", "shootsCatches", "rosterStatus", "currentTeam", "primaryPosition"}, {"firstName", "lastName", "primaryNumber", "birthDate", "birthCity", "birthCountry", "nationality", "height", "weight", "active", "alternateCaptain", "captain", "rookie", "shootsCatches", "rosterStatus", "currentTeam", "primaryPosition"})
    in
        #"Expanded people1";

 GetSingleSeasonStats = (url as text, season as number) as table =>
    let
        Source = NHLStatsConnector.Feed("https://statsapi.web.nhl.com/api/v1/teams"),
        teams = Source[teams],
        #"Converted to Table" = Table.FromList(teams, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "link"}, {"id", "link"}),
        #"Added Custom" = Table.AddColumn(#"Expanded Column1", "Custom", each NHLStatsConnector.Feed ("https://statsapi.web.nhl.com/api/v1/teams/" & Text.From([id]) & "/roster")),
        #"Expanded Custom" = Table.ExpandRecordColumn(#"Added Custom", "Custom", {"roster"}, {"roster"}),
        #"Expanded roster" = Table.ExpandListColumn(#"Expanded Custom", "roster"),
        #"Expanded roster1" = Table.ExpandRecordColumn(#"Expanded roster", "roster", {"person"}, {"person"}),
        #"Expanded person" = Table.ExpandRecordColumn(#"Expanded roster1", "person", {"id", "fullName"}, {"id.1", "fullName"}),
        #"Removed Columns" = Table.RemoveColumns(#"Expanded person",{"id", "link"}),
        newCol = Table.AddColumn(#"Removed Columns", "Stats", each NHLStatsConnector.Feed ("https://statsapi.web.nhl.com/api/v1/people/" & Text.From([id.1]) & "/stats?stats=statsSingleSeason&season=" & Text.From(season) & Text.From(season + 1))),
        #"Expanded Stats" = Table.ExpandRecordColumn(newCol, "Stats", {"stats"}, {"stats.1"}),
        #"Expanded stats.1" = Table.ExpandListColumn(#"Expanded Stats", "stats.1"),
        #"Expanded stats.2" = Table.ExpandRecordColumn(#"Expanded stats.1", "stats.1", {"splits"}, {"splits"}),
        #"Expanded splits" = Table.ExpandListColumn(#"Expanded stats.2", "splits"),
        #"Expanded splits1" = Table.ExpandRecordColumn(#"Expanded splits", "splits", {"season", "stat"}, {"season", "stat"}),
        #"Expanded stat" = Table.ExpandRecordColumn(#"Expanded splits1", "stat", {"timeOnIce", "assists", "goals", "pim", "shots", "games", "hits", "powerPlayGoals", "powerPlayPoints", "powerPlayTimeOnIce", "evenTimeOnIce", "penaltyMinutes", "faceOffPct", "shotPct", "gameWinningGoals", "overTimeGoals", "shortHandedGoals", "shortHandedPoints", "shortHandedTimeOnIce", "blocked", "plusMinus", "points", "shifts", "timeOnIcePerGame", "evenTimeOnIcePerGame", "shortHandedTimeOnIcePerGame", "powerPlayTimeOnIcePerGame"}, {"timeOnIce", "assists", "goals", "pim", "shots", "games", "hits", "powerPlayGoals", "powerPlayPoints", "powerPlayTimeOnIce", "evenTimeOnIce", "penaltyMinutes", "faceOffPct", "shotPct", "gameWinningGoals", "overTimeGoals", "shortHandedGoals", "shortHandedPoints", "shortHandedTimeOnIce", "blocked", "plusMinus", "points", "shifts", "timeOnIcePerGame", "evenTimeOnIcePerGame", "shortHandedTimeOnIcePerGame", "powerPlayTimeOnIcePerGame"})
    in
        #"Expanded stat";


NHLNavTable = (url as text) as table =>
    let
        source = #table({"Name","Data", "ItemKind", "ItemName", "IsLeaf"},{
        {"Teams", GetTeamDetails(url), "Table","Table",true},
        {"Players", GetPlayers(url), "Table", "Table", true },
        {"2019 stats", GetSingleSeasonStats(url, 2019),"Table","Table",true },
        {"2018 stats", GetSingleSeasonStats(url, 2018),"Table","Table",true }
        }),
        navTable = Table.ToNavigationTable(source,{"Name"},"Name","Data","ItemKind","ItemName","IsLeaf")
    in 
        navTable;

 Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;