class EducationModel {
  final String schoolName;
  final String degree;
  final String fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;
  final String activities;
  final String description;
  final String schoolLogoUrl;

  EducationModel({
    required this.schoolName,
    this.degree = '',
    this.fieldOfStudy = '',
    this.startDate,
    this.endDate,
    this.activities = '',
    this.description = '',
    this.schoolLogoUrl = '',
  });

  factory EducationModel.fromMap(Map<String, dynamic> map) => EducationModel(
    schoolName: map['schoolName'] ?? '',
    degree: map['degree'] ?? '',
    fieldOfStudy: map['fieldOfStudy'] ?? '',
    startDate:
        map['startDate'] != null ? DateTime.tryParse(map['startDate']) : null,
    endDate: map['endDate'] != null ? DateTime.tryParse(map['endDate']) : null,
    activities: map['activities'] ?? '',
    description: map['description'] ?? '',
    schoolLogoUrl: map['schoolLogoUrl'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'schoolName': schoolName,
    'degree': degree,
    'fieldOfStudy': fieldOfStudy,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'activities': activities,
    'description': description,
    'schoolLogoUrl': schoolLogoUrl,
  };

  EducationModel copyWith({
    String? schoolName,
    String? degree,
    String? fieldOfStudy,
    DateTime? startDate,
    DateTime? endDate,
    String? activities,
    String? description,
    String? schoolLogoUrl,
  }) {
    return EducationModel(
      schoolName: schoolName ?? this.schoolName,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      activities: activities ?? this.activities,
      description: description ?? this.description,
      schoolLogoUrl: schoolLogoUrl ?? this.schoolLogoUrl,
    );
  }
}
