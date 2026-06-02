class Clinic {
  final String id;
  final String name;
  final String specialty;
  final String address;
  final String imageUrl;
  final double rating;
  final String distance;
  final List<Doctor> doctors;

  Clinic({
    required this.id,
    required this.name,
    required this.specialty,
    required this.address,
    required this.imageUrl,
    required this.rating,
    required this.distance,
    required this.doctors,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? 'General Clinic',
      address: json['address'] ?? '',
      imageUrl: json['imageUrl'] ?? 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=500&auto=format&fit=crop',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      distance: json['distance'] ?? '1.2 km',
      doctors: (json['doctors'] as List?)
              ?.map((d) => Doctor.fromJson(d))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'address': address,
      'imageUrl': imageUrl,
      'rating': rating,
      'distance': distance,
      'doctors': doctors.map((d) => d.toJson()).toList(),
    };
  }
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String imageUrl;
  final double rating;
  final int experienceYears;
  final List<String> availableSlots;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
    required this.rating,
    required this.experienceYears,
    required this.availableSlots,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? 'General Practitioner',
      imageUrl: json['imageUrl'] ?? 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&auto=format&fit=crop',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      experienceYears: json['experienceYears'] ?? 5,
      availableSlots: List<String>.from(json['availableSlots'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'imageUrl': imageUrl,
      'rating': rating,
      'experienceYears': experienceYears,
      'availableSlots': availableSlots,
    };
  }
}
