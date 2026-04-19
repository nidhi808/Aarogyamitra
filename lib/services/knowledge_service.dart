import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'csv_loader_service.dart';

class Hospital {
  final String name;
  final String city;
  final String address;
  final String contact;

  Hospital({required this.name, required this.city, required this.address, required this.contact});
}

class Doctor {
  final String name;
  final String speciality;

  Doctor({required this.name, required this.speciality});
}

class KnowledgeService {
  late CsvLoaderService _csvService;

  Future<void> init({CsvLoaderService? csvService}) async {
    _csvService = csvService ?? CsvLoaderService();
  }

  Future<List<Hospital>> get hospitals async {
    return getInstantHospitals();
  }

  List<Hospital> getInstantHospitals() {
    return [..._getMumbaiHospitals(), ..._getThaneHospitals()];
  }

  Future<List<Hospital>> searchHospitalsByCity(String city) async {
    print("Searching hospitals for city: $city");
    
    // Check CSV first for dynamic lookup
    final results = _csvService.searchHospitals(city);
    if (results.isNotEmpty) return results;

    // Fallback to switch case / fast paths
    switch (city.toLowerCase()) {
      case 'mumbai':
      case 'bombay':
        return _getMumbaiHospitals();
      case 'thane':
        return _getThaneHospitals();
      default:
        return getInstantHospitals();
    }
  }

  List<Hospital> _getMumbaiHospitals() {
    return [
      Hospital(
        name: "LTMG Sion Hospital",
        city: "Mumbai",
        address: "Sion, Mumbai, Maharashtra 400022",
        contact: "022 2407 6381",
      ),
      Hospital(
        name: "KEM Hospital",
        city: "Mumbai",
        address: "Parel, Mumbai, Maharashtra 400012",
        contact: "022 2410 7000",
      ),
      Hospital(
        name: "Sir H. N. Reliance Foundation Hospital",
        city: "Mumbai",
        address: "Prarthana Samaj, Girgaon, Mumbai",
        contact: "1800 221 166",
      ),
    ];
  }

  List<Hospital> _getThaneHospitals() {
    return [
      Hospital(
        name: "Jupiter Hospital",
        city: "Thane",
        address: "Eastern Express Hwy, Thane West",
        contact: "022 2172 5555",
      ),
      Hospital(
        name: "Bethany Hospital",
        city: "Thane",
        address: "Pokhran Rd Number 2, Thane West",
        contact: "022 2172 5111",
      ),
      Hospital(
        name: "Chhatrapati Shivaji Maharaj Hospital",
        city: "Thane",
        address: "Kalwa, Thane, Maharashtra 400605",
        contact: "022 2537 2595",
      ),
    ];
  }

  // Maintaining signature for compatibility
  // Dynamic lookup for doctors from CSV
  Future<Doctor?> findDoctorBySpeciality(String speciality) async {
    final doctors = _csvService.getDoctorsBySpecialty(speciality);
    if (doctors.isNotEmpty) return doctors.first;
    
    // Fallback
    return Doctor(name: "Dr. Rahul Sharma", speciality: speciality);
  }
}
