import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'knowledge_service.dart'; // To reuse Hospital and Doctor classes
import '../models/scheme_rule.dart';

class CsvLoaderService {
  List<Doctor> _doctors = [];
  List<Hospital> _hospitals = [];
  List<SchemeRule> _schemeRules = [];

  Future<void> loadDoctors() async {
    try {
      final ByteData data = await rootBundle.load('assets/data/doctors.csv');
      String decoded = utf8.decode(data.buffer.asUint8List(), allowMalformed: true);
      
      // Remove BOM if present
      if (decoded.startsWith('\uFEFF')) {
        decoded = decoded.substring(1);
      }
      
      List<List<dynamic>> csvTable = const CsvToListConverter(
        eol: '\n', 
        shouldParseNumbers: false,
        allowInvalid: true
      ).convert(decoded);
      
      print("CSV Loader: Doctors file string length: ${decoded.length}");
      print("CSV Loader: Doctors table row count: ${csvTable.length}");
      
      if (csvTable.isNotEmpty) {
        print("CSV Loader: Doctors Header row: ${csvTable[0]}");
        if (csvTable.length > 1) {
          print("CSV Loader: Doctors First data row: ${csvTable[1]}");
        }
      }

      _doctors = csvTable
          .where((row) => row.length >= 2)
          .skip(1) // Skip header
          .map((row) {
            // Index 0: Sr No, Index 1: Name, Index 2: Specialty
            // Since some rows have extra commas inside quotes, CsvToListConverter handles them,
            // but we need to ensure we pick the right columns.
            String name = row.length > 1 ? row[1].toString().trim() : "Unknown";
            String specialty = row.length >= row.length - 1 ? row.last.toString().trim() : "General";
            
            // Cleanup specialty if it's too long or has noise
            if (specialty.length > 50) specialty = "Specialist";
            
            return Doctor(name: name, speciality: specialty);
          })
          .where((d) => d.name.isNotEmpty && !d.name.contains("Doctor's Name"))
          .toList();
          
      print("CSV Loader: Final processed Doctors: ${_doctors.length}");
    } catch (e) {
      print("CSV Loader Error (Doctors): $e");
    }
  }

  Future<void> loadHospitals() async {
    try {
      final ByteData data = await rootBundle.load('assets/data/hospitals.csv');
      final String decoded = utf8.decode(data.buffer.asUint8List(), allowMalformed: true);
      List<List<dynamic>> csvTable = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(decoded);
      
      _hospitals = csvTable.skip(3).map((row) {
        if (row.length < 5) return null;
        return Hospital(
          name: row[1].toString(),
          city: row[3].toString(),
          address: row.length > 6 ? row[6].toString() : "Maharashtra",
          contact: row.length > 8 ? "${row[7]}-${row[8]}" : "9076200636",
        );
      }).whereType<Hospital>().toList();
      
      print("CSV Loader: Loaded ${_hospitals.length} hospitals.");
    } catch (e) {
      print("CSV Loader Error (Hospitals): $e");
    }
  }

  Future<void> loadSchemeRules() async {
    try {
      final ByteData data = await rootBundle.load('assets/data/schemes.csv');
      final String decoded = utf8.decode(data.buffer.asUint8List(), allowMalformed: true);
      List<List<dynamic>> csvTable = const CsvToListConverter(shouldParseNumbers: false).convert(decoded);
      
      // age,gender,problem,has_bpl_card,has_ayushman_card,has_white_ration_card,residency,scheme,eligible,benefit,documents
      _schemeRules = csvTable.skip(1).map((row) {
        if (row.length < 11) return null;
        return SchemeRule(
          age: row[0].toString(),
          gender: row[1].toString(),
          problem: row[2].toString(),
          hasBplCard: row[3].toString().toLowerCase() == 'true',
          hasAyushmanCard: row[4].toString().toLowerCase() == 'true',
          hasWhiteRationCard: row[5].toString().toLowerCase() == 'true',
          residency: row[6].toString(),
          scheme: row[7].toString(),
          eligible: row[8].toString().toLowerCase() == 'true',
          benefit: row[9].toString(),
          documents: row[10].toString(),
        );
      }).whereType<SchemeRule>().toList();
      
      print("CSV Loader: Loaded ${_schemeRules.length} scheme rules.");
    } catch (e) {
      print("CSV Loader Error (Schemes): $e");
    }
  }

  List<SchemeRule> getMatchingSchemes({
    required String symptoms,
    required bool hasBpl,
    required bool hasAyushman,
    required bool hasWhiteRation,
    required bool isLocal,
  }) {
    final s = symptoms.toLowerCase();
    
    // Simple matching logic: find rules where problem keywords match symptoms
    // and card status matches
    return _schemeRules.where((rule) {
      // 1. Check if the problem matches (Keywords)
      bool problemMatch = s.contains(rule.problem.toLowerCase()) || 
                         rule.problem.toLowerCase().split(',').any((k) => s.contains(k.trim().toLowerCase()));
      
      // Fallback for universal schemes if symptom is short
      if (s.length < 5) problemMatch = true;

      // 2. Check if the card status matches exactly what the rule requires
      // Priority matching:
      bool cardMatch = false;
      if (hasAyushman && rule.hasAyushmanCard) cardMatch = true;
      else if (hasBpl && rule.hasBplCard) cardMatch = true;
      else if (hasWhiteRation && rule.hasWhiteRationCard) cardMatch = true;
      
      // 3. Handle rules that require NO special card (General/Universal)
      bool universalRule = !rule.hasBplCard && !rule.hasAyushmanCard && !rule.hasWhiteRationCard;

      return problemMatch && (cardMatch || universalRule);
    }).toList();
  }

  List<Doctor> getDoctorsBySpecialty(String specialty) {
    final search = specialty.toLowerCase();
    return _doctors
        .where((d) => d.speciality.toLowerCase().contains(search))
        .toList();
  }

  List<Hospital> searchHospitals(String query) {
    final search = query.toLowerCase();
    return _hospitals
        .where((h) => 
            h.name.toLowerCase().contains(search) || 
            h.city.toLowerCase().contains(search))
        .toList();
  }

  String analyzeSymptoms(String symptoms) {
    final s = symptoms.toLowerCase();
    if (s.contains("heart") || s.contains("chest") || s.contains("dil") || s.contains("dhakan")) return "Cardiologist";
    if (s.contains("skin") || s.contains("khujli") || s.contains("daag") || s.contains("rash")) return "Dermatologist";
    if (s.contains("bone") || s.contains("haddi") || s.contains("fracture") || s.contains("moch")) return "Orthopedist";
    if (s.contains("eye") || s.contains("aankh") || s.contains("vision")) return "Ophthalmologist";
    if (s.contains("kidney") || s.contains("pathari") || s.contains("stone")) return "Urologist";
    if (s.contains("shishu") || s.contains("bachha") || s.contains("child")) return "Pediatrician";
    return "General Physician";
  }
}
