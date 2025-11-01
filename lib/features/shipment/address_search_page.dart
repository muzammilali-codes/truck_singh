import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../config/config.dart';
import 'form_step/address_step.dart';

String GOOGLE_MAPS_API_KEY = AppConfig.googleMapsApiKey;

// Localization helper
class AppLocalizations {
  final Map<String, dynamic> _localizedStrings;
  AppLocalizations(this._localizedStrings);

  String translate(String key, [Map<String, String>? params]) {
    var text = _localizedStrings[key] ?? key;
    if (params != null) {
      params.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }

  static Future<AppLocalizations> load(String languageCode) async {
    try {
      debugPrint("🔄 Trying to load assets/translation/$languageCode.json");
      final jsonString =
      await rootBundle.loadString('assets/translations/$languageCode.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return AppLocalizations(jsonMap);
    } catch (e) {
      debugPrint("❌ Failed to load localization: $e");
      return AppLocalizations({});
    }
  }


}

class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({Key? key}) : super(key: key);

  @override
  _AddressSearchPageState createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;

  final String _sessionToken = const Uuid().v4();
  // late AppLocalizations loc;
  AppLocalizations? loc;
  @override
  void initState() {
    super.initState();
    _loadLocalization();
  }

  Future<void> _loadLocalization() async {
    // Change 'en' to 'hi' to load Hindi
    loc = await AppLocalizations.load('en');
    setState(() {}); // refresh UI after loading localization
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String input) {
    if (input.length < 2) {
      setState(() => _suggestions.clear());
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
          () => _fetchSuggestions(input),
    );
  }

  Future<void> _fetchSuggestions(String input) async {
    setState(() => _isLoading = true);
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': GOOGLE_MAPS_API_KEY,
        'sessiontoken': _sessionToken,
        'components': 'country:in',
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _suggestions = List<Map<String, dynamic>>.from(data['predictions']);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          debugPrint(
            loc?.translate('places_api_error', {'error': data['error_message']}),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint(loc?.translate('fetch_error', {'error': e.toString()}));
    }
  }

  Future<void> _getPlaceDetails(String placeId, String description) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'fields': 'geometry',
      'key': GOOGLE_MAPS_API_KEY,
      'sessiontoken': _sessionToken,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final place = Place(
            description: description,
            lat: location['lat'],
            lng: location['lng'],
          );
          if (mounted) Navigator.pop(context, place);
        }
      }
    } catch (e) {
      debugPrint(loc?.translate('place_details_error', {'error': e.toString()}));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loader until localization is loaded
    if (loc == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      //backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        //backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          decoration: BoxDecoration(
            //color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: loc!.translate('search_address_hint'),
              //hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(Colors.orange),
              ),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                final mainText =
                    suggestion['structured_formatting']?['main_text'] ?? '';
                final secondaryText =
                    suggestion['structured_formatting']?['secondary_text'] ?? '';

                return Container(
                  //color: Colors.white,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        //color: Colors.orange.shade100,
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    title: Text(
                      mainText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      secondaryText,
                      //style: TextStyle(color: Colors.grey.shade600),
                    ),
                    onTap: () => _getPlaceDetails(
                      suggestion['place_id'],
                      suggestion['description'],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
