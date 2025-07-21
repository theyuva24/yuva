class ExperienceModel {
  final String jobTitle;
  final String companyName;
  final String companyLogoUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final String location;
  final String description;

  ExperienceModel({
    required this.jobTitle,
    required this.companyName,
    this.companyLogoUrl = '',
    this.startDate,
    this.endDate,
    this.location = '',
    this.description = '',
  });

  factory ExperienceModel.fromMap(Map<String, dynamic> map) => ExperienceModel(
    jobTitle: map['jobTitle'] ?? '',
    companyName: map['companyName'] ?? '',
    companyLogoUrl: map['companyLogoUrl'] ?? '',
    startDate:
        map['startDate'] != null ? DateTime.tryParse(map['startDate']) : null,
    endDate: map['endDate'] != null ? DateTime.tryParse(map['endDate']) : null,
    location: map['location'] ?? '',
    description: map['description'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'jobTitle': jobTitle,
    'companyName': companyName,
    'companyLogoUrl': companyLogoUrl,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'location': location,
    'description': description,
  };

  ExperienceModel copyWith({
    String? jobTitle,
    String? companyName,
    String? companyLogoUrl,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? description,
  }) {
    return ExperienceModel(
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      description: description ?? this.description,
    );
  }
}
