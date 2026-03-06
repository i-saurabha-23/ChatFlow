class ContactModel {
  final String id;
  final String fullName;
  final String? email;
  final String phoneNumber;
  final String about;
  final bool isOnChatFlow;
  final bool isSavedInDevice;

  const ContactModel({
    required this.id,
    required this.fullName,
    this.email,
    required this.phoneNumber,
    required this.about,
    required this.isOnChatFlow,
    required this.isSavedInDevice,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    final phoneNumber = json['phoneNumber']?.toString().trim();

    return ContactModel(
      id: json['id'].toString(),
      fullName: json['fullName']?.toString() ?? 'Unknown',
      email: json['email']?.toString(),
      phoneNumber: (phoneNumber == null || phoneNumber.isEmpty)
          ? 'No phone number'
          : phoneNumber,
      about: 'Available',
      isOnChatFlow: true,
      isSavedInDevice: true,
    );
  }
}
