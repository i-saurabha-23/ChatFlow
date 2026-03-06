import 'package:permission_handler/permission_handler.dart';

class AppPermissionsService {
  static const List<Permission> _corePermissions = [
    Permission.contacts,
    Permission.camera,
    Permission.microphone,
    Permission.storage,
    Permission.photos,
    Permission.videos,
    Permission.audio,
  ];

  Future<Map<Permission, PermissionStatus>> requestCorePermissions() async {
    final result = <Permission, PermissionStatus>{};

    for (final permission in _corePermissions) {
      final status = await permission.status;
      if (status.isGranted || status.isLimited) {
        result[permission] = status;
        continue;
      }

      result[permission] = await permission.request();
    }

    return result;
  }

  bool isContactsGranted(Map<Permission, PermissionStatus> statuses) {
    final status = statuses[Permission.contacts];
    if (status == null) {
      return false;
    }
    return status.isGranted || status.isLimited;
  }

  List<String> deniedPermissionLabels(
    Map<Permission, PermissionStatus> statuses,
  ) {
    final denied = <String>[];

    void addIfDenied(Permission permission, String label) {
      final status = statuses[permission];
      if (status == null) {
        return;
      }
      if (!status.isGranted && !status.isLimited) {
        denied.add(label);
      }
    }

    addIfDenied(Permission.contacts, 'Contacts');
    addIfDenied(Permission.camera, 'Camera');
    addIfDenied(Permission.microphone, 'Microphone');

    final storageStatuses = [
      statuses[Permission.storage],
      statuses[Permission.photos],
      statuses[Permission.videos],
      statuses[Permission.audio],
    ].whereType<PermissionStatus>();

    final anyStorageGranted = storageStatuses.any(
      (status) => status.isGranted || status.isLimited,
    );

    if (!anyStorageGranted) {
      denied.add('Storage/Media');
    }

    return denied;
  }

  bool hasAnyPermanentlyDenied(
    Map<Permission, PermissionStatus> statuses,
  ) {
    return statuses.values.any((status) => status.isPermanentlyDenied);
  }
}
