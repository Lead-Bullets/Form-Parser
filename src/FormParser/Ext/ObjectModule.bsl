
#Region Parser

Function Parse(XMLReader, Kinds, Kind, ReadToMap = False) Export
	Data = Undefined;
	If TypeOf(Kind) = Type("Map") Then
		Data = ParseRecord(XMLReader, Kinds, Kind, ReadToMap);
	ElsIf TypeOf(Kind) = Type("Structure") Then
		Data = ParseObject(XMLReader, Kinds, Kind, ReadToMap);
	Else
		XMLReader.Read(); // node val | node end
		If XMLReader.NodeType <> XMLNodeType.EndElement Then
			If TypeOf(Kind) = Type("TypeDescription") Then // basic
				Data = Kind.AdjustValue(XMLReader.Value);
			Else // enum
				Data = Kind[XMLReader.Value];
			EndIf;
			XMLReader.Read(); // node end
		EndIf;
	EndIf;
	Return Data;
EndFunction // Parse()

Function ParseRecord(XMLReader, Kinds, Kind, ReadToMap)
	Object = ?(ReadToMap, New Map, New Structure);
	While XMLReader.ReadAttribute() Do
		AttributeName = XMLReader.LocalName;
		AttributeKind = Kind[AttributeName];
		If AttributeKind <> Undefined Then
			Object.Insert(AttributeName, AttributeKind.AdjustValue(XMLReader.Value));
		EndIf;
	EndDo;
	While XMLReader.Read() // node beg | parent end | none
		And XMLReader.NodeType = XMLNodeType.StartElement Do
		PropertyName = XMLReader.LocalName;
		PropertyKind = Kind[PropertyName];
		If PropertyKind = Undefined Then
			XMLReader.Skip();
		Else
			Object.Insert(PropertyName, Parse(XMLReader, Kinds, PropertyKind, ReadToMap));
		EndIf;
	EndDo;
	If XMLReader.NodeType = XMLNodeType.Text Then
		PropertyName = "_"; // noname
		PropertyKind = Kind[PropertyName];
		If PropertyKind <> Undefined Then
			Object.Insert(PropertyName, PropertyKind.AdjustValue(XMLReader.Value));
		EndIf;
		XMLReader.Read(); // node end
	EndIf;
	Return Object;
EndFunction // ParseRecord()

Function ParseObject(XMLReader, Kinds, Kind, ReadToMap)
	Data = ?(ReadToMap, New Map, New Structure);
	Attributes = Kind.Attributes;
	While XMLReader.ReadAttribute() Do
		AttributeName = XMLReader.LocalName;
		AttributeKind = Attributes[AttributeName];
		If AttributeKind <> Undefined Then
			Data.Insert(AttributeName, AttributeKind.AdjustValue(XMLReader.Value));
		EndIf;
	EndDo;
	Items = Kind.Items;
	For Each Item In Items Do
		Data.Insert(Item.Key, New Array);
	EndDo;
	While XMLReader.Read() // node beg | parent end | none
		And XMLReader.NodeType = XMLNodeType.StartElement Do
		ItemName = XMLReader.LocalName;
		ItemKind = Items[ItemName];
		If ItemKind = Undefined Then
			XMLReader.Skip(); // node end
		Else
			Data[ItemName].Add(Parse(XMLReader, Kinds, ItemKind, ReadToMap));
		EndIf;
	EndDo;
	Return Data;
EndFunction // ParseObject()

#EndRegion // Parser

#Region Kinds

Function Kinds() Export

	Kinds = New Structure;

	// basic
	Kinds.Insert("String", New TypeDescription("String"));
	Kinds.Insert("Boolean", New TypeDescription("Boolean"));
	Kinds.Insert("Decimal", New TypeDescription("Number"));
	Kinds.Insert("DateTime", "String");
	Kinds.Insert("UUID", "String");

	// simple
	Kinds.Insert("MDObjectRef", "String");
	Kinds.Insert("FormItemRef", "String");
	Kinds.Insert("DataPath", "String");
	Kinds.Insert("LFEDataPath", "String");
	Kinds.Insert("QName", "String");
	Kinds.Insert("base64Binary", "String");
	Kinds.Insert("Field", "String");

	// common
	Kinds.Insert("LocalStringType", LocalStringType());
	Kinds.Insert("TypeDescription", TypeDescription());

	// form
	Kinds.Insert("Form", Form());
	Kinds.Insert("ChildItems", ChildItems());

	Kinds.Insert("ContextMenu", ContextMenu());
	Kinds.Insert("AutoCommandBar", AutoCommandBar());
	Kinds.Insert("LabelDecoration", LabelDecoration());
	Kinds.Insert("SearchStringAddition", SearchStringAddition());
	Kinds.Insert("ViewStatusAddition", ViewStatusAddition());
	Kinds.Insert("SearchControlAddition", SearchControlAddition());

	Resolve(Kinds, Kinds);

	Return Kinds;

EndFunction // Kinds()

Procedure Resolve(Kinds, Object)
	Var Keys, Item, Key;
	Keys = New Array;
	For Each Item In Object Do
		Keys.Add(Item.Key);
	EndDo;
	For Each Key In Keys Do
		Value = Object[Key];
		If TypeOf(Value) = Type("String") Then
			Object[Key] = Kinds[Value]
		ElsIf TypeOf(Value) = Type("Map")
			Or TypeOf(Value) = Type("Structure") Then
			Resolve(Kinds, Value);
		EndIf;
	EndDo;
EndProcedure // Resolve()

Function Record(Base = Undefined)
	Record = New Map;
	If Base <> Undefined Then
		For Each Item In Base Do
			Record[Item.Key] = Item.Value;
		EndDo;
	EndIf;
	Return Record;
EndFunction // Record()

Function Object(Base = Undefined)
	Object = New Structure;
	Object.Insert("Attributes", New Map);
	Object.Insert("Items", New Map);
	If Base <> Undefined Then
		For Each Item In Base.Items Do
			Object.Items.Add(Item);
		EndDo;
	EndIf;
	Return Object;
EndFunction // Object()

#EndRegion // Kinds

#Region Common

Function LocalStringType()
	This = Object();
	Items = This.Items;
	Items["item"] = LocalStringTypeItem();
	Return This;
EndFunction // LocalStringType()

Function LocalStringTypeItem()
	This = Record();
	This["lang"] = "String";
	This["content"] = "String";
	Return This
EndFunction // LocalStringTypeItem()

Function TypeDescription()
	This = Object();
	Items = This.Items;
	Items["Type"] = "QName";
	Items["TypeSet"] = "QName";
	Items["TypeId"] = "UUID";
	Items["NumberQualifiers"]     = NumberQualifiers();
	Items["StringQualifiers"]     = StringQualifiers();
	Items["DateQualifiers"]       = DateQualifiers();
	Items["BinaryDataQualifiers"] = BinaryDataQualifiers();
	Return This;
EndFunction // TypeDescription()

Function NumberQualifiers()
	This = Record();
	This["Digits"]         = "Decimal";
	This["FractionDigits"] = "Decimal";
	This["AllowedSign"]    = "String"; //Enums.AllowedSign;
	Return This;
EndFunction // NumberQualifiers()

Function StringQualifiers()
	This = Record();
	This["Length"]        = "Decimal";
	This["AllowedLength"] = "String"; //Enums.AllowedLength;
	Return This;
EndFunction // StringQualifiers()

Function DateQualifiers()
	This = Record();
	This["DateFractions"] = "String"; //Enums.DateFractions;
	Return This;
EndFunction // DateQualifiers()

Function BinaryDataQualifiers()
	This = Record();
	This["Length"] = "Decimal";
	This["AllowedLength"] = "String"; //Enums.AllowedLength;
	Return This;
EndFunction // BinaryDataQualifiers()

#EndRegion // Common

#Region Form

Function FormVisualEntity()
	This = Record(PredefinedChildItems());
	This["Events"]     = FormItemEvents();
	This["ChildItems"] =  "ChildItems";
	Return This;
EndFunction // FormVisualEntity()

Function PredefinedChildItems()
	This = Record();
	This["ContextMenu"]           = "ContextMenu";
	This["AutoCommandBar"]        = "AutoCommandBar";
	This["ExtendedTooltip"]       = "LabelDecoration";
	This["SearchStringAddition"]  = "SearchStringAddition";
	This["ViewStatusAddition"]    = "ViewStatusAddition";
	This["SearchControlAddition"] = "SearchControlAddition";
	Return This;
EndFunction // PredefinedChildItems()

Function Form()
	This = Record(FormVisualEntity());
	This["Title"]                          = "LocalStringType";
	This["Width"]                          = "Decimal";
	This["Height"]                         = "Decimal";
	This["WindowOpeningMode"]              = "String"; //Enums.FormWindowOpeningMode;
	This["EnterKeyBehavior"]               = "String"; //Enums.FormEnterKeyBehavior;
	This["AutoSaveDataInSettings"]         = "String"; //Enums.AutoSaveFormDataInSettings;
	This["SaveDataInSettings"]             = "String"; //Enums.SaveFormDataInSettings;
	This["SettingsStorage"]                = "MDObjectRef";
	This["AutoTitle"]                      = "Boolean";
	This["AutoURL"]                        = "Boolean";
	This["Group"]                          = "String"; //Enums.FormChildrenGroup;
	This["ChildrenAlign"]                  = "String"; //Enums.FormChildrenAlign;
	This["HorizontalSpacing"]              = "String"; //Enums.FormItemSpacing;
	This["VerticalSpacing"]                = "String"; //Enums.FormItemSpacing;
	This["HorizontalAlign"]                = "String"; //Enums.ItemHorizontalAlignment;
	This["VerticalAlign"]                  = "String"; //Enums.ItemVerticalAlignment;
	This["ChildItemsWidth"]                = "String"; //Enums.FormChildrenWidth;
	This["AutoFillCheck"]                  = "Boolean";
	This["Customizable"]                   = "Boolean";
	This["Enabled"]                        = "Boolean";
	This["ReadOnly"]                       = "Boolean";
	This["CommandBarLocation"]             = "String"; //Enums.FormElementCommandBarLocation;
	This["VerticalScroll"]                 = "String"; //Enums.LogFormScrollMode
	This["ScalingMode"]                    = "String"; //Enums.FormBaseFontVariant;
	This["Scale"]                          = "Decimal";
	This["ConversationsRepresentation"]    = "String"; //Enums.LogFormShowConversations;
	This["CommandSet"]                     = CommandsContent();
	This["ShowTitle"]                      = "Boolean";
	This["ShowCloseButton"]                = "Boolean";
	This["UseForFoldersAndItems"]          = "String"; //Enums.FoldersAndItemsUse;
	This["GroupList"]                      = "FormItemRef";
	This["AutoTime"]                       = "String"; //Enums.AutoTimeMode;
	This["UsePostingMode"]                 = "String"; //Enums.PostingModeUse;
	This["RepostOnWrite"]                  = "Boolean";
	This["ReportResult"]                   = "LFEDataPath";
	This["DetailsData"]                    = "LFEDataPath";
	This["ReportFormType"]                 = "String"; //Enums.ReportFormType;
	This["VariantAppearance"]              = "LFEDataPath";
	This["AutoShowState"]                  = "String"; //Enums.AutoShowStateMode;
	This["CustomSettingsFolder"]           = "FormItemRef";
	This["Attributes"]                     = FormAttributes();
	This["Commands"]                       = FormCommands();
	This["Parameters"]                     = FormParameters();
	This["CommandInterface"]               = FormCommandInterface();
	//This["BaseForm"]                       = "Form";
	Return This;
EndFunction // Form()

Function FormItemBase()
	This = Record(FormVisualEntity());
	This["id"]   = "Decimal";
	This["name"] = "String";
	Return This;
EndFunction // FormItemBase()

Function GroupBase()
	This = Record(FormItemBase());
	This["Visible"]                  = "Boolean";
	This["UserVisible"]              = "String"; //AdjustableBoolean
	This["Enabled"]                  = "Boolean";
	This["ReadOnly"]                 = "Boolean";
	This["EnableContentChange"]      = "Boolean";
	This["Title"]                    = "LocalStringType";
	This["TitleTextColor"]           = "String"; //Color
	This["TitleFont"]                = Font();
	This["ToolTip"]                  = "LocalStringType";
	This["ToolTipRepresentation"]    = "String"; //Enums.TooltipRepresentation;
	This["Shortcut"]                 = ShortCutType();
	This["Width"]                    = "Decimal";
	This["Height"]                   = "Decimal";
	This["HorizontalStretch"]        = "String"; //Enums.BWAValue;
	This["VerticalStretch"]          = "String"; //Enums.BWAValue;
	This["GroupHorizontalAlign"]     = "String"; //Enums.ItemHorizontalAlignment;
	This["GroupVerticalAlign"]       = "String"; //Enums.ItemVerticalAlignment;
	Return This;
EndFunction // GroupBase()

Function Decoration()
	This = Record(FormItemBase());
	This["Visible"]               = "Boolean";
	This["UserVisible"]           = "String"; //AdjustableBoolean
	This["Enabled"]               = "Boolean";
	This["Width"]                 = "Decimal";
	This["AutoMaxWidth"]          = "Boolean";
	This["MaxWidth"]              = "Decimal";
	This["MinWidth"]              = "Decimal";
	This["Height"]                = "Decimal";
	This["AutoMaxHeight"]         = "Boolean";
	This["MaxHeight"]             = "Decimal";
	This["HorizontalStretch"]     = "String"; //Enums.BWAValue;
	This["VerticalStretch"]       = "String"; //Enums.BWAValue;
	This["SkipOnInput"]           = "String"; //Enums.BWAValue;
	This["TextColor"]             = "String"; //Color
	This["Font"]                  = Font();
	This["Shortcut"]              = ShortCutType();
	This["Title"]                 = FormattedStringType();
	This["ToolTip"]               = "LocalStringType";
	This["ToolTipRepresentation"] = "String"; //Enums.TooltipRepresentation;
	This["GroupHorizontalAlign"]  = "String"; //Enums.ItemHorizontalAlignment;
	This["GroupVerticalAlign"]    = "String"; //Enums.ItemVerticalAlignment;
	Return This;
EndFunction // Decoration()

Function Field()
	This = Record(FormItemBase());
	This["DataPath"]                    = "LFEDataPath";
	This["Visible"]                     = "Boolean";
	This["UserVisible"]                 = "String"; //AdjustableBoolean
	This["DefaultItem"]                 = "Boolean";
	This["Enabled"]                     = "Boolean";
	This["ReadOnly"]                    = "Boolean";
	This["SkipOnInput"]                 = "String"; //Enums.BWAValue;
	This["Title"]                       = "LocalStringType";
	This["TitleTextColor"]              = "String"; //Color
	This["TitleBackColor"]              = "String"; //Color
	This["TitleFont"]                   = Font();
	This["TitleLocation"]               = "String"; //Enums.FormElementTitleLocation;
	This["TitleHeight"]                 = "Decimal";
	This["ToolTip"]                     = "LocalStringType";
	This["ToolTipRepresentation"]       = "String"; //Enums.TooltipRepresentation;
	This["WarningOnEditRepresentation"] = "String"; //Enums.WarningOnEditRepresentation;
	This["WarningOnEdit"]               = "LocalStringType";
	This["Shortcut"]                    = ShortCutType();
	This["CommandSet"]                  = CommandsContent();
	This["HorizontalAlign"]             = "String"; //Enums.ItemHorizontalAlignment;
	This["VerticalAlign"]               = "String"; //Enums.ItemVerticalAlignment;
	This["GroupHorizontalAlign"]        = "String"; //Enums.ItemHorizontalAlignment;
	This["GroupVerticalAlign"]          = "String"; //Enums.ItemVerticalAlignment;
	This["EditMode"]                    = "String"; //Enums.TableFieldEditMode;
	This["FixingInTable"]               = "String"; //Enums.FormFixedInTable;
	This["CellHyperlink"]               = "Boolean";
	This["AutoCellHeight"]              = "Boolean";
	This["ShowInHeader"]                = "Boolean";
	This["HeaderPicture"]               = Picture();
	This["HeaderHorizontalAlign"]       = "String"; //Enums.ItemHorizontalAlignment;
	This["ShowInFooter"]                = "Boolean";
	This["FooterDataPath"]              = "LFEDataPath";
	This["FooterText"]                  = "LocalStringType";
	This["FooterTextColor"]             = "String"; //Color
	This["FooterBackColor"]             = "String"; //Color
	This["FooterFont"]                  = Font();
	This["FooterPicture"]               = Picture();
	This["FooterHorizontalAlign"]       = "String"; //Enums.ItemHorizontalAlignment;
	Return This;
EndFunction // Field()

Function CommandsContent()
	This = Record();
	This["ExcludedCommand"] = "String";
	Return This;
EndFunction // CommandsContent()

#Region Events

Function FormItemEvents()
	This = Object();
	Items = This.Items;
	Items["Event"] = FormItemEvent();
	Return This;
EndFunction // FormItemEvents()

Function FormItemEvent()
	This = Record();
	This["name"]     = "String";
	This["callType"] = "String"; //Enums.HandlerCallType;
	This["_"]        = "String";
	Return This;
EndFunction // FormItemEvent()

#EndRegion // Events

#Region Attributes

Function FormAttributes()
	This = Object();
	Items = This.Items;
	Items["Attribute"] = FormAttribute();
	// Items["ConditionalAppearance"] = "ConditionalAppearance";
	Return This;
EndFunction // FormAttributes()

Function FormAttribute()
	This = Record();
	This["name"]              = "String";
	This["id"]                = "Decimal";
	This["Type"]              = TypeDescription();
	This["Title"]             = "LocalStringType";
	This["View"]              = "String"; //AdjustableBoolean;
	This["Edit"]              = "String"; //AdjustableBoolean;
	This["MainAttribute"]     = "Boolean";
	This["SavedData"]         = "Boolean";
	This["FillCheck"]         = "String"; //Enums.FillChecking
	This["UseAlways"]         = ContentType();
	This["Save"]              = ContentType();
	This["FunctionalOptions"] = FunctionalOptions();
	This["Columns"]           = FormAttributeColumns();
	//This["Settings"]          = "";
	Return This;
EndFunction // FormAttribute()

Function ContentType()
	This = Object();
	Items = This.Items;
	Items["Field"] = "LFEDataPath";
	Return This;
EndFunction // ContentType()

Function FunctionalOptions()
	This = Object();
	Items = This.Items;
	Items["Item"] = "MDObjectRef";
	Return This;
EndFunction // FunctionalOptions()

#Region Columns

Function FormAttributeColumns()
	This = Object();
	Items = This.Items;
	Items["Column"]            = FormAttributeColumn();
	Items["AdditionalColumns"] = FormAttributeAdditionalColumns();
	Return This;
EndFunction // FormAttributeColumns()

Function FormAttributeAdditionalColumns()
	This = Object();
	Attributes = This.Attributes;
	Attributes["table"] = "LFEDataPath";
	Items = This.Items;
	Items["Column"] = FormAttributeColumn();
	Return This;
EndFunction // FormAttributeAdditionalColumns()

Function FormAttributeColumn()
	This = Record();
	This["name"]              = "String";
	This["id"]                = "Decimal";
	This["Title"]             = "LocalStringType";
	This["View"]              = "String"; //AdjustableBoolean;
	This["Edit"]              = "String"; //AdjustableBoolean;
	This["FillCheck"]         = "String"; //Enums.FillChecking
	This["FunctionalOptions"] = FunctionalOptions();
	Return This;
EndFunction // FormAttributeColumn()

#EndRegion // Columns

#EndRegion // Attributes

#Region Commands

Function FormCommands()
	This = Object();
	Items = This.Items;
	Items["Command"] = FormCommand();
	Return This;
EndFunction // FormCommands()

Function FormCommand()
	This = Record();
	This["name"]                     = "String";
	This["id"]                       = "Decimal";
	This["Title"]                    = "LocalStringType";
	This["ToolTip"]                  = "LocalStringType";
	This["Use"]                      = "String"; //AdjustableBoolean;
	This["Shortcut"]                 = ShortCutType();
	This["Picture"]                  = Picture();
	This["Action"]                   = FormCommandAction();
	This["FunctionalOptions"]        = FunctionalOptions();
	This["Representation"]           = "String"; //Enums.DefaultRepresentation;
	This["ModifiesSavedData"]        = "Boolean";
	This["CurrentRowUse"]            = "String"; //Enums.CurrentRowUse;
	This["AssociatedTableElementId"] = "Decimal";
	Return This;
EndFunction // FormCommand()

Function FormCommandAction()
	This = Record();
	This["callType"] = "String"; //Enums.HandlerCallType;
	This["_"]        = "String";
	Return This;
EndFunction // FormCommandAction()

#EndRegion // Commands

#Region CommandInterface

Function FormCommandInterface()
	This = Record();
	This["NavigationPanel"] = FormCommandInterfaceItems();
	This["CommandBar"]      = FormCommandInterfaceItems();
	Return This;
EndFunction // FormCommandInterface()

Function FormCommandInterfaceItems()
	This = Object();
	Items = This.Items;
	Items["Item"] = FormCommandInterfaceItem();
	Return This;
EndFunction // FormCommandInterfaceItems()

Function FormCommandInterfaceItem()
	This = Record();
	This["Command"]        = "String";
	This["Type"]           = "String"; //Enums.CommandKind;
	This["Attribute"]      = "LFEDataPath";
	This["CommandGroup"]   = "String";
	This["Index"]          = "Decimal";
	This["DefaultVisible"] = "Boolean";
	This["Visible"]        = "String"; //AdjustableBoolean;
	Return This;
EndFunction // FormCommandInterfaceItem()

#EndRegion // CommandInterface

#Region Parameters

Function FormParameters()
	This = Object();
	Items = This.Items;
	Items["Parameter"] = FormParameter();
	Return This;
EndFunction // FormParameters()

Function FormParameter()
	This = Record();
	This["name"] = "String";
	This["Type"] = "TypeDescription";
	This["KeyParameter"] = "Boolean";
	Return This;
EndFunction // FormParameter()

#EndRegion // Parameters

#Region Addition

Function Addition()
	This = Record(FormItemBase());
	This["Source"]                = AdditionSource();
	This["AdditionSource"]        = AdditionSource();
	This["Visible"]               = "Boolean";
	This["UserVisible"]           = "String"; //AdjustableBoolean
	This["Enabled"]               = "Boolean";
	This["PlacementArea"]         = "String"; //Enums.MenuElementPlacementArea;
	This["Title"]                 = "LocalStringType";
	This["ToolTip"]               = "LocalStringType";
	This["ToolTipRepresentation"] = "String"; //Enums.TooltipRepresentation;
	This["GroupHorizontalAlign"]  = "String"; //Enums.ItemHorizontalAlignment;
	This["GroupVerticalAlign"]    = "String"; //Enums.ItemVerticalAlignment;
	Return This;
EndFunction

Function AdditionSource()
	This = Record();
	This["Item"] = "String";
	This["Type"] = "String"; //Enums.LogFormElementAdditionKind;
	Return This;
EndFunction // AdditionSource()

#EndRegion // Addition

#Region ChildItems

Function ChildItems()
	This = Object();
	Items = This.Items;
	Items["AutoCommandBar"]           = AutoCommandBar();
	Items["Button"]                   = Button();
	Items["ButtonGroup"]              = ButtonGroup();
	Items["CalendarField"]            = CalendarField();
	Items["ChartField"]               = ChartField();
	Items["CheckBoxField"]            = CheckBoxField();
	Items["ColumnGroup"]              = ColumnGroup();
	Items["CommandBar"]               = CommandBar();
	Items["ContextMenu"]              = ContextMenu();
	Items["DendrogramField"]          = DendrogramField();
	Items["FormattedDocumentField"]   = FormattedDocumentField();
	Items["GanttChartField"]          = GanttChartField();
	Items["GeographicalSchemaField"]  = GeographicalSchemaField();
	Items["GraphicalSchemaField"]     = GraphicalSchemaField();
	Items["HTMLDocumentField"]        = HTMLDocumentField();
	Items["InputField"]               = InputField();
	Items["LabelDecoration"]          = LabelDecoration();
	Items["LabelField"]               = LabelField();
	Items["Page"]                     = Page();
	Items["Pages"]                    = Pages();
	Items["PeriodField"]              = PeriodField();
	Items["PictureDecoration"]        = PictureDecoration();
	Items["PictureField"]             = PictureField();
	Items["PlannerField"]             = PlannerField();
	Items["Popup"]                    = Popup();
	Items["ProgressBarField"]         = ProgressBarField();
	Items["RadioButtonField"]         = RadioButtonField();
	Items["SearchControlAddition"]    = SearchControlAddition();
	Items["SearchStringAddition"]     = SearchStringAddition();
	Items["SpreadSheetDocumentField"] = SpreadSheetDocumentField();
	Items["Table"]                    = Table();
	Items["TextDocumentField"]        = TextDocumentField();
	Items["TrackBarField"]            = TrackBarField();
	Items["UsualGroup"]               = UsualGroup();
	Items["ViewStatusAddition"]       = ViewStatusAddition();
	Return This;
EndFunction // ChildItems()

Function AutoCommandBar()
	This = Record(GroupBase());
	This["HorizontalAlign"] = "String"; //Enums.ItemHorizontalAlignment;
	This["Autofill"]        = "Boolean";
	Return This;
EndFunction // AutoCommandBar()

Function Button()
	This = Record(FormItemBase());
	This["Type"]                        = "String"; //Enums.ManagedFormButtonType;
	This["DataPath"]                    = "LFEDataPath";
	This["CommandName"]                 = "String";
	//This["Parameter"]                   = "";
	This["Visible"]                     = "Boolean";
	This["UserVisible"]                 = "String"; //AdjustableBoolean
	This["Representation"]              = "String"; //Enums.ButtonRepresentation;
	This["DefaultButton"]               = "Boolean";
	This["SkipOnInput"]                 = "String"; //Enums.BWAValue;
	This["Enabled"]                     = "Boolean";
	This["DefaultItem"]                 = "Boolean";
	This["OnlyInAllActions"]            = "String"; //Enums.BWAValue;
	This["Width"]                       = "Decimal";
	This["AutoMaxWidth"]                = "Boolean";
	This["MaxWidth"]                    = "Decimal";
	This["MinWidth"]                    = "Decimal";
	This["Height"]                      = "Decimal";
	This["AutoMaxHeight"]               = "Boolean";
	This["MaxHeight"]                   = "Decimal";
	This["HorizontalStretch"]           = "Boolean";
	This["VerticalStretch"]             = "Boolean";
	This["GroupHorizontalAlign"]        = "String"; //Enums.ItemHorizontalAlignment;
	This["GroupVerticalAlign"]          = "String"; //Enums.ItemVerticalAlignment;
	This["PlacementArea"]               = "String"; //Enums.MenuElementPlacementArea;
	This["Check"]                       = "Boolean";
	This["TextColor"]                   = "String"; //Color
	This["BackColor"]                   = "String"; //Color
	This["BorderColor"]                 = "String"; //Color
	This["Font"]                        = Font();
	This["Shortcut"]                    = ShortCutType();
	This["Picture"]                     = Picture();
	This["Title"]                       = "LocalStringType";
	This["TitleHeight"]                 = "Decimal";
	This["ToolTipRepresentation"]       = "String"; //Enums.TooltipRepresentation;
	This["RepresentationInContextMenu"] = "String"; //Enums.RepresentationInContextMenu;
	This["Shape"]                       = "String"; //Enums.ButtonShape;
	This["ShapeRepresentation"]         = "String"; //Enums.ButtonShapeRepresentation;
	This["PictureLocation"]             = "String"; //Enums.FormButtonPictureLocation;
	Return This;
EndFunction // Button()

Function ButtonGroup()
	This = Record(GroupBase());
	This["CommandSource"]  = "String"; //CommandSourceName
	This["PlacementArea"]  = "String"; //Enums.MenuElementPlacementArea;
	This["Representation"] = "String"; //Enums.ButtonGroupRepresentation;
	Return This;
EndFunction // ButtonGroup()

Function CalendarField()
	This = Record(Field());
	This["Width"]                       = "Decimal";
	This["AutoMaxWidth"]                = "Boolean";
	This["MaxWidth"]                    = "Decimal";
	This["MinWidth"]                    = "Decimal";
	This["Height"]                      = "Decimal";
	This["AutoMaxHeight"]               = "Boolean";
	This["MaxHeight"]                   = "Decimal";
	This["HorizontalStretch"]           = "Boolean";
	This["VerticalStretch"]             = "Boolean";
	This["SelectionMode"]               = "String"; //Enums.FormDateSelectionMode;
	This["ShowCurrentDate"]             = "Boolean";
	This["CalendarNavigation"]          = "Boolean";
	This["BeginOfRepresentationPeriod"] = "DateTime";
	This["EndOfRepresentationPeriod"]   = "DateTime";
	This["EnableStartDrag"]             = "Boolean";
	This["EnableDrag"]                  = "Boolean";
	This["Font"]                        = Font();
	This["BorderColor"]                 = "String"; //Color
	This["Border"]                      = Border();
	This["ShowMonthsPanel"]             = "Boolean";
	This["WidthInMonths"]               = "Decimal";
	This["HeightInMonths"]              = "Decimal";
	Return This;
EndFunction // CalendarField()

Function ChartField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	Return This;
EndFunction // ChartField()

Function CheckBoxField()
	This = Record(Field());
	This["CheckBoxType"]    = "String"; //Enums.CheckBoxType;
	This["ThreeState"]      = "Boolean";
	This["BorderColor"]     = "String"; //Color
	This["BackColor"]       = "String"; //Color
	This["TextColor"]       = "String"; //Color
	This["Font"]            = Font();
	This["EditFormat"]      = "LocalStringType";
	This["ItemTitleHeight"] = "Decimal";
	This["ItemWidth"]       = "Decimal";
	This["ItemHeight"]      = "Decimal";
	This["EqualItemsWidth"] = "String"; //Enums.BWAValue;
	Return This;
EndFunction // CheckBoxField()

Function ColumnGroup()
	This = Record(GroupBase());
	This["Group"]                 = "String"; //Enums.ColumnsGroup;
	This["ShowTitle"]             = "Boolean";
	This["TitleBackColor"]        = "String"; //Color
	This["ShowInHeader"]          = "Boolean";
	This["HeaderDataPath"]        = "LFEDataPath";
	This["HeaderHorizontalAlign"] = "String"; //Enums.ItemHorizontalAlignment;
	This["HeaderFormat"]          = "LocalStringType";
	This["HeaderPicture"]         = Picture();
	This["FixingInTable"]         = "String"; //Enums.FormFixedInTable;
	Return This;
EndFunction // ColumnGroup()

Function CommandBar()
	This = Record(GroupBase());
	This["HorizontalLocation"] = "String"; //Enums.ItemHorizontalAlignment;
	This["CommandSource"]      = "String"; //CommandSourceName
	Return This;
EndFunction // CommandBar()

Function ContextMenu()
	This = Record(GroupBase());
	This["Autofill"] = "Boolean";
	Return This;
EndFunction // ContextMenu()

Function DendrogramField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	Return This;
EndFunction // DendrogramField()

Function FormattedDocumentField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	This["Output"]            = "String"; //Enums.UseOutput;
	This["TextColor"]         = "String"; //Color
	This["BackColor"]         = "String"; //Color
	This["BorderColor"]       = "String"; //Color
	This["Font"]              = Font();
	Return This;
EndFunction // FormattedDocumentField()

Function GanttChartField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	Return This;
EndFunction // GanttChartField()

Function GeographicalSchemaField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	This["Output"]            = "String"; //Enums.UseOutput;
	This["BorderColor"]       = "String"; //Color
	Return This;
EndFunction // GeographicalSchemaField()

Function GraphicalSchemaField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	This["Output"]            = "String"; //Enums.UseOutput;
	This["Edit"]              = "Boolean";
	This["BorderColor"]       = "String"; //Color
	Return This;
EndFunction // GraphicalSchemaField()

Function HTMLDocumentField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	This["Output"]            = "String"; //Enums.UseOutput;
	This["BorderColor"]       = "String"; //Color
	Return This;
EndFunction // HTMLDocumentField()

Function InputField()
	This = Record(Field());
	This["Width"]                         = "Decimal";
	This["AutoMaxWidth"]                  = "Boolean";
	This["MaxWidth"]                      = "Decimal";
	This["MinWidth"]                      = "Decimal";
	This["Height"]                        = "Decimal";
	This["AutoMaxHeight"]                 = "Boolean";
	This["MaxHeight"]                     = "Decimal";
	This["HorizontalStretch"]             = "String"; //Enums.BWAValue;
	This["VerticalStretch"]               = "String"; //Enums.BWAValue;
	This["Wrap"]                          = "Boolean";
	This["PasswordMode"]                  = "String"; //Enums.BWAValue;
	This["MultiLine"]                     = "String"; //Enums.BWAValue;
	This["ExtendedEdit"]                  = "String"; //Enums.BWAValue;
	This["MarkNegatives"]                 = "String"; //Enums.BWAValue;
	This["DropListButton"]                = "String"; //Enums.BWAValue;
	This["ChoiceButton"]                  = "String"; //Enums.BWAValue;
	This["ChoiceButtonRepresentation"]    = "String"; //Enums.ChoiceButtonRepresentation;
	This["ChoiceButtonPicture"]           = Picture();
	This["ClearButton"]                   = "String"; //Enums.BWAValue;
	This["SpinButton"]                    = "String"; //Enums.BWAValue;
	This["OpenButton"]                    = "String"; //Enums.BWAValue;
	This["CreateButton"]                  = "String"; //Enums.BWAValue;
	This["Mask"]                          = "String";
	This["AutoChoiceIncomplete"]          = "String"; //Enums.BWAValue;
	This["QuickChoice"]                   = "String"; //Enums.BWAValue;
	This["ChoiceFoldersAndItems"]         = "String"; //Enums.FoldersAndItems;
	This["Format"]                        = "LocalStringType";
	This["EditFormat"]                    = "LocalStringType";
	This["AutoMarkIncomplete"]            = "String"; //Enums.BWAValue;
	This["ChooseType"]                    = "Boolean";
	This["IncompleteChoiceMode"]          = "String"; //Enums.IncompleteItemChoiceMode;
	This["TypeDomainEnabled"]             = "Boolean";
	This["TextEdit"]                      = "Boolean";
	This["EditTextUpdate"]                = "String"; //Enums.EditTextUpdate;
	//This["MinValue"]                      = "";
	//This["MaxValue"]                      = "";
	This["ChoiceForm"]                    = "MDObjectRef";
	This["ChoiceParameterLinks"]          = ChoiceParameterLinks();
	This["ChoiceParameters"]              = ChoiceParameters();
	This["AvailableTypes"]                = "TypeDescription";
	This["ListChoiceMode"]                = "Boolean";
	This["ChoiceList"]                    = ValueList();
	This["ChoiceListButton"]              = "String"; //Enums.BWAValue;
	This["ChoiceListHeight"]              = "Decimal";
	This["DropListWidth"]                 = "Decimal";
	This["TextColor"]                     = "String"; //Color
	This["BackColor"]                     = "String"; //Color
	This["BorderColor"]                   = "String"; //Color
	This["Font"]                          = Font();
	This["TypeLink"]                      = TypeLink();
	This["HeightControlVariant"]          = "String"; //Enums.HeightControlVariant;
	This["AutoShowClearButtonMode"]       = "String"; //Enums.AutoShowClearButtonMode;
	This["AutoShowOpenButtonMode"]        = "String"; //Enums.AutoShowOpenButtonMode;
	This["AutoCorrectionOnTextInput"]     = "String"; //Enums.AutoCorrectionOnTextInput;
	This["SpellCheckingOnTextInput"]      = "String"; //Enums.SpellCheckingOnTextInput;
	This["AutoCapitalizationOnTextInput"] = "String"; //Enums.AutoCapitalizationOnTextInput;
	This["SpecialTextInputMode"]          = "String"; //Enums.SpecialTextInputMode;
	This["OnScreenKeyboardReturnKeyText"] = "String"; //Enums.OnScreenKeyboardReturnKeyText;
	This["InputHint"]                     = "LocalStringType";
	This["ChoiceHistoryOnInput"]          = "String"; //Enums.ChoiceHistoryOnInput;
	Return This;
EndFunction // InputField()

Function LabelDecoration()
	This = Record(Decoration());
	This["Hyperlink"]       = "Boolean";
	This["HorizontalAlign"] = "String"; //Enums.ItemHorizontalAlignment;
	This["VerticalAlign"]   = "String"; //Enums.ItemVerticalAlignment;
	This["TitleHeight"]     = "Decimal";
	This["BackColor"]       = "String"; //Color
	This["BorderColor"]     = "String"; //Color
	This["Border"]          = Border();
	Return This;
EndFunction // LabelDecoration()

Function LabelField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "String"; //Enums.BWAValue;
	This["VerticalStretch"]   = "String"; //Enums.BWAValue;
	This["MarkNegatives"]     = "String"; //Enums.BWAValue;
	This["Format"]            = "LocalStringType";
	This["Hiperlink"]         = "Boolean";
	This["PasswordMode"]      = "String"; //Enums.BWAValue;
	This["Border"]            = Border();
	This["BorderColor"]       = "String"; //Color
	This["TextColor"]         = "String"; //Color
	This["BackColor"]         = "String"; //Color
	This["Font"]              = Font();
	Return This;
EndFunction // LabelField()

Function Page()
	This = Record(GroupBase());
	This["Picture"]           = Picture();
	This["Group"]             = "String"; //Enums.FormChildrenGroup;
	This["ChildrenAlign"]     = "String"; //Enums.FormChildrenAlign;
	This["HorizontalSpacing"] = "String"; //Enums.FormItemSpacing;
	This["VerticalSpacing"]   = "String"; //Enums.FormItemSpacing;
	This["HorizontalAlign"]   = "String"; //Enums.ItemHorizontalAlignment;
	This["VerticalAlign"]     = "String"; //Enums.ItemVerticalAlignment;
	This["ChildItemsWidth"]   = "String"; //Enums.FormChildrenWidth;
	This["Format"]            = "LocalStringType";
	This["ShowTitle"]         = "Boolean";
	This["TitleDataPath"]     = "LFEDataPath";
	This["BackColor"]         = "String"; //Color
	This["ScrollOnCompress"]  = "Boolean";
	Return This;
EndFunction // Page()

Function Pages()
	This = Record(GroupBase());
	This["PagesRepresentation"] = "String"; //Enums.FormPagesRepresentation;
	Return This;
EndFunction // Pages()

Function PeriodField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	This["Font"]              = Font();
	This["BorderColor"]       = "String"; //Color
	This["Border"]            = Border();
	Return This;
EndFunction // PeriodField()

Function PictureDecoration()
	This = Record(Decoration());
	This["Picture"]                = Picture();
	This["PictureSize"]            = "String"; //Enums.PictureSize;
	This["Hyperlink"]              = "Boolean";
	This["Zoomable"]               = "Boolean";
	This["NonselectedPictureText"] = "LocalStringType";
	This["EnableStartDrag"]        = "Boolean";
	This["EnableDrag"]             = "Boolean";
	This["Border"]                 = Border();
	This["BorderColor"]            = "String"; //Color
	Return This;
EndFunction // PictureDecoration()

Function PictureField()
	This = Record(Field());
	This["Width"]                  = "Decimal";
	This["AutoMaxWidth"]           = "Boolean";
	This["MaxWidth"]               = "Decimal";
	This["MinWidth"]               = "Decimal";
	This["Height"]                 = "Decimal";
	This["AutoMaxHeight"]          = "Boolean";
	This["MaxHeight"]              = "Decimal";
	This["HorizontalStretch"]      = "Boolean";
	This["VerticalStretch"]        = "Boolean";
	This["PictureSize"]            = "String"; //Enums.PictureSize;
	This["Zoomable"]               = "Boolean";
	This["Hyperlink"]              = "Boolean";
	This["NonselectedPictureText"] = "LocalStringType";
	This["EnableStartDrag"]        = "Boolean";
	This["EnableDrag"]             = "Boolean";
	This["ValuesPicture"]          = Picture();
	This["TextColor"]              = "String"; //Color
	This["Border"]                 = Border();
	This["BorderColor"]            = "String"; //Color
	This["Font"]                   = Font();
	Return This;
EndFunction // PictureField()

Function PlannerField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	This["EnableStartDrag"]   = "Boolean";
	This["EnableDrag"]        = "Boolean";
	Return This;
EndFunction // PlannerField()

Function Popup()
	This = Record(GroupBase());
	This["Picture"]             = Picture();
	This["CommandSource"]       = "String"; //CommandSourceName
	This["Representation"]      = "String"; //Enums.ButtonRepresentation;
	This["PlacementArea"]       = "String"; //Enums.MenuElementPlacementArea;
	This["Shape"]               = "String"; //Enums.ButtonShape;
	This["ShapeRepresentation"] = "String"; //Enums.ButtonShapeRepresentation;
	This["BackColor"]           = "String"; //Color
	This["BorderColor"]         = "String"; //Color
	Return This;
EndFunction // Popup()

Function ProgressBarField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	This["MinValue"]          = "Decimal";
	This["MaxValue"]          = "Decimal";
	This["Orientation"]       = "String"; //Enums.FormElementOrientation;
	This["Representation"]    = "String"; //Enums.FormProgressBarRepresentation;
	This["ShowPercent"]       = "Boolean";
	This["BorderColor"]       = "String"; //Color
	Return This;
EndFunction // ProgressBarField()

Function RadioButtonField()
	This = Record(Field());
	This["RadioButtonType"]   = "String"; //Enums.RadioButtonType;
	This["ItemWidth"]         = "Decimal";
	This["ItemHeight"]        = "Decimal";
	This["ItemTitleHeight"]   = "Decimal";
	This["ColumnsCount"]      = "Decimal";
	This["EqualColumnsWidth"] = "String"; //Enums.BWAValue;
	This["ChoiceList"]        = ValueList();
	This["Font"]              = Font();
	This["TextColor"]         = "String"; //Color
	This["BackColor"]         = "String"; //Color
	This["BorderColor"]       = "String"; //Color
	Return This;
EndFunction // RadioButtonField()

Function SearchControlAddition()
	This = Record(Addition());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["HorizontalStretch"] = "String"; //Enums.BWAValue;
	This["BackColor"]         = "String"; //Color
	This["TextColor"]         = "String"; //Color
	This["BorderColor"]       = "String"; //Color
	This["Font"]              = Font();
	Return This;
EndFunction // SearchControlAddition()

Function SearchStringAddition()
	This = Record(Addition());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["HorizontalStretch"] = "String"; //Enums.BWAValue;
	This["BackColor"]         = "String"; //Color
	This["TextColor"]         = "String"; //Color
	This["BorderColor"]       = "String"; //Color
	This["Font"]              = Font();
	Return This;
EndFunction // SearchStringAddition()

Function SpreadSheetDocumentField()
	This = Record(Field());
	This["Width"]                 = "Decimal";
	This["AutoMaxWidth"]          = "Boolean";
	This["MaxWidth"]              = "Decimal";
	This["MinWidth"]              = "Decimal";
	This["Height"]                = "Decimal";
	This["AutoMaxHeight"]         = "Boolean";
	This["MaxHeight"]             = "Decimal";
	This["HorizontalStretch"]     = "Boolean";
	This["VerticalStretch"]       = "Boolean";
	This["ShowGrid"]              = "Boolean";
	This["ShowHeaders"]           = "Boolean";
	This["VerticalScrollBar"]     = "String"; //SpreadSheetDocumentScrollBarUse
	This["HorizontalScrollBar"]   = "String"; //SpreadSheetDocumentScrollBarUse
	This["BlackAndWhiteView"]     = "Boolean";
	This["Protection"]            = "Boolean";
	This["SelectionShowMode"]     = "String"; //Enums.SelectionShowMode;
	This["Output"]                = "String"; //Enums.UseOutput;
	This["Edit"]                  = "Boolean";
	This["ShowGroups"]            = "Boolean";
	This["EnableStartDrag"]       = "Boolean";
	This["EnableDrag"]            = "Boolean";
	This["BorderColor"]           = "String"; //Color
	This["ViewScalingMode"]       = "String"; //Enums.ViewScalingMode;
	This["ShowCellNames"]         = "Boolean";
	This["ShowRowAndColumnNames"] = "Boolean";
	This["PointerType"]           = "String"; //Enums.SpreadsheetDocumentPointerType;
	Return This;
EndFunction // SpreadSheetDocumentField()

Function Table()
	This = Record(FormItemBase());
	This["Representation"]                          = "String"; //Enums.TableRepresentation;
	This["Visible"]                                 = "Boolean";
	This["UserVisible"]                             = "String"; //AdjustableBoolean
	This["CommandBarLocation"]                      = "String"; //Enums.FormElementCommandBarLocation;
	This["Autofill"]                                = "Boolean";
	This["Enabled"]                                 = "Boolean";
	This["ReadOnly"]                                = "Boolean";
	This["SkipOnInput"]                             = "String"; //Enums.BWAValue;
	This["DefaultItem"]                             = "Boolean";
	This["ChangeRowSet"]                            = "Boolean";
	This["ChangeRowOrder"]                          = "Boolean";
	This["Width"]                                   = "Decimal";
	This["AutoMaxWidth"]                            = "Boolean";
	This["MaxWidth"]                                = "Decimal";
	This["MinWidth"]                                = "Decimal";
	This["Height"]                                  = "Decimal";
	This["AutoMaxHeight"]                           = "Boolean";
	This["MaxHeight"]                               = "Decimal";
	This["HeightInTableRows"]                       = "Decimal";
	This["HeightControlVariant"]                    = "String"; //Enums.TableHeightControlVariant;
	This["AutoMaxRowsCount"]                        = "Boolean";
	This["MaxRowsCount"]                            = "Decimal";
	This["ChoiceMode"]                              = "Boolean";
	This["MultipleChoice"]                          = "Boolean";
	This["RowInputMode"]                            = "String"; //Enums.TableRowInputMode;
	This["SelectionMode"]                           = "String"; //Enums.TableSelectionMode;
	This["RowSelectionMode"]                        = "String"; //Enums.TableRowSelectionMode;
	This["Header"]                                  = "Boolean";
	This["HeaderHeight"]                            = "Decimal";
	This["Footer"]                                  = "Boolean";
	This["FooterHeight"]                            = "Decimal";
	This["HorizontalScrollBar"]                     = "String"; //Enums.TableScrollBarUse;
	This["VerticalScrollBar"]                       = "String"; //Enums.TableScrollBarUse;
	This["HorizontalLines"]                         = "Boolean";
	This["VerticalLines"]                           = "Boolean";
	This["FixedLeft"]                               = "Decimal";
	This["FixedRight"]                              = "Decimal";
	This["UseAlternationRowColor"]                  = "Boolean";
	This["AutoInsertNewRow"]                        = "Boolean";
	This["AutoAddIncomplete"]                       = "String"; //Enums.BWAValue;
	This["AutoMarkIncomplete"]                      = "String"; //Enums.BWAValue;
	This["SearchOnInput"]                           = "String"; //Enums.SearchOnInput;
	This["InitialListView"]                         = "String"; //Enums.TableInitialListView;
	This["InitialTreeView"]                         = "String"; //Enums.TableInitialTreeView;
	This["Output"]                                  = "String"; //Enums.UseOutput;
	This["HorizontalStretch"]                       = "Boolean";
	This["VerticalStretch"]                         = "Boolean";
	This["EnableStartDrag"]                         = "Boolean";
	This["EnableDrag"]                              = "Boolean";
	This["DataPath"]                                = "LFEDataPath";
	This["RowPictureDataPath"]                      = "LFEDataPath";
	This["RowsPicture"]                             = Picture();
	This["TextColor"]                               = "String"; //Color
	This["BackColor"]                               = "String"; //Color
	This["BorderColor"]                             = "String"; //Color
	This["Font"]                                    = Font();
	This["Title"]                                   = "LocalStringType";
	This["TitleHeight"]                             = "Decimal";
	This["TitleFont"]                               = Font();
	This["TitleTextColor"]                          = "String"; //Color
	This["TitleLocation"]                           = "String"; //Enums.FormElementTitleLocation;
	This["Shortcut"]                                = ShortCutType();
	This["CommandSet"]                              = CommandsContent();
	This["ToolTip"]                                 = "LocalStringType";
	This["ToolTipRepresentation"]                   = "String"; //Enums.TooltipRepresentation;
	This["SearchStringLocation"]                    = "String"; //Enums.SearchStringLocation;
	This["ViewStatusLocation"]                      = "String"; //Enums.ViewStatusLocation;
	This["SearchControlLocation"]                   = "String"; //Enums.SearchControlLocation;
	This["GroupHorizontalAlign"]                    = "String"; //Enums.ItemHorizontalAlignment;
	This["GroupVerticalAlign"]                      = "String"; //Enums.ItemVerticalAlignment;
	This["RefreshRequest"]                          = "String"; //Enums.RefreshRequestMethod;
	This["ViewMode"]                                = "String"; //Enums.DataCompositionSettingsViewMode;
	This["SettingsNamedItemDetailedRepresentation"] = "Boolean";
	This["AutoRefresh"]                             = "Boolean";
	This["AutoRefreshPeriod"]                       = "Decimal";
	This["Period"]                                  = StandardPeriod();
	This["ChoiceFoldersAndItems"]                   = "String"; //Enums.FoldersAndItemsUse;
	This["RestoreCurrentRow"]                       = "Boolean";
	//This["TopLevelParent"]                          = "";
	This["ShowRoot"]                                = "Boolean";
	This["AllowRootChoice"]                         = "Boolean";
	//This["RowFilter"]                               = "";
	This["UpdateOnDataChange"]                      = "String"; //Enums.UpdateOnDataChange;
	This["UserSettingsGroup"]                       = "String";
	Return This;
EndFunction // Table()

Function TextDocumentField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	This["Output"]            = "String"; //Enums.UseOutput;
	This["TextColor"]         = "String"; //Color
	This["BackColor"]         = "String"; //Color
	This["BorderColor"]       = "String"; //Color
	This["Font"]              = Font();
	Return This;
EndFunction // TextDocumentField()

Function TrackBarField()
	This = Record(Field());
	This["Width"]             = "Decimal";
	This["AutoMaxWidth"]      = "Boolean";
	This["MaxWidth"]          = "Decimal";
	This["MinWidth"]          = "Decimal";
	This["Height"]            = "Decimal";
	This["AutoMaxHeight"]     = "Boolean";
	This["MaxHeight"]         = "Decimal";
	This["HorizontalStretch"] = "Boolean";
	This["VerticalStretch"]   = "Boolean";
	This["MinValue"]          = "Decimal";
	This["MaxValue"]          = "Decimal";
	This["Step"]              = "Decimal";
	This["LargeStep"]         = "Decimal";
	This["MarkingStep"]       = "Decimal";
	This["Orientation"]       = "String"; //Enums.FormElementOrientation;
	This["MarkingAppearance"] = "String"; //Enums.MarkingStyle;
	This["BorderColor"]       = "String"; //Color
	Return This;
EndFunction // TrackBarField()

Function UsualGroup()
	This = Record(GroupBase());
	This["Group"]                        = "String"; //Enums.FormChildrenGroup;
	This["ChildrenAlign"]                = "String"; //Enums.FormChildrenAlign;
	This["HorizontalSpacing"]            = "String"; //Enums.FormItemSpacing;
	This["VerticalSpacing"]              = "String"; //Enums.FormItemSpacing;
	This["HorizontalAlign"]              = "String"; //Enums.ItemHorizontalAlignment;
	This["VerticalAlign"]                = "String"; //Enums.ItemVerticalAlignment;
	This["Behavior"]                     = "String"; //Enums.UsualGroupBehavior;
	This["CollapsedRepresentationTitle"] = "LocalStringType";
	This["Collapsed"]                    = "Boolean";
	This["ControlRepresentation"]        = "String"; //Enums.UsualGroupControlRepresentation;
	This["Representation"]               = "String"; //Enums.UsualGroupControlRepresentation;
	This["ShowLeftMargin"]               = "Boolean";
	This["United"]                       = "Boolean";
	This["ChildItemsWidth"]              = "String"; //Enums.FormChildrenWidth;
	This["Format"]                       = "LocalStringType";
	This["ShowTitle"]                    = "Boolean";
	This["TitleDataPath"]                = "LFEDataPath";
	This["BackColor"]                    = "String"; //Color
	This["ThroughAlign"]                 = "String"; //Enums.UsualGroupThroughAlign;
	Return This;
EndFunction // UsualGroup()

Function ViewStatusAddition()
	This = Record(Addition());
	This["Width"]              = "Decimal";
	This["AutoMaxWidth"]       = "Boolean";
	This["MaxWidth"]           = "Decimal";
	This["MinWidth"]           = "Decimal";
	This["HorizontalStretch"]  = "String"; //Enums.BWAValue;
	This["HorizontalLocation"] = "String"; //Enums.ItemHorizontalAlignment;
	This["BackColor"]          = "String"; //Color
	This["ButtonColor"]        = "String"; //Color
	This["TextColor"]          = "String"; //Color
	This["TitleTextColor"]     = "String"; //Color
	This["BorderColor"]        = "String"; //Color
	This["Font"]               = Font();
	This["TitleFont"]          = Font();
	This["Border"]             = Border();
	Return This;
EndFunction // ViewStatusAddition()

#EndRegion // ChildItems

#Region Other

Function Font()
	This = Record();
	This["ref"]       = "String"; // StyleRef
	This["faceName"]  = "String";
	This["height"]    = "Decimal";
	This["bold"]      = "Boolean";
	This["italic"]    = "Boolean";
	This["underline"] = "Boolean";
	This["strikeout"] = "Boolean";
	This["kind"]      = "String"; //Enums.FontType;
	This["scale"]     = "Decimal";
	Return This;
EndFunction // Font()

Function ShortCutType()
	This = Object();
	Attributes = This.Attributes;
	Attributes["Alt"]   = "Boolean";
	Attributes["Ctrl"]  = "Boolean";
	Attributes["Shift"] = "Boolean";
	Items = This.Items;
	Items["Key"] = "String"; //Enums.Key;
	Return This;
EndFunction // ShortCutType()

Function Border()
	This = Record();
	This["ref"]   = "String"; //StyleRef
	This["style"] = "String"; //BorderType
	This["width"] = "Decimal"; //unsignedInt
	Return This;
EndFunction // Border()

Function StandardPeriod()
	This = Record();
	This["variant"]   = "String"; //Enums.StandardPeriodVariant;
	This["startDate"] = "DateTime";
	This["endDate"]   = "DateTime";
	Return This;
EndFunction // StandardPeriod()

Function ValueList()
	This = Object();
	Items = This.Items;
	Items["Item"] = ValueListItem();
	Return This;
EndFunction // ValueList()

Function ValueListItem()
	This = Record();
	This["Presentation"] = "String";
	This["CheckState"]   = "Decimal";
	//This["Value"]        = "";
	Return This;
EndFunction // ValueListItem()

Function FormattedStringType()
	This = Record(LocalStringType());
	This["formatted"] = "Boolean";
	Return This;
EndFunction // FormattedStringType()

Function Picture()
	This = Record();
	This["url"] = "String";
	This["ref"] = "String"; //PictureRef
	This["t"]   = "Boolean";
	This["tx"]  = "Decimal";
	This["ty"]  = "Decimal";
	This["gx"]  = "Decimal";
	This["gy"]  = "Decimal";
	This["gw"]  = "Decimal";
	This["gh"]  = "Decimal";
	This["_"]   = "base64Binary";
	Return This;
EndFunction // Picture()

Function ChoiceParameterLinks()
	This = Object();
	Items = This.Items;
	Items["item"] = ChoiceParameterLink();
	Return This;
EndFunction // ChoiceParameterLinks()

Function ChoiceParameterLink()
	This = Record();
	This["choiceParameter"] = "String";
	This["value"]           = "Field";
	//This["mode"]          = "";
	Return This;
EndFunction // ChoiceParameterLink()

Function ChoiceParameters()
	This = Object();
	Items = This.Items;
	Items["item"] = ChoiceParameter();
	Return This;
EndFunction // ChoiceParameters()

Function ChoiceParameter()
	This = Record();
	This["choiceParameter"] = "String";
	//This["value"] = "";
	Return This;
EndFunction // ChoiceParameter()

Function TypeLink()
	This = Record();
	This["field"]    = "Field";
	This["linkItem"] = "Decimal";
	Return This;
EndFunction // TypeLink()

#EndRegion // Other

#EndRegion // Form
