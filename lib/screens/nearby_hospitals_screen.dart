import 'package:flutter/material.dart';

import '../services/knowledge_service.dart';
import '../services/facility_service.dart';
import 'package:geolocator/geolocator.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  final KnowledgeService knowledgeService;
  final FacilityService facilityService; 
  final String language;

  const NearbyHospitalsScreen({
    super.key,
    required this.knowledgeService,
    required this.facilityService,
    required this.language,
  });

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  String _userCity = "";
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      Position? position = await widget.facilityService.getCurrentLocation();
      if (position != null) {
        final nearest = widget.facilityService.findNearestFacility(position);
        if (nearest != null && nearest['facility'] != null) {
           setState(() {
            _userCity = nearest['facility'].city ?? "";
            _isLoadingLocation = false;
          });
        } else {
          setState(() => _isLoadingLocation = false);
        }
      } else {
        setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.language == 'hi' ? "पास के अस्पताल" : "जवळपासची रुग्णालये",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
               setState(() {
                 _userCity = "";
                 _detectLocation();
               });
            },
          )
        ],
      ),
      body: FutureBuilder<List<Hospital>>(
        future: _userCity.isNotEmpty 
            ? widget.knowledgeService.searchHospitalsByCity(_userCity)
            : widget.knowledgeService.hospitals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isLoadingLocation) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }
          
          final hospitals = snapshot.data ?? widget.knowledgeService.getInstantHospitals();
          
          return Column(
            children: [
              _buildStatusHeader(context, hospitals.length),
              Expanded(
                child: hospitals.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      itemCount: hospitals.length,
                      itemBuilder: (context, index) {
                        final h = hospitals[index];
                        return _buildHospitalCard(context, h);
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EE), // surface-container-low
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _userCity.isNotEmpty ? Icons.gps_fixed_outlined : Icons.location_searching_outlined,
              color: colorScheme.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingLocation 
                     ? (widget.language == 'hi' ? "लोकेशन ढूँढ रहे हैं..." : "स्थान शोधत आहे...")
                     : (_userCity.isNotEmpty 
                         ? (widget.language == 'hi' ? "$_userCity में मिले अस्पताल" : "$_userCity मध्ये आढळली रुग्णालये")
                         : (widget.language == 'hi' ? "महाराष्ट्र अस्पताल सूची" : "महाराष्ट्र रुग्णालय सूची")),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
                Text(
                  _userCity.isNotEmpty ? "Based on your current region" : "Showing all verified facilities",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "$count",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildHospitalCard(BuildContext context, Hospital h) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // surface-container-lowest
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.local_hospital_outlined, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.name, 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2, color: const Color(0xFF1C1C19))
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${h.city}, Maharashtra", 
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(
                    h.contact, 
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.secondary)
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: Color(0xFF0F5238), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "VERIFIED",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0F5238)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            widget.language == 'hi' 
              ? (_userCity.isNotEmpty ? "$_userCity में कोई अस्पताल नहीं" : "कोई डेटा नहीं मिला") 
              : (_userCity.isNotEmpty ? "$_userCity मध्ये रुग्णालय नाही" : "डेटा सापडला नाही"),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          if (_userCity.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: () => setState(() => _userCity = ""),
                child: Text(
                  "सभी अस्पताल दिखाएं",
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            )
        ],
      ),
    );
  }
}
