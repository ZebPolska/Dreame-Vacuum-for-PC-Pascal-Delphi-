unit Unit2;

interface

uses
  System.Generics.Collections, System.SysUtils;

type
  // Sta³e stringi dla atrybutów oraz trybów pracy
  TDreameConst = class
  public
    const piid = 'piid';
    const siid = 'siid';
    const aiid = 'aiid';

    const ATTR_A = 'a';
    const ATTR_X = 'x';
    const ATTR_X0 = 'x0';
    const ATTR_X1 = 'x1';
    const ATTR_X2 = 'x2';
    const ATTR_X3 = 'x3';
    const ATTR_Y = 'y';
    const ATTR_Y0 = 'y0';
    const ATTR_Y1 = 'y1';
    const ATTR_Y2 = 'y2';
    const ATTR_Y3 = 'y3';
    const ATTR_CHARGER = 'charger_position';
    const ATTR_IS_EMPTY = 'is_empty';
    const ATTR_NO_GO_AREAS = 'no_go_areas';
    const ATTR_NO_MOPPING_AREAS = 'no_mopping_areas';
    const ATTR_CARPETS = 'carpets';
    const ATTR_DELETED_CARPETS = 'deleted_carpets';
    const ATTR_DETECTED_CARPETS = 'detected_carpets';
    const ATTR_PREDEFINED_POINTS = 'predefined_points';
    const ATTR_VIRTUAL_WALLS = 'virtual_walls';
    const ATTR_VIRTUAL_THRESHOLDS = 'virtual_thresholds';
    const ATTR_PASSABLE_THRESHOLDS = 'passable_thresholds';
    const ATTR_IMPASSABLE_THRESHOLDS = 'impassable_thresholds';
    const ATTR_RAMPS = 'ramps';
    const ATTR_CURTAINS = 'curtains';
    const ATTR_LOW_LYING_AREAS = 'low_lying_areas';
    const ATTR_ROOMS = 'rooms';
    const ATTR_ROBOT_POSITION = 'vacuum_position';
    const ATTR_MAP_ID = 'map_id';
    const ATTR_SAVED_MAP_ID = 'saved_map_id';
    const ATTR_MAP_NAME = 'map_name';
    const ATTR_ROTATION = 'rotation';
    const ATTR_TIMESTAMP = 'timestamp';
    const ATTR_UPDATED = 'updated_at';
    const ATTR_ACTIVE_AREAS = 'active_areas';
    const ATTR_ACTIVE_POINTS = 'active_points';
    const ATTR_ACTIVE_CRUISE_POINTS = 'active_cruise_points';
    const ATTR_ACTIVE_SEGMENTS = 'active_segments';
    const ATTR_FRAME_ID = 'frame_id';
    const ATTR_MAP_INDEX = 'map_index';
    const ATTR_ROOM_ID = 'room_id';
    const ATTR_FURNITURE_ID = 'furniture_id';
    const ATTR_ROOM_ICON = 'room_icon';
    const ATTR_UNIQUE_ID = 'unique_id';
    const ATTR_FLOOR_MATERIAL = 'floor_material';
    const ATTR_FLOOR_MATERIAL_DIRECTION = 'floor_material_direction';
    const ATTR_VISIBILITY = 'visibility';
    const ATTR_NAME = 'name';
    const ATTR_CUSTOM_NAME = 'custom_name';
    const ATTR_OUTLINE = 'outline';
    const ATTR_CENTER = 'center';
    const ATTR_ORDER = 'order';
    const ATTR_CLEANING_TIMES = 'cleaning_times';
    const ATTR_SUCTION_LEVEL = 'suction_level';
    const ATTR_WATER_VOLUME = 'water_volume';
    const ATTR_WETNESS_LEVEL = 'wetness_level';
    const ATTR_CLEANING_MODE = 'cleaning_mode';
    const ATTR_CLEANING_ROUTE = 'cleaning_route';
    const ATTR_CUSTOM_MOPPING_ROUTE = 'custom_mopping_route';
    const ATTR_TYPE = 'type';
    const ATTR_INDEX = 'index';
    const ATTR_ICON = 'icon';
    const ATTR_COLOR_INDEX = 'color_index';
    const ATTR_OBSTACLES = 'obstacles';
    const ATTR_POSSIBILTY = 'possibility';
    const ATTR_PICTURE_STATUS = 'picture_status';
    const ATTR_IGNORE_STATUS = 'ignore_status';
    const ATTR_ROOM = 'room';
    const ATTR_REASON = 'reason';
    const ATTR_ROUTER_POSITION = 'router_position';
    const ATTR_FURNITURES = 'furnitures';
    const ATTR_STARTUP_METHOD = 'startup_method';
    const ATTR_DUST_COLLECTION_COUNT = 'dust_collection_count';
    const ATTR_MOP_WASH_COUNT = 'mop_wash_count';
    const ATTR_RECOVERY_MAP_LIST = 'recovery_map_list';
    const ATTR_WIDTH = 'width';
    const ATTR_HEIGHT = 'height';
    const ATTR_SIZE_TYPE = 'size_type';
    const ATTR_ANGLE = 'angle';
    const ATTR_SCALE = 'scale';
    const ATTR_COMPLETED = 'completed';
  end;

  // ChargingStatus
  TDreameVacuumChargingStatus = (UNKNOWN_CHARGING = -1, CHARGING = 1, NOT_CHARGING = 2,
    CHARGING_COMPLETED = 3, RETURN_TO_CHARGE = 5);

  // ErrorCode
  TDreameVacuumErrorCode = (
    UNKNOWN_ERROR = -1,
    NO_ERROR = 0,
    DROP = 1,
    CLIFF = 2,
    BUMPER = 3,
    GESTURE = 4,
    BUMPER_REPEAT = 5,
    DROP_REPEAT = 6,
    OPTICAL_FLOW = 7,
    BOX = 8,
    TANKBOX = 9,
    WATERBOX_EMPTY = 10,
    BOX_FULL = 11,
    BRUSH = 12,
    SIDE_BRUSH = 13,
    FAN = 14,
    LEFT_WHEEL_MOTOR = 15,
    RIGHT_WHEEL_MOTOR = 16,
    TURN_SUFFOCATE = 17,
    FORWARD_SUFFOCATE = 18,
    CHARGER_GET = 19,
    BATTERY_LOW = 20,
    CHARGE_FAULT = 21,
    BATTERY_PERCENTAGE = 22,
    HEART = 23,
    CAMERA_OCCLUSION = 24,
    MOVE = 25,
    FLOW_SHIELDING = 26,
    INFRARED_SHIELDING = 27,
    CHARGE_NO_ELECTRIC = 28,
    BATTERY_FAULT = 29,
    FAN_SPEED_ERROR = 30,
    LEFTWHELL_SPEED = 31,
    RIGHTWHELL_SPEED = 32,
    BMI055_ACCE = 33,
    BMI055_GYRO = 34,
    XV7001 = 35,
    LEFT_MAGNET = 36,
    RIGHT_MAGNET = 37,
    FLOW_ERROR = 38,
    INFRARED_FAULT = 39,
    CAMERA_FAULT = 40,
    STRONG_MAGNET = 41,
    WATER_PUMP = 42,
    RTC = 43,
    AUTO_KEY_TRIG = 44,
    P3V3 = 45,
    CAMERA_IDLE = 46,
    BLOCKED = 47,
    LDS_ERROR = 48,
    LDS_BUMPER = 49,
    WATER_PUMP_2 = 50,
    FILTER_BLOCKED = 51,
    EDGE = 54,
    CARPET = 55,
    LASER = 56,
    EDGE_2 = 57,
    ULTRASONIC = 58,
    NO_GO_ZONE = 59,
    ROUTE = 61,
    ROUTE_2 = 62,
    BLOCKED_2 = 63,
    BLOCKED_3 = 64,
    RESTRICTED = 65,
    RESTRICTED_2 = 66,
    RESTRICTED_3 = 67,
    REMOVE_MOP = 68,
    MOP_REMOVED = 69,
    MOP_REMOVED_2 = 70,
    MOP_PAD_STOP_ROTATE = 71,
    MOP_PAD_STOP_ROTATE_2 = 72,
    MOP_INSTALL_FAILED = 74,
    LOW_BATTERY_TURN_OFF = 75,
    DIRTY_TANK_NOT_INSTALLED = 76,
    ROBOT_IN_HIDDEN_ROOM = 78,
    BIN_FULL = 101,
    BIN_OPEN = 102,
    BIN_OPEN_2 = 103,
    BIN_FULL_2 = 104,
    WATER_TANK = 105,
    DIRTY_WATER_TANK = 106,
    WATER_TANK_DRY = 107,
    DIRTY_WATER_TANK_2 = 108,
    DIRTY_WATER_TANK_BLOCKED = 109,
    DIRTY_WATER_TANK_PUMP = 110,
    MOP_PAD = 111,
    WET_MOP_PAD = 112,
    CLEAN_MOP_PAD = 114,
    CLEAN_TANK_LEVEL = 116,
    STATION_DISCONNECTED = 117,
    DIRTY_TANK_LEVEL = 118,
    WASHBOARD_LEVEL = 119,
    NO_MOP_IN_STATION = 120,
    DUST_BAG_FULL = 121,
    UNKNOWN_WARNING_2 = 122,
    SELF_TEST_FAILED = 123,
    WASHBOARD_NOT_WORKING = 124,
    RETURN_TO_CHARGE_FAILED = 125);

  // Property
  TDreameVacuumProperty = (
    PROP_STATE = 0, PROP_ERROR = 1, PROP_BATTERY_LEVEL = 2, PROP_CHARGING_STATUS = 3,
    PROP_OFF_PEAK_CHARGING = 4, PROP_STATUS = 5, PROP_CLEANING_TIME = 6, PROP_CLEANED_AREA = 7,
    PROP_SUCTION_LEVEL = 8, PROP_WATER_VOLUME = 9, PROP_WATER_TANK = 10, PROP_TASK_STATUS = 11,
    PROP_CLEANING_START_TIME = 12, PROP_CLEAN_LOG_FILE_NAME = 13, PROP_CLEANING_PROPERTIES = 14,
    PROP_RESUME_CLEANING = 15, PROP_CARPET_BOOST = 16, PROP_CLEAN_LOG_STATUS = 17,
    PROP_SERIAL_NUMBER = 18, PROP_REMOTE_CONTROL = 19, PROP_MOP_CLEANING_REMAINDER = 20,
    PROP_CLEANING_PAUSED = 21, PROP_FAULTS = 22, PROP_NATION_MATCHED = 23, PROP_RELOCATION_STATUS = 24,
    PROP_OBSTACLE_AVOIDANCE = 25, PROP_AI_DETECTION = 26, PROP_CLEANING_MODE = 27,
    PROP_UPLOAD_MAP = 28, PROP_SELF_WASH_BASE_STATUS = 29, PROP_CUSTOMIZED_CLEANING = 30,
    PROP_CHILD_LOCK = 31, PROP_CARPET_SENSITIVITY = 32, PROP_TIGHT_MOPPING = 33,
    PROP_CLEANING_CANCEL = 34, PROP_Y_CLEAN = 35, PROP_WATER_ELECTROLYSIS = 36,
    PROP_CARPET_RECOGNITION = 37, PROP_SELF_CLEAN = 38, PROP_WARN_STATUS = 39,
    PROP_CARPET_CLEANING = 40, PROP_AUTO_ADD_DETERGENT = 41, PROP_CAPABILITY = 42,
    PROP_SAVE_WATER_TIPS = 43, PROP_DRYING_TIME = 44, PROP_LOW_WATER_WARNING = 45,
    PROP_MAP_INDEX = 46, PROP_MAP_NAME = 47, PROP_CRUISE_TYPE = 48, PROP_MOP_WASH_LEVEL = 49,
    PROP_AUTO_MOUNT_MOP = 50, PROP_SCHEDULED_CLEAN = 51, PROP_SHORTCUTS = 52,
    PROP_INTELLIGENT_RECOGNITION = 53, PROP_AUTO_SWITCH_SETTINGS = 54, PROP_AUTO_WATER_REFILLING = 55,
    PROP_MOP_IN_STATION = 56, PROP_MOP_PAD_INSTALLED = 57, PROP_WATER_CHECK = 58,
    PROP_DRY_STOP_REMAINDER = 59, PROP_NUMERIC_MESSAGE_PROMPT = 60, PROP_MESSAGE_PROMPT = 61,
    PROP_TASK_TYPE = 62, PROP_PET_DETECTIVE = 63, PROP_DRAINAGE_STATUS = 64,
    PROP_DOCK_CLEANING_STATUS = 65, PROP_BACK_CLEAN_MODE = 66, PROP_CLEANING_PROGRESS = 67,
    PROP_DRYING_PROGRESS = 68, PROP_DEVICE_CAPABILITY = 69, PROP_DND = 70,
    PROP_DND_START = 71, PROP_DND_END = 72, PROP_DND_TASK = 73, PROP_MAP_DATA = 74,
    PROP_FRAME_INFO = 75, PROP_OBJECT_NAME = 76, PROP_MAP_EXTEND_DATA = 77,
    PROP_ROBOT_TIME = 78, PROP_RESULT_CODE = 79, PROP_MULTI_FLOOR_MAP = 80,
    PROP_MAP_LIST = 81, PROP_RECOVERY_MAP_LIST = 82, PROP_MAP_RECOVERY = 83,
    PROP_MAP_RECOVERY_STATUS = 84, PROP_OLD_MAP_DATA = 85, PROP_MAP_BACKUP_STATUS = 86,
    PROP_WIFI_MAP = 87, PROP_RESTORE_MAP_BY_AREA = 88, PROP_VOLUME = 89,
    PROP_VOICE_PACKET_ID = 90, PROP_VOICE_CHANGE_STATUS = 91, PROP_VOICE_CHANGE = 92,
    PROP_VOICE_ASSISTANT = 93, PROP_VOICE_ASSISTANT_LANGUAGE = 94, PROP_EMPTY_STAMP = 95,
    PROP_CURRENT_CITY = 96, PROP_VOICE_TEST = 97, PROP_LISTEN_LANGUAGE_TYPE = 98,
    PROP_BAIDU_LOG = 99, PROP_RESPONSE_WORD = 100, PROP_DREAME_GPT = 101,
    PROP_LISTEN_LANGUAGE = 102, PROP_LISTEN_LANGUAGE_STATUS = 103, PROP_TIMEZONE = 104,
    PROP_SCHEDULE = 105, PROP_SCHEDULE_ID = 106, PROP_SCHEDULE_CANCEL_REASON = 107,
    PROP_CRUISE_SCHEDULE = 108, PROP_MAIN_BRUSH_TIME_LEFT = 109, PROP_MAIN_BRUSH_LEFT = 110,
    PROP_SIDE_BRUSH_TIME_LEFT = 111, PROP_SIDE_BRUSH_LEFT = 112, PROP_FILTER_LEFT = 113,
    PROP_FILTER_TIME_LEFT = 114, PROP_FIRST_CLEANING_DATE = 115, PROP_TOTAL_CLEANING_TIME = 116,
    PROP_CLEANING_COUNT = 117, PROP_TOTAL_CLEANED_AREA = 118, PROP_TOTAL_RUNTIME = 119,
    PROP_TOTAL_CRUISE_TIME = 120, PROP_MAP_SAVING = 121, PROP_ROBOT_CONFIG = 122,
    PROP_AUTO_DUST_COLLECTING = 123, PROP_AUTO_EMPTY_FREQUENCY = 124, PROP_DUST_COLLECTION = 125,
    PROP_AUTO_EMPTY_STATUS = 126, PROP_SENSOR_DIRTY_LEFT = 127, PROP_SENSOR_DIRTY_TIME_LEFT = 128,
    PROP_MOP_PAD_LEFT = 129, PROP_MOP_PAD_TIME_LEFT = 130, PROP_TANK_FILTER_LEFT = 131,
    PROP_TANK_FILTER_TIME_LEFT = 132, PROP_SILVER_ION_TIME_LEFT = 133, PROP_SILVER_ION_LEFT = 134,
    PROP_SILVER_ION_ADD = 135, PROP_DETERGENT_LEFT = 136, PROP_DETERGENT_TIME_LEFT = 137,
    PROP_SQUEEGEE_LEFT = 138, PROP_SQUEEGEE_TIME_LEFT = 139, PROP_ONBOARD_DIRTY_WATER_TANK_LEFT = 140,
    PROP_ONBOARD_DIRTY_WATER_TANK_TIME_LEFT = 141, PROP_DIRTY_WATER_TANK_LEFT = 142,
    PROP_DIRTY_WATER_TANK_TIME_LEFT = 143, PROP_CLEAN_WATER_TANK_STATUS = 144,
    PROP_DIRTY_WATER_TANK_STATUS = 145, PROP_DUST_BAG_STATUS = 146, PROP_DETERGENT_STATUS = 147,
    PROP_STATION_DRAINAGE_STATUS = 148, PROP_AI_MAP_OPTIMIZATION_STATUS = 149,
    PROP_SECOND_CLEANING_STATUS = 150, PROP_WATER_TANK_STATUS = 151, PROP_ADD_CLEANING_AREA_STATUS = 152,
    PROP_ADD_CLEANING_AREA_RESULT = 153, PROP_FIRST_CONNECT_WIFI = 154, PROP_HAND_DUST_STATUS = 155,
    PROP_HAND_DUST_CONNECT_STATUS = 156, PROP_HOT_WATER_STATUS = 157, PROP_WETNESS_LEVEL = 158,
    PROP_CLEAN_CARPETS_FIRST = 159, PROP_AUTO_LDS_LIFTING = 160, PROP_LDS_STATE = 161,
    PROP_CLEANGENIUS_MODE = 162, PROP_QUICK_WASH_MODE = 163, PROP_WATER_TEMPERATURE = 164,
    PROP_CLEAN_EFFICIENCY = 165, PROP_IMPACT_INJECTION_PUMP = 166, PROP_OBSTACLE_VIDEOS = 167,
    PROP_DND_DISABLE_RESUME_CLEANING = 168, PROP_DND_DISABLE_AUTO_EMPTY = 169,
    PROP_DND_REDUCE_VOLUME = 170, PROP_HAND_VACUUM_AUTO_DUSTING = 171, PROP_DYNAMIC_OBSTACLE_CLEAN = 172,
    PROP_HUMAN_NOISE_REDUCTION = 173, PROP_PET_CARE = 174, PROP_LOWER_HATCH_CONTROL = 175,
    PROP_SMART_MOP_WASHING = 176, PROP_BLOCK_HEALTH_CHECKS = 177, PROP_MOP_AFTER_VACUUM = 178,
    PROP_SMALL_AREA_FAST_CLEAN = 179, PROP_SHIELD_ULTRASONIC_SIGNALS = 180, PROP_SILENT_DRYING = 181,
    PROP_HAIR_COMPRESSION = 182, PROP_SIDE_BRUSH_CARPET_ROTATE = 183, PROP_ERP_LOW_POWER = 184,
    PROP_SHIELD_WASHBOARD_IN_PLACE = 185, PROP_SELF_CLEANING_PROBLEM = 186, PROP_WASHING_TEST = 187,
    PROP_FEEDBACK_SWITCH = 188, PROP_CARPET_AI_SEGMENT = 189, PROP_OBSTACLE_CROSSING = 190,
    PROP_VISUAL_RESUME = 191, PROP_FAN_ABNORMAL_NOISE = 192, PROP_LARGE_MEMORY_RESET = 193,
    PROP_BOW_BEFORE_EDGE = 194, PROP_VOLTAGE = 195, PROP_DETERGENT_A = 196,
    PROP_DETERGENT_B = 197, PROP_MOP_TEMPERATURE = 198, PROP_BATTERY_CHARGE_LEVEL = 199,
    PROP_DUST_BAG_DRYING = 200, PROP_SWEEP_DISTANCE = 201, PROP_LDS_LIFTING_FREQUENCY = 202,
    PROP_MOPPING_WITH_DETERGENT = 203, PROP_PRESSURIZED_CLEANING = 204, PROP_SCRAPER_FREQUENCY = 205,
    PROP_REALTIME_PARTICLE_DETECT = 206, PROP_IGNORE_STAIRS = 207, PROP_POWER_SAVING = 208,
    PROP_RING_LIGHT_ALWAYS_ON = 209, PROP_STORE_MODE = 210, PROP_INTEGRATED_POWER = 211,
    PROP_DEODORIZER_TIME_LEFT = 212, PROP_DEODORIZER_LEFT = 213, PROP_WHEEL_DIRTY_TIME_LEFT = 214,
    PROP_WHEEL_DIRTY_LEFT = 215, PROP_SCALE_INHIBITOR_TIME_LEFT = 216, PROP_SCALE_INHIBITOR_LEFT = 217,
    PROP_FACTORY_TEST_STATUS = 218, PROP_FACTORY_TEST_RESULT = 219, PROP_SELF_TEST_STATUS = 220,
    PROP_LSD_TEST_STATUS = 221, PROP_DEBUG_SWITCH = 222, PROP_SERIAL = 223,
    PROP_CALIBRATION_STATUS = 224, PROP_VERSION = 225, PROP_PERFORMANCE_SWITCH = 226,
    PROP_AI_TEST_STATUS = 227, PROP_PUBLIC_KEY = 228, PROP_AUTO_PAIR = 229,
    PROP_MCU_VERSION = 230, PROP_MOP_TEST_STATUS = 231, PROP_PLATFORM_NETWORK = 232,
    PROP_STREAM_STATUS = 233, PROP_STREAM_AUDIO = 234, PROP_STREAM_RECORD = 235,
    PROP_TAKE_PHOTO = 236, PROP_STREAM_KEEP_ALIVE = 237, PROP_STREAM_FAULT = 238,
    PROP_CAMERA_LIGHT_BRIGHTNESS = 239, PROP_CAMERA_LIGHT = 240, PROP_STREAM_VENDOR = 241,
    PROP_STREAM_PROPERTY = 242, PROP_STREAM_CRUISE_POINT = 243, PROP_STREAM_TASK = 244,
    PROP_STEAM_HUMAN_FOLLOW = 245, PROP_OBSTACLE_VIDEO_STATUS = 246, PROP_OBSTACLE_VIDEO_DATA = 247,
    PROP_STREAM_UPLOAD = 248, PROP_STREAM_CODE = 249, PROP_STREAM_SET_CODE = 250,
    PROP_STREAM_VERIFY_CODE = 251, PROP_STREAM_RESET_CODE = 252, PROP_STREAM_SPACE = 253
  );

  // klasa Action (IntEnum)
  TDreameVacuumAction = (
    ACT_START = 1, ACT_PAUSE = 2, ACT_CHARGE = 3, ACT_START_CUSTOM = 4,
    ACT_STOP = 5, ACT_CLEAR_WARNING = 6, ACT_START_WASHING = 7, ACT_GET_PHOTO_INFO = 8,
    ACT_SHORTCUTS = 9, ACT_REQUEST_MAP = 10, ACT_UPDATE_MAP_DATA = 11, ACT_BACKUP_MAP = 12,
    ACT_WIFI_MAP = 13, ACT_LOCATE = 14, ACT_TEST_SOUND = 15, ACT_DELETE_SCHEDULE = 16,
    ACT_DELETE_CRUISE_SCHEDULE = 17, ACT_RESET_MAIN_BRUSH = 18, ACT_RESET_SIDE_BRUSH = 19,
    ACT_RESET_FILTER = 20, ACT_RESET_SENSOR = 21, ACT_START_AUTO_EMPTY = 22,
    ACT_RESET_TANK_FILTER = 23, ACT_RESET_MOP_PAD = 24, ACT_RESET_SILVER_ION = 25,
    ACT_RESET_DETERGENT = 26, ACT_RESET_SQUEEGEE = 27, ACT_RESET_ONBOARD_DIRTY_WATER_TANK = 28,
    ACT_RESET_DIRTY_WATER_TANK = 29, ACT_RESET_DEODORIZER = 30, ACT_RESET_WHEEL = 31,
    ACT_RESET_SCALE_INHIBITOR = 32, ACT_STREAM_VIDEO = 33, ACT_STREAM_AUDIO = 34,
    ACT_STREAM_PROPERTY = 35, ACT_STREAM_CODE = 36);

  // Zarz¹dzanie s³ownikami pomieszczeñ i dekodowaniem IntEnumów
  TPlikTypes = class
  private
    class var FSegmentNames: TDictionary<Integer, string>;
    class var FSegmentIcons: TDictionary<Integer, string>;
    class procedure InicjalizujSlowniki; static;
    class procedure ZwolnijSlowniki; static;
  public
    class function GetSegmentName(Code: Integer): string; static;
    class function GetSegmentIcon(Code: Integer): string; static;
    class function IntToErrorCode(Code: Integer): TDreameVacuumErrorCode; static;
    class function IntToChargingStatus(Code: Integer): TDreameVacuumChargingStatus; static;
  end;

implementation

{ TPlikTypes }

class procedure TPlikTypes.InicjalizujSlowniki;
begin
  if Assigned(FSegmentNames) then Exit;

  FSegmentNames := TDictionary<Integer, string>.Create;
  FSegmentNames.Add(0, 'Room');
  FSegmentNames.Add(1, 'Living Room');
  FSegmentNames.Add(2, 'Primary Bedroom');
  FSegmentNames.Add(3, 'Study');
  FSegmentNames.Add(4, 'Kitchen');
  FSegmentNames.Add(5, 'Dining Hall');
  FSegmentNames.Add(6, 'Bathroom');
  FSegmentNames.Add(7, 'Balcony');
  FSegmentNames.Add(8, 'Corridor');
  FSegmentNames.Add(9, 'Utility Room');
  FSegmentNames.Add(10, 'Closet');
  FSegmentNames.Add(11, 'Meeting Room');
  FSegmentNames.Add(12, 'Office');
  FSegmentNames.Add(13, 'Fitness Area');
  FSegmentNames.Add(14, 'Recreation Area');
  FSegmentNames.Add(15, 'Secondary Bedroom');

  FSegmentIcons := TDictionary<Integer, string>.Create;
  FSegmentIcons.Add(0, 'mdi:home-outline');
  FSegmentIcons.Add(1, 'mdi:sofa-outline');
  FSegmentIcons.Add(2, 'mdi:bed-king-outline');
  FSegmentIcons.Add(3, 'mdi:bookshelf');
  FSegmentIcons.Add(4, 'mdi:chef-hat');
  FSegmentIcons.Add(5, 'mdi:room-service-outline');
  FSegmentIcons.Add(6, 'mdi:toilet');
  FSegmentIcons.Add(7, 'mdi:flower-outline');
  FSegmentIcons.Add(8, 'mdi:foot-print');
  FSegmentIcons.Add(9, 'mdi:archive-outline');
  FSegmentIcons.Add(10, 'mdi:hanger');
  FSegmentIcons.Add(11, 'mdi:presentation');
  FSegmentIcons.Add(12, 'mdi:monitor-shimmer');
  FSegmentIcons.Add(13, 'mdi:dumbbell');
  FSegmentIcons.Add(14, 'mdi:gamepad-variant-outline');
  FSegmentIcons.Add(15, 'mdi:bed-single-outline');
end;

class procedure TPlikTypes.ZwolnijSlowniki;
begin
  FreeAndNil(FSegmentNames);
  FreeAndNil(FSegmentIcons);
end;

class function TPlikTypes.GetSegmentName(Code: Integer): string;
begin
  InicjalizujSlowniki;
  if not FSegmentNames.TryGetValue(Code, Result) then Result := 'Unknown Room';
end;

class function TPlikTypes.GetSegmentIcon(Code: Integer): string;
begin
  InicjalizujSlowniki;
  if not FSegmentIcons.TryGetValue(Code, Result) then Result := 'mdi:help-circle-outline';
end;

class function TPlikTypes.IntToErrorCode(Code: Integer): TDreameVacuumErrorCode;
begin
  if (Code >= 0) and (Code <= 78) then Result := TDreameVacuumErrorCode(Code)
  else if (Code >= 101) and (Code <= 125) then Result := TDreameVacuumErrorCode(Code)
  else Result := TDreameVacuumErrorCode.UNKNOWN_ERROR;
end;

class function TPlikTypes.IntToChargingStatus(Code: Integer): TDreameVacuumChargingStatus;
begin
  try
    Result := TDreameVacuumChargingStatus(Code);
    if Result in [CHARGING, NOT_CHARGING, CHARGING_COMPLETED, RETURN_TO_CHARGE] then
      Exit;
  except
    ;
  end;
  Result := TDreameVacuumChargingStatus.UNKNOWN_CHARGING;
end;

end.
