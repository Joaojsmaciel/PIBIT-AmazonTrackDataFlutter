class FirestorePaths {
  // Documento raiz para namespace
  static const String rootDocument = '_root';
  static const String amazontrackdataDoc = 'amazontrackdata';
  
  // Coleções dentro do documento raiz
  static const String usersCollection = '$rootDocument/$amazontrackdataDoc/users';
  static const String boatsCollection = '$rootDocument/$amazontrackdataDoc/boats';
  static const String routesCollection = '$rootDocument/$amazontrackdataDoc/routes';
  static const String stopsCollection = '$rootDocument/$amazontrackdataDoc/stops';
  static const String locationsCollection = '$rootDocument/$amazontrackdataDoc/locations';
  static const String tripMetaCollection = '$rootDocument/$amazontrackdataDoc/tripMeta';

  // Subcoleções
  static const String tracksSubcollection = 'tracks';
  
  // Documentos especiais
  static const String defaultStopsDocument = '_default_stops';
  
  // Caminhos completos
  static String userDoc(String userId) => '$usersCollection/$userId';
  static String boatDoc(String boatId) => '$boatsCollection/$boatId';
  static String routeDoc(String routeId) => '$routesCollection/$routeId';
  static String stopDoc(String stopId) => '$stopsCollection/$stopId';
  static String locationTracksPath(String userId) => '$locationsCollection/$userId/$tracksSubcollection';
  static String locationTrackPath(String userId, String trackId) => '${locationTracksPath(userId)}/$trackId';
  static String tripMetaPath(String userId) => '$tripMetaCollection/$userId/trips';
}
