class AttendanceSettings {
  final String? id;
  final WorkTimings? workTimings;
  final AttendanceModes? attendanceModes;
  final AutomationRules? automationRules;
  final LeaveIntegration? leaveIntegration;
  final bool staffCanViewOwnAttendance;

  AttendanceSettings({
    this.id,
    this.workTimings,
    this.attendanceModes,
    this.automationRules,
    this.leaveIntegration,
    this.staffCanViewOwnAttendance = false,
  });

  factory AttendanceSettings.fromJson(Map<String, dynamic> json) {
    // The backend returns { scheduleType: "...", attendance: { ... } }
    // We are interested in the 'attendance' object mostly
    final data = json['attendance'] ?? {};

    return AttendanceSettings(
      id: data['_id'],
      workTimings: data['workTimings'] != null
          ? WorkTimings.fromJson(data['workTimings'])
          : null,
      attendanceModes: data['attendanceModes'] != null
          ? AttendanceModes.fromJson(data['attendanceModes'])
          : null,
      automationRules: data['automationRules'] != null
          ? AutomationRules.fromJson(data['automationRules'])
          : null,
      leaveIntegration: data['leaveIntegration'] != null
          ? LeaveIntegration.fromJson(data['leaveIntegration'])
          : null,
      staffCanViewOwnAttendance: data['staffCanViewOwnAttendance'] ?? false,
    );
  }
}

class WorkTimings {
  final String scheduleType; // "Fixed", "Flexible", "Not Set"
  final FixedSchedule? fixed;

  WorkTimings({this.scheduleType = "Not Set", this.fixed});

  factory WorkTimings.fromJson(Map<String, dynamic> json) {
    return WorkTimings(
      scheduleType: json['scheduleType'] ?? "Not Set",
      fixed:
          json['fixed'] != null ? FixedSchedule.fromJson(json['fixed']) : null,
    );
  }
}

class FixedSchedule {
  final List<FixedDay> days;

  FixedSchedule({this.days = const []});

  factory FixedSchedule.fromJson(Map<String, dynamic> json) {
    var list = json['days'] as List?;
    List<FixedDay> daysList =
        list != null ? list.map((i) => FixedDay.fromJson(i)).toList() : [];
    return FixedSchedule(days: daysList);
  }
}

class FixedDay {
  final String day;
  final bool isWeekoff;
  final Shift? selectedShift;

  FixedDay({required this.day, this.isWeekoff = false, this.selectedShift});

  factory FixedDay.fromJson(Map<String, dynamic> json) {
    return FixedDay(
      day: json['day'] ?? '',
      isWeekoff: json['isWeekoff'] ?? false,
      selectedShift:
          json['selectedShift'] != null && json['selectedShift'] is Map
              ? Shift.fromJson(json['selectedShift'])
              : null, // Handle case where it might be just an ID string or null
    );
  }
}

class Shift {
  final String name;
  final String startTime;
  final String endTime;

  Shift({required this.name, required this.startTime, required this.endTime});

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      name: json['name'] ?? 'Unknown Shift',
      startTime: json['startTime'] ?? '--:--',
      endTime: json['endTime'] ?? '--:--',
    );
  }
}

class AttendanceModes {
  final bool enableSmartphone;
  final SmartphoneSettings? smartphone;

  AttendanceModes({this.enableSmartphone = true, this.smartphone});

  factory AttendanceModes.fromJson(Map<String, dynamic> json) {
    return AttendanceModes(
      enableSmartphone: json['enableSmartphoneAttendance'] ?? true,
      smartphone: json['smartphone'] != null
          ? SmartphoneSettings.fromJson(json['smartphone'])
          : null,
    );
  }
}

class SmartphoneSettings {
  final bool selfieAttendance;
  final bool qrAttendance;
  final bool gpsAttendance;
  final String markAttendanceFrom;

  SmartphoneSettings({
    this.selfieAttendance = false,
    this.qrAttendance = false,
    this.gpsAttendance = true,
    this.markAttendanceFrom = 'Anywhere',
  });

  factory SmartphoneSettings.fromJson(Map<String, dynamic> json) {
    return SmartphoneSettings(
      selfieAttendance: json['selfieAttendance'] ?? false,
      qrAttendance: json['qrAttendance'] ?? false,
      gpsAttendance: json['gpsAttendance'] ?? true,
      markAttendanceFrom: json['markAttendanceFrom'] ?? 'Anywhere',
    );
  }
}

class AutomationRules {
  final bool autoPresentAtDayStart;
  final bool presentOnPunchIn;
  final TimeDuration? autoHalfDayIfLateBy;
  final TimeDuration? mandatoryHalfDayHours;
  final TimeDuration? mandatoryFullDayHours;

  AutomationRules({
    this.autoPresentAtDayStart = false,
    this.presentOnPunchIn = true,
    this.autoHalfDayIfLateBy,
    this.mandatoryHalfDayHours,
    this.mandatoryFullDayHours,
  });

  factory AutomationRules.fromJson(Map<String, dynamic> json) {
    return AutomationRules(
      autoPresentAtDayStart: json['autoPresentAtDayStart'] ?? false,
      presentOnPunchIn: json['presentOnPunchIn'] ?? true,
      autoHalfDayIfLateBy: json['autoHalfDayIfLateBy'] != null
          ? TimeDuration.fromJson(json['autoHalfDayIfLateBy'])
          : null,
      mandatoryHalfDayHours: json['mandatoryHalfDayHours'] != null
          ? TimeDuration.fromJson(json['mandatoryHalfDayHours'])
          : null,
      mandatoryFullDayHours: json['mandatoryFullDayHours'] != null
          ? TimeDuration.fromJson(json['mandatoryFullDayHours'])
          : null,
    );
  }
}

class TimeDuration {
  final int hours;
  final int minutes;

  TimeDuration({this.hours = 0, this.minutes = 0});

  factory TimeDuration.fromJson(Map<String, dynamic> json) {
    return TimeDuration(
      hours: json['hours'] ?? 0,
      minutes: json['minutes'] ?? 0,
    );
  }

  @override
  String toString() => "${hours}h ${minutes}m";
}

class LeaveIntegration {
  final bool autoDeductLeave;
  final bool notifyLowAttendance;

  LeaveIntegration(
      {this.autoDeductLeave = false, this.notifyLowAttendance = true});

  factory LeaveIntegration.fromJson(Map<String, dynamic> json) {
    return LeaveIntegration(
      autoDeductLeave: json['autoDeductLeave'] ?? false,
      notifyLowAttendance: json['notifyLowAttendance'] ?? true,
    );
  }
}
