class AnnouncementItem {
  final String id;
  final String title;
  final String description;
  final String? createdByName;
  final List<dynamic> targetBranches; // Renamed from targetCompanies
  final bool isAllBranches;
  final int totalViews;
  final int totalReads;
  final String status;
  final bool isActive;
  final bool isPinned;
  final DateTime createdAt;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.description,
    this.createdByName,
    required this.targetBranches,
    required this.isAllBranches,
    required this.totalViews,
    required this.totalReads,
    required this.status,
    required this.isActive,
    required this.isPinned,
    required this.createdAt,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdByName: json['createdBy']?['name'],
      targetBranches: json['targetBranches'] ?? [],
      isAllBranches: json['isAllBranches'] ?? false,
      totalViews: json['totalViews'] ?? 0,
      totalReads: json['totalReads'] ?? 0,
      status: json['status'] ?? 'published',
      isActive: json['isActive'] ?? true,
      isPinned: json['isPinned'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get formattedDateTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      final hours = diff.inHours;
      return hours == 0
          ? 'Just now'
          : '$hours ${hours == 1 ? 'hr' : 'hrs'} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    }
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  String get formattedDate {
    // Convert UTC from backend to local (IST when device is IST)
    final local = createdAt.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    // Example: 09/12/2025, 11:58 AM
    final isPm = local.hour >= 12;
    final hour12 = ((local.hour + 11) % 12 + 1).toString().padLeft(2, '0');
    final ampm = isPm ? 'PM' : 'AM';

    return '$day/$month/$year, $hour12:$minute $ampm';
  }

  String get branchText {
    if (isAllBranches) return 'All Branches';

    if (targetBranches.isEmpty) return 'General';

    try {
      // Check if the first item is a Map (Object) with a 'name' key
      if (targetBranches.first is Map &&
          targetBranches.first.containsKey('name')) {
        final names = targetBranches
            .map((b) => b['name']?.toString() ?? 'Unknown')
            .toList();

        if (names.length <= 2) {
          return names.join(', ');
        } else {
          return '${names[0]}, ${names[1]} +${names.length - 2}';
        }
      }

      // Fallback: If it's still just a list of IDs (strings)
      return '${targetBranches.length} selected ${targetBranches.length == 1 ? 'branch' : 'branches'}';
    } catch (e) {
      return 'Multiple Branches';
    }
  }
}
