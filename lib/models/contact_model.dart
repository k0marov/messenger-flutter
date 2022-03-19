
class ContactModel {
  final String phone; 
  final String contactsName; 
  final String? userId; 

  const ContactModel({
    required this.phone, 
    required this.contactsName, 
    this.userId, 
  }); 
} 
