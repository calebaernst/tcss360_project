extends GutTest

const SLOT := 3  # keep tests in a separate slot

# --- helpers --------------------------------------------------------------

func _abs_user(p_user: String) -> String:
	# Convert user:// path to absolute OS path for deletion
	return ProjectSettings.globalize_path(p_user)

func _nuke_slot_file() -> void:
	var p_user := SaveManager.getSaveFilepath(SLOT)
	var p_abs  := _abs_user(p_user)

	# Try absolute delete
	if FileAccess.file_exists(p_user):
		DirAccess.remove_absolute(p_abs)

	# Try user:// delete as well
	var d := DirAccess.open("user://")
	if d:
		d.remove(p_user.get_file())

	# As a last resort, overwrite then remove (helps on Windows)
	if FileAccess.file_exists(p_user):
		var f := FileAccess.open(p_user, FileAccess.WRITE)
		if f:
			f.close()
		DirAccess.remove_absolute(p_abs)

func _before_each() -> void:
	_nuke_slot_file()

func _after_each() -> void:
	_nuke_slot_file()

# Write a tiny valid JSON save (no JSON.stringify needed)
func _write_fake_save(x: int, y: int) -> void:
	var p := SaveManager.getSaveFilepath(SLOT)
	var f := FileAccess.open(p, FileAccess.WRITE)
	assert_ne(f, null, "Could not open save file for writing at: %s" % p)
	var txt := '{"currentRoomX":%d,"currentRoomY":%d,"mazeRooms":[[{}]]}' % [x, y]
	f.store_string(txt)
	f.close()

# --- tests ---------------------------------------------------------------

func test_getSaveFilepath_valid_slots() -> void:
	assert_eq(SaveManager.getSaveFilepath(1), "user://saveSlot1")
	assert_eq(SaveManager.getSaveFilepath(2), "user://saveSlot2")
	assert_eq(SaveManager.getSaveFilepath(3), "user://saveSlot3")

func test_saveExists_false_when_no_file() -> void:
	_nuke_slot_file()
	var p := SaveManager.getSaveFilepath(SLOT)
	# Ensure filesystem is actually clean first
	assert_false(FileAccess.file_exists(p), "Precondition failed: file exists at %s" % p)
	assert_false(SaveManager.saveExists(SLOT), "saveExists() should be false when no file is present")

func test_getSaveData_returns_null_when_missing() -> void:
	var data = SaveManager.getSaveData(SLOT)
	assert_true(data == null)

func test_getSlotDisplay_empty_when_missing() -> void:
	assert_eq(SaveManager.getSlotDisplay(SLOT), "")

func test_write_and_read_save_data_roundtrip() -> void:
	_write_fake_save(4, 7)
	assert_true(SaveManager.saveExists(SLOT))
	var data = SaveManager.getSaveData(SLOT)
	assert_true(typeof(data) == TYPE_DICTIONARY, "Expected parsed JSON dictionary")
	var dx := int(data.get("currentRoomX", -1))
	var dy := int(data.get("currentRoomY", -1))
	assert_eq(dx, 4)
	assert_eq(dy, 7)
	assert_true(data.has("mazeRooms"))

func test_getSlotDisplay_formats_coordinates() -> void:
	_write_fake_save(2, 5)
	assert_eq(SaveManager.getSlotDisplay(SLOT), "(2, 5)")

func test_deleteSave_removes_file() -> void:
	_write_fake_save(1, 1)
	assert_true(SaveManager.saveExists(SLOT))
	SaveManager.deleteSave(SLOT)
	assert_false(SaveManager.saveExists(SLOT))

func test_getSaveData_bad_json_returns_null() -> void:
	var p := SaveManager.getSaveFilepath(SLOT)
	var f := FileAccess.open(p, FileAccess.WRITE)
	assert_ne(f, null)
	f.store_string("{ this is not valid json")
	f.close()
	var data = SaveManager.getSaveData(SLOT)   # may be null
	assert_true(data == null, "Bad JSON should return null")
