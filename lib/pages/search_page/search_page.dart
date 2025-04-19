import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/place_information.dart';
import 'package:first_maps_project/services/places_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';

class SearchPage extends StatefulWidget {
  final String apiKey;
  final LatLng cameraCenter;
  final TextEditingController textController;
  final void Function(PlaceInformation, String?) onPlaceSelected;

  const SearchPage({
    super.key,
    required this.apiKey,
    required this.cameraCenter,
    required this.textController,
    required this.onPlaceSelected,
  });

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _sessionToken;
  late final PlacesService _placesService;
  late FocusNode _searchFocusNode;
  final List<PlaceInformation> _places = [];

  @override
  void initState() {
    super.initState();
    widget.textController.text = "";
    _tabController = TabController(length: 3, vsync: this);
    _sessionToken = const Uuid().v4();
    _placesService = PlacesService(widget.apiKey);
    _searchFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus(); // ✅ pide foco al iniciar
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con botón de volver y campo de búsqueda visual
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ), // separa del safe area
              child: Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EEE8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: (){
                          widget.textController.text = "";
                          Navigator.pop(context);
                        }, // Botón de volver
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_back, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: widget.textController,
                          focusNode: _searchFocusNode,
                          onChanged: (text) => _onSearchChanged(text),
                          style: const TextStyle(
                            fontFamily: 'HalyardDisplay',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Search...',
                          ),
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),

            // Pestañas de navegación (Places, Maps, Users)
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              indicatorColor: Colors.black,
              //line below
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 3.0,
                  color: Color(0xFF41AAF5), // Cambiá el color aquí
                ),
                insets: EdgeInsets.symmetric(
                  horizontal: -24,
                ), // Controla el ancho de la línea
              ),
              // text style:
              labelStyle: TextStyle(
                fontFamily: 'Marine',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
              tabs: [
                Tab(
                  icon: SvgPicture.asset(
                    'assets/icons/F_ISO_Celeste_Naranja.svg',
                    width: 24,
                    height: 24,
                  ),
                  text: 'Places',
                ),
                Tab(icon: Icon(Icons.map), text: 'Maps'),
                Tab(icon: Icon(Icons.person), text: 'Users'),
              ],
            ),

            // Línea divisoria debajo de las pestañas
            Divider(height: 1, thickness: 1, color: Color(0xFFD6D6D6)),

            // Vista de contenido que cambia según la pestaña seleccionada
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildResultsList(), // Lista de resultados para Places
                  Center(child: Text('Maps content')), // Placeholder para Maps
                  Center(
                    child: Text('Users content'),
                  ), // Placeholder para Users
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construye la lista de resultados para la pestaña Places
  Widget _buildResultsList() {
    if (_places.isEmpty) {
      return Center(child: Text('No results'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return GestureDetector(
          onTap: () {
            widget.onPlaceSelected(place, _sessionToken);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFF2EEE8),
                  child: SvgPicture.asset(
                    'assets/icons/basic_pin.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'HalyardDisplay',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        place.formattedAddress ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'HalyardDisplay',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Maneja los cambios de texto en el buscador
  void _onSearchChanged(String text) async {
    if (!mounted) return;
    if (text.trim().isEmpty) {
      setState(() => _places.clear());
      return;
    }

    final results = await _placesService.getAutocomplete(
      text,
      _sessionToken,
      widget.cameraCenter,
    );

    setState(() {
      _places
        ..clear()
        ..addAll(results);
    });
  }
}
