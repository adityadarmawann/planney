import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/expense_plan_model.dart';

class CalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  String? _calendarId;

  Future<bool> _isCalendarPermissionGranted() async {
    final fullAccessStatus = await Permission.calendarFullAccess.status;
    if (fullAccessStatus.isGranted) return true;

    final writeOnlyStatus = await Permission.calendarWriteOnly.status;
    return writeOnlyStatus.isGranted;
  }

  /// Request calendar permission
  Future<bool> requestPermission() async {
    try {
      final fullAccessPermission = await Permission.calendarFullAccess.request();
      if (fullAccessPermission.isGranted) return true;

      final writeOnlyPermission = await Permission.calendarWriteOnly.request();
      return writeOnlyPermission.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Check if calendar permission is granted
  Future<bool> hasPermission() async {
    try {
      return await _isCalendarPermissionGranted();
    } catch (e) {
      return false;
    }
  }

  /// Get or create Planney calendar
  Future<String?> _getOrCreateCalendar() async {
    if (_calendarId != null) return _calendarId;

    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        // Look for existing Planney calendar
        final existingCalendar = calendarsResult.data!.firstWhere(
          (cal) => cal.name == 'Planney - Rencana Pengeluaran',
          orElse: () => calendarsResult.data!.first,
        );

        _calendarId = existingCalendar.id;
        return _calendarId;
      }
    } catch (e) {
      // If calendar retrieval fails, use default calendar
      return null;
    }
    return null;
  }

  /// Sync expense plan to device calendar
  Future<String?> syncExpensePlanToCalendar(ExpensePlan plan) async {
    try {
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) return null;
      }

      final calendarId = await _getOrCreateCalendar();
      if (calendarId == null) return null;

      final plannedDateTime = plan.plannedDateTime;

      // Calculate reminder time
      DateTime? reminderTime;
      if (plan.reminderType != null) {
        switch (plan.reminderType) {
          case 'h-1':
            reminderTime = plannedDateTime.subtract(const Duration(days: 1));
            break;
          case 'h-3':
            reminderTime = plannedDateTime.subtract(const Duration(hours: 3));
            break;
          case 'custom':
            final customMinutes = plan.effectiveCustomReminderMinutes;
            if (customMinutes != null && customMinutes > 0) {
              reminderTime = plannedDateTime.subtract(
                Duration(minutes: customMinutes),
              );
            }
            break;
        }
      }

      // Create event
      final event = Event(
        calendarId,
        eventId: plan.id, // Use expense plan ID as event ID
        title: '💸 ${plan.title}',
        description: _buildEventDescription(plan),
        start: TZDateTime.from(plannedDateTime, _getLocation('Asia/Jakarta')),
        end: TZDateTime.from(
          plannedDateTime.add(const Duration(hours: 1)),
          _getLocation('Asia/Jakarta'),
        ),
        allDay: false,
      );

      // Add reminder if set
      if (reminderTime != null) {
        final reminderMinutes = plannedDateTime.difference(reminderTime).inMinutes;
        if (reminderMinutes > 0) {
          event.reminders = [Reminder(minutes: reminderMinutes)];
        }
      }

      // Create or update event
      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      
      if (result != null && result.isSuccess && result.data != null) {
        return result.data; // Return event ID
      }
    } catch (e) {
      // Silently fail - calendar sync is optional
      return null;
    }
    return null;
  }

  /// Delete expense plan from calendar
  Future<bool> deleteExpensePlanFromCalendar(
    String eventId,
    String calendarId,
  ) async {
    try {
      if (!await hasPermission()) return false;

      final result = await _deviceCalendarPlugin.deleteEvent(
        calendarId,
        eventId,
      );

      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Delete expense plan from calendar using plan ID as event ID
  Future<bool> deleteExpensePlanByPlanId(String planId) async {
    try {
      if (!await hasPermission()) return false;

      final calendarId = await _getOrCreateCalendar();
      if (calendarId == null) return false;

      final result = await _deviceCalendarPlugin.deleteEvent(
        calendarId,
        planId,
      );

      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Strict sync: throw exception if calendar sync fails
  Future<void> ensureSyncExpensePlanToCalendar(ExpensePlan plan) async {
    final eventId = await syncExpensePlanToCalendar(plan);
    if (eventId == null) {
      throw Exception('Sinkronisasi kalender gagal. Pastikan izin kalender aktif.');
    }
  }

  /// Strict delete: throw exception if calendar delete fails
  Future<void> ensureDeleteExpensePlanByPlanId(String planId) async {
    final deleted = await deleteExpensePlanByPlanId(planId);
    if (!deleted) {
      throw Exception('Gagal menghapus event kalender. Pastikan izin kalender aktif.');
    }
  }

  /// Build event description
  String _buildEventDescription(ExpensePlan plan) {
    final buffer = StringBuffer();
    buffer.writeln('Kategori: ${plan.category}');
    buffer.writeln('Jumlah: Rp ${plan.amount.toStringAsFixed(0)}');
    buffer.writeln('Sumber Pembayaran: ${plan.paymentSource}');
    buffer.writeln('Waktu Pengeluaran: ${plan.plannedTime}');
    if (plan.notes != null && plan.notes!.isNotEmpty) {
      buffer.writeln('\nCatatan:');
      buffer.writeln(plan.notes);
    }
    buffer.writeln('\n📱 Dibuat dari Planney App');
    return buffer.toString();
  }

  /// Helper to get timezone location
  Location _getLocation(String locationName) {
    try {
      return tz.getLocation(locationName);
    } catch (e) {
      return tz.local;
    }
  }
}
