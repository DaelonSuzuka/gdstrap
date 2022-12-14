tool
extends EditorPlugin

## Path to the version script file (bruh).
const VERSION_SCRIPT_PATH = "res://system/Version.gd"

## Change the code of this method to return a String that will identify your version.
## Two example ways of doing so are provided, just uncomment one of them.
## You can use the arguments to customize your version based on selected platform or something.
func _fetch_version(features: PoolStringArray, is_debug: bool, path: String, flags: int) -> String:
	### Git version ### ---------------------------------------------------------------------------
	
	# Version is number of commits. Requires git installed
	# and project inside git repository with at least 1 commit.
	
	var output := []
	OS.execute("git", PoolStringArray(["rev-list", "--count", "HEAD"]), true, output)
	if output.empty() or output[0].empty():
		push_error("Failed to fetch version. Make sure you have git installed and project is inside valid git directory.")
		return ''
	else:
		return output[0].trim_suffix("\n")

	### Git branch version ### --------------------------------------------------------------------
	
	# Version is the current branch name. Useful for feature branches like 'release-1.0.0'
	# Requires git installed and project inside git repository.

#	var output := []
#	OS.execute("git", PoolStringArray(["rev-parse", "--abbrev-ref", "HEAD"]), true, output)
#	if output.empty() or output[0].empty():
#		push_error("Failed to fetch version. Make sure you have git installed and project is inside valid git directory.")
#	else:
#		return output[0].trim_suffix("\n")

### Unimportant stuff here.

var exporter: AEVExporter

func _enter_tree() -> void:
	exporter = AEVExporter.new()
	exporter.plugin = self
	add_export_plugin(exporter)
	add_tool_menu_item("Print Current Version", self, "print_version")
	
	if not File.new().file_exists(VERSION_SCRIPT_PATH):
		exporter.store_version(_fetch_version(PoolStringArray(), true, "", 0))

func _exit_tree() -> void:
	remove_export_plugin(exporter)
	remove_tool_menu_item("Print Current Version")

func print_version(ud):
	var v = _fetch_version(PoolStringArray(), true, "", 0)
	if v.empty():
		OS.alert("Error fetching version. Check console for details.")
	else:
		OS.alert("Current game version: %s" % v)
		print(v)

class AEVExporter extends EditorExportPlugin:
	var plugin
	
	func _export_begin(features: PoolStringArray, is_debug: bool, path: String, flags: int):
		var version: String = plugin._fetch_version(features, is_debug, path, flags)
		if version.empty():
			push_error("Version string is empty. Make sure your _fetch_version() is configured properly.")
		
		store_version(version)

	func store_version(version: String):
		var script = GDScript.new()
		script.source_code = str("extends Reference\nconst VERSION = \"", version, "\"\n")
		if ResourceSaver.save(VERSION_SCRIPT_PATH, script) != OK:
			push_error("Failed to save version file. Make sure the path is valid.")
