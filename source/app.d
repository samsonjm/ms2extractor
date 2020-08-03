import dlangui;
import dlangui.dialogs.filedlg;
import mzxmlparse;

mixin APP_ENTRY_POINT;

extern (C) int UIAppMain(string[] args) {
	Window window = Platform.instance.createWindow("mzXML MS2 extracter", null);

	auto vlayout = new VerticalLayout();
	vlayout.margins = 10;
	vlayout.padding = 10;

	auto tlayout = new TableLayout();
	tlayout.colCount = 2;
	tlayout.margins = 10;
	tlayout.padding = 10;
	tlayout.addChild(new TextWidget(null, "Input file:"d));
	auto input_file = new FileNameEditLine("/path/to/input.file.mzXML");
	tlayout.addChild(input_file);
	tlayout.addChild(new TextWidget(null, "Output file:"d));
	auto output_file = new EditLine(null, "/path/to/output.file.mzXML");
	tlayout.addChild(output_file);
	vlayout.addChild(tlayout);

	auto metadata = new CheckBox(null, "Include metadata"d);
	vlayout.addChild(metadata);
	auto all_scans = new CheckBox(null, "Include all scans (rather than just MS2)"d);
	vlayout.addChild(all_scans);
	
	auto buttons = new HorizontalLayout();
	auto run = new Button(null, "Run"d);
	auto cancel = new Button(null, "Cancel"d);
	buttons.addChild(run);
	buttons.addChild(cancel);


	vlayout.addChild(buttons);
	window.mainWidget = vlayout;

	window.show();

	run.click = delegate(Widget src) {
		if(mzxmlparse.extract_ms2(
					input_file.text.to!string, 
					output_file.text.to!string, 
					metadata.checked, 
					all_scans.checked
					) == true)
			window.showMessageBox("Success!"d, 
					"Scans extracted;\nOutput file:"d ~ output_file.text);
		return true;
	};

	cancel.click = delegate(Widget src) {
		window.close();
		return true;
	};

	return Platform.instance.enterMessageLoop();
}
